"""Verify key-binding rows, input wait, rejection, and writeback."""
import argparse
from pathlib import Path
from struct import pack, unpack_from

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'run_key_binding_menu_'
ENTRY = FUNCTION_ADDRESSES[SYMBOL]
STACK, STOP = 0x3f0000, 0x3ff000
ROWS, SCAN_NAMES, ACTION_NAMES = 0x200000, 0x201000, 0x202000
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def scenario(code, menus, keys, results):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x400000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for index, register in enumerate(SAVED):
        cpu.reg_write(register, 0x21000000 + index)
    data = DATA_OFFSETS
    initial = bytes(range(2, 27))
    cpu.mem_write(data['_key_forward'], initial)
    for index in range(25):
        cpu.mem_write(data['_key_entries'] + index * 4, pack('<I', ROWS + index * 16))
        cpu.mem_write(data['_key_action_labels'] + index * 8, pack('<I', ACTION_NAMES + index * 16))
    for index in range(256):
        cpu.mem_write(data['_key_scan_names'] + index * 4, pack('<I', SCAN_NAMES + index * 4))
    selected = data['_key_menu_selection']
    formats, frames, sounds, checked = [], [], [], []
    menu_input, key_input, validity = iter(menus), iter(keys), iter(results)

    def format_row(emu, address, size, user_data):
        args = unpack_from('<IIII', emu.mem_read(emu.reg_read(UC_X86_REG_ESP) + 4, 16))
        formats.append(args)

    def select_row(emu, address, size, user_data):
        index = next(menu_input)
        assert emu.reg_read(UC_X86_REG_EAX) == selected
        assert emu.reg_read(UC_X86_REG_ECX) == data['_key_menu_title']
        emu.mem_write(selected, pack('<I', max(index, 0)))
        emu.reg_write(UC_X86_REG_EAX, int(index >= 0))

    def read_key(emu, address, size, user_data):
        emu.reg_write(UC_X86_REG_EAX, next(key_input))

    def validate(emu, address, size, user_data):
        checked.append((emu.reg_read(UC_X86_REG_EAX), emu.reg_read(UC_X86_REG_EDX)))
        emu.reg_write(UC_X86_REG_EAX, next(validity) & 0xffffffff)

    def draw(emu, address, size, user_data):
        frames.append(emu.reg_read(UC_X86_REG_ECX))

    def sound(emu, address, size, user_data):
        sounds.append(emu.reg_read(UC_X86_REG_EAX))

    for name, callback, pops in (
        ('format_string_', format_row, 0), ('run_menu_loop_', select_row, 4),
        ('presentation_input_', read_key, 0), ('validate_key_binding_', validate, 0),
        ('draw_menu_frame_', draw, 4), ('play_sound_', sound, 0),
    ):
        address = FUNCTION_ADDRESSES[name]
        cpu.mem_write(address, bytes((0xc2, pops, 0)) if pops else bytes((0xc3,)))
        cpu.hook_add(UC_HOOK_CODE, callback, begin=address, end=address)

    cpu.emu_start(ENTRY, STOP, count=4000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.reg_read(UC_X86_REG_EAX) == 0
    assert tuple(cpu.reg_read(reg) for reg in SAVED) == tuple(0x21000000 + i for i in range(6))
    assert formats[:25] == [
        (data['_key_menu_rows'] + 30 * i, data['_key_menu_row_format'],
         ACTION_NAMES + 16 * i, SCAN_NAMES + scan * 4) for i, scan in enumerate(initial)
    ]
    return bytes(cpu.mem_read(data['_key_forward'], 25)), formats[25:], frames, sounds, checked


def check(executable, obj):
    raw, size = LEAVES[SYMBOL]
    expected = executable[raw:raw + size]
    restored, bindings = bind_leaf_details(
        obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    assert restored == expected
    verify_leaf_relocations(restored, bindings, read_le_fixups(executable)['pointers'], ENTRY)
    data = DATA_OFFSETS
    initial = bytes(range(2, 27))
    for code in (expected, restored):
        assert scenario(code, [-1], [], []) == (initial, [], [], [], [])
        keys, formats, frames, sounds, checked = scenario(code, [4, -1], [0, 42], [1])
        assert keys == initial[:4] + bytes((42,)) + initial[5:]
        assert [args[3] for args in formats] == [data['_key_blank_name'], SCAN_NAMES + 42 * 4]
        assert frames == [data['_key_menu_prompt']] and not sounds and checked == [(42, 4)]
        keys, formats, frames, sounds, checked = scenario(code, [4, -1], [43], [-2])
        assert keys == initial
        assert [args[3] for args in formats] == [data['_key_blank_name'], SCAN_NAMES + 6 * 4]
        assert frames == [data['_key_menu_rejected']] and sounds == [0x9d] and checked == [(43, 4)]
    print(f'PASS: {size} exact bytes, {len(bindings)} LE relocations, 3 original/restored key-binding cases')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())


if __name__ == '__main__':
    main()
