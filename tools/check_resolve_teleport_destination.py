"""Verify teleport destination selection, coordinates, and positioned sound calls."""
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
from verify_c_leaf import FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

SYMBOL = 'resolve_teleport_destination_'
ENTRY, SIZE, DATA_BASE = 0x2e7f7, 501, 0x80000
STACK, STOP, COORDS = 0x3e0000, 0x3ff000, 0x380000
X, Y, Z, ANGLE, SECTOR = (COORDS + 4 * i for i in range(5))
PRESERVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSETS = {
    '_teleport_sound_name': 0x5a8, '_teleport_sectors': 0x1ccac, '_teleport_count': 0x7dece,
    '_teleport_wall_x': 0x2310a0, '_teleport_wall_y': 0x2310a4, '_teleport_wall_next': 0x2310a8,
    '_teleport_wall_link': 0x2310ac, '_teleport_sector_wall_starts': 0x27c3a0,
    '_teleport_sector_wall_counts': 0x27c3a2, '_teleport_sector_floors': 0x27c3a8,
    '_teleport_sector_tags': 0x27c3c4,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
CALLBACKS = {name: FUNCTION_ADDRESSES[name] for name in
             ('updatesector_', 'getangle_', 'krand_', 'play_positioned_sound_')}


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, start, destinations, expected_sector, negative):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(X, pack('<iiihxxh', 1200, -360, 77, 41, start))

    def read(address, fmt):
        return unpack(fmt, cpu.mem_read(address, len(pack(fmt, 0))))[0]

    def put(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    put('_teleport_count', '<h', len(destinations))
    for i, sector in enumerate(destinations):
        put('_teleport_sectors', '<h', sector, 2 * i)
    for sector, tag in ((1, 0x201), (2, 0x50f), (3, 0x101), (4, 0x401)):
        put('_teleport_sector_tags', '<h', tag, 40 * sector)
        put('_teleport_sector_wall_starts', '<h', 10, 40 * sector)
        put('_teleport_sector_wall_counts', '<h', 3, 40 * sector)
        put('_teleport_sector_floors', '<i', 0x3000 + 200 * sector, 40 * sector)
    sign = -1 if negative else 1
    for i, (x, y, point, link) in enumerate(((9, 21, 11, 3), (-6, 3, 12, 1), (6, 1, 10, -1)), 10):
        put('_teleport_wall_x', '<i', sign * x, 32 * i)
        put('_teleport_wall_y', '<i', y, 32 * i)
        put('_teleport_wall_next', '<h', point, 32 * i)
        put('_teleport_wall_link', '<h', link, 32 * i)

    calls = []
    rolls = iter((0x182, 0x4ff))

    def record(machine, address, _size, _data):
        eax, edx, ebx, ecx = (machine.reg_read(reg) for reg in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if address == CALLBACKS['updatesector_']:
            assert ebx == SECTOR
            calls.append(('sector', signed(eax), signed(edx), read(ebx, '<h')))
            cpu.mem_write(ebx, pack('<h', 9))
        elif address == CALLBACKS['getangle_']:
            calls.append(('angle', signed(eax), signed(edx)))
            machine.reg_write(UC_X86_REG_EAX, 0x329)
        elif address == CALLBACKS['krand_']:
            calls.append(('random',))
            machine.reg_write(UC_X86_REG_EAX, next(rolls))
        elif address == CALLBACKS['play_positioned_sound_']:
            stack = machine.reg_read(UC_X86_REG_ESP)
            assert eax == DATA['_teleport_sound_name'] and read(stack + 8, '<I') == 0
            y_ptr = read(stack + 4, '<I')
            calls.append(('sound', edx, ebx, read(ecx, '<i'), read(y_ptr, '<i')))

    for name, address in CALLBACKS.items():
        code = b'\xc2\x08\x00' if name == 'play_positioned_sound_' else b'\xc3'
        cpu.mem_write(address, code)
        cpu.hook_add(UC_HOOK_CODE, record, begin=address, end=address)

    for register, value in ((UC_X86_REG_EAX, X), (UC_X86_REG_EDX, Y), (UC_X86_REG_EBX, Z),
                            (UC_X86_REG_ECX, ANGLE), (UC_X86_REG_ESP, STACK)):
        cpu.reg_write(register, value)
    for i, register in enumerate(PRESERVED, 1):
        cpu.reg_write(register, 0xaa550000 | i)
    cpu.mem_write(STACK, pack('<II', STOP, SECTOR) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=900)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 8
    assert cpu.mem_read(STACK + 8, 16) == b'\xa5' * 16
    for i, register in enumerate(PRESERVED, 1):
        assert cpu.reg_read(register) == 0xaa550000 | i

    expected_x = sign * 3
    assert read(X, '<i') == expected_x and read(Y, '<i') == 8
    assert read(Z, '<i') == 0x1000 + 200 * expected_sector
    assert read(ANGLE, '<h') == 0x329 and read(SECTOR, '<h') == 9
    expected = [('sector', expected_x, 8, expected_sector), ('angle', -expected_x, -6), ('random',),
                ('sound', 0xbc2, 0xc0, 1200, -360), ('random',), ('sound', 0x103f, 0x100, expected_x, 8)]
    assert calls == expected, (calls, expected)


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSETS, address=ENTRY, functions=CALLBACKS)
    raw = ENTRY + 0x25600
    assert len(refs) == 20 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACKS)
    original = bytes(image(executable)[ENTRY:ENTRY + SIZE])
    scenarios = (
        (1, [1, 2, 3], 3, False),
        (3, [1, 2, 3], 1, True),
        (4, [1, 2, 3], 4, False),
        (2, [1, 2, 3], 2, True),
        (4, [], 4, True),
    )
    for body in (original, relocated):
        for scenario in scenarios:
            exercise(body, *scenario)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(scenarios)} teleport scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
