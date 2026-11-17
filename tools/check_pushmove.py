"""Verify the exact wall-penetration routine on guarded two-sector examples."""
import argparse
from math import sin, tau
from pathlib import Path
from struct import pack, pack_into

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_ESP, UC_X86_REG_EBP, UC_X86_REG_EIP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'pushmove_'
ENTRY, STACK, STOP, POSITION = 0x53edd, 0x3ff000, 0x3fff00, 0x3fe004
DATA = {
    name: DS + DATA_OFFSETS['_' + name]
    for name in ('sector', 'wall', 'clipsectorlist', 'clipsectnum', 'sintable', 'numsectors')
}
SAVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
SINE = pack('<2048h', *(round(16384 * sin(index * tau / 2048)) for index in range(2048)))

# Coordinates, portal status, flags, neighbor ceiling/floor, parallax flags,
# clip type, expected result and final position.
CASES = (
    ('invalid sector', (500, 0, 0, -1), False, 0, -4096, 4096, 0, 0, 0, -1, (500, 0, 0, -1)),
    ('clear inside', (500, 0, 14, 0), False, 0, -4096, 4096, 0, 0, 0, 0, (500, 0, 14, 0)),
    ('solid right wall', (1000, 0, 0, 0), False, 0, -4096, 4096, 0, 0, 0, 0, (896, 0, 0, 0)),
    ('solid upper wall', (500, -500, 0, 0), False, 0, -4096, 4096, 0, 0, 0, 0, (500, -388, 0, 0)),
    ('corner', (1000, -500, 0, 0), False, 0, -4096, 4096, 0, 0, 0, 0, (896, -388, 0, 0)),
    ('open portal', (1000, 0, 0, 0), True, 0, -4096, 4096, 0, 0, 0, 0, (1000, 0, 0, 0)),
    ('blocking flag 1', (1000, 0, 0, 0), True, 1, -4096, 4096, 0, 0, 0, 0, (896, 0, 0, 0)),
    ('blocking flag 64', (1000, 0, 0, 0), True, 64, -4096, 4096, 0, 0, 1, 0, (896, 0, 0, 0)),
    ('flag 64 ignored for type 0', (1000, 0, 0, 0), True, 64, -4096, 4096, 0, 0, 0, 0, (1000, 0, 0, 0)),
    ('floor rise', (1000, 0, 0, 0), True, 0, -4096, -1024, 0, 0, 0, 0, (896, 0, 0, 0)),
    ('parallax floor', (1000, 0, 0, 0), True, 0, -4096, -1024, 0, 1, 0, 0, (1000, 0, 0, 0)),
    ('low ceiling', (1000, 0, 0, 0), True, 0, 32, 4096, 0, 0, 0, 0, (896, 0, 0, 0)),
    ('parallax ceiling', (1000, 0, 0, 0), True, 0, 32, 4096, 1, 0, 0, 0, (1000, 0, 0, 0)),
    ('near contact', (1023, 0, 0, 0), False, 0, -4096, 4096, 0, 0, 0, 0, (895, 0, 0, 0)),
)


def geometry(portal, flags, neighbor_ceiling, neighbor_floor, ceiling_flag, floor_flag):
    sectors = bytearray(80)
    walls = bytearray(8 * 32)
    portals = {1: (7, 1), 7: (1, 0)} if portal else {}
    for index in range(2):
        ceiling, floor = (neighbor_ceiling, neighbor_floor) if index else (-4096, 4096)
        cs, fs = (ceiling_flag, floor_flag) if index else (0, 0)
        pack_into('<2h2i2h', sectors, index * 40, 4 * index, 4, ceiling, floor, cs, fs)
        x = index * 1024
        for edge, (wx, wy) in enumerate(((x, -512), (x + 1024, -512), (x + 1024, 512), (x, 512))):
            wall = 4 * index + edge
            next_wall, next_sector = portals.get(wall, (-1, -1))
            pack_into('<2i3hH', walls, 32 * wall, wx, wy, 4 * index + (edge + 1) % 4,
                      next_wall, next_sector, flags if wall == 1 else 0)
    return bytes(sectors), bytes(walls)


def check_case(code, original, position, portal, flags, neighbor_ceiling, neighbor_floor,
               ceiling_flag, floor_flag, clip_type, status, expected_position):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(0x10000, original[0x10000:])
    machine.mem_write(ENTRY, code)
    sectors, walls = geometry(portal, flags, neighbor_ceiling, neighbor_floor, ceiling_flag, floor_flag)
    machine.mem_write(DATA['sector'], sectors)
    machine.mem_write(DATA['wall'], walls)
    machine.mem_write(DATA['numsectors'], pack('<h', 2))
    machine.mem_write(DATA['sintable'], SINE)
    machine.mem_write(DATA['clipsectorlist'] - 4, b'left' + b'\xcd' * 16 + b'edge')
    machine.mem_write(POSITION - 4, b'left' + pack('<3ih', *position) + b'edge')

    for index, reg in enumerate(SAVED):
        machine.reg_write(reg, 0x123400 + index)
    for reg, offset in zip(ARGS, (0, 4, 8, 12)):
        machine.reg_write(reg, POSITION + offset)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<I4i', STOP, 128, 128, 128, clip_type))
    machine.emu_start(ENTRY, STOP, count=100000)

    assert machine.reg_read(UC_X86_REG_EAX) == status & 0xffffffff
    assert machine.mem_read(POSITION - 4, 22) == b'left' + pack('<3ih', *expected_position) + b'edge', (
        bytes(machine.mem_read(POSITION, 14)).hex(), expected_position,
    )
    assert machine.mem_read(DATA['sector'], len(sectors)) == sectors
    assert machine.mem_read(DATA['wall'], len(walls)) == walls
    assert machine.mem_read(DATA['clipsectorlist'] - 4, 4) == b'left'
    assert machine.mem_read(DATA['clipsectorlist'] + 16, 4) == b'edge'
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK + 20
    assert [machine.reg_read(reg) for reg in SAVED] == [0x123400 + i for i in range(len(SAVED))]


def check(executable, obj):
    original = image(executable)
    raw, size = LEAVES[SYMBOL]
    assert raw - 0x25600 == ENTRY
    code, bindings = bind_leaf_details(
        obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    assert len(code) == size and code == executable[raw:raw + size]
    verify_leaf_relocations(code, bindings, read_le_fixups(executable)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, SYMBOL, {'_' + name: address for name, address in DATA.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    for label, source in (('original', original[ENTRY:ENTRY + size]), ('restored', restored)):
        for name, *case in CASES:
            try:
                check_case(source, original, *case)
            except AssertionError as error:
                raise AssertionError(f'{label} wall-penetration case {name} failed') from error
    return size, len(bindings), len(CASES)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing pushmove_')
    args = parser.parse_args()
    size, relocations, cases = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {size} bytes, {relocations} LE relocations, {cases} original and {cases} restored wall-push cases')
