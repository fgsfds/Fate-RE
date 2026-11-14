"""Exact insertion wrapper; behavioral-only integration of unmatched list helpers.

Resolved internal JMPs are never patched. The whole compiled insertion group runs
contiguously at its generated layout, so its status helper has a different address
than FATE. This does not establish a byte match for those two helper bodies.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED, image
from le_fixups import read_le_fixups
from match_objects import read_object
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from verify_spawn_template_sprite import bind as bind_spawn, verify as verify_spawn, FIELDS

BASE = 0x508b8
DATA = {'_sprite': 0x2040a0, '_headspritesect': 0x28891e,
        '_prevspritesect': 0x1f6020, '_nextspritesect': 0x1f9ca0,
        '_headspritestat': 0x28811c, '_prevspritestat': 0x1fdca0,
        '_nextspritestat': 0x1fbca0}
ORIGINAL_FUNCTIONS = {'insertspritesect_': 0x508cd, 'insertspritestat_': 0x5096b}


def wrapper_match(exe, obj):
    code, refs = bind_leaf_details(obj, 'insertsprite_', DATA, address=BASE,
                                  functions=ORIGINAL_FUNCTIONS)
    if code != exe[0x75eb8:0x75ecd]:
        raise ValueError('Insertion wrapper does not match all 21 bytes')
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], BASE)
    return len(refs)


def integration(obj, spawn, original=None):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX,
        UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI,
        UC_X86_REG_EBP, UC_X86_REG_ESP, UC_X86_REG_EIP, UC_X86_REG_EFLAGS)
    segments, publics = read_object(obj)
    if publics != [(1, 0, 'insertsprite_'), (1, 21, 'insertspritesect_'), (1, 175, 'insertspritestat_')]:
        raise ValueError('Unexpected generated insertion-group layout')
    if len(segments[1]['data']) != 328:
        raise ValueError('Unexpected insertion-group size')
    generated_functions = {name: BASE + offset for seg, offset, name in publics}
    loaded_data = {name: offset + 0x80000 for name, offset in DATA.items()}
    results = []
    for name, sector, status, free, occupied in [
            ('empty_targets', 5, 9, [0, 1, 2], False),
            ('occupied_targets', 5, 9, [0, 1, 2], True),
            ('last_free', 5, 9, [3], True),
            ('full', 5, 9, [], False),
            ('bad_sector', 1024, 9, [0, 1], False),
            ('bad_status', 5, 1024, [0, 1], False)]:
        for call_spawn in (False, True):
            memory = bytearray(0x400000)
            if original is None:
                for seg, offset, symbol in publics:
                    code, _ = bind_leaf_details(obj, symbol, loaded_data, address=BASE + offset,
                                               functions=generated_functions)
                    memory[BASE + offset:BASE + offset + len(code)] = code
            else:
                # Oracle instructions are executed only; never output or counted as source.
                memory[BASE:0x50a09] = original[BASE:0x50a09]
                memory[0x4abbf:0x4abc5] = original[0x4abbf:0x4abc5]
            spawn_code, _ = bind_spawn(spawn, loaded=True)
            memory[0x11073:0x11073 + len(spawn_code)] = spawn_code
            def put(fmt, address, value):
                struct.pack_into('<' + fmt, memory, address, value)
            def get(fmt, address):
                return struct.unpack_from('<' + fmt, memory, address)[0]
            sprite_base = loaded_data['_sprite']
            memory[sprite_base - 44:sprite_base + 10 * 44] = b'\xa5' * (11 * 44)
            for suffix in ('sect', 'stat'):
                heads = loaded_data['_headsprite' + suffix]
                prev = loaded_data['_prevsprite' + suffix]
                nxt = loaded_data['_nextsprite' + suffix]
                memory[heads:heads + 2050] = b'\xff' * 2050
                memory[prev:prev + 8192] = b'\xff' * 8192
                memory[nxt:nxt + 8192] = b'\xff' * 8192
                put('h', heads + 2048, free[0] if free else -1)
                for i, slot in enumerate(free):
                    put('h', prev + 2 * slot, free[i - 1] if i else -1)
                    put('h', nxt + 2 * slot, free[i + 1] if i + 1 < len(free) else -1)
                    put('h', sprite_base + slot * 44 + (24 if suffix == 'sect' else 26), 1024)
                if occupied:
                    target, slot = (5, 7) if suffix == 'sect' else (9, 8)
                    put('h', heads + 2 * target, slot)
                    put('h', sprite_base + slot * 44 + (24 if suffix == 'sect' else 26), target)
            template = bytearray((i * 37 + 11) & 255 for i in range(31))
            struct.pack_into('<h', template, 21, status)
            memory[0x82bfe:0x82bfe + 31] = template
            position = struct.pack('<3i', 12345, -23456, -34567)
            memory[0x380000:0x38000c] = position
            memory[0x26cf9f:0x26cfa4] = b'\xff' * 5
            uc = Uc(UC_ARCH_X86, UC_MODE_32)
            uc.mem_map(0, len(memory))
            uc.mem_write(0, bytes(memory))
            def model_insert(suffix, target):
                heads, prev, nxt = [loaded_data['_' + prefix + suffix] for prefix in ('headsprite', 'prevsprite', 'nextsprite')]
                if target >= 1024 or get('h', heads + 2048) == -1:
                    return -1
                slot = get('h', heads + 2048)
                next_free = get('h', nxt + slot * 2)
                put('h', heads + 2048, next_free)
                if next_free >= 0:
                    put('h', prev + next_free * 2, -1)
                old_head = get('h', heads + target * 2)
                put('h', prev + slot * 2, -1)
                put('h', nxt + slot * 2, old_head)
                if old_head >= 0:
                    put('h', prev + old_head * 2, slot)
                put('h', heads + target * 2, slot)
                put('h', sprite_base + slot * 44 + (24 if suffix == 'sect' else 26), target)
                return slot
            status_result = model_insert('stat', status)
            result = model_insert('sect', sector)
            if call_spawn:
                dst = sprite_base + result * 44
                memory[dst:dst + 12] = position
                for src, off, width in FIELDS:
                    memory[dst + off:dst + off + width] = template[src:src + width]
                old = 0xa0a2c + result * 12
                memory[old:old + 12] = position
                memory[0x26cfa0 + (result >> 3)] &= ~(1 << (result & 7))
            saved = ((UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
                     if call_spawn else (UC_X86_REG_EBX,))
            for reg in saved:
                uc.reg_write(reg, 0x12345678)
            uc.reg_write(UC_X86_REG_EAX, 0 if call_spawn else sector)
            uc.reg_write(UC_X86_REG_EDX, 0x380000 if call_spawn else status)
            if call_spawn:
                uc.reg_write(UC_X86_REG_EBX, sector)
            uc.reg_write(UC_X86_REG_ESP, 0x3ff000)
            uc.reg_write(UC_X86_REG_EFLAGS, 2)
            uc.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
            uc.emu_start(0x11073 if call_spawn else BASE, 0x3fff00, count=10000)
            assert uc.reg_read(UC_X86_REG_EIP) == 0x3fff00
            assert uc.reg_read(UC_X86_REG_ESP) == 0x3ff004
            assert all(uc.reg_read(reg) == 0x12345678 for reg in saved)
            assert uc.reg_read(UC_X86_REG_EAX) == result & 0xffffffff
            assert bytes(uc.mem_read(0, 0x3f0000)) == bytes(memory[:0x3f0000])
            results.append(dict(case=name, compiled_spawn=call_spawn, status_result_ignored=status_result,
                                result=result, whole_nonstack_memory_equal=True))
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('insertion_object', type=Path)
    parser.add_argument('spawn_object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.insertion_object.read_bytes()
    if hashlib.sha256(exe).hexdigest() != EXPECTED:
        raise ValueError('Unsupported executable hash')
    refs = wrapper_match(exe, obj)
    spawn_report = verify_spawn(args.executable, args.spawn_object)
    result = dict(executable_sha256=EXPECTED, insertion_object_sha256=hashlib.sha256(obj).hexdigest(),
                  spawn_object_sha256=spawn_report['object_sha256'], wrapper_entry=hex(BASE),
                  exact_wrapper_bytes=21, wrapper_le_targets=refs, wrapper_calls=2,
                  list_helpers_exact=False, generated_group_bytes=328,
                  generated_public_offsets={'insertsprite_': 0, 'insertspritesect_': 21, 'insertspritestat_': 175},
                  original_list_helper_offsets={'insertspritesect_': 21, 'insertspritestat_': 179},
                  no_resolved_branch_patching=True, no_external_stubs=True,
                  integration_cases=integration(obj, args.spawn_object.read_bytes()),
                  original_instruction_oracle_cases=integration(obj, args.spawn_object.read_bytes(), image(exe)))
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: exact21-byte wrapper; 12 compiled insertion/spawn cases plus 12 original-oracle cases, no stubs')
