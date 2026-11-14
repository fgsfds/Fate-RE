"""Bounded behavioral oracle for the pinned START hook, not reconstructed code.

Runs original instructions in Unicorn; three external callees are replaced with
recording stubs. No DOS execution, original bytes or generated binary are output.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from le_fixups import read_le_fixups

EXPECTED = '61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f'
SECTORS = [87, 76, 75, 74, 72, 86, 80, 79, 78, 77, 56, 57, 58, 59, 60, 159]
DS = 0x80000


def image(blob):
    if hashlib.sha256(blob).hexdigest() != EXPECTED:
        raise ValueError('Unsupported executable hash')
    h = struct.unpack_from('<I', blob, 0x3c)[0]
    def field(offset):
        return struct.unpack_from('<I', blob, h + offset)[0]
    memory = bytearray(0x400000)
    for i in range(field(0x44)):
        size, base, flags, first, count, reserved = struct.unpack_from(
            '<6I', blob, h + field(0x40) + i * 24)
        for page in range(count):
            off = h + field(0x48) + (first + page - 1) * 4
            physical = int.from_bytes(blob[off:off + 3], 'big')
            if physical:
                src = field(0x80) + (physical - 1) * 4096
                chunk = blob[src:src + min(4096, size - page * 4096)]
                memory[base + page * 4096:base + page * 4096 + len(chunk)] = chunk
    for site, target in read_le_fixups(blob)['pointers'].items():
        struct.pack_into('<I', memory, site, target)
    assert list(struct.unpack_from('<16h', memory, DS + 0x1284a)) == SECTORS
    return bytes(memory)


def scenario(memory, occupied=False, previous=0, guard=0, done=0,
             entries=(), flags=0xa0):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX,
        UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI,
        UC_X86_REG_ESP, UC_X86_REG_EIP)
    emu = Uc(UC_ARCH_X86, UC_MODE_32)
    emu.mem_map(0, len(memory))
    emu.mem_write(0, memory)
    def put(fmt, off, value):
        emu.mem_write(DS + off, struct.pack('<' + fmt, value))
    def get(fmt, off):
        return struct.unpack('<' + fmt, emu.mem_read(DS + off, struct.calcsize(fmt)))[0]
    put('I', 0x12840, done)
    put('h', 0x12844, guard)
    put('h', 0x12848, previous)
    put('h', 0x288a4a, 10 if occupied else -1)
    put('h', 0x1f9ca0 + 20, -1)
    put('h', 0x3be6, len(entries))
    put('B', 0x203c, flags)
    put('h', 0x236fd0, 1672)
    for sector in SECTORS:
        put('h', 0x27c3c2 + sector * 40, 9)
    for i, (sprite, encoded, tile) in enumerate(entries, 1):
        put('h', 0x77124 + 4 * i, sprite)
        put('H', 0x77126 + 4 * i, encoded)
        put('h', 0x2040ae + 44 * sprite, tile)
    preserved = [UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                 UC_X86_REG_ESI, UC_X86_REG_EDI]
    for i, register in enumerate(preserved):
        emu.reg_write(register, 0x12340000 + i)
    emu.reg_write(UC_X86_REG_ESP, 0x3ff000)
    emu.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
    calls = []
    def hook(uc, address, size, user):
        if address not in (0x34f79, 0x28710, 0x10f9f):
            return
        eax = uc.reg_read(UC_X86_REG_EAX)
        event = dict(target=hex(address), eax=eax)
        if address == 0x28710:
            event['lotag_at_call'] = get('h', 0x27c3c2 + eax * 40)
        if address == 0x34f79:
            event['edx_ebx_ecx'] = [uc.reg_read(r) for r in
                (UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)]
        calls.append(event)
        esp = uc.reg_read(UC_X86_REG_ESP)
        ret = struct.unpack('<I', uc.mem_read(esp, 4))[0]
        uc.reg_write(UC_X86_REG_ESP, esp + 4)
        uc.reg_write(UC_X86_REG_EIP, ret)
    emu.hook_add(UC_HOOK_CODE, hook)
    emu.emu_start(0x1e5d1, 0x3fff00, timeout=2_000_000, count=10000)
    assert emu.reg_read(UC_X86_REG_EIP) == 0x3fff00
    assert emu.reg_read(UC_X86_REG_ESP) == 0x3ff004
    assert all(emu.reg_read(r) == 0x12340000 + i for i, r in enumerate(preserved))
    return dict(calls=calls, done=get('I', 0x12840), flags=get('B', 0x203c),
                current=get('h', 0x12846), previous=get('h', 0x12848),
                guard=get('h', 0x12844), wall_picnum=get('h', 0x236fd0),
                lotags=[get('h', 0x27c3c2 + s * 40) for s in SECTORS])


def check(path):
    memory = image(Path(path).read_bytes())
    cases = {}
    cases['empty'] = scenario(memory)
    assert cases['empty']['calls'] == [] and cases['empty']['lotags'] == [0] * 16
    cases['guard_preserves_tags'] = scenario(memory, guard=1)
    assert cases['guard_preserves_tags']['lotags'] == [9] * 16
    for name, occupied, previous in [('enter', True, 0), ('leave', False, 1)]:
        r = cases[name] = scenario(memory, occupied=occupied, previous=previous)
        assert r['calls'] == [dict(target='0x34f79', eax=156, edx_ebx_ecx=[0, 0, 0])] + [
            dict(target='0x28710', eax=s, lotag_at_call=6) for s in SECTORS]
        assert r['previous'] == int(occupied) and r['lotags'] == [0] * 16
    cases['still_occupied'] = scenario(memory, occupied=True, previous=1)
    assert cases['still_occupied']['calls'] == []
    cases['matching_event'] = scenario(memory, entries=[(12, 0x405d, 527)])
    r = cases['matching_event']
    assert r['calls'] == [dict(target='0x10f9f', eax=12)]
    assert (r['done'], r['flags'], r['wall_picnum']) == (1, 0xa1, 1673)
    cases['already_done'] = scenario(memory, done=1, entries=[(12, 0x405d, 527)])
    assert cases['already_done']['calls'] == []
    cases['near_misses'] = scenario(memory, entries=[(12, 0x405c, 527), (13, 0x805d, 527), (14, 0x405d, 526)])
    assert cases['near_misses']['calls'] == [] and cases['near_misses']['done'] == 0
    cases['two_matches_same_invocation'] = scenario(memory, entries=[(12, 0x405d, 527), (13, 0x405d, 527)])
    assert cases['two_matches_same_invocation']['calls'] == [dict(target='0x10f9f', eax=i) for i in (12, 13)]
    return dict(executable_sha256=EXPECTED, entry='0x1e5d1', end_exclusive='0x1e73a',
                original_instruction_oracle=True, external_callees_stubbed=True,
                reconstructed_bytes_added=0, cases=cases)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.write_text(json.dumps(check(args.executable), indent=2) + '\n', encoding='utf-8')
