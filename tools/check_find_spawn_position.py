"""Verify spawn sector filtering, bounds, retry budget, and clipping ABI."""
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

SYMBOL = 'find_spawn_position_'
ENTRY, SIZE, BASE = 0x2e5fc, 507, 0x80000
STACK, STOP, COORDS = 0x3e0000, 0x3ff000, 0x380000
X, Y, SECTOR = (COORDS + 4 * i for i in range(3))
INSIDE, PUSHMOVE, KRAND = 0x4c88f, 0x53edd, 0x562e5
PRESERVED = (UC_X86_REG_ECX, UC_X86_REG_EBP, UC_X86_REG_ESI, UC_X86_REG_EDI)
OFFSETS = {
    '_numsectors': 0x289154, '_spawn_hitag': 0x27c3c4, '_spawn_lotag': 0x27c3c2,
    '_spawn_floor_flags': 0x27c3ae, '_spawn_first_wall': 0x27c3a0, '_spawn_wall_count': 0x27c3a2,
    '_spawn_ceiling': 0x27c3a4, '_spawn_floor': 0x27c3a8,
    '_spawn_wall_x': 0x2310a0, '_spawn_wall_y': 0x2310a4,
}
DATA = {name: BASE + offset for name, offset in OFFSETS.items()}
CALLBACKS = {
    'inside_': INSIDE, 'pushmove_': PUSHMOVE, 'krand_': KRAND,
    'spawn_try_sector_': 0x2e613, 'spawn_test_retry_budget_': 0x2e7e4,
}
ORIGIN = (111, -222, 7)
CENTER = (-70, -29)


def signed(value):
    return value - 0x100000000 if value & 0x80000000 else value


def exercise(body, room_changes, samples, inside_results, clip_results):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(X, pack('<iih', *ORIGIN))

    def read(address, fmt):
        return unpack(fmt, cpu.mem_read(address, len(pack(fmt, 0))))[0]

    def put(field, fmt, value, offset=0):
        cpu.mem_write(DATA[field] + offset, pack(fmt, value))

    rooms = [dict(ceiling=0, floor=16000, lotag=0, hitag=0, floor_flags=0,
                  wall_count=4, width=420, height=360) for _ in range(4)]
    put('_numsectors', '<h', len(rooms))
    for i, room in enumerate(rooms):
        room.update(room_changes.get(i, {}))
        first_wall = 10 + 4 * i
        offset = 40 * i
        put('_spawn_first_wall', '<h', first_wall, offset)
        for name in ('ceiling', 'floor', 'lotag', 'hitag', 'floor_flags', 'wall_count'):
            fmt = '<i' if name in ('ceiling', 'floor') else '<h'
            put('_spawn_' + name, fmt, room[name], offset)
        left, top = -280, -209
        right, bottom = left + room['width'], top + room['height']
        for wall, (x, y) in enumerate(((left, top), (right, top), (right, bottom), (left, bottom)), first_wall):
            put('_spawn_wall_x', '<i', x, 32 * wall)
            put('_spawn_wall_y', '<i', y, 32 * wall)

    seen = []
    random_samples, inside_results, clip_results = map(iter, (samples, inside_results, clip_results))

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx = (machine.reg_read(reg) for reg in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if address == KRAND:
            picked = next(random_samples)
            seen.append(('sample', picked))
            machine.reg_write(UC_X86_REG_EAX, 0x4000 * picked)
        elif address == INSIDE:
            seen.append(('inside', (signed(eax), signed(edx)), ebx))
            machine.reg_write(UC_X86_REG_EAX, next(inside_results))
        elif address == PUSHMOVE:
            stack = machine.reg_read(UC_X86_REG_ESP)
            assert bytes(machine.mem_read(stack + 4, 16)) == pack('<4I', 128, 1024, 1024, 0)
            sector = read(ecx, '<h')
            assert read(ebx, '<i') == rooms[sector]['floor'] - 8192
            seen.append(('clip', (read(eax, '<i'), read(edx, '<i')), sector))
            result = next(clip_results)
            if result >= 0:
                machine.mem_write(eax, pack('<i', read(eax, '<i') + 9))
                machine.mem_write(edx, pack('<i', read(edx, '<i') - 5))
                machine.mem_write(ecx, pack('<h', sector + 1))
            machine.reg_write(UC_X86_REG_EAX, result & 0xffffffff)

    for address in (INSIDE, PUSHMOVE, KRAND):
        code = b'\xc2\x10\x00' if address == PUSHMOVE else b'\xc3'
        cpu.mem_write(address, code)
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    for register, value in ((UC_X86_REG_EAX, X), (UC_X86_REG_EDX, Y), (UC_X86_REG_EBX, SECTOR),
                            (UC_X86_REG_ESP, STACK)):
        cpu.reg_write(register, value)
    for i, register in enumerate(PRESERVED, 1):
        cpu.reg_write(register, 0x77770000 | i)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\x99' * 16)
    cpu.emu_start(ENTRY, STOP, count=20000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\x99' * 16
    for i, register in enumerate(PRESERVED, 1):
        assert cpu.reg_read(register) == 0x77770000 | i
    assert next(random_samples, None) is None
    return (read(X, '<i'), read(Y, '<i'), read(SECTOR, '<h')), seen


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSETS, address=ENTRY, functions=CALLBACKS)
    raw = ENTRY + 0x25600
    assert len(refs) == 15 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACKS)
    original = bytes(image(executable)[ENTRY:ENTRY + SIZE])

    def accepted(sector):
        return (CENTER[0] + 9, CENTER[1] - 5, sector + 1)

    cases = (
        ({3: {'hitag': 0x4100}}, [3], [1], [0],
         (accepted(3), [('sample', 3), ('inside', CENTER, 3), ('clip', CENTER, 3)])),
        ({0: {'floor': 2048}, 1: {'lotag': 1}, 2: {'floor_flags': 1}}, [0, 1, 2, 3], [1], [0],
         (accepted(3), [('sample', 0), ('sample', 1), ('sample', 2), ('sample', 3),
                        ('inside', CENTER, 3), ('clip', CENTER, 3)])),
        ({0: {'width': 256}, 1: {'height': 256}}, [0, 1, 2], [1], [0],
         (accepted(2), [('sample', 0), ('sample', 1), ('sample', 2),
                        ('inside', CENTER, 2), ('clip', CENTER, 2)])),
        ({}, [0, 1, 2], [0, 1, 1], [-1, 0],
         (accepted(2), [('sample', 0), ('inside', CENTER, 0), ('sample', 1), ('inside', CENTER, 1),
                        ('clip', CENTER, 1), ('sample', 2), ('inside', CENTER, 2), ('clip', CENTER, 2)])),
        ({0: {'wall_count': 0}}, [0] * 257, [], [], (ORIGIN, [('sample', 0)] * 257)),
    )
    for body in (original, relocated):
        for *inputs, expected in cases:
            result = exercise(body, *inputs)
            assert result == expected, (inputs, result, expected)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} spawn scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
