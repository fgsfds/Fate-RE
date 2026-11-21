"""Execute the exact square-root initializer with its verified shared return."""
import argparse
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_MEM_WRITE
from unicorn.x86_const import (
    UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI,
    UC_X86_REG_EDI, UC_X86_REG_EBP, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_ksqrt import table_value
from le_fixups import read_le_fixups
from verify_assembly_suite import verify
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

ENTRY, TAIL, OWNER = 0x4caaa, 0x4abbf, 0x4aa28
TABLE, STACK, STOP = 0x25fa60, 0x3ff000, 0x3fff00


def verified_tail(exe, directory, c_inventory, owner):
    verify(exe, directory, c_inventory)
    owner_code, refs = bind_leaf_details(
        owner, 'transmaskvline_', DATA_OFFSETS, address=OWNER,
        functions=FUNCTION_ADDRESSES,
    )
    if len(owner_code) != 413 or owner_code != exe[0x70028:0x701c5]:
        raise ValueError('Shared return owner differs')
    verify_leaf_relocations(owner_code, refs, read_le_fixups(exe)['pointers'], OWNER)

    return owner_code[TAIL-OWNER:]


def verified_code(exe, directory, c_inventory, owner, initializer):
    tail = verified_tail(exe, directory, c_inventory, owner)
    symbol = 'initksqrt_'
    raw, size = LEAVES[symbol]
    body, refs = bind_leaf_details(initializer, symbol, DATA_OFFSETS, address=ENTRY,
                                   functions=FUNCTION_ADDRESSES)
    if body != exe[raw:raw+size]:
        raise ValueError('Square-root initializer differs')
    verify_leaf_relocations(body, refs, read_le_fixups(exe)['pointers'], ENTRY)
    code, _ = bind_leaf_details(initializer, symbol, {'_sqrtable': TABLE}, address=ENTRY,
                                functions=FUNCTION_ADDRESSES)
    return code, tail


def check(exe, directory, c_inventory, owner, initializer):
    code, tail = verified_code(exe, directory, c_inventory, owner, initializer)
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(ENTRY, code)
    machine.mem_write(TAIL, tail)
    machine.mem_write(TABLE-16, b'\xa5'*16 + b'\xcc'*4096 + b'\x5a'*16)
    machine.mem_write(STACK, struct.pack('<I', STOP))
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    for index, reg in enumerate(saved):
        machine.reg_write(reg, 0x13570000+index)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    writes = []

    def record_write(_, access, address, size, value, data):
        if not STACK-20 <= address < STACK:
            writes.append((address, size, value))

    machine.hook_add(UC_HOOK_MEM_WRITE, record_write)
    machine.emu_start(ENTRY, STOP, count=500000)
    expected = [table_value(index) for index in range(2048)]
    assert writes == [(TABLE+2*index, 2, value) for index, value in enumerate(expected)]
    assert machine.mem_read(TABLE-16, 4128) == (
        b'\xa5'*16 + struct.pack('<2048H', *expected) + b'\x5a'*16
    )
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK+4
    assert [machine.reg_read(reg) for reg in saved] == [0x13570000+i for i in range(len(saved))]


if __name__ == '__main__':
    import json
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('executable', 'assembly_directory', 'c_inventory', 'tail_owner'):
        parser.add_argument(name, type=Path)
    parser.add_argument('--initializer', type=Path)
    args = parser.parse_args()
    initializer = args.initializer or args.tail_owner.with_name('sqrtinit.obj')
    check(args.executable.read_bytes(), args.assembly_directory,
          json.loads(args.c_inventory.read_text(encoding='utf-8')), args.tail_owner.read_bytes(),
          initializer.read_bytes())
    print('PASS: 2,048 square-root entries, guards, registers and shared return')
