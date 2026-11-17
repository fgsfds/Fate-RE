"""Verify the original and Watcom C sprite sequence state transitions."""
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

ENTRY, SIZE, DATA_BASE = 0x10433, 477, 0x80000
MOVE_ACTOR, UPDATE_SECTOR, SET_SPRITE = 0x196b2, 0x542c4, 0x506f6
TABLE, STACK, STOP = 0x320000, 0x3f0000, 0x3ff000
OFFSETS = {
    '_sequence_actor_sprite': 0x7dab8, '_sequence_actor_sector': 0x7d2e4,
    '_sequence_tile_height': 0x1f4020, '_sequence_actor_x': 0x799e8,
    '_sequence_actor_y': 0x7a1bc, '_sequence_actor_z_offset': 0x79214,
    '_actor_kind': 0x7f0a0, '_sequence_actor_state': 0x7e2ed,
    '_sequence_actor_flag': 0x7f67f, '_sequence_actor_first': 0x7e4e2,
    '_sequence_actor_frame': 0x7e6d7, '_sequence_sprite_tile': 0x2040ae,
    '_advance_clock': 0x229b, '_sequence_sprite_yrepeat': 0x2040b5, '_sector_floor_z': 0x27c3a8,
}
FUNCTIONS = {'move_actor_': MOVE_ACTOR, 'updatesector_': UPDATE_SECTOR, 'setsprite_': SET_SPRITE}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
ACTOR, SPRITE, SECTOR = 3, 7, 4
ANCHOR, BASE, TURN = (-100, 300), (1222, -1555), (333, -572)
TILES = (8, 100, 200, 300, 400, -1)
SAVED = dict(zip((UC_X86_REG_EBP, UC_X86_REG_ESI, UC_X86_REG_EDI),
                 (0xaa550001, 0xaa550002, 0xaa550003)))


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, kind, state, frame, clock, movement_kind):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    calls = []

    def write(field, fmt, value, index=0):
        cpu.mem_write(DATA[field] + index, pack(fmt, value))

    def read(field, fmt, index=0):
        width = len(pack(fmt, 0))
        return unpack(fmt, cpu.mem_read(DATA[field] + index, width))[0]

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx = (signed(machine.reg_read(register)) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if address == UPDATE_SECTOR:
            assert ebx == DATA['_sequence_actor_sector'] + 2 * ACTOR
            calls.append(('sector', eax, edx))
            write('_sequence_actor_sector', '<h', 5, 2 * ACTOR)
        elif address == MOVE_ACTOR:
            esp = machine.reg_read(UC_X86_REG_ESP)
            outgoing = unpack('<ii', machine.mem_read(esp + 4, 8))
            calls.append(('move', eax, edx, ebx, ecx, *outgoing))
            write('_actor_kind', '<B', movement_kind, ACTOR)
        elif address == SET_SPRITE:
            calls.append(('position', eax, edx, ebx, ecx))

    for address, instruction in ((UPDATE_SECTOR, b'\xc3'), (MOVE_ACTOR, b'\xc2\x08\x00'),
                                 (SET_SPRITE, b'\xc3')):
        cpu.mem_write(address, instruction)
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    write('_sequence_actor_sprite', '<h', SPRITE, 2 * ACTOR)
    write('_sequence_actor_sector', '<h', SECTOR, 2 * ACTOR)
    write('_sequence_actor_x', '<i', ANCHOR[0], 4 * ACTOR)
    write('_sequence_actor_y', '<i', ANCHOR[1], 4 * ACTOR)
    write('_sequence_actor_z_offset', '<i', 500, 4 * ACTOR)
    write('_sequence_actor_state', '<B', state, ACTOR)
    write('_sequence_actor_flag', '<B', 73, ACTOR)
    write('_sequence_actor_first', '<B', 66, ACTOR)
    write('_sequence_actor_frame', '<B', frame, ACTOR)
    write('_actor_kind', '<B', kind, ACTOR)
    write('_sequence_tile_height', '<h', 20, 2 * TILES[1])
    write('_sequence_sprite_yrepeat', '<B', 10, 44 * SPRITE)
    write('_sequence_sprite_tile', '<h', 1900, 44 * SPRITE)
    write('_sector_floor_z', '<i', 2500, 40 * SECTOR)
    write('_advance_clock', '<h', clock)

    incoming = {
        UC_X86_REG_EAX: 0xdadd0000 | ACTOR, UC_X86_REG_EDX: BASE[0], UC_X86_REG_EBX: BASE[1],
        UC_X86_REG_ECX: TURN[0], UC_X86_REG_ESP: STACK, **SAVED,
    }
    for register, value in incoming.items():
        cpu.reg_write(register, value & 0xffffffff)
    cpu.mem_write(TABLE, pack('<6h', *TILES))
    cpu.mem_write(STACK, pack('<IiI', STOP, TURN[1], TABLE) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=800)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 12
    assert cpu.mem_read(STACK + 12, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())

    setup = (read('_sequence_actor_flag', '<B', ACTOR), read('_sequence_actor_first', '<B', ACTOR),
             read('_sequence_actor_sector', '<h', 2 * ACTOR), read('_sequence_actor_x', '<i', 4 * ACTOR),
             read('_sequence_actor_y', '<i', 4 * ACTOR))
    state = read('_sequence_actor_state', '<B', ACTOR)
    frame = read('_sequence_actor_frame', '<B', ACTOR)
    tile = read('_sequence_sprite_tile', '<h', 44 * SPRITE)
    return state, frame, tile, setup, calls


def check(executable, obj):
    name = 'update_sprite_sequence_state_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 34
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]

    setup = (73, 66, SECTOR, *ANCHOR)
    movement = [('move', ACTOR, *ANCHOR, SECTOR, *TURN)]
    position = [*movement, ('position', SPRITE, *ANCHOR, 2600)]
    cases = (
        ((3, 2, 3, 1, 0), (2, 3, 1900, setup, [])),
        ((4, 2, 3, 1, 0), (2, 3, 200, setup, [])),
        ((5, 2, 3, 1, 0), (2, 3, 200, setup, [])),
        ((0, 0, 3, 0, 0), (1, 3, 1900, (0, TILES[0], 5, *BASE), [('sector', *BASE)])),
        ((0, 1, 3, 1, 1), (1, 3, 100, setup, movement)),
        ((0, 1, 1, 0, 0), (1, 1, 100, setup, position)),
        ((0, 1, 1, 1, 0), (2, 3, 300, setup, position)),
        ((0, 2, 3, 0, 0), (2, 3, 1900, setup, [])),
        ((0, 2, 3, 1, 0), (2, 4, 400, setup, [])),
        ((0, 2, 4, 1, 0), (3, 5, 1900, setup, [])),
        ((0, 2, 255, 1, 0), (2, 0, 8, setup, [])),
        ((0, 3, 5, 1, 0), (0, 5, 1900, setup, [])),
        ((0, 6, 5, 1, 0), (6, 5, 1900, setup, [])),
    )
    for args, expected in cases:
        for body in (original, code):
            result = exercise(body, *args)
            assert result == expected, (args, result, expected)
    print('PASS: 477 exact bytes, 34 LE pointers, 13 sequence scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
