"""Verify both Watcom slope queries against the linked DOS image and a numerical model."""
import argparse
from pathlib import Path
from struct import pack, pack_into

from check_ksqrt import oracle as square_root, table_value
from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

DATA_BASE, SECTOR, WALL, SQRT_TABLE = 0x80000, 0x27c3a0, 0x2310a0, 0x1dfa60
TAIL, STACK, STOP = 0x4c944, 0x3f0000, 0x3ff000
COMMON = {
    '_sector_wallptr': SECTOR, '_wall_x': WALL, '_wall_y': WALL + 4,
    '_wall_point2': WALL + 8, '_sqrtable': SQRT_TABLE,
}
QUERIES = (
    ('getceilzofslope_', 0x5de70, {**COMMON, '_ceiling_z': SECTOR + 4,
                                  '_ceiling_flags': SECTOR + 12, '_ceiling_heinum': SECTOR + 18}, 0),
    ('getflorzofslope_', 0x5df75, {**COMMON, '_floor_z': SECTOR + 8,
                                  '_floor_flags': SECTOR + 14, '_floor_heinum': SECTOR + 26}, 1),
)
SAVED = dict(zip((UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP),
                 (0x13570001, 0x13570002, 0x13570003, 0x13570004)))
TABLE = [table_value(index) for index in range(2048)]
FUNCTIONS = {'finish_slope_height_': TAIL}


def expected(height, flags, heinum, start, end, point):
    if not flags & 2:
        return height
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = square_root(dx * dx + dy * dy, TABLE)
    if not length:
        return height
    coefficient = (abs(heinum) << 15) // length
    if heinum < 0:
        coefficient = -coefficient
    cross = dx * (point[1] - start[1]) - dy * (point[0] - start[0])
    return height + ((coefficient * cross) >> 23)


def execute(address, code, shared_return, start, end, point, heights, flags, slopes):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(address, code)
    machine.mem_write(TAIL, shared_return)
    machine.mem_write(DATA_BASE + SQRT_TABLE, pack('<2048H', *TABLE))

    # Query sector 1. Its first wall and next corner are distinct, nonzero indices.
    sector = bytearray(40)
    pack_into('<hhiiHH', sector, 0, 3, 4, *heights, *flags)
    pack_into('<h', sector, 18, slopes[0])
    pack_into('<h', sector, 26, slopes[1])
    machine.mem_write(DATA_BASE + SECTOR + 40, bytes(sector))
    machine.mem_write(DATA_BASE + WALL + 3 * 32, pack('<iih', *start, 5))
    machine.mem_write(DATA_BASE + WALL + 5 * 32, pack('<ii', *end))
    for register, value in SAVED.items():
        machine.reg_write(register, value)
    machine.reg_write(UC_X86_REG_EAX, 0x24680001)
    machine.reg_write(UC_X86_REG_EDX, point[0] & 0xffffffff)
    machine.reg_write(UC_X86_REG_EBX, point[1] & 0xffffffff)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    machine.emu_start(address, STOP, count=500)
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert machine.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(machine.reg_read(register) == value for register, value in SAVED.items())
    return machine.reg_read(UC_X86_REG_EAX)


def check(exe, obj):
    linked = image(exe)
    tail = linked[TAIL:TAIL + 8]
    pointers = read_le_fixups(exe)['pointers']
    scenarios = [
        ((100, 204), (116, 204), (101, 250), (-12000, 12100), (1, 0), (256, 128)),
        ((300, -200), (300, -200), (500, -201), (-6500, 6500), (2, 2), (1000, -1000)),
        ((-200, 100), (-193, 103), (-120, 250), (-900, 1400), (2, 2), (257, -511)),
        ((70, -80), (900, 250), (122, -180), (-1000, 1100), (2, 0), (-384, 512)),
        ((400, -250), (75, -120), (305, -99), (-123, 456), (0, 2), (384, 514)),
        ((-55, -25), (90, 20), (-10, -270), (-300, 300), (3, 3), (0, 0)),
    ]
    for symbol, address, data, plane in QUERIES:
        code, refs = bind_leaf_details(obj, symbol, data, address=address, functions=FUNCTIONS)
        assert len(code) == 261 and len(refs) == 14
        raw_offset = address + 0x25600
        assert code == exe[raw_offset:raw_offset + 261]
        verify_leaf_relocations(code, refs, pointers, address)
        relocated = {name: DATA_BASE + offset for name, offset in data.items()}
        code, _ = bind_leaf_details(obj, symbol, relocated, address=address, functions=FUNCTIONS)
        for start, end, point, heights, flags, slopes in scenarios:
            height = expected(heights[plane], flags[plane], slopes[plane], start, end, point)
            for body in (code, linked[address:address + 261]):
                actual = execute(address, body, tail, start, end, point, heights, flags, slopes)
                assert actual == height & 0xffffffff, (symbol, start, end, point, actual, height)
    print('PASS: 522 exact bytes, 28 LE pointers, 12 slope scenarios for original and compiled code')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
