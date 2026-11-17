"""Verify Build map loading, bitmap resets, sprite reconstruction, and the return ABI."""
import argparse
from pathlib import Path
from struct import pack, pack_into, unpack

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

ENTRY, SIZE, DATA_BASE = 0x49f89, 401, 0x80000
OPEN, READ, CLOSE, TAIL = 0x41281, 0x4137d, 0x41503, 0x4918a
INIT, INSERT, UPDATE = 0x507e3, 0x508b8, 0x542c4
STACK, STOP, NAME, OUTPUT = 0x3f0000, 0x3ff000, 0x310000, 0x320000
OFFSETS = {
    '_map_version': 0x286b28, '_numsectors': 0x289154, '_numwalls': 0x289152,
    '_sector': 0x27c3a0, '_wall': 0x2310a0, '_sprite': 0x2040a0,
    '_show_2d_sectors': 0x1ec6a0, '_show_2d_walls': 0x1ec920, '_sprite_visibility': 0x1ecfa0,
}
FUNCTIONS = {'kopen4load_': OPEN, 'kread_': READ, 'kclose_': CLOSE, 'initspritelists_': INIT,
             'insertsprite_': INSERT, 'updatesector_': UPDATE, 'finish_load_map_': TAIL}
DATA = {name: DATA_BASE + offset for name, offset in OFFSETS.items()}
FILE_NAME = b'existing.map'
COORDS, ANGLE, START_SECTOR, UPDATED_SECTOR = (-121366, 16573, -199), 1569, -1, 17
BITMAPS = (('_show_2d_sectors', 128), ('_sprite_visibility', 512), ('_show_2d_walls', 1024))
SAVED = {
    register: 0xface0000 + index
    for index, register in enumerate((UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def signed(value, bits):
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def records(count, length):
    return b''.join(bytes((11 * number + byte) & 0xff for byte in range(length)) for number in range(count))


def sprites_data(sprites):
    result = bytearray(records(len(sprites), 44))
    for index, (sector, status) in enumerate(sprites):
        pack_into('<hh', result, index * 44 + 24, sector, status)
    return bytes(result)


def exercise(body, tail, raw_fd, version, sector_count, wall_count, sprites):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(TAIL, tail)
    events = []
    descriptor = signed(raw_fd & 0xffff, 16)
    sectors, walls, sprite_bytes = records(sector_count, 40), records(wall_count, 32), sprites_data(sprites)
    payloads = [
        pack('<i', version), *(pack('<i', value) for value in COORDS),
        pack('<h', ANGLE), pack('<h', START_SECTOR), pack('<h', sector_count), sectors,
        pack('<h', wall_count), walls, pack('<h', len(sprites)), sprite_bytes,
    ]
    targets = (DATA['_map_version'], OUTPUT, OUTPUT + 4, OUTPUT + 8, OUTPUT + 12, OUTPUT + 14,
               DATA['_numsectors'], DATA['_sector'], DATA['_numwalls'], DATA['_wall'],
               STACK - 16, DATA['_sprite'])
    reads = iter(zip(targets, payloads))

    def hook(machine, address, _size, _data):
        eax, edx, ebx = (machine.reg_read(register) for register in
                         (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX))
        if address == OPEN:
            assert eax == NAME and edx == 0
            assert machine.mem_read(NAME, len(FILE_NAME) + 1) == FILE_NAME + b'\0'
            events.append(('open',))
            machine.reg_write(UC_X86_REG_EAX, raw_fd)
            for register in (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX):
                machine.reg_write(register, 0x12345678)
        elif address == READ:
            target, value = next(reads)
            assert eax == descriptor & 0xffffffff and edx == target and ebx == len(value), (eax, edx, ebx, target)
            events.append(('read', len(value)))
            if value:
                machine.mem_write(target, value)
            machine.reg_write(UC_X86_REG_EAX, len(value))
            machine.reg_write(UC_X86_REG_EBX, 0xfedcba98)
            machine.reg_write(UC_X86_REG_EDX, 0xabcd0001)
        elif address == INIT:
            events.append(('init',))
            assert all(machine.mem_read(DATA[name], length) == b'\xab' * length for name, length in BITMAPS)
        elif address == INSERT:
            events.append(('insert', signed(eax, 32), signed(edx, 32)))
            machine.reg_write(UC_X86_REG_EAX, 0xaaaa0001)
        elif address == UPDATE:
            assert unpack('<h', machine.mem_read(ebx, 2))[0] == START_SECTOR
            events.append(('sector', signed(eax, 32), signed(edx, 32), ebx))
            machine.mem_write(ebx, pack('<h', UPDATED_SECTOR))
        elif address == CLOSE:
            assert eax == descriptor & 0xffffffff
            events.append(('close',))

    for address in (OPEN, READ, CLOSE, INIT, INSERT, UPDATE):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.mem_write(NAME, FILE_NAME + b'\0')
    cpu.mem_write(OUTPUT, b'\x19' * 16)
    cpu.mem_write(DATA['_map_version'], pack('<i', 42))
    for field, size in BITMAPS:
        cpu.mem_write(DATA[field] - 1, b'\x1b' + b'\xab' * size + b'\x7f')

    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_EAX, NAME)
    cpu.reg_write(UC_X86_REG_EDX, OUTPUT)
    cpu.reg_write(UC_X86_REG_EBX, OUTPUT + 4)
    cpu.reg_write(UC_X86_REG_ECX, OUTPUT + 8)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<III', STOP, OUTPUT + 12, OUTPUT + 14) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=12000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 12
    assert cpu.mem_read(STACK + 12, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())

    result, final_version = cpu.reg_read(UC_X86_REG_EAX), unpack('<i', cpu.mem_read(DATA['_map_version'], 4))[0]
    loaded = descriptor != -1 and version == 7
    for field, size in BITMAPS:
        contents = b'\0' if loaded else b'\xab'
        assert cpu.mem_read(DATA[field] - 1, size + 2) == b'\x1b' + contents * size + b'\x7f'
    if not loaded:
        assert cpu.mem_read(OUTPUT, 16) == b'\x19' * 16
        assert (result, final_version) == (0xffffffff, 7 if descriptor == -1 else version)
        assert events == [('open',)] + ([('read', 4)] if descriptor != -1 else [])
        return
    assert (result, final_version) == (0, 7)
    assert unpack('<iiihh', cpu.mem_read(OUTPUT, 16)) == (*COORDS, ANGLE, UPDATED_SECTOR)
    assert unpack('<h', cpu.mem_read(DATA['_numsectors'], 2))[0] == sector_count
    assert unpack('<h', cpu.mem_read(DATA['_numwalls'], 2))[0] == wall_count
    for field, value in (('_sector', sectors), ('_wall', walls), ('_sprite', sprite_bytes)):
        assert bytes(cpu.mem_read(DATA[field], len(value))) == value
    assert events == [('open',), ('read', 4), ('init',),
                      *(('read', len(value)) for value in payloads[1:]),
                      *(('insert', *pair) for pair in sprites),
                      ('sector', *COORDS[:2], OUTPUT + 14), ('close',)]
    assert next(reads, None) is None


def check(executable, obj):
    name = 'load_build_map_'
    code, refs = bind_leaf_details(obj, name, OFFSETS, address=ENTRY, functions=FUNCTIONS)
    raw = ENTRY + 0x25600
    assert len(code) == SIZE and code == executable[raw:raw + SIZE] and len(refs) == 15
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, name, DATA, address=ENTRY, functions=FUNCTIONS)
    original = image(executable)
    tail, original = original[TAIL:TAIL + 6], original[ENTRY:ENTRY + SIZE]
    cases = (
        (0xabcdffff, 9, 2, 5, ((0, 1),)), (0x12340007, 6, 2, 3, ()),
        (0xeedb0000, 7, 0, 0, ()), (0x1234000d, 7, 2, 3, ((8, 4), (-3, -1), (12, 800))),
        (0xfe128000, 7, 1, 0, ((0, 1023),)),
    )
    for args in cases:
        for body in (original, code):
            exercise(body, tail, *args)
    print(f'PASS: 401 exact bytes, 15 LE pointers, {len(cases)} map loader scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
