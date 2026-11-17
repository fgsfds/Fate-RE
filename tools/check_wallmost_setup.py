"""Check exact wallmost slope endpoint heights and the clipper handoff."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_owallmost import divide
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x5EAAA, 817
FILL, CHECK = 0x5EDDB, 0x5EE1D
SPANS = (
    ('wallmost_left_height_', ENTRY, 238), ('wallmost_right_ray_', 0x5EB98, 167),
    ('wallmost_right_height_', 0x5EC3F, 133), ('wallmost_clip_flags_', 0x5ECC4, 279),
)
FRAME, STACK, STOP = 0x350000, 0x3F0000, 0x3FF000
SCAN, SECTOR_NUMBER, FIRST_WALL = 3, 5, 18
CAMERA_X, CAMERA_Y, CAMERA_Z = 490, 820, 600
ORIGIN_X, ORIGIN_Y, WALL_X, WALL_Y = 420, 850, 500, 900
DX, DY, BASE_DX, BASE_DY = 128, -96, 192, 53
DEPTH1, DEPTH2, NORMALIZER = 1024, 2048, 760
TOP_FACTOR, BOTTOM_FACTOR = -(1 << 19), 1 << 19
LEFT_FRACTION = 1 << 26
WIDTH = 320


@dataclass(frozen=True)
class Case:
    name: str
    elevation: int
    heinum: int
    floor: bool = False
    left: int = 10
    right: int = 200
    ray_x: int = 100
    ray_y: int = 40


CASES = (
    Case('unclipped ceiling', 0, 4),
    Case('unclipped floor, negative slope', 0, -5, floor=True),
    Case('fully top clipped', -14, 6),
    Case('fully bottom clipped', 14, -6, floor=True),
    Case('partial top clip', -6, 4),
    Case('partial bottom clip', 6, -4, floor=True),
    Case('right screen-edge ray', 3, 8, right=WIDTH - 1),
    Case('parallel screen-edge ray uses guarded fraction', 2, -7, floor=True,
         right=WIDTH - 1, ray_x=16, ray_y=-112),
)


def expected(case):
    coefficient = divide(case.heinum << 15, NORMALIZER)

    def project(fraction):
        x = ((WALL_X - ORIGIN_X) << 8) + (DX * fraction >> 20)
        y = ((WALL_Y - ORIGIN_Y) << 8) + (DY * fraction >> 20)
        height = (BASE_DX * coefficient * y - BASE_DY * coefficient * x) >> 24
        return (case.elevation << 7) + height

    x = WALL_X - CAMERA_X
    y = WALL_Y - CAMERA_Y
    if case.right == WIDTH - 1:
        ray_x, ray_y = case.ray_x - case.ray_y, case.ray_x + case.ray_y
    else:
        ray_x, ray_y = x + DX, y + DY
    numerator = y * ray_x - x * ray_y
    denominator = DX * ray_y - DY * ray_x
    fraction = divide(numerator << 28, denominator) if abs(denominator) > abs(numerator >> 3) else numerator
    height2 = project(LEFT_FRACTION)
    height1 = project(fraction)
    top1, top2 = (TOP_FACTOR * depth >> 20 for depth in (DEPTH1, DEPTH2))
    bottom1, bottom2 = (BOTTOM_FACTOR * depth >> 20 for depth in (DEPTH1, DEPTH2))
    top = (2 if height1 < top1 else 0) | (1 if height2 < top2 else 0)
    bottom = (8 if height1 > bottom1 else 0) | (4 if height2 > bottom2 else 0)
    slots = (top2, top1, top, bottom1, DEPTH2, bottom2, DEPTH1, height2,
             case.right, case.left, height1, top | bottom, height2)
    output = FRAME + case.left * 2
    registers = (0 if top == 3 else top, output, (case.right - case.left + 1) * 2,
                 output if top == 3 else SCAN * 4, height1, SCAN)
    return FILL if top == 3 else CHECK, registers, slots


def run_case(code, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)

    def put(name, value, offset=0, fmt='i'):
        address = DS + DATA_OFFSETS['_' + name] + offset
        cpu.mem_write(address, pack('<' + fmt, value))

    for name, value in (
        ('xdimen', WIDTH), ('camera_x', CAMERA_X), ('camera_y', CAMERA_Y),
        ('camera_z', CAMERA_Z), ('view_ray_x', case.ray_x), ('view_ray_y', case.ray_y),
        ('wall_clip_top', TOP_FACTOR), ('wall_clip_bottom', BOTTOM_FACTOR),
    ):
        put(name, value)
    for name, value in (('xb1', case.left), ('xb2', case.right), ('yb1', DEPTH1), ('yb2', DEPTH2)):
        put(name, value, SCAN * 4)
    put('wall', ORIGIN_X, FIRST_WALL * 32)
    put('wall', ORIGIN_Y, FIRST_WALL * 32 + 4)
    put('sector', case.heinum, SECTOR_NUMBER * 40 + (26 if case.floor else 18), 'h')
    put('sector', CAMERA_Z + case.elevation, SECTOR_NUMBER * 40 + (8 if case.floor else 4))

    for offset, value in (
        (0, FRAME), (0x2C, FIRST_WALL), (0x34, BASE_DX), (0x3C, BASE_DY),
        (0x40, SECTOR_NUMBER), (0x44, DY), (0x48, DX), (0x5C, WALL_X), (0x60, WALL_Y),
        (0x64, divide(case.heinum << 15, NORMALIZER)), (0x70, case.floor),
    ):
        cpu.mem_write(STACK + offset, pack('<i', value))

    state = []

    def enter_clipper(machine, address, _size, _user_data):
        assert machine.reg_read(UC_X86_REG_ESP) == STACK
        registers = (
            UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
            UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_EBP,
        )
        registers = tuple(unpack('<i', pack('<I', machine.reg_read(reg)))[0] for reg in registers)
        positions = (8, 0x18, 0x1C, 0x20, 0x24, 0x28, 0x30, 0x38, 0x50, 0x54, 4, 0x68, 0x6C)
        slots = tuple(unpack('<i', machine.mem_read(STACK + slot, 4))[0] for slot in positions)
        state.append((address, registers, slots))
        machine.emu_stop()

    for dest in (FILL, CHECK):
        cpu.mem_write(dest, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, enter_clipper, begin=dest, end=dest)
    for register, value in (
        (UC_X86_REG_EAX, CAMERA_Z + case.elevation), (UC_X86_REG_EBP, SCAN),
        (UC_X86_REG_ECX, NORMALIZER), (UC_X86_REG_EDI, LEFT_FRACTION),
        (UC_X86_REG_ESP, STACK),
    ):
        cpu.reg_write(register, value)
    cpu.emu_start(ENTRY, STOP, count=5000)
    assert cpu.reg_read(UC_X86_REG_EIP) in (FILL, CHECK)
    assert len(state) == 1
    return state[0]


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
            actual, desired = run_case(code, case), expected(case)
            assert actual == desired, f'{label}: {case.name}: {actual} != {desired}'
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the sloped wall setup')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored sloped-height setup cases')


if __name__ == '__main__':
    main()
