"""Exact sequence advancement with real compiled removal and recovered descriptors."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED
from le_fixups import read_le_fixups
from verify_init_object_sequences import verify as verify_initializer, compiled_descriptors
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from verify_remove_listed_sprite import bind as bind_remove, verify as verify_remove

ADDRESS, SIZE = 0x123d6, 203
DATA = {'_sequence_sprites': 0x2040a0, '_object_sequences': 0x6807c,
        '_active_sequence_count': 0x7dee0, '_active_sequence_sprites': 0x67a3c}
FUNCTIONS = {'sequence_remove_sprite_': 0x10f9f}


def bind(blob, loaded=False):
    return bind_leaf_details(blob, 'advance_sequences_',
        {name: value + (0x80000 if loaded else 0) for name, value in DATA.items()},
        address=ADDRESS, functions=FUNCTIONS)


def behavior(blob, removal, descriptors):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX,
        UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI,
        UC_X86_REG_ESP, UC_X86_REG_EIP)
    compiled, _ = bind(blob, loaded=True)
    removed, _ = bind_remove(removal, loaded=True)
    table = {int(key): [row[name] for name in ('start', 'end', 'final', 'next')]
             for key, row in descriptors.items()}
    table[1] = [32767, 32767, 42, 2]
    table[255] = [5, 6, 7, 3]
    # State tuples: sprite, sequence index, current picnum, preserved low tag.
    scenarios = [
        ('empty', [], {}, 1),
        ('door_28_finish_then_idle', [44], {44: (28, 1516, 0)}, 2),
        ('door_29_full_advance', [44], {44: (29, 1517, 0)}, 6),
        ('grate_61_remove', [43], {43: (61, 1408, 0)}, 1),
        ('barrel_55_at_end', [47], {47: (55, 1019, 100)}, 1),
        ('barrel_50_reaches_end', [70], {70: (50, 1018, 100)}, 1),
        ('swap_skips_remaining_sprite', [43, 44], {43: (61, 1408, 0), 44: (29, 1517, 0)}, 1),
        ('last_entry_finishes', [44, 43], {44: (29, 1517, 0), 43: (61, 1408, 0)}, 1),
        ('duplicate_active_entry', [44, 44], {44: (28, 1516, 0)}, 1),
        ('signed_picnum_wrap', [12], {12: (1, 32767, 100)}, 1),
        ('high_sequence_byte', [12], {12: (255, 5, 100)}, 2),
    ]
    results = []
    for name, active_ids, initial, steps in scenarios:
        for engine_return in (0, 0xffffffff):
            uc = Uc(UC_ARCH_X86, UC_MODE_32)
            uc.mem_map(0, 0x400000)
            uc.mem_write(ADDRESS, compiled)
            uc.mem_write(0x10f9f, removed)
            for index, values in table.items():
                uc.mem_write(0xe807c + index * 120, struct.pack('<4h', *values))
            active = [-1234] + active_ids[:]
            active_count = len(active_ids)
            moving = [-2345] + list(initial)
            moving_count = len(initial)
            uc.mem_write(0xfdee0, struct.pack('<h', active_count))
            uc.mem_write(0xe7a3c, struct.pack('<' + 'h' * len(active), *active))
            uc.mem_write(0x82be8, struct.pack('<h', moving_count))
            uc.mem_write(0xefcbc, struct.pack('<' + 'h' * len(moving), *moving))
            sprites = {}
            for sprite, (sequence, picnum, low_tag) in initial.items():
                row = bytearray(b'\xa5' * 44)
                struct.pack_into('<H', row, 12, 273)
                struct.pack_into('<h', row, 14, picnum)
                struct.pack_into('<H', row, 38, (sequence << 8) | low_tag)
                sprites[sprite] = row
                uc.mem_write(0x2840a0 + sprite * 44, bytes(row))
            engine_calls, expected_calls = [], []
            def hook(machine, address, size, user):
                if address != 0x50a09:
                    return
                engine_calls.append(machine.reg_read(UC_X86_REG_EAX))
                machine.reg_write(UC_X86_REG_EAX, engine_return)
                esp = machine.reg_read(UC_X86_REG_ESP)
                ret = struct.unpack('<I', machine.mem_read(esp, 4))[0]
                machine.reg_write(UC_X86_REG_ESP, esp + 4)
                machine.reg_write(UC_X86_REG_EIP, ret)
            uc.hook_add(UC_HOOK_CODE, hook)
            history = []
            for step in range(steps):
                i = 1
                while i <= active_count:
                    sprite = active[i]
                    row = sprites[sprite]
                    tag = struct.unpack_from('<H', row, 38)[0]
                    sequence = table[tag >> 8]
                    picnum = struct.unpack_from('<h', row, 14)[0]
                    picnum = (picnum + 1 + 32768) % 65536 - 32768
                    struct.pack_into('<h', row, 14, picnum)
                    if picnum > sequence[1]:
                        if sequence[2]:
                            struct.pack_into('<h', row, 14, sequence[2])
                            struct.pack_into('<H', row, 38, ((tag & 255) | (sequence[3] << 8)) & 65535)
                        else:
                            expected_calls.append(sprite)
                            j = 1
                            while j <= moving_count:
                                if moving[j] == sprite:
                                    moving[j] = moving[moving_count]
                                    moving_count -= 1
                                j += 1
                        active[i] = active[active_count]
                        active_count -= 1
                    i += 1
                saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI)
                for reg in saved:
                    uc.reg_write(reg, 0x12345678)
                uc.reg_write(UC_X86_REG_ESP, 0x3ff000)
                uc.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
                uc.emu_start(ADDRESS, 0x3fff00, count=10000)
                assert uc.reg_read(UC_X86_REG_EIP) == 0x3fff00
                assert uc.reg_read(UC_X86_REG_ESP) == 0x3ff004
                assert all(uc.reg_read(reg) == 0x12345678 for reg in saved)
                assert engine_calls == expected_calls
                assert struct.unpack('<h', uc.mem_read(0xfdee0, 2))[0] == active_count
                assert struct.unpack('<h', uc.mem_read(0x82be8, 2))[0] == moving_count
                assert bytes(uc.mem_read(0xe7a3c, len(active) * 2)) == struct.pack('<' + 'h' * len(active), *active)
                assert bytes(uc.mem_read(0xefcbc, len(moving) * 2)) == struct.pack('<' + 'h' * len(moving), *moving)
                for sprite, row in sprites.items():
                    assert bytes(uc.mem_read(0x2840a0 + sprite * 44, 44)) == bytes(row)
                history.append(dict(active_count=active_count, moving_count=moving_count,
                    sprites={str(sprite): dict(picnum=struct.unpack_from('<h', row, 14)[0],
                        lotag=struct.unpack_from('<H', row, 38)[0]) for sprite, row in sprites.items()}))
            results.append(dict(case=name, engine_return=hex(engine_return), engine_calls=engine_calls,
                                history=history))
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('sequence_object', type=Path)
    parser.add_argument('removal_object', type=Path)
    parser.add_argument('initializer_object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    exe, blob = args.executable.read_bytes(), args.sequence_object.read_bytes()
    if hashlib.sha256(exe).hexdigest() != EXPECTED:
        raise ValueError('Unsupported executable hash')
    code, refs = bind(blob)
    if code != exe[0x379d6:0x37aa1]:
        raise ValueError('Sequence advancement code mismatch')
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ADDRESS)
    removal_report = verify_remove(args.executable, args.removal_object)
    initializer = args.initializer_object.read_bytes()
    verify_initializer(exe, initializer)
    recovered = {'sequences': compiled_descriptors(initializer)}
    cases = behavior(blob, args.removal_object.read_bytes(), recovered['sequences'])
    result = dict(executable_sha256=EXPECTED, object_sha256=hashlib.sha256(blob).hexdigest(),
        removal_object_sha256=removal_report['object_sha256'], entry=hex(ADDRESS),
        end_exclusive=hex(ADDRESS + SIZE), bytes=SIZE, exact_code=True, le_data_pointer_count=len(refs),
        data_bindings={key: hex(value) for key, value in DATA.items()},
        call_bindings={key: hex(value) for key, value in FUNCTIONS.items()},
        descriptor_source='matched compiled C initializer with zeroed BSS',
        initializer_object_sha256=hashlib.sha256(initializer).hexdigest(),
        recovered_descriptors={key: {field: row[field] for field in ('start', 'end', 'final', 'next')}
                               for key, row in recovered['sequences'].items()},
        compiled_source_cases=cases, only_engine_removal_stubbed=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 203 exact bytes, 16 LE targets, 1 call; 22 compiled sequence/removal scenarios')
