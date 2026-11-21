"""Check the linked PCX geometry paths without opening a file or using video IO."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import DS, image
from compare_exe import TARGET_SHA256


START, END = 0x4c40f, 0x4c50f
HEADER = DS + 0x140d5
GUARD = 16
STACK = 0x3ff000
SEQUENCE = DS + 0x140d3
FILENAME = STACK + 0x100
OPEN_ENTRY, OPEN_STOP, OPEN = 0x4c376, 0x4c402, 0x61368
CLOSE_ENTRY, CLOSE_STOP, CLOSE = 0x4c871, 0x4c887, 0x6219a
CASES = (
    (200, 320, 200), (200, 640, 480), (200, 1024, 768),
    (200, 256, 257), (200, 1, 1),
    (350, 111, 222), (480, 1024, 768), (256, 256, 257),
)


def check(memory, mode, width, height):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    for offset, value in ((0x140ba, mode), (0x287e90, width), (0x287e8c, height)):
        cpu.mem_write(DS + offset, struct.pack('<i', value))
    initial = bytes(range(128 + 2 * GUARD))
    cpu.mem_write(HEADER - GUARD, initial)
    cpu.reg_write(UC_X86_REG_ESP, STACK)

    cpu.emu_start(START, END, count=80)
    if (cpu.reg_read(UC_X86_REG_EIP), cpu.reg_read(UC_X86_REG_ESP)) != (END, STACK):
        raise AssertionError('PCX geometry did not reach the write handoff with the same stack')
    if mode != 200:
        width, height = 640, mode
    expected = bytearray(initial)
    struct.pack_into('<4H', expected, GUARD + 8, width - 1, height - 1, width, height)
    struct.pack_into('<H', expected, GUARD + 66, width)
    if cpu.mem_read(HEADER - GUARD, len(expected)) != expected:
        raise AssertionError(f'PCX geometry or surrounding bytes differ for mode {mode}, {width}x{height}')


def run_file_stub(memory, sequence, *, closing):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    initial = b'fate????.pcx\0guard'
    cpu.mem_write(FILENAME, initial)
    cpu.mem_write(SEQUENCE, struct.pack('<H', sequence & 0xffff))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, 21)
    cpu.reg_write(UC_X86_REG_EBX, FILENAME)
    entry, stop, callee = ((CLOSE_ENTRY, CLOSE_STOP, CLOSE) if closing
                           else (OPEN_ENTRY, OPEN_STOP, OPEN))
    result = 0xffffffff if closing or sequence < 0 else 23
    calls = []

    def intercept(emu, address, size, data):
        sp = emu.reg_read(UC_X86_REG_ESP)
        if closing:
            ret, = struct.unpack('<I', emu.mem_read(sp, 4))
            args = (emu.reg_read(UC_X86_REG_EAX),)
            expected = (21,)
            return_pc = entry + 5
        else:
            ret, name, flags, mode = struct.unpack('<4I', emu.mem_read(sp, 16))
            args = (name, flags, mode)
            expected = (FILENAME, 0x261, 0x80)
            return_pc = stop - 3
        if args != expected or ret != return_pc:
            raise AssertionError(f'Unexpected capture call arguments or return address: {args!r}, {ret:#x}')
        calls.append(address)
        emu.reg_write(UC_X86_REG_EAX, result)
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    cpu.hook_add(UC_HOOK_CODE, intercept, begin=callee, end=callee)
    cpu.emu_start(entry, stop, count=150)
    registers = tuple(cpu.reg_read(r) for r in (UC_X86_REG_EIP, UC_X86_REG_ESP, UC_X86_REG_EAX))
    if registers != (stop, STACK, 0 if closing else result) or calls != [callee]:
        raise AssertionError('Capture did not return from exactly one file call with the original stack')
    observed, = struct.unpack('<H', cpu.mem_read(SEQUENCE, 2))
    if observed != ((sequence + closing) & 0xffff):
        raise AssertionError(f'Unexpected capture sequence after file call: {observed}')
    if not closing:
        sign = -1 if sequence < 0 else 1
        digits = bytes(48 + sign * ((abs(sequence) // place) % 10) for place in (1000, 100, 10, 1))
        initial = initial[:4] + digits + initial[8:]
    if cpu.mem_read(FILENAME, len(initial)) != initial:
        raise AssertionError(f'Unexpected capture filename or guard bytes for sequence {sequence}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    memory = image(blob)
    for case in CASES:
        check(memory, *case)
    filenames = (0, 9, 10, 999, 1000, 9999, 32767, -1, -32768)
    counters = (0, 9999, 32767, 65535)
    for sequence in filenames:
        run_file_stub(memory, sequence, closing=False)
    for sequence in counters:
        run_file_stub(memory, sequence, closing=True)
    result = {'status': 'PASS', 'cases': len(CASES) + len(filenames) + len(counters),
              'geometry': len(CASES), 'filenames': len(filenames), 'counters': len(counters)}
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
