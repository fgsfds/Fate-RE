"""Check crusher updates against the original executable and Watcom object."""
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
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'update_level_effects_'
ENTRY = FUNCTION_ADDRESSES[SYMBOL]
DATA_BASE = 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
BANK_INDEX = 3
BANK = DATA_BASE + DATA_OFFSETS['_update_crusher_banks'] + 1032 * BANK_INDEX
SECTORS = DATA_BASE + DATA_OFFSETS['_crusher_update_sectors']
NUM_SECTORS = DATA_BASE + DATA_OFFSETS['_numsectors']
DATA = {name: DATA_BASE + offset for name, offset in DATA_OFFSETS.items()}
CALLBACKS = {
    'error': FUNCTION_ADDRESSES['report_game_error_'],
    'goal': FUNCTION_ADDRESSES['get_animation_goal_'],
    'player': FUNCTION_ADDRESSES['check_crushed_player_'],
    'sprites': FUNCTION_ADDRESSES['check_crushed_sprites_'],
    'sound': FUNCTION_ADDRESSES['play_crusher_sound_'],
    'activate': FUNCTION_ADDRESSES['activate_crush_sector_'],
}
PRESERVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
FIELDS = {
    'sector': ('<h', 0), 'ceiling': ('<i', 2), 'floor': ('<i', 6),
    'opening': ('<i', 10), 'last_shade_z': ('<i', 14),
    'shade': ('<b', 19), 'darkest': ('<b', 20), 'active': ('<i', 21),
    'direction': ('<i', 25), 'interval': ('<i', 29),
    'automatic': ('<i', 49), 'reopen': ('<i', 53), 'restart': ('<i', 57),
}


def exercise(mapped, body, records, goals, *, enabled=1, index=BANK_INDEX, error=None):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    restore = FUNCTION_ADDRESSES['restore_crusher_registers_']
    cpu.mem_write(restore, bytes(mapped[restore:restore + 7]))

    for address in CALLBACKS.values():
        cpu.mem_write(address, b'\xc3')
    cpu.mem_write(BANK, pack('<ii', enabled, len(records)))
    cpu.mem_write(NUM_SECTORS, pack('<h', 16))
    for slot, (sector, sector_ceiling, fields) in enumerate(records):
        record = BANK + 8 + 64 * slot
        cpu.mem_write(SECTORS + 40 * sector + 4, pack('<i', sector_ceiling))
        for field, value in dict(fields, sector=sector).items():
            fmt, offset = FIELDS[field]
            cpu.mem_write(record + offset, pack(fmt, value))

    calls = []
    for label, callback in CALLBACKS.items():
        def hook(machine, _address, _size, _data, kind=label):
            eax = machine.reg_read(UC_X86_REG_EAX)
            edx = machine.reg_read(UC_X86_REG_EDX)
            if kind == 'error':
                assert eax == DATA[error], hex(eax)
                calls.append((kind,))
                machine.emu_stop()
            elif kind == 'goal':
                assert (eax - SECTORS - 4) % 40 == 0
                sector = (eax - SECTORS - 4) // 40
                calls.append((kind, sector))
                machine.reg_write(UC_X86_REG_EAX, goals[sector] & 0xffffffff)
            elif kind == 'activate':
                calls.append((kind, eax, edx))
            else:
                assert (eax - BANK - 8) % 64 == 0
                slot = (eax - BANK - 8) // 64
                calls.append((kind, slot, edx))
        cpu.hook_add(UC_HOOK_CODE, hook, begin=callback, end=callback)

    cpu.reg_write(UC_X86_REG_EAX, index & 0xffffffff)
    for i, register in enumerate(PRESERVED, 1):
        cpu.reg_write(register, 0x55aa0000 | i)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\x5a' * 16)
    cpu.emu_start(ENTRY, STOP, count=1500)
    if error:
        assert calls == [('error',)]
        return None
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\x5a' * 16
    for i, register in enumerate(PRESERVED, 1):
        assert cpu.reg_read(register) == 0x55aa0000 | i

    state = []
    for slot, (sector, _, _) in enumerate(records):
        entry = BANK + 8 + 64 * slot
        fields = []
        for field in ('ceiling', 'last_shade_z', 'shade', 'active', 'direction', 'restart'):
            fmt, offset = FIELDS[field]
            fields.append(unpack(fmt, cpu.mem_read(entry + offset, len(pack(fmt, 0))))[0])
        floor_shade = unpack('<b', cpu.mem_read(SECTORS + 40 * sector + 28, 1))[0]
        state.append((*fields, floor_shade))
    return state, calls


def check(executable, obj):
    raw, size = LEAVES[SYMBOL]
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY,
                                   functions=FUNCTION_ADDRESSES)
    assert len(refs) == 8 and code == executable[raw:raw + size]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=FUNCTION_ADDRESSES)
    mapped = image(executable)
    original = bytes(mapped[ENTRY:ENTRY + size])

    moving = dict(active=1, direction=2, opening=100, floor=4000, interval=16)
    no_shade = dict(moving, opening=1000)
    cases = (
        ([], {}, ([], [])),
        ([(1, 400, {})], {}, ([(0, 0, 0, 0, 0, 0, 0)], [])),
        ([(2, 500, dict(moving, last_shade_z=800, shade=-20, darkest=-20))],
         {2: 0}, ([(500, 500, -20, 1, 2, 0, -20)],
                  [('player', 0, 2), ('sprites', 0, 2), ('goal', 2)])),
        ([(3, 550, dict(moving, direction=1, last_shade_z=100, shade=32))],
         {3: 1}, ([(550, 550, 32, 1, 1, 0, 32)], [('goal', 3)])),
        ([(4, 600, dict(no_shade, automatic=1, reopen=0)),
          (5, 700, dict(no_shade, direction=1, automatic=1, reopen=1))],
         {4: -1, 5: -1},
         ([(2976, 0, 0, 0, 0, 0, 0), (700, 0, 0, 0, 0, 0, 0)],
          [('goal', 4), ('player', 0, 4), ('sprites', 0, 4), ('sound', 0, 0),
           ('goal', 5), ('sound', 1, 0), ('activate', BANK_INDEX, 4), ('activate', BANK_INDEX, 5)])),
        ([(6, 700, dict(no_shade, direction=1, automatic=1, reopen=0))],
         {6: -1}, ([(700, 0, 0, 0, 0, 0, 0)], [('goal', 6), ('sound', 0, 0)])),
        ([(7, 500, dict(moving, direction=1, last_shade_z=505, shade=3))],
         {7: 0}, ([(500, 505, 3, 1, 1, 0, 3)], [('goal', 7)])),
    )
    for body in (original, relocated):
        for entries, goals, expected in cases:
            actual = exercise(mapped, body, entries, goals)
            assert actual == expected, (actual, expected)
        exercise(mapped, body, [], {}, index=-1, error='_crusher_update_bad_bank')
        exercise(mapped, body, [], {}, enabled=0, error='_crusher_update_disabled')
        exercise(mapped, body, [(16, 500, {})], {}, error='_crusher_update_bad_sector')
    print(f'PASS: {size} exact bytes, {len(refs)} LE relocations, 10 crusher scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
