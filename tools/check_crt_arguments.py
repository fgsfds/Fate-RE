"""Check restored DOS argument parsing and adjacent error translation."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP,
    UC_X86_REG_ESP, UC_X86_REG_EIP)

from check_start_hook import image
from verify_c_leaf import LEAVES

INPUT, VECTOR, END = 0x390000, 0x390100, 0x390200
STACK, STOP = 0x3ff000, 0x3fff00


def setup(memory):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    return cpu


def invoke(cpu, symbol, eax, edx, ebx=0):
    preserved = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    for reg in preserved:
        cpu.reg_write(reg, 0x12300000 + reg)
    for reg, value in ((UC_X86_REG_EAX, eax), (UC_X86_REG_EDX, edx), (UC_X86_REG_EBX, ebx)):
        cpu.reg_write(reg, value)
    cpu.emu_start(LEAVES[symbol][0] - 0x25600, STOP, count=10000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12300000 + reg for reg in preserved)
    return cpu.reg_read(UC_X86_REG_EAX)


def check_parse(memory, command, words, split):
    cpu = setup(memory)
    cpu.mem_write(INPUT, command + b'\0\xa5')
    cpu.mem_write(VECTOR, b'\xa5' * 64)
    assert invoke(cpu, 'parse_command_line_', INPUT, VECTOR if split else 0, END) == len(words)
    assert unpack('<I', cpu.mem_read(END, 4))[0] == INPUT + len(command)
    assert cpu.mem_read(INPUT + len(command) + 1, 1) == b'\xa5'
    if split:
        pointers = unpack('<' + 'I' * len(words), cpu.mem_read(VECTOR, 4 * len(words))) if words else ()
        for address, word in zip(pointers, words):
            assert INPUT <= address <= INPUT + len(command)
            assert cpu.mem_read(address, len(word) + 1) == word + b'\0'
    else:
        assert cpu.mem_read(INPUT, len(command) + 1) == command + b'\0'
    assert cpu.mem_read(VECTOR + (4 * len(words) if split else 0), 4) == b'\xa5' * 4


def check_error_translation(memory):
    target = LEAVES['set_dos_errno_'][0] - 0x25600
    for failed, expected in ((0, 53), (1, 42), (0xffffffff, 42)):
        cpu = setup(memory)
        cpu.mem_write(target, b'\xb8\x2a\x00\x00\x00\xc3')
        assert invoke(cpu, 'translate_exec_result_', 53, failed) == expected
        cpu = setup(memory)
        cpu.mem_write(target, b'\xb8\x2a\x00\x00\x00\xc3')
        assert invoke(cpu, 'dosret0_', 53, failed) == (42 if failed else 0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    for command, words in (
        (b'', ()),
        (b'\t  ', ()),
        (b' foo\tbar ', (b'foo', b'bar')),
        (b'"two words"tail', (b'two words', b'tail')),
        (b'"" extra', (b'', b'extra')),
        (b'abc\\"def', (b'abc"def',)),
        (b'"a\\\\b\\"c" d', (b'a\\b"c', b'd')),
        (b'"unterminated', (b'unterminated',)),
    ):
        for split in (False, True):
            check_parse(memory, command, words, split)
    check_error_translation(memory)
    print('PASS: 16 DOS parser and six error translation scenarios')
