"""Check save-slot name editing against both the linked executable and Watcom C."""
import argparse
from pathlib import Path
from struct import pack, unpack

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

ENTRY, SIZE, DATA_BASE = 0x39890, 370, 0x80000
COPY, FILL, FORMAT, TRIM = 0x60333, 0x61350, 0x601f3, 0x383a0
RESET, INPUT, DRAW, UPPER = 0x36246, 0x3625c, 0x39511, 0x62dce
STACK, STOP, TITLE = 0x3f0000, 0x3ff000, 0x320000
ROW, TEXT, SLOT = 0x310000, 0x310100, 3
OFFSETS = {
    '_save_slot_name_format': 0xd13, '_save_name_key_ascii': 0x3d04,
    '_save_slot_menu_rows': 0x173fc0, '_editing_save_slot': 0x1740c8,
    '_editing_save_slot_name': 0x1314e,
}
FUNCTIONS = {
    'strcpy_': COPY, 'memset_': FILL, 'sprintf_': FORMAT, 'trim_and_uppercase_': TRIM,
    'presentation_reset_': RESET, 'presentation_input_': INPUT, 'draw_menu_frame_': DRAW,
    'toupper_': UPPER,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
CHARACTERS = {2: b'a', 0x20: b'd', 0x21: b'f', 0x81: b'z'}
ORIGINAL_NAME = b'Old slot 4'
SAVED = {
    register: 0x13570000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI,
                                      UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def exercise(body, keys):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    events = []
    pending = iter(keys)

    def string(address):
        return bytes(cpu.mem_read(address, 64)).split(b'\0', 1)[0]

    def write_string(address, value):
        cpu.mem_write(address, value + b'\0')

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx, esp = (machine.reg_read(register) for register in
                                   (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX,
                                    UC_X86_REG_ECX, UC_X86_REG_ESP))
        editing = machine.mem_read(DATA['_editing_save_slot_name'], 1)[0]
        if address == COPY:
            source = string(edx)
            write_string(eax, source)
            if eax == TEXT:
                events.append(('restore', source))
        elif address == TRIM:
            assert string(eax) == ORIGINAL_NAME
            write_string(eax, ORIGINAL_NAME.upper())
        elif address == FILL:
            assert edx == 0 and ebx == 17
            machine.mem_write(eax, b'\0' * ebx)
        elif address == FORMAT:
            destination, fmt, source = unpack('<iii', machine.mem_read(esp + 4, 12))
            assert destination == TEXT and fmt == DATA['_save_slot_name_format']
            assert string(fmt) == b'%-16s'
            new = string(source).ljust(16)
            write_string(destination, new)
            events.append(('format', new))
            machine.reg_write(UC_X86_REG_EAX, len(new))
        elif address == RESET:
            assert not editing
            events.append(('reset',))
        elif address == DRAW:
            assert editing == 1
            assert (eax, edx, ebx, ecx) == (SLOT, 10, 0xfffffffe, TITLE)
            assert unpack('<I', machine.mem_read(esp + 4, 4))[0] == DATA['_save_slot_menu_rows']
            events.append(('draw', string(TEXT)))
            for register in (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX):
                machine.reg_write(register, 0xbcde5678)
        elif address == INPUT:
            assert editing == 0
            machine.reg_write(UC_X86_REG_EAX, next(pending))
        elif address == UPPER:
            assert 1 <= eax <= 255
            machine.reg_write(UC_X86_REG_EAX, bytes([eax]).upper()[0])

    for address in FUNCTIONS.values():
        cpu.mem_write(address, b'\xc2\x04\x00' if address == DRAW else b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.mem_write(DATA['_save_slot_menu_rows'] + 4 * SLOT, pack('<I', ROW))
    cpu.mem_write(ROW + 3, pack('<I', TEXT))
    cpu.mem_write(DATA['_editing_save_slot'], pack('<I', SLOT))
    write_string(TEXT, ORIGINAL_NAME)
    write_string(DATA['_save_slot_name_format'], b'%-16s')
    for key, char in CHARACTERS.items():
        cpu.mem_write(DATA['_save_name_key_ascii'] + key, char)
    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_EAX, 0x5555fffe)
    cpu.reg_write(UC_X86_REG_EDX, TITLE)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=7000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    assert cpu.mem_read(DATA['_editing_save_slot_name'], 1)[0] == 0
    assert next(pending, None) is None
    return cpu.reg_read(UC_X86_REG_EAX), string(TEXT), events


def expected(keys):
    text = b''
    shown = text.ljust(16)
    events = [('format', shown), ('reset',)]
    for key in keys:
        events.append(('draw', shown))
        if key == 0:
            continue
        if key == 1:
            events.append(('restore', ORIGINAL_NAME))
            return 0, ORIGINAL_NAME, events
        if key == 0x1c:
            if not text:
                shown = ORIGINAL_NAME.ljust(16)
                events.append(('format', shown))
            return 1, shown, events
        if key == 0xe:
            text = text[:-1]
        elif key in CHARACTERS:
            text = (text + CHARACTERS[key].upper())[:16]
        shown = text.ljust(16)
        events.append(('format', shown))
    raise AssertionError('Unterminated key sequence')


def check(executable, obj):
    name = 'edit_save_slot_name_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 17
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]
    cases = (
        (1,), (0x1c,), (0, 0, 0xe, 0x44, 0x1c),
        (2, 0x20, 0x1c), (2, 0x20, 0xe, 0x21, 0x1c), (2, 0x20, 0xe, 1),
        (2,) * 16 + (0x20, 0x81, 0x1c), (2,) * 16 + (0x20, 0xe, 0x81, 0x1c),
        (0x81, 0xe, 0xe, 0x1c),
    )
    for keys in cases:
        for body in (original, code):
            result = exercise(body, keys)
            assert result == expected(keys), (keys, result, expected(keys))
    print(f'PASS: 370 exact bytes, 17 LE pointers, {len(cases)} save editor scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
