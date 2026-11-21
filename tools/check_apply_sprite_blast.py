"""Verify blast range checks, sprite traversal, and x87 impulse results."""
import argparse
from math import isqrt, trunc
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_FPCW,
)

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

SYMBOL = 'apply_sprite_blast_'
ENTRY, SIZE, BASE = 0x10d3a, 532, 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
SOURCE, ORIGIN = 5, (1000, -200)
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSET = {
    '_blast_horizontal_scale': 0xf8, '_blast_vertical_scale': 0xfc,
    '_blast_vertical_limit': 0x100, '_blast_vertical_velocity': 0x104,
    '_blast_player_x': 0x5ad9c, '_blast_player_y': 0x5ad5c,
    '_blast_sprite_actor': 0x709dc, '_actor_kind': 0x7f0a0,
    '_blast_next_sprite_status': 0x1fbca0, '_blast_sprite_x': 0x2040a0,
    '_blast_sprite_y': 0x2040a4, '_blast_sprite_cstat': 0x2040ac,
    '_blast_sprite_tile': 0x2040ae, '_blast_sprite_xrepeat': 0x2040b2,
    '_blast_sprite_xvel': 0x2040c0, '_blast_sprite_yvel': 0x2040c2,
    '_blast_sprite_zvel': 0x2040c4, '_blast_sprite_lotag': 0x2040c6,
    '_blast_head_sprite_status': 0x28811c,
}
DATA = {name: BASE + offset for name, offset in OFFSET.items()}
CALLBACK = {
    'adjust_blast_player_status_': 0x1092e, 'blast_random_': 0x602d0, 'absolute_long_': 0x602c3,
    'play_sound_': 0x34f79, 'blast_distance_root_': 0x4ca38, 'truncate_st0_': 0x60304,
    'start_blast_sequence_': 0x11fdd, 'add_listed_sprite_': 0x134c2,
}
TRUNCATE = CALLBACK['truncate_st0_']
SENTINEL = (101, -102, 103)


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def float32(value):
    return unpack('<f', pack('<f', value))[0]


def velocity(dx, dy):
    distance = isqrt(dx * dx + dy * dy)
    horizontal = float32(1024.0 / distance)
    vertical = min(3.0, float32(1248576.0 / (distance * distance)))
    return trunc(horizontal * dx * vertical), trunc(horizontal * dy * vertical), trunc(-400.0 * vertical)


