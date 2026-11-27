"""Exercise the DOS spawn dispatcher with deterministic runtime and exec stubs."""

import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_DS, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX,
    UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ES, UC_X86_REG_ESI, UC_X86_REG_ESP, UC_X86_REG_GDTR, UC_X86_REG_SS,
)

from check_start_hook import DS, image
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES


PROGRAM, ARGV, ENVP = 0x310000, 0x310100, 0x310200
BASE, SUFFIX, DRIVE, DIRECTORY = 0x310300, 0x310310, 0x310320, 0x310330
PATH, TAIL, ENVIRONMENT = 0x320000, 0x321000, 0x322000
STACK, RETURN = 0x3ff000, 0x3fff00
SAVE, RESTORE = 0x3ff100, 0x3ff110
SAVED = (UC_X86_REG_EBP, UC_X86_REG_ESI, UC_X86_REG_EDI)
REGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)


def exercise(memory, mode, environment_ok, heap_path, expected):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(0x1000, pack('<QQQ', 0, 0x00cf9a000000ffff, 0x00cf92000000ffff))
    cpu.reg_write(UC_X86_REG_GDTR, (0, 0x1000, 23, 0))
    for reg in (UC_X86_REG_DS, UC_X86_REG_ES, UC_X86_REG_SS):
        cpu.reg_write(reg, 0x10)

    def put(address, value):
        cpu.mem_write(address, pack('<I', value))

    def get(address):
        return unpack('<I', cpu.mem_read(address, 4))[0]

    for address, data in ((PROGRAM, b'FATE.EXE\0'), (BASE, b'FATE\0'), (SUFFIX, b'.EXE\0'),
                          (DRIVE, b'C:\0'), (DIRECTORY, b'\\DOS\\\0')):
        cpu.mem_write(address, data)
    put(DS + DATA_OFFSETS['_save_spawn_state'], SAVE)
    put(DS + DATA_OFFSETS['_restore_spawn_state'], RESTORE)
    calls = []
    snapshots = []
    allocations = iter((PATH if heap_path else 0, TAIL))
    return_sizes = {'check_stack_': 4, 'build_child_environment_': 12,
                    'split_path_': 8, 'make_path_': 4, 'prepare_spawn_': 4}
    names = (*return_sizes, 'malloc_', 'free_', 'set_errno_', 'stackavail_')
    hooks = {FUNCTION_ADDRESSES[name]: name for name in names} | {SAVE: 'save', RESTORE: 'restore'}

    def stub(engine, address, _size, _data):
        name = hooks[address]
        eax, edx, ebx, ecx = (engine.reg_read(reg) for reg in REGS)
        sp = engine.reg_read(UC_X86_REG_ESP)
        calls.append((name, eax) if name in ('set_errno_', 'free_', 'malloc_') else name)
        if name == 'check_stack_':
            assert get(sp + 4) == 0xe4
        elif name == 'build_child_environment_':
            assert (eax, edx, get(sp + 12)) == (ARGV, ENVP, 0)
            if environment_ok:
                put(ebx, ENVIRONMENT)
                put(ecx, ENVIRONMENT)
                put(get(sp + 4), 0)
                put(get(sp + 8), 144)
            engine.reg_write(UC_X86_REG_EAX, 2 if environment_ok else 0xffffffff)
        elif name == 'malloc_':
            engine.reg_write(UC_X86_REG_EAX, next(allocations))
        elif name == 'stackavail_':
            engine.reg_write(UC_X86_REG_EAX, 0x1000)
        elif name == 'split_path_':
            assert eax == PROGRAM
            for slot, value in ((ebx, DRIVE), (ecx, DIRECTORY),
                                (get(sp + 4), BASE), (get(sp + 8), SUFFIX)):
                put(slot, value)
        elif name == 'make_path_':
            assert (edx, ebx, ecx, get(sp + 4)) == (DRIVE, DIRECTORY, BASE, SUFFIX)
            engine.mem_write(eax, b'C:\\DOS\\FATE.EXE\0')
        elif name == 'prepare_spawn_':
            assert (eax, ebx, ecx, get(sp + 4)) == (mode, TAIL, ENVIRONMENT, ARGV)
            assert engine.mem_read(edx, 16) == b'C:\\DOS\\FATE.EXE\0'
            engine.reg_write(UC_X86_REG_EAX, 31)
        elif name in ('save', 'restore'):
            snapshots.append(eax)

    for address, name in hooks.items():
        width = return_sizes.get(name)
        cpu.mem_write(address, b'\xc2' + pack('<H', width) if width else b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, stub, begin=address, end=address)
    for reg, val in zip(REGS, (mode, PROGRAM, ARGV, ENVP)):
        cpu.reg_write(reg, val)
    for index, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12340000 + index)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    put(STACK, RETURN)
    cpu.emu_start(FUNCTION_ADDRESSES['spawnve_'], RETURN, count=6000)
    assert cpu.reg_read(UC_X86_REG_EIP) == RETURN
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12340000 + i for i, reg in enumerate(SAVED))
    assert cpu.reg_read(UC_X86_REG_ES) == 0x10
    if mode >= 2:
        sequence = ['check_stack_', ('set_errno_', 9)]
    elif not environment_ok:
        sequence = ['check_stack_', 'build_child_environment_']
    else:
        sequence = ['check_stack_', 'build_child_environment_', ('malloc_', 162)]
        if not heap_path:
            sequence.append('stackavail_')
        sequence.extend(('split_path_', 'save', ('malloc_', 144), 'make_path_',
                         ('set_errno_', 1), ('set_errno_', 0), 'prepare_spawn_',
                         ('free_', TAIL), ('free_', PATH if heap_path else 0),
                         ('free_', ENVIRONMENT), 'restore'))
        assert len(snapshots) == 2 and snapshots[0] == snapshots[1]
    assert calls == sequence, (calls, sequence)
    assert cpu.reg_read(UC_X86_REG_EAX) == expected & 0xffffffff


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    exercise(memory, 2, False, True, -1)
    exercise(memory, 1, False, True, -1)
    exercise(memory, 1, True, True, 31)
    exercise(memory, 0, True, False, 31)
    print('PASS: four DOS process dispatcher scenarios')
