"""Exercise the restored sample queue and controls in the exact executable."""
import argparse
from pathlib import Path

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX, UC_X86_REG_ESP, UC_X86_REG_EIP

from verify_c_leaf import LEAVES


def check(image):
    slots, driver, samples, sample_input = 0x1663c, 0x100000, 0x110000, 0x120000
    stack, stop = 0x1f0000, 0x1ff000
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x200000)
    machine.mem_write(0x10000, image[0x35600:0x9b600])

    def write(address, value):
        machine.mem_write(address, value.to_bytes(4, 'little'))

    def read(address, size=4):
        return int.from_bytes(machine.mem_read(address, size), 'little')

    def call(symbol, eax=0, edx=0, ebx=0):
        addr = LEAVES[symbol+'_'][0] - 0x25600
        write(stack, stop)
        for reg, val in [(UC_X86_REG_EAX, eax), (UC_X86_REG_EDX, edx),
                         (UC_X86_REG_EBX, ebx), (UC_X86_REG_ESP, stack)]:
            machine.reg_write(reg, val)
        machine.emu_start(addr, stop, count=5000)
        assert machine.reg_read(UC_X86_REG_ESP) == stack+4, symbol
        return machine.reg_read(UC_X86_REG_EAX)

    # Exercise the queue's register ABI using a flat-memory stand-in for
    # the DOS runtime's segmented memcpy.
    def copy_sample(cpu, _address, _size, _data):
        destination = cpu.reg_read(UC_X86_REG_EAX)
        source = cpu.reg_read(UC_X86_REG_EDX)
        length = cpu.reg_read(UC_X86_REG_EBX)
        assert source == sample_input and length == 0xf0
        cpu.mem_write(destination, bytes(cpu.mem_read(source, length)))
        sp = cpu.reg_read(UC_X86_REG_ESP)
        cpu.reg_write(UC_X86_REG_ESP, sp+4)
        cpu.reg_write(UC_X86_REG_EIP, read(sp))

    memcpy = LEAVES['memcpy_'][0] - 0x25600
    machine.hook_add(UC_HOOK_CODE, copy_sample, begin=memcpy, end=memcpy)

    # DS-relative operands are unrelocated. Initialize the slot in this flat
    # test mapping before setting up two sample records and one template.
    write(slots, 0)
    assert call('queue_audio_sample', edx=sample_input) == 10
    write(slots, driver)
    write(driver+0x14, 2)
    write(driver+0x58, samples)
    write(driver+0x1c, 99)
    write(driver+0x54, 42)
    write(sample_input, 0x891abc)
    write(sample_input+0x1c, 0x123)
    write(sample_input+0x2c, 0x56)
    assert call('read_driver_field_1c') == 99
    assert call('read_driver_field_54') == 42
    assert call('sample_is_inactive') == 1
    assert call('get_sample_field_2c') == 10

    assert call('queue_audio_sample', edx=sample_input) == 0
    assert read(driver+0x30) == samples
    assert read(samples+4) == 0x891abc
    assert read(samples+0x21, 1) == 0x80
    assert read(samples+0xec) == 0
    assert call('sample_is_inactive') == 0
    assert call('get_sample_identifier') == 0x123
    for field, previous, new in [('2c', 0x56, 0x78), ('44', 0, 0xe1), ('34', 0, 0xa9)]:
        assert call(f'set_sample_field_{field}', ebx=new) == previous
        assert call(f'get_sample_field_{field}') == new

    write(sample_input+0x1c, 0x456)
    assert call('queue_audio_sample', edx=sample_input) == 1
    second_sample = samples+0xf0
    assert read(samples+0xec) == second_sample
    assert read(second_sample+0xec) == 0
    assert call('find_sample_by_identifier', edx=0x456) == 1
    assert call('find_sample_by_identifier', edx=0x999) == 0xffffffff
    assert call('queue_audio_sample', edx=sample_input) == 0xffffffff
    assert call('request_sample_stop', edx=1) == 0
    assert read(second_sample+0x21, 1) == 0xc0
    assert read(samples+0x21, 1) == 0x80
    assert call('request_all_samples_stop') == 0
    assert read(samples+0x21, 1) == 0xc0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes())
    print('PASS: audio sample queue and controls')
