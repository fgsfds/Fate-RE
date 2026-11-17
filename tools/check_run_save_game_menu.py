"""Verify save menu row initialization, preview flow, and commit/cancel behavior."""
import argparse
from pathlib import Path
from struct import pack, unpack_from

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

ENTRY, SIZE, DATA_BASE = 0x39d95, 394, 0x80000
OPEN, SEEK, READ, WRITE, CLOSE = 0x61368, 0x615b6, 0x615f7, 0x62a97, 0x6219a
REPORT, ALLOCATE = 0x26a03, 0x40c73
MENU, EDIT, RENDER, PREVIEW, TAIL = 0x3963b, 0x39890, 0x39a02, 0x39c8b, 0x39482
STACK, STOP, PIXELS = 0x3f0000, 0x3ff000, 0x310000
OFFSETS = {
    '_save_menu_title': 0xc23, '_save_names_filename': 0xd2b, '_save_names_open_error': 0xd37,
    '_save_names': 0x1303a, '_save_menu_records': 0x174104, '_save_slot_menu_rows': 0x173fc0,
    '_editing_save_slot': 0x1740c8, '_save_preview_lock': 0x1f9c9e, '_save_preview_pixels': 0x203c98,
}
FUNCTIONS = {
    'open_': OPEN, 'lseek_': SEEK, 'read_': READ, 'write_': WRITE, 'close_': CLOSE,
    'report_game_error_': REPORT, 'allocache_': ALLOCATE, 'run_menu_loop_': MENU,
    'edit_save_slot_name_': EDIT, 'render_save_slot_preview_': RENDER,
    'write_save_slot_preview_': PREVIEW, 'finish_save_game_menu_': TAIL,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
ORIGINAL_NAMES = b''.join(f'Game {slot:02}'.encode().ljust(16) + b'\0' for slot in range(10))
UPDATED_NAME = b'EDITED GAMENAME \0'
SAVED = {
    register: 0xabcd0001 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def exercise(body, tail, fd, cached, old_slot, chosen_slot, accept):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(TAIL, tail)
    events = []

    def dword(address):
        return unpack_from('<I', cpu.mem_read(address, 4))[0]

    def write_slot(value):
        cpu.mem_write(DATA['_editing_save_slot'], pack('<I', value))

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx, esp = (machine.reg_read(register) for register in
                                   (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX,
                                    UC_X86_REG_ECX, UC_X86_REG_ESP))
        if address == OPEN:
            assert ecx == 1
            filename, flags, mode = unpack_from('<III', machine.mem_read(esp + 4, 12))
            assert (filename, flags, mode) == (DATA['_save_names_filename'], 0x222, 0x180)
            events.append(('open',))
            machine.reg_write(UC_X86_REG_EAX, fd & 0xffffffff)
        elif address == SEEK:
            assert (eax, edx, ebx) == (fd & 0xffffffff, 0, 0)
            events.append(('seek',))
            machine.reg_write(UC_X86_REG_EAX, 0)
        elif address == READ:
            assert (eax, edx, ebx) == (fd & 0xffffffff, DATA['_save_names'], 170)
            machine.mem_write(edx, ORIGINAL_NAMES)
            machine.reg_write(UC_X86_REG_EAX, 170)
            events.append(('read',))
        elif address == REPORT:
            assert eax == DATA['_save_names_open_error']
            events.append(('report',))
        elif address == ALLOCATE:
            assert (eax, edx, ebx) == (DATA['_save_preview_pixels'], 64000, DATA['_save_preview_lock'])
            assert machine.mem_read(ebx, 1)[0] == 255
            machine.mem_write(eax, pack('<I', PIXELS))
            events.append(('allocate',))
        elif address == RENDER:
            assert eax == old_slot
            assert dword(DATA['_save_preview_pixels']) == PIXELS
            assert machine.mem_read(DATA['_save_preview_lock'], 1)[0] == 255
            for index in range(10):
                row = DATA['_save_menu_records'] + 21 * index
                assert dword(DATA['_save_slot_menu_rows'] + 4 * index) == row
                assert machine.mem_read(row, 21) == (
                    b'\x01\x06\x00' + pack('<I', DATA['_save_names'] + 17 * index) +
                    b'\0' * 8 + b'\xa5' * 4 + b'\0\0')
            events.append(('render', eax))
        elif address == MENU:
            assert (eax, edx, ebx, ecx) == (DATA['_editing_save_slot'], 10, 0x83d, DATA['_save_menu_title'])
            assert dword(esp + 4) == DATA['_save_slot_menu_rows']
            events.append(('menu', dword(eax)))
            machine.reg_write(UC_X86_REG_EAX, 0 if chosen_slot is None else 1)
            if chosen_slot is not None:
                write_slot(chosen_slot)
        elif address == EDIT:
            assert (eax, edx) == (0x83d, DATA['_save_menu_title'])
            events.append(('edit', chosen_slot))
            if accept:
                machine.mem_write(DATA['_save_names'] + 17 * chosen_slot, UPDATED_NAME)
            machine.reg_write(UC_X86_REG_EAX, int(accept))
        elif address == WRITE:
            assert (eax, edx, ebx) == (fd & 0xffffffff, DATA['_save_names'], 170)
            payload = bytearray(ORIGINAL_NAMES)
            payload[17 * chosen_slot:17 * (chosen_slot + 1)] = UPDATED_NAME
            assert machine.mem_read(edx, ebx) == payload
            events.append(('write',))
        elif address == PREVIEW:
            assert eax == chosen_slot
            events.append(('preview', eax))
        elif address == CLOSE:
            assert eax == fd & 0xffffffff
            assert (edx & 0xff) == 1
            assert machine.mem_read(DATA['_save_preview_lock'], 1)[0] == 255
            events.append(('close',))

    for address in FUNCTIONS.values():
        if address == TAIL:
            continue
        cpu.mem_write(address, b'\xc2\x04\0' if address == MENU else b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.mem_write(DATA['_save_preview_pixels'], pack('<I', PIXELS if cached else 0))
    cpu.mem_write(DATA['_save_preview_lock'], b'\x7f')
    cpu.mem_write(DATA['_save_menu_records'], b'\xa5' * 210)
    write_slot(old_slot)
    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=1400)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    assert cpu.mem_read(DATA['_save_preview_lock'], 1)[0] == 1
    assert cpu.reg_read(UC_X86_REG_EAX) == 0
    return events


def expected(fd, cached, old_slot, chosen_slot, accept):
    events = [('open',)]
    events.extend([('report',)] if fd == -1 else [('seek',), ('read',)])
    if not cached:
        events.append(('allocate',))
    events.extend([('render', old_slot), ('menu', old_slot if old_slot < 10 else 0)])
    if chosen_slot is not None:
        events.append(('edit', chosen_slot))
        if accept:
            events.extend([('seek',), ('write',), ('preview', chosen_slot)])
    return [*events, ('close',)]


def check(executable, obj):
    name = 'run_save_game_menu_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 26
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    linked = image(executable)
    original, tail = linked[ENTRY:ENTRY + SIZE], linked[TAIL:TAIL + 6]
    cases = ((4, True, 3, None, False), (3, False, 10, None, False),
             (7, False, 12, 4, True), (8, True, 1, 0, False), (-1, True, 0, None, False))
    for args in cases:
        for body in (original, code):
            result = exercise(body, tail, *args)
            assert result == expected(*args), (args, result, expected(*args))
    print(f'PASS: 394 exact bytes, 26 LE pointers, {len(cases)} save-menu scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
