"""Verify Board 5's trigger sectors, animation delay, and actor movement staging."""
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

ENTRY, SIZE, DATA_BASE = 0x1e41d, 435, 0x80000
SOUND, SEQUENCE, UPDATE_SECTOR, MOVE = 0x34f79, 0x11fdd, 0x542c4, 0x196b2
STACK, STOP = 0x3f0000, 0x3ff000
OFFSETS = {
    '_board5_actor_steps': 0x851b0, '_board5_actors': 0x12818, '_board5_script_sprites': 0x7494e,
    '_player_sector': 0x5acfc, '_advance_clock': 0x229b, '_sequence_actor_sector': 0x7d2e4,
    '_sequence_actor_sprite': 0x7dab8, '_hit_sprite_lotag': 0x2040c6, '_sequence_sprite_tile': 0x2040ae,
    '_board5_target_x': 0x12820, '_board5_target_y': 0x12824, '_player_x': 0x5ad9c, '_player_y': 0x5ad5c,
    '_actor_kind': 0x7f0a0, '_sequence_actor_flag': 0x7f67f, '_saved_actor_lotag': 0x7d6ce,
}
FUNCTIONS = {'play_sound_': SOUND, 'start_sequence_': SEQUENCE, 'updatesector_': UPDATE_SECTOR,
             'move_actor_': MOVE}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
SAVED = {
    register: 0xbada0000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}
ACTORS = (5, 9, 12, 18)
ACTOR_SPRITES = (80, 81, 82, 83)
SEQUENCE_SPRITES = (121, 122, 123, 124)
TARGETS = ((550, -600), (-800, 1100), (1400, -2320), (-3681, -4671))
SECTORS = (31, -4, 76, 5)
OLD_SECTOR, OLD_TILE, OLD_TAG, OLD_SAVED, OLD_MODE = 320, 444, 0xa812, 0x4d82, 89
PLAYER = (477, -810)


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, sector, clock, steps, kinds, movement_results):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    events = []

    def write(name, fmt, value, offset=0):
        cpu.mem_write(DATA[name] + offset, pack(fmt, value))

    def read(name, fmt, offset=0):
        width = len(pack(fmt, 0))
        return unpack(fmt, cpu.mem_read(DATA[name] + offset, width))[0]

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx = (signed(machine.reg_read(register)) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if address == SOUND:
            assert tuple(read('_board5_actor_steps', '<h', 2 * slot) for slot in range(4)) == (1,) * 4
            events.append(('sound', eax, edx, ebx, ecx))
        elif address == SEQUENCE:
            assert read('_hit_sprite_lotag', '<H', 44 * eax) == 0x4400
            events.append(('sequence', eax))
        elif address == UPDATE_SECTOR:
            actor = (ebx - DATA['_sequence_actor_sector']) // 2
            slot = ACTORS.index(actor)
            assert read('_sequence_sprite_tile', '<h', 44 * ACTOR_SPRITES[slot]) == 0x91b
            assert read('_hit_sprite_lotag', '<H', 44 * ACTOR_SPRITES[slot]) == OLD_TAG | 0x65
            assert read('_saved_actor_lotag', '<H', 2 * actor) == OLD_SAVED | 0x65
            events.append(('sector', actor, eax, edx))
            write('_sequence_actor_sector', '<h', SECTORS[slot], 2 * actor)
        elif address == MOVE:
            outgoing = unpack('<ii', machine.mem_read(machine.reg_read(UC_X86_REG_ESP) + 4, 8))
            events.append(('move', eax, edx, ebx, ecx, *outgoing))
            write('_actor_kind', '<B', movement_results[ACTORS.index(eax)], eax)

    for address, instruction in ((SOUND, b'\xc3'), (SEQUENCE, b'\xc3'), (UPDATE_SECTOR, b'\xc3'),
                                 (MOVE, b'\xc2\x08\x00')):
        cpu.mem_write(address, instruction)
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    write('_player_sector', '<h', sector)
    write('_advance_clock', '<h', clock)
    write('_player_x', '<i', PLAYER[0])
    write('_player_y', '<i', PLAYER[1])
    for slot, actor in enumerate(ACTORS):
        write('_board5_actors', '<h', actor, 2 * slot)
        write('_board5_actor_steps', '<h', steps[slot], 2 * slot)
        write('_board5_script_sprites', '<h', SEQUENCE_SPRITES[slot], 2 * slot)
        write('_board5_target_x', '<i', TARGETS[slot][0], 8 * slot)
        write('_board5_target_y', '<i', TARGETS[slot][1], 8 * slot)
        write('_sequence_actor_sector', '<h', OLD_SECTOR, 2 * actor)
        write('_sequence_actor_sprite', '<h', ACTOR_SPRITES[slot], 2 * actor)
        write('_actor_kind', '<B', kinds[slot], actor)
        write('_sequence_actor_flag', '<B', OLD_MODE, actor)
        write('_saved_actor_lotag', '<H', OLD_SAVED, 2 * actor)
        write('_hit_sprite_lotag', '<H', OLD_TAG, 44 * ACTOR_SPRITES[slot])
        write('_hit_sprite_lotag', '<H', OLD_TAG, 44 * SEQUENCE_SPRITES[slot])
        write('_sequence_sprite_tile', '<h', OLD_TILE, 44 * ACTOR_SPRITES[slot])

    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=1500)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    return [
        (read('_board5_actor_steps', '<h', 2 * slot), read('_sequence_actor_flag', '<B', actor),
         read('_sequence_actor_sector', '<h', 2 * actor), read('_saved_actor_lotag', '<H', 2 * actor),
         read('_hit_sprite_lotag', '<H', 44 * ACTOR_SPRITES[slot]),
         read('_hit_sprite_lotag', '<H', 44 * SEQUENCE_SPRITES[slot]),
         read('_sequence_sprite_tile', '<h', 44 * ACTOR_SPRITES[slot]))
        for slot, actor in enumerate(ACTORS)
    ], events


