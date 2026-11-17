"""Check the exact sloped wall clip and interpolation continuation."""
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

from check_owallmost import divide, signed
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, TAIL = 0x5E824, 0x5EDDB
TAIL_SIZE, EPILOGUE, FLAT_PROJECT = 1053, 0x5F1F1, 0x5E350
SPANS = (
    ('wallmost_fill_clipped_', TAIL, 66), ('wallmost_check_bottom_', 0x5EE1D, 32),
    ('wallmost_clip_top_', 0x5EE3D, 257), ('wallmost_fill_top_', 0x5EF3E, 63),
    ('wallmost_clip_bottom_', 0x5EF7D, 297), ('wallmost_fill_bottom_', 0x5F0A6, 65),
    ('wallmost_interpolate_', 0x5F0E7, 262), ('wallmost_read_flags_', 0x5F1ED, 4),
    ('wallmost_restore_', EPILOGUE, 7),
)
FRAME, STACK, STOP = 0x350000, 0x3F0000, 0x3FF000
STACK_FRAME, SCAN, COLUMNS = STACK - 128, 13, 48
HEIGHT, SCALE, GUARD = 200, 7000, 0x1234
TOP_FACTOR, BOTTOM_FACTOR = -(1 << 19), 1 << 19
SAVED_REGISTERS = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)
PRIOR = (0x10203040, 0x11223344, 0x23456789)


@dataclass(frozen=True)
class Case:
    name: str
    left: int
    right: int
    height1: int
    height2: int
    depth1: int = 1024
    depth2: int = 2048
    horizon: int = 100
    output_shift: int = 0


CASES = (
    Case('fully top clipped one column', 3, 3, -830, -1320),
    Case('fully top clipped longer span', 3, 32, -830, -1320),
    Case('fully bottom clipped short span', 6, 7, 830, 1320, output_shift=2),
    Case('fully bottom clipped longer span', 3, 30, 830, 1320, output_shift=2),
    Case('top flag 2', 2, 35, -800, -700),
    Case('top flag 1', 3, 34, -300, -1350),
    Case('bottom flag 8', 2, 35, 800, 700),
    Case('bottom flag 4', 3, 34, 300, 1350),
    Case('clips both ends of a sloped edge', 2, 35, -800, 1400),
    Case('unclipped descending scan', 4, 28, -200, 90),
    Case('unclipped ascending and unaligned scan', 4, 28, 310, -110, output_shift=2),
    Case('unclipped single column', 5, 5, 250, 150),
    Case('negative endpoints clamp', 4, 10, 0, 0, horizon=-2),
    Case('high endpoints clamp', 5, 13, 0, 0, horizon=205),
)


def clip_planes(case):
    top = tuple(TOP_FACTOR * depth >> 20 for depth in (case.depth1, case.depth2))
    bottom = tuple(BOTTOM_FACTOR * depth >> 20 for depth in (case.depth1, case.depth2))
    flags = (
        (2 if case.height1 < top[0] else 0) | (1 if case.height2 < top[1] else 0),
        (8 if case.height1 > bottom[0] else 0) | (4 if case.height2 > bottom[1] else 0),
    )
    return top, bottom, flags


def expected(case):
    top, bottom, (top_flags, bottom_flags) = clip_planes(case)
    visible = [GUARD] * COLUMNS
    left, right = case.left, case.right
    left_depth, right_depth = case.depth2, case.depth1
    left_height, right_height = case.height2, case.height1

    if top_flags == 3 or bottom_flags == 12:
        visible[left:right + 1] = [0 if top_flags == 3 else HEIGHT] * (right - left + 1)
        return top_flags | bottom_flags, tuple(visible)

    for flags, right_flag, (edge1, edge2), blank in (
        (top_flags, 2, top, 0), (bottom_flags, 8, bottom, HEIGHT),
    ):
        if not flags:
            continue
        z1, z2 = case.height1, case.height2
        fraction = divide((z2 - edge2) << 30, edge1 - edge2 + z2 - z1)
        depth = case.depth2 + ((case.depth1 - case.depth2) * fraction >> 30)
        height = z2 + ((z1 - z2) * fraction >> 30)
        column = case.left + divide((case.depth1 * fraction >> 30) * (case.right - case.left), depth)
        if flags == right_flag:
            if column >= case.left:
                right, right_depth, right_height = column, depth, height
            visible[column + 1:case.right + 1] = [blank] * (case.right - column)
        else:
            if column <= case.right:
                left, left_depth, left_height = column, depth, height
            visible[case.left:column + 1] = [blank] * (column - case.left + 1)

    start = divide(left_height * SCALE, left_depth) << 4
    end = divide(right_height * SCALE, right_depth) << 4
    step = divide(end - start, right - left + 1)
    sample = (case.horizon << 16) + start
    column = left
    if (case.output_shift + left * 2) & 2:
        visible[column] = signed(sample >> 16, 16)
        column += 1
        sample += step
    while column + 1 <= right:
        packed = (sample >> 16) + ((sample + step) & 0xFFFF0000)
        visible[column:column + 2] = [signed(packed, 16), signed(packed >> 16, 16)]
        column += 2
        sample += step * 2
    if column <= right:
        visible[column] = signed(sample >> 16, 16)
    for column in (left, right):
        visible[column] = min(HEIGHT, max(0, visible[column]))
    return top_flags | bottom_flags, tuple(visible)


