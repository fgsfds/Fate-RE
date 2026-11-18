"""Verify empty-near-heap traversal, backing releases, and the shared return ABI."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import UC_ARCH_X86, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ES,
    UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_GDTR, UC_X86_REG_SS,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

SYMBOL, ENTRY, RAW, SIZE = 'release_empty_heaps_', 0x65190, 0x8a790, 94
HEAD = DS + DATA_OFFSETS['_near_heap_head']
ROVER = DS + DATA_OFFSETS['_near_heap_rover']
STACK, STOP, GDT = 0x3ff000, 0x3fff00, 0x350000
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)


def exercise(memory, body, mixed):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def put(address, *words):
        cpu.mem_write(address, pack('<' + 'I' * len(words), *words))

    def get(address):
        return unpack('<I', cpu.mem_read(address, 4))[0]

    # Install one flat writable descriptor for DOS release's temporary ES.
    cpu.mem_write(GDT, bytes(8) + bytes.fromhex('ff ff 00 00 00 93 cf 00'))
    cpu.reg_write(UC_X86_REG_GDTR, (0, GDT, 15, 0))
    cpu.reg_write(UC_X86_REG_SS, 8)
    keep, dpmi, dos = 0x351008, 0x352008, 0x353008
    if mixed:
        for node, previous, following, tag in (
            (keep, 0, dpmi, 0x80), (dpmi, keep, dos, 0xd4), (dos, dpmi, 0, 0xd4),
        ):
            put(node, 0x100, previous, following)
            put(node + 0x24, node + 0x2c)
            put(node + 0x2c, tag)
        put(dpmi - 8, 0x1234abcd, 0)
        put(dos - 8, 0, 8)
    put(HEAD, keep if mixed else 0)
    put(ROVER, dpmi if mixed else 0)

    events = []

    def release_backing(uc, irq, _):
        eax = uc.reg_read(UC_X86_REG_EAX)
        if irq == 0x31:
            events.append((irq, eax & 0xffff, uc.reg_read(UC_X86_REG_ESI),
                           uc.reg_read(UC_X86_REG_EDI) & 0xffff))
        elif irq == 0x21:
            events.append((irq, (eax >> 8) & 0xff, uc.reg_read(UC_X86_REG_ES)))
            uc.reg_write(UC_X86_REG_EFLAGS, uc.reg_read(UC_X86_REG_EFLAGS) | 1)
        else:
            raise AssertionError(f'Unexpected interrupt: {irq:#x}')

    cpu.hook_add(UC_HOOK_INTR, release_backing)
    put(STACK, STOP, 0x11223344)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for i, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12345400 + i)
    cpu.emu_start(ENTRY, STOP, count=500)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert get(STACK + 4) == 0x11223344
    assert cpu.reg_read(UC_X86_REG_ES) == 0
    assert all(cpu.reg_read(reg) == 0x12345400 + i for i, reg in enumerate(SAVED))
    assert get(ROVER) == 0
    assert get(HEAD) == (keep if mixed else 0)
    if mixed:
        assert get(keep + 8) == 0
        assert get(keep + 0x2c) == 0x80
        assert events == [(0x31, 0x502, 0x1234, 0xabcd), (0x21, 0x49, 8)]
        assert cpu.reg_read(UC_X86_REG_EAX) == 0x80004908
    else:
        assert not events


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe = args.executable.read_bytes()
    obj = args.object.read_bytes()
    memory = image(exe)
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[RAW:RAW + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ENTRY)
    loaded = {symbol: value + DS for symbol, value in DATA_OFFSETS.items()}
    restored, _ = bind_leaf_details(obj, SYMBOL, loaded, address=ENTRY, functions=FUNCTION_ADDRESSES)
    for body in (memory[ENTRY:ENTRY + SIZE], restored):
        for mixed in (False, True):
            exercise(memory, body, mixed)
    print(f'PASS: {SIZE} bytes, {len(refs)} LE relocation, two original and two restored heap cases')


if __name__ == '__main__':
    main()