def exercise(mapped, body, targets, player_dx, player_dy, roll):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(TRUNCATE, bytes(mapped[TRUNCATE:TRUNCATE + 0x1d]))
    cpu.mem_write(DATA['_blast_horizontal_scale'], bytes(mapped[BASE + 0xf8:BASE + 0x108]))

    def put(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    def read(field, fmt, offset=0):
        return unpack(fmt, cpu.mem_read(DATA[field] + offset, len(pack(fmt, 0))))[0]

    put('_blast_player_x', '<i', ORIGIN[0] + player_dx)
    put('_blast_player_y', '<i', ORIGIN[1] + player_dy)
    put('_blast_head_sprite_status', '<h', targets[0][0] if targets else -1)
    put('_blast_sprite_x', '<i', ORIGIN[0], 44 * SOURCE)
    put('_blast_sprite_y', '<i', ORIGIN[1], 44 * SOURCE)
    for i, (sprite, dx, dy, tag, tile, actor) in enumerate(targets):
        offset = 44 * sprite
        put('_blast_next_sprite_status', '<h', targets[i + 1][0] if i + 1 < len(targets) else -1, 2 * sprite)
        put('_blast_sprite_actor', '<h', actor, 2 * sprite)
        put('_blast_sprite_x', '<i', ORIGIN[0] + dx, offset)
        put('_blast_sprite_y', '<i', ORIGIN[1] + dy, offset)
        put('_blast_sprite_lotag', '<h', tag, offset)
        put('_blast_sprite_tile', '<h', tile, offset)
        put('_blast_sprite_cstat', '<h', 0x101, offset)
        put('_blast_sprite_xrepeat', '<B', 20, offset)
        for coord, value in zip('xyz', SENTINEL):
            put('_blast_sprite_' + coord + 'vel', '<h', value, offset)
        if actor >= 0:
            put('_actor_kind', '<B', 6, actor)

    seen = []

    def hook(machine, _address, _size, name):
        eax, edx, ebx, ecx = (machine.reg_read(reg) for reg in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if name == 'absolute_long_':
            machine.reg_write(UC_X86_REG_EAX, abs(signed(eax)))
        elif name == 'blast_random_':
            seen.append(('random',))
            machine.reg_write(UC_X86_REG_EAX, roll & 0xffffffff)
        elif name == 'blast_distance_root_':
            seen.append(('distance_square', eax))
            machine.reg_write(UC_X86_REG_EAX, isqrt(eax))
        elif name == 'play_sound_':
            seen.append(('sound', eax, edx, ebx, ecx))
        elif name == 'start_blast_sequence_':
            seen.append(('sequence', eax))
        elif name == 'add_listed_sprite_':
            seen.append(('add', eax))
            # The loop must already have read its next link.
            put('_blast_next_sprite_status', '<h', -1, 2 * eax)
        elif name == 'adjust_blast_player_status_':
            seen.append(('damage', signed(eax)))

    for name, address in CALLBACK.items():
        if address != TRUNCATE:
            cpu.mem_write(address, b'\xc3')
            cpu.hook_add(UC_HOOK_CODE, hook, user_data=name, begin=address, end=address)

    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, 0xabcd0000 | SOURCE)
    cpu.reg_write(UC_X86_REG_FPCW, 0x037f)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(SAVED, 1):
        cpu.reg_write(register, 0x77770000 | i)
    cpu.emu_start(ENTRY, STOP, count=1500)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, register in enumerate(SAVED, 1):
        assert cpu.reg_read(register) == 0x77770000 | i
    assert cpu.reg_read(UC_X86_REG_FPCW) == 0x037f

    state = []
    for sprite, _, _, _, _, actor in targets:
        offset = 44 * sprite
        speed = tuple(read('_blast_sprite_' + coord + 'vel', '<h', offset) for coord in 'xyz')
        cstat = read('_blast_sprite_cstat', '<h', offset)
        repeat = read('_blast_sprite_xrepeat', '<B', offset)
        kind = read('_actor_kind', '<B', actor) if actor >= 0 else None
        state.append((speed, cstat, repeat, kind))
    return state, seen


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSET, address=ENTRY, functions=CALLBACK)
    raw = ENTRY + 0x25600
    assert len(refs) == 24 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACK)
    mapped = image(executable)
    original = bytes(mapped[ENTRY:ENTRY + SIZE])

    targets = ((8, 3, 4, 0x664, 0x154, 11), (9, 600, 800, 101, 0, -1),
               (10, 1024, 0, 100, 0x154, -1), (12, -80, -60, 0, 0x154, -1))
    target_state = [
        (velocity(3, 4), 0, 40, 3), (velocity(600, 800), 0x101, 20, None),
        (SENTINEL, 0x101, 20, None), (SENTINEL, 0x101, 20, None),
    ]
    target_calls = [('distance_square', 25), ('sequence', 8), ('add', 8), ('sequence', 8),
                    ('distance_square', 1000000), ('sequence', 9), ('add', 9), ('sequence', 12)]
    y_boundary = ((8, 0, 1023, 0, 0x154, -1), (9, 0, 1024, 101, 0x154, -1),
                  (10, 0, -1024, 0, 0x154, -1))
    cases = (
        (((), 100, -200, -3), ([], [('damage', -400), ('random',), ('sound', 14, 0, 0, 0)])),
        (((), 0, -1024, 0), ([], [])),
        ((targets, 1024, 0, 0), (target_state, target_calls)),
        # Inside range the tile alone starts the sequence. Outside either
        # Y boundary neither the impulse tag nor the tile has an effect.
        ((y_boundary, 1024, 0, 0), ([(SENTINEL, 0x101, 20, None)] * 3, [('sequence', 8)])),
    )
    for body in (original, relocated):
        for args, expected in cases:
            result = exercise(mapped, body, *args)
            assert result == expected, (args, result, expected)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} blast scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
