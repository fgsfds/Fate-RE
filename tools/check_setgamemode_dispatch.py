"""Verify generated video dispatch code, table relocations, and case routing."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from random import Random
from struct import pack_into

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EFLAGS, UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from bind_setgamemode_dispatch import BASE, PRIVATE_TARGETS, SECTIONS, bind_context, bind_section, bind_table
from check_setgamemode_init import mutate_context_byte
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_c_leaf import verify_leaf_relocations

RAW_BIAS = 0x25600
GUARD, RETURN = 0x4b1d1, 0x4b386
PRIVATE_BASE = 0x380000
ORIGINAL_TARGETS = (
    0x4b1f3, 0x4b275, 0x4b295, 0x4b2aa, 0x4b2aa, 0x4b2aa, 0x4b2b9, 0x4b320,
)
WIDTH, HEIGHT = DS + 0x287e90, DS + 0x287e8c
REGISTERS = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESP)
DIMENSIONS = ((320, 200), (0, 0xffffffff), (0x7fffffff, 2),
              (0x80000000, 1), (0x80000000, 0xffffffff))


def cpu_for(memory):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, bytes(memory))
    return cpu


def run(cpu, incoming, flags, width, height, private=False):
    for reg, value in zip(REGISTERS, incoming):
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_EFLAGS, flags)
    cpu.mem_write(WIDTH, width.to_bytes(4, 'little'))
    cpu.mem_write(HEIGHT, height.to_bytes(4, 'little'))
    reads, writes = [], []
    read_hook = cpu.hook_add(UC_HOOK_MEM_READ, lambda _, access, addr, size, value, data:
                            reads.append((addr, size)))
    write_hook = cpu.hook_add(UC_HOOK_MEM_WRITE, lambda _, access, addr, size, value, data:
                             writes.append((addr, size)))
    count = 8 if (incoming[0] & 255) <= 7 else 2
    cpu.emu_start(PRIVATE_BASE + 0x26 if private else GUARD, 0, count=count)
    cpu.hook_del(read_hook)
    cpu.hook_del(write_hook)
    if writes:
        raise AssertionError('Dispatch wrote memory before entering a case')
    return (tuple(cpu.reg_read(reg) for reg in REGISTERS), cpu.reg_read(UC_X86_REG_EIP),
            cpu.reg_read(UC_X86_REG_EFLAGS), reads)


def dword_signed(value):
    return value if value < 0x80000000 else value - 0x100000000


def check_result(result, incoming, flags, width, height):
    state, target, next_flags, reads = result
    mode = incoming[0] & 255
    if mode > 7:
        if state != incoming or target != RETURN or reads:
            raise AssertionError('Invalid backend changed state or read the table')
        return
    product = dword_signed(width) * dword_signed(height)
    overflow = not -0x80000000 <= product < 0x80000000
    expected_state = (product & 0xffffffff, height, incoming[2], mode, incoming[4])
    if target != ORIGINAL_TARGETS[mode]:
        raise AssertionError('Dispatch selected the wrong original case entry')
    if state != expected_state or reads != [(HEIGHT, 4), (WIDTH, 4), (BASE + 4 * mode, 4)]:
        raise AssertionError('Dispatch live registers or ordered reads differ')
    if next_flags & 0x801 != (0x801 if overflow else 0) or next_flags & 0x600 != flags & 0x600:
        raise AssertionError('Dispatch multiplication overflow or preserved flags differ')


def check_consumers(exe, private_code, private_calls):
    # Prefixes identify the data flow into the original case, independent of
    # pointer-count and slot-order checks. Calls are compared by their target.
    for mode, length in enumerate((0x1d, 11, 0, 10, 10, 10, 5, 5)):
        private, original = PRIVATE_TARGETS[mode], ORIGINAL_TARGETS[mode]
        raw = original + RAW_BIAS
        if private_code[private:private + length] != exe[raw:raw + length]:
            raise AssertionError(f'Video case {mode} entry consumer differs')
        if mode in (1, 2, 6, 7):
            raw += length
            disp = int.from_bytes(exe[raw + 1:raw + 5], 'little', signed=True)
            if (exe[raw] != 0xe8 or original + length + 5 + disp != 0x4478c
                    or private_code[private + length] != 0xe8
                    or private_calls[private + length + 1] != 0x4478c):
                raise AssertionError(f'Video case {mode} allocator target differs')
        if mode in (6, 7):
            raw = original + RAW_BIAS + 19
            if private_code[private + 19:private + 24] != exe[raw:raw + 5]:
                raise AssertionError(f'Video case {mode} failure diagnostic differs')


def reject(action, exception, message):
    try:
        action()
    except exception as exc:
        if message not in str(exc):
            raise AssertionError('Negative control reached the wrong check') from exc
    else:
        raise AssertionError('Negative control was accepted')


def check(exe, blob):
    if sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    pointers = read_le_fixups(exe)['pointers']
    if tuple(pointers[BASE + 4 * mode] for mode in range(8)) != ORIGINAL_TARGETS:
        raise AssertionError('Original dispatch table targets differ')
    baseline = image(exe)
    candidate = bytearray(baseline)

    def install(address, code, refs, code_refs):
        raw = address + RAW_BIAS
        if code != exe[raw:raw + len(code)]:
            raise AssertionError('Placed dispatch bytes differ from their original span')
        verify_leaf_relocations(code, refs, pointers, address, code_bindings=code_refs)
        candidate[address:address + len(code)] = code
        for site, value in refs.items():
            pack_into('<I', candidate, address + site, value + (0x10000 if site in code_refs else DS))

    private_code, _, _, private_calls = bind_context(blob)
    check_consumers(exe, private_code, private_calls)
    table, data, code_refs, calls = bind_table(blob)
    if len(table) != 32 or data or calls or len(code_refs) != 8:
        raise AssertionError('Dispatch table is not exactly eight CODE pointers')
    install(BASE, table, code_refs, code_refs)
    for symbol, (_, _, address) in SECTIONS.items():
        phase_code_refs = {}
        code, refs = bind_section(blob, symbol, address, phase_code_refs)
        install(address, code, refs, phase_code_refs)

    for offset in (0, 0x20, 0x38, 0x1e9):
        reject(lambda: bind_table(mutate_context_byte(blob, offset)), ValueError, 'raw group digest')
    reject(lambda: verify_leaf_relocations(table, code_refs, pointers, BASE), ValueError,
           'Original LE relocation sites or targets differ')

    mutant = bytearray(candidate)
    pack_into('<I', mutant, BASE + 8, ORIGINAL_TARGETS[0])
    control = (0x92f30a02, 0xfedcba98, 0x87654321, 0x12345678, 0x3ff000), 0x202, 320, 200
    reject(lambda: check_result(run(cpu_for(mutant), *control), *control), AssertionError,
           'selected the wrong original case entry')

    private_code, _, _, _ = bind_context(blob, loaded=True, base=PRIVATE_BASE)
    unlinked = bytearray(baseline)
    unlinked[PRIVATE_BASE:PRIVATE_BASE + len(private_code)] = private_code
    ref_cpu, cand_cpu, context_cpu = map(cpu_for, (baseline, candidate, unlinked))
    rng = Random(0x4b1d9)
    for width, height in DIMENSIONS:
        for mode in range(256):
            incoming = ((rng.getrandbits(32) & 0xffffff00) | mode, rng.getrandbits(32),
                        rng.getrandbits(32), rng.getrandbits(32), 0x3ff000)
            flags = rng.choice((0x202, 0x683, 0xe03))
            inputs = incoming, flags, width, height
            result = run(cand_cpu, *inputs)
            check_result(result, *inputs)
            if run(ref_cpu, *inputs) != result:
                raise AssertionError('Placed dispatch and original trace differ')
            if mode <= 7:
                state, target, _, reads = run(context_cpu, *inputs, private=True)
                if (state != result[0] or target != PRIVATE_BASE + PRIVATE_TARGETS[mode]
                        or reads != [(HEIGHT, 4), (WIDTH, 4), (PRIVATE_BASE + 4 * mode, 4)]):
                    raise AssertionError('Private compiler table selected a different case contract')
    return dict(target_sha256=TARGET_SHA256, object_sha256=sha256(blob).hexdigest(),
                placed_cases=256 * len(DIMENSIONS), private_cases=8 * len(DIMENSIONS),
                table_bytes=len(table), table_code_relocations=len(code_refs),
                native_dispatch_bytes=sum(stop - start for start, stop, _ in SECTIONS.values()),
                rejection_controls=6, result='PASS')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--object', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = check(args.exe.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 1280 placed and 40 private video dispatch cases, 6 rejection controls')


if __name__ == '__main__':
    main()

