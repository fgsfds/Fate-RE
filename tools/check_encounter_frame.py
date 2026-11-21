"""Exact frame entry and return checks for the encounter context."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from capstone import Cs, CS_ARCH_X86, CS_MODE_32
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_c_leaf import (CODE_OFFSETS, DATA_OFFSETS, FUNCTION_ADDRESSES,
                           LEAVES, LEAF_CODE_SLICES, bind_leaf_details,
                           parsed_leaf_object, verify_leaf_relocations)
from verify_c_suite import OBJECT_NAMES

ROLES = ('encounter_entry_save_', 'encounter_initialize_',
         'encounter_release_frame_', 'encounter_restore_return_')
EXPECTED = {
    'encounter_entry_save_': (0x4352e, 0x1df2e, 5, 0, 5),
    'encounter_initialize_': (0x43534, 0x1df34, 39, 5, 44),
    'encounter_release_frame_': (0x43a10, 0x1e410, 6, 1213, 1219),
    'encounter_restore_return_': (0x43a17, 0x1e417, 6, 1219, 1225),
}
PUBLIC_NAME, PUBLIC_START, PUBLIC_SIZE = 'encounter_exit_context_', 160, 1225
OBJECT_NAME = 'encexit'
CODE_FIELDS = {14: 0xde8e, 33: 0xdf0e}
CODE_LOAD_BASE = 0x10000
PUSH_EBP = b'\x55'
POP_EBP = b'\x5d'
FRAME_BYTES, COPY_BYTES, SAVED_COUNT = 184, 160, 6
CALLER_SP, STOP = 0x3fef00, 0x3fff00
GUARD_BYTES = 64
DATA_SIZE = 0x360000
FLAGS_MASK = 0x8d5
GP_REGS = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
           UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
SAVE_REGS = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI,
             UC_X86_REG_EDX, UC_X86_REG_ECX, UC_X86_REG_EBX)


def read_i(mem, addr, fmt):
    return struct.unpack('<' + fmt, mem.mem_read(addr, struct.calcsize('<' + fmt)))[0]


def put(mem, addr, fmt, value):
    mem.mem_write(addr, struct.pack('<' + fmt, value))


def validate_boundaries(public_code, ranges):
    decoded = tuple(Cs(CS_ARCH_X86, CS_MODE_32).disasm(public_code, 0))
    if not decoded or sum(i.size for i in decoded) != len(public_code):
        raise ValueError('complete private public instruction decoding failed')
    boundaries = {i.address for i in decoded} | {len(public_code)}
    for start, end in ranges:
        if start not in boundaries or end not in boundaries:
            raise ValueError('registered C alias splits a source instruction')


def compose_prefix(entry_save, push_ebp, initializer):
    if len(entry_save) != 5 or bytes(push_ebp) != PUSH_EBP or len(initializer) != 39:
        raise ValueError('entry prefix components have unexpected extents')
    return bytes(entry_save) + PUSH_EBP + bytes(initializer)


def compose_return(release, pop_ebp, restore):
    if len(release) != 6 or bytes(pop_ebp) != POP_EBP or len(restore) != 6:
        raise ValueError('return components have unexpected extents')
    return bytes(release) + POP_EBP + bytes(restore)


def materialize_code_fields(initializer, code_bindings):
    if len(initializer) != 39 or code_bindings != CODE_FIELDS:
        raise ValueError('initializer CODE relocation metadata differs')
    out = bytearray(initializer)
    for offset, raw_target in code_bindings.items():
        if offset < 0 or offset + 4 > len(out):
            raise ValueError('typed CODE field lies outside initializer')
        out[offset:offset+4] = (raw_target + CODE_LOAD_BASE).to_bytes(4, 'little')
    if (int.from_bytes(out[14:18], 'little') != 0x1de8e
            or int.from_bytes(out[33:37], 'little') != 0x1df0e):
        raise ValueError('loaded CODE pointer targets differ')
    return bytes(out)


def mutate_first_code_pointer(initializer, code_bindings):
    out = bytearray(materialize_code_fields(initializer, code_bindings))
    target = int.from_bytes(out[14:18], 'little')
    if target != 0x1de8e:
        raise ValueError('first initializer CODE pointer mutation anchor changed')
    out[14:18] = (target + 1).to_bytes(4, 'little')
    return bytes(out)


def mutate_pop_edi(return_body):
    out = bytearray(return_body)
    if len(out) != 13 or out[7] != 0x5f:
        raise ValueError('native POP EDI mutation anchor changed')
    out[7] = 0x5e
    return bytes(out)


def validate_asm_guards(executable):
    if executable[0x43533] != 0x55 or executable[0x43a16] != 0x5d:
        raise ValueError('retained ASM PUSH/POP EBP guard differs')


def bind(executable, build):
    if any(OBJECT_NAMES.get(role) != OBJECT_NAME for role in ROLES):
        raise ValueError('unexpected encounter frame object registration')
    blob = (build / (OBJECT_NAME + '.obj')).read_bytes()
    segments, publics, _externals, _flats, _fixups = parsed_leaf_object(blob)
    if publics != ((1, PUBLIC_START, PUBLIC_NAME),) or segments[1]['cls'] != 'CODE':
        raise ValueError('private encounter frame public layout differs')
    source = segments[1]['data'][PUBLIC_START:PUBLIC_START + PUBLIC_SIZE]
    if len(segments[1]['data']) != PUBLIC_START + PUBLIC_SIZE:
        raise ValueError('private encounter frame extent differs')
    ranges = []
    cursor = 0
    for role in ROLES:
        raw, loaded, size, start, end = EXPECTED[role]
        if (LEAVES.get(role) != (raw, size)
                or LEAF_CODE_SLICES.get(role) != (PUBLIC_NAME, start, end, PUBLIC_SIZE)
                or start < cursor or end - start != size):
            raise ValueError(f'{role} source/registration extent differs')
        ranges.append((start, end))
        cursor = end
    validate_boundaries(source, ranges)
    if cursor != PUBLIC_SIZE:
        raise ValueError('four frame aliases do not account for the selected body boundaries')
    pointers = read_le_fixups(executable)['pointers']
    raw_parts, run_parts, reports = [], [], []
    code_fields = {}
    for role in ROLES:
        raw, loaded, size, _start, _end = EXPECTED[role]
        code_bindings = {}
        exact, bindings = bind_leaf_details(
            blob, role, DATA_OFFSETS, address=loaded,
            functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS,
            code_bindings=code_bindings)
        reference = executable[raw:raw + size]
        if len(reference) != size or exact != reference:
            raise ValueError(f'{role} exact raw bytes differ')
        verify_leaf_relocations(exact, bindings, pointers, loaded,
                                code_bindings=code_bindings)
        if role == 'encounter_initialize_':
            if code_bindings != CODE_FIELDS or set(bindings) != set(CODE_FIELDS):
                raise ValueError('initializer must expose only the two typed CODE fields')
            for offset, raw_target in CODE_FIELDS.items():
                if int.from_bytes(exact[offset:offset+4], 'little') != raw_target:
                    raise ValueError('raw initializer CODE field/addend differs')
            code_fields = dict(code_bindings)
        elif code_bindings or bindings:
            raise ValueError(f'{role} unexpectedly contains LE fields')
        loaded_code_bindings = {}
        run_code, run_bindings = bind_leaf_details(
            blob, role, {name: DS + value for name, value in DATA_OFFSETS.items()},
            address=loaded, functions=FUNCTION_ADDRESSES,
            absolute_code=CODE_OFFSETS, code_bindings=loaded_code_bindings)
        if role == 'encounter_initialize_':
            if loaded_code_bindings != CODE_FIELDS or run_bindings != loaded_code_bindings:
                raise ValueError('loaded initializer generic and typed CODE maps differ')
            run_code = materialize_code_fields(run_code, loaded_code_bindings)
        elif run_bindings or loaded_code_bindings:
            raise ValueError(f'{role} unexpected loaded CODE fields')
        raw_parts.append(exact)
        run_parts.append(run_code)
        reports.append({'role': role, 'bytes': size, 'LE_sites': len(bindings),
                        'CODE_sites': len(code_bindings)})
    validate_asm_guards(executable)
    entry_save, initializer, release, restore = run_parts
    loaded_image = image(executable)
    if loaded_image[0x1df33] != 0x55 or loaded_image[0x1e416] != 0x5d:
        raise ValueError('loaded retained ASM EBP opcodes differ')
    prefix = compose_prefix(entry_save, loaded_image[0x1df33:0x1df34], initializer)
    return_body = compose_return(release, loaded_image[0x1e416:0x1e417], restore)
    if len(prefix) != 45 or len(return_body) != 13:
        raise ValueError('stitched frame extents differ')
    golden_prefix = loaded_image[0x1df2e:0x1df5b]
    golden_return = loaded_image[0x1e410:0x1e41d]
    if len(golden_prefix) != 45 or len(golden_return) != 13:
        raise ValueError('truncated original frame prefix or return')
    return (golden_prefix, prefix, golden_return, return_body,
            code_fields, hashlib.sha256(blob).hexdigest(), reports, loaded_image)


def frame_inputs(pattern, saved):
    frame_base = CALLER_SP - (FRAME_BYTES + SAVED_COUNT * 4)
    scratch = bytes((pattern,)) * FRAME_BYTES
    poison = tuple(0xd00d0000 + pattern * 0x100 + i for i in range(SAVED_COUNT))
    if len(set(poison)) != SAVED_COUNT or set(poison) & set(saved):
        raise ValueError('saved-slot poison is not distinct from caller registers')
    frame = (scratch + struct.pack('<6I', *poison) + struct.pack('<I', STOP)
             + bytes((pattern ^ 0xff,)) * GUARD_BYTES)
    return frame_base, scratch, saved, poison, frame


def _new_cpu(memory):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    return cpu


def run_prefix(memory, code, initial_gp, flags, pattern, payload):
    cpu = _new_cpu(memory)
    saved = (initial_gp[6], initial_gp[5], initial_gp[4],
             initial_gp[3], initial_gp[2], initial_gp[1])
    frame_base, scratch, saved, poison, frame = frame_inputs(pattern, saved)
    cpu.mem_write(CALLER_SP - (FRAME_BYTES + SAVED_COUNT * 4), frame)
    cpu.mem_write(0x1df2e, code)
    cpu.reg_write(UC_X86_REG_ESP, CALLER_SP)
    for reg, value in zip(GP_REGS, initial_gp):
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_EFLAGS, flags)
    try:
        cpu.emu_start(0x1df2e, 0x1df5b, count=500)
        if cpu.reg_read(UC_X86_REG_EIP) != 0x1df5b:
            raise AssertionError('entry/initializer did not reach prefix stop')
        esp = cpu.reg_read(UC_X86_REG_ESP)
        if esp != frame_base:
            raise AssertionError('initializer ESP differs from callerSP-208')
        expected_gp = (initial_gp[0], initial_gp[1], 0, initial_gp[3],
                       0x1df2e, frame_base + 160, initial_gp[6])
        regs = tuple(cpu.reg_read(r) for r in GP_REGS)
        if regs != expected_gp:
            raise AssertionError(f'prefix register outputs differ: {regs!r}')
        start = frame_base
        frame_after = bytes(cpu.mem_read(start, len(frame)))
        if frame_after[:160] != payload:
            raise AssertionError('initializer did not copy both literal arrays')
        if frame_after[160:184] != scratch[160:184]:
            raise AssertionError('initializer changed the last 24 scratch bytes')
        if frame_after[184:208] != struct.pack('<6I', *saved):
            raise AssertionError('initializer saved register order/values differ')
        if frame_after[184:208] == struct.pack('<6I', *poison):
            raise AssertionError('initializer left poisoned saved-register slots untouched')
        if frame_after[208:212] != struct.pack('<I', STOP):
            raise AssertionError('caller return address changed')
        if frame_after[212:] != bytes((pattern ^ 0xff,)) * GUARD_BYTES:
            raise AssertionError('caller post-guard changed')
        if hashlib.sha256(cpu.mem_read(DS, DATA_SIZE)).digest() != hashlib.sha256(memory[DS:DS+DATA_SIZE]).digest():
            raise AssertionError('entry prefix changed full DATA region')
        return (regs, cpu.reg_read(UC_X86_REG_EFLAGS) & FLAGS_MASK, esp,
                hashlib.sha256(cpu.mem_read(DS, DATA_SIZE)).digest(), frame_after)
    finally:
        del cpu


def run_return(memory, code, prefix_frame, clobbers, *, require_restore=True):
    cpu = _new_cpu(memory)
    frame_base = CALLER_SP - (FRAME_BYTES + SAVED_COUNT * 4)
    if len(prefix_frame) != FRAME_BYTES + SAVED_COUNT * 4 + 4 + GUARD_BYTES:
        raise ValueError('return entry does not contain the measured prefix frame')
    frame = bytes(prefix_frame)
    saved = struct.unpack_from('<6I', frame, FRAME_BYTES)
    cpu.mem_write(frame_base, frame)
    cpu.mem_write(0x1e410, code)
    cpu.reg_write(UC_X86_REG_ESP, frame_base)
    for reg, value in zip(SAVE_REGS, clobbers):
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_EAX, 0xdeadbeef)
    cpu.reg_write(UC_X86_REG_EFLAGS, 0x202)
    try:
        cpu.emu_start(0x1e410, STOP, count=100)
        if cpu.reg_read(UC_X86_REG_EIP) != STOP:
            raise AssertionError('frame return did not reach caller STOP')
        restored = tuple(cpu.reg_read(r) for r in SAVE_REGS)
        if require_restore and restored != saved:
            raise AssertionError('return did not restore all six caller registers')
        if cpu.reg_read(UC_X86_REG_ESP) != CALLER_SP + 4:
            raise AssertionError('return ESP differs from callerSP+4')
        frame_after = bytes(cpu.mem_read(frame_base, len(frame)))
        if frame_after != frame:
            raise AssertionError('release/return changed frame or caller guard')
        data_digest = hashlib.sha256(cpu.mem_read(DS, DATA_SIZE)).digest()
        if data_digest != hashlib.sha256(memory[DS:DS+DATA_SIZE]).digest():
            raise AssertionError('return changed full DATA region')
        return (restored, cpu.reg_read(UC_X86_REG_ESP), frame_after,
                cpu.reg_read(UC_X86_REG_EIP), data_digest)
    finally:
        del cpu


def run(executable, build, output):
    if hashlib.sha256(executable).hexdigest() != TARGET_SHA256:
        raise ValueError('unsupported pinned executable')
    golden_prefix, prefix, golden_return, return_body, code_fields, object_hash, reports, memory = bind(executable, build)
    payload = memory[0x1de8e:0x1df2e]
    if len(payload) != COPY_BYTES:
        raise ValueError('original literal payload extent differs')
    if payload[128:] != memory[0x1df0e:0x1df2e]:
        raise ValueError('repeat table source extent differs')
    prefix_cases = ((0x10203040,0x21314151,0x32425262,0x43536373,0x54647484,0x65758595,0x768696a6,0x202,0xa5),
                    (0xfedcba98,0xedcba987,0xdcba9876,0xcba98765,0xba987654,0xa9876543,0x98765432,0x8d7,0x5a))
    prefix_frames = []
    for row in prefix_cases:
        gp, flags, pattern = row[:7], row[7], row[8]
        if flags & 0x400:
            raise ValueError('DF must remain clear for REP MOVSD')
        original = run_prefix(memory, golden_prefix, gp, flags, pattern, payload)
        actual = run_prefix(memory, prefix, gp, flags, pattern, payload)
        if actual != original:
            raise AssertionError('C frame prefix differs from original')
        prefix_frames.append((original[4], actual[4]))

    pointer_mutant = compose_prefix(prefix[:5], prefix[5:6],
                                    mutate_first_code_pointer(prefix[6:], code_fields))
    shifted_payload = memory[0x1de8f:0x1df0f] + memory[0x1df0e:0x1df2e]
    mut_result = run_prefix(memory, pointer_mutant, prefix_cases[0][:7],
                            prefix_cases[0][7], prefix_cases[0][8], shifted_payload)
    baseline_frame = prefix_frames[0][1]
    if mut_result[4][:160] != shifted_payload or mut_result[4][:160] == baseline_frame[:160]:
        raise AssertionError('initializer CODE pointer mutation did not change copied positions')

    returns = []
    for golden_frame, candidate_frame in prefix_frames:
        saved = struct.unpack_from('<6I', golden_frame, FRAME_BYTES)
        clobbers = tuple((value ^ 0xffffffff) & 0xffffffff for value in saved)
        golden = run_return(memory, golden_return, golden_frame, clobbers)
        actual = run_return(memory, return_body, candidate_frame, clobbers)
        if actual != golden:
            raise AssertionError('C frame return differs from original')
        returns.append(actual)
    pop_mutant = mutate_pop_edi(return_body)
    prefix_frame = prefix_frames[0][1]
    saved = struct.unpack_from('<6I', prefix_frame, FRAME_BYTES)
    clobbers = tuple((value ^ 0xffffffff) & 0xffffffff for value in saved)
    mut_return = run_return(memory, pop_mutant, prefix_frame, clobbers,
                            require_restore=False)
    if (mut_return[1] != CALLER_SP + 4 or mut_return[3] != STOP
            or mut_return[0][1] == saved[1]):
        raise AssertionError('POP EDI mutation did not misrestore EDI with correct return/ESP')

    result = {'status': 'PASS', 'cases': len(prefix_cases) + len(returns),
              'prefix_cases': len(prefix_cases), 'return_cases': len(returns),
              'controls': ['initializer CODE pointer +1', 'POP EDI -> POP ESI'],
              'C_bytes': 56, 'CODE_LE_sites': 2, 'retained_ASM_bytes': 2,
              'copied_bytes': COPY_BYTES, 'retained_ASM_table_bytes': 160,
              'object_sha256': object_hash, 'roles': reports}
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
