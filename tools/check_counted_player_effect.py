"""Check counted player-effect creation and its 16-bit velocity arithmetic."""

import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EDI, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations


SYMBOL = 'spawn_counted_player_effect_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
STACK, RETURN = 0x3ff000, 0x3fff00
PLAYER, EFFECT = 7, 14
PLAYER_MOTION = (0x4321, -900, 0x3ffe)
COORDINATES, SECTOR = (1000, -2000, 3000), 81
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)


def sine(index):
    return ((index & 2047) % 521 - 260) * 43


def exercise(memory, code, count, angle, speed):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, code)

    def write(name, fmt, value, offset=0):
        cpu.mem_write(DS + DATA_OFFSETS[name] + offset, pack(fmt, value))

    def read(name, fmt, offset=0):
        address = DS + DATA_OFFSETS[name] + offset
        return unpack(fmt, cpu.mem_read(address, len(pack(fmt, 0))))[0]

    write('_player_sprite', '<h', PLAYER)
    write('_player_sector', '<h', SECTOR)
    write('_player_angle', '<h', angle)
    write('_effect_speed', '<H', speed)
    write('_effect_count', '<h', count)
    for axis, coord, momentum in zip('xyz', COORDINATES, PLAYER_MOTION):
        write(f'_player_{axis}', '<i', coord)
        write(f'_effect_sprite_{axis}vel', '<h', momentum, PLAYER * 44)
        write(f'_effect_sprite_{axis}vel', '<h', -123, EFFECT * 44)
    cpu.mem_write(DS + DATA_OFFSETS['_sintable'], pack('<2048h', *map(sine, range(2048))))

    launch, motion, listed = (FUNCTION_ADDRESSES[name] for name in
                              ('spawn_sprite_at_position_', 'set_sprite_motion_', 'add_listed_sprite_'))
    calls = []

    def stub(engine, address, _size, _data):
        calls.append(address)
        eax, edx, ebx, ecx = (engine.reg_read(reg) for reg in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if address == launch:
            assert eax == 36 and ebx == SECTOR
            assert unpack('<3i', engine.mem_read(edx, 12)) == (*COORDINATES[:2], COORDINATES[2] + 4000)
            assert read('_effect_count', '<h') == count - 1
            engine.reg_write(UC_X86_REG_EAX, EFFECT)
        elif address == motion:
            stack_args = unpack('<3I', engine.mem_read(engine.reg_read(UC_X86_REG_ESP) + 4, 12))
            assert eax == EFFECT and ecx == 0 and stack_args == (1024, 1024, 0)
            assert edx == (sine(angle + 212) << 8) & 0xffffffff
            assert ebx == (sine(angle - 300) << 8) & 0xffffffff
        else:
            assert eax == EFFECT

    for address, return_code in ((launch, b'\xc3'), (motion, b'\xc2\x0c\x00'), (listed, b'\xc3')):
        cpu.mem_write(address, return_code)
        cpu.hook_add(UC_HOOK_CODE, stub, begin=address, end=address)
    for index, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12340000 + index)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', RETURN))
    cpu.emu_start(ENTRY, RETURN, count=1500)
    assert cpu.reg_read(UC_X86_REG_EIP) == RETURN
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12340000 + i for i, reg in enumerate(SAVED))
    assert read('_effect_count', '<h') == (count - 1 if count > 0 else count)
    assert calls == ([launch, motion, listed] if count > 0 else [])
    base = ((sine(angle + 512) >> 3) * speed, (sine(angle) >> 3) * speed, -1000)
    for axis, initial, inherited in zip('xyz', base, PLAYER_MOTION):
        expected = (initial + 8 * inherited) & 0xffff if count > 0 else (-123 & 0xffff)
        assert read(f'_effect_sprite_{axis}vel', '<H', EFFECT * 44) == expected


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[RAW:RAW + SIZE] and len(refs) == 27
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(obj, SYMBOL, {key: DS + val for key, val in DATA_OFFSETS.items()},
                                    address=ENTRY, functions=FUNCTION_ADDRESSES)
    memory = image(exe)
    for body in (memory[ENTRY:ENTRY + SIZE], restored):
        for case in ((0, 0, 0), (-1, 0, 0), (1, 0, 0), (5, 2047, 65535)):
            exercise(memory, body, *case)
    print('PASS: 374 bytes, 27 LE relocations, four counted effect scenarios for original and C')