def expected(sector, clock, steps, kinds, movement_results):
    events, state = [], []
    if steps[0] == 0 and sector in (0xec, 0xed, 0xee):
        steps = (1,) * 4
        events.append(('sound', 142, 0, 0, 0))
    for slot, (actor, kind, step) in enumerate(zip(ACTORS, kinds, steps)):
        mode, sector, saved, tag, sequence_tag, tile = OLD_MODE, OLD_SECTOR, OLD_SAVED, OLD_TAG, OLD_TAG, OLD_TILE
        if kind != 3:
            if step == 1:
                step, sequence_tag = 2, 0x4400
                events.append(('sequence', SEQUENCE_SPRITES[slot]))
            elif 2 <= step <= 7 and clock:
                step += 1
            elif step == 8:
                sector, saved, tag, tile = SECTORS[slot], saved | 0x65, tag | 0x65, 0x91b
                events.extend([('sector', actor, *TARGETS[slot]),
                               ('move', actor, *TARGETS[slot], sector, *PLAYER)])
                if movement_results[slot] == 0:
                    step, mode = 9, 2
        state.append((step, mode, sector, saved, tag, sequence_tag, tile))
    return state, events


def check(executable, obj):
    name = 'update_board_5_script_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 32
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]
    empty = (0,) * 4
    cases = (
        (0xec, 0, empty, empty, empty), (0xed, 1, empty, (3, 0, 0, 3), empty),
        (0xee, 2, empty, empty, empty), (0xeb, 1, empty, empty, empty),
        (0xef, 1, (1, 2, 7, 8), (0, 0, 0, 0), (0, 0, 0, 1)),
        (0xed, 0, (2, 3, 6, 7), empty, empty),
        (0xec, -1, (2, 3, 6, 7), (3, 0, 3, 0), empty),
        (-1, 1, (8, 8, 8, 8), (0, 3, 0, 0), (0, 0, 1, 0)),
        (0xef, 0, (9, -1, 8, 0), (0, 0, 1, 0), (1, 1, 0, 1)),
    )
    for args in cases:
        for body in (original, code):
            outcome = exercise(body, *args)
            assert outcome == expected(*args), (args, outcome, expected(*args))
    print(f'PASS: 435 exact bytes, 32 LE pointers, {len(cases)} Board 5 scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
