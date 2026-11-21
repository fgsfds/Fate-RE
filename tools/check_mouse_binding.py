"""Exercise mouse binding selection, synthetic keys, and the action latch."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESP, UC_X86_REG_EIP,
)

from check_start_hook import DS, image
from verify_c_leaf import DATA_OFFSETS, LEAVES

STACK, STOP = 0x3ff000, 0x3fff00


def check(memory, buttons, bindings, keys, pending, previous, flags, expected):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)

    def address(name):
        return DS + DATA_OFFSETS[name]

    key_map = bytes(keys.get(i, 32) for i in range(25))
    key_state = address('_mouse_key_state')
    cpu.mem_write(address('_mouse_button_bindings'), bytes(bindings))
    cpu.mem_write(address('_mouse_action_keys'), key_map)
    cpu.mem_write(address('_pending_mouse_action'), pack('<i', pending))
    cpu.mem_write(address('_previous_mouse_action'), pack('<H', previous))
    cpu.mem_write(address('_mouse_input_actions'), pack('<H', flags))
    cpu.mem_write(key_state, bytes(256))
    if pending != -1:
        cpu.mem_write(key_state + key_map[pending], b'\x01')

    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, buttons)
    preserved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX)
    for register in preserved:
        cpu.reg_write(register, 0x12340000 + register)
    cpu.emu_start(LEAVES['apply_mouse_button_binding_'][0] - 0x25600, STOP, count=1000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12340000 + reg for reg in preserved)

    after_pending = unpack('<i', cpu.mem_read(address('_pending_mouse_action'), 4))[0]
    after_previous = unpack('<H', cpu.mem_read(address('_previous_mouse_action'), 2))[0]
    after_flags = unpack('<H', cpu.mem_read(address('_mouse_input_actions'), 2))[0]
    pressed = [index for index, byte in enumerate(cpu.mem_read(key_state, 256)) if byte]
    assert (after_pending, after_previous, after_flags, pressed) == expected


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    bindings = (24, 0, 7)
    keys = {24: 6, 7: 18}
    check(memory, 0, bindings, keys, 24, 0, 0, (-1, 0, 0, []))
    check(memory, 1, bindings, keys, -1, 0, 0, (24, 0, 0, [6]))
    check(memory, 2, bindings, keys, 24, 0, 0, (7, 0, 0, [18]))
    check(memory, 4, bindings, keys, -1, 0, 1, (-1, 0, 0x801, []))
    check(memory, 4, bindings, keys, -1, 1, 1, (-1, 1, 1, []))
    check(memory, 4, bindings, keys, -1, 1, 0x801, (-1, 0, 0x801, []))
    check(memory, 1, (25, 0, 7), keys, 7, 2, 1, (-1, 2, 1, []))
    check(memory, 1 | 2, bindings, keys, -1, 0, 0, (24, 0, 0, [6]))
    print('PASS: eight mouse binding and action-latch scenarios')
