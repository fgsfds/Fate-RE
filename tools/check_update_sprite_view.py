"""Check temporary sprite directional frames, interpolation, and sector shade."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

SYMBOL = 'update_sprite_view_'
TILES, DISPATCH, ENTRY = 0x2a1ef, 0x2a257, 0x2a32b
SIZE, BASE = 579, 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
ANGLE, DIRECTIONAL, ORDINARY = 0x4c94c, 0x2a35e, 0x2a3df
PRESERVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSETS = {
    '_temporary_view_sprites': 0x2710a0, '_view_tile_animation_flags': 0x1ed3a0,
    '_view_interpolation_modes': 0x3ccb, '_view_previous_positions': 0x20a2c,
    '_view_interpolation_fraction': 0x770bc, '_view_interpolation_clock': 0x770d4,
    '_view_sprite_count': 0x287e84, '_view_sector_ceiling_flags': 0x27c3ac,
    '_view_sector_ceiling_shade': 0x27c3b4, '_view_sector_floor_shade': 0x27c3bc,
}
DATA = {name: BASE + offset for name, offset in OFFSETS.items()}
TABLES = {'_directional_sprite_tiles': TILES, '_sprite_view_dispatch': DISPATCH}
FUNCTIONS = {'getangle_': ANGLE}
CAMERA, CURRENT, PRIOR = (25, 40), (100, -20, 200), (-300, 120, 200)
OWNER, SECTOR, FRACTION, CLOCK = 7, 4, 32768, 18


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, tables, count, tile, angle_value, status, mode, ceiling):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(TILES, tables)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(ANGLE, b'\xc3')
    sprite = DATA['_temporary_view_sprites']
    start = pack('<iiiHHb7B4h6h', *CURRENT, 0x107, tile, -12, 2, 10, 0, 22, 24, 0, 0,
                 SECTOR, status, 128, OWNER, 0, 0, 0, 0, 0, 0)
    cpu.mem_write(sprite, start)
    cpu.mem_write(sprite + 44, b'\xa5' * 44)

    def put(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    put('_view_sprite_count', '<i', count)
    put('_view_tile_animation_flags', '<I', 0x45, 4 * tile)
    put('_view_interpolation_modes', '<b', mode, status)
    put('_view_interpolation_fraction', '<i', FRACTION)
    put('_view_interpolation_clock', '<i', CLOCK)
    put('_view_sector_ceiling_flags', '<h', 0x4400 | ceiling, 40 * SECTOR)
    put('_view_sector_ceiling_shade', '<b', 6, 40 * SECTOR)
    put('_view_sector_floor_shade', '<b', -7, 40 * SECTOR)
    cpu.mem_write(DATA['_view_previous_positions'] + 12 * OWNER, pack('<iii', *PRIOR))
    angles = []

    def find_angle(machine, _address, _size, _data):
        angles.append(tuple(signed(machine.reg_read(reg)) for reg in (UC_X86_REG_EAX, UC_X86_REG_EDX)))
        assert angle_value is not None
        machine.reg_write(UC_X86_REG_EAX, angle_value)

    cpu.hook_add(UC_HOOK_CODE, find_angle, begin=ANGLE, end=ANGLE)
    for reg, value in ((UC_X86_REG_EAX, CAMERA[0]), (UC_X86_REG_EDX, CAMERA[1]), (UC_X86_REG_ESP, STACK)):
        cpu.reg_write(reg, value)
    for i, reg in enumerate(PRESERVED, 1):
        cpu.reg_write(reg, 0x88880000 | i)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=3000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, reg in enumerate(PRESERVED, 1):
        assert cpu.reg_read(reg) == 0x88880000 | i
    assert cpu.mem_read(sprite + 44, 44) == b'\xa5' * 44
    actual = bytes(cpu.mem_read(sprite, 44))
    if not count:
        assert actual == start and angles == []
        return

    expected = bytearray(start)
    cstat = 0x107
    if angle_value is not None:
        assert angles == [(CURRENT[0] - CAMERA[0], CURRENT[1] - CAMERA[1])]
        direction = ((128 + 3200 - angle_value) & 0x7ff) >> 8
        mirrored = direction > 4
        if mirrored:
            direction = 8 - direction
        cstat = (cstat | 4) if mirrored else (cstat & ~4)
        expected[14:16] = pack('<H', tile + direction * 6)
    else:
        assert angles == []
    position = CURRENT
    if mode >= 0:
        shift = (mode + 1).bit_length() - 1
        numerator = (FRACTION >> shift) + (((CLOCK - OWNER) & mode) << (16 - shift))
        position = tuple(old + (((new - old) * numerator) >> 16) for old, new in zip(PRIOR, CURRENT))
    expected[0:12] = pack('<iii', *position)
    if status in (3, 4, 5, 7) and all(abs(a - b) < 256 for a, b in zip(position[:2], CAMERA)):
        cstat &= ~2
    expected[12:14] = pack('<H', cstat)
    expected[16:17] = pack('<b', -12 + 6 + (6 if ceiling else -7))
    assert actual == bytes(expected), (unpack('<iiiHHb', actual[:17]), unpack('<iiiHHb', expected[:17]))


def check(executable, obj, tables):
    raw = TILES + 0x25600
    assert len(tables) == ENTRY - TILES and tables == executable[raw:raw + len(tables)]
    pointers = read_le_fixups(executable)['pointers']
    destinations = (ORDINARY, *([DIRECTIONAL] * 52))
    assert tuple(pointers[DISPATCH + i * 4] for i in range(53)) == destinations
    assert unpack('<53I', tables[DISPATCH - TILES:]) == tuple(target - 0x10000 for target in destinations)
    code_refs = {}
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSETS, address=ENTRY, functions=FUNCTIONS,
                                   absolute_code={name: value - 0x10000 for name, value in TABLES.items()},
                                   code_bindings=code_refs)
    raw = ENTRY + 0x25600
    assert len(refs) == 16 and len(code_refs) == 2 and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, pointers, ENTRY, code_bindings=code_refs)
    linked, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=FUNCTIONS,
                                  absolute_code=TABLES, code_bindings={})
    mapped = image(executable)
    original = bytes(mapped[ENTRY:ENTRY + SIZE])
    loaded_tables = bytes(mapped[TILES:ENTRY])
    cases = (
        (0, 2767, None, 0, -1, False),
        (1, 120, None, 3, -1, True),
        (1, 2767, 512, 0, -1, False),
        (1, 165, 1792, 3, -1, True),
        *((1, 120, None, 4, mode, False) for mode in (0, 1, 3, 7, 15)),
    )
    for body in (original, linked):
        for inputs in cases:
            exercise(body, loaded_tables, *inputs)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, 53 retained dispatch targets, {len(cases)} view scenarios')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('tables', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes(), args.tables.read_bytes())
