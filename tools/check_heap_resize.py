"""Verify near-heap resize paths with a deterministic DPMI service boundary."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOLS = (
    'resize_dpmi_heap_', 'resize_heap_target_', 'resize_heap_result_', 'resize_use_whole_block_',
    'resize_return_block_', 'resize_next_heap_', 'resize_check_heap_', 'resize_return_zero_', 'resize_restore_',
)
HEAD = DS + DATA_OFFSETS['_near_heap_head']
ROVER = DS + DATA_OFFSETS['_near_heap_rover']
STACK, STOP = 0x3ff000, 0x3fff00
OLD, NEW = 0x350000, 0x352000
OLD_TAG = OLD + 8 + 44
NEW_TAG = NEW + 8 + 44
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
CASES = ('empty', 'later_heap', 'multiple_allocations', 'dos', 'failure', 'split', 'whole')


def exercise(memory, entry, body, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    free = FUNCTION_ADDRESSES['free_']
    cpu.mem_write(free, b'\xc3')

    def put(addr, *words):
        cpu.mem_write(addr, pack('<' + 'I' * len(words), *words))

    def get(addr):
        return unpack('<I', cpu.mem_read(addr, 4))[0]

    # The live allocation at +44 has one allocated tag. A separate free tag
    # ensures release_empty_heaps does not mistake the old region for empty.
    put(OLD, 0x1234abcd, int(case == 'dos'))
    put(OLD + 8, 0x22c, 0, 0)
    put(OLD + 8 + 0x18, 2 if case == 'multiple_allocations' else 1)
    put(OLD + 8 + 0x24, OLD_TAG + 0x200)
    put(OLD_TAG, 0x201)
    put(OLD_TAG + 0x200, 8)
    put(HEAD, 0 if case == 'empty' else OLD + 8)
    put(ROVER, get(HEAD))
    request = 0xfc0 if case == 'whole' else 0x381
    interrupt_calls, free_calls = [], []

    def dpmi(uc, interrupt, _):
        assert interrupt == 0x31
        low = lambda reg: uc.reg_read(reg) & 0xffff
        interrupt_calls.append((low(UC_X86_REG_EAX), (low(UC_X86_REG_EBX) << 16) | low(UC_X86_REG_ECX),
                                low(UC_X86_REG_EDI), low(UC_X86_REG_ESI)))
        flags = uc.reg_read(UC_X86_REG_EFLAGS)
        if case == 'failure':
            uc.reg_write(UC_X86_REG_EFLAGS, flags | 1)
        else:
            uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)
            uc.reg_write(UC_X86_REG_EBX, NEW >> 16)
            uc.reg_write(UC_X86_REG_ECX, NEW & 0xffff)
            uc.reg_write(UC_X86_REG_EDI, 0x4321)
            uc.reg_write(UC_X86_REG_ESI, 0xdcba)

    cpu.hook_add(UC_HOOK_INTR, dpmi)
    cpu.hook_add(UC_HOOK_CODE, lambda uc, *_: free_calls.append(uc.reg_read(UC_X86_REG_EAX)), begin=free, end=free)
    put(STACK, STOP)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, OLD if case == 'later_heap' else OLD_TAG)
    cpu.reg_write(UC_X86_REG_EDX, request)
    for i, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12345670 + i)
    cpu.emu_start(entry, STOP, count=2500)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12345670 + i for i, reg in enumerate(SAVED))
    reached_dpmi = case in ('failure', 'split', 'whole')
    page_size = (0x22c + 12 + request - (0x201 - 4) + 4095) & ~4095
    assert interrupt_calls == ([(0x503, page_size, 0xabcd, 0x1234)] if reached_dpmi else [])
    if case in ('split', 'whole'):
        assert cpu.reg_read(UC_X86_REG_EAX) == NEW_TAG
        assert get(HEAD) == NEW + 8 and get(NEW) == 0xdcba4321 and get(NEW + 4) == 0
        assert get(NEW + 8) == page_size - 12
        available = page_size - 12 - 44
        allocated = (request + 1) & ~1
        if case == 'split':
            assert get(NEW_TAG) == allocated | 1
            assert get(NEW_TAG + allocated) == (available - allocated) | 1
            assert get(NEW + 8 + 0x14) == 0xffffffff
            assert get(NEW + 8 + 0x18) == 2
            assert free_calls == [NEW_TAG + allocated + 4]
        else:
            assert get(NEW_TAG) == available | 1
            assert get(NEW + 8 + 0x18) == 1
            assert not free_calls
    else:
        assert cpu.reg_read(UC_X86_REG_EAX) == 0
        assert get(HEAD) == (OLD + 8 if case in ('later_heap', 'multiple_allocations') else 0)
        assert not free_calls


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    body = bytearray()
    sites = 0
    entry = LEAVES[SYMBOLS[0]][0] - 0x25600
    for symbol in SYMBOLS:
        raw, size = LEAVES[symbol]
        address = raw - 0x25600
        assert address == entry + len(body)
        data, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=address, functions=FUNCTION_ADDRESSES)
        assert len(data) == size and data == exe[raw:raw + size], symbol
        verify_leaf_relocations(data, refs, pointers, address)
        patched, _ = bind_leaf_details(obj, symbol, loaded, address=address, functions=FUNCTION_ADDRESSES)
        body.extend(patched)
        sites += len(refs)
    assert len(body) == 259 and sites == 1
    for code in (memory[entry:entry + len(body)], bytes(body)):
        for case in CASES:
            exercise(memory, entry, code, case)
    print(f'PASS: {len(body)} exact bytes, {sites} LE relocation, {len(CASES)} original and {len(CASES)} restored resize cases')


if __name__ == '__main__':
    main()
