"""Verify stream allocation, list links, and the failure paths in the exact build."""

import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EDI, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES


STACK, RETURN = 0x3ff000, 0x3fff00
RECORD_SIZE = 26
FREELIST, NEXT_LINK, OPENLIST = 0x310000, 0x310010, 0x310020
RECYCLED_STREAM, HEAP_BLOCK = 0x310100, 0x310200
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)


def exercise(memory, recycled, free_slot, allocation_failed):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    free_list = DS + DATA_OFFSETS['_recycled_streams']
    open_list = DS + DATA_OFFSETS['_open_streams']
    first = DS + DATA_OFFSETS['_static_streams']
    end = DS + DATA_OFFSETS['_static_streams_end']
    cpu.mem_write(free_list, pack('<I', FREELIST if recycled else 0))
    cpu.mem_write(open_list, pack('<I', OPENLIST))
    cpu.mem_write(FREELIST, pack('<II', NEXT_LINK, RECYCLED_STREAM))
    cpu.mem_write(RECYCLED_STREAM, bytes([0xa5]) * RECORD_SIZE)
    cpu.mem_write(RECYCLED_STREAM + 12, pack('<I', 0xdead7001))
    cpu.mem_write(HEAP_BLOCK, bytes([0xa5]) * (8 + RECORD_SIZE))
    for address in range(first, end, RECORD_SIZE):
        cpu.mem_write(address, bytes([0xa5]) * RECORD_SIZE)
    if free_slot:
        cpu.mem_write(first + RECORD_SIZE + 12, b'\x00')

    event_log = []
    malloc = FUNCTION_ADDRESSES['malloc_']
    memset = FUNCTION_ADDRESSES['memset_']
    errno = FUNCTION_ADDRESSES['set_errno_']

    def stub(engine, address, _size, _data):
        eax = engine.reg_read(UC_X86_REG_EAX)
        if address == malloc:
            event_log.append(('malloc', eax))
            engine.reg_write(UC_X86_REG_EAX, 0 if allocation_failed else HEAP_BLOCK)
        elif address == memset:
            length = engine.reg_read(UC_X86_REG_EBX)
            assert engine.reg_read(UC_X86_REG_EDX) == 0
            event_log.append(('memset', eax, length))
            engine.mem_write(eax, bytes(length))
        else:
            event_log.append(('errno', eax))

    for address in (malloc, memset, errno):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, stub, begin=address, end=address)
    for index, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12340000 + index)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', RETURN))
    cpu.emu_start(LEAVES['allocate_stream_'][0] - 0x25600, RETURN, count=512)
    assert cpu.reg_read(UC_X86_REG_EIP) == RETURN
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x12340000 + i for i, reg in enumerate(SAVED))

    def pointer(address):
        return unpack('<I', cpu.mem_read(address, 4))[0]

    assert pointer(free_list) == (NEXT_LINK if recycled else 0)
    expected_calls = [] if recycled else [('malloc', 8 if free_slot else 34)]
    if allocation_failed:
        assert cpu.reg_read(UC_X86_REG_EAX) == 0
        assert pointer(open_list) == OPENLIST
        assert event_log == expected_calls + [('errno', 5)]
        return

    stream = RECYCLED_STREAM if recycled else (first + RECORD_SIZE if free_slot else HEAP_BLOCK + 8)
    link = FREELIST if recycled else HEAP_BLOCK
    flags = 3 if free_slot else 0x4003
    assert cpu.reg_read(UC_X86_REG_EAX) == stream
    assert pointer(open_list) == link
    assert pointer(link) == OPENLIST
    assert pointer(link + 4) == stream
    assert cpu.mem_read(stream, RECORD_SIZE) == bytes(12) + pack('<I', flags) + bytes(10)
    assert event_log == expected_calls + [('memset', stream, RECORD_SIZE)]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    memory = image(parser.parse_args().executable.read_bytes())
    exercise(memory, recycled=True, free_slot=False, allocation_failed=False)
    for free_slot in (False, True):
        for failed in (False, True):
            exercise(memory, recycled=False, free_slot=free_slot, allocation_failed=failed)
    print('PASS: five runtime stream allocation scenarios')
