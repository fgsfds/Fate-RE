"""Verify the original and Watcom C teleport terminal scans and destination side effects."""
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

ENTRY, SIZE, DATA_BASE = 0x13d9f, 334, 0x80000
ABSOLUTE, DELETE, SPECIAL, REPORT = 0x602c3, 0x50a09, 0x38800, 0x26a03
STACK, STOP = 0x3f0000, 0x3ff000
OFFSETS = {
    '_current_level': 0x7f87e, '_terminal_x': 0x3e74, '_terminal_y': 0x3e78,
    '_terminal_destination_x': 0x3e7c, '_terminal_destination_y': 0x3e80,
    '_terminal_destination_level': 0x3e84, '_terminal_destination_entry': 0x3e88,
    '_destination_level': 0x2040, '_destination_entry': 0x7deee, '_terminal_special_case': 0x6793d,
    '_terminal_projectiles': 0x7053c, '_projectile_count': 0x2bee, '_moving_sprite_count': 0x2be8,
    '_float_sprite_count': 0x2bec, '_active_sequence_count': 0x7dee0, '_player_x': 0x5ad9c,
    '_player_y': 0x5ad5c, '_destination_x': 0x7a998, '_destination_y': 0x7a99c,
    '_status_right_tenths': 0x6319c, '_terminal_special_counter': 0x77118, '_terminal_table_error': 0x268,
}
FUNCTIONS = {
    'absolute_long_': ABSOLUTE, 'remove_engine_sprite_': DELETE,
    'apply_terminal_special_case_': SPECIAL, 'report_game_error_': REPORT,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
SAVED = {
    register: 0xcab00000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}
PLAYER = (800, -1200)
OLD_DESTINATION = (40, 60, 17, 8)
OLD_SPECIAL = (7, 345, 12345)
DESTINATION_FIELDS = (('_destination_x', '<i'), ('_destination_y', '<i'),
                      ('_destination_level', '<B'), ('_destination_entry', '<h'))
TERMINAL_FIELDS = (('_terminal_x', '<i'), ('_terminal_y', '<i'),
                   ('_terminal_destination_x', '<i'), ('_terminal_destination_y', '<i'),
                   ('_terminal_destination_level', '<B'), ('_terminal_destination_entry', '<h'))
LIST_FIELDS = ('_moving_sprite_count', '_float_sprite_count', '_active_sequence_count')
SPECIAL_FIELDS = (('_terminal_special_case', '<B'), ('_status_right_tenths', '<i'),
                  ('_terminal_special_counter', '<i'))


def exercise(body, level, terminals, projectiles, blockers):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    events = []

    def write(name, fmt, value, offset=0):
        cpu.mem_write(DATA[name] + offset, pack(fmt, value))

    def read(name, fmt):
        width = len(pack(fmt, 0))
        return unpack(fmt, cpu.mem_read(DATA[name], width))[0]

    def hook(machine, address, _size, _data):
        eax = machine.reg_read(UC_X86_REG_EAX)
        if eax & 0x80000000:
            eax -= 0x100000000
        if address == ABSOLUTE:
            events.append(('distance', eax))
            machine.reg_write(UC_X86_REG_EAX, abs(eax))
        elif address == DELETE:
            events.append(('delete', eax))
        elif address == SPECIAL:
            assert read('_projectile_count', '<h') == 0
            assert tuple(read(*field) for field in SPECIAL_FIELDS) == (1, 100, 0)
            events.append(('special', tuple(read(*field) for field in DESTINATION_FIELDS)))
        elif address == REPORT:
            assert eax == DATA['_terminal_table_error']
            events.append(('error',))

    for address in (ABSOLUTE, DELETE, SPECIAL, REPORT):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    write('_current_level', '<b', level)
    for field, value in zip(('_player_x', '_player_y'), PLAYER):
        write(field, '<i', value)
    for field, value in zip(DESTINATION_FIELDS, OLD_DESTINATION):
        write(*field, value)
    for field, value in zip(SPECIAL_FIELDS, OLD_SPECIAL):
        write(*field, value)
    for field, value in zip(LIST_FIELDS, blockers):
        write(field, '<h', value)
    write('_projectile_count', '<h', len(projectiles))
    for slot, sprite in enumerate(projectiles, start=1):
        write('_terminal_projectiles', '<h', sprite, slot * 2)
    for slot in range(6):
        offset = 144 * level + 24 * slot
        record = terminals[slot] if slot < len(terminals) else (-1, 1, 0, 0, 0, 0)
        for field, value in zip(TERMINAL_FIELDS, record):
            write(*field, value, offset)

    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=1500)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    assert tuple(read(name, '<h') for name in LIST_FIELDS) == blockers
    return (read('_projectile_count', '<h'), tuple(read(*field) for field in DESTINATION_FIELDS),
            tuple(read(*field) for field in SPECIAL_FIELDS), events)


def expected(level, terminals, projectiles, blockers):
    events = []
    count, destination, status = len(projectiles), OLD_DESTINATION, OLD_SPECIAL
    for index in range(5):
        if index >= len(terminals):
            break
        x, y, *options = terminals[index]
        if x == -1:
            break
        dx, dy = x - PLAYER[0], y - PLAYER[1]
        events.append(('distance', dx))
        if abs(dx) >= 256:
            continue
        events.append(('distance', dy))
        if abs(dy) >= 256:
            continue
        events.extend(('delete', sprite) for sprite in projectiles[:count])
        count = 0
        if sum(blockers):
            continue
        destination = tuple(options)
        if level == 5 and index == 1:
            status = (1, 100, 0)
            events.append(('special', destination))
    else:
        events.append(('error',))
    return count, destination, status, events


def check(executable, obj):
    name = 'check_teleport_terminals_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 24
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]

    nearby = (PLAYER[0] + 255, PLAYER[1] - 255, 9000, -4321, 12, -200)
    other = (PLAYER[0], PLAYER[1], 735, -547, 16, 50)
    far_x = (PLAYER[0] + 256, *nearby[1:])
    far_y = (nearby[0], PLAYER[1] - 256, *nearby[2:])
    sentinel = (-1, *nearby[1:])
    projectiles, clear = (-7, 21), (0, 0, 0)
    cases = [
        (4, (), projectiles, clear),
        (4, (far_x, far_y), projectiles, clear),
        (4, (nearby,), projectiles, clear),
        (4, (nearby,), projectiles, (2, -2, 0)),
        (5, (far_x, nearby), projectiles, clear),
        (5, (nearby,), projectiles, clear),
        (4, (far_x, nearby), (), clear),
        (3, (nearby, other), projectiles, clear),
        (3, (far_x, sentinel, nearby), projectiles, clear),
        (3, (far_x,) * 5 + (nearby,), projectiles, clear),
    ]
    cases.extend((4, (nearby,), projectiles, blockers)
                 for blockers in ((1, 0, 0), (0, 1, 0), (0, 0, 1)))
    for args in cases:
        for body in (original, code):
            match = exercise(body, *args)
            assert match == expected(*args), (args, match, expected(*args))
    print(f'PASS: 334 exact bytes, 24 LE pointers, {len(cases)} terminal scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
