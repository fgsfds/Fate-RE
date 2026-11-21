"""Check exact portal visibility bytes and run bounded multi-sector fixtures.

The emulator executes the verified intersection and sector-height callees from
the pinned image. Both visibility versions run on the same guarded test map.
"""
import argparse
from pathlib import Path
from struct import pack, pack_into

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_ESP, UC_X86_REG_EBP, UC_X86_REG_EIP,
)

from check_ksqrt import table_value
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'cansee_'
ENTRY, STACK, STOP = 0x50d33, 0x3ff000, 0x3fff00
DATA = {name: DS + DATA_OFFSETS['_' + name] for name in ('sector', 'wall', 'visibility_queue')}
SAVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
CASES = (
    ('same XY and sector', (500, 0, 123, 0), (500, 0, 888, 0), (), (), (), 1, ()),
    ('same XY and different sector', (500, 0, 0, 0), (500, 0, 0, 1), (), (), (), 0, ()),
    ('inside first room', (500, 0, 0, 0), (700, 50, 0, 0), (), (), (), 1, (0,)),
    ('destination sector not reached', (500, 0, 0, 0), (700, 50, 0, 1), (), (), (), 0, (0,)),
    ('one open portal', (500, 0, 0, 0), (1500, 50, 0, 1), (), (), (), 1, (0, 1)),
    ('two open portals', (500, 0, 0, 0), (2500, 50, 0, 2), (), (), (), 1, (0, 1, 2)),
    ('reverse portals', (2500, 30, 0, 2), (500, -30, 0, 0), (), (), (), 1, (2, 1, 0)),
    ('outside at solid wall', (500, 0, 0, 0), (4000, 50, 0, 2), (), (), (), 0, (0, 1, 2)),
    ('first blocking flag', (500, 0, 0, 0), (2500, 50, 0, 2), (1,), (), (), 0, (0,)),
    ('second blocking flag', (500, 0, 0, 0), (2500, 50, 0, 2), (5,), (), (), 0, (0, 1)),
    ('ceiling equality', (500, 0, -4096, 0), (1500, 0, -4096, 1), (), (), (), 0, (0,)),
    ('neighbor floor equality', (500, 0, 950, 0), (1500, 0, 950, 1), (), ((1, 950),), (), 0, (0,)),
    ('neighbor below floor', (500, 0, 951, 0), (1500, 0, 951, 1), (), ((1, 950),), (), 0, (0,)),
    ('neighbor strictly above floor', (500, 0, 949, 0), (1500, 0, 949, 1),
     (), ((1, 950),), (), 1, (0, 1)),
    ('neighbor elevated slope blocks', (500, 0, 4100, 0), (1500, 0, 4100, 1),
     (), ((0, 8192),), ((1, 0, -4096),), 0, (0,)),
    ('neighbor lowered slope passes', (500, 0, 4100, 0), (1500, 0, 4100, 1),
     (), ((0, 8192),), ((1, 0, 4096),), 1, (0, 1)),
)


def layout(blockers, floors, slopes):
    sector = bytearray(3 * 40)
    wall = bytearray(12 * 32)
    extra_floors = dict(floors)
    slope_fields = {idx: (ceiling_grad, floor_grad) for idx, ceiling_grad, floor_grad in slopes}
    portals = {1: (7, 1), 7: (1, 0), 5: (11, 2), 11: (5, 1)}
    for index in range(3):
        offset = index * 40
        gradients = slope_fields.get(index, (0, 0))
        pack_into('<2h2i2h', sector, offset, 4 * index, 4, -4096, extra_floors.get(index, 4096),
                  2 if gradients[0] else 0, 2 if gradients[1] else 0)
        pack_into('<h', sector, offset + 18, gradients[0])
        pack_into('<h', sector, offset + 26, gradients[1])
        x = index * 1024
        for edge, (wx, wy) in enumerate(((x, -512), (x + 1024, -512), (x + 1024, 512), (x, 512))):
            wall_index = 4 * index + edge
            next_wall, next_sector = portals.get(wall_index, (-1, -1))
            pack_into('<2i3hH', wall, 32 * wall_index, wx, wy, 4 * index + (edge + 1) % 4,
                      next_wall, next_sector, 32 if wall_index in blockers else 0)
    return bytes(sector), bytes(wall)


def check_case(code, original, start, end, blockers, floors, slopes, visible, queued):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(0x10000, original[0x10000:])
    machine.mem_write(ENTRY, code)
    sectors, walls = layout(blockers, floors, slopes)
    machine.mem_write(DATA['sector'], sectors)
    machine.mem_write(DATA['wall'], walls)
    table = DS + DATA_OFFSETS['_sqrtable']
    machine.mem_write(table, pack('<2048H', *(table_value(index) for index in range(2048))))
    queue = DATA['visibility_queue']
    machine.mem_write(queue - 4, b'left' + b'\xcd' * 16 + b'edge')
    for index, reg in enumerate(SAVED):
        machine.reg_write(reg, 0x123400 + index)
    for reg, value in zip(ARGS, start):
        machine.reg_write(reg, value & 0xffffffff)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<I4i', STOP, *end))
    machine.emu_start(ENTRY, STOP, count=50000)

    assert machine.reg_read(UC_X86_REG_EAX) == visible
    assert machine.mem_read(queue - 4, 24) == (
        b'left' + pack('<' + 'h' * len(queued), *queued) + b'\xcd' * (16 - 2 * len(queued)) + b'edge'
    )
    assert machine.mem_read(DATA['sector'], len(sectors)) == sectors
    assert machine.mem_read(DATA['wall'], len(walls)) == walls
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
                raise AssertionError(f'{label} visibility case {name} failed') from error
    return size, len(bindings), len(CASES)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing cansee_')
    args = parser.parse_args()
    size, relocations, cases = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {size} bytes, {relocations} LE relocations, {cases} original and {cases} restored visibility cases')
