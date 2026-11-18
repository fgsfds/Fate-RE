"""Check VGA, CGA, and Hercules monochrome pixel address and mask setup."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import UC_ARCH_X86, UC_MODE_32, Uc
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

STACK, STOP = 0x3ff000, 0x3fff00
SELECTOR, BASE = 0x1828, 0x28000


def address(name):
    return DS + DATA_OFFSETS['_' + name]


def rotate_byte(value, count):
    return ((value >> count) | (value << (8 - count))) & 0xff


def exercise(memory, code, entry, mode):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, code)
    cpu.mem_write(address('current_buffer_selector'), pack('<H', SELECTOR))
    cpu.mem_write(address('current_buffer_offset'), pack('<I', BASE))
    cpu.mem_write(STACK, pack('<I', STOP))
    # All eight bit positions and all four Hercules banks; test page and column edges.
    cases = [(32 + bit, row, 0x81 + bit + row) for row in range(4) for bit in range(8)]
    if mode == 'hercules':
        cases.extend(((719, 347, 0xff), (0, 344, 0)))
    else:
        cases.extend(((639, 199, 0xff), (0, 198, 0)))
    for x, y, color in cases:
        cpu.mem_write(address('pixel_address'), bytes([0xcc]) * 12)
        for reg, value in ((UC_X86_REG_EAX, x), (UC_X86_REG_EDX, y),
                           (UC_X86_REG_EBX, color), (UC_X86_REG_ESP, STACK)):
            cpu.reg_write(reg, value)
        cpu.emu_start(entry, STOP, count=200)
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
        if mode == 'vga':
            row_offset = y * 80
        elif mode == 'cga':
            row_offset = (y // 2) * 80 + (y % 2) * 8192
        else:
            row_offset = (y // 4) * 90 + (y % 4) * 8192
        bit = x % 8
        expected = (BASE + row_offset + x // 8, SELECTOR,
                    rotate_byte(color, bit + 1), (rotate_byte(0xfe, bit + 1) << 8) | 1, bit)
        actual = unpack('<I4H', cpu.mem_read(address('pixel_address'), 12))
        assert actual == expected, (mode, x, y, color, actual, expected)
    return len(cases)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    cases = sites = total = 0
    for mode, symbol in (('vga', 'address_vga_mono_pixel_'), ('cga', 'address_cga_mono_pixel_'),
                         ('hercules', 'address_hercules_pixel_')):
        raw, length = LEAVES[symbol]
        entry = raw - 0x25600
        code, refs = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES)
        assert len(code) == length and code == exe[raw:raw + length], symbol
        verify_leaf_relocations(code, refs, pointers, entry)
        restored, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
        n = exercise(memory, memory[entry:entry + length], entry, mode)
        assert exercise(memory, restored, entry, mode) == n
        cases += n
        sites += len(refs)
        total += length
    print(f'PASS: {total} exact bytes, {sites} LE relocations, {cases} original and {cases} restored pixel cases')


if __name__ == '__main__':
    main()
