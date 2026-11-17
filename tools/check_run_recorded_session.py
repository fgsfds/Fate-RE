"""Check recorded playback, listener controls, and DOS shutdown sequencing."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INTR, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

SYMBOL = 'run_recorded_session_'
ENTRY, SIZE, BASE = 0x2e350, 475, 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
PLAYERS = (3, 1)
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSET = {
    '_playback_view_key': 0x3cab, '_playback_mode_key': 0x3caa, '_playback_timer_enabled': 0x3ce9,
    '_playback_pending_time': 0x3cd6, '_playback_last_tick': 0x3cea, '_playback_saved_clock': 0x3cee,
    '_playback_listener': 0x3cfa, '_playback_first_player': 0x19028a, '_playback_next_player': 0x18fd78,
    '_playback_actor_clock': 0x770b8, '_playback_frame_count': 0x770d0, '_totalclock': 0x287e88,
    '_playback_keys': 0x6793c, '_playback_player_mode': 0x62f1c, '_playback_board_name': 0x1e5ac,
    '_recorded_input_a': 0x2db6c, '_recorded_input_b': 0x2db6d, '_recorded_input_c': 0x2db6e,
    '_recorded_input_word': 0x2db6f, '_playback_input_a': 0x5ac3c, '_playback_input_b': 0x5ac3d,
    '_playback_input_c': 0x5ac3e, '_playback_input_word': 0x5ac3f, '_playback_quit': 0x6793d,
}
DATA = {name: BASE + offset for name, offset in OFFSET.items()}
CALLBACK = {
    'prepare_loaded_board_': 0x27a8c, 'initialize_board_entry_': 0x2e14f,
    'reset_playback_timer_': 0x4c0b0, 'snapshot_playback_input_': 0x2d1bd, 'process_playback_frame_': 0x2d23e,
    'render_playback_frame_': 0x2c48d, 'uninitmultiplayers_': 0x4164f, 'shutdown_step_b_': 0x34bf6,
    'shutdown_step_d_': 0x34860, 'shutdown_step_e_': 0x2f258, 'shutdown_engine_': 0x4b390,
    'uninitgroupfile_': 0x4124c, 'exit_': 0x60353,
}
SHUTDOWN = [('uninitmultiplayers_',), ('shutdown_step_b_',), ('shutdown_step_d_',),
            ('shutdown_step_e_',), ('shutdown_engine_',), ('uninitgroupfile_',),
            ('bios', 0x10, 3), ('exit', 0)]
RECORDS = ((b'\x01\x02\xff\x34\x12', b'\xbc\xde\xf0\x78\x56'),
           (b'\x19\x07\x08\xcc\xbb', b'\x20\x21\x22\xff\xfa'))


def exercise(body, tick, listener, *, quit_now=False, controls=False, mode=2):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(DATA['_recorded_input_a'], b''.join(b''.join(row) for row in RECORDS))

    def write(field, fmt, val, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, val))

    def read(field, fmt, offset=0):
        return unpack(fmt, cpu.mem_read(DATA[field] + offset, len(pack(fmt, 0))))[0]

    for field, fmt, val in (
        ('_playback_timer_enabled', '<B', 1), ('_playback_pending_time', '<i', 40),
        ('_playback_last_tick', '<i', 91), ('_playback_saved_clock', '<i', 92),
        ('_playback_first_player', '<h', PLAYERS[0]), ('_playback_listener', '<h', listener),
        ('_playback_actor_clock', '<i', 50), ('_totalclock', '<i', tick),
        ('_playback_frame_count', '<i', len(RECORDS)), ('_playback_quit', '<B', quit_now),
        ('_playback_view_key', '<B', 49), ('_playback_mode_key', '<B', 80),
    ):
        write(field, fmt, val)
    write('_playback_next_player', '<h', PLAYERS[1], 2 * PLAYERS[0])
    write('_playback_next_player', '<h', -1, 2 * PLAYERS[1])
    for key in (49, 80):
        write('_playback_keys', '<B', 1 if controls else 0, key)
    for player in PLAYERS:
        write('_playback_player_mode', '<B', mode, player)

    seen = []

    def hook(machine, _address, _size, name):
        eax = machine.reg_read(UC_X86_REG_EAX)
        edx = machine.reg_read(UC_X86_REG_EDX)
        if name == 'render_playback_frame_':
            seen.append(('render', eax, edx))
            write('_playback_quit', '<B', 1)
        elif name == 'process_playback_frame_':
            seen.append(('process',))
            write('_playback_actor_clock', '<i', read('_playback_actor_clock', '<i') + 3)
        elif name == 'snapshot_playback_input_':
            records = tuple(bytes(machine.mem_read(DATA['_playback_input_a'] + 5 * player, 5))
                            for player in PLAYERS)
            seen.append(('inputs', records))
        elif name == 'initialize_board_entry_':
            seen.append(('init', eax))
        elif name == 'prepare_loaded_board_':
            assert eax == DATA['_playback_board_name']
            seen.append(('reload',))
        elif name == 'exit_':
            seen.append(('exit', eax))
        else:
            seen.append((name,))

    for name, address in CALLBACK.items():
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, user_data=name, begin=address, end=address)

    def interrupt(machine, number, _data):
        seen.append(('bios', number, machine.reg_read(UC_X86_REG_EAX)))

    cpu.hook_add(UC_HOOK_INTR, interrupt)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(SAVED, 1):
        cpu.reg_write(register, 0x77770000 | i)

    cpu.emu_start(ENTRY, STOP, count=4000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, register in enumerate(SAVED, 1):
        assert cpu.reg_read(register) == 0x77770000 | i
    assert read('_playback_timer_enabled', '<B') == 0
    assert read('_playback_pending_time', '<i') == 0

    active = read('_playback_listener', '<h')
    current_mode = read('_playback_player_mode', '<B', active)
    keys = tuple(read('_playback_keys', '<B', key) for key in (49, 80))
    clocks = tuple(read(field, '<i') for field in ('_playback_last_tick', '_playback_saved_clock'))
    return seen, active, current_mode, keys, clocks


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSET, address=ENTRY, functions=CALLBACK)
    raw = ENTRY + 0x25600
    assert len(refs) == 40 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACK)
    original = bytes(image(executable)[ENTRY:ENTRY + SIZE])

    reload = [('reload',), ('init', 3), ('init', 1), ('reset_playback_timer_',)]
    replay = [('inputs', RECORDS[0]), ('process',)]
    replay2 = [('inputs', RECORDS[1]), ('process',)]
    cases = (
        ((52, 3), {'quit_now': True}, (SHUTDOWN, 3, 2, (0, 0), (91, 92))),
        ((52, 3), {'controls': True}, ([('render', 3, 43690)] + SHUTDOWN, 1, 3, (0, 0), (91, 92))),
        ((51, 1), {'controls': True, 'mode': 3}, ([('render', 1, 21845)] + SHUTDOWN, 3, 1, (0, 0), (91, 92))),
        ((54, 3), {}, (reload + replay + [('render', 3, 21845)] + SHUTDOWN, 3, 2, (0, 0), (0, 0))),
        ((56, 3), {}, (reload + replay + replay2 + [('render', 3, 0)] + SHUTDOWN, 3, 2, (0, 0), (0, 0))),
    )
    for body in (original, relocated):
        for args, kwargs, expected in cases:
            result = exercise(body, *args, **kwargs)
            assert result == expected, (args, kwargs, result, expected)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} playback scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
