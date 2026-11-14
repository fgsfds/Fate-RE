"""Strict template-spawn match with compiled field-copy, bitmap and failure checks."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

ADDRESS, SIZE = 0x11073, 302
DATA = {'_sprite_templates': 0x2bfe, '_game_sprites': 0x2040a0,
        '_sprite_old_positions': 0x20a2c, '_sprite_visibility': 0x1ecfa0}
FUNCTIONS = {'insert_template_sprite_': 0x508b8}
FIELDS = [(0, 12, 2), (2, 16, 1), (3, 17, 1), (4, 18, 1),
          (5, 20, 1), (6, 21, 1), (7, 22, 1), (8, 23, 1),
          (9, 14, 2), (11, 28, 2), (13, 32, 2), (15, 34, 2),
          (17, 36, 2), (19, 30, 2), (23, 38, 2), (25, 40, 2), (27, 42, 2)]


def bind(blob, loaded=False):
    return bind_leaf_details(blob, 'spawn_template_sprite_',
        {key: value + (0x80000 if loaded else 0) for key, value in DATA.items()},
        address=ADDRESS, functions=FUNCTIONS)


def behavior(blob):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX,
        UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI,
        UC_X86_REG_EBP, UC_X86_REG_ESP, UC_X86_REG_EIP, UC_X86_REG_EFLAGS)
    code, _ = bind(blob, loaded=True)
    cases = []
    for template_index in (0, 1, 128):
        template = bytes((i * 37 + template_index * 11) & 255 for i in range(31))
        status = struct.unpack_from('<h', template, 21)[0]
        for sprite in (-1, 0, 7, 8, 4095):
            for upper in (0, 0xabcd0000):
                for bitmap in (0xff, 0xa5):
                    uc = Uc(UC_ARCH_X86, UC_MODE_32)
                    uc.mem_map(0, 0x400000)
                    uc.mem_write(ADDRESS, code)
                    template_address = 0x80000 + DATA['_sprite_templates'] + template_index * 31
                    uc.mem_write(template_address, template)
                    position = struct.pack('<3i', -2147483647, 12345678, -987654)
                    uc.mem_write(0x380000, position)
                    sprite_address = 0x80000 + DATA['_game_sprites'] + sprite * 44
                    old_address = 0x80000 + DATA['_sprite_old_positions'] + sprite * 12
                    bitmap_address = 0x80000 + DATA['_sprite_visibility'] + (sprite >> 3)
                    uc.mem_write(sprite_address - 16, b'\xe7' * 16 + b'\xa5' * 44 + b'\xe7' * 16)
                    uc.mem_write(old_address - 16, b'\x79' * 44)
                    uc.mem_write(bitmap_address - 4, bytes([bitmap]) * 9)
                    sector = 225
                    returned = upper | (sprite & 0xffff)
                    uc.reg_write(UC_X86_REG_EAX, 0x56780000 | template_index)
                    uc.reg_write(UC_X86_REG_EDX, 0x380000)
                    uc.reg_write(UC_X86_REG_EBX, 0x12340000 | sector)
                    uc.reg_write(UC_X86_REG_EFLAGS, 2)  # ABI requires forward string operations.
                    saved = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
                    for reg in saved:
                        uc.reg_write(reg, 0x12345678)
                    uc.reg_write(UC_X86_REG_ESP, 0x3ff000)
                    uc.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
                    calls = []
                    def hook(machine, address, size, user):
                        if address != 0x508b8:
                            return
                        calls.append([machine.reg_read(UC_X86_REG_EAX), machine.reg_read(UC_X86_REG_EDX)])
                        # Only successful insertion initializes the engine-owned fields.
                        if sprite >= 0:
                            machine.mem_write(sprite_address + 24, struct.pack('<2h', sector, status))
                        machine.reg_write(UC_X86_REG_EAX, returned)
                        esp = machine.reg_read(UC_X86_REG_ESP)
                        ret = struct.unpack('<I', machine.mem_read(esp, 4))[0]
                        machine.reg_write(UC_X86_REG_ESP, esp + 4)
                        machine.reg_write(UC_X86_REG_EIP, ret)
                    uc.hook_add(UC_HOOK_CODE, hook)
                    uc.emu_start(ADDRESS, 0x3fff00, count=10000)
                    expected = bytearray(b'\xa5' * 44)
                    expected[:12] = position
                    if sprite >= 0:
                        struct.pack_into('<2h', expected, 24, sector, status)
                    for src, dest, width in FIELDS:
                        expected[dest:dest + width] = template[src:src + width]
                    assert uc.reg_read(UC_X86_REG_EIP) == 0x3fff00
                    assert uc.reg_read(UC_X86_REG_ESP) == 0x3ff004
                    assert all(uc.reg_read(reg) == 0x12345678 for reg in saved)
                    assert uc.reg_read(UC_X86_REG_EAX) == returned
                    assert calls == [[sector, status & 0xffffffff]]
                    assert bytes(uc.mem_read(sprite_address - 16, 76)) == b'\xe7' * 16 + bytes(expected) + b'\xe7' * 16
                    assert bytes(uc.mem_read(old_address - 16, 44)) == b'\x79' * 16 + position + b'\x79' * 16
                    expected_bitmap = bytes([bitmap]) * 4 + bytes([bitmap & ~(1 << (sprite & 7))]) + bytes([bitmap]) * 4
                    assert bytes(uc.mem_read(bitmap_address - 4, 9)) == expected_bitmap
                    assert bytes(uc.mem_read(template_address, 31)) == template
                    assert bytes(uc.mem_read(0x380000, 12)) == position
                    cases.append(dict(template=template_index, sprite=sprite, return_upper_bits=hex(upper),
                                      bitmap_before=bitmap, insertion_failure_unchecked=(sprite < 0)))
    return cases


def verify(executable, obj):
    exe, blob = Path(executable).read_bytes(), Path(obj).read_bytes()
    if hashlib.sha256(exe).hexdigest() != EXPECTED:
        raise ValueError('Unsupported executable hash')
    code, refs = bind(blob)
    if code != exe[ADDRESS + 0x25600:ADDRESS + 0x25600 + SIZE]:
        raise ValueError(f'Compiled code mismatch ({len(code)} generated bytes, {SIZE} target)')
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ADDRESS)
    return dict(executable_sha256=EXPECTED, object_sha256=hashlib.sha256(blob).hexdigest(),
                entry=hex(ADDRESS), end_exclusive=hex(ADDRESS + SIZE), bytes=SIZE,
                exact_code=True, le_data_pointer_count=len(refs),
                data_bindings={key: hex(value) for key, value in DATA.items()},
                call_bindings={key: hex(value) for key, value in FUNCTIONS.items()},
                copybuf_eax_scratch_contract='inferred conservative clobber; original spelling unknown',
                compiled_source_cases=behavior(blob), external_insertion_stubbed=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.executable, args.object)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 302 exact bytes, 21 LE targets, 1 call, 60 compiled-source fixtures')
