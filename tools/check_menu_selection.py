"""Compare complete menu-selection C with the pinned original instructions."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import pointer_range, read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, RAW, SIZE, LE_SITES = 0x39235, 0x5e835, 595, 35
STACK, STOP, ROWS, STORAGE = 0x3ff000, 0x3fff00, 0x3a0000, 0x3a2000
DATA = DATA_OFFSETS
FUNCS = FUNCTION_ADDRESSES
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def exercise(memory, body, case):
    key, dx, dy, ax, ay, count, selected, mask, kind, value, limit = case
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def put(name, fmt, number):
        cpu.mem_write(DS + DATA['_' + name], pack('<' + fmt, number))

    for name, fmt, number in (
        ('menu_mouse_x', 'i', 999), ('menu_mouse_y', 'i', 999),
        ('mouse_dx', 'h', -7), ('mouse_dy', 'h', 8),
        ('menu_selection', 'i', selected), ('menu_entry_count', 'i', count),
        ('enabled_menu_entries', 'I', mask), ('menu_loop_state', 'i', 77),
        ('menu_selection_storage', 'I', STORAGE),
    ):
        put(name, fmt, number)
    cpu.mem_write(STORAGE, pack('<I', 0x76543210))
    rows = bytearray(b'\xb9' * (32 * 21))
    for index in range(32):
        row = memoryview(rows)[index * 21:(index + 1) * 21]
        row[1:3] = pack('<H', kind)
        row[7:15] = pack('<ii', value, limit)
    cpu.mem_write(ROWS, bytes(rows))
    cpu.mem_write(DS + DATA['_active_menu_entries'],
                  b''.join(pack('<I', ROWS + index * 21) for index in range(32)))
    trace = []

    def hook(engine, address, size, data):
        if address == FUNCS['presentation_input_']:
            trace.append(('input',))
            for name, fmt, number in (('mouse_dx', 'h', dx), ('mouse_dy', 'h', dy),
                                      ('menu_mouse_x', 'i', ax), ('menu_mouse_y', 'i', ay)):
                put(name, fmt, number)
            engine.reg_write(UC_X86_REG_EAX, key)
        elif address == FUNCS['play_sound_']:
            arguments = tuple(engine.reg_read(register) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
            assert arguments[0] in (2, 3, 4, 0x9c) and arguments[1:] == (0, 0, 0)
            trace.append(('sound', arguments))
            for register in (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX):
                engine.reg_write(register, 0xa5c3f17e)
        else:
            return
        sp = engine.reg_read(UC_X86_REG_ESP)
        target = unpack('<I', engine.mem_read(sp, 4))[0]
        engine.reg_write(UC_X86_REG_ESP, sp + 4)
        engine.reg_write(UC_X86_REG_EIP, target)

    cpu.hook_add(UC_HOOK_CODE, hook)
    for index, register in enumerate(SAVED):
        cpu.reg_write(register, 0xabcd1230 + index)
    sentinel = b'\x5a' * 16
    cpu.mem_write(STACK, pack('<I', STOP) + sentinel)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(ENTRY, STOP, count=3000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert bytes(cpu.mem_read(STACK + 4, 16)) == sentinel
    assert all(cpu.reg_read(register) == 0xabcd1230 + index
               for index, register in enumerate(SAVED))
    assert trace[0] == ('input',)
    return cpu.reg_read(UC_X86_REG_EAX), trace, bytes(cpu.mem_read(DS, len(memory) - DS - 0x10000))


def cases():
    base = (0, 0, 0, 0, 0, 4, 1, 0xb, 2, 2, 5)
    result = [(key,) + base[1:] for key in range(256)]
    result += [(0xabcd0048,) + base[1:], (0x87650001,) + base[1:]]
    for key, count in itertools.product((0x48, 0x50, 0xc8, 0xd0), (1, 2, 4, 32)):
        for selected in (0, count - 1):
            for mask in (1, 1 << (count - 1), (1 << count) - 1):
                result.append((key, 0, 0, 0, 0, count, selected, mask, 2, 2, 5))
    for key, kind, value in itertools.product((0x4b, 0x4d), (0, 1, 2, 3, 65535),
                                             (-2147483648, -1, 0, 1, 4, 5, 2147483647)):
        result.append((key, 0, 0, 0, 0, 4, 1, 0xb, kind, value, 5))
    for key, limit in itertools.product((0x4b, 0x4d), (-2147483648, 0, 2147483647)):
        result.append((key, 0, 0, 0, 0, 4, 1, 0xb, 2, 2, limit))
    for ax, ay in itertools.product((-101, -100, -99, 99, 100, 101),
                                    (-121, -120, -119, 119, 120, 121)):
        result.append((0x1c, 0, 0, ax, ay, 4, 1, 0xb, 2, 2, 5))
    for dx, dy, ax, ay in ((1, 1, 100, 120), (-1, -1, -100, -120),
                            (32767, -32768, 2147483647, -2147483648),
                            (-32768, 32767, -2147483648, 2147483647)):
        result.append((0, dx, dy, ax, ay, 4, 1, 0xb, 2, 2, 5))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    executable = args.executable.read_bytes()
    assert hashlib.sha256(executable).hexdigest() == TARGET_SHA256
    pointers = read_le_fixups(executable)['pointers']
    assert len(pointer_range(pointers, ENTRY, SIZE)) == LE_SITES
    obj = args.object.read_bytes()
    raw, bindings = bind_leaf_details(obj, 'update_menu_selection_', DATA, address=ENTRY, functions=FUNCS)
    assert len(raw) == SIZE and raw == executable[RAW:RAW + SIZE]
    verify_leaf_relocations(raw, bindings, pointers, ENTRY)
    body, _ = bind_leaf_details(obj, 'update_menu_selection_',
                               {name: DS + offset for name, offset in DATA.items()},
                               address=ENTRY, functions=FUNCS)
    memory = image(executable)
    original = memory[ENTRY:ENTRY + SIZE]
    assert body == original
    scenarios = cases()
    for index, case in enumerate(scenarios):
        expected, actual = exercise(memory, original, case), exercise(memory, body, case)
        assert actual == expected, (index, case, expected[:2], actual[:2], expected[2] == actual[2])
    print(json.dumps({'bytes': SIZE, 'le_sites': LE_SITES, 'cases': len(scenarios),
                      'original_and_candidate': 'passed'}))


if __name__ == '__main__':
    main()
