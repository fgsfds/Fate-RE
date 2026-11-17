"""Check the exact wallmost entry, flat ABI path, and sloped geometry handoff."""
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

from check_owallmost import divide
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x5E824, 646
SETUP, FLAT, RESTORE = 0x5EAAA, 0x5E350, 0x5F1F1
SPANS = (
    ('wallmost_', ENTRY, 64), ('wallmost_flat_height_', 0x5E864, 10),
    ('wallmost_floor_height_', 0x5E86E, 37), ('wallmost_slope_geometry_', 0x5E893, 222),
    ('wallmost_slope_length_', 0x5E971, 85), ('wallmost_left_ray_', 0x5E9C6, 144),
    ('wallmost_slope_coefficient_', 0x5EA56, 84),
)
FRAME, STACK, STOP = 0x350000, 0x3F0000, 0x3FF000
STACK_FRAME = STACK - 128
SCAN, SECTOR, WALL, POINT2, BASE_WALL, BASE_POINT2 = 3, 5, 17, 19, 18, 20
CAMERA_X, CAMERA_Y, CAMERA_Z = 490, 820, 600
WALL_X, WALL_Y, DELTA_X, DELTA_Y = 500, 900, 128, -96
BASE_X, BASE_Y = 420, 850
SAVED_REGISTERS = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)
PRIOR = (0x10203040, 0x11223344, 0x23456789)


@dataclass(frozen=True)
class Case:
    name: str
    floor: bool = False
    sloped: bool = True
    elevation: int = 6
    heinum: int = 4
    left: int = 10
    base_dx: int = 16
    base_dy: int = 12
    table_value: int = 0x2800
    ray_x: int = 100
    ray_y: int = 40


CASES = (
    Case('flat ceiling', sloped=False),
    Case('flat floor', floor=True, sloped=False, elevation=-4),
    Case('ceiling slope uses minimum normalization length'),
    Case('floor slope uses normalized lookup twice', floor=True, heinum=-5,
         elevation=-3, base_dx=192, base_dy=53, table_value=0x1C00),
    Case('left screen-edge ray', floor=True, left=0),
    Case('left edge parallel ray uses guarded fraction', left=0, ray_x=112, ray_y=16),
)


def table_index(case):
    square = case.base_dx ** 2 + case.base_dy ** 2
    scratch = pack('<f', float(square))
    exponent = max(0, scratch[3] - 0x44)
    return square >> (2 * exponent), exponent, scratch


def expected_setup(case):
    _, exponent, scratch = table_index(case)
    length = max(16, (case.table_value << exponent) >> 10)
    coefficient = divide(case.heinum << 15, length)
    x = WALL_X - CAMERA_X
    y = WALL_Y - CAMERA_Y
    if case.left == 0:
        ray_x = case.ray_x + case.ray_y
        ray_y = case.ray_y - case.ray_x
    else:
        ray_x, ray_y = x, y
    numerator = y * ray_x - x * ray_y
    divisor = DELTA_X * ray_y - DELTA_Y * ray_x
    fraction = divide(numerator << 28, divisor) if abs(divisor) > abs(numerator >> 3) else numerator
    registers = (CAMERA_Z + case.elevation, length, fraction, SCAN)
    slots = (FRAME, BASE_WALL, case.base_dx, case.base_dy, SECTOR,
             DELTA_Y, DELTA_X, WALL_X, WALL_Y, coefficient, case.floor)
    return registers, slots, scratch


def run_case(code, original, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 7])

    def address(name, offset=0):
        return DS + DATA_OFFSETS['_' + name] + offset

    def put(name, value, offset=0, fmt='i'):
        cpu.mem_write(address(name, offset), pack('<' + fmt, value))

    for name, value in (
        ('camera_x', CAMERA_X), ('camera_y', CAMERA_Y), ('camera_z', CAMERA_Z),
        ('view_ray_x', case.ray_x), ('view_ray_y', case.ray_y),
    ):
        put(name, value)
    put('xb1', case.left, SCAN * 4)
    put('scan_wall_index', WALL, SCAN * 2, 'h')
    put('sector', BASE_WALL, SECTOR * 40, 'h')
    put('sector', CAMERA_Z + case.elevation, SECTOR * 40 + (8 if case.floor else 4))
    put('sector', case.heinum, SECTOR * 40 + (26 if case.floor else 18), 'h')
    put('sector', 0x1201 | (2 if case.sloped else 0), SECTOR * 40 + (14 if case.floor else 12), 'H')
    for index, x, y in (
        (WALL, WALL_X, WALL_Y), (POINT2, WALL_X + DELTA_X, WALL_Y + DELTA_Y),
        (BASE_WALL, BASE_X, BASE_Y), (BASE_POINT2, BASE_X + case.base_dx, BASE_Y + case.base_dy),
    ):
        put('wall', x, index * 32)
        put('wall', y, index * 32 + 4)
    put('wall', POINT2, WALL * 32 + 8, 'h')
    put('wall', BASE_POINT2, BASE_WALL * 32 + 8, 'h')
    ix, _, _ = table_index(case)
    put('sqrtable', case.table_value, ix * 2, 'H')

    flat_calls, setups = [], []

    def on_flat(machine, _address, _size, _user_data):
        registers = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX)
        flat_calls.append(tuple(unpack('<i', pack('<I', machine.reg_read(reg)))[0] for reg in registers))
        machine.reg_write(UC_X86_REG_EAX, 0x11223344)

    def on_setup(machine, _address, _size, _user_data):
        assert machine.reg_read(UC_X86_REG_ESP) == STACK_FRAME
        assert unpack('<3I', machine.mem_read(STACK_FRAME + 0x74, 12)) == PRIOR
        registers = (UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EBP)
        state = tuple(unpack('<i', pack('<I', machine.reg_read(reg)))[0] for reg in registers)
        positions = (0, 0x2C, 0x34, 0x3C, 0x40, 0x44, 0x48, 0x5C, 0x60, 0x64, 0x70)
        slots = tuple(unpack('<i', machine.mem_read(STACK_FRAME + off, 4))[0] for off in positions)
        scratch = bytes(machine.mem_read(address('wallmost_sqrt_scratch'), 4))
        setups.append((state, slots, scratch))
        machine.emu_stop()

    for target, handler in ((FLAT, on_flat), (SETUP, on_setup)):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, handler, begin=target, end=target)
    cpu.mem_write(STACK, pack('<I', STOP))
    for reg, value in zip(SAVED_REGISTERS, PRIOR):
        cpu.reg_write(reg, value)
    for reg, value in (
        (UC_X86_REG_EAX, FRAME), (UC_X86_REG_EBX, SECTOR), (UC_X86_REG_ECX, case.floor),
        (UC_X86_REG_EDX, SCAN), (UC_X86_REG_ESP, STACK),
    ):
        cpu.reg_write(reg, value)
    cpu.emu_start(ENTRY, STOP, count=4000)

    if case.sloped:
        assert not flat_calls
        assert setups == [expected_setup(case)], (setups, expected_setup(case))
        assert cpu.reg_read(UC_X86_REG_EIP) == SETUP
    else:
        assert not setups
        assert flat_calls == [(FRAME, case.elevation, SCAN)]
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
        assert tuple(cpu.reg_read(reg) for reg in SAVED_REGISTERS) == PRIOR
        assert cpu.reg_read(UC_X86_REG_EAX) == 0x11223344


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
    parser.add_argument('object', type=Path, help='Watcom object containing the wallmost entry')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored wallmost entry cases')


if __name__ == '__main__':
    main()
