"""Compare the original and compiled load menu, including preview and file-presence checks."""
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

ENTRY, SIZE, DATA_BASE = 0x39f1f, 431, 0x80000
OPEN, SEEK, READ, CLOSE = 0x61368, 0x615b6, 0x615f7, 0x6219a
ALLOCATE, READ_PREVIEW, TILE_VIEW, RESTORE_VIEW = 0x40c73, 0x39cfa, 0x5d2f4, 0x5d46d
MENU, FORMAT, ACCESS = 0x3963b, 0x601f3, 0x63130
STACK, STOP, PIXELS = 0x3f0000, 0x3ff000, 0x310000
OFFSETS = {
    '_load_menu_title': 0xc19, '_save_preview_filename': 0xd19, '_save_preview_format': 0xd21,
    '_save_names_filename': 0xd2b, '_save_names': 0x1303a, '_save_menu_records': 0x174104,
    '_save_slot_menu_rows': 0x173fc0, '_editing_save_slot': 0x1740c8,
    '_save_preview_lock': 0x1f9c9e, '_save_preview_pixels': 0x203c98, '_save_slot_preview_enabled': 0x1314d,
}
FUNCTIONS = {
    'open_': OPEN, 'lseek_': SEEK, 'read_': READ, 'close_': CLOSE, 'allocache_': ALLOCATE,
    'read_save_slot_preview_': READ_PREVIEW, 'setviewtotile_': TILE_VIEW, 'setviewback_': RESTORE_VIEW,
    'run_menu_loop_': MENU, 'sprintf_': FORMAT, 'access_': ACCESS,
}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
NAMES = b''.join(f'Game {slot:02}'.encode().ljust(16) + b'\0' for slot in range(10))
SAVED = {
    register: 0xbcde1000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def exercise(body, fd, cached, initial_slot, choice, access_result):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    events = []
    initial_preview = initial_slot if initial_slot < 10 else 0

    def dword(address):
        return unpack_from('<I', cpu.mem_read(address, 4))[0]

    def write_slot(value):
        cpu.mem_write(DATA['_editing_save_slot'], pack('<I', value))

    def preview_active(machine):
        assert machine.mem_read(DATA['_save_slot_preview_enabled'], 1)[0] == 1
        assert machine.mem_read(DATA['_save_preview_lock'], 1)[0] == 255

    def check_rows(machine, prepared):
        for slot in range(10):
            row = DATA['_save_menu_records'] + slot * 21
            assert dword(DATA['_save_slot_menu_rows'] + 4 * slot) == row
            values = (0xffe, 0x6000) if prepared and slot == initial_preview else (0, 0)
            assert machine.mem_read(row, 21) == (
                b'\x01\x06\x00' + pack('<Iii', DATA['_save_names'] + slot * 17, *values) +
                b'\xa5' * 4 + b'\0\0')

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx, esp = (machine.reg_read(register) for register in
                                   (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX,
                                    UC_X86_REG_ECX, UC_X86_REG_ESP))
        if address == OPEN:
            args = unpack_from('<II', machine.mem_read(esp + 4, 8))
            assert args == (DATA['_save_names_filename'], 0x202)
            assert machine.reg_read(UC_X86_REG_ESI) == DATA['_save_preview_filename']
            events.append(('open',))
            machine.reg_write(UC_X86_REG_EAX, fd & 0xffffffff)
        elif address == SEEK:
            assert (eax, edx, ebx) == (fd, 0, 0)
            events.append(('seek',))
            machine.reg_write(UC_X86_REG_EAX, 0)
        elif address == READ:
            assert (eax, edx, ebx) == (fd, DATA['_save_names'], 170)
            machine.mem_write(edx, NAMES)
            machine.reg_write(UC_X86_REG_EAX, 170)
            events.append(('read',))
        elif address == CLOSE:
            assert eax == fd
            events.append(('close',))
        elif address == ALLOCATE:
            assert (eax, edx, ebx) == (DATA['_save_preview_pixels'], 64000, DATA['_save_preview_lock'])
            assert machine.mem_read(ebx, 1)[0] == 255
            machine.mem_write(eax, pack('<I', PIXELS))
            events.append(('allocate',))
        elif address == READ_PREVIEW:
            assert (eax, edx, ebx) == (initial_preview, 200, 320)
            assert dword(DATA['_save_preview_pixels']) == PIXELS
            preview_active(machine)
            check_rows(machine, False)
            events.append(('preview', eax))
            machine.reg_write(UC_X86_REG_EAX, 0x1705)
        elif address == TILE_VIEW:
            assert (eax, edx, ebx) == (0xffe, 200, 320)
            preview_active(machine)
            events.append(('tile_view',))
        elif address == RESTORE_VIEW:
            events.append(('restore_view',))
        elif address == MENU:
            assert (eax, edx, ebx, ecx) == (DATA['_editing_save_slot'], 10, 0x83d, DATA['_load_menu_title'])
            assert dword(esp + 4) == DATA['_save_slot_menu_rows']
            assert dword(eax) == initial_preview
            preview_active(machine)
            check_rows(machine, True)
            events.append(('menu', initial_preview))
            machine.reg_write(UC_X86_REG_EAX, int(choice is not None))
            if choice is not None:
                write_slot(choice)
        elif address == FORMAT:
            destination, fmt, selected = unpack_from('<III', machine.mem_read(esp + 4, 12))
            assert (destination, fmt, selected) == (DATA['_save_preview_filename'], DATA['_save_preview_format'], choice)
            assert machine.mem_read(fmt, 9) == b'sss.g%02d'
            machine.mem_write(destination, f'sss.g{selected:02}'.encode() + b'\0')
            events.append(('format', selected))
        elif address == ACCESS:
            assert (eax, edx) == (DATA['_save_preview_filename'], 0)
            assert machine.mem_read(eax, 8) == f'sss.g{choice:02}'.encode() + b'\0'
            preview_active(machine)
            machine.reg_write(UC_X86_REG_EAX, access_result & 0xffffffff)
            events.append(('access', choice))

    for address in FUNCTIONS.values():
        cpu.mem_write(address, b'\xc2\x04\x00' if address == MENU else b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.mem_write(DATA['_save_preview_pixels'], pack('<I', PIXELS if cached else 0))
    cpu.mem_write(DATA['_save_preview_lock'], b'\x7f')
    cpu.mem_write(DATA['_save_slot_preview_enabled'], b'\x7a')
    cpu.mem_write(DATA['_save_menu_records'], b'\xa5' * 210)
    cpu.mem_write(DATA['_save_preview_format'], b'sss.g%02d\0')
    write_slot(initial_slot)
    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=1500)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    assert cpu.mem_read(DATA['_save_preview_lock'], 1)[0] == 1
    assert cpu.mem_read(DATA['_save_slot_preview_enabled'], 1)[0] == 0
    return cpu.reg_read(UC_X86_REG_EAX), events


def expected(fd, cached, initial_slot, choice, access_result):
    events = [('open',)]
    if fd != -1:
        events.extend([('seek',), ('read',), ('close',)])
    if not cached:
        events.append(('allocate',))
    shown = initial_slot if initial_slot < 10 else 0
    events.extend([('preview', shown), ('tile_view',), ('restore_view',), ('menu', shown)])
    if choice is not None:
        events.extend([('format', choice), ('access', choice)])
    result = choice if choice is not None and access_result != -1 else 0xffffffff
    return result, events


def check(executable, obj):
    name = 'run_load_game_menu_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 31
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)[ENTRY:ENTRY + SIZE]
    cases = ((4, True, 3, None, -1), (3, False, 10, None, -1), (7, False, 12, 4, 0),
             (8, True, 1, 0, -1), (-1, True, 0, None, -1), (-1, False, 8, 9, 2))
    for args in cases:
        for body in (original, code):
            result = exercise(body, *args)
            assert result == expected(*args), (args, result, expected(*args))
    print(f'PASS: 431 exact bytes, 31 LE pointers, {len(cases)} load-menu scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
