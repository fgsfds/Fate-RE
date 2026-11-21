"""Strict movement-helper match with original and compiled behavioral fixtures.

The exact append helper executes; geometry interfaces remain explicit stubs.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED, image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from verify_add_listed_sprite import bind as bind_append, ADDRESS as APPEND_ADDRESS
from inspect_demo import inspect_map
from match_objects import read_object
from research_startup import layout

ADDRESS, SIZE = 0x1351a, 405
DATA = {'_move_sprites': 0x2040a0, '_move_tile_heights': 0x1f4020}
FUNCTIONS = {'move_clip_': 0x5291f, 'move_change_sector_': 0x50bc3,
             'move_zrange_': 0x562f9, 'move_add_listed_': 0x134c2}


def map_evidence(path):
    blob = Path(path).read_bytes()
    digest = hashlib.sha256(blob).hexdigest()
    if digest != '812f8deec1af874af4d71ed7bb21ddc70a3d40a2a3844ffa83713156e1a61b1e':
        raise ValueError('Unsupported START.MAP hash')
    survey = inspect_map(blob)
    if survey['structural_errors']:
        raise ValueError('Invalid map structure')
    offset = 20
    for name, size in [('sectors', 40), ('walls', 32), ('sprites', 44)]:
        count = struct.unpack_from('<H', blob, offset)[0]
        offset += 2
        rows = [blob[offset + i * size:offset + (i + 1) * size] for i in range(count)]
        offset += count * size
    candidates = []
    for i, row in enumerate(rows):
        tag = struct.unpack_from('<H', row, 38)[0]
        if tag & 255 == 100:
            candidates.append(dict(sprite=i, picnum=struct.unpack_from('<h', row, 14)[0],
                sector=struct.unpack_from('<h', row, 24)[0], lotag=tag,
                high_tag=tag >> 8, clipdist=row[18], yrepeat=row[21],
                zvel=struct.unpack_from('<h', row, 36)[0]))
    return dict(sha256=digest, raw_map_before_initialization=True, low_tag_100_candidates=candidates)


def bind(blob, loaded=False):
    return bind_leaf_details(blob, 'move_listed_sprite_',
        {name: value + (0x80000 if loaded else 0) for name, value in DATA.items()},
        address=ADDRESS, functions=FUNCTIONS)


def verify(exe,blob):
    if hashlib.sha256(exe).hexdigest()!=EXPECTED:
        raise ValueError('Unsupported executable hash')
    segments,publics=read_object(blob);initialized,_=layout(blob)
    if publics!=[(1,0,'move_listed_sprite_')] or initialized!={1:set(range(SIZE))}:
        raise ValueError('Movement public or initialized extent differs')
    if len(segments[1]['data'])!=SIZE or any(s['data'] for s in segments[2:]):
        raise ValueError('Unexpected movement object payload')
    code,refs=bind(blob)
    if code!=exe[ADDRESS+0x25600:ADDRESS+0x25600+SIZE]:
        raise ValueError('Movement body is not an exact match')
    verify_leaf_relocations(code,refs,read_le_fixups(exe)['pointers'],ADDRESS)
    if len(refs)!=22:
        raise ValueError('Unexpected movement relocation count')
    return code,refs


def exercise(code, append, sector_code=None):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import (UC_X86_REG_EAX, UC_X86_REG_EBX,
        UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI,
        UC_X86_REG_EBP, UC_X86_REG_ESP, UC_X86_REG_EIP)
    scenarios = [('wrong_tag', 99, 0, 5, 1), ('already_moving', 100, 1, 5, 1),
                 ('floor_equal', 100, 0, 5, 0), ('floor_below_threshold', 100, 0, 5, -1),
                 ('activate', 100, 0, 5, 1), ('change_sector', 100, 0, 6, 1),
                 ('negative_sector', 100, 0, -1, 1), ('high_tag_bits', 0x8064, 0, 6, 1)]
    results = []
    for name, tag, zvel, clipped_sector, clearance in scenarios:
        for vx, vy in [(513, -1025), (-1, 255)]:
            uc = Uc(UC_ARCH_X86, UC_MODE_32)
            uc.mem_map(0, 0x400000)
            uc.mem_write(ADDRESS, code)
            uc.mem_write(APPEND_ADDRESS, append)
            sprite, picnum, repeat, radius = 12, 527, 4, 17
            heads, free = 0x30891e, 0x30911e
            prev, next_ = 0x276020, 0x279ca0
            if sector_code is not None:
                for address, body in sector_code.items():
                    uc.mem_write(address, body)
                uc.mem_write(heads+10, struct.pack('<2h', sprite, 13))
                uc.mem_write(free, struct.pack('<h', -1))
                for address in (prev, next_):
                    uc.mem_write(address+2*sprite, struct.pack('<2h', -1, -1))
            record_address = 0x2840a0 + sprite * 44
            original = bytearray(44)
            struct.pack_into('<3i', original, 0, 1000, 2000, 3000)
            struct.pack_into('<2H', original, 12, 0x8001, picnum)
            original[18], original[21] = radius, repeat
            struct.pack_into('<h', original, 24, 5)
            struct.pack_into('<5H', original, 32, 31, 32, zvel, tag, 33)
            struct.pack_into('<H', original, 42, 0x0200)
            uc.mem_write(record_address-16,b'\xa5'*16+bytes(original)+b'\x5a'*16)
            uc.mem_write(0x274020 + picnum * 2, struct.pack('<h', 33))
            height = 33 * repeat * 2
            trace = []
            active = tag & 255 == 100 and zvel == 0
            activated = active and clearance > 0
            def hook(machine, address, size, user):
                if address == APPEND_ADDRESS:
                    assert machine.reg_read(UC_X86_REG_EAX) == sprite
                    trace.append('append')
                    return  # Real source-generated append executes.
                if address in (0x601f3, 0x26a03):
                    raise AssertionError('Unexpected append error path')
                if address not in (0x5291f, 0x50bc3, 0x562f9):
                    return
                esp = machine.reg_read(UC_X86_REG_ESP)
                ret = struct.unpack('<I', machine.mem_read(esp, 4))[0]
                pop = 0
                regs = [machine.reg_read(r) for r in (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)]
                if address == 0x5291f:
                    trace.append('clip')
                    args = struct.unpack('<6i', machine.mem_read(esp + 4, 24))
                    assert args == (vx >> 1, vy >> 1, radius * 2, height, height, 0)
                    for ptr, value, delta in zip(regs[:3], (1000, 2000, 3000), (10, -20, 30)):
                        assert struct.unpack('<i', machine.mem_read(ptr, 4))[0] == value
                        machine.mem_write(ptr, struct.pack('<i', value + delta))
                    assert struct.unpack('<h', machine.mem_read(regs[3], 2))[0] == 5
                    machine.mem_write(regs[3], struct.pack('<h', clipped_sector))
                    pop = 24
                elif address == 0x50bc3:
                    trace.append('change_sector')
                    assert regs[:2] == [sprite, clipped_sector]
                    if sector_code is not None:
                        return
                    machine.mem_write(record_address + 24, struct.pack('<h', clipped_sector))
                else:
                    trace.append('zrange')
                    assert regs == [1010, 1980, 3030, clipped_sector & 0xffffffff]
                    assert struct.unpack('<H', machine.mem_read(record_address + 12, 2))[0] == 0x8000
                    args = struct.unpack('<6I', machine.mem_read(esp + 4, 24))
                    assert args[4:] == (radius * 2, 0)
                    for ptr, value in zip(args[:4], (-500, 0x4000, 3000 + height + clearance, 0x4001)):
                        machine.mem_write(ptr, struct.pack('<i', value))
                    pop = 24
                machine.reg_write(UC_X86_REG_EAX, 0xc003)
                machine.reg_write(UC_X86_REG_ESP, esp + 4 + pop)
                machine.reg_write(UC_X86_REG_EIP, ret)
            uc.hook_add(UC_HOOK_CODE, hook)
            saved = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
            for reg in saved:
                uc.reg_write(reg, 0x12345678)
            uc.reg_write(UC_X86_REG_EAX, sprite)
            uc.reg_write(UC_X86_REG_EDX, vx & 0xffffffff)
            uc.reg_write(UC_X86_REG_EBX, vy & 0xffffffff)
            uc.reg_write(UC_X86_REG_ESP, 0x3ff000)
            uc.mem_write(0x3ff000, struct.pack('<I', 0x3fff00))
            uc.emu_start(ADDRESS, 0x3fff00, count=10000)
            expected = bytearray(original)
            expected_trace = []
            if active:
                struct.pack_into('<2i', expected, 0, 1010, 1980)
                expected_trace.append('clip')
                if clipped_sector >= 0 and clipped_sector != 5:
                    struct.pack_into('<h', expected, 24, clipped_sector)
                    expected_trace.append('change_sector')
                expected_trace.append('zrange')
                if activated:
                    struct.pack_into('<3h', expected, 32, vx >> 8, vy >> 8, 100)
                    struct.pack_into('<H', expected, 42, 0x5200)
                    expected_trace.append('append')
            assert bytes(uc.mem_read(record_address, 44)) == bytes(expected)
            assert uc.mem_read(record_address-16,16)==b'\xa5'*16
            assert uc.mem_read(record_address+44,16)==b'\x5a'*16
            assert trace == expected_trace
            if sector_code is not None:
                changed = 'change_sector' in trace
                expected_heads = (-1, sprite) if changed else (sprite, 13)
                assert uc.mem_read(heads+10,4) == struct.pack('<2h', *expected_heads)
                assert uc.mem_read(free,2) == struct.pack('<h', -1)
                assert uc.mem_read(prev+2*sprite,4) == struct.pack('<2h', -1, sprite if changed else -1)
                assert uc.mem_read(next_+2*sprite,4) == struct.pack('<2h', 13 if changed else -1, -1)
            assert struct.unpack('<h', uc.mem_read(0x82be8, 2))[0] == int(activated)
            assert struct.unpack('<h', uc.mem_read(0xefcbe, 2))[0] == (sprite if activated else 0)
            assert uc.reg_read(UC_X86_REG_EIP) == 0x3fff00
            assert uc.reg_read(UC_X86_REG_ESP) == 0x3ff004
            assert all(uc.reg_read(reg) == 0x12345678 for reg in saved)
            results.append(dict(case=name, vectors=[vx, vy], trace=trace, activated=activated,
                                sprite_hex=bytes(expected).hex()))
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('candidate_object', type=Path)
    parser.add_argument('append_object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--require-exact', action='store_true')
    parser.add_argument('--map', type=Path)
    parser.add_argument('--sector-integration', type=Path, nargs=4,
                        metavar=('ASSEMBLY', 'C_INVENTORY', 'CHANGE_OBJECT', 'TAIL_OWNER'))
    args = parser.parse_args()
    exe, candidate, append_obj = args.executable.read_bytes(), args.candidate_object.read_bytes(), args.append_object.read_bytes()
    if hashlib.sha256(exe).hexdigest() != EXPECTED:
        raise ValueError('Unsupported executable hash')
    raw, refs = verify(exe,candidate)
    exact = True  # verify() above rejects every mismatch, regardless of legacy flag.
    append_raw, append_refs = bind_append(append_obj)
    if append_raw != exe[0x38ac2:0x38b1a]:
        raise ValueError('Append dependency is not an exact match')
    verify_leaf_relocations(append_raw, append_refs, read_le_fixups(exe)['pointers'], APPEND_ADDRESS)
    loaded = image(exe)
    compiled, _ = bind(candidate, loaded=True)
    append_loaded, _ = bind_append(append_obj, loaded=True)
    original_cases = exercise(loaded[ADDRESS:ADDRESS + SIZE], append_loaded)
    compiled_cases = exercise(compiled, append_loaded)
    assert original_cases == compiled_cases
    integrated_cases = 0
    if args.sector_integration:
        import check_spritechange as change
        from check_initksqrt import verified_tail
        directory, inventory, changes, owner = args.sector_integration
        tail = verified_tail(exe, directory, json.loads(inventory.read_text(encoding='utf-8')),
                             owner.read_bytes())
        change_blob = changes.read_bytes()
        change.verify(exe, change_blob)
        wrapper, _ = bind_leaf_details(change_blob, 'changespritesect_',
                                       {k:v+0x80000 for k,v in change.DATA.items()},
                                       address=0x50bc3, functions=change.FUNCTIONS)
        sector_code = {0x4abbf:tail, 0x50bc3:wrapper,
                       0x508cd:loaded[0x508cd:0x5096b],
                       0x50a1d:loaded[0x50a1d:0x50af0]}
        integrated = exercise(compiled, append_loaded, sector_code)
        assert integrated == compiled_cases
        integrated_cases = len(integrated)
    result = dict(executable_sha256=EXPECTED, candidate_object_sha256=hashlib.sha256(candidate).hexdigest(),
                  append_object_sha256=hashlib.sha256(append_obj).hexdigest(), entry=hex(ADDRESS),
                  target_bytes=SIZE, generated_bytes=len(raw), exact_code=exact, reconstructed_bytes_added=SIZE, le_targets=len(refs),
                  original_oracle_cases=original_cases, compiled_cases=compiled_cases,
                  geometry_callees_stubbed=True, append_source_executes=True,
                  exact_sector_integration_cases=integrated_cases)
    if args.map:
        result['start_map'] = map_evidence(args.map)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(f'PASS: 16 original + 16 compiled behavioral fixtures; exact_code={exact}, 405 reconstructed bytes / 22 LE targets')
