"""Exercise startup and spawn FPU callback registration without executing x87 code."""

import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from verify_c_leaf import CODE_OFFSETS, DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES


STACK, RETURN = 0x3ff000, 0x3fff00
CONTROL_WORD = 0xa57f
PRESERVED = {UC_X86_REG_EBX: 0x12345678, UC_X86_REG_EDX: 0x9abcdef0}
INITIAL_HOOKS = (0x12345, 0x67890)


def exercise(memory, symbol, present, configure):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    save = DS + DATA_OFFSETS['_save_spawn_state']
    restore = DS + DATA_OFFSETS['_restore_spawn_state']
    control = DS + DATA_OFFSETS['_fpu_control_word']
    cpu.mem_write(DS + DATA_OFFSETS['_fpu_present'], bytes([present]))
    cpu.mem_write(control, pack('<H', CONTROL_WORD))
    cpu.mem_write(save, pack('<I', INITIAL_HOOKS[0]))
    cpu.mem_write(restore, pack('<I', INITIAL_HOOKS[1]))
    cpu.reg_write(UC_X86_REG_EAX, 0xffff0000)
    for reg, value in PRESERVED.items():
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', RETURN))
    target = FUNCTION_ADDRESSES['configure_fpu_']
    cpu.mem_write(target, b'\xc3')
    calls = []

    def get_hooks():
        return tuple(unpack('<I', cpu.mem_read(address, 4))[0] for address in (save, restore))

    expected = (tuple(0x10000 + CODE_OFFSETS[name] for name in
                      ('save_fpu_state_', 'restore_fpu_state_')) if present else INITIAL_HOOKS)

    def configure_stub(engine, _address, _size, _data):
        assert get_hooks() == expected
        calls.append(engine.reg_read(UC_X86_REG_EAX))

    cpu.hook_add(UC_HOOK_CODE, configure_stub, begin=target, end=target)
    cpu.emu_start(LEAVES[symbol][0] - 0x25600, RETURN, count=40)
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.reg_read(UC_X86_REG_EIP) == RETURN
    assert all(cpu.reg_read(reg) == value for reg, value in PRESERVED.items())
    assert get_hooks() == expected
    assert calls == ([CONTROL_WORD] if configure else [])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    for entry in ('init_fpu_callbacks_', 'check_fpu_callbacks_'):
        for present in (0, 2):
            exercise(memory, entry, present, entry == 'init_fpu_callbacks_' or present != 0)
    print('PASS: four spawn FPU callback scenarios')
