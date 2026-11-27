"""Verify the Fate projectile hit routine and exercise its actor, player, and item paths."""
import argparse
from pathlib import Path
from struct import pack, unpack

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

ENTRY, SIZE, DATA_BASE = 0x13115, 290, 0x80000
ADJUST_STATUS, START_SEQUENCE = 0x1092e, 0x11fdd
STACK, STOP = 0x3f0000, 0x3ff000
OFFSET = {
    '_hit_sprite_lotag': 0x2040c6, '_hit_actor_index': 0x709dc,
    '_hit_actor_health': 0x7cefa, '_hit_sprite_sector': 0x2040b8,
    '_hit_sprite_cstat': 0x2040ac, '_hit_sprite_owner': 0x2040be,
    '_player_sprite': 0x62f2c, '_held_item': 0x2bf6, '_holding_sprite': 0x2bfa,
    '_hit_sprite_tile': 0x2040ae, '_hit_sprite_z': 0x2040a8, '_sector_floor_z': 0x27c3a8,
    '_hit_sprite_xrepeat': 0x2040b2, '_actor_kind': 0x7f0a0,
}
LOADED = {name: DATA_BASE + offset for name, offset in OFFSET.items()}
FUNCTIONS = {'adjust_status_value_': ADJUST_STATUS, 'start_sequence_': START_SEQUENCE}
VICTIM, PROJECTILE, ACTOR, SECTOR, TILE = 7, 8, 4, 3, 1942


def exercise(body, tag, owner, target, health, damage, held):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(ENTRY, body)
    machine.mem_write(ADJUST_STATUS, b'\xc3')
    machine.mem_write(START_SEQUENCE, b'\xc3')
    calls = []

    def record_call(cpu, address, _size, _data):
        argument = cpu.reg_read(UC_X86_REG_EAX)
        if argument & 0x80000000:
            argument -= 0x100000000
        calls.append((address, argument))
        cpu.reg_write(UC_X86_REG_EAX, 0x12345678)

    for address in (ADJUST_STATUS, START_SEQUENCE):
        machine.hook_add(UC_HOOK_CODE, record_call, begin=address, end=address)

    def write(field, fmt, value, index=0):
        machine.mem_write(LOADED[field] + index, pack(fmt, value))

    def read(field, fmt, index=0):
        width = len(pack(fmt, 0))
        return unpack(fmt, machine.mem_read(LOADED[field] + index, width))[0]

    write('_hit_sprite_lotag', '<H', tag, 44 * PROJECTILE)
    write('_hit_sprite_owner', '<h', owner, 44 * PROJECTILE)
    write('_hit_actor_index', '<h', ACTOR if target == 'actor' else -1, 2 * VICTIM)
    write('_hit_actor_health', '<h', health, 2 * ACTOR)
    write('_actor_kind', '<B', 9, ACTOR)
    write('_player_sprite', '<h', VICTIM if target == 'player' else -1)
    write('_held_item', '<h', held)
    write('_holding_sprite', '<h', 31)
    write('_hit_sprite_tile', '<h', TILE, 44 * VICTIM)
    write('_hit_sprite_sector', '<h', SECTOR, 44 * VICTIM)
    write('_hit_sprite_z', '<i', -100, 44 * VICTIM)
    write('_sector_floor_z', '<i', 17777, 40 * SECTOR)
    write('_hit_sprite_cstat', '<H', 0xaa55, 44 * VICTIM)
    write('_hit_sprite_xrepeat', '<B', 193, 44 * VICTIM)

    saved = {
        UC_X86_REG_EBX: 0xabcd0001,
        UC_X86_REG_ECX: damage & 0xffffffff,
        UC_X86_REG_ESI: 0xabcd0002,
        UC_X86_REG_EDI: 0xabcd0003,
        UC_X86_REG_EBP: 0xabcd0004,
    }
    for register, value in saved.items():
        machine.reg_write(register, value)
    machine.reg_write(UC_X86_REG_EAX, 0xface0000 | VICTIM)
    machine.reg_write(UC_X86_REG_EDX, 0xcafe0000 | PROJECTILE)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    machine.emu_start(ENTRY, STOP, count=500)
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert machine.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(machine.reg_read(register) == value for register, value in saved.items())
    return (
        read('_hit_actor_health', '<h', 2 * ACTOR), read('_actor_kind', '<B', ACTOR),
        read('_hit_sprite_z', '<i', 44 * VICTIM), read('_hit_sprite_cstat', '<H', 44 * VICTIM),
        read('_hit_sprite_xrepeat', '<B', 44 * VICTIM), read('_held_item', '<h'),
        read('_holding_sprite', '<h'), calls,
    )


def check(executable, obj):
    code, refs = bind_leaf_details(obj, 'apply_projectile_hit_', OFFSET, address=ENTRY,
                                   functions=FUNCTIONS)
    raw_offset = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw_offset:raw_offset + SIZE]
    assert len(refs) == 19
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, 'apply_projectile_hit_', LOADED, address=ENTRY,
                                functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]
    sprite = (-100, 0xaa55, 193)
    sequence = (START_SEQUENCE, VICTIM)
    cases = (
        ((0x100, 1, 'actor', 300, -17, TILE), (100, 5, *sprite, TILE, 31, [])),
        ((0xa00, 0, 'actor', 300, -17, TILE), (175, 4, *sprite, TILE, 31, [])),
        ((0x102, 1, 'actor', 300, -35, TILE), (265, 5, *sprite, TILE, 31, [])),
        ((0x3000, 1, 'actor', 100, -17, TILE), (-200, 3, 17777, 0, 130, TILE, 31, [sequence])),
        ((0x4200, 0, 'player', 100, -17, TILE),
         (100, 9, *sprite, TILE, 31, [(ADJUST_STATUS, -25), sequence])),
        ((0x4400, 0, 'item', 100, -17, TILE), (100, 9, *sprite, 0, 0, [sequence])),
        ((0x3001, 0, 'item', 100, -17, TILE + 1), (100, 9, *sprite, TILE + 1, 31, [sequence])),
    )
    for arguments, expected in cases:
        for body in (original, code):
            assert exercise(body, *arguments) == expected, arguments
    print('PASS: 290 exact bytes, 19 LE pointers, seven projectile scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
