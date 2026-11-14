"""Unmatched sequence-start candidate against bounded original-instruction fixtures."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED, image
from verify_init_object_sequences import verify as verify_initializer, compiled_descriptors
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from le_fixups import read_le_fixups
from verify_advance_sequences import bind as bind_advance
from verify_add_listed_sprite import bind as bind_append

ADDRESS, SIZE = 0x11fdd, 1017
DATA = {'_start_sequence_sprites': 0x2040a0, '_start_sequence_sectors': 0x27c3a0,
        '_start_sequence_rows': 0x6807c, '_start_sequence_count': 0x7dee0,
        '_start_sequence_list': 0x67a3c, '_start_sequence_tile_heights': 0x1f4020,
        '_start_sequence_error_buffer': 0x67e3c, '_start_sequence_overflow_text': 0x1b0}
FUNCTIONS = {'sequence_random_': 0x602d0, 'sequence_sound_': 0x34f79,
             'format_sequence_error_': 0x601f3, 'report_sequence_error_': 0x26a03,
             'sequence_spawn_': 0x11073, 'sequence_move_': 0x339b9,
             'sequence_append_movement_': 0x134c2}


def bind(blob, loaded=False, address=ADDRESS):
    return bind_leaf_details(blob, 'start_sequence_',
        {k: v + (0x80000 if loaded else 0) for k, v in DATA.items()},
        address=address, functions=FUNCTIONS)


def fixtures(exe, blob, advance, append, descriptors, assembled=None):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import (UC_X86_REG_EAX as AX, UC_X86_REG_EBX as BX,
        UC_X86_REG_ECX as CX, UC_X86_REG_EDX as DX, UC_X86_REG_ESI as SI,
        UC_X86_REG_EDI as DI, UC_X86_REG_EBP as BP, UC_X86_REG_ESP as SP,
        UC_X86_REG_EIP as IP)
    memory = image(exe)
    candidate_address = 0x380000 if assembled is None else ADDRESS
    compiled = bind(blob, True, candidate_address)[0] if assembled is None else assembled
    advance_code, _ = bind_advance(advance, True)
    append_code, _ = bind_append(append, True)
    base_row = [1516, 1516, 1516, 29] + [0] * 56
    cases = [('zero', 0, base_row, 0, 1, 0, 0),
             ('duplicate', 28, base_row, 1, 1, 0, 0),
             ('normal', 28, base_row, 0, 1, 0, 0),
             ('centered', 28, base_row, 0, 129, 0, 0),
             ('overflow', 28, base_row, 511, 1, 0, 0)]
    for tile in (0, -1, 807, 803, 827, 910, 771, 866):
        row = base_row[:]; row[0] = tile
        for extra in (0, 0x2000):
            cases.append((f'tile_{tile}_extra_{extra}', 1, row, 0, 129, 1, extra))
    for speed in (0, 3):
        row = base_row[:]; row[4:12] = [7, 2, speed, 1, 8, 3, speed, 0]
        row[52:] = list(range(10, 18))
        cases.append((f'debris_{speed}', 1, row, 0, 129, 0, 0))
    for key, desc in descriptors.items():
        row = [desc[n] for n in ('start', 'end', 'final', 'next')] + desc['debris'] + desc['sounds']
        cases.append((f'recovered_{key}', int(key), row, 0, 1, 0, 0))
    results = []
    for name, seq, row, before, cstat, owner, extra in cases:
        states = []
        for source in (False, True):
            uc = Uc(UC_ARCH_X86, UC_MODE_32); uc.mem_map(0, len(memory)); uc.mem_write(0, memory)
            if source: uc.mem_write(candidate_address, compiled)
            uc.mem_write(0x123d6, advance_code); uc.mem_write(0x134c2, append_code)
            def put(fmt, addr, *args): uc.mem_write(addr, struct.pack('<' + fmt, *args))
            def get(fmt, addr): return struct.unpack('<' + fmt, uc.mem_read(addr, struct.calcsize(fmt)))[0]
            for key, desc in descriptors.items():
                values = [desc[n] for n in ('start', 'end', 'final', 'next')] + desc['debris'] + desc['sounds']
                put('60h', 0xe807c + int(key) * 120, *values)
            put('60h', 0xe807c + seq * 120, *row)
            put('h', 0xfdee0, before); put('h', 0x82be8, 0)
            if name == 'duplicate': put('h', 0xe7a3e, 44)
            s = 0x2840a0 + 44 * 44
            uc.mem_write(s, b'\0' * 44)
            put('3i', s, 100, 200, 300); put('Hh', s + 12, cstat, 1515)
            put('BB', s + 20, 37, 39); put('h', s + 24, 2)
            put('h', s + 30, owner); put('HHH', s + 38, seq * 256 + 100, 0, extra)
            put('i', 0x2fc3a8 + 80, 9000)
            calls = []; random_index = [0]; spawn_index = [100]
            def hook(machine, addr, size, user):
                if addr not in (0x602d0, 0x34f79, 0x601f3, 0x26a03, 0x11073, 0x339b9): return
                esp = machine.reg_read(SP); pop = 4
                if addr == 0x602d0:
                    value = (random_index[0] * 7919 + 1234) & 32767; random_index[0] += 1
                    machine.reg_write(AX, value); calls.append(['random', value])
                elif addr == 0x34f79:
                    calls.append(['sound'] + [machine.reg_read(r) for r in (AX, DX, BX, CX)])
                elif addr == 0x601f3:
                    assert struct.unpack('<2I', machine.mem_read(esp + 4, 8)) == (0xe7e3c, 0x801b0)
                    machine.mem_write(0xe7e3c, b'fixture\0'); calls.append(['format'])
                elif addr == 0x26a03:
                    assert machine.reg_read(AX) == 0xe7e3c; calls.append(['report'])
                elif addr == 0x11073:
                    idx = spawn_index[0]; spawn_index[0] += 1
                    typ, ptr, sect = [machine.reg_read(r) for r in (AX, DX, BX)]
                    pos = bytes(machine.mem_read(ptr, 12)); dest = 0x2840a0 + idx * 44
                    machine.mem_write(dest, b'\0' * 44); machine.mem_write(dest, pos)
                    put('Hh', dest + 12, 128 if idx & 1 else 0, 500)
                    put('B', dest + 21, 10); put('h', dest + 24, sect); put('h', 0x274020 + 1000, 20)
                    calls.append(['spawn', typ, list(struct.unpack('<3i', pos)), sect, idx])
                    machine.reg_write(AX, idx)
                else:
                    args = [machine.reg_read(r) for r in (AX, DX, BX, CX)]
                    args += list(struct.unpack('<3I', machine.mem_read(esp + 4, 12)))
                    calls.append(['move'] + args); pop += 12
                ret = get('I', esp); machine.reg_write(SP, esp + pop); machine.reg_write(IP, ret)
            uc.hook_add(UC_HOOK_CODE, hook)
            def run(entry):
                for reg in (BX, CX, DX, SI, DI, BP): uc.reg_write(reg, 0x12345678)
                uc.reg_write(AX, 44); uc.reg_write(SP, 0x3ff000); put('I', 0x3ff000, 0x3fff00)
                actual_entry = candidate_address if source and entry == ADDRESS else entry
                uc.emu_start(actual_entry, 0x3fff00, count=200000)
                assert uc.reg_read(IP) == 0x3fff00 and uc.reg_read(SP) == 0x3ff004, (name, source, hex(uc.reg_read(IP)), hex(uc.reg_read(SP)))
                assert all(uc.reg_read(r) == 0x12345678 for r in (BX, CX, DX, SI, DI, BP))
            run(ADDRESS)
            if name == 'recovered_28':
                # Actual compiled advancement, with a second explicit start operation.
                trace = []
                def state():
                    return [get('h', s + 14), get('H', s + 38) >> 8, get('h', 0xfdee0), get('H', s + 12)]
                trace.append(state())
                run(ADDRESS); trace.append(state())  # duplicate ignored while active
                run(0x123d6); trace.append(state())
                run(0x123d6); trace.append(state())  # idle does not start stage29
                run(ADDRESS); trace.append(state())
                for _ in range(5): run(0x123d6); trace.append(state())
                run(ADDRESS); trace.append(state())  # no sequence remains
                assert trace == [[1516, 28, 1, 1], [1516, 28, 1, 1],
                                 [1516, 29, 0, 1], [1516, 29, 0, 1],
                                 [1517, 29, 1, 1], [1518, 29, 1, 1],
                                 [1519, 29, 1, 1], [1520, 29, 1, 1],
                                 [1521, 29, 1, 1], [1521, 0, 0, 1], [1521, 0, 0, 1]]
                calls.append(['door_trace', trace])
            states.append((bytes(uc.mem_read(0x80000, 0x2f0000)), calls))
        assert states[0] == states[1], name
        results.append(dict(case=name, source_and_original_agree=True, calls=states[0][1]))
    return results


def check(executable, obj, advance_obj, append_obj, initializer_obj, require_exact=False,
          assembly_directory=None, c_inventory=None):
    exe, blob = Path(executable).read_bytes(), Path(obj).read_bytes()
    if hashlib.sha256(exe).hexdigest() != EXPECTED: raise ValueError('Unsupported executable hash')
    code, refs = bind(blob)
    exact = code == exe[ADDRESS + 0x25600:ADDRESS + 0x25600 + SIZE]
    assembled = None
    if assembly_directory is not None:
        from verify_assembly_suite import verify, START_SEQUENCE_POINTERS
        verify(exe, assembly_directory, json.loads(c_inventory.read_text(encoding='utf-8')))
        assembled = bytearray((assembly_directory/'startseq.bin').read_bytes())
        for site, target in START_SEQUENCE_POINTERS.items():
            struct.pack_into('<I', assembled, site, target)
        assembled = bytes(assembled)
    if require_exact and not exact and assembled is None: raise ValueError(f'Unmatched sequence start: {len(code)} generated versus {SIZE} original bytes')
    if exact: verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ADDRESS)
    for binder, path, address, size in ((bind_advance, advance_obj, 0x123d6, 203),
                                        (bind_append, append_obj, 0x134c2, 88)):
        dep_code, dep_refs = binder(Path(path).read_bytes())
        if dep_code != exe[address + 0x25600:address + 0x25600 + size]:
            raise ValueError('Compiled dependency mismatch')
        verify_leaf_relocations(dep_code, dep_refs, read_le_fixups(exe)['pointers'], address)
    initializer = Path(initializer_obj).read_bytes()
    verify_initializer(exe, initializer)
    rows = compiled_descriptors(initializer)
    cases = fixtures(exe, blob, Path(advance_obj).read_bytes(), Path(append_obj).read_bytes(), rows, assembled)
    return dict(executable_sha256=EXPECTED, object_sha256=hashlib.sha256(blob).hexdigest(),
                address=hex(ADDRESS), original_bytes=SIZE, candidate_bytes=len(code),
                c_candidate_exact=exact, exact_code=exact or assembled is not None,
                assembly_executed=assembled is not None,
                reconstructed_bytes_added=SIZE if exact or assembled is not None else 0, cases=cases,
                dependencies_stubbed=['random', 'sound', 'formatter', 'reporter', 'spawn', 'move'],
                compiled_sequence_initializer=True,
                initializer_object_sha256=hashlib.sha256(initializer).hexdigest(),
                compiled_movement_append=True, compiled_sequence_advancement=True,
                advancement_object_sha256=hashlib.sha256(Path(advance_obj).read_bytes()).hexdigest(),
                append_object_sha256=hashlib.sha256(Path(append_obj).read_bytes()).hexdigest(),
                candidate_fixture_address=hex(ADDRESS if assembled is not None else 0x380000),
                original_instructions_are_oracle_only=True)


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('executable', 'object', 'advance_object', 'append_object', 'initializer_object'): p.add_argument(name, type=Path)
    p.add_argument('--output', type=Path, required=True); p.add_argument('--require-exact', action='store_true')
    p.add_argument('--assembly-directory', type=Path); p.add_argument('--c-inventory', type=Path)
    a = p.parse_args()
    if bool(a.assembly_directory) != bool(a.c_inventory):
        p.error('Use both --assembly-directory and --c-inventory')
    result = check(a.executable, a.object, a.advance_object, a.append_object, a.initializer_object,
                   a.require_exact, a.assembly_directory, a.c_inventory)
    a.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(f"PASS: {len(result['cases'])} original/candidate scenarios; exact={result['exact_code']}")
