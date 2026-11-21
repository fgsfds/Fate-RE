"""Differential and exact checks for the encounter tile-latch phase."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from capstone import Cs, CS_ARCH_X86, CS_MODE_32, x86_const
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES,
                           LEAF_CODE_SLICES, bind_leaf_details,
                           parsed_leaf_object, verify_leaf_relocations)
from verify_c_suite import OBJECT_NAMES

ROLES = ('encounter_latch_', 'encounter_latch_index_',
         'encounter_latch_zero_', 'encounter_latch_tag_')
ENTRY, RAW, SIZE = 0x1e1b0, 0x437b0, 138
HANDOFF = bytes.fromhex('668b35f62701006685f6')
HANDOFF_SIZE = 10
DATA_SIZE = 0x360000
STACK, STACK_STOP, END = 0x3fe000, 0x3fff00, 0x1e244
PHASE_END = ENTRY + SIZE
OBJ_NAME = 'enclatch'
EXPECTED_PUBLIC = ((1, 160, 'encounter_latch_context_'),)
SAVED_REGS = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI,
              UC_X86_REG_EDX, UC_X86_REG_ECX, UC_X86_REG_EBX)
ALL_REGS = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
            UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
# Independent addresses from the frozen original DATA map.
DATA = {'first_trigger_sprite': 0x7494e, 'second_trigger_state': 0x127f6,
        'second_actor_kind': 0x7f0df, 'second_actor_mode': 0x7f6be,
        'sprite': 0x2040a0}
SPRITE_STRIDE, SPRITE_TILE, SPRITE_LOTAG = 44, 14, 38
ACTIVATE, PLAY_SOUND = 0x28710, 0x34f79


def read_i(mem, addr, fmt):
    return struct.unpack('<' + fmt, mem.mem_read(addr, struct.calcsize('<' + fmt)))[0]


def put(mem, addr, fmt, value):
    mem.mem_write(addr, struct.pack('<' + fmt, value))


def validate_handoff(data):
    if bytes(data) != HANDOFF:
        raise ValueError('original MOV SI/TEST SI handoff differs')


def natural_order(parts):
    if len(parts) != 4:
        raise ValueError('expected four registered latch roles')
    return parts[0] + parts[2] + parts[1] + parts[3]


def linked_order(parts):
    if len(parts) != 4:
        raise ValueError('expected four registered latch roles')
    return parts[0] + parts[1] + parts[2] + parts[3]


def _rel32(site, target):
    return struct.pack('<i', target - (ENTRY + site + 5))


def edge_fixture():
    """Small instruction-aligned fixture for unit-testing transfer guards."""
    code = bytearray(b'\x90' * (SIZE + HANDOFF_SIZE))
    code[SIZE:] = HANDOFF
    code[0x16:0x18] = b'\x75\x72'  # 1e1c6 -> 1e23a
    code[0x22:0x24] = b'\x74\x66'  # 1e1d2 -> 1e23a
    code[0x2e:0x30] = b'\x74\x07'  # 1e1de -> 1e1e7
    for site, target in ((0x4a, ACTIVATE), (0x56, ACTIVATE),
                         (0x62, PLAY_SOUND), (0x72, PLAY_SOUND)):
        code[site:site+5] = b'\xe8' + _rel32(site, target)
    code[0x37:0x3c] = bytes.fromhex('bb03000000')
    code[0x67:0x6c] = bytes.fromhex('b88e000000')
    return bytes(code)


def validate_transfers(code, handoff=HANDOFF):
    code = bytes(code)
    if len(code) != SIZE + HANDOFF_SIZE:
        raise ValueError('phase plus handoff extent differs')
    if handoff == HANDOFF:
        validate_handoff(code[SIZE:])
    elif bytes(code[SIZE:]) != bytes(handoff):
        raise ValueError('loaded handoff differs from pinned image')
    reader = Cs(CS_ARCH_X86, CS_MODE_32)
    reader.detail = True
    insns = tuple(reader.disasm(code, ENTRY))
    if not insns or sum(i.size for i in insns) != len(code):
        raise ValueError('phase/handoff instruction decoding incomplete')
    starts = {i.address for i in insns} | {ENTRY + len(code)}
    if PHASE_END not in starts or END not in starts:
        raise ValueError('phase or stop boundary splits an instruction')
    exits, internal, calls = {}, {}, {}
    for ins in insns:
        if ins.address >= PHASE_END:
            continue
        if ins.mnemonic.startswith('ret'):
            raise ValueError('private return in latch phase')
        if ins.mnemonic.startswith('j') or ins.mnemonic == 'call':
            if len(ins.operands) != 1 or ins.operands[0].type != x86_const.X86_OP_IMM:
                raise ValueError('indirect phase transfer')
            target = ins.operands[0].imm
            if target not in starts and target not in (ACTIVATE, PLAY_SOUND):
                raise ValueError('transfer target is not instruction aligned or registered')
            if ins.mnemonic == 'call':
                calls[ins.address] = target
            elif target == PHASE_END:
                exits[ins.address] = target
            elif ENTRY <= target < PHASE_END:
                internal[ins.address] = target
            else:
                raise ValueError('unexpected latch phase branch target')
    if exits != {0x1e1c6: PHASE_END, 0x1e1d2: PHASE_END}:
        raise ValueError('unexpected latch phase exits')
    if internal != {0x1e1de: 0x1e1e7}:
        raise ValueError('unexpected internal latch branch')
    if calls != {0x1e1fa: ACTIVATE, 0x1e206: ACTIVATE,
                 0x1e212: PLAY_SOUND, 0x1e222: PLAY_SOUND}:
        raise ValueError('unexpected latch phase calls')


def validate_slice_boundaries(code, ranges):
    decoded = tuple(Cs(CS_ARCH_X86, CS_MODE_32).disasm(code, 0))
    if not decoded or sum(i.size for i in decoded) != len(code):
        raise ValueError('complete compiler public cannot be decoded')
    boundaries = {i.address for i in decoded} | {len(code)}
    for start, end in ranges:
        if start not in boundaries or end not in boundaries:
            raise ValueError('compiler slice boundary splits an instruction')


def bind(executable, build):
    if OBJECT_NAMES.get(ROLES[0]) != OBJ_NAME or any(
            OBJECT_NAMES.get(role) != OBJ_NAME for role in ROLES):
        raise ValueError('unexpected latch object registration')
    blob = (build / (OBJ_NAME + '.obj')).read_bytes()
    segments, publics, _externals, _flats, fixups = parsed_leaf_object(blob)
    if publics != EXPECTED_PUBLIC or segments[1]['cls'] != 'CODE':
        raise ValueError('latch private public or OMF segment layout changed')
    code_segment = segments[1]['data']
    if len(code_segment) != 1409:
        raise ValueError('latch object extent differs from the pinned 160+1249 layout')
    validate_slice_boundaries(code_segment[160:],
                              [LEAF_CODE_SLICES[role][1:3] for role in ROLES])
    pointers = read_le_fixups(executable)['pointers']
    raw_parts, loaded_parts, reports = [], [], []
    cursor = RAW
    for role in ROLES:
        raw, size = LEAVES[role]
        if raw != cursor or size <= 0:
            raise ValueError(f'{role} registration is not contiguous in linked order')
        cursor += size
        context, start, end, extent = LEAF_CODE_SLICES[role]
        if context != 'encounter_latch_context_' or extent != 1249:
            raise ValueError(f'{role} compiler slice registration changed')
        if end - start != size or start < 0 or end > extent:
            raise ValueError(f'{role} compiler slice extent differs from registration')
        object_start = EXPECTED_PUBLIC[0][1] + start
        selected = code_segment[object_start:object_start + size]
        if len(selected) != size:
            raise ValueError(f'{role} compiler slice falls outside the registered public')
        placed = raw - 0x25600
        exact, refs = bind_leaf_details(blob, role, DATA_OFFSETS,
                                        address=placed, functions=FUNCTION_ADDRESSES)
        reference = executable[raw:raw + size]
        normalized = bytearray(reference)
        for fix in fixups:
            if fix.segment != 1 or not object_start <= fix.offset < object_start + size:
                continue
            rel = fix.offset - object_start
            if rel + fix.width > size:
                raise ValueError(f'{role} relocation crosses its compiler slice')
            normalized[rel:rel + fix.width] = selected[rel:rel + fix.width]
        if len(reference) != size or exact != reference or selected != bytes(normalized):
            raise ValueError(f'{role} raw original bytes or object fixups differ')
        verify_leaf_relocations(exact, refs, pointers, placed)
        loaded, _ = bind_leaf_details(blob, role,
                                      {name: DS + value for name, value in DATA_OFFSETS.items()},
                                      address=placed, functions=FUNCTION_ADDRESSES)
        raw_parts.append(exact)
        loaded_parts.append(loaded)
        reports.append({'role': role, 'bytes': size, 'LE_sites': len(refs)})
    if cursor != RAW + SIZE or sum(report['LE_sites'] for report in reports) != 8:
        raise ValueError('latch linked span or LE-site total differs')
    if tuple(report['bytes'] for report in reports) != (119, 10, 2, 7):
        raise ValueError('latch role extents differ')
    # The two role-sensitive instructions are pinned independently by decoded operands.
    checks = ((1, 'movsx', 'eax, word ptr [0x7494e]'),
              (1, 'imul', 'eax, eax, 0x2c'),
              (2, 'xor', 'ecx, ecx'),
              (3, 'mov', 'word ptr [eax + 0x2040c6], cx'))
    for part_index, mnemonic, operand in checks:
        decoded = tuple(Cs(CS_ARCH_X86, CS_MODE_32).disasm(raw_parts[part_index],
                                                            LEAVES[ROLES[part_index]][0] - 0x25600))
        if not any(i.mnemonic == mnemonic and i.op_str == operand for i in decoded):
            raise ValueError(f'{ROLES[part_index]} no longer has required {mnemonic} role')
    linked = linked_order(loaded_parts)
    natural = natural_order(loaded_parts)
    raw_phase = executable[RAW:RAW + SIZE]
    raw_handoff = executable[RAW + SIZE:RAW + SIZE + HANDOFF_SIZE]
    validate_handoff(raw_handoff)
    if len(raw_phase) != SIZE:
        raise ValueError('truncated original latch phase')
    loaded_image = image(executable)
    loaded_handoff = loaded_image[PHASE_END:END]
    validate_transfers(linked + loaded_handoff, handoff=loaded_handoff)
    validate_transfers(natural + loaded_handoff, handoff=loaded_handoff)
    original_loaded = loaded_image[ENTRY:END]
    if len(original_loaded) != SIZE + HANDOFF_SIZE:
        raise ValueError('loaded original handoff extent differs')
    validate_transfers(original_loaded, handoff=loaded_handoff)
    return original_loaded, linked + loaded_handoff, natural + loaded_handoff, hashlib.sha256(blob).hexdigest(), reports


def make_cases():
    cases = []
    for tile in (0x567, 0x568, 0x569):
        for state in (-32768, 0, 1, 3, 32767):
            for kind in (0, 3, 4, 255):
                for old_mode in (1, 255):
                    for sprite_id in (0, 1, 4095):
                        cases.append({'tile': tile, 'state': state, 'kind': kind,
                                      'old_mode': old_mode, 'sprite_id': sprite_id,
                                      'lotag': 0x1234})
    return cases


def expected_active(case):
    return case['tile'] == 0x568 and case['state'] != 3


def execute(memory, body, case, gp_inputs, saved_regs, flags):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)
    sprite_id = case['sprite_id']
    sprite = DS + DATA['sprite'] + SPRITE_STRIDE * sprite_id
    put(cpu, DS + DATA['first_trigger_sprite'], 'h', sprite_id)
    put(cpu, sprite + SPRITE_TILE, 'h', case['tile'])
    put(cpu, sprite + SPRITE_LOTAG, 'h', case['lotag'])
    put(cpu, DS + DATA['second_trigger_state'], 'h', case['state'])
    put(cpu, DS + DATA['second_actor_kind'], 'B', case['kind'])
    put(cpu, DS + DATA['second_actor_mode'], 'B', case['old_mode'])
    calls = []

    def ret():
        sp = cpu.reg_read(UC_X86_REG_ESP)
        dest = read_i(cpu, sp, 'I')
        cpu.reg_write(UC_X86_REG_ESP, sp + 4)
        cpu.reg_write(UC_X86_REG_EIP, dest)

    def hook(_emu, address, _size, _user_data):
        if address == ACTIVATE:
            record = tuple(cpu.reg_read(r) for r in
                           (UC_X86_REG_EAX, UC_X86_REG_EDX,
                            UC_X86_REG_EBX, UC_X86_REG_ECX))
            calls.append(('activate_sector_', record))
            cpu.reg_write(UC_X86_REG_EAX, 0xa1000001 + len(calls))
            ret()
        elif address == PLAY_SOUND:
            record = tuple(cpu.reg_read(r) for r in
                           (UC_X86_REG_EAX, UC_X86_REG_EDX,
                            UC_X86_REG_EBX, UC_X86_REG_ECX))
            calls.append(('play_sound_', record))
            for reg, value in zip((UC_X86_REG_EAX, UC_X86_REG_EDX,
                                   UC_X86_REG_EBX, UC_X86_REG_ECX),
                                  (0xb1000001, 0xb2000002,
                                   0xb3000003, 0xb4000004)):
                cpu.reg_write(reg, value)
            ret()

    hook_handle = cpu.hook_add(UC_HOOK_CODE, hook)
    frame = (b'\xa7' * 184 + struct.pack('<6I', *saved_regs) +
             struct.pack('<I', STACK_STOP) + b'\x5c' * 64)
    cpu.mem_write(STACK, frame)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg, value in zip(ALL_REGS, gp_inputs):
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_EFLAGS, flags)
    try:
        cpu.emu_start(ENTRY, END, count=2000)
        if cpu.reg_read(UC_X86_REG_EIP) != END:
            raise AssertionError('latch phase did not stop after original TEST SI')
        if cpu.reg_read(UC_X86_REG_ESP) != STACK:
            raise AssertionError('latch phase changed ESP')
        if cpu.mem_read(STACK, len(frame)) != frame:
            raise AssertionError('latch stack frame or caller guard changed')
        registers = tuple(cpu.reg_read(r) for r in ALL_REGS)
        flags_out = cpu.reg_read(UC_X86_REG_EFLAGS) & 0x8c5
        data_digest = hashlib.sha256(cpu.mem_read(DS, DATA_SIZE)).hexdigest()
        state = read_i(cpu, DS + DATA['second_trigger_state'], 'h')
        mode = read_i(cpu, DS + DATA['second_actor_mode'], 'B')
        tag = read_i(cpu, sprite + SPRITE_LOTAG, 'h')
        return (tuple(calls), data_digest, registers, flags_out,
                cpu.reg_read(UC_X86_REG_ESP), bytes(cpu.mem_read(STACK, len(frame))),
                state, mode, tag)
    finally:
        cpu.hook_del(hook_handle)
        del cpu


def assert_semantics(case, observed):
    active = expected_active(case)
    calls, _digest, _regs, _flags, _esp, _frame, state, mode, tag = observed
    expected_state = 3 if active else case['state']
    expected_mode = (2 if case['kind'] != 3 else case['old_mode']) if active else case['old_mode']
    expected_tag = 0 if active else case['lotag']
    if (state, mode, tag) != (expected_state, expected_mode, expected_tag):
        raise AssertionError(f'wrong latch state/mode/tag for {case}')
    if not active:
        if calls:
            raise AssertionError(f'inactive latch unexpectedly called callees: {calls!r}')
        return
    if len(calls) != 4 or [c[0] for c in calls] != [
            'activate_sector_', 'activate_sector_', 'play_sound_', 'play_sound_']:
        raise AssertionError(f'active latch call sequence differs: {calls!r}')
    first, second, sound_a, sound_b = (c[1] for c in calls)
    if first[0] != 150 or first[3] != 0:
        raise AssertionError('first activation EAX/ECX contract differs')
    if second[0] != 153 or second[1] != 0 or second[3] != 0:
        raise AssertionError('second activation EAX/EDX/ECX contract differs')
    if sound_a != (126, 0, 0, 0) or sound_b != (142, 0, 0, 0):
        raise AssertionError('sound argument registers differ')


def mutate(candidate, which):
    code = bytearray(candidate)
    decoded = tuple(Cs(CS_ARCH_X86, CS_MODE_32).disasm(candidate, ENTRY))
    if which == 'state':
        address, mnemonic, operand, byte_index, value = 0x1e1e7, 'mov', 'ebx, 3', 1, 4
    elif which == 'sound':
        address, mnemonic, operand, byte_index, value = 0x1e217, 'mov', 'eax, 0x8e', 1, 0x8f
    else:
        raise ValueError('unknown latch mutation')
    ins = next((i for i in decoded if i.address == address), None)
    if ins is None or ins.mnemonic != mnemonic or ins.op_str != operand:
        raise ValueError(f'{which} machine-code mutation anchor changed')
    code[address - ENTRY + byte_index] = value
    return bytes(code)


def run(executable, build, output):
    if hashlib.sha256(executable).hexdigest() != TARGET_SHA256:
        raise ValueError('unsupported pinned executable')
    original, candidate, natural, object_hash, reports = bind(executable, build)
    memory = image(executable)
    cases = make_cases()
    gp_sets = ((0x10203040, 0x21314151, 0x32425262, 0x43536373,
                0x54647484, 0x65758595, 0x768696a6),
               (0xfedcba98, 0xedcba987, 0xdcba9876, 0xcba98765,
                0xba987654, 0xa9876543, 0x98765432))
    saved = (0x0bad0001, 0x1bad0002, 0x2bad0003,
             0x3bad0004, 0x4bad0005, 0x5bad0006)
    for index, case in enumerate(cases):
        gp = gp_sets[index % len(gp_sets)]
        flags = 0x202 if index & 1 else 0x8d7
        expected = execute(memory, original, case, gp, saved, flags)
        actual = execute(memory, candidate, case, gp, saved, flags)
        ordered = execute(memory, natural, case, gp, saved, flags)
        if actual != expected:
            raise AssertionError(f'C/native latch mismatch: {case}')
        if ordered != expected:
            raise AssertionError(f'natural compiler order mismatch: {case}')
        assert_semantics(case, expected)

    control = next(c for c in cases if c['tile'] == 0x568 and c['state'] == 0
                   and c['kind'] == 0 and c['old_mode'] == 1 and c['sprite_id'] == 4095)
    gp, flags = gp_sets[0], 0x202
    baseline = execute(memory, original, control, gp, saved, flags)
    assert_semantics(control, baseline)
    controls = []
    for name in ('state', 'sound'):
        mutant = execute(memory, mutate(candidate, name), control, gp, saved, flags)
        if name == 'state':
            identities = [(call[0], call[1][0]) for call in mutant[0]]
            if (mutant[6] != 4 or mutant[1] == baseline[1]
                    or identities != [('activate_sector_',150), ('activate_sector_',153),
                                      ('play_sound_',126), ('play_sound_',142)]):
                raise AssertionError('state mutation did not reach state 4 on the active path')
        elif (mutant[0][:3] != baseline[0][:3]
              or mutant[0][3:] != (('play_sound_', (143,0,0,0)),)
              or mutant[1:] != baseline[1:]):
            raise AssertionError('sound mutation did not isolate sound 143 with unchanged DATA')
        controls.append(name)

    result = {'status': 'PASS', 'cases': len(cases), 'controls': controls,
              'phase_bytes': SIZE, 'LE_sites': 8, 'DS_bytes': DATA_SIZE,
              'object_sha256': object_hash, 'natural_order_check': 'PASS',
              'roles': reports}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--build', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(run(args.exe.read_bytes(), args.build, args.output), indent=2))


if __name__ == '__main__':
    main()
