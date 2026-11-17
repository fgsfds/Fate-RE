"""Check sloped-plane first-wall geometry and its fixed-point view basis."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, bind_leaf_details, verify_leaf_relocations

ENTRY, END = 0x5F351, 0x5F468
SPANS = (
    ('grouscan_wall_vector_', ENTRY, 71),
    ('grouscan_wall_length_', 0x5F398, 61),
    ('grouscan_inverse_length_', 0x5F3D5, 61),
    ('grouscan_scale_wall_vector_', 0x5F412, 86),
)
STACK, SECTOR, WALL, POINT2 = 0x3F0000, 6, 13, 41
MASK = 0xFFFFFFFF


@dataclass(frozen=True)
class Case:
    name: str
    dx: int
    dy: int
    slope: int
    table_root: int
    x_ray: int
    y_ray: int
    scale: int


CASES = (
    Case('low exponent and positive slope', 16, 12, 819, 0x5000, 12015, 7000, 134500),
    Case('scaled index and negative slope', 192, -53, -1234, 0x4400, -13000, 2700, 221900),
    Case('degenerate wall and zero root', 0, 0, 15, 0, 4000, -8200, 162200),
    Case('flat z along a negative wall vector', -90, -125, 0, 0x4200, 15000, -7100, 162200),
)


def float_bits(value):
    return unpack('<I', pack('<f', value))[0]


def run_case(code, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)

    def address(name, offset=0):
        return DS + DATA_OFFSETS['_' + name] + offset

    def put(addr, value, fmt='i'):
        cpu.mem_write(addr, pack('<' + fmt, value))

    def get(addr):
        return unpack('<i', cpu.mem_read(addr, 4))[0]

    sector_ptr = address('sector', SECTOR * 40)
    wall_ptr = address('wall', WALL * 32)
    next_ptr = address('wall', POINT2 * 32)
    put(sector_ptr, WALL, 'h')
    put(wall_ptr, 931)
    put(wall_ptr + 4, 738)
    put(wall_ptr + 8, POINT2, 'h')
    put(next_ptr, 931 + case.dx)
    put(next_ptr + 4, 738 + case.dy)
    put(STACK + 0x1C, case.slope)
    put(address('view_ray_x'), case.x_ray)
    put(address('view_ray_y'), case.y_ray)
    put(address('view_width_reciprocal'), case.scale)

    squared = case.dx * case.dx + case.dy * case.dy
    exponent = max(0, (float_bits(squared) >> 24) - 0x44)
    root_index = squared >> (2 * exponent)
    put(address('sqrtable', root_index * 2), case.table_root, 'H')
    length = (case.table_root << exponent) >> 10

    bits = float_bits(length)
    reciprocal_index = (bits & 0x7FF000) >> 10
    reciprocal_exponent = ((bits - 0x3F800000) & MASK) >> 23
    table_reciprocal = 0x614F128
    put(address('reciptable', reciprocal_index), table_reciprocal)
    reciprocal = table_reciprocal >> (reciprocal_exponent & 31)
    slope_scale = (reciprocal * case.slope) >> 21

    cpu.reg_write(UC_X86_REG_EBP, sector_ptr)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(ENTRY, END, count=1000)
    assert cpu.reg_read(UC_X86_REG_EIP) == END
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK
    assert cpu.reg_read(UC_X86_REG_EBP) == sector_ptr
    assert cpu.reg_read(UC_X86_REG_ECX) == reciprocal
    assert cpu.reg_read(UC_X86_REG_EBX) == case.scale
    assert get(STACK + 0x30) == wall_ptr
    assert get(STACK + 0x2C) == case.dx * slope_scale
    assert get(STACK + 0x24) == case.dy * slope_scale
    assert get(address('sqrt_float_bits')) == bits
    assert get(address('slope_view_axis_x')) == -((case.y_ray * case.scale) >> 19)
    assert get(address('slope_view_axis_y')) == (case.x_ray * case.scale) >> 19


def check(executable, obj):
    original = image(executable)
    restored = bytearray()
    relocations = 0
    pointers = read_le_fixups(executable)['pointers']
    loaded = {name: address + DS for name, address in DATA_OFFSETS.items()}
    for symbol, entry, size in SPANS:
        raw = entry + 0x25600
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry)
        assert len(code) == size and code == executable[raw:raw + size], symbol
        verify_leaf_relocations(code, references, pointers, entry)
        relocations += len(references)
        code, _ = bind_leaf_details(obj, symbol, loaded, address=entry)
        restored.extend(code)
    assert len(restored) == END - ENTRY
    for label, code in (('original', original[ENTRY:END]), ('restored', bytes(restored))):
        for case in CASES:
            try:
                run_case(code, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing slope scan geometry')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {END - ENTRY} slope geometry bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored cases')


if __name__ == '__main__':
    main()
