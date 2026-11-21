"""Check the board actor scan, template restoration, and index publication."""
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

ENTRY, SIZE, BASE = 0x26749, 698, 0x80000
SYMBOL = 'restore_board_actor_sprites_'
STACK, STOP = 0x3e0000, 0x3ff000
REGISTERS = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSETS = {
    '_restored_sprite': 0x2040a0, '_actor_kind': 0x7f0a0, '_saved_actor_board': 0x7eac1,
    '_saved_actor_mode': 0x7f67f, '_saved_actor_active': 0x7ecb6, '_restored_current_board': 0x7f87e,
    '_restored_actor_sprite': 0x7dab8, '_restored_sprite_actor': 0x709dc, '_saved_actor_lotag': 0x7d6ce,
    '_restored_tile_height': 0x1f4020, '_restored_actor_tiles': 0x7abc0, '_inactive_actor_tiles': 0x68080,
    '_saved_actor_x': 0x772c4, '_saved_actor_y': 0x772c8, '_saved_actor_z': 0x772cc,
    '_restored_actor_z_offset': 0x79214, '_restored_sector_floor': 0x27c3a8,
    '_restored_sprite_position': 0x20a2c, '_restored_sprite_interpolated': 0x1ecfa0,
    '_restore_actor_error_buffer': 0x67e3c, '_restore_actor_sector_error': 0x3e0,
    '_restore_template_cstat': 0x2a9d, '_restore_template_angle': 0x2aa8,
    '_restore_template_status': 0x2ab2, '_restore_template_hitag': 0x2ab6,
    '_restore_template_xvel': 0x2aaa, '_restore_template_yvel': 0x2aac,
    '_restore_template_zvel': 0x2aae, '_restore_template_owner': 0x2ab0,
    '_restore_template_shade': 0x2a9f, '_restore_template_palette': 0x2aa0,
    '_restore_template_clip_distance': 0x2aa1, '_restore_template_xrepeat': 0x2aa2,
    '_restore_template_yrepeat': 0x2aa3, '_restore_template_xoffset': 0x2aa4,
    '_restore_template_yoffset': 0x2aa5,
}
DATA = {name: BASE + offset for name, offset in OFFSETS.items()}
CALLBACKS = {'updatesector_': 0x542c4, 'insertsprite_': 0x508b8,
             'sprintf_': 0x601f3, 'report_game_error_': 0x26a03}
