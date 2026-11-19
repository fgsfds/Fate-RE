"""Verify the Windows driver dispatch branches on the multiplex result."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import UC_ARCH_X86, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

STACK, STOP = 0x3ff000, 0x3fff00


def exercise(memory, entry, body, version, expect_call):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.mem_write(STACK + 4, b'\x00' * 0x10)
    cpu.reg_write(UC_X86_REG_ESP, STACK)

    calls = []

    def intr_hook(uc, intno, user_data):
        if intno == 0x2f:
            uc.reg_write(UC_X86_REG_EAX, (uc.reg_read(UC_X86_REG_EAX) & ~0xff) | version)
        elif intno == 0x4b:
            calls.append('int4b')

    cpu.hook_add(UC_HOOK_INTR, intr_hook)
    try:
        cpu.emu_start(entry, STOP, count=200)
    except Exception:
        pass  # the ret reaches a garbage address after Unicorn's push es quirk
    assert (calls == ['int4b']) == expect_call


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: 0x80000 + offset for name, offset in DATA_OFFSETS.items()}
    symbol = 'windows_driver_interrupt_'
    raw, size = LEAVES[symbol]
    entry = raw - 0x25600
    code, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES)
    assert len(code) == size and code == exe[raw:raw + size], symbol
    verify_leaf_relocations(code, refs, pointers, entry)
    patched, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
    for code2 in (memory[entry:entry + size], patched):
        for version, expect_call in ((3, True), (2, False)):
            exercise(memory, entry, code2, version, expect_call)
    print('PASS: 53 exact bytes, 0 LE relocations, 2 original and 2 restored dispatch cases')


if __name__ == '__main__':
    main()
