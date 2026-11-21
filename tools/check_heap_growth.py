"""Verify near-heap growth dispatch and return values with stubbed allocators."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOLS = (
    'expand_separate_heap_', 'expand_return_zero_', 'expand_check_limit_',
    'expand_allocate_dos_', 'expand_check_block_',
)
HEAD = DS + DATA_OFFSETS['_near_heap_head']
ROVER = DS + DATA_OFFSETS['_near_heap_rover']
RUNTIME_HOOK = DS + DATA_OFFSETS['_runtime_hook']
MEMORY_LIMIT = DS + DATA_OFFSETS['_memory_limit']
EXTENDER_TYPE = DS + DATA_OFFSETS['_dos_extender_type']
STACK, STOP = 0x3ff000, 0x3fff00
BLOCK, PAYLOAD = 0x350000, 0x35002c
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)
CASES = ('no_hook', 'at_limit', 'round_zero', 'dpmi', 'dos', 'small_block')


def exercise(memory, entry, body, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    cpu.mem_map(0x80000000, 0x1000)  # DOS segment-relative block address

    def put(addr, *words):
        cpu.mem_write(addr, pack('<' + 'I' * len(words), *words))

    def get(addr):
        return unpack('<I', cpu.mem_read(addr, 4))[0]

    request = 0x100 if case == 'small_block' else 0x200
    round_value = 0 if case == 'round_zero' else request
    dpmi_block = BLOCK if case == 'dpmi' else 0
    calls = []

    def round_hook(uc, *_):
        uc.reg_write(UC_X86_REG_EAX, round_value)

    def allocate_hook(uc, *_):
        uc.reg_write(UC_X86_REG_EAX, dpmi_block)
        if dpmi_block:
            uc.mem_write(BLOCK, pack('<I', request - 8))

    def link_hook(uc, *_):
        block = uc.reg_read(UC_X86_REG_EAX)
        uc.reg_write(UC_X86_REG_EAX, PAYLOAD)
        uc.mem_write(PAYLOAD, pack('<I', request - 4))
        uc.mem_write(block + 0x18, pack('<I', 1))
        calls.append('link')

    def free_hook(uc, *_):
        calls.append('free')

    cpu.hook_add(UC_HOOK_CODE, round_hook, begin=FUNCTION_ADDRESSES['round_heap_request_'],
                 end=FUNCTION_ADDRESSES['round_heap_request_'])
    cpu.hook_add(UC_HOOK_CODE, allocate_hook, begin=FUNCTION_ADDRESSES['allocate_dpmi_heap_'],
                 end=FUNCTION_ADDRESSES['allocate_dpmi_heap_'])
    cpu.hook_add(UC_HOOK_CODE, link_hook, begin=FUNCTION_ADDRESSES['link_and_initialize_heap_'],
                 end=FUNCTION_ADDRESSES['link_and_initialize_heap_'])
    cpu.hook_add(UC_HOOK_CODE, free_hook, begin=FUNCTION_ADDRESSES['free_'], end=FUNCTION_ADDRESSES['free_'])
    cpu.mem_write(FUNCTION_ADDRESSES['round_heap_request_'], b'\xc3')
    cpu.mem_write(FUNCTION_ADDRESSES['allocate_dpmi_heap_'], b'\xc3')
    cpu.mem_write(FUNCTION_ADDRESSES['link_and_initialize_heap_'], b'\xc3')
    cpu.mem_write(FUNCTION_ADDRESSES['free_'], b'\xc3')

    dos_allocated = []

    def dos(uc, interrupt, _):
        assert interrupt == 0x21
        flags = uc.reg_read(UC_X86_REG_EFLAGS)
        if case == 'dos':
            uc.reg_write(UC_X86_REG_EAX, 0x80000000)
            uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)
            dos_allocated.append(uc.reg_read(UC_X86_REG_EBX))
        else:
            uc.reg_write(UC_X86_REG_EFLAGS, flags | 1)

    cpu.hook_add(UC_HOOK_INTR, dos)

    put(RUNTIME_HOOK, 0 if case == 'no_hook' else 1)
    put(MEMORY_LIMIT, 0xfffffffe if case == 'at_limit' else 0x100000)
    put(EXTENDER_TYPE, 1 if case == 'dpmi' else 0)
    put(HEAD, 0)
    put(ROVER, 0)
    put(STACK, STOP)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, request)
    for i, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12345670 + i)
    cpu.emu_start(entry, STOP, count=2000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12345670 + i for i, reg in enumerate(SAVED))
    success = cpu.reg_read(UC_X86_REG_EAX) == 1
    expected = case in ('dpmi', 'dos')
    assert success == expected, (case, success, expected)
    if case in ('dpmi', 'dos'):
        assert 'link' in calls and 'free' in calls
    return 1


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
        code, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=address, functions=FUNCTION_ADDRESSES)
        assert len(code) == size and code == exe[raw:raw + size], symbol
        verify_leaf_relocations(code, refs, pointers, address)
        patched, _ = bind_leaf_details(obj, symbol, loaded, address=address, functions=FUNCTION_ADDRESSES)
        body.extend(patched)
        sites += len(refs)
    assert len(body) == 175 and sites == 3
    for code in (memory[entry:entry + len(body)], bytes(body)):
        for case in CASES:
            exercise(memory, entry, code, case)
    print(f'PASS: {len(body)} exact bytes, {sites} LE relocations, {len(CASES)} original and {len(CASES)} restored growth cases')


if __name__ == '__main__':
    main()
