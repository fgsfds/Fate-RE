"""Verify exact environment scanning, allocation, copy, and failure cleanup."""
import argparse
from pathlib import Path
from struct import pack, unpack_from

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)
from verify_c_suite import ENV_COPY_ENTRIES

ENTRY = LEAVES[ENV_COPY_ENTRIES[0]][0] - 0x25600
SOURCE, STRINGS, VECTOR = 0x200000, 0x201000, 0x202000
STACK, STOP = 0x7000, 0x7800
SAVED = (UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_EDX, UC_X86_REG_ECX, UC_X86_REG_EBX)


def scenario(code, strings, results):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x400000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(STACK, pack('<8I', 0, 0, 11, 12, 13, 14, 15, STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(DATA_OFFSETS['_dos_environment_offset'], pack('<I', SOURCE))
    payload = b''.join(value + b'\x00' for value in strings)
    cpu.mem_write(SOURCE, payload + b'\x00')
    cpu.mem_write(STRINGS, b'\xcd' * 128)
    cpu.mem_write(VECTOR, b'\xcd' * 128)

    allocations, frees, clears = [], [], []
    results = iter(results)

    def allocate(emu, address, size, user_data):
        allocations.append(emu.reg_read(UC_X86_REG_EAX))
        emu.reg_write(UC_X86_REG_EAX, next(results))

    def release(emu, address, size, user_data):
        frees.append(emu.reg_read(UC_X86_REG_EAX))

    def clear(emu, address, size, user_data):
        start, count = emu.reg_read(UC_X86_REG_EAX), emu.reg_read(UC_X86_REG_EBX)
        assert emu.reg_read(UC_X86_REG_EDX) == 0
        clears.append((start, count))
        if count:
            emu.mem_write(start, bytes(count))

    for name, callback in (('malloc_', allocate), ('free_', release), ('memset_', clear)):
        address = FUNCTION_ADDRESSES[name]
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, callback, begin=address, end=address)

    cpu.emu_start(ENTRY, STOP, count=1000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 32
    assert tuple(cpu.reg_read(reg) for reg in SAVED) == (11, 12, 13, 14, 15)
    assert allocations[0] == max(1, len(payload))
    head = unpack_from('<I', cpu.mem_read(DATA_OFFSETS['_environment_vector'], 4))[0]
    flags = unpack_from('<I', cpu.mem_read(DATA_OFFSETS['_environment_flags'], 4))[0]
    if not head:
        assert not flags and not clears
        assert frees == ([STRINGS] if len(allocations) == 2 else [])
        assert cpu.mem_read(STRINGS, 128) == b'\xcd' * 128
    else:
        assert head == VECTOR and not frees
        flag_start = VECTOR + 4 * (len(strings) + 1)
        assert flags == flag_start and clears == [(flag_start, len(strings))]
        expected_vector, offset = [], 0
        for string in strings:
            expected_vector.append(STRINGS + offset)
            offset += len(string) + 1
        expected_vector.append(0)
        vector = unpack_from(f'<{len(expected_vector)}I', cpu.mem_read(VECTOR, flag_start - VECTOR))
        assert list(vector) == expected_vector
        assert cpu.mem_read(STRINGS, len(payload) + 1) == payload + b'\xcd'
        assert cpu.mem_read(flag_start, len(strings) + 1) == bytes(len(strings)) + b'\xcd'
    if len(allocations) == 2:
        assert allocations[1] == 5 * len(strings) + 4


def check(executable, obj):
    original, restored = bytearray(), bytearray()
    sites = 0
    pointers = read_le_fixups(executable)['pointers']
    for symbol in ENV_COPY_ENTRIES:
        raw, size = LEAVES[symbol]
        entry = raw - 0x25600
        assert entry == ENTRY + len(original)
        expected = executable[raw:raw + size]
        code, bindings = bind_leaf_details(
            obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES,
        )
        assert expected == code, symbol
        verify_leaf_relocations(code, bindings, pointers, entry)
        original.extend(expected)
        restored.extend(code)
        sites += len(bindings)
    for code in (bytes(original), bytes(restored)):
        scenario(code, (b'A=1', b'PATH=C:\\DOS'), (STRINGS, VECTOR))
        scenario(code, (), (STRINGS, VECTOR))
        scenario(code, (b'A=1',), (0,))
        scenario(code, (b'A=1',), (STRINGS, 0))
    print(f'PASS: {len(original)} exact bytes, {sites} LE relocations, 4 original/restored environment cases')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())


if __name__ == '__main__':
    main()
