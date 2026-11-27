"""Verify DOS binary-mode handle setup with stubbed IOCTL and errno services."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INTR, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOLS = (
    '__set_binary_', 'set_binary_device_get_', 'set_binary_dos_error_',
    'set_binary_device_set_', 'set_binary_success_', 'set_binary_restore_',
)
STACK, STOP = 0x3ff000, 0x3fff00
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI)
CASES = ('non_device', 'device_ok', 'device_get_error', 'device_set_error')


def exercise(memory, entry, body, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)

    def put(addr, *words):
        cpu.mem_write(addr, pack('<' + 'I' * len(words), *words))

    mode = 0x2000 if case != 'non_device' else 0
    ioctl_count = 0
    recorded_mode = []

    def get_io_mode_hook(uc, *_):
        uc.reg_write(UC_X86_REG_EAX, mode)

    def set_io_mode_hook(uc, *_):
        recorded_mode.append(uc.reg_read(UC_X86_REG_EDX))

    def set_dos_errno_hook(uc, *_):
        uc.reg_write(UC_X86_REG_EAX, 0xffffffff)

    cpu.hook_add(UC_HOOK_CODE, get_io_mode_hook, begin=FUNCTION_ADDRESSES['get_io_mode_'],
                 end=FUNCTION_ADDRESSES['get_io_mode_'])
    cpu.hook_add(UC_HOOK_CODE, set_io_mode_hook, begin=FUNCTION_ADDRESSES['set_io_mode_'],
                 end=FUNCTION_ADDRESSES['set_io_mode_'])
    cpu.hook_add(UC_HOOK_CODE, set_dos_errno_hook, begin=FUNCTION_ADDRESSES['set_dos_errno_'],
                 end=FUNCTION_ADDRESSES['set_dos_errno_'])
    cpu.mem_write(FUNCTION_ADDRESSES['get_io_mode_'], b'\xc3')
    cpu.mem_write(FUNCTION_ADDRESSES['set_io_mode_'], b'\xc3')
    cpu.mem_write(FUNCTION_ADDRESSES['set_dos_errno_'], b'\xc3')

    def ioctl(uc, interrupt, _):
        nonlocal ioctl_count
        assert interrupt == 0x21
        al = uc.reg_read(UC_X86_REG_EAX) & 0xff
        ioctl_count += 1
        flags = uc.reg_read(UC_X86_REG_EFLAGS)
        if al == 0:  # get device info
            error = (case == 'device_get_error')
            uc.reg_write(UC_X86_REG_EDX, 0)
            uc.reg_write(UC_X86_REG_EFLAGS, flags | (1 if error else 0))
        elif al == 1:  # set device info
            error = (case == 'device_set_error')
            uc.reg_write(UC_X86_REG_EDX, 0)
            uc.reg_write(UC_X86_REG_EFLAGS, flags | (1 if error else 0))
        else:
            raise AssertionError(f'Unexpected IOCTL subfunction {al:#x}')

    cpu.hook_add(UC_HOOK_INTR, ioctl)
    put(STACK, STOP)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, 0x1234)
    for i, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12345670 + i)
    cpu.emu_start(entry, STOP, count=2000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12345670 + i for i, reg in enumerate(SAVED))
    result = cpu.reg_read(UC_X86_REG_EAX)
    if case == 'non_device':
        assert result == 0 and ioctl_count == 0
    elif case == 'device_ok':
        assert result == 0 and ioctl_count == 2
    elif case == 'device_get_error':
        assert result == 0xffffffff and ioctl_count == 1
    else:
        assert result == 0xffffffff and ioctl_count == 2
    assert recorded_mode == [mode | 0x40]


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
    assert len(body) == 101
    for code in (memory[entry:entry + len(body)], bytes(body)):
        for case in CASES:
            exercise(memory, entry, code, case)
    print(f'PASS: {len(body)} exact bytes, {sites} LE relocations, {len(CASES)} original and {len(CASES)} restored set-binary cases')


if __name__ == '__main__':
    main()
