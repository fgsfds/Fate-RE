"""Verify the Build bitmap text renderer and exercise both video paths.

Verify the Watcom routine and LE data relocations against FATE.EXE, then use
guarded buffers and port hooks to compare original and restored pixel writes
against a bitmap text model.
"""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_INSN, UC_HOOK_MEM_WRITE
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_ESP, UC_X86_REG_EBP, UC_X86_REG_EIP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'draw_screen_text_'
ENTRY, STACK, STOP = 0x560de, 0x3ff000, 0x3fff00
TAIL = FUNCTION_ADDRESSES['finish_screen_text_']
TEXT, LINEAR, PLANAR = 0x3a0010, 0x3c2010, 0x3b1010
BUFFER_SIZE = 8192
DATA = {
    name: DS + DATA_OFFSETS['_' + name]
    for name in ('chainstat', 'chainplace', 'draw_page_address', 'ylookup', 'textfont',
                 'smalltextfont', 'pow2char', 'pow2long')
}
SAVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
MASKS = bytes(1 << bit for bit in range(8))


def font_data(salt):
    glyphs = []
    for glyph in range(256):
        glyphs.extend(((glyph * 37 + (glyph >> 2) * row + row * 29) ^ salt) & 255
                      for row in range(8))
    return bytes(glyphs)


FONTS = (font_data(0xa1), font_data(0x2c))
CASES = (
    (0, 0, b'', 8, 2, 64, 23, 90),
    (1, 0, b'', 8, 2, 64, 23, -1),
    (0, 0, b'A', 0, 3, 80, 51, 0),
    (0, 0, b'AbZ', 3, 1, 80, 51, -1),
    (0, 1, b'Ll', 13, 2, 46, 23, 244),
    (0, 1, b'\xffQ', 1, 0, 72, 239, 0x8000),
    (0, 256, b'\x90!', 9, 5, 67, 17, 0x10001),
    (1, 0, b'Az', 7, 5, 80, 1, 211),
    (1, 0, b'\x81q', 3, 2, 45, 15, -1),
    (1, 1, b'ABC', 4, 3, 72, 9, 134),
    (255, 1, b'8Z', 1, 2, 64, 197, 0x8000),
    (2, 256, b'\xc0Z', 19, 1, 33, 31, 0x10001),
)


def model(planar, small, text, x, y, stride, foreground, background):
    ports = [(0x3c4, 1, 2)] if planar else []
    writes = []
    small &= 255
    width = 4 if small else 8
    font = FONTS[bool(small)]
    opaque = (background & 0x8000) == 0
    for index, character in enumerate(text):
        for row in range(7, -1, -1):
            bits = font[character * 8 + row]
            for column in range(width - 1, -1, -1):
                shift = 7 - small - column
                set_pixel = bits & (1 << shift)
                if not set_pixel and not opaque:
                    continue
                color = (foreground if set_pixel else background) & 255
                pixel = x + index * width + column - small
                row_start = (y + row) * stride
                if planar:
                    ports.append((0x3c5, 1, 1 << (pixel & 3)))
                    writes.append((PLANAR + row_start + (pixel >> 2), 1, color))
                else:
                    writes.append((LINEAR + row_start + pixel, 1, color))
    return ports, writes


def check_case(code, tail, planar, small, text, x, y, stride, foreground, background):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(ENTRY, code)
    machine.mem_write(TAIL, tail)
    machine.mem_write(TEXT - 4, b'left' + text + b'\0edge')
    machine.mem_write(DATA['textfont'], FONTS[0])
    machine.mem_write(DATA['smalltextfont'], FONTS[1])
    machine.mem_write(DATA['chainstat'], bytes([planar]))
    machine.mem_write(DATA['chainplace'], pack('<I', PLANAR))
    machine.mem_write(DATA['draw_page_address'], pack('<I', LINEAR))
    machine.mem_write(DATA['ylookup'], pack('<32i', *(row * stride for row in range(32))))
    machine.mem_write(DATA['pow2char'], MASKS)
    machine.mem_write(DATA['pow2long'], pack('<8I', *MASKS))
    expected_buffers = {address: bytearray(b'\xac' * BUFFER_SIZE) for address in (LINEAR, PLANAR)}
    for address, contents in expected_buffers.items():
        machine.mem_write(address - 4, b'left' + contents + b'edge')

    ports, writes = [], []

    def port_write(_machine, port, size, value, _data):
        ports.append((port, size, value))

    def pixel_write(_machine, _access, address, size, value, _data):
        if not STACK - 48 <= address < STACK:
            writes.append((address, size, value))

    machine.hook_add(UC_HOOK_INSN, port_write, None, 1, 0, UC_X86_INS_OUT)
    machine.hook_add(UC_HOOK_MEM_WRITE, pixel_write)
    for index, reg in enumerate(SAVED):
        machine.reg_write(reg, 0x123400 + index)
    for reg, value in zip(ARGS, (x, y, foreground, background)):
        machine.reg_write(reg, value & 0xffffffff)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<IIi', STOP, TEXT, small))
    machine.emu_start(ENTRY, STOP, count=24000)

    expected_ports, expected_writes = model(planar, small, text, x, y, stride, foreground, background)
    assert ports == expected_ports
    assert writes == expected_writes
    start = PLANAR if planar else LINEAR
    for address, _, pixel in expected_writes:
        expected_buffers[start][address - start] = pixel
    for address, contents in expected_buffers.items():
        assert machine.mem_read(address - 4, BUFFER_SIZE + 8) == b'left' + contents + b'edge'
    assert machine.mem_read(TEXT - 4, len(text) + 9) == b'left' + text + b'\0edge'
    assert machine.mem_read(DATA['textfont'], len(FONTS[0])) == FONTS[0]
    assert machine.mem_read(DATA['smalltextfont'], len(FONTS[1])) == FONTS[1]
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK + 12
    assert [machine.reg_read(reg) for reg in SAVED] == [0x123400 + i for i in range(len(SAVED))]


def check(executable, obj):
    original = image(executable)
    raw, size = LEAVES[SYMBOL]
    assert raw - 0x25600 == ENTRY
    code, bindings = bind_leaf_details(
        obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    assert len(code) == size and code == executable[raw:raw + size]
    verify_leaf_relocations(code, bindings, read_le_fixups(executable)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, SYMBOL, {'_' + name: address for name, address in DATA.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    for label, source in (('original', original[ENTRY:ENTRY + size]), ('restored', restored)):
        for case in CASES:
            try:
                check_case(source, original[TAIL:TAIL + 8], *case)
            except AssertionError as error:
                raise AssertionError(f'{label} text case {case} failed') from error
    return size, len(bindings), len(CASES)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing draw_screen_text_')
    args = parser.parse_args()
    size, relocations, cases = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {size} bytes, {relocations} LE relocations, {cases} original and {cases} restored text cases')
