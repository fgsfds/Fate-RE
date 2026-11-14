"""Exact append helper plus compiled append/removal list-lifecycle fixtures."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from verify_remove_listed_sprite import bind as bind_remove, verify as verify_remove

ADDRESS, SIZE = 0x134c2, 88
DATA = {'_listed_sprite_count': 0x2be8, '_listed_sprites': 0x6fcbc,
        '_listed_sprite_records': 0x2040a0, '_listed_sprite_overflow_text': 0x21c,
        '_listed_sprite_error_buffer': 0x67e3c}
FUNCTIONS = {'format_listed_sprite_error_': 0x601f3, 'report_listed_sprite_error_': 0x26a03}


def bind(blob, loaded=False):
    return bind_leaf_details(blob, 'add_listed_sprite_',
        {key: value + (0x80000 if loaded else 0) for key, value in DATA.items()},
        address=ADDRESS, functions=FUNCTIONS)


def behavior(blob, removal):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX,
        UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EDI, UC_X86_REG_ESP, UC_X86_REG_EIP)
    compiled, _ = bind(blob, loaded=True)
    removed, _ = bind_remove(removal, loaded=True)
    def machine():
        uc = Uc(UC_ARCH_X86, UC_MODE_32)
        uc.mem_map(0, 0x400000)
        uc.mem_write(ADDRESS, compiled)
        uc.mem_write(0x10f9f, removed)
        calls = []
        def hook(machine, address, size, user):
            if address not in (0x601f3, 0x26a03, 0x50a09):
                return
            esp = machine.reg_read(UC_X86_REG_ESP)
            if address == 0x601f3:
                args = struct.unpack('<2I', machine.mem_read(esp + 4, 8))
                assert args == (0xe7e3c, 0x8021c)
                calls.append('format')
                machine.mem_write(args[0], b'overflow fixture\0')
                machine.reg_write(UC_X86_REG_EAX, 16)
            elif address == 0x26a03:
                assert machine.reg_read(UC_X86_REG_EAX) == 0xe7e3c
                assert bytes(machine.mem_read(0xe7e3c, 17)) == b'overflow fixture\0'
                calls.append('report')
            else:
                calls.append(['remove', machine.reg_read(UC_X86_REG_EAX)])
                machine.reg_write(UC_X86_REG_EAX, 0xffffffff)
            ret = struct.unpack('<I', machine.mem_read(esp, 4))[0]
            machine.reg_write(UC_X86_REG_ESP, esp + 4)
            machine.reg_write(UC_X86_REG_EIP, ret)
        uc.hook_add(UC_HOOK_CODE, hook)
        return uc, calls
    def run(uc, entry, sprite):
        saved = ((UC_X86_REG_EBX, UC_X86_REG_EDX) if entry == ADDRESS
                 else (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EDI))
        for reg in saved:
            uc.reg_write(reg, 0x12345678)
        uc.reg_write(UC_X86_REG_EAX, 0xabcd0000 | (sprite & 0xffff))
        uc.reg_write(UC_X86_REG_ESP, 0x3ff000)
        uc.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
        uc.emu_start(entry, 0x3fff00, count=10000)
        assert uc.reg_read(UC_X86_REG_EIP) == 0x3fff00
        assert uc.reg_read(UC_X86_REG_ESP) == 0x3ff004
        assert all(uc.reg_read(reg) == 0x12345678 for reg in saved)
    results = []
    for before in (-1, 0, 1, 1022, 1023, 32767):
        after = (before + 1 + 32768) % 65536 - 32768
        for sprite in (0, 7, 4095):
            for extra in (0, 0x1234, 0xffff):
                uc, calls = machine()
                slot = 0xefcbc + after * 2
                record = 0x2840a0 + sprite * 44
                uc.mem_write(0x82be8, struct.pack('<h', before))
                uc.mem_write(slot - 8, b'\x5a' * 18)
                sprite_bytes = bytearray(b'\xa5' * 44)
                struct.pack_into('<H', sprite_bytes, 42, extra)
                uc.mem_write(record, bytes(sprite_bytes))
                run(uc, ADDRESS, sprite)
                struct.pack_into('<H', sprite_bytes, 42, extra | 0x4000)
                assert bytes(uc.mem_read(record, 44)) == bytes(sprite_bytes)
                assert bytes(uc.mem_read(slot - 8, 18)) == b'\x5a' * 8 + struct.pack('<h', sprite) + b'\x5a' * 8
                assert struct.unpack('<h', uc.mem_read(0x82be8, 2))[0] == after
                assert calls == (['format', 'report'] if after > 1023 else [])
                results.append(dict(count_before=before, count_after=after, sprite=sprite,
                                    extra_before=extra, error_calls=calls[:]))
    uc, calls = machine()
    lifecycle = []
    for entry, sprite, expected in [(ADDRESS, 12, [12]), (ADDRESS, 13, [12, 13]),
            (ADDRESS, 12, [12, 13, 12]), (0x10f9f, 12, [12, 13]),
            (0x10f9f, 12, [13]), (0x10f9f, 13, [])]:
        run(uc, entry, sprite)
        count = struct.unpack('<h', uc.mem_read(0x82be8, 2))[0]
        assert count == len(expected)
        assert bytes(uc.mem_read(0xefcbe, count * 2)) == struct.pack('<' + 'h' * count, *expected)
        lifecycle.append(dict(operation='append' if entry == ADDRESS else 'remove', sprite=sprite, remaining=expected))
    assert calls == [['remove', 12], ['remove', 12], ['remove', 13]]
    assert all(struct.unpack('<H', uc.mem_read(0x2840a0 + sprite * 44 + 42, 2))[0] == 0x4000 for sprite in (12, 13))
    return results, lifecycle


def verify(executable, obj, removal):
    exe, blob = Path(executable).read_bytes(), Path(obj).read_bytes()
    if hashlib.sha256(exe).hexdigest() != EXPECTED:
        raise ValueError('Unsupported executable hash')
    code, refs = bind(blob)
    if code != exe[ADDRESS + 0x25600:ADDRESS + 0x25600 + SIZE]:
        raise ValueError('Append helper code mismatch')
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ADDRESS)
    removal_report = verify_remove(executable, removal)
    cases, lifecycle = behavior(blob, Path(removal).read_bytes())
    return dict(executable_sha256=EXPECTED, object_sha256=hashlib.sha256(blob).hexdigest(),
                removal_object_sha256=removal_report['object_sha256'], entry=hex(ADDRESS),
                end_exclusive=hex(ADDRESS + SIZE), bytes=SIZE, exact_code=True,
                le_data_pointer_count=len(refs), data_bindings={k: hex(v) for k, v in DATA.items()},
                call_bindings={k: hex(v) for k, v in FUNCTIONS.items()},
                compiled_source_cases=cases, compiled_lifecycle=lifecycle,
                external_format_report_and_engine_removal_stubbed=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('append_object', type=Path)
    parser.add_argument('removal_object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable, args.append_object, args.removal_object)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 88 exact bytes, 8 LE targets, 2 calls, 54 compiled fixtures and 6 lifecycle calls')
