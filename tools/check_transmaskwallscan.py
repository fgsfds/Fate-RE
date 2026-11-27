"""Check the translucent wall dispatcher, cache touch and VGA plane selection."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_INSN
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX,
    UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x49DD1, 440
RESTORE, TIMER = 0x50347, 0x31EC4
LOAD, SETUP, SINGLE, PAIR = 0x4BB0D, 0x74310, 0x4AA28, 0x4ABC5
STACK, STOP, TILE, VIEW_LEFT = 0x3F0000, 0x3FF000, 13, 40
CASES = (
    ('linear paired and final single', False, 0, 6, 0, (), (16, 32), False, 0),
    ('linear clipped odd start and lazy tile', False, 0, 6, 0, (0,), (16, 32), True, 200),
    ('linear fully clipped', False, 2, 5, 0, (2, 3, 4, 5), (16, 32), False, 199),
    ('short planar span', True, 1, 2, 1, (), (16, 32), False, 0),
    ('all four planar groups', True, 0, 11, 2, (), (16, 32), False, 255),
    ('planar clip skipping', True, 0, 11, 0, (0, 1, 3, 4, 5), (16, 32), True, 42),
    ('zero tile width', False, 1, 5, 0, (), (0, 32), True, 0),
    ('negative tile height', True, 1, 5, 0, (), (16, -1), True, 200),
)


def expected_render(planar, left, right, view, clipped):
    draws, ports = [], []
    if planar:
        planes = min(4, right - left + 1)
        stride = 4
    else:
        planes, stride = 1, 1
    for offset in range(planes):
        column = left + offset
        if planar:
            plane = (column + view) & 3
            ports.extend(((0x3C5, 1, 1 << plane), (0x3CE, 2, (plane << 8) + 4)))
        while column <= right and column in clipped:
            column += stride
        if column <= right and column & 1:
            draws.append((SINGLE, column))
            column += stride
        while column + stride <= right:
            draws.append((PAIR, column))
            column += 2 * stride
        while column <= right:
            draws.append((SINGLE, column))
            column += stride
    return draws, ports


def run_case(code, original, planar, left, right, view, clipped, dimensions, lazy, lock):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 6])

    def address(name):
        return DS + DATA_OFFSETS['_' + name]

    def put(fmt, name, *values, offset=0):
        cpu.mem_write(address(name) + offset, pack('<' + fmt, *values))

    put('h', 'globalpicnum', TILE)
    put('h', 'translucent_tile_shift', -70)
    put('i', 'windowx1', VIEW_LEFT)
    put('i', 'viewoffset', view)
    put('B', 'chainstat', planar)
    put('8B', 'pow2char', *(1 << bit for bit in range(8)))
    put('B', 'walock', lock, offset=TILE)
    put('B', 'gotpic', 0x02, offset=TILE >> 3)
    put('h', 'tilesizx', dimensions[0], offset=2 * TILE)
    put('h', 'tilesizy', dimensions[1], offset=2 * TILE)
    put('I', 'waloff', 0 if lazy else 0x350000, offset=4 * TILE)
    for column in clipped:
        put('h', 'startumost', 50, offset=2 * (VIEW_LEFT + column))
        put('h', 'startdmost', -50, offset=2 * (VIEW_LEFT + column))

    calls, ports, tail_stack = [], [], []

    def track_call(machine, target, _size, _user):
        value = machine.reg_read(UC_X86_REG_EAX)
        if value >= 0x80000000:
            value -= 0x100000000
        calls.append((target, None if target == TIMER else value))
        machine.reg_write(UC_X86_REG_EAX, 0x12345678)

    def track_port(_machine, port, width, value, _user):
        ports.append((port, width, value))

    def on_restore(machine, _address, _size, _user):
        tail_stack.append(machine.reg_read(UC_X86_REG_ESP))

    for target in (LOAD, SETUP, SINGLE, PAIR, TIMER):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, track_call, begin=target, end=target)
    cpu.hook_add(UC_HOOK_INSN, track_port, None, 1, 0, UC_X86_INS_OUT)
    cpu.hook_add(UC_HOOK_CODE, on_restore, begin=RESTORE, end=RESTORE)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, left)
    cpu.reg_write(UC_X86_REG_EDX, right)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    prior = tuple(0x1020304A + index for index in range(len(saved)))
    for register, value in zip(saved, prior):
        cpu.reg_write(register, value)
    cpu.emu_start(ENTRY, STOP, count=15000)

    assert tail_stack == [STACK - 20]
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior
    assert cpu.mem_read(address('walock') + TILE, 1)[0] == (199 if lock < 200 else lock)
    assert cpu.mem_read(address('gotpic') + (TILE >> 3), 1)[0] == 0x02 | (1 << (TILE & 7))

    if min(dimensions) <= 0:
        assert not calls and not ports
    else:
        draws, expected_ports = expected_render(planar, left, right, view, clipped)
        expected_calls = ([(LOAD, TILE)] if lazy else []) + [(SETUP, -70)] + draws + [(TIMER, None)]
        assert calls == expected_calls, (calls, expected_calls)
        assert ports == expected_ports, (ports, expected_ports)


def check(exe, obj):
    original = image(exe)
    raw = ENTRY + 0x25600
    code, references = bind_leaf_details(obj, 'transmaskwallscan_', DATA_OFFSETS, address=ENTRY,
                                          functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[raw:raw + SIZE]
    verify_leaf_relocations(code, references, read_le_fixups(exe)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, 'transmaskwallscan_', {name: value + DS for name, value in DATA_OFFSETS.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    for label, body in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', restored)):
        for name, *case in CASES:
            try:
                run_case(body, original, *case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {name}: {error}') from error
    return len(references)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing transmaskwallscan_')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, {len(CASES)} original and {len(CASES)} restored translucent wall cases')


if __name__ == '__main__':
    main()
