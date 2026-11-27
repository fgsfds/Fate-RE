"""Verify sector panning for every original jump-table entry."""
import argparse
from pathlib import Path
from struct import pack, unpack_from

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX,
    UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    CODE_OFFSETS, DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details,
    verify_leaf_relocations,
)
from verify_c_suite import PAN_ENTRIES

RAW = LEAVES['update_sector_panning_'][0]
ENTRY = RAW - 0x25600
TABLE = CODE_OFFSETS['_pan_dispatch']
STACK, STOP = 0x3f0000, 0x3ff000
PAN_FIELDS = ('_pan_floor_x', '_pan_floor_y', '_pan_ceiling_x', '_pan_ceiling_y')
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)


def check_case(code, destinations, clock, count):
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0, 0x400000)
    emulator.mem_write(ENTRY, code)
    emulator.mem_write(TABLE, pack('<12I', *destinations))
    emulator.mem_write(STACK, pack('<I', STOP))
    emulator.reg_write(UC_X86_REG_ESP, STACK)
    for index, register in enumerate(SAVED):
        emulator.reg_write(register, 0x12340000 + index)
    data = DATA_OFFSETS
    emulator.mem_write(data['_pan_clock'], pack('<i', clock))
    emulator.mem_write(data['_pan_sector_count'], pack('<h', count))
    emulator.mem_write(data['_pan_sectors'], pack('<15h', *range(15)))

    slow, normal, fast = (clock >> 2) & 255, clock & 255, (clock << 2) & 255
    ceiling_slow = (clock >> 4) & 255
    updates = (
        {0: slow}, {0: normal}, {0: fast},
        {1: slow}, {1: normal}, {1: fast, 2: ceiling_slow},
        {2: ceiling_slow}, {2: normal}, {2: fast},
        {3: ceiling_slow}, {3: normal}, {3: fast},
    )
    tags = (18, *range(18, 30), 17, 30)
    for index, tag in enumerate(tags):
        emulator.mem_write(data['_pan_sector_tag'] + index * 40, pack('<h', tag))
        for field, name in enumerate(PAN_FIELDS):
            emulator.mem_write(data[name] + index * 40, bytes((0xa0 + field,)))
    emulator.emu_start(ENTRY, STOP, count=1000)
    assert emulator.reg_read(UC_X86_REG_EIP) == STOP
    assert emulator.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(emulator.reg_read(reg) for reg in SAVED) == tuple(0x12340000 + i for i in range(5))
    for index, tag in enumerate(tags):
        actual = tuple(emulator.mem_read(data[name] + index * 40, 1)[0] for name in PAN_FIELDS)
        expected = [0xa0, 0xa1, 0xa2, 0xa3]
        if 1 <= index <= count and 18 <= tag <= 29:
            for field, value in updates[tag - 18].items():
                expected[field] = value
        assert actual == tuple(expected), (clock, count, index, actual, expected)


def check(executable, obj):
    expected, restored = bytearray(), bytearray()
    pointers = read_le_fixups(executable)['pointers']
    sites = 0
    for symbol in PAN_ENTRIES:
        raw, size = LEAVES[symbol]
        entry = raw - 0x25600
        code_bindings = {}
        code, bindings = bind_leaf_details(
            obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES,
            absolute_code=CODE_OFFSETS, code_bindings=code_bindings,
        )
        assert code == executable[raw:raw + size], symbol
        verify_leaf_relocations(code, bindings, pointers, entry, code_bindings=code_bindings)
        expected.extend(executable[raw:raw + size])
        restored.extend(code)
        sites += len(bindings)
    destinations = [value + 0x10000 for value in unpack_from('<12I', executable, RAW - 48)]
    for code in (bytes(expected), bytes(restored)):
        for clock, count in ((0x12b, 14), (-19, 14), (0x12b, 0)):
            check_case(code, destinations, clock, count)
    print(f'PASS: {len(expected)} exact bytes, {sites} LE relocations, '
          '12 panning modes plus count and invalid-tag cases for original and restored code')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())


if __name__ == '__main__':
    main()