TEMPLATE = {
    'cstat': (12, '<h', 0x301), 'angle': (28, '<h', 768),
    'status': (26, '<h', 14), 'hitag': (40, '<h', 0x451),
    'xvel': (32, '<h', 34), 'yvel': (34, '<h', -45), 'zvel': (36, '<h', 56),
    'owner': (30, '<h', -1), 'shade': (16, '<B', 0xf9), 'palette': (17, '<B', 12),
    'clip_distance': (18, '<B', 27), 'xrepeat': (20, '<B', 36), 'yrepeat': (21, '<B', 19),
    'xoffset': (22, '<B', 25), 'yoffset': (23, '<B', 26),
}
BOARD, SECTOR, SPRITE = 3, 6, 23
ORIGIN, Z_RESTORED = (140, -92, 1700), 9734
ACTOR_TILE, INACTIVE_TILE, LOTAG = 83, 93, 0x402


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, actor, kind, actor_board, sector):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(DATA['_saved_actor_active'], b'\xff' * 501)
    cpu.mem_write(DATA['_restored_sprite'] + 44 * SPRITE, b'\xa5' * 44)

    def write(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    def read(field, fmt, offset=0):
        return unpack(fmt, cpu.mem_read(DATA[field] + offset, len(pack(fmt, 0))))[0]

    write('_restored_current_board', '<b', BOARD)
    write('_restored_sprite_actor', '<h', -1, 2 * SPRITE)
    write('_restored_actor_sprite', '<h', -1, 2 * actor)
    write('_restored_sprite_interpolated', '<B', 0xff, SPRITE // 8)
    write('_saved_actor_active', '<b', 2, actor)
    write('_saved_actor_board', '<B', actor_board, actor)
    write('_actor_kind', '<B', kind, actor)
    write('_saved_actor_mode', '<B', 2, actor)
    write('_saved_actor_lotag', '<h', LOTAG, 2 * actor)
    write('_restored_actor_tiles', '<h', ACTOR_TILE, 18 * actor + 4)
    write('_inactive_actor_tiles', '<h', INACTIVE_TILE, 4 * 120)
    write('_restored_tile_height', '<h', 12, 2 * ACTOR_TILE)
    write('_restored_actor_z_offset', '<i', 190, 4 * actor)
    write('_restored_sector_floor', '<i', 10000, 40 * SECTOR)
    for axis, value in zip('xyz', ORIGIN):
        write('_saved_actor_' + axis, '<i', value, 12 * actor)
    for field, (_, fmt, value) in TEMPLATE.items():
        write('_restore_template_' + field, fmt, value, 2 * 29)

    calls = []
    fatal = False

    def hook(machine, _address, _size, name):
        nonlocal fatal
        eax, edx, ebx = (machine.reg_read(reg) for reg in
                         (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX))
        if name == 'updatesector_':
            calls.append(('locate', signed(eax), signed(edx)))
            machine.mem_write(ebx, pack('<h', sector))
        elif name == 'insertsprite_':
            calls.append(('insert', eax, edx))
            write('_restored_sprite', '<h', eax, 44 * SPRITE + 24)
            write('_restored_sprite', '<h', edx, 44 * SPRITE + 26)
            machine.reg_write(UC_X86_REG_EAX, SPRITE)
        elif name == 'sprintf_':
            stack = machine.reg_read(UC_X86_REG_ESP)
            dest, fmt, index, x, y = unpack('<IIIii', machine.mem_read(stack + 4, 20))
            assert dest == DATA['_restore_actor_error_buffer'] and fmt == DATA['_restore_actor_sector_error']
            calls.append(('format', index, x, y))
        elif name == 'report_game_error_':
            assert eax == DATA['_restore_actor_error_buffer']
            calls.append(('report',))
            fatal = True
            machine.emu_stop()

    for name, address in CALLBACKS.items():
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, user_data=name, begin=address, end=address)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(REGISTERS, 1):
        cpu.reg_write(register, 0x88880000 | i)
    cpu.emu_start(ENTRY, STOP, count=15000)
    if not fatal:
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
        assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
        for i, register in enumerate(REGISTERS, 1):
            assert cpu.reg_read(register) == 0x88880000 | i

    saved_z = read('_saved_actor_z', '<i', 12 * actor)
    indices = read('_restored_actor_sprite', '<h', 2 * actor), read('_restored_sprite_actor', '<h', 2 * SPRITE)
    interpolation = read('_restored_sprite_interpolated', '<B', SPRITE // 8)
    sprite = bytes(cpu.mem_read(DATA['_restored_sprite'] + 44 * SPRITE, 44))
    if not any(call[0] == 'insert' for call in calls):
        assert indices == (-1, -1) and interpolation == 0xff and sprite == b'\xa5' * 44
        assert saved_z == ORIGIN[2]
    else:
        assert indices == (SPRITE, actor) and interpolation == 0x7f and not fatal
        inactive = kind == 3
        assert saved_z == (ORIGIN[2] if inactive else Z_RESTORED)
        assert unpack('<iii', sprite[:12]) == (*ORIGIN[:2], saved_z)
        assert unpack('<h', sprite[14:16])[0] == (INACTIVE_TILE if inactive else ACTOR_TILE)
        assert unpack('<h', sprite[24:26])[0] == sector
        assert unpack('<h', sprite[38:40])[0] == LOTAG and sprite[42:44] == b'\0\0'
        for field, (offset, fmt, value) in TEMPLATE.items():
            if inactive and field == 'cstat':
                value = 0
            assert sprite[offset:offset + len(pack(fmt, value))] == pack(fmt, value)
        assert bytes(cpu.mem_read(DATA['_restored_sprite_position'] + 12 * SPRITE, 12)) == sprite[:12]
    return calls


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSETS, address=ENTRY, functions=CALLBACKS)
    raw = ENTRY + 0x25600
    assert len(refs) == 45 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACKS)
    original = bytes(image(executable)[ENTRY:ENTRY + SIZE])

    locate = ('locate', *ORIGIN[:2])
    insert = ('insert', SECTOR, TEMPLATE['status'][2])
    cases = (
        ((5, 1, 4, SECTOR), []),
        ((5, 1, BOARD, SECTOR), [locate, insert]),
        ((500, 3, BOARD, SECTOR), [locate, insert]),
        ((5, 3, BOARD, -1), [locate, ('format', 5, *ORIGIN[:2])]),
        ((5, 1, BOARD, -1), [locate, ('format', 5, *ORIGIN[:2]), ('report',)]),
    )
    for body in (original, relocated):
        for inputs, expected in cases:
            result = exercise(body, *inputs)
            assert result == expected, (inputs, result, expected)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} board actor scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
