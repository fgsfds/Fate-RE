"""Check the board dispatcher against the original game image and every generated switch case."""
import argparse
from pathlib import Path
from struct import pack, unpack

from bind_level_script_dispatch import BASE, BOARD_SCRIPTS, CALLS, DATA, PREFIX, SIZE, bind
from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

PLAYER = (123, -456, 789, -12)
STACK, STOP = 0x3f0000, 0x3ff000
ENTRY, UPDATE = BASE + PREFIX, CALLS['update_actor_']
LOADED = {name: 0x80000 + offset for name, offset in DATA.items()}
SAVED = {
    register: 0xa9870000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(group, level, entries, board_change):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(BASE, group)
    events = []

    def write(name, fmt, value, offset=0):
        cpu.mem_write(LOADED[name] + offset, pack(fmt, value))

    def hook(machine, address, _size, _data):
        if address != UPDATE:
            events.append(('script', address))
            return
        eax, edx, ebx, ecx = (signed(machine.reg_read(register)) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        esp = machine.reg_read(UC_X86_REG_ESP)
        assert (edx, ebx, ecx, *unpack('<ii', machine.mem_read(esp + 4, 8))) == (0, *PLAYER)
        events.append(('actor', eax))
        if board_change and eax == board_change[0]:
            write('_current_level', '<b', board_change[1])

    cpu.mem_write(UPDATE, b'\xc2\x08\x00')
    for address in BOARD_SCRIPTS:
        cpu.mem_write(address, b'\xc3')
    for address in (*BOARD_SCRIPTS, UPDATE):
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)

    cpu.mem_write(LOADED['_dispatch_actor_enabled'], b'\xff' * 501)
    for index, status, board in entries:
        write('_dispatch_actor_enabled', '<b', status, index)
        write('_dispatch_actor_board', '<B', board, index)
    write('_current_level', '<b', level)
    for field, fmt, value in zip(('_player_x', '_player_y', '_player_z', '_player_sector'),
                                 ('<i', '<i', '<i', '<h'), PLAYER):
        write(field, fmt, value)

    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=10000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    return events


def expected(level, entries, board_change):
    events = []
    for index, status, board in sorted(entries):
        if index <= 500 and status != -1 and board == level:
            events.append(('actor', index))
            if board_change and index == board_change[0]:
                level = board_change[1]
    if 1 <= level <= 25:
        events.append(('script', BOARD_SCRIPTS[level - 1]))
    return events


def check(executable, obj):
    code, data_refs, code_refs, calls = bind(obj)
    raw = BASE + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE]
    assert (len(data_refs), len(code_refs), len(calls)) == (8, 26, 26)
    verify_leaf_relocations(code, data_refs | code_refs, read_le_fixups(executable)['pointers'],
                            BASE, code_bindings=code_refs)
    code, _, _, _ = bind(obj, loaded=True)
    original = image(executable)[BASE:BASE + SIZE]

    cases = [
        (level, ((0, 1, level), (10, -1, level), (11, 0, level + 1),
                 (499, -2, level), (500, 0, level), (501, 0, level)), None)
        for level in range(1, 26)
    ]
    cases.extend([
        (0, ((0, 0, 0), (500, 0, 2)), None),
        (26, ((0, 0, 26), (500, 0, 2)), None),
        (-1, ((0, 0, 255), (500, 0, 2)), None),
        (4, ((0, 0, 4), (10, 0, 7), (11, 0, 4), (500, 0, 7)), (0, 7)),
    ])
    for args in cases:
        for body in (original, code):
            result = exercise(body, *args)
            assert result == expected(*args), (args, result, expected(*args))
    print(f'PASS: 462 exact group bytes, 34 LE pointers, {len(cases)} dispatcher scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
