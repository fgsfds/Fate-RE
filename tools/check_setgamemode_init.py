"""Check the video initialization handoff with hardware and runtime calls stubbed."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from compare_exe import TARGET_SHA256

ENTRY, STOP, STACK = 0x4b04e, 0x4b149, 0x3ff000
BACKEND, MALLOC, DIAGNOSTIC, EXIT = 0x4a294, 0x4478c, 0x40bb4, 0x60353
ALLOCATIONS = (0x301000, 0x302000)
SAVES = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ECX)
SAVED_VALUES = (0x10203040, 0x50403020, 0x55667788, 0x87654321)
CASES = ((0, 320, 200, 0), (2, 640, 480, 0), (7, 800, 601, 0),
         (1, 320, 201, 1), (6, 1280, 719, 2))


def check(memory, mode, width, height, fail_at):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(STACK - 16, b'\xa5' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg, value in zip(SAVES, SAVED_VALUES):
        cpu.reg_write(reg, value)
    for reg, value in ((UC_X86_REG_EAX, mode), (UC_X86_REG_EDX, width), (UC_X86_REG_EBX, height)):
        cpu.reg_write(reg, value)

    dimensions = ((0x2891db, 'B', mode), (0x287e90, 'I', width), (0x287e8c, 'I', height))
    setup = ((0x286ae0, 'I', 3 * height // 2), (0x286bac, 'i', -1),
             (0x1ed1a0, 'H', 0), (0x289150, 'H', 0), (0x2891da, 'B', 2),
             (0x286b88, 'I', 0), (0x286b8c, 'I', 65536), (0x2891d9, 'B', 0),
             (0x140c2, 'B', 0), (0x28912a, 'H', 0), (0x289122, 'h', -1))

    def read(offset, fmt):
        count = struct.calcsize('<' + fmt)
        return struct.unpack('<' + fmt, cpu.mem_read(DS + offset, count))[0]

    for offset, fmt, _ in (*dimensions, *setup):
        cpu.mem_write(DS + offset, b'\xa5' * struct.calcsize('<' + fmt))

    calls = []
    allocation_count = 0

    def intercept(emu, address, size, data):
        nonlocal allocation_count
        calls.append(address)
        sp = emu.reg_read(UC_X86_REG_ESP)
        if address == EXIT:
            if emu.reg_read(UC_X86_REG_EAX) != 0:
                raise AssertionError('Unexpected allocator failure exit status')
            emu.emu_stop()
            return
        result = 0
        if address == BACKEND:
            if any(read(off, fmt) != value for off, fmt, value in dimensions):
                raise AssertionError('Video dimensions are not visible to the backend')
        elif address == MALLOC:
            allocation_count += 1
            if emu.reg_read(UC_X86_REG_EAX) != height * 12 or allocation_count > 2:
                raise AssertionError('Unexpected horizon allocator request')
            result = 0 if fail_at == allocation_count else ALLOCATIONS[allocation_count - 1]
        elif address == DIAGNOSTIC:
            arg, = struct.unpack('<I', emu.mem_read(sp + 4, 4))
            if arg != DS + 0x1af9:
                raise AssertionError('Unexpected out-of-memory diagnostic pointer')
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_EAX, result)
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    for address in (BACKEND, MALLOC, DIAGNOSTIC, EXIT):
        cpu.hook_add(UC_HOOK_CODE, intercept, begin=address, end=address)
    cpu.emu_start(ENTRY, STOP, count=150)
    if struct.unpack('<4I', cpu.mem_read(STACK - 16, 16)) != SAVED_VALUES:
        raise AssertionError('Video initialization altered the saved register layout')
    if fail_at:
        if calls != [BACKEND] + [MALLOC] * fail_at + [DIAGNOSTIC, EXIT]:
            raise AssertionError(f'Incorrect allocator failure path: {calls!r}')
        offset = (0x286ac4, 0x286aec)[fail_at - 1]
        if read(offset, 'I') != 0 or cpu.reg_read(UC_X86_REG_EIP) != EXIT:
            raise AssertionError('Failure path did not record the failed allocation and exit')
        return

    if calls != [BACKEND, MALLOC, MALLOC]:
        raise AssertionError(f'Unexpected initialization calls: {calls!r}')
    if (cpu.reg_read(UC_X86_REG_EIP), cpu.reg_read(UC_X86_REG_EAX),
            cpu.reg_read(UC_X86_REG_ESP)) != (STOP, 0, STACK - 16):
        raise AssertionError('Palette loop did not receive index zero and the original frame')
    for offset, fmt, expected in (*dimensions, *setup, (0x286ac4, 'I', ALLOCATIONS[0]),
                                  (0x286aec, 'I', ALLOCATIONS[1])):
        if read(offset, fmt) != expected:
            raise AssertionError(f'Video setup field at {offset:#x} differs')


def check_display_reset(memory, mode, fill):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(DS + 0x2891db, bytes((mode,)))
    buffers = ((0x1ffca0, 4096 * 4), (0x1ec6a0, 32 * 4),
               (0x1ecfa0, 128 * 4), (0x1ec920, 256 * 4))
    before_call = ((0x2891d8, 'B', 0), (0x28913a, 'h', 0),
                   (0x289142, 'h', -1), (0x28913c, 'h', -1))
    after_call = ((0x286ba8, 'I', 512), (0x286ba0, 'I', 512),
                  (0x14004, 'I', 0), (0x14003, 'B', 0))
    for offset, count in buffers:
        cpu.mem_write(DS + offset - 1, b'\xa5' + bytes((fill,)) * count + b'\x5a')
    for offset, fmt, _ in (*before_call, *after_call):
        cpu.mem_write(DS + offset, bytes((fill,)) * struct.calcsize('<' + fmt))
    calls = []

    def check_fields(fields):
        for offset, fmt, expected in fields:
            actual, = struct.unpack('<' + fmt,
                                    cpu.mem_read(DS + offset, struct.calcsize('<' + fmt)))
            if actual != expected:
                raise AssertionError(f'Unexpected display reset field at {offset:#x}: {actual}')

    def intercept(emu, address, size, data):
        calls.append(address)
        check_fields(before_call)
        for offset, count in buffers:
            if emu.mem_read(DS + offset - 1, count + 2) != b'\xa5' + bytes(count) + b'\x5a':
                raise AssertionError(f'Display buffer at {offset:#x} or its guard differs')
        sp = emu.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    cpu.hook_add(UC_HOOK_CODE, intercept, begin=0x4c0b0, end=0x4c0b0)
    cpu.emu_start(0x4b150, 0x4b1d1, count=6000)
    if (calls != [0x4c0b0] or cpu.reg_read(UC_X86_REG_EIP) != 0x4b1d1
            or cpu.reg_read(UC_X86_REG_EAX) & 255 != mode
            or cpu.reg_read(UC_X86_REG_ESP) != STACK):
        raise AssertionError('Backend dispatch did not receive the original mode and stack')
    check_fields(after_call)


def check_palette_lookup(memory, first):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    base = DS + 0x203ca0
    cpu.mem_write(base - 4, b'\xa5' * (256 * 4 + 8))
    cpu.reg_write(UC_X86_REG_EAX, first)
    cpu.reg_write(UC_X86_REG_EBX, 0x12345678)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(0x4b13d, 0x4b150, count=2000)
    expected = b'\xa5' * (4 + first * 4) + bytes((256 - first) * 4) + b'\xa5' * 4
    if cpu.mem_read(base - 4, len(expected)) != expected:
        raise AssertionError('Palette lookup contents or boundary guards differ')
    if (cpu.reg_read(UC_X86_REG_EAX), cpu.reg_read(UC_X86_REG_EBX),
            cpu.reg_read(UC_X86_REG_ESP)) != (256, 0x12345678, STACK):
        raise AssertionError('Palette lookup register or stack handoff differs')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    memory = image(blob)
    for case in CASES:
        check(memory, *case)
    display_cases = ((0, 0x33), (7, 0x94), (255, 0xfe))
    for mode, fill in display_cases:
        check_display_reset(memory, mode, fill)
    for first in (0, 255, 256):
        check_palette_lookup(memory, first)
    for offset in (0x4b13f, 0x4b145):
        mutant = bytearray(memory)
        mutant[offset] ^= 1
        try:
            check_palette_lookup(bytes(mutant), 0)
        except AssertionError:
            pass
        else:
            raise AssertionError('Palette lookup oracle accepted a code or pointer mutation')
    result = {'palette_lookup_mutation_controls': 2, 'palette_lookup_cases': 3, 'status': 'PASS', 'cases': len(CASES) + len(display_cases) + 3,
              'allocator_failure_cases': 2, 'display_reset_cases': len(display_cases)}
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