def new_cpu(code):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(STACK, pack('<I', STOP))
    return cpu


def finish_case(cpu):
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in SAVED_REGISTERS) == PRIOR
    return cpu.reg_read(UC_X86_REG_EAX)


def run_sloped_tail(code, case):
    cpu = new_cpu(code)
    frame = FRAME + case.output_shift
    cpu.mem_write(frame, pack('<h', GUARD) * COLUMNS)
    cpu.mem_write(frame - 2, b'\xa5\xa5')
    cpu.mem_write(frame + COLUMNS * 2, b'\x5a\x5a')

    def put(name, value, index=0):
        address = DS + DATA_OFFSETS['_' + name] + index * 4
        cpu.mem_write(address, pack('<i', value))

    for name, value in (('viewingrange_scaled', SCALE), ('view_height', HEIGHT),
                        ('globalhoriz', case.horizon)):
        put(name, value)
    for name, value in (('xb1', case.left), ('xb2', case.right),
                        ('yb1', case.depth1), ('yb2', case.depth2)):
        put(name, value, SCAN)

    top, bottom, (top_flags, bottom_flags) = clip_planes(case)
    saved_slots = {
        0: frame, 4: case.height1, 8: top[1], 0x18: top[0], 0x1C: top_flags,
        0x20: bottom[0], 0x24: case.depth2, 0x28: bottom[1], 0x30: case.depth1,
        0x38: case.height2, 0x50: case.right, 0x54: case.left,
        0x68: top_flags | bottom_flags, 0x6C: case.height2,
    }
    for offset, value in saved_slots.items():
        cpu.mem_write(STACK_FRAME + offset, pack('<i', value))
    cpu.mem_write(STACK_FRAME + 0x74, pack('<3I', *PRIOR))
    cpu.reg_write(UC_X86_REG_ESP, STACK_FRAME)
    cpu.reg_write(UC_X86_REG_EAX, 0)
    cpu.reg_write(UC_X86_REG_EBX, frame + case.left * 2)
    cpu.reg_write(UC_X86_REG_ECX, (case.right - case.left + 1) * 2)
    cpu.reg_write(UC_X86_REG_ESI, case.height1 & 0xFFFFFFFF)
    cpu.reg_write(UC_X86_REG_EDI, frame + case.left * 2 if top_flags == 3 else SCAN * 4)
    cpu.reg_write(UC_X86_REG_EBP, SCAN)
    entry = TAIL if top_flags == 3 else SPANS[1][1]
    cpu.emu_start(entry, STOP, count=8000)

    flags = finish_case(cpu)
    assert cpu.mem_read(frame - 2, 2) == b'\xa5\xa5'
    assert cpu.mem_read(frame + COLUMNS * 2, 2) == b'\x5a\x5a'
    values = unpack(f'<{COLUMNS}h', cpu.mem_read(frame, COLUMNS * 2))
    return flags, values


def run_flat_entry(code, floor):
    cpu = new_cpu(code)
    z = 1190 if floor else 715
    camera_z = 640
    sector = 5
    sector_addr = DS + DATA_OFFSETS['_sector'] + sector * 40
    cpu.mem_write(sector_addr + (8 if floor else 4), pack('<i', z))
    cpu.mem_write(DS + 0x286AD8, pack('<i', camera_z))
    args, restore_frames = [], []

    def on_flat(machine, _address, _size, _user_data):
        args.append(tuple(machine.reg_read(reg) for reg in (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX)))
        machine.reg_write(UC_X86_REG_EAX, 0x11223344)

    def on_restore(machine, _address, _size, _user_data):
        restore_frames.append(machine.reg_read(UC_X86_REG_ESP))

    cpu.mem_write(FLAT_PROJECT, b'\xc3')
    cpu.hook_add(UC_HOOK_CODE, on_flat, begin=FLAT_PROJECT, end=FLAT_PROJECT)
    cpu.hook_add(UC_HOOK_CODE, on_restore, begin=EPILOGUE, end=EPILOGUE)
    for register, value in zip(SAVED_REGISTERS, PRIOR):
        cpu.reg_write(register, value)
    for register, value in ((UC_X86_REG_ESP, STACK), (UC_X86_REG_EAX, FRAME),
                            (UC_X86_REG_EBX, sector), (UC_X86_REG_ECX, floor),
                            (UC_X86_REG_EDX, SCAN)):
        cpu.reg_write(register, value)
    cpu.emu_start(ENTRY, STOP, count=1200)
    assert args == [(FRAME, z - camera_z, SCAN)]
    assert restore_frames == [STACK_FRAME]
    assert finish_case(cpu) == 0x11223344


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
    assert len(restored) == TAIL_SIZE

    entry_code = original[ENTRY:TAIL]
    for label, tail_code in (('original', original[TAIL:TAIL + TAIL_SIZE]), ('restored', bytes(restored))):
        code = entry_code + tail_code
        for case in CASES:
            actual = run_sloped_tail(code, case)
            desired = expected(case)
            assert actual == desired, f'{label}: {case.name}: {actual} != {desired}'
        for floor in (False, True):
            run_flat_entry(code, floor)
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the wall clipping continuation')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {TAIL_SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES) + 2} original and {len(CASES) + 2} restored wall projection cases')


if __name__ == '__main__':
    main()
