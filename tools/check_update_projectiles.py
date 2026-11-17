"""Verify projectile movement, swap-removal, collision dispatch, and close-hit feedback."""
import argparse
from math import isqrt
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

SYMBOL = 'update_projectiles_'
ENTRY, SIZE, BASE = 0x13237, 651, 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
PRESERVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSETS = {
    '_projectile_count': 0x2bee, '_projectile_list': 0x7053c, '_projectile_player_sprite': 0x62f2c,
    '_projectile_sector': 0x2040b8, '_projectile_owner': 0x2040be,
    '_projectile_lotag': 0x2040c6, '_projectile_hitag': 0x2040c8,
    '_projectile_xvel': 0x2040c0, '_projectile_yvel': 0x2040c2, '_projectile_zvel': 0x2040c4,
    '_projectile_x': 0x2040a0, '_projectile_y': 0x2040a4, '_projectile_z': 0x2040a8,
    '_projectile_ticks': 0x7a994, '_projectile_player_x': 0x5ad9c,
    '_projectile_player_y': 0x5ad5c, '_projectile_player_z': 0x5ad1c,
    '_projectile_player_hit_x': 0x7097c, '_projectile_player_hit_y': 0x7093c,
    '_projectile_player_hit_timer': 0x6f89c, '_projectile_selected_weapon': 0x2be2,
    '_projectile_close_hit_tile': 0x2be6, '_projectile_player_mode': 0x62f1c, '_projectile_extra_high': 0x2040cb,
}
DATA = {name: BASE + offset for name, offset in OFFSETS.items()}
CALLBACKS = {
    'move_sprite_': 0x339b9, 'ksqrt_': 0x4ca38, 'adjust_status_value_': 0x1092e,
    'changespritesect_': 0x50bc3, 'dispatch_hit_event_': 0x2b369, 'apply_projectile_hit_': 0x13115,
    'start_sequence_': 0x11fdd, 'sequence_remove_sprite_': 0x10f9f,
}
SPRITE, OTHER, TARGET, PLAYER = 7, 8, 12, 2
PREVIOUS, CURRENT, MIDPOINT = (100, -100, 200), (105, -105, 195), (103, -103, 197)
OLD_SECTOR, NEW_SECTOR = 3, 5
MOVEMENT = ('move', SPRITE, 24576, -36864, -4)
RECOIL = (-50, -49152, -65536)


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, active, owner, collision, *, mode=0, weapon=1):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)

    def write(name, fmt, value, offset=0):
        cpu.mem_write(DATA['_projectile_' + name] + offset, pack(fmt, value))

    def read(name, fmt, offset=0):
        data = cpu.mem_read(DATA['_projectile_' + name] + offset, len(pack(fmt, 0)))
        return unpack(fmt, data)[0]

    for name, fmt, value in (('count', '<h', len(active)), ('ticks', '<i', 3),
                             ('player_sprite', '<h', PLAYER), ('player_mode', '<B', mode),
                             ('selected_weapon', '<h', weapon)):
        write(name, fmt, value)
    for axis, value in zip('xyz', (102, -109, 175)):
        write('player_' + axis, '<i', value)
    for i, sprite in enumerate(active, 1):
        write('list', '<h', sprite, 2 * i)
        write('owner', '<h', owner, 44 * sprite)
        write('sector', '<h', OLD_SECTOR, 44 * sprite)
        for axis, value, speed in zip('xyz', PREVIOUS, (2, -3, -5)):
            write(axis, '<i', value, 44 * sprite)
            write(axis + 'vel', '<h', speed, 44 * sprite)
    write('lotag', '<h', 0x5504, 44 * TARGET)
    write('hitag', '<h', 0x1207, 44 * TARGET)

    calls = []

    def hook(machine, _address, _size, name):
        eax, edx, ebx, ecx = (signed(machine.reg_read(reg)) for reg in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if name == 'move_sprite_':
            stack = machine.reg_read(UC_X86_REG_ESP)
            assert bytes(machine.mem_read(stack + 4, 12)) == pack('<3I', 16, 16, 1)
            assert eax == SPRITE
            calls.append(('move', eax, edx, ebx, ecx))
            for axis, value in zip('xyz', CURRENT):
                write(axis, '<i', value, 44 * eax)
            write('sector', '<h', NEW_SECTOR, 44 * eax)
            machine.reg_write(UC_X86_REG_EAX, collision)
        elif name == 'ksqrt_':
            calls.append(('distance', eax))
            machine.reg_write(UC_X86_REG_EAX, isqrt(eax))
        elif name == 'adjust_status_value_':
            calls.append(('damage', eax))
        elif name == 'changespritesect_':
            calls.append(('sector', eax, edx))
            write('sector', '<h', edx, 44 * eax)
        elif name == 'dispatch_hit_event_':
            calls.append(('event', eax))
        elif name == 'apply_projectile_hit_':
            calls.append(('hit', eax, edx, ecx))
        else:
            calls.append(('sequence' if name == 'start_sequence_' else 'remove', eax))

    for name, address in CALLBACKS.items():
        cpu.mem_write(address, b'\xc2\x0c\x00' if name == 'move_sprite_' else b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, user_data=name, begin=address, end=address)

    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(PRESERVED, 1):
        cpu.reg_write(register, 0x88880000 | i)
    cpu.emu_start(ENTRY, STOP, count=1400)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, register in enumerate(PRESERVED, 1):
        assert cpu.reg_read(register) == 0x88880000 | i

    remaining = tuple(read('list', '<h', 2 * i) for i in range(1, 1 + read('count', '<h')))
    position = tuple(read(axis, '<i', 44 * SPRITE) for axis in 'xyz')
    recoil = tuple(read('player_hit_' + name, fmt) for name, fmt in (('timer', '<h'), ('x', '<i'), ('y', '<i')))
    return (remaining, position, read('sector', '<h', 44 * SPRITE),
            read('extra_high', '<B', 44 * SPRITE), read('close_hit_tile', '<h'), recoil, calls)


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSETS, address=ENTRY, functions=CALLBACKS)
    raw = ENTRY + 0x25600
    assert len(refs) == 42 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACKS)
    original = bytes(image(executable)[ENTRY:ENTRY + SIZE])
    sector = ('sector', SPRITE, OLD_SECTOR)
    sequence = ('sequence', SPRITE)
    close = [MOVEMENT, ('distance', 25), ('damage', -350), sector]
    cases = (
        (((), 0, 0), {}, ((), (0, 0, 0), 0, 0, 0, (0, 0, 0), [])),
        (((SPRITE,), 0, 0x56000000), {}, ((SPRITE,), CURRENT, NEW_SECTOR, 0, 0, (0, 0, 0), [MOVEMENT])),
        (((SPRITE,), 1, 0xc000 + PLAYER), {}, ((SPRITE,), CURRENT, NEW_SECTOR, 0, 0, (0, 0, 0), [MOVEMENT])),
        (((SPRITE, OTHER), 0, 2), {}, ((OTHER,), MIDPOINT, OLD_SECTOR, 0x20, 0, (0, 0, 0),
                                      [MOVEMENT, sector, sequence])),
        (((SPRITE,), 0, 0x1200c000 + TARGET), {}, ((), MIDPOINT, OLD_SECTOR, 0, 0, (0, 0, 0),
            [MOVEMENT, sector, ('event', 7), ('hit', TARGET, SPRITE, 0x1200c000 + TARGET), sequence])),
        (((SPRITE,), 1, 0x8001), {}, ((), MIDPOINT, OLD_SECTOR, 0, 0x323, RECOIL, close + [('remove', SPRITE)])),
        (((SPRITE,), 1, 0x8001), {'weapon': 3}, ((), MIDPOINT, OLD_SECTOR, 0, 0x327, RECOIL,
                                               close + [('remove', SPRITE)])),
        (((SPRITE,), 1, 0x8001), {'mode': 2}, ((), MIDPOINT, OLD_SECTOR, 0, 0, RECOIL, close + [sequence])),
    )
    for body in (original, relocated):
        for args, kwargs, expected in cases:
            result = exercise(body, *args, **kwargs)
            assert result == expected, (args, kwargs, result, expected)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} projectile scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
