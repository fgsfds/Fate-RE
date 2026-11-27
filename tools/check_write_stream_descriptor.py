"""Verify descriptor writes, append seeks, and DOS error translation."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INTR, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'write_stream_descriptor_'
ENTRY = FUNCTION_ADDRESSES[SYMBOL]
GET_MODE, SET_ERRNO, SET_DOS_ERRNO = 0x65783, 0x6468e, 0x6571d
BUFFER, STACK, STOP = 0x300000, 0x3f0000, 0x3ff000
DESCRIPTOR, COUNT = 7, 12


def exercise(code, mode, seek_error, written, write_error):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x400000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(BUFFER, bytes(range(COUNT)))
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, DESCRIPTOR)
    cpu.reg_write(UC_X86_REG_EBX, COUNT)
    cpu.reg_write(UC_X86_REG_EDX, BUFFER)
    preserved = {
        UC_X86_REG_ECX: 0x12345678, UC_X86_REG_ESI: 0x23456789,
        UC_X86_REG_EDI: 0x3456789a, UC_X86_REG_EBP: 0x456789ab,
    }
    for register, value in preserved.items():
        cpu.reg_write(register, value)
    calls = []

    def runtime(machine, address, _size, _data):
        argument = machine.reg_read(UC_X86_REG_EAX)
        if address == GET_MODE:
            calls.append(('mode', argument))
            machine.reg_write(UC_X86_REG_EAX, mode)
        elif address == SET_DOS_ERRNO:
            calls.append(('dos errno', argument))
            machine.reg_write(UC_X86_REG_EAX, 0xffffffff)
        else:
            calls.append(('errno', argument))
            machine.reg_write(UC_X86_REG_EAX, 0xdeadbeef)

    for address in (GET_MODE, SET_ERRNO, SET_DOS_ERRNO):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, runtime, begin=address, end=address)

    def dos(machine, interrupt, _data):
        assert interrupt == 0x21
        eax, ebx, ecx, edx = (machine.reg_read(r) for r in (
            UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX))
        assert ebx == DESCRIPTOR
        if eax & 0xff00 == 0x4200:
            assert (eax & 0xff, ecx, edx) == (2, 0, 0)
            calls.append(('seek end',))
            machine.reg_write(UC_X86_REG_EAX, seek_error or 0x4567)
            machine.reg_write(UC_X86_REG_EDX, 0 if seek_error else 1)
            carry = bool(seek_error)
        else:
            assert eax & 0xff00 == 0x4000
            assert (ecx, edx) == (COUNT, BUFFER)
            calls.append(('write',))
            machine.reg_write(UC_X86_REG_EAX, write_error or written)
            carry = bool(write_error)
        flags = machine.reg_read(UC_X86_REG_EFLAGS)
        machine.reg_write(UC_X86_REG_EFLAGS, (flags & ~1) | carry)

    cpu.hook_add(UC_HOOK_INTR, dos)
    cpu.emu_start(ENTRY, STOP, count=120)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    for register, value in preserved.items():
        assert cpu.reg_read(register) == value
    expected = [('mode', DESCRIPTOR)]
    if mode & 0x80:
        expected.append(('seek end',))
    if not seek_error:
        expected.append(('write',))
    if seek_error or write_error:
        expected.append(('dos errno', seek_error or write_error))
    elif written != COUNT:
        expected.append(('errno', 12))
    assert calls == expected
    assert cpu.reg_read(UC_X86_REG_EAX) == (0xffffffff if seek_error or write_error else written)


def check(executable, obj):
    raw, length = LEAVES[SYMBOL]
    expected = executable[raw:raw + length]
    code, references = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY,
                                         functions=FUNCTION_ADDRESSES)
    assert code == expected and not references
    verify_leaf_relocations(code, references, read_le_fixups(executable)['pointers'], ENTRY)
    for body in (expected, code):
        for scenario in ((0, 0, COUNT, 0), (0, 0, 4, 0), (0, 0, 0, 0),
                         (0, 0, 0, 5), (0x80, 0, COUNT, 0), (0x80, 6, 0, 0)):
            exercise(body, *scenario)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
    print('PASS: 124 exact bytes, no LE relocations, 6 original/restored descriptor write cases')
