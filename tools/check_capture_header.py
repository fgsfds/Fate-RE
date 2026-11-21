"""Check the linked PCX geometry paths without opening a file or using video IO."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import DS, image
from compare_exe import TARGET_SHA256


START, END = 0x4c40f, 0x4c50f
HEADER = DS + 0x140d5
GUARD = 16
STACK = 0x3ff000
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
    result = {'status': 'PASS', 'cases': len(CASES)}
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
