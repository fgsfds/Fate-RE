"""Exercise the reconstructed Watcom near-string search."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_DS, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX,
    UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ES, UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_GDTR,
    UC_X86_REG_SS,
)

from check_start_hook import image
from verify_c_leaf import FUNCTION_ADDRESSES

HAYSTACK, NEEDLE = 0x3fa000, 0x3fb000
STACK, STOP = 0x3ff000, 0x3fff00
PRESERVED = (
    UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_ESI,
)
CASES = (
    (b'', b'', 0),
    (b'abba', b'', 0),
    (b'', b'z', None),
    (b'ab', b'b', 1),
    (b'abc', b'c', 2),
    (b'abc', b'z', None),
    (b'abcd', b'z', None),
    (b'abc', b'bc', 1),
    (b'aaab', b'aab', 1),
    (b'abcd', b'abcdef', None),
    (b'aaxaax', b'aab', None),
    (b'\xff\xfe', b'\xfe', 1),
    (b'a\xff\xfe', b'\xff\xfe', 1),
    (b'a\0z', b'z', None),
)


def check(memory, haystack, needle, match):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    # Protected-mode segment loads during SCAS/CMPS use this flat GDT.
    cpu.mem_write(0x1000, pack('<QQQQ', 0, 0x00cf9a000000ffff,
                               0x00cf92000000ffff, 0x00cf92000000ffff))
    cpu.reg_write(UC_X86_REG_GDTR, (0, 0x1000, 31, 0))
    cpu.reg_write(UC_X86_REG_DS, 0x10)
    cpu.reg_write(UC_X86_REG_SS, 0x10)
    cpu.reg_write(UC_X86_REG_ES, 0x18)
    cpu.mem_write(HAYSTACK, haystack + b'\0')
    cpu.mem_write(NEEDLE, needle + b'\0')

    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, HAYSTACK)
    cpu.reg_write(UC_X86_REG_EDX, NEEDLE)
    for reg in PRESERVED:
        cpu.reg_write(reg, 0x12340000 + reg)

    cpu.emu_start(FUNCTION_ADDRESSES['strstr_'], STOP, count=1000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.reg_read(UC_X86_REG_ES) == 0x18
    assert all(cpu.reg_read(reg) == 0x12340000 + reg for reg in PRESERVED)
    actual = cpu.reg_read(UC_X86_REG_EAX)
    assert actual == (0 if match is None else HAYSTACK + match), (haystack, needle, actual)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    for case in CASES:
        check(memory, *case)
    print(f'PASS: {len(CASES)} near-string search scenarios')
