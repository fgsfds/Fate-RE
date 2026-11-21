"""Verify the driver parameter stores and sign extension after the far call."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32, Uc
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

PARAMS = ('ax', 'cl', 'ch', 'dx')
STACK, STOP = 0x3ff000, 0x3fff00


def exercise(memory, entry, body):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.mem_write(STACK + 4, b'\x00' * 0x40)
    cpu.reg_write(UC_X86_REG_ESP, STACK)

    def hook(uc, address, size, user_data):
        if uc.mem_read(address, 3) == b'\xff\x5d\x08':  # call far [ebp + 8]
            uc.reg_write(UC_X86_REG_EAX, 0x1234)
            uc.reg_write(UC_X86_REG_ECX, 0x807f)       # CH = 0x80, CL = 0x7f
            uc.reg_write(UC_X86_REG_EDX, 0x5678)
            uc.reg_write(UC_X86_REG_EIP, address + 3)

    cpu.hook_add(UC_HOOK_CODE, hook)
    try:
        cpu.emu_start(entry, STOP, count=200)
    except Exception:
        pass  # the ret reaches a garbage address after Unicorn's push es quirk

    def word(name):
        return unpack('<H', cpu.mem_read(DS + DATA_OFFSETS['_detector_parameter_' + name], 2))[0]

    assert word('ax') == 0x1234
    assert word('ch') == 0xff80          # sign-extended CH = 0x80
    assert word('cl') == 0x007f          # sign-extended CL = 0x7f
    assert word('dx') == 0x5678


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    symbol = 'read_driver_parameters_'
    raw, size = LEAVES[symbol]
    entry = raw - 0x25600
    code, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES)
    assert len(code) == size and code == exe[raw:raw + size], symbol
    verify_leaf_relocations(code, refs, pointers, entry)
    patched, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
    for code2 in (memory[entry:entry + size], patched):
        exercise(memory, entry, code2)
    print('PASS: 68 exact bytes, 4 LE relocations, 1 original and 1 restored parameter read case')


if __name__ == '__main__':
    main()
