"""Verify near-heap allocation through simulated DPMI and DOS services."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import UC_ARCH_X86, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP, UC_X86_REG_GDTR, UC_X86_REG_SS,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOLS = (
    'allocate_dpmi_heap_', 'allocate_dpmi_result_', 'allocate_dos_fallback_',
    'allocate_dos_heap_', 'allocate_heap_failure_', 'discard_heap_request_', 'heap_release_restore_',
)
HEAD = DS + DATA_OFFSETS['_near_heap_head']
ROVER = DS + DATA_OFFSETS['_near_heap_rover']
RESERVE = DS + 0x2892dc
STACK, STOP, GDT = 0x3ff000, 0x3fff00, 0x350000
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)
DPMI_ADDR, DPMI_HANDLE, DOS_BASE, RESERVE_SEG, HEAP_SEG = 0x40000, 0x1234, 0x50000, 8, 0x2000
CASES = ('dpmi_success', 'dos_success', 'dos_reserve_fail', 'dos_heap_fail', 'oversize')


def exercise(memory, entry, body, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    cpu.mem_write(GDT, bytes(8) + bytes.fromhex('ff ff 00 00 00 93 cf 00'))
    cpu.reg_write(UC_X86_REG_GDTR, (0, GDT, 15, 0))
    cpu.reg_write(UC_X86_REG_SS, 8)

    def put(addr, *words):
        cpu.mem_write(addr, pack('<' + 'I' * len(words), *words))

    def get(addr):
        return unpack('<I', cpu.mem_read(addr, 4))[0]

    request = 0x10001 if case == 'oversize' else 0x2000
    dpmi = 0
    dos_alloc = 0

    def service(uc, interrupt, _):
        nonlocal dpmi, dos_alloc
        eax = uc.reg_read(UC_X86_REG_EAX)
        flags = uc.reg_read(UC_X86_REG_EFLAGS)
        low = lambda reg: uc.reg_read(reg) & 0xffff
        if interrupt == 0x31:
            if (eax >> 8) == 5:  # 0501h allocate memory block
                dpmi += 1
                if case == 'dpmi_success':
                    uc.reg_write(UC_X86_REG_EBX, DPMI_ADDR >> 16)
                    uc.reg_write(UC_X86_REG_ECX, DPMI_ADDR & 0xffff)
                    uc.reg_write(UC_X86_REG_ESI, DPMI_HANDLE >> 16)
                    uc.reg_write(UC_X86_REG_EDI, DPMI_HANDLE & 0xffff)
                    uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)
                else:
                    uc.reg_write(UC_X86_REG_EFLAGS, flags | 1)
            elif (eax >> 8) == 0:  # 0006h get selector base
                assert low(UC_X86_REG_EBX) == HEAP_SEG
                uc.reg_write(UC_X86_REG_ECX, DOS_BASE >> 16)
                uc.reg_write(UC_X86_REG_EDX, DOS_BASE & 0xffff)
                uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)
            else:
                raise AssertionError(f'Unexpected DPMI function {eax:#x}')
        elif interrupt == 0x21:
            if (eax >> 8) == 0x48:  # allocate paragraphs in BX
                dos_alloc += 1
                if dos_alloc == 1 and case == 'dos_reserve_fail':
                    uc.reg_write(UC_X86_REG_EFLAGS, flags | 1)
                    uc.reg_write(UC_X86_REG_EAX, 8)
                elif dos_alloc == 2 and case == 'dos_heap_fail':
                    uc.reg_write(UC_X86_REG_EFLAGS, flags | 1)
                    uc.reg_write(UC_X86_REG_EAX, 8)
                else:
                    segment = RESERVE_SEG if dos_alloc == 1 else HEAP_SEG
                    uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)
                    uc.reg_write(UC_X86_REG_EAX, segment)
            elif (eax >> 8) == 0x49:  # free ES segment
                uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)
            else:
                raise AssertionError(f'Unexpected DOS function {eax:#x}')
        else:
            raise AssertionError(f'Unexpected interrupt {interrupt:#x}')

    cpu.hook_add(UC_HOOK_INTR, service)
    put(HEAD, 0)
    put(ROVER, 0)
    put(RESERVE, 0)
    put(STACK, STOP)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, request)
    for i, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12345670 + i)
    cpu.emu_start(entry, STOP, count=2000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12345670 + i for i, reg in enumerate(SAVED))

    if case == 'dpmi_success':
        assert dpmi == 1 and dos_alloc == 0
        assert cpu.reg_read(UC_X86_REG_EAX) == DPMI_ADDR + 8
        assert get(DPMI_ADDR) == DPMI_HANDLE
        assert get(DPMI_ADDR + 4) == 0
        assert get(DPMI_ADDR + 8) == request - 8
    elif case == 'dos_success':
        assert dpmi == 1 and dos_alloc == 2
        assert cpu.reg_read(UC_X86_REG_EAX) == DOS_BASE + 8
        assert get(DOS_BASE + 4) == HEAP_SEG
        assert get(DOS_BASE + 8) == request - 8
    else:
        assert cpu.reg_read(UC_X86_REG_EAX) == 0
        if case == 'dos_reserve_fail':
            assert dos_alloc == 1
        elif case == 'dos_heap_fail':
            assert dos_alloc == 2
        elif case == 'oversize':
            assert dos_alloc == 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    loaded['_dos_reserve_bytes'] = DS + 0x2892dc
    loaded['_dos_reserve_high_word'] = DS + 0x2892de
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
    assert len(body) == 211 and sites == 3
    for code in (memory[entry:entry + len(body)], bytes(body)):
        for case in CASES:
            exercise(memory, entry, code, case)
    print(f'PASS: {len(body)} exact bytes, {sites} LE relocations, {len(CASES)} original and {len(CASES)} restored allocate cases')


if __name__ == '__main__':
    main()
