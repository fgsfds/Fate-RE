"""Recover Fate object sequences from the known demo in an isolated x86 emulator.

Requires Unicorn 2.1.x. No DOS process, host imports, or system calls are run.
Only JSON metadata is emitted; no executable or artwork is redistributed.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path

EXPECTED = '61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f'


def recover(path):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
    from unicorn.x86_const import UC_X86_REG_ESP, UC_X86_REG_EIP
    blob = Path(path).read_bytes()
    if hashlib.sha256(blob).hexdigest() != EXPECTED:
        raise ValueError('Unsupported FATE.EXE hash; addresses are demo-specific')
    header = struct.unpack_from('<I', blob, 60)[0]
    def field(off):
        return struct.unpack_from('<I', blob, header + off)[0]
    objects = [struct.unpack_from('<6I', blob, header + field(0x40) + i*24)
               for i in range(field(0x44))]
    memory = bytearray(0x400000)
    for size, base, flags, first, count, reserved in objects:
        for page in range(count):
            off = header + field(0x48) + (first+page-1)*4
            physical = int.from_bytes(blob[off:off+3], 'big')
            if physical:
                src = field(0x80) + (physical-1)*4096
                chunk = blob[src:src+min(4096, size-page*4096)]
                memory[base+page*4096:base+page*4096+len(chunk)] = chunk
    fixups = 0
    for page in range(field(0x14)):
        begin, end = struct.unpack_from('<II', blob, header+field(0x68)+page*4)
        off = header+field(0x6c)+begin
        end += header+field(0x6c)
        owner = next(o for o in objects if o[3]-1 <= page < o[3]-1+o[4])
        pagebase = owner[1]+(page-owner[3]+1)*4096
        while off < end:
            kind, flags, source, obj = struct.unpack_from('<BBhB', blob, off)
            off += 5
            if kind != 7 or flags not in (0, 16):
                raise ValueError('Unexpected relocation')
            width = 4 if flags & 16 else 2
            target = int.from_bytes(blob[off:off+width], 'little')
            off += width
            struct.pack_into('<I', memory, pagebase+source, objects[obj-1][1]+target)
            fixups += 1
        if off != end:
            raise ValueError('Relocation boundary mismatch')
    emu = Uc(UC_ARCH_X86, UC_MODE_32)
    emu.mem_map(0, len(memory))
    emu.mem_write(0, bytes(memory))
    emu.reg_write(UC_X86_REG_ESP, 0x3ff000)
    emu.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
    emu.emu_start(0x3b609, 0x3fff00, timeout=5_000_000, count=1_000_000)
    if emu.reg_read(UC_X86_REG_EIP) != 0x3fff00:
        raise ValueError('Initializer exceeded its execution budget')
    sequences = {}
    for index in (28, 29, 50, 55, 61):
        row = struct.unpack('<60h', emu.mem_read(0xe807c+index*120, 120))
        sequences[index] = dict(start=row[0], end=row[1], final=row[2], next=row[3],
                                debris=list(row[4:52]), sounds=list(row[52:]))
    return dict(executable_sha256=EXPECTED, relocations=fixups,
                initializer='0x3b609', table='DS:0x6807c', stride=120, sequences=sequences)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = recover(args.executable)
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
