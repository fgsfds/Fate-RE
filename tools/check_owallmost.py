"""Check exact flat-wall clipping and projected screen columns."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x5E350, 1236
SPANS = (
    ('owallmost_', ENTRY, 272), ('owallmost_fill_clipped_', 0x5E460, 66),
    ('owallmost_check_bottom_', 0x5E4A2, 32), ('owallmost_clip_top_', 0x5E4C2, 213),
    ('owallmost_fill_top_', 0x5E597, 63), ('owallmost_clip_bottom_', 0x5E5D6, 260),
    ('owallmost_fill_bottom_', 0x5E6DA, 61), ('owallmost_interpolate_', 0x5E717, 257),
    ('owallmost_return_', 0x5E818, 12),
)
FRAME, STACK, STOP = 0x350000, 0x3F0000, 0x3FF000
SCAN, COLUMNS, HEIGHT = 13, 48, 200
TOP_FACTOR, BOTTOM_FACTOR, SCALE = -(1 << 19), 1 << 19, 7000
GUARD = 0x1234


@dataclass(frozen=True)
class Case:
    name: str
    left: int
    right: int
    z: int
    depth1: int = 1024
    depth2: int = 2048
    horizon: int = 100
    output_shift: int = 0


CASES = (
    Case('fully top clipped one column', 3, 3, -10),
    Case('fully top clipped unaligned span', 3, 32, -10),
    Case('fully bottom clipped short span', 6, 7, 10, output_shift=2),
    Case('fully bottom clipped even span', 3, 30, 10, output_shift=2),
    Case('top clipped 2 flag', 2, 35, -6),
    Case('top clipped 1 flag', 3, 34, -6, depth1=2048, depth2=1024),
    Case('bottom clipped 8 flag', 2, 35, 6),
    Case('bottom clipped 4 flag', 3, 34, 6, depth1=2048, depth2=1024),
    Case('unclipped descending scan', 4, 28, -2),
    Case('unclipped ascending and unaligned scan', 4, 28, 2, output_shift=2),
    Case('unclipped single column', 5, 5, 2),
    Case('negative endpoints clamp', 4, 10, 0, horizon=-2),
    Case('high endpoints clamp', 5, 13, 0, horizon=205),
)


def signed(value, size):
    sign = 1 << (size - 1)
    return ((value & (sign - 1)) - (value & sign))


def divide(numerator, denominator):
    magnitude = abs(numerator) // abs(denominator)
    return -magnitude if (numerator < 0) != (denominator < 0) else magnitude


def expected(case):
    z = case.z << 7
    top1, top2 = (TOP_FACTOR * depth >> 20 for depth in (case.depth1, case.depth2))
    bottom1, bottom2 = (BOTTOM_FACTOR * depth >> 20 for depth in (case.depth1, case.depth2))
    top = (2 if z < top1 else 0) | (1 if z < top2 else 0)
    bottom = (8 if z > bottom1 else 0) | (4 if z > bottom2 else 0)
    output = [GUARD] * COLUMNS
    left, right = case.left, case.right
    depth_left, depth_right = case.depth2, case.depth1

    if top == 3 or bottom == 12:
        output[left:right + 1] = [0 if top == 3 else HEIGHT] * (right - left + 1)
        return top | bottom, tuple(output)

    for flags, right_flag, edge1, edge2, blank in (
        (top, 2, top1, top2, 0), (bottom, 8, bottom1, bottom2, HEIGHT),
    ):
        if not flags:
            continue
        fraction = divide((z - edge2) << 30, edge1 - edge2)
        depth = case.depth2 + ((case.depth1 - case.depth2) * fraction >> 30)
        column = case.left + divide((case.depth1 * fraction >> 30) * (case.right - case.left), depth)
        if flags == right_flag:
            if column >= case.left:
                right, depth_right = column, depth
            output[column + 1:case.right + 1] = [blank] * (case.right - column)
        else:
            if column <= case.right:
                left, depth_left = column, depth
            output[case.left:column + 1] = [blank] * (column - case.left + 1)

    start = divide(z * SCALE, depth_left) << 4
    end = divide(z * SCALE, depth_right) << 4
    step = divide(end - start, right - left + 1)
    sample = (case.horizon << 16) + start
    column = left
    if (case.output_shift + left * 2) & 2:
        output[column] = signed(sample >> 16, 16)
        column += 1
        sample += step
    while column + 1 <= right:
        packed = (sample >> 16) + ((sample + step) & 0xFFFF0000)
        output[column:column + 2] = [signed(packed, 16), signed(packed >> 16, 16)]
        column += 2
        sample += step * 2
    if column <= right:
        output[column] = signed(sample >> 16, 16)
    for column in (left, right):
        output[column] = min(HEIGHT, max(0, output[column]))
    return top | bottom, tuple(output)


def run_case(code, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    frame = FRAME + case.output_shift
    cpu.mem_write(frame, pack('<h', GUARD) * COLUMNS)
    cpu.mem_write(frame - 2, b'\xa5\xa5')
    cpu.mem_write(frame + COLUMNS * 2, b'\x5a\x5a')

    def put(name, value, index=0):
        address = DS + DATA_OFFSETS['_' + name] + index * 4
        cpu.mem_write(address, pack('<i', value))

    for name, value in (
        ('wall_clip_top', TOP_FACTOR), ('wall_clip_bottom', BOTTOM_FACTOR),
        ('viewingrange_scaled', SCALE), ('view_height', HEIGHT), ('globalhoriz', case.horizon),
    ):
        put(name, value)
    for name, value in (
        ('xb1', case.left), ('xb2', case.right), ('yb1', case.depth1), ('yb2', case.depth2),
    ):
        put(name, value, SCAN)

    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, frame)
    cpu.reg_write(UC_X86_REG_EBX, case.z & 0xFFFFFFFF)
    cpu.reg_write(UC_X86_REG_EDX, SCAN)
    saved = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    prior = tuple(0x10203040 + index for index in range(len(saved)))
    for reg, value in zip(saved, prior):
        cpu.reg_write(reg, value)
    cpu.emu_start(ENTRY, STOP, count=6000)

    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior
    assert cpu.mem_read(frame - 2, 2) == b'\xa5\xa5'
    assert cpu.mem_read(frame + COLUMNS * 2, 2) == b'\x5a\x5a'
    values = unpack(f'<{COLUMNS}h', cpu.mem_read(frame, COLUMNS * 2))
    return cpu.reg_read(UC_X86_REG_EAX), values


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
            actual = run_case(code, case)
            desired = expected(case)
            assert actual == desired, f'{label}: {case.name}: {actual} != {desired}'
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the flat-wall projection')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored wall projection cases')


if __name__ == '__main__':
    main()
