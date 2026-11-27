"""Verify Build map serialization order and the original register/stack calling convention."""
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

ENTRY, SIZE, DATA_BASE = 0x4a11a, 378, 0x80000
OPEN, WRITE, CLOSE, TAIL = 0x61368, 0x62a97, 0x6219a, 0x4918a
STACK, STOP, NAME, INPUT = 0x3f0000, 0x3ff000, 0x310000, 0x320000
OFFSETS = {
    '_map_version': 0x286b28, '_numsectors': 0x289154, '_numwalls': 0x289152,
    '_sector': 0x27c3a0, '_wall': 0x2310a0, '_sprite': 0x2040a0,
    '_headspritestat': 0x28811c, '_nextspritestat': 0x1fbca0,
}
FUNCTIONS = {'open_': OPEN, 'write_': WRITE, 'close_': CLOSE, 'finish_save_map_': TAIL}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
FILE_NAME = b'newboard.map'
COORDINATES = (-222222, 7123, -256)
ANGLE_SECTOR = (2047, 2)
SAVED = {
    register: 0xaa550000 + index
    for index, register in enumerate((UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def descriptor(raw):
    fd = raw & 0xffff
    return fd - 0x10000 if fd & 0x8000 else fd


def record(index, size):
    return bytes((index * 17 + byte) & 0xff for byte in range(size))


def exercise(body, tail, raw_fd, sector_count, wall_count, lists, fail_writes):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(TAIL, tail)
    events = []

    def hook(machine, address, _size, _data):
        eax, edx, ebx, esp = (machine.reg_read(register) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ESP))
        if address == OPEN:
            name, flags, mode = unpack('<III', machine.mem_read(esp + 4, 12))
            assert name == NAME
            path = bytes(machine.mem_read(name, len(FILE_NAME) + 1))
            assert path == FILE_NAME + b'\0'
            events.append(('open', flags, mode))
            machine.reg_write(UC_X86_REG_EAX, raw_fd)
            for register in (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX):
                machine.reg_write(register, 0x12345678)
        elif address == WRITE:
            assert eax == descriptor(raw_fd) & 0xffffffff
            data = bytes(machine.mem_read(edx, ebx)) if ebx else b''
            events.append(('write', data))
            machine.reg_write(UC_X86_REG_EAX, 0xffffffff if fail_writes else ebx)
            machine.reg_write(UC_X86_REG_EBX, 0x87654321)
        elif address == CLOSE:
            assert eax == descriptor(raw_fd) & 0xffffffff
            events.append(('close',))

    for address in (OPEN, WRITE, CLOSE):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.mem_write(NAME, FILE_NAME + b'\0')
    cpu.mem_write(INPUT, pack('<iiihh', *COORDINATES, *ANGLE_SECTOR))
    cpu.mem_write(DATA['_map_version'], pack('<i', 7))
    cpu.mem_write(DATA['_numsectors'], pack('<h', sector_count))
    cpu.mem_write(DATA['_numwalls'], pack('<h', wall_count))
    for field, count, size in (('_sector', sector_count, 40), ('_wall', wall_count, 32)):
        if count:
            cpu.mem_write(DATA[field], b''.join(record(index, size) for index in range(count)))
    cpu.mem_write(DATA['_headspritestat'], b'\xff' * 2050)
    for status, sprites in lists:
        cpu.mem_write(DATA['_headspritestat'] + 2 * status, pack('<h', sprites[0]))
        for sprite, following in zip(sprites, (*sprites[1:], -1)):
            cpu.mem_write(DATA['_nextspritestat'] + 2 * sprite, pack('<h', following))
            cpu.mem_write(DATA['_sprite'] + 44 * sprite, record(sprite, 44))

    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_EAX, NAME)
    cpu.reg_write(UC_X86_REG_EDX, INPUT)
    cpu.reg_write(UC_X86_REG_EBX, INPUT + 4)
    cpu.reg_write(UC_X86_REG_ECX, INPUT + 8)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<III', STOP, INPUT + 12, INPUT + 14) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=30000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 12
    assert cpu.mem_read(STACK + 12, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    return cpu.reg_read(UC_X86_REG_EAX), events


def expected(raw_fd, sector_count, wall_count, lists, fail_writes):
    del fail_writes  # The original returns success after writing whenever open succeeded.
    events = [('open', 0x261, 0x80)]
    if descriptor(raw_fd) == -1:
        return 0xffffffff, events
    sprites = tuple(sprite for status, items in sorted(lists) if status < 1024 for sprite in items)
    blocks = [
        pack('<i', 7), *(pack('<i', value) for value in COORDINATES),
        *(pack('<h', value) for value in ANGLE_SECTOR),
        pack('<h', sector_count), b''.join(record(index, 40) for index in range(sector_count)),
        pack('<h', wall_count), b''.join(record(index, 32) for index in range(wall_count)),
        pack('<H', len(sprites)), *(record(sprite, 44) for sprite in sprites),
    ]
    return 0, [*events, *(('write', block) for block in blocks), ('close',)]


def check(executable, obj):
    name = 'save_build_map_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 12
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    linked = image(executable)
    original, tail = linked[ENTRY:ENTRY + SIZE], linked[TAIL:TAIL + 6]
    boards = ((1023, (55, 9)), (3, (7, 18, 2)), (0, (21,)), (1024, (60,)))
    cases = (
        (0xaabbffff, 3, 4, boards, False), (0xabab0005, 0, 0, (), False),
        (0x7abc1234, 2, 3, boards, False), (0x45670000, 1, 0, boards, True),
        (0xffcc8000, 0, 1, ((1024, (3,)),), False),
    )
    for args in cases:
        for body in (original, code):
            result = exercise(body, tail, *args)
            assert result == expected(*args), (args, result, expected(*args))
    print(f'PASS: 378 exact bytes, 12 LE pointers, {len(cases)} map writer scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
