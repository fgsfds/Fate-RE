"""Exercise menu font selection, glyph spacing, and shadow drawing."""

import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations


SYMBOL = 'draw_menu_text_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
TEXT, STACK, STOP = 0x310000, 0x3ff000, 0x3fff00
SAVED = (UC_X86_REG_EBP, UC_X86_REG_ESI, UC_X86_REG_EDI)
REGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
X, Y, WIDTH, HEIGHT = 80, 24, 640, 480
ZOOMS, SPACING = (0x7000, 0x5400), (8, 11)
GLYPHS = {ord('A'): 123, ord('B'): 0, ord('C'): 456}
STUBS = {FUNCTION_ADDRESSES[name]: (name, width) for name, width in
         (('strlen_', 0), ('menu_glyph_tile_', 0), ('draw_screen_text_', 8), ('rotatesprite_', 32))}


def exercise(memory, code, font, shade, text, expected):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(TEXT, text + b'\0')

    def data(name, value, delta=0):
        cpu.mem_write(DS + DATA_OFFSETS[name] + delta, value)

    data('_presentation_width', pack('<I', WIDTH))
    data('_presentation_height', pack('<I', HEIGHT))
    data('_menu_font_zoom', pack('<II', *ZOOMS))
    data('_small_text_character_widths', pack('<II', *SPACING))
    data('_character_types', b'\x00' * 256)
    data('_character_types', b'\x40', ord('A') + 1)
    data('_character_types', b'\x20', ord('7') + 1)
    calls = []

    def hook(engine, address, _size, _data):
        kind, extra = STUBS[address]
        eax, edx, ebx, ecx = (engine.reg_read(reg) for reg in REGS)
        if kind == 'strlen_':
            assert eax == TEXT
            engine.reg_write(UC_X86_REG_EAX, len(text))
        elif kind == 'menu_glyph_tile_':
            calls.append(('lookup', eax & 255))
            engine.reg_write(UC_X86_REG_EAX, GLYPHS[eax & 255])
        else:
            sp = engine.reg_read(UC_X86_REG_ESP)
            args = unpack(f'<{extra // 4}I', engine.mem_read(sp + 4, extra))
            if kind == 'draw_screen_text_':
                calls.append(('shadow', eax, edx, ebx, ecx, args))
            else:
                calls.append(('glyph', eax, edx, ebx, ecx, args))

    for address, (_, width) in STUBS.items():
        cpu.mem_write(address, b'\xc2' + pack('<H', width) if width else b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    for reg, value in zip(REGS, (X, Y, shade & 0xffffffff, TEXT)):
        cpu.reg_write(reg, value)
    for index, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0x12000000 + index)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<II', STOP, font))
    cpu.emu_start(ENTRY, STOP, count=2000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 8
    assert all(cpu.reg_read(reg) == 0x12000000 + i for i, reg in enumerate(SAVED))
    assert calls == expected, (calls, expected)


def glyph(font, position, tile, shade):
    return ('glyph', position << 16, Y << 16, ZOOMS[font], 0,
            (tile, shade & 0xffffffff, 0, 0x12, 0, 0, WIDTH - 1, HEIGHT - 1))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    executable, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(executable)
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and len(refs) == 6 and code == executable[RAW:RAW + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    loaded = {name: offset + DS for name, offset in DATA_OFFSETS.items()}
    restored, _ = bind_leaf_details(obj, SYMBOL, loaded, address=ENTRY, functions=FUNCTION_ADDRESSES)
    for body in (memory[ENTRY:ENTRY + SIZE], restored):
        exercise(memory, body, 0, -6, b'ABC', [('lookup', ord('A')), glyph(0, X, 123, -6),
                 ('lookup', ord('B')), ('lookup', ord('C')), glyph(0, X + 2 * SPACING[0], 456, -6)])
        exercise(memory, body, 1, 4, b'A!7', [glyph(1, X, ord('A') + 0x7c4, 4),
                 glyph(1, X + 2 * SPACING[1], ord('7') + 0x7c9, 4)])
        for shade in (-1, 0):
            exercise(memory, body, 2, shade, b'ABC',
                     [('shadow', X, Y, 0x60, 0xffffffff, (TEXT, 0)),
                      ('shadow', X - 1, Y - 1, 0x70, 0 if shade == -1 else 0xffffffff, (TEXT, 0))])
    print('PASS: 301 bytes, six LE relocations, four menu text scenarios for original and C')
