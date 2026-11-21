"""Verify DOS access checking with a stubbed attribute service and errno call."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOLS = ('access_', 'access_translate_')
STACK, STOP = 0x3ff000, 0x3fff00
CASES = ('ok', 'error', 'deny')


def exercise(memory, entry, body, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)

    def put(addr, *words):
        cpu.mem_write(addr, pack('<' + 'I' * len(words), *words))

    dosret0_args = []

    def dosret0_hook(uc, *_):
        dosret0_args.append((uc.reg_read(UC_X86_REG_EAX), uc.reg_read(UC_X86_REG_EDX)))
        uc.reg_write(UC_X86_REG_EAX, 0xffffffff)

    cpu.hook_add(UC_HOOK_CODE, dosret0_hook, begin=FUNCTION_ADDRESSES['dosret0_'],
                 end=FUNCTION_ADDRESSES['dosret0_'])
    cpu.mem_write(FUNCTION_ADDRESSES['dosret0_'], b'\xc3')

    def dos_43h(uc, interrupt, _):
        assert interrupt == 0x21
        flags = uc.reg_read(UC_X86_REG_EFLAGS)
        if case == 'error':
            uc.reg_write(UC_X86_REG_EAX, 5)
            uc.reg_write(UC_X86_REG_EFLAGS, flags | 1)
        else:
            uc.reg_write(UC_X86_REG_ECX, 1 if case == 'deny' else 0)
            uc.reg_write(UC_X86_REG_EFLAGS, flags & ~1)

    cpu.hook_add(UC_HOOK_INTR, dos_43h)
    put(STACK, STOP)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, 0x1234)          # filename
    cpu.reg_write(UC_X86_REG_EDX, 2 if case == 'deny' else 0)  # mode
    cpu.emu_start(entry, STOP, count=2000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.reg_read(UC_X86_REG_EAX) == 0xffffffff
    assert len(dosret0_args) == 1
    _, flag = dosret0_args[0]
    if case == 'ok':
        assert flag == 0
    else:
        assert flag == 0xffff


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
    assert len(body) == 59
    for code in (memory[entry:entry + len(body)], bytes(body)):
        for case in CASES:
            exercise(memory, entry, code, case)
    print(f'PASS: {len(body)} exact bytes, {sites} LE relocations, {len(CASES)} original and {len(CASES)} restored access cases')


if __name__ == '__main__':
    main()
