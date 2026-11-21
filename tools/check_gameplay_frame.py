"""Compare gameplay-frame behavior with the pinned original instructions."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
from struct import calcsize, pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import pointer_range, read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations,
)

ENTRY, RAW, SIZE, LE_SITES = 0x2d23e, 0x5283e, 732, 64
STACK, STOP = 0x3ff000, 0x3fff00
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)

# Set up and observe the original layout independently of the candidate's bindings.
ORIGINAL_DATA = {
    'network_enabled': 0x3c98,
    'view_state_3ccb': 0x3ccb,
    'frame_state_3cd6': 0x3cd6,
    'event_write_index': 0x3cdc,
    'player_count': 0x13ce0,
    'event_queue': 0x1f7fc,
    'board_state_209fc': 0x209fc,
    'projectile_positions': 0x20a2c,
    'board_state_2ca2c': 0x2ca2c,
    'board_state_2ca6c': 0x2ca6c,
    'board_state_2caac': 0x2caac,
    'board_state_2caec': 0x2caec,
    'board_state_2cb2c': 0x2cb2c,
    'frame_state_2db6c': 0x2db6c,
    'input_history': 0x55bbc,
    'board_state_5ac8c': 0x5ac8c,
    'previous_player_sector': 0x5acdc,
    'player_sector': 0x5acfc,
    'player_z': 0x5ad1c,
    'player_y': 0x5ad5c,
    'player_x': 0x5ad9c,
    'board_state_5ae1c': 0x5ae1c,
    'player_horizon': 0x62f8c,
    'player_angle': 0x6308c,
    'actor_clock': 0x770b8,
    'input_read_index': 0x770cc,
    'recorded_frame_count': 0x770d0,
    'processed_frame_count': 0x770d4,
    'next_player': 0x18fd78,
    'first_player': 0x19028a,
    'next_sprite_stat': 0x1fbca0,
    'sprite': 0x2040a0,
    'hit_sprite_list_head': 0x28811c,
}
CALLS = {
    0x2a56e: 'update_board_environment',
    0x2b3ed: 'update_player_motion',
    0x2eeae: 'do_animations',
    0x2f035: 'rotate_network_lead_player',
    0x33c3f: 'checksum_gameplay_state',
    0x34589: 'update_interpolations',
}


def exercise(memory, body, case):
    players, network, read_index, recording_mode, recorded_count, frame_count, mask = case
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def write(name, data, offset=0):
        cpu.mem_write(DS + ORIGINAL_DATA[name] + offset, data)

    def put(name, fmt, value):
        write(name, pack('<' + fmt, value))

    def get(name, fmt):
        fmt = '<' + fmt
        return unpack(fmt, cpu.mem_read(DS + ORIGINAL_DATA[name], calcsize(fmt)))[0]

    put('processed_frame_count', 'I', frame_count)
    put('actor_clock', 'I', 0xfffffffe)
    put('first_player', 'h', players[0] if players else -1)
    put('player_count', 'h', len(players))
    links = [-1] * 16
    for player, next_player in zip(players, players[1:]):
        links[player] = next_player
    write('next_player', pack('<16h', *links))
    put('input_read_index', 'I', read_index)
    put('event_write_index', 'I', 255)
    put('network_enabled', 'B', network)
    write('input_history', bytes((index * 37 + 19) & 255 for index in range(256 * 80)))
    write('board_state_5ac8c', b'\xa5' * 80)
    put('frame_state_3cd6', 'i', recording_mode)
    put('recorded_frame_count', 'i', recorded_count)
    write('frame_state_2db6c', b'\xb9' * (16384 * 10))
    write('event_queue', b'\xc7' * 512)

    for name, offset in (
        ('player_x', 101), ('player_y', -202), ('player_z', 303),
        ('player_horizon', -404), ('board_state_5ae1c', 505),
    ):
        write(name, pack('<16i', *(offset + index * 100003 for index in range(16))))
    for name in ('board_state_2caac', 'board_state_2caec', 'board_state_2ca6c',
                 'board_state_2ca2c', 'board_state_2cb2c'):
        write(name, b'\xd8' * 64)
    for name in ('player_angle', 'player_sector'):
        write(name, pack('<16h', *(-1000 + index * 77 for index in range(16))))
    for name in ('board_state_209fc', 'previous_player_sector'):
        write(name, b'\xe9' * 32)

    write('projectile_positions', b'\xfa' * (4096 * 12))
    write('next_sprite_stat', b'\xff' * (4096 * 2))
    heads = [-1] * 11
    heads[5], heads[10] = 4095, 0
    write('hit_sprite_list_head', pack('<11h', *heads))
    write('next_sprite_stat', pack('<h', 7))
    write('view_state_3ccb', pack('<11b', *([-1] * 5 + [mask] + [-1] * 4 + [mask])))
    for sprite in (0, 7, 4095):
        write('sprite', pack('<iii', sprite * 101, -sprite * 203, sprite * 307), sprite * 44)

    trace = []

    def hook(engine, address, size, data):
        name = CALLS.get(address)
        if name is None:
            return
        arguments = ()
        result = 0
        if name == 'checksum_gameplay_state':
            current_input = bytes(engine.mem_read(DS + ORIGINAL_DATA['board_state_5ac8c'], 80))
            arguments = (get('input_read_index', 'I'), get('processed_frame_count', 'I'),
                         current_input.hex())
            result = 0x89abcdef
        elif name == 'update_player_motion':
            player = engine.reg_read(UC_X86_REG_EAX)
            assert player in players
            arguments = (player, get('actor_clock', 'I'))
            write('player_x', pack('<i', 777777 + player), player * 4)
        trace.append((name, arguments))
        sp = engine.reg_read(UC_X86_REG_ESP)
        target = unpack('<I', engine.mem_read(sp, 4))[0]
        engine.reg_write(UC_X86_REG_EAX, result)
        engine.reg_write(UC_X86_REG_ESP, sp + 4)
        engine.reg_write(UC_X86_REG_EIP, target)

    cpu.hook_add(UC_HOOK_CODE, hook)
    for index, register in enumerate(SAVED):
        cpu.reg_write(register, 0xabcd1230 + index)
    cpu.reg_write(UC_X86_REG_EAX, 0xdead1234)
    sentinel = b'\x5a' * 16
    cpu.mem_write(STACK, pack('<I', STOP) + sentinel)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(ENTRY, STOP, count=30000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert bytes(cpu.mem_read(STACK + 4, 16)) == sentinel
    assert all(cpu.reg_read(register) == 0xabcd1230 + index
               for index, register in enumerate(SAVED))
    return trace, bytes(cpu.mem_read(DS, len(memory) - DS - 0x10000))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    executable = args.executable.read_bytes()
    assert hashlib.sha256(executable).hexdigest() == TARGET_SHA256
    pointers = read_le_fixups(executable)['pointers']
    assert len(pointer_range(pointers, ENTRY, SIZE)) == LE_SITES
    obj = args.object.read_bytes()
    raw, bindings = bind_leaf_details(obj, 'process_gameplay_frame_',
                                      DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(raw) == SIZE and raw == executable[RAW:RAW + SIZE]
    verify_leaf_relocations(raw, bindings, pointers, ENTRY)

    memory = image(executable)
    original = memory[ENTRY:ENTRY + SIZE]
    loaded_data = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    body, _ = bind_leaf_details(obj, 'process_gameplay_frame_',
                                loaded_data, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert body == original
    scenarios = list(itertools.product(
        ((), (0,), (0, 1), (0, 3, 1, 15)),
        (0, 1), (0, 255), (0, 1), (0, 16383), (0, 0xffffffff), (-1, 0, 1, 3, 127),
    ))
    for index, case in enumerate(scenarios):
        expected, actual = exercise(memory, original, case), exercise(memory, body, case)
        assert actual == expected, (index, case, expected[0], actual[0], expected[1] == actual[1])
    print(json.dumps({'bytes': SIZE, 'le_sites': LE_SITES, 'cases': len(scenarios),
                      'original_and_candidate': 'passed'}))


if __name__ == '__main__':
    main()
