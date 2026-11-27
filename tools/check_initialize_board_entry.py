"""Verify player sprite insertion and all retained palette dispatch entries."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

TABLE, ENTRY, END, DATA_BASE = 0x2e133, 0x2e14f, 0x2e350, 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
INSERT, MAKE_PALOOKUP = 0x508b8, 0x593b4
SPRITE, SECTOR, ANGLE = 17, 5, 612
POSITION = (1234, -5432, 2000)
RAMP = (0x80, 0x20, 0xe0, 0x40, 0x60, 0xa0, 0xc0)
STAGES = (ENTRY, 0x2e274, 0x2e28e, 0x2e2a8, 0x2e2c2, 0x2e2d9, 0x2e2f0, 0x2e307, 0x2e31e, END)
SYMBOLS = ('initialize_board_entry_', *(f'board_entry_palette_{i}_' for i in range(1, 8)),
           'board_entry_default_palette_')
CALLBACKS = {'insertsprite_': INSERT, 'makepalookup_': MAKE_PALOOKUP,
             'board_entry_finish_': 0x2e347, 'board_entry_default_palette_': 0x2e31e,
             'board_player_palette_finish_': 0x2e330}
OFFSETS = {
    '_board_player_sprites': 0x2040a0, '_board_player_sprite': 0x62f2c,
    '_board_player_sector': 0x5acfc, '_board_player_angle': 0x6308c,
    '_board_player_x': 0x5ad9c, '_board_player_y': 0x5ad5c, '_board_player_z': 0x5ad1c,
    '_board_player_positions': 0x20a2c, '_board_sprite_visibility': 0x1ecfa0,
    '_board_player_palette': 0x1df6c, '_board_player_ramp': 0x1e02b,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
TABLE_SYMBOL = '_board_player_palette_dispatch'
PRESERVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)


def exercise(code, table, player, already_present):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(TABLE, table)

    def put(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    def get(field, fmt, offset=0):
        return unpack(fmt, cpu.mem_read(DATA[field] + offset, len(pack(fmt, 0))))[0]

    sprites = DATA['_board_player_sprites'] + 44 * SPRITE
    palette = DATA['_board_player_palette']
    cpu.mem_write(sprites, b'\xa5' * 44)
    cpu.mem_write(palette, b'\x91' * 256)
    put('_board_sprite_visibility', '<B', 0xff, SPRITE // 8)
    put('_board_player_sprite', '<h', SPRITE if already_present else -1, player * 2)
    put('_board_player_sector', '<h', SECTOR, player * 2)
    put('_board_player_angle', '<h', ANGLE, player * 2)
    for axis, value in zip('xyz', POSITION):
        put('_board_player_' + axis, '<i', value, player * 4)
    calls = []

    def on_insert(machine, _address, _size, _data):
        args = machine.reg_read(UC_X86_REG_EAX), machine.reg_read(UC_X86_REG_EDX)
        calls.append(('insert', *args))
        cpu.mem_write(sprites + 24, pack('<hh', *args))
        machine.reg_write(UC_X86_REG_EAX, SPRITE)

    def on_palookup(machine, _address, _size, _data):
        eax, edx, ebx, ecx, esp = (machine.reg_read(reg) for reg in
                                  (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX,
                                   UC_X86_REG_ECX, UC_X86_REG_ESP))
        assert edx == palette
        calls.append(('palookup', eax, ebx, ecx, *unpack('<II', cpu.mem_read(esp + 4, 8))))

    cpu.mem_write(INSERT, b'\xc3')
    cpu.mem_write(MAKE_PALOOKUP, b'\xc2\x08\x00')
    cpu.hook_add(UC_HOOK_CODE, on_insert, begin=INSERT, end=INSERT)
    cpu.hook_add(UC_HOOK_CODE, on_palookup, begin=MAKE_PALOOKUP, end=MAKE_PALOOKUP)

    cpu.reg_write(UC_X86_REG_EAX, 0x65120000 | player)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(PRESERVED, 1):
        cpu.reg_write(register, 0x88440000 | i)
    cpu.emu_start(ENTRY, STOP, count=3000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, register in enumerate(PRESERVED, 1):
        assert cpu.reg_read(register) == 0x88440000 | i
    assert get('_board_player_sprite', '<h', 2 * player) == SPRITE
    actual_sprite = bytes(cpu.mem_read(sprites, 44))
    actual_palette = bytes(cpu.mem_read(palette, 256))
    if already_present:
        assert calls == [] and actual_sprite == b'\xa5' * 44 and actual_palette == b'\x91' * 256
        return
    assert calls == [('insert', SECTOR, 8), ('palookup', player, 0, 0, 0, 1)]
    pos = (*POSITION[:2], POSITION[2] + 8192)
    visual = (0, player, 32, 0xa5, 64, 64, 0, 0)
    expected_sprite = pack('<iiiHH8B10h', *pos, 0x101, 120, *visual,
                           SECTOR, 8, ANGLE, 0x1000 + player, 0, 0, 0, 0, 0, 0)
    assert actual_sprite == expected_sprite
    assert bytes(cpu.mem_read(DATA['_board_player_positions'] + SPRITE * 12, 12)) == pack('<iii', *pos)
    assert get('_board_sprite_visibility', '<B', SPRITE // 8) == 0xfd
    expected_palette = bytes(range(256)) if player == 0 else (
        b'\x91' * 192 + bytes(range(RAMP[player - 1], RAMP[player - 1] + 32)) + b'\x91' * 32
    )
    assert actual_palette == expected_palette


def check(executable, obj, table):
    raw = TABLE + 0x25600
    pointers = read_le_fixups(executable)['pointers']
    assert table == executable[raw:raw + 28]
    assert tuple(pointers[TABLE + i * 4] for i in range(7)) == STAGES[1:8]
    assert unpack('<7I', table) == tuple(address - 0x10000 for address in STAGES[1:8])
    mapped = image(executable)
    loaded_table = bytes(mapped[TABLE:ENTRY])

    count = 0
    relocated = []
    for name, start, end in zip(SYMBOLS, STAGES, STAGES[1:]):
        code_refs = {}
        code, refs = bind_leaf_details(obj, name, OFFSETS, address=start, functions=CALLBACKS,
                                       absolute_code={TABLE_SYMBOL: TABLE - 0x10000}, code_bindings=code_refs)
        assert code == executable[start + 0x25600:end + 0x25600]
        verify_leaf_relocations(code, refs, pointers, start, code_bindings=code_refs)
        count += len(refs)
        body, _ = bind_leaf_details(obj, name, DATA, address=start, functions=CALLBACKS,
                                    absolute_code={TABLE_SYMBOL: TABLE}, code_bindings={})
        relocated.append(body)
    assert count == 24
    original = bytes(mapped[ENTRY:END])
    for body in (original, b''.join(relocated)):
        for player in range(8):
            exercise(body, loaded_table, player, False)
        exercise(body, loaded_table, 5, True)
    print(f'PASS: {END - ENTRY} exact bytes, {count} LE relocations, 7 table targets, 9 board-entry scenarios')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('table', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes(), args.table.read_bytes())
