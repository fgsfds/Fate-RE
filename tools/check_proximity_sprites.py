"""Check linked and Watcom C proximity activation over range, sight, and counter paths."""
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

ENTRY, SIZE, DATA_BASE = 0x102ca, 361, 0x80000
ACTIVATE, ABSOLUTE, RANDOM, CANSEE = 0x129fc, 0x602c3, 0x602d0, 0x50d33
STACK, STOP = 0x3f0000, 0x3ff000
OFFSETS = {
    '_activation_sprite_index': 0x7497c, '_activation_sprite_count': 0x7def0,
    '_advance_clock': 0x229b, '_activation_counter': 0x7496c,
    '_proximity_player_x': 0x5ad9c, '_proximity_player_y': 0x5ad5c,
    '_proximity_player_z': 0x5ad1c, '_proximity_player_sector': 0x5acfc,
    '_proximity_sprite_x': 0x2040a0, '_proximity_sprite_y': 0x2040a4,
    '_proximity_sprite_z': 0x2040a8, '_proximity_sprite_tile': 0x2040ae,
    '_proximity_sprite_sector': 0x2040b8,
}
FUNCTIONS = {
    'activate_sprite_at_player_': ACTIVATE, 'absolute_long_': ABSOLUTE,
    'random_value_': RANDOM, 'cansee_': CANSEE,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
PLAYER, NEAR, SPRITE = (-100, 300, -500, 4), (50, 420, 870, 8), 7

SAVED = {
    register: 0x5afe0000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, count, tile, counter, clock, position, visibility, random):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    trace = []

    def calls(machine, address, _size, _data):
        eax, edx, ebx, ecx = (signed(machine.reg_read(register)) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        esp = machine.reg_read(UC_X86_REG_ESP)
        if address == ACTIVATE:
            trace.append(('activate', eax, edx, ebx, ecx, *unpack('<ii', machine.mem_read(esp + 4, 8))))
            machine.reg_write(UC_X86_REG_EAX, 0x5678aaaa)
        elif address == ABSOLUTE:
            trace.append(('absolute', eax))
            machine.reg_write(UC_X86_REG_EAX, abs(eax))
        elif address == CANSEE:
            trace.append(('cansee', eax, edx, ebx, ecx, *unpack('<iiii', machine.mem_read(esp + 4, 16))))
            machine.reg_write(UC_X86_REG_EAX, 0xaaaa0000 | visibility)
        elif address == RANDOM:
            trace.append(('random',))
            machine.reg_write(UC_X86_REG_EAX, 0xbeefff00 | random)

    for address, instruction in ((ACTIVATE, b'\xc2\x08\x00'), (ABSOLUTE, b'\xc3'),
                                 (CANSEE, b'\xc2\x10\x00'), (RANDOM, b'\xc3')):
        cpu.mem_write(address, instruction)
        cpu.hook_add(UC_HOOK_CODE, calls, begin=address, end=address)

    def write(name, fmt, value, offset=0):
        cpu.mem_write(DATA[name] + offset, pack(fmt, value))

    for field, value, fmt in zip(('x', 'y', 'z', 'sector'), PLAYER, ('<i', '<i', '<i', '<h')):
        write('_proximity_player_' + field, fmt, value)
    for field, value, fmt in zip(('x', 'y', 'z', 'sector'), position, ('<i', '<i', '<i', '<h')):
        write('_proximity_sprite_' + field, fmt, value, 44 * SPRITE)
    write('_activation_sprite_count', '<h', count)
    write('_activation_sprite_index', '<h', SPRITE, 2)
    write('_proximity_sprite_tile', '<h', tile, 44 * SPRITE)
    write('_advance_clock', '<h', clock)
    cpu.mem_write(DATA['_activation_counter'], bytes([99, counter, 101]))
    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=800)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    left, result, right = cpu.mem_read(DATA['_activation_counter'], 3)
    assert (left, right) == (99, 101)
    return result, trace


def check(executable, obj):
    name = 'update_proximity_sprites_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 27
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]

    lower = [('activate', SPRITE, PLAYER[0], PLAYER[1], PLAYER[2] + 2000, 512, 5)]
    upper = [(*lower[0][:-1], 4)]
    sight = [('absolute', -150), ('absolute', -120), ('cansee', *NEAR, *PLAYER)]
    cases = (
        ((0, 0x3a6, 2, 1, NEAR, 1, 9), (2, [])),
        ((1, 0x3a5, 2, 1, NEAR, 1, 9), (2, [])),
        ((1, 0x3aa, 2, 1, NEAR, 1, 9), (2, [])),
        ((1, 0x3a6, 2, 0, NEAR, 1, 9), (0, lower)),
        ((1, 0x3a7, 2, 1, NEAR, 1, 9), (1, lower)),
        ((1, 0x3a8, 2, 1, NEAR, 1, 9), (3, upper)),
        ((1, 0x3a9, 3, 1, NEAR, 1, 9), (0, upper)),
        ((1, 0x3a8, 255, 1, NEAR, 1, 9), (0, upper)),
        ((1, 0x3a9, 0, 1, NEAR, 1, 9), (1, [*sight, ('random',)])),
        ((1, 0x3a9, 0, 1, NEAR, 1, 10), (0, [*sight, ('random',)])),
        ((1, 0x3a9, 0, 1, NEAR, 0, 9), (0, sight)),
        ((1, 0x3a9, 0, 1, NEAR, 2, 9), (0, sight)),
        ((1, 0x3a9, 0, 1, (8192 + PLAYER[0], *NEAR[1:]), 1, 9), (0, [('absolute', -8192)])),
        ((1, 0x3a9, 0, 1, (NEAR[0], PLAYER[1] - 8192, *NEAR[2:]), 1, 9),
         (0, [('absolute', -150), ('absolute', 8192)])),
    )
    for args, expected in cases:
        for body in (original, code):
            result = exercise(body, *args)
            assert result == expected, (args, result, expected)
    print('PASS: 361 exact bytes, 27 LE pointers, 14 proximity scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
