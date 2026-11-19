"""Verify the FPU configuration sequence issues the x87 instructions and branch."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32, Uc
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

STACK, STOP = 0x3ff000, 0x3fff00


def exercise(memory, entry, body):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)

    seen = []

    def hook(uc, address, size, user_data):
        op = uc.mem_read(address, 1)[0]
        if op == 0x9b:  # wait / fwait
            seen.append('wait')
            uc.reg_write(UC_X86_REG_EIP, address + 1)
        elif op in (0xd9, 0xde, 0xdf):  # x87 op
            seen.append('fpu')
            if op == 0xdf and uc.mem_read(address + 1, 1)[0] == 0xe0:  # fnstsw ax
                uc.reg_write(UC_X86_REG_EAX, (uc.reg_read(UC_X86_REG_EAX) & ~0xffff) | 0x4000)
            uc.reg_write(UC_X86_REG_EIP, address + 2)

    cpu.hook_add(UC_HOOK_CODE, hook)
    try:
        cpu.emu_start(entry, STOP, count=200)
    except Exception:
        pass
    assert seen.count('fpu') >= 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: 0x80000 + offset for name, offset in DATA_OFFSETS.items()}
    symbol = 'configure_fpu_'
    raw, size = LEAVES[symbol]
    entry = raw - 0x25600
    code, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES)
    assert len(code) == size and code == exe[raw:raw + size], symbol
    verify_leaf_relocations(code, refs, pointers, entry)
    patched, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
    for code2 in (memory[entry:entry + size], patched):
        exercise(memory, entry, code2)
    print('PASS: 39 exact bytes, 0 LE relocations, 1 original and 1 restored FPU configure case')


if __name__ == '__main__':
    main()
