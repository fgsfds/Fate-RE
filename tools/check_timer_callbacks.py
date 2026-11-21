"""Exercise the rebuilt HMI timer scheduler with hardware calls stubbed."""
import argparse
from pathlib import Path
from struct import calcsize, pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES
from verify_c_suite import LEAVES


STACK, RETURN, CALLBACK, SLOT = 0x3ff000, 0x3fff00, 0x3fff10, 0x3fff20
PIT_CLOCK, BIOS_RATE, BIOS_DIVISOR = 0x1234dc, 0xff00, 0xffff


def check(executable):
    memory = image(executable.read_bytes())
    emu = Uc(UC_ARCH_X86, UC_MODE_32)
    emu.mem_map(0, len(memory))
    emu.mem_write(0, memory)
    calls = []

    def location(symbol, index):
        return DS + DATA_OFFSETS['_'+symbol] + 4*index

    def get(symbol, index=0, fmt='I'):
        return unpack('<'+fmt, emu.mem_read(location(symbol, index), calcsize('<'+fmt)))[0]

    def set_value(symbol, value, index=0, fmt='I'):
        emu.mem_write(location(symbol, index), pack('<'+fmt, value))

    stubs = {FUNCTION_ADDRESSES[name+'_']: name for name in (
        'program_pit', 'install_timer_vector', 'mask_timer_irq', 'unmask_timer_irq',
        'restore_timer_vector', 'chain_original_timer',
    )}
    stubs[CALLBACK] = 'callback'
    for address in stubs:
        emu.mem_write(address, b'\xc3')

    def record_call(_, address, size, user):
        if address in stubs:
            calls.append((stubs[address], get('current_timer_context')))

    emu.hook_add(UC_HOOK_CODE, record_call)

    def invoke(name, eax=0, edx=0, ebx=0):
        raw, _ = LEAVES[name+'_']
        emu.mem_write(STACK, pack('<I', RETURN))
        for register, value in ((UC_X86_REG_ESP, STACK), (UC_X86_REG_EAX, eax),
                                (UC_X86_REG_EDX, edx), (UC_X86_REG_EBX, ebx)):
            emu.reg_write(register, value)
        emu.emu_start(raw-0x25600, RETURN, count=10000)
        assert emu.reg_read(UC_X86_REG_EIP) == RETURN, name
        assert emu.reg_read(UC_X86_REG_ESP) == STACK+4, name
        return emu.reg_read(UC_X86_REG_EAX)

    for table in ('timer_callbacks', 'timer_frequencies', 'timer_increments',
                  'timer_accumulators', 'timer_contexts'):
        emu.mem_write(location(table, 0), bytes(16*4))
    set_value('timer_flags', 1, fmt='B')
    assert invoke('timer_initialize', 120, 1) == 0
    assert not calls and get('timer_flags', fmt='B') == 0
    assert get('pit_divisor') == BIOS_DIVISOR

    assert invoke('timer_initialize', BIOS_RATE, 2) == 0
    assert get('use_dpmi_vector', fmt='B') == 1
    assert get('timer_flags', fmt='B') == 1
    assert get('timer_frequencies', 15) == BIOS_RATE
    assert get('timer_callbacks', 15) == LEAVES['default_timer_callback_'][0]-0x25600
    assert [name for name, _ in calls] == [
        'mask_timer_irq', 'install_timer_vector', 'unmask_timer_irq', 'program_pit',
    ]

    assert invoke('timer_register_callback', 120, CALLBACK, SLOT) == 0
    assert unpack('<I', emu.mem_read(SLOT, 4))[0] == 0
    assert get('pit_divisor') == PIT_CLOCK//120
    assert invoke('timer_get_frequency', 0) == 120
    assert get('timer_increments', 0) == (120 << 16)//(PIT_CLOCK//get('pit_divisor'))
    assert invoke('timer_set_frequency', 16, 240) == 10
    assert invoke('timer_set_frequency', 1, 240) == 10
    assert invoke('timer_set_frequency', 0, 240) == 0
    assert invoke('timer_get_frequency', 0) == 240
    assert get('pit_divisor') == PIT_CLOCK//240

    set_value('timer_contexts', 7, fmt='B')
    set_value('timer_contexts', 0xff, 15, fmt='B')
    set_value('timer_accumulators', 9)
    set_value('timer_accumulators', 0, 15)
    set_value('timer_increments', 0x10008)
    set_value('timer_increments', 0x10000, 15)
    calls.clear()
    invoke('timer_dispatch_callbacks')
    assert calls == [('callback', 7), ('chain_original_timer', 7)]
    assert get('timer_accumulators') == 17

    assert invoke('timer_remove_callback', 0) == 0
    assert get('timer_callbacks') == 0 and get('pit_divisor') == BIOS_DIVISOR
    calls.clear()
    assert invoke('timer_shutdown', 0) == 0
    assert [name for name, _ in calls] == [
        'mask_timer_irq', 'restore_timer_vector', 'unmask_timer_irq',
    ]
    print('HMI timer initialization, registration, frequency, dispatch, removal, and shutdown passed')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    check(parser.parse_args().executable)
