"""Check the exact floor texture transform, span clipping, and shared ceiling return."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)

from check_ceilscan_tail import expected_spans, transformed
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x48272, 788
HLINE, TIMER, RESTORE = 0x4A7F3, 0x31EC4, 0x47F04
TIMER_ENTRY = 0x47EFF
SET_SIZE = 0x73FF0
SPANS = (
    ('florscan_texture_', ENTRY, 175), ('florscan_flip_x_', 0x48321, 54),
    ('florscan_flip_y_', 0x48357, 52), ('florscan_begin_spans_', 0x4838B, 274),
    ('florscan_scan_column_', 0x4849D, 141), ('florscan_empty_column_', 0x4852A, 59),
    ('florscan_test_column_', 0x48565, 9), ('florscan_finish_spans_', 0x4856E, 24),
)
STACK, STOP, SECTOR = 0x3F0000, 0x3FF000, 0x380000
FRAME = STACK - 36
LEFT, TILE, HALF_WIDTH, TEXTURE_ADDRESS = 3, 17, 160, 0x350000
TILE_SIZE, PAN_X, PAN_Y, ROWS = 0x65, 123, 254, 16
INITIAL = (72, -121, 337, -413, 3072, -17404)
GLOBALS = ('globalx1', 'globalx2', 'globaly1', 'globaly2', 'globalxpanning', 'globalypanning')
SAVED = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ECX)
PRIOR = (0x11223344, 0x22334455, 0x33445566, 0x44556677)
MASK = 0xFFFFFFFF


@dataclass(frozen=True)
class Case:
    name: str
    flags: int
    edges: tuple


CASES = (
    Case('floor edge dominates', 0, ((2, 4, 9),) * 5),
    Case('ceiling edge dominates', 4, ((4, 2, 9), (5, 2, 8), (3, 1, 8))),
    Case('double scale and empty middle', 8, ((2, 1, 6), (5, 7, 2), (2, 4, 7), (3, 3, 7))),
    Case('horizontal flip and empty right edge', 16, ((2, 3, 8), (4, 2, 6), (9, 6, 2))),
    Case('vertical flip and clipped single column', 32, ((3, 1, 7),)),
    Case('all texture flags with disjoint spans', 60, ((2, 4, 8), (7, 8, 10), (2, 1, 4))),
    Case('empty floor', 0, ((5, 6, 2),) * 3),
)
CASES += tuple(
    Case(f'complete texture-flag combination {flags:#x}', flags,
         ((4, 2, 9), (5, 2, 8), (3, 1, 8)))
    for flags in range(0, 64, 4)
)


def floor_spans(edges):
    return expected_spans(tuple((max(upper, lower), clip, clip) for upper, lower, clip in edges))


def run_case(code, original, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(TIMER_ENTRY, original[TIMER_ENTRY:RESTORE + 8])

    def address(name, offset=0):
        return DS + DATA_OFFSETS['_' + name] + offset

    def put(name, value, offset=0, fmt='i'):
        cpu.mem_write(address(name, offset), pack('<' + fmt, value))

    for name, value in zip(GLOBALS, INITIAL):
        put(name, value)
    for name, value in (
        ('globalorientation', case.flags), ('half_view_width', HALF_WIDTH),
        ('globalbufplc', TEXTURE_ADDRESS),
    ):
        put(name, value)
    put('globalpicnum', TILE, fmt='h')
    put('picsiz', TILE_SIZE, TILE, 'B')
    cpu.mem_write(SECTOR + 0x1E, bytes((PAN_X, PAN_Y)))
    for column, edge in enumerate(case.edges, LEFT):
        for name, value in zip(('upper_plane_edge', 'lower_plane_edge', 'lower_clip_edge'), edge):
            put(name, value, column * 2, 'h')
    for row in range(ROWS):
        put('lastx', 50 + row, row * 4)

    calls, spans, timer_frames, return_frames = [], [], [], []

    def init_texture(machine, _address, _size, _user_data):
        calls.append(tuple(machine.reg_read(reg) for reg in (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX)))

    def draw_span(machine, _address, _size, _user_data):
        column = machine.reg_read(UC_X86_REG_EAX)
        row = machine.reg_read(UC_X86_REG_EDX)
        start = unpack('<i', machine.mem_read(address('lastx', row * 4), 4))[0]
        spans.append((column, row, start))
        machine.reg_write(UC_X86_REG_EAX, 0xface)
        machine.reg_write(UC_X86_REG_EDX, 0xfeed)

    def on_timer(machine, _address, _size, _user_data):
        timer_frames.append(machine.reg_read(UC_X86_REG_ESP))

    def on_restore(machine, _address, _size, _user_data):
        return_frames.append(machine.reg_read(UC_X86_REG_ESP))

    for target, handler in ((SET_SIZE, init_texture), (HLINE, draw_span), (TIMER, on_timer)):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, handler, begin=target, end=target)
    cpu.hook_add(UC_HOOK_CODE, on_restore, begin=RESTORE, end=RESTORE)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.mem_write(FRAME, pack('<2I', LEFT + len(case.edges) - 1, LEFT))
    cpu.mem_write(FRAME + 0x14, pack('<4I', *PRIOR))
    cpu.reg_write(UC_X86_REG_EBP, SECTOR)
    cpu.reg_write(UC_X86_REG_ESP, FRAME)
    cpu.emu_start(ENTRY, STOP, count=5000)

    assert calls == [(TILE_SIZE & 15, TILE_SIZE >> 4, TEXTURE_ADDRESS)]
    assert timer_frames == [FRAME - 4]
    assert return_frames == [FRAME]
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in SAVED) == PRIOR
    lastx = unpack(f'<{ROWS}i', cpu.mem_read(address('lastx'), ROWS * 4))
    assert (spans, lastx) == floor_spans(case.edges), (spans, lastx, floor_spans(case.edges))
    dims = tuple(cpu.mem_read(address(name), 1)[0] for name in ('tile_x_shift', 'tile_y_shift'))
    values = tuple(unpack('<I', cpu.mem_read(address(name), 4))[0] for name in GLOBALS)
    assert (dims, values) == transformed(case.flags), (dims, values, transformed(case.flags))


def check(exe, obj):
    original = image(exe)
    restored = bytearray()
    relocations = 0
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: offset + DS for name, offset in DATA_OFFSETS.items()}
    for symbol, entry, length in SPANS:
        raw = entry + 0x25600
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry,
                                             functions=FUNCTION_ADDRESSES)
        assert len(code) == length and code == exe[raw:raw + length], f'{symbol}: machine code mismatch'
        verify_leaf_relocations(code, references, pointers, entry)
        relocations += len(references)
        code, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
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
    parser.add_argument('object', type=Path, help='Watcom object containing the floor scan continuation')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored floor continuation cases')


if __name__ == '__main__':
    main()
