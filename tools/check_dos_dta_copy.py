"""Check the historical DOS DTA transfer ABI and its extender guard."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_INTR
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EFLAGS, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

EXTENDER_TYPE = DATA_OFFSETS['_dos_extender_type']
CALLER, DOS, STACK, STOP = 0x300000, 0x310000, 0x3f0000, 0x3ff000
SIZE = 43


def run_case(code, entry, extender, to_caller):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x400000)
    cpu.mem_write(entry, code)
    cpu.mem_write(EXTENDER_TYPE, bytes([extender]))
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EFLAGS, 2)
    registers = {
        UC_X86_REG_EAX: 0x1234abcd, UC_X86_REG_EBX: 0x11223344,
        UC_X86_REG_ECX: 0x55667788, UC_X86_REG_EDX: CALLER,
        UC_X86_REG_ESI: 0x90abcdef, UC_X86_REG_EDI: 0xfedcba09,
    }
    for register, value in registers.items():
        cpu.reg_write(register, value)
    source, destination = (DOS, CALLER) if to_caller else (CALLER, DOS)
    payload = bytes(range(SIZE))
    cpu.mem_write(source - 1, b'\xf1' + payload + b'\xf2')
    cpu.mem_write(destination - 1, b'\xa5' * (SIZE + 2))
    calls = []

    def get_dta(emulator, interrupt, user_data):
        assert interrupt == 0x21
        assert (emulator.reg_read(UC_X86_REG_EAX) >> 8) & 0xff == 0x2f
        calls.append(interrupt)
        emulator.reg_write(UC_X86_REG_EBX, DOS)

    cpu.hook_add(UC_HOOK_INTR, get_dta)
    cpu.emu_start(entry, STOP, count=100)
    assert len(calls) == (1 if extender == 9 else 0)
    expected = b'\xa5' + payload + b'\xa5' if extender == 9 else b'\xa5' * (SIZE + 2)
    assert cpu.mem_read(destination - 1, SIZE + 2) == expected
    assert cpu.mem_read(source - 1, SIZE + 2) == b'\xf1' + payload + b'\xf2'
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    for register, value in registers.items():
        assert cpu.reg_read(register) == value


def check(executable, obj):
    fixups = read_le_fixups(executable)['pointers']
    for symbol, to_caller in [('copy_dta_to_caller_', True), ('copy_caller_to_dta_', False)]:
        entry = FUNCTION_ADDRESSES[symbol]
        raw, size = LEAVES[symbol]
        expected = executable[raw:raw + size]
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry,
                                             functions=FUNCTION_ADDRESSES)
        assert code == expected and len(references) == 1
        verify_leaf_relocations(code, references, fixups, entry)
        for data in (expected, code):
            for extender in (0, 9, 10):
                run_case(data, entry, extender, to_caller)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
    print('PASS: 70 exact bytes, 2 LE relocations and 6 original/restored DTA cases')


if __name__ == '__main__':
    main()
