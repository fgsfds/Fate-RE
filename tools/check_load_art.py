"""Check ART header reads, tile metadata, cache allocation and the original ABI."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x4BD46, 752
RESTORE, STRCPY = 0x4ABBE, 0x60333
STACK, STOP, PATH, CACHE = 0x3F0000, 0x3FF000, 0x3F4000, 0xD0000
OPEN, READ, CLOSE, ALLOC, INIT = 0x41281, 0x4137D, 0x41503, 0x4478C, 0x40C49
MIB, STEP = 1048576, 65536
INITIAL_GLOBAL = 0x01010101
FILES = ((3, (8, 32), (4, 2), (17, 0xC040)), (9, (1024,), (2048,), (177,)))
CASES = (
    ('no ART files', (), 0, 0),
    ('two files, large cache', FILES, 0, 0),
    ('allocator retries', FILES, 2, 0),
    ('allocation exhaustion', (), None, -1),
    ('unsupported ART version', (None,), 0, -1),
)


def run_case(code, original, files, failures, status):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(STRCPY, original[STRCPY:STRCPY + 32])
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 7])

    def data(name):
        return DS + DATA_OFFSETS['_' + name]

    def read_global(name):
        return unpack('<i', cpu.mem_read(data(name), 4))[0]

    for name, length in (('tilesizx', 8192), ('tilesizy', 8192), ('picanm', 16384),
                         ('picsiz', 4096), ('art_tile_locks', 512), ('art_tile_file', 4096)):
        cpu.mem_write(data(name), b'\x01' * length)
    for name in ('shutdown_art_handle', 'loaded_art_number', 'art_file_position',
                 'art_size', 'art_file_count', 'art_tile_cache', 'art_cache_bytes'):
        cpu.mem_write(data(name), pack('<i', INITIAL_GLOBAL))
    cpu.mem_write(data('pow2long'), pack('<16i', *(1 << bit for bit in range(16))))
    cpu.mem_write(PATH, b'TILES000.ART\x00')
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_EAX, PATH)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    prior = tuple(0x12345670 + i for i in range(len(saved)))
    for register, value in zip(saved, prior):
        cpu.reg_write(register, value)

    chunks = []
    for info in files:
        if info is None:
            chunks.append([pack('<i', 2)])
        else:
            start, widths, heights, animations = info
            count = len(widths)
            chunks.append([pack('<i', value) for value in (1, 4096, start, start + count - 1)] + [
                pack(f'<{count}h', *widths), pack(f'<{count}h', *heights), pack(f'<{count}i', *animations),
            ])
    opens, closes, allocations, initialized, tail_stack = [], [], [], [], []
    pending = {}

    def external(machine, address, _size, _user):
        eax, edx, ebx = (machine.reg_read(reg) for reg in (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX))
        if address == OPEN:
            assert edx == 0
            name = bytes(machine.mem_read(eax, 13)).rstrip(b'\x00').decode('ascii')
            index = len(opens)
            opens.append(name)
            handle = 100 + index if index < len(files) else -1
            if handle != -1:
                pending[handle] = chunks[index]
            machine.reg_write(UC_X86_REG_EAX, handle)
        elif address == READ:
            encoded = pending[eax].pop(0)
            assert ebx == len(encoded)
            machine.mem_write(edx, encoded)
            machine.reg_write(UC_X86_REG_EAX, ebx)
        elif address == CLOSE:
            assert not pending[eax]
            closes.append(eax)
        elif address == ALLOC:
            allocations.append(eax)
            machine.reg_write(UC_X86_REG_EAX, CACHE if failures is not None and len(allocations) > failures else 0)
        elif address == INIT:
            initialized.append((eax, edx))

    def record_tail(machine, _address, _size, _user):
        tail_stack.append(machine.reg_read(UC_X86_REG_ESP))

    for address in (OPEN, READ, CLOSE, ALLOC, INIT):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, external, begin=address, end=address)
    cpu.hook_add(UC_HOOK_CODE, record_tail, begin=RESTORE, end=RESTORE)
    cpu.emu_start(ENTRY, STOP, count=2000000)
    assert tail_stack == [STACK - 24]
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior
    assert cpu.reg_read(UC_X86_REG_EAX) == status & 0xFFFFFFFF

    unsupported = bool(files and files[0] is None)
    loaded = () if unsupported else files
    assert opens == [f'TILES{index:03d}.ART' for index in range(len(loaded) + 1)]
    assert closes == [100 + index for index in range(len(loaded))]
    assert all(not blocks for blocks in chunks)
    assert read_global('art_file_count') == len(loaded)
    widths, heights, animations = [0] * 4096, [0] * 4096, [0] * 4096
    total = 0
    for file_number, (start, file_widths, file_heights, art) in enumerate(loaded):
        offset = 16 + len(art) * 8
        for index, (width, height, animation) in enumerate(zip(file_widths, file_heights, art), start):
            widths[index], heights[index], animations[index] = width, height, animation
            assert cpu.mem_read(data('art_tile_file') + index, 1)[0] == file_number
            assert unpack('<i', cpu.mem_read(data('art_tile_offsets') + 4 * index, 4))[0] == offset
            total += width * height
            offset += width * height
    assert read_global('art_size') == total
    assert cpu.mem_read(data('tilesizx'), 8192) == pack('<4096h', *widths)
    assert cpu.mem_read(data('tilesizy'), 8192) == pack('<4096h', *heights)
    assert cpu.mem_read(data('picanm'), 16384) == pack('<4096i', *animations)
    if unsupported:
        assert not allocations and not initialized
        assert cpu.mem_read(data('art_tile_locks'), 512) == b'\x01' * 512
    else:
        assert cpu.mem_read(data('art_tile_locks'), 512) == bytes(512)
        initial_size = max(MIB, total)
        size_count = initial_size // STEP if failures is None else failures + 1
        assert allocations == [initial_size - attempt * STEP for attempt in range(size_count)]
        expected_size = allocations[-1] - STEP if failures is None else allocations[-1]
        assert read_global('art_cache_bytes') == expected_size
    if status:
        assert not initialized
        assert cpu.mem_read(data('picsiz'), 4096) == b'\x01' * 4096
        assert all(read_global(name) == INITIAL_GLOBAL for name in (
            'shutdown_art_handle', 'loaded_art_number', 'art_file_position',
        ))
    else:
        assert initialized == [(CACHE, allocations[-1])]
        assert read_global('art_tile_cache') == CACHE
        assert read_global('shutdown_art_handle') == -1
        assert read_global('loaded_art_number') == -1
        assert read_global('art_file_position') == 0
        expected = bytes(
            max(1, width.bit_length() - 1) + 16 * max(1, height.bit_length() - 1)
            for width, height in zip(widths, heights)
        )
        assert cpu.mem_read(data('picsiz'), 4096) == expected


def check(exe, obj):
    original = image(exe)
    raw = ENTRY + 0x25600
    code, references = bind_leaf_details(obj, 'load_art_files_', DATA_OFFSETS, address=ENTRY,
                                          functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[raw:raw + SIZE]
    verify_leaf_relocations(code, references, read_le_fixups(exe)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, 'load_art_files_', {key: value + DS for key, value in DATA_OFFSETS.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    for label, body in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', restored)):
        for name, *case in CASES:
            try:
                run_case(body, original, *case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {name}') from error
    return len(references)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing load_art_files_')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, {len(CASES)} original and {len(CASES)} restored ART cases')


if __name__ == '__main__':
    main()
