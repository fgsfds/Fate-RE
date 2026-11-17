"""Check the exact ceiling texture transform, horizontal spans, and shared return."""
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

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x47C1C, 752
ROLL, TIMER, RESTORE = 0x4A7F3, 0x31EC4, 0x47F04
SET_SIZE = 0x73FF0
SPANS = (
    ('ceilscan_texture_', ENTRY, 171), ('ceilscan_flip_x_', 0x47CC7, 54),
    ('ceilscan_flip_y_', 0x47CFD, 52), ('ceilscan_begin_spans_', 0x47D31, 255),
    ('ceilscan_scan_column_', 0x47E30, 142), ('ceilscan_empty_column_', 0x47EBE, 36),
    ('ceilscan_test_column_', 0x47EE2, 9), ('ceilscan_finish_spans_', 0x47EEB, 20),
    ('ceilscan_run_timer_', 0x47EFF, 5), ('ceilscan_restore_stack_', RESTORE, 8),
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
    Case('flat upper and lower edges', 0, ((2, 7, 8),) * 5),
    Case('transpose and narrowing', 4, ((2, 8, 9), (4, 8, 9), (3, 7, 7), (5, 10, 6))),
    Case('double scale and empty middle', 8, ((2, 6, 7), (5, 2, 3), (2, 7, 5), (3, 7, 8))),
    Case('horizontal flip and empty right edge', 16, ((2, 5, 8), (2, 6, 8), (9, 2, 4))),
    Case('vertical flip and clipped single column', 32, ((3, 9, 7),)),
    Case('all texture flags with disjoint spans', 60, ((2, 5, 5), (7, 11, 10), (2, 4, 4))),
    Case('empty scan', 0, ((5, 2, 2),) * 3),
)
CASES += tuple(
    Case(f'complete texture-flag combination {flags:#x}', flags,
         ((2, 8, 9), (4, 8, 9), (3, 7, 7), (5, 10, 6)))
    for flags in range(0, 64, 4)
)


def transformed(flags):
    x1, x2, y1, y2, pan_x, pan_y = INITIAL
    x_shift = 8 - (TILE_SIZE & 15) + bool(flags & 8)
    y_shift = 8 - (TILE_SIZE >> 4) + bool(flags & 8)
    if flags & 4:
        x1, x2, y1, y2 = y2, -y1, -x2, x1
        pan_x, pan_y = pan_y, pan_x
    if flags & 16:
        x1, y1, pan_x = -x1, -y1, -pan_x
    if flags & 32:
        x2, y2, pan_y = -x2, -y2, -pan_y
    x1 <<= x_shift
    x2 <<= y_shift
    y1 <<= x_shift
    y2 <<= y_shift
    pan_x = (pan_x << x_shift) + (PAN_X << 24)
    pan_y = (pan_y << y_shift) + (PAN_Y << 24)
    y1 = (-x1 - y1) * HALF_WIDTH
    x2 = (x2 - y2) * HALF_WIDTH
    return (x_shift, y_shift), tuple(value & MASK for value in (x1, x2, y1, y2, pan_x, pan_y))


def expected_spans(edges):
    right = LEFT + len(edges) - 1
    start_columns = list(range(50, 50 + ROWS))
    spans = []
    top = bottom = edges[0][0]

    def close(column, rows):
        spans.extend((column, row, start_columns[row]) for row in rows)

    for column, (upper, clip_a, clip_b) in enumerate(edges, LEFT):
        new_top = upper - 1
        new_bottom = min(clip_a, clip_b)
        if new_top >= new_bottom - 1:
            close(column - 1, range(top + 1, bottom))
            top = max(top, bottom - 1)
            if column == right:
                break
            top = bottom = edges[column - LEFT + 1][0]
            continue
        if new_top >= bottom:
            close(column - 1, range(top + 1, bottom))
        else:
            close(column - 1, range(top + 1, new_top + 1))
            for row in range(top, new_top, -1):
                start_columns[row] = column
        close(column - 1, range(bottom - 1, new_bottom - 1, -1))
        for row in range(bottom, new_bottom):
            start_columns[row] = column
        top, bottom = new_top, new_bottom
    close(right, range(top + 1, bottom))
    return spans, tuple(start_columns)


def run_case(code, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)

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
    cpu.mem_write(SECTOR + 0x16, bytes((PAN_X, PAN_Y)))
    for column, edge in enumerate(case.edges, LEFT):
        for name, value in zip(('upper_plane_edge', 'upper_clip_edge', 'lower_clip_edge'), edge):
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

    for target, handler in ((SET_SIZE, init_texture), (ROLL, draw_span), (TIMER, on_timer)):
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
    assert (spans, lastx) == expected_spans(case.edges), (spans, lastx, expected_spans(case.edges))
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
                run_case(code, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the ceiling scan continuation')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored ceiling continuation cases')


if __name__ == '__main__':
    main()
