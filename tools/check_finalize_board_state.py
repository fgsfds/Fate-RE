"""Verify board visibility traversal and tile preloading with a two-sector board."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE, BASE = 0x34211, 723, 0x80000
SYMBOL = 'finalize_board_state_'
STACK, STOP, LOADTILE = 0x3e0000, 0x3ff000, 0x4bb0d
REGISTERS = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSETS = {
    '_numsectors': 0x289154, '_final_player_sprite': 0x62f2c,
    '_final_sector_seed': 0x1d12c, '_final_sector_queue': 0x1d12a,
    '_final_wall_first': 0x27c3a0, '_final_wall_count': 0x27c3a2,
    '_final_sector_lotag': 0x27c3c2, '_final_ceiling_tile': 0x27c3b0, '_final_floor_tile': 0x27c3b8,
    '_final_wall_tile': 0x2310b0, '_final_wall_overlay': 0x2310b2, '_final_wall_lotag': 0x2310ba,
    '_final_tile_cache': 0x1ffca0, '_final_sectors_before': 0x1ec69f, '_final_walls_before': 0x1ec91f,
    '_final_sprites_before': 0x1ecf9f, '_final_sectors_visible': 0x1ec6a0, '_final_walls_visible': 0x1ec920,
    '_final_sprites_visible': 0x1ecfa0, '_final_visibility_dirty': 0x2891d8, '_final_walls': 0x2310a0,
}
DATA = {name: BASE + offset for name, offset in OFFSETS.items()}
CALLS = {'loadtile_': LOADTILE}
MASKS = {'_final_sectors_visible': 128, '_final_walls_visible': 1024, '_final_sprites_visible': 512}
PLAYER_OFFSET = 17 // 8


def exercise(body, sector, hidden):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)

    def put(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    put('_numsectors', '<h', 2)
    put('_final_player_sprite', '<h', 17)
    put('_final_visibility_dirty', '<B', 0xff)
    cpu.mem_write(DATA['_final_sector_seed'], pack('<3h', -1, -1, -1))
    for field, length in MASKS.items():
        cpu.mem_write(DATA[field] - 1, b'\xa5' * (length + 2))
    for index, (start, count, ceiling, floor, lotag) in enumerate(
        ((5, 1 if hidden else 2, 10, 11, 99 if hidden else 0), (7, 1, 12, 13, 0))
    ):
        for field, value in (('wall_first', start), ('wall_count', count), ('ceiling_tile', ceiling),
                             ('floor_tile', floor), ('sector_lotag', lotag)):
            put('_final_' + field, '<h', value, 40 * index)
    for index, (neighbor, tile, overlay, lotag) in enumerate(
        ((1, 20, 21, 0), (1, 22, 0xf002, 99), (-1 if hidden else 0, 20, 23, 0)), 5
    ):
        put('_final_walls', '<h', neighbor, 32 * index + 12)
        put('_final_wall_tile', '<h', tile, 32 * index)
        put('_final_wall_overlay', '<H', overlay, 32 * index)
        put('_final_wall_lotag', '<h', lotag, 32 * index)
    for tile in (11, 23):
        put('_final_tile_cache', '<I', 1, 4 * tile)

    loads = []

    def load_tile(machine, _address, _size, _data):
        tile = machine.reg_read(UC_X86_REG_EAX)
        loads.append(tile)
        put('_final_tile_cache', '<I', 1, 4 * tile)

    cpu.mem_write(LOADTILE, b'\xc3')
    cpu.hook_add(UC_HOOK_CODE, load_tile, begin=LOADTILE, end=LOADTILE)
    cpu.reg_write(UC_X86_REG_EAX, 0x66660000 | (sector & 0xffff))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(REGISTERS, 1):
        cpu.reg_write(register, 0x88880000 | i)
    cpu.emu_start(ENTRY, STOP, count=10000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, register in enumerate(REGISTERS, 1):
        assert cpu.reg_read(register) == 0x88880000 | i

    queue = unpack('<3h', cpu.mem_read(DATA['_final_sector_seed'], 6))
    invalid = not 0 <= sector < 2
    assert queue == ((-1, -1, -1) if invalid else (0, 1, -1))
    assert cpu.mem_read(DATA['_final_visibility_dirty'], 1) == (b'\xff' if invalid else b'\0')
    expected_masks = {
        '_final_sectors_visible': (0, 0 if hidden else 3),
        '_final_walls_visible': (0, 0x80 if hidden else 0xa0),
        '_final_sprites_visible': (PLAYER_OFFSET, 0x41 if hidden else 0x81),
    }
    for field, length in MASKS.items():
        address = DATA[field]
        assert cpu.mem_read(address - 1, 1) == cpu.mem_read(address + length, 1) == b'\xa5'
        if invalid:
            expected = b'\xa5' * length
        else:
            expected = bytearray(length)
            offset, value = expected_masks[field]
            expected[offset] = value
        assert cpu.mem_read(address, length) == expected, field
    return loads


def check(executable, obj):
    raw = ENTRY + 0x25600
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSETS, address=ENTRY, functions=CALLS)
    assert len(refs) == 38 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLS)
    original = bytes(image(executable)[ENTRY:ENTRY + SIZE])
    cases = ((-1, False, []), (2, False, []),
             (0, False, [10, 20, 21, 12, 13, 22]), (0, True, [10, 20, 21, 12, 13]))
    for body in (original, relocated):
        for sector, hidden, expected in cases:
            assert exercise(body, sector, hidden) == expected, (sector, hidden)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} board visibility scenarios')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
