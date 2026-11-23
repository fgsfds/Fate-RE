"""Check encounter actor proximity and kind decisions against an independent model."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_EIP,
)
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256

ENTRY, UPDATE, EXIT, NEAR = 0x1e23a, 0x1e299, 0x1e30b, 0x10610
STATE, KIND, STACK = DS + 0x127f6, DS + 0x7f0df, 0x3fe000
PAIRS = ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1),
         (0x10000, 0), (0xffff0000, 0), (0x8000, 0x7fff))


def signed_word(value):
    return ((value + 32768) & 65535) - 32768


def check(memory, state, kind, results):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(STATE - 1, b'\xa5' + struct.pack('<h', state) + b'\x5a')
    cpu.mem_write(KIND - 1, bytes((0xa5, kind, 0x5a)))
    cpu.reg_write(UC_X86_REG_ESI, 0xfeed0000)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    calls = []

    def intercept(emu, address, size, data):
        if address in (UPDATE, EXIT):
            emu.emu_stop()
            return
        calls.append((emu.reg_read(UC_X86_REG_EAX), emu.reg_read(UC_X86_REG_EDX)))
        index = len(calls) - 1
        if index >= 2:
            raise AssertionError('Unexpected extra encounter proximity call')
        emu.reg_write(UC_X86_REG_EAX, results[index] & 0xffffffff)
        emu.reg_write(UC_X86_REG_ECX, 0x87654321)
        emu.reg_write(UC_X86_REG_EDX, 0x12345678)
        sp = emu.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    for address in (NEAR, UPDATE, EXIT):
        cpu.hook_add(UC_HOOK_CODE, intercept, begin=address, end=address)
    cpu.emu_start(ENTRY, 0x1e31b, count=100)
    reset = state == 0 and (any(signed_word(value) != 0 for value in results) or kind in (4, 5))
    expected_state, expected_kind = (1, 0) if reset else (state, kind)
    if cpu.mem_read(STATE - 1, 4) != b'\xa5' + struct.pack('<h', expected_state) + b'\x5a':
        raise AssertionError('Encounter actor state or boundary guard differs')
    if cpu.mem_read(KIND - 1, 3) != bytes((0xa5, expected_kind, 0x5a)):
        raise AssertionError('Encounter actor kind or boundary guard differs')
    if calls != ([] if state else [(0x2a00, 0x1000), (0x2a00, 0x2000)]):
        raise AssertionError('Encounter proximity call arguments differ')
    if (cpu.reg_read(UC_X86_REG_EIP) != (UPDATE if state else EXIT)
            or cpu.reg_read(UC_X86_REG_ESP) != STACK
            or cpu.reg_read(UC_X86_REG_ESI) != (0xfeed0000 | (state & 65535))):
        raise AssertionError('Encounter actor register or branch handoff differs')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    memory = image(blob)
    cases = 0
    for state in (-1, 0, 1, 2, 32767):
        for kind in range(8):
            for results in PAIRS:
                check(memory, state, kind, results)
                cases += 1
    for offset, value in ((0x1e26a, 0x21), (0x1e247, 1)):
        mutant = bytearray(memory)
        mutant[offset] = value
        try:
            check(bytes(mutant), 0, 0, (1, 0))
        except AssertionError:
            pass
        else:
            raise AssertionError('Actor oracle accepted an OR or call-argument mutation')
    report = dict(status='PASS', cases=cases, mutation_controls=2)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
