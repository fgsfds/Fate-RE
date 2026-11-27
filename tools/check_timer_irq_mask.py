"""Verify timer IRQ mask/unmask control flow with stubbed PIC port I/O."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOLS = ('mask_timer_irq_', 'unmask_timer_irq_')
PIT_ENABLED = DS + DATA_OFFSETS['_pit_programming_enabled']
STACK, STOP = 0x3ff000, 0x3fff00


def exercise(memory, entry, body, symbol, enabled):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    cpu.mem_write(PIT_ENABLED, pack('<I', 1 if enabled else 0))
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)

    io = []

    def hook(uc, address, size, user_data):
        opcode = uc.mem_read(address, 1)[0]
        if opcode == 0xec:  # in al, dx
            io.append(('in', uc.reg_read(UC_X86_REG_EDX) & 0xffff))
            uc.reg_write(UC_X86_REG_EAX, (uc.reg_read(UC_X86_REG_EAX) & ~0xff) | 0)
            uc.reg_write(UC_X86_REG_EIP, address + 1)
        elif opcode == 0xee:  # out dx, al
            io.append(('out', uc.reg_read(UC_X86_REG_EDX) & 0xffff, uc.reg_read(UC_X86_REG_EAX) & 0xff))
            uc.reg_write(UC_X86_REG_EIP, address + 1)

    cpu.hook_add(UC_HOOK_CODE, hook)
    try:
        cpu.emu_start(entry, STOP, count=200)
    except Exception:
        pass  # the ret reaches a garbage address after Unicorn's push es quirk
    if enabled:
        assert io == [('in', 0x21), ('out', 0x21, 1 if symbol == 'mask_timer_irq_' else 0)]
    else:
        assert io == []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    for symbol in SYMBOLS:
        raw, size = LEAVES[symbol]
        entry = raw - 0x25600
        code, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES)
        assert len(code) == size and code == exe[raw:raw + size], symbol
        verify_leaf_relocations(code, refs, pointers, entry)
        patched, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
        for code2 in (memory[entry:entry + size], patched):
            for enabled in (False, True):
                exercise(memory, entry, code2, symbol, enabled)
    print('PASS: 88 exact bytes, 2 LE relocations, 4 original and 4 restored timer mask cases')


if __name__ == '__main__':
    main()
