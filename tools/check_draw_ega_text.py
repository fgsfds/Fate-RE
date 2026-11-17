"""Verify EGA bitmap text bytes and exercise the controller write sequence.

The same guarded video buffer and port model run the original and compiled
routines through aligned and split-byte rendering for both font sizes.
"""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_INSN, UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE
from unicorn.x86_const import (
    UC_X86_INS_IN, UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_ESP, UC_X86_REG_EBP, UC_X86_REG_EIP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'draw_ega_text_'
ENTRY, STACK, STOP = 0x55e2c, 0x3ff000, 0x3fff00
TAIL = FUNCTION_ADDRESSES['finish_ega_text_']
TEXT, VIDEO, VIDEO_SIZE = 0x3a0010, 0xa0000, 4096
DATA = {name: DS + DATA_OFFSETS['_' + name] for name in ('pow2char', 'textfont', 'smalltextfont')}
SAVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)


def make_font(salt):
    return bytes(((glyph * 29 + (glyph >> 2) * row + row * 17) ^ salt) & 255
                 for glyph in range(256) for row in range(8))


FONTS = (make_font(0xa1), make_font(0x2c))
CASES = (
    (0, b'', 8, 2, 23, 90, 0x85),
    (1, b'', 8, 2, 23, -1, 0x4f),
    (0, b'A', 0, 3, 51, 0, 0x38),
    (0, b'AbZ', 8, 1, 51, -1, 0x38),
    (0, b'zZ', 1, 2, 52, 14, 0x43),
    (0, b'Zz', 7, 3, 53, -1, 0x43),
    (1, b'LlM', 8, 2, 23, 244, 0xd9),
    (1, b'\xffQ', 1, 0, 239, 0x8000, 0x82),
    (1, b'\x90!x', 7, 5, 17, 0x10001, 0x9e),
    (2, b'Az', 8, 5, 1, 211, 0xc7),
    (256, b'\x81q', 3, 2, 15, -1, 0x00),
    (257, b'8Z', 9, 2, 197, 5, 0xff),
)


def model(small, text, x, y, foreground, background, mode):
    def port(selector, value):
        return ('out', selector, 1, value & 255)

    entered = (mode & 0xfc) | 2
    events = [port(0x3ce, 5), ('in', 0x3cf, 1, mode), port(0x3cf, entered), port(0x3ce, 8)]
    is_small = (small & 255) == 1
    width = 4 if is_small else 8
    opaque = (background & 0x8000) == 0
    font = FONTS[is_small]

    def write_pixel(address, *masks, color):
        events.extend(port(0x3cf, mask) for mask in masks)
        events.extend((('read', address, 1), ('write', address, 1, color & 255)))

    for index, character in enumerate(text):
        pixel = x + width * index
        alignment = pixel & 7
        left_mask = 0xff >> alignment
        right_mask = 0xff ^ left_mask
        for row in range(8):
            address = VIDEO + (y + row) * 80 + (pixel >> 3)
            glyph = font[character * 8 + row]
            if not alignment:
                if opaque:
                    masks = (0xff, 0x7c) if is_small else (0xff,)
                    write_pixel(address, *masks, color=background)
                masks = (glyph, glyph & 0x7c) if is_small else (glyph,)
                write_pixel(address, *masks, color=foreground)
            else:
                if opaque:
                    bg_left = 0x7c >> alignment if is_small else left_mask
                    bg_right = 0x7c << (8 - alignment) if is_small else right_mask
                    write_pixel(address, bg_left, color=background)
                    write_pixel(address + 1, bg_right, color=background)
                if is_small:
                    glyph &= 0x7c
                write_pixel(address, (glyph >> alignment) & left_mask, color=foreground)
                write_pixel(address + 1, (glyph << (8 - alignment)) & right_mask, color=foreground)

    events.extend((port(0x3ce, 5), ('in', 0x3cf, 1, entered), port(0x3cf, mode & 0xfc)))
    return events


def check_case(code, tail, small, text, x, y, foreground, background, mode):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(ENTRY, code)
    machine.mem_write(TAIL, tail)
    machine.mem_write(TEXT - 4, b'left' + text + b'\0edge')
    machine.mem_write(DATA['textfont'], FONTS[0])
    machine.mem_write(DATA['smalltextfont'], FONTS[1])
    machine.mem_write(DATA['pow2char'], bytes(1 << i for i in range(8)) + b'\0')
    expected_buffer = bytearray(b'\xac' * VIDEO_SIZE)
    machine.mem_write(VIDEO - 4, b'left' + expected_buffer + b'edge')

    events = []
    controller_index = None
    controller_mode = mode

    def port_write(_machine, port, size, value, _data):
        nonlocal controller_index, controller_mode
        events.append(('out', port, size, value))
        if port == 0x3ce:
            controller_index = value
        elif port == 0x3cf and controller_index == 5:
            controller_mode = value

    def port_read(_machine, port, size, _data):
        assert port == 0x3cf and controller_index == 5
        events.append(('in', port, size, controller_mode))
        return controller_mode

    def video_read(_machine, _access, address, size, _value, _data):
        events.append(('read', address, size))

    def pixel_write(_machine, _access, address, size, value, _data):
        if not STACK - 56 <= address < STACK:
            events.append(('write', address, size, value))

    machine.hook_add(UC_HOOK_INSN, port_write, None, 1, 0, UC_X86_INS_OUT)
    machine.hook_add(UC_HOOK_INSN, port_read, None, 1, 0, UC_X86_INS_IN)
    machine.hook_add(UC_HOOK_MEM_READ, video_read, None, VIDEO - 4, VIDEO + VIDEO_SIZE + 3)
    machine.hook_add(UC_HOOK_MEM_WRITE, pixel_write)
    for index, reg in enumerate(SAVED):
        machine.reg_write(reg, 0x123400 + index)
    for reg, value in zip(ARGS, (x, y, foreground, background)):
        machine.reg_write(reg, value & 0xffffffff)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<IIi', STOP, TEXT, small))
    machine.emu_start(ENTRY, STOP, count=24000)

    expected_events = model(small, text, x, y, foreground, background, mode)
    assert events == expected_events
    for kind, address, *args in expected_events:
        if kind == 'write':
            expected_buffer[address - VIDEO] = args[1]
    assert machine.mem_read(VIDEO - 4, VIDEO_SIZE + 8) == b'left' + expected_buffer + b'edge'
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
                raise AssertionError(f'{label} EGA text case {case} failed') from error
    return size, len(bindings), len(CASES)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing draw_ega_text_')
    args = parser.parse_args()
    size, relocations, cases = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {size} bytes, {relocations} LE relocations, {cases} original and {cases} restored EGA text cases')
