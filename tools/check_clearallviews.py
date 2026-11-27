"""Check exact display clearing for stereo, VGA, paged and linear framebuffers."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_INSN
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    CODE_OFFSETS, DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES,
    bind_leaf_details, verify_leaf_relocations,
)
from verify_c_suite import GROUPS

ENTRY, SIZE = 0x5D0AA, 413
DISPATCH, RESTORE = 0x5D08A, 0x4ABBF
SELECT_PAGE, TIMER = 0x4417C, 0x31EC4
VGA, FRAME, STEREO = 0xA0000, 0x360000, 0x370000
PAGES, STACK, STOP = 0x3D0000, 0x3F0000, 0x3FF000
WIDTH, HEIGHT, PIXEL = 7, 5, 0xAD
VGA_SIZE, STEREO_SIZE = 0x10000, 0x7D00 * 4
GUARD = b'\x6b'


@dataclass(frozen=True)
class Case:
    name: str
    backend: int = 0
    mode: int = 0xC8
    stereo: bool = False
    graphics_mode: int = 0
    ports: tuple = ()
    bank_bytes: int = 0
    pages: tuple = ()


CASES = (
    Case('text mode returns without clearing', mode=3),
    Case('stereo buffer', stereo=True, graphics_mode=5),
    Case('stereo CRTC banks and buffer', stereo=True, graphics_mode=6,
         ports=tuple((0x3D4, 2, bank * 256 + 0x35) for bank in range(4)),
         bank_bytes=VGA_SIZE),
    Case('VGA planes', ports=((0x3C4, 2, 0xF02),), bank_bytes=VGA_SIZE),
    Case('paged framebuffer and alignment', backend=1,
         pages=((0, 0), (2, 0), (3, 1), (6, 3), (17, 1), (65, 0))),
    Case('paged mode with no pages', backend=1),
    Case('linear framebuffer', backend=2),
    Case('port 0x3cd banks', backend=3,
         ports=tuple((0x3CD, 1, bank) for bank in range(4)), bank_bytes=64000),
    Case('graphics controller banks', backend=4,
         ports=tuple((0x3CE, 2, bank * 4096 + 9) for bank in range(4)), bank_bytes=64000),
    Case('CRTC banks', backend=5,
         ports=tuple((0x3D4, 2, bank * 256 + 0x35) for bank in range(4)), bank_bytes=64000),
    Case('backend 6 only services timer', backend=6),
    Case('backend 7 only services timer', backend=7),
    Case('unknown backend only services timer', backend=255),
)


def cleared_region(length, offset=0, size=128):
    return GUARD * offset + bytes(length) + GUARD * (size - length - offset)


def run_case(code, original, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(DISPATCH, original[DISPATCH:DISPATCH + 32])
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 6])
    cpu.mem_write(VGA, GUARD * (VGA_SIZE + 8))
    cpu.mem_write(STEREO, GUARD * (STEREO_SIZE + 8))
    cpu.mem_write(FRAME, GUARD * 128)
    for index in range(len(case.pages)):
        cpu.mem_write(PAGES + index * 0x1000, GUARD * 128)

    def put(name, value, fmt='I'):
        cpu.mem_write(DS + DATA_OFFSETS['_' + name], pack('<' + fmt, value))

    put('qsetmode', case.mode)
    put('stereofps', case.stereo)
    put('brightness_video_mode', case.graphics_mode)
    put('video_backend', case.backend, 'B')
    put('display_page_count', len(case.pages))
    put('presentation_width', WIDTH)
    put('presentation_height', HEIGHT)
    put('frameplace', FRAME)
    put('clear_stereo_buffer', STEREO)

    parameters, port_writes, bank_images, timer_stacks, restore_stacks = [], [], [], [], []

    def select_page(machine, _address, _size, _user):
        index = machine.reg_read(UC_X86_REG_EAX)
        length, offset = case.pages[index]
        parameters.append(index)
        put('display_page_bytes', length)
        put('frameplace', PAGES + index * 0x1000 + offset + 16)

    def write_port(machine, port, size, value, _user):
        if port_writes:
            bank_images.append(bytes(machine.mem_read(VGA, VGA_SIZE + 8)))
        port_writes.append((port, size, value))
        machine.mem_write(VGA, GUARD * (VGA_SIZE + 8))

    def timer(machine, _address, _size, _user):
        timer_stacks.append(machine.reg_read(UC_X86_REG_ESP))

    def restore(machine, _address, _size, _user):
        restore_stacks.append(machine.reg_read(UC_X86_REG_ESP))

    for address, callback in ((SELECT_PAGE, select_page), (TIMER, timer)):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, callback, begin=address, end=address)
    cpu.hook_add(UC_HOOK_CODE, restore, begin=RESTORE, end=RESTORE)
    cpu.hook_add(UC_HOOK_INSN, write_port, None, 1, 0, UC_X86_INS_OUT)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, PIXEL)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)
    prior = tuple(0x10203040 + index for index in range(len(saved)))
    for reg, value in zip(saved, prior):
        cpu.reg_write(reg, value)
    cpu.emu_start(ENTRY, STOP, count=300000)

    assert parameters == list(range(len(case.pages))), 'display page order differs'
    assert tuple(port_writes) == case.ports, f'port writes differ: {port_writes}'
    final_bank = bytes(cpu.mem_read(VGA, VGA_SIZE + 8))
    if port_writes:
        bank_images.append(final_bank)
        expected_bank = cleared_region(case.bank_bytes, size=VGA_SIZE + 8)
        assert bank_images == [expected_bank] * len(case.ports), 'bank fill range differs'
    else:
        assert final_bank == GUARD * (VGA_SIZE + 8), 'unexpected bank write'
    fill = bytes([PIXEL]) if case.stereo else GUARD
    assert cpu.mem_read(STEREO, STEREO_SIZE + 8) == fill * STEREO_SIZE + GUARD * 8

    linear_length = (WIDTH * HEIGHT) & ~3
    linear_frame = case.mode == 0xC8 and case.backend in (1, 2) and not case.pages
    assert cpu.mem_read(FRAME, 128) == cleared_region(linear_length if linear_frame else 0)
    for index, (length, offset) in enumerate(case.pages):
        if index == len(case.pages) - 1:
            length = max(length, linear_length)
        assert cpu.mem_read(PAGES + index * 0x1000, 128) == cleared_region(length, offset + 16)

    assert timer_stacks == ([] if case.mode != 0xC8 else [STACK - 24]), 'timer call frame differs'
    assert restore_stacks == [STACK - 20], 'shared register frame differs'
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior


def check(exe, obj):
    original = image(exe)
    restored = bytearray()
    relocations = 0
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: offset + DS for name, offset in DATA_OFFSETS.items()}
    loaded_code = {name: offset + 0x10000 for name, offset in CODE_OFFSETS.items()}
    for symbol in GROUPS['clrviews'][1]:
        raw, length = LEAVES[symbol]
        entry = raw - 0x25600
        code_bindings = {}
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry,
                                             functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS,
                                             code_bindings=code_bindings)
        assert len(code) == length and code == exe[raw:raw + length], f'{symbol}: machine code mismatch'
        verify_leaf_relocations(code, references, pointers, entry, code_bindings=code_bindings)
        relocations += len(references)
        code, _ = bind_leaf_details(obj, symbol, loaded, address=entry,
                                    functions=FUNCTION_ADDRESSES, absolute_code=loaded_code,
                                    code_bindings={})
        restored.extend(code)
    assert len(restored) == SIZE

    for label, code in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', bytes(restored))):
        for case in CASES:
            try:
                run_case(code, original, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the display clear spans')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored display-clear cases')


if __name__ == '__main__':
    main()
