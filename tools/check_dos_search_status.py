"""Check DOS find-status translation with the original carry-flag ABI."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EFLAGS, UC_X86_REG_ESP

from check_start_hook import image
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf

SYMBOL = 'dos_search_status_'
ENTRY = FUNCTION_ADDRESSES[SYMBOL]
SET_ERRNO = FUNCTION_ADDRESSES['set_dos_errno_']
STACK, STOP = 0x3f0000, 0x3ff000


def run_case(code, carry, status):
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0, 0x400000)
    emulator.mem_write(ENTRY, code)
    # The stub records the argument, then clobbers EAX as the DOS helper may.
    emulator.mem_write(SET_ERRNO, b'\xb8\xff\xff\xff\xff\xc3')
    emulator.mem_write(STACK, pack('<I', STOP))
    emulator.reg_write(UC_X86_REG_ESP, STACK)
    emulator.reg_write(UC_X86_REG_EAX, status)
    emulator.reg_write(UC_X86_REG_EFLAGS, 2 | carry)
    errno_calls = []

    def record_errno(cpu, address, size, user_data):
        errno_calls.append(cpu.reg_read(UC_X86_REG_EAX))

    emulator.hook_add(UC_HOOK_CODE, record_errno, begin=SET_ERRNO, end=SET_ERRNO)
    emulator.emu_start(ENTRY, STOP, count=24)
    assert emulator.reg_read(UC_X86_REG_ESP) == STACK + 4
    expected = status & 0xffff if carry else 0
    assert emulator.reg_read(UC_X86_REG_EAX) == expected
    assert errno_calls == ([expected] if carry else [])


def check(executable, obj):
    raw, size = LEAVES[SYMBOL]
    expected = image(executable)[ENTRY:ENTRY + size]
    assert expected == executable[raw:raw + size]
    restored, relocations = bind_leaf(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert restored == expected and relocations == 0
    for code in (expected, restored):
        run_case(code, 0, 0x12340012)
        run_case(code, 1, 0x12340012)
        run_case(code, 1, 0x89abffff)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
    print('PASS: 19 exact bytes and 3 original/restored DOS search status cases')


if __name__ == '__main__':
    main()
