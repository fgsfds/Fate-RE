"""Exercise original and restored keepaway on directed clip lines."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations,
)

ENTRY, RESTORE, SIZE = 0x53C2E, 0x47F04, 167
POINT, STACK, STOP = 0x350000, 0x3F0000, 0x3FF000
LINE, REGISTER_LINE = 7, 0xCCDD0007
SAVED = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
PRIOR = (0x11223344, 0x22334455, 0x33445566, 0x44556677)


@dataclass(frozen=True)
class Case:
    name: str
    start: tuple
    end: tuple
    point: tuple
    expected: tuple


CASES = (
    Case('already outside', (20, 30), (30, 35), (20, 31), (20, 31)),
    Case('horizontal forward', (20, 30), (30, 30), (24, 27), (24, 31)),
    Case('horizontal reverse', (20, 30), (10, 30), (16, 33), (16, 29)),
    Case('vertical forward', (20, 30), (20, 40), (23, 34), (19, 34)),
    Case('vertical reverse', (20, 30), (20, 20), (17, 26), (21, 26)),
    Case('equal axis magnitudes', (20, 30), (26, 36), (22, 32), (22, 33)),
    Case('greater horizontal magnitude', (20, 30), (29, 34), (22, 30), (21, 31)),
    Case('greater vertical magnitude', (20, 30), (16, 39), (21, 30), (20, 29)),
    Case('both slopes negative', (20, 30), (15, 24), (19, 30), (20, 29)),
    Case('wrapped signed cross product', (0, 0), (0x40000001, 1), (0, 3), (-1, 4)),
)


def run_case(code, original, case):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3F0000)
    machine.mem_write(ENTRY, code)
    machine.mem_write(RESTORE, original[RESTORE:RESTORE + 8])
    for name, value in zip(('_clipx1', '_clipx2', '_clipy1', '_clipy2'),
                           (case.start[0], case.end[0], case.start[1], case.end[1])):
        machine.mem_write(DS + DATA_OFFSETS[name] + LINE * 4, pack('<i', value))
    machine.mem_write(POINT, pack('<4i', -7064, *case.point, 6543))
    machine.mem_write(STACK, pack('<I', STOP))
    for register, value in zip(SAVED, PRIOR):
        machine.reg_write(register, value)
    for register, value in (
        (UC_X86_REG_EAX, POINT + 4), (UC_X86_REG_EDX, POINT + 8),
        (UC_X86_REG_EBX, REGISTER_LINE), (UC_X86_REG_ESP, STACK),
    ):
        machine.reg_write(register, value)
    machine.emu_start(ENTRY, STOP, count=2000)
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(machine.reg_read(register) for register in SAVED) == PRIOR
    actual = unpack('<4i', machine.mem_read(POINT, 16))
    assert actual == (-7064, *case.expected, 6543), (actual, case.expected)


def check(executable, obj):
    original = image(executable)
    raw = ENTRY + 0x25600
    bytes_at_entry = executable[raw:raw + SIZE]
    code, refs = bind_leaf_details(obj, 'keepaway_', DATA_OFFSETS, address=ENTRY,
                                    functions=FUNCTION_ADDRESSES)
    assert code == bytes_at_entry
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    code, _ = bind_leaf_details(obj, 'keepaway_', loaded, address=ENTRY,
                                 functions=FUNCTION_ADDRESSES)
    for label, data in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', code)):
        for case in CASES:
            try:
                run_case(data, original, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return len(refs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing keepaway')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} keepaway bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored cases')


if __name__ == '__main__':
    main()
