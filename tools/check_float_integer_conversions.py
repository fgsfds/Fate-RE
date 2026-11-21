"""Verify the software float widening and integer conversion routines."""

import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import image
from verify_c_leaf import FUNCTION_ADDRESSES, LEAVES


CALLER_ECX = 0x12345678
STACK, STOP = 0x3ff000, 0x3fff00
MODES = {'i32': 0x9e, 'u32': 0x9f, 'i16': 0x8e, 'u16': 0x8f, 'i8': 0x86, 'u8': 0x87}


def check(memory, name, mode, value, expected):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    target = FUNCTION_ADDRESSES[f'truncate_for_{name}_']
    bits = unpack('<I', pack('<f', value))[0]
    calls = []

    def enter_truncator(engine, address, _size, _data):
        assert address == target
        assert engine.reg_read(UC_X86_REG_EAX) == bits
        assert engine.reg_read(UC_X86_REG_ECX) == ((CALLER_ECX & ~0xff) | mode)
        calls.append(address)

    cpu.hook_add(UC_HOOK_CODE, enter_truncator, begin=target, end=target)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_EAX, bits)
    cpu.reg_write(UC_X86_REG_ECX, CALLER_ECX)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(LEAVES[f'float_to_{name}_'][0] - 0x25600, STOP, count=100)
    assert calls == [target]
    assert cpu.reg_read(UC_X86_REG_EAX) == (expected & 0xffffffff)
    assert cpu.reg_read(UC_X86_REG_ECX) == CALLER_ECX
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP



def check_to_float(memory, name, values):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    signed = name == 'signed'
    target = FUNCTION_ADDRESSES['__I4FS'] if signed else LEAVES['u32_to_float_'][0] - 0x25600
    for value in values:
        magnitude = abs(value)
        expected = 0
        if magnitude:
            bit = magnitude.bit_length() - 1
            aligned = magnitude << (23 - bit) if bit <= 23 else magnitude >> (bit - 23)
            expected = ((bit + 127) << 23) | (aligned & 0x7fffff)
            if value < 0:
                expected |= 0x80000000
        cpu.mem_write(STACK, pack('<I', STOP))
        cpu.reg_write(UC_X86_REG_EAX, value & 0xffffffff)
        cpu.reg_write(UC_X86_REG_ECX, CALLER_ECX)
        cpu.reg_write(UC_X86_REG_ESP, STACK)
        cpu.emu_start(target, STOP, count=60)
        assert cpu.reg_read(UC_X86_REG_EAX) == expected, (name, value, expected)
        assert cpu.reg_read(UC_X86_REG_ECX) == CALLER_ECX
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP


def check_widening(memory):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    inputs = (0, 1, 3, 0x00400001, 0x007fffff, 0x00800000,
              0x3f800001, 0x43800007, 0x7f7fffff, 0x7f800000)
    cases = {}
    for sign in (0, 0x80000000):
        for magnitude in inputs:
            bits = sign | magnitude
            single, = unpack('<f', pack('<I', bits))
            cases[bits], = unpack('<Q', pack('<d', single))

    # Preserve the original packing for negative zero, tiny subnormals
    # whose exponent adjustment goes negative, and NaN payloads.
    cases.update({0x80000000: 0x0000000080000000,
                  0x00000001: 0xb6a0000000000000,
                  0x00000003: 0xb6b8000000000000,
                  0x80000001: 0x36a0000000000000,
                  0x80000003: 0x36b8000000000000,
                  0x7fc00000: 0x47f8000000000000,
                  0xff800001: 0xc7f0000020000000})
    for bits, expected in cases.items():
        cpu.mem_write(STACK, pack('<I', STOP))
        cpu.reg_write(UC_X86_REG_EAX, bits)
        cpu.reg_write(UC_X86_REG_EDX, 0xfeedface)
        cpu.reg_write(UC_X86_REG_ECX, CALLER_ECX)
        cpu.reg_write(UC_X86_REG_ESP, STACK)
        cpu.emu_start(FUNCTION_ADDRESSES['__FSFD'], STOP, count=256)
        result = (cpu.reg_read(UC_X86_REG_EDX) << 32) | cpu.reg_read(UC_X86_REG_EAX)
        assert result == expected, (hex(bits), hex(result), hex(expected))
        assert cpu.reg_read(UC_X86_REG_ECX) == CALLER_ECX
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    return len(cases)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    for name, mode in MODES.items():
        check(memory, name, mode, 3.75, 3)
        check(memory, name, mode, 0.0, 0)
        if name.startswith('i'):
            check(memory, name, mode, -3.75, -3)
    for value, expected in ((2.0**-149, 0), (0.75, 0), (2.0**23, 2**23),
                            (2.0**30, 2**30), (float('inf'), 0x7fffffff),
                            (-float('inf'), -0x7fffffff)):
        check(memory, 'i32', MODES['i32'], value, expected)
    check(memory, 'u32', MODES['u32'], 2.0**31, 2**31)
    check(memory, 'u32', MODES['u32'], float('inf'), 0xffffffff)
    check_to_float(memory, 'unsigned', (0, 1, 3, 0xffffff, 0x1000001,
                                        0x7fffffff, 0x80000000, 0xffffffff))
    check_to_float(memory, 'signed', (0, 1, -1, -0x1000001, -0x80000000))
    print(f'PASS: 36 float/integer scenarios, six CL modes, and {check_widening(memory)} widening cases')
