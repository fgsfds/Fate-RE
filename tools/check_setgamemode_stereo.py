"""Verify both C stereo contexts, placed state writes and inherited return frame."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from random import Random
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_MEM_WRITE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EFLAGS, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_ESP,
)
from check_start_hook import DS, image
from check_setgamemode_init import mutate_context_byte
from compare_exe import TARGET_SHA256
from bind_setgamemode_stereo import CONTEXTS, DATA, PHASES, SINGLE, DOUBLE, verify_context
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations
from le_fixups import read_le_fixups

EAX, EBX, ECX, EDX = UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX
EBP, EDI, ESI, ESP = UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ESP
EFLAGS, EIP = UC_X86_REG_EFLAGS, UC_X86_REG_EIP
SCREEN, BACKEND, FRAME = 0x13ff0, 0x2891db, 0x286b74
WIDTH, PIXELS, FLIP, MODE = 0x286b40, 0x286b44, 0x14014, 0x286b24
STACK, FINISH, RETURN = 0x3ff010, 0x4a367, 0x4b386
EXIT = 0x90100
REGS = (EAX, EBX, ECX, EDX, EBP, EDI, ESI, ESP)

def run(memory, mode_number, original_backend, frame, live, saved, input_flags, *, entry=None, state_stop=RETURN, ordered=True):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, bytes(memory))
    for reg, value in zip(REGS, (*live, STACK)):
        cpu.reg_write(reg, value)
    cpu.reg_write(EFLAGS, input_flags)
    old_stack = pack('<7I', 0x55555555, *saved, EXIT, 0xaaaaaaaa)
    cpu.mem_write(STACK - 4, old_stack)
    cpu.mem_write(DS + SCREEN, pack('<I', frame))
    cpu.mem_write(DS + BACKEND - 1, bytes((0xA5, original_backend, 0x5A)))
    for data_offset in (FRAME, WIDTH, PIXELS, FLIP, MODE):
        cpu.mem_write(DS + data_offset, b'\xcc' * 4)
    writes = []
    hook = cpu.hook_add(
        UC_HOOK_MEM_WRITE,
        lambda _cpu, _access, address, size, value, _data:
            writes.append((address - DS, size, value)),
    )
    cpu.emu_start(entry if entry is not None else
                  0x4b2e0 if mode_number == 6 else 0x4b347, state_stop, count=30)
    cpu.hook_del(hook)
    eax, ebx, ecx, edx, ebp, edi, esi = live
    expected = (
        (32768, ebx, (ecx & 0xffff00ff) | 0x200, 32, 1, edi, esi, STACK)
        if mode_number == 6 else
        (original_backend, ebx, 1, edx, ebp, 32, 32768, STACK)
    )
    result = tuple(cpu.reg_read(reg) for reg in REGS)
    assert result == expected
    flags = cpu.reg_read(EFLAGS)
    assert flags & 0xcc5 == (input_flags & 0x400) | 0x44
    common = {FRAME: (4, frame), WIDTH: (4, 32768), PIXELS: (4, 32),
              FLIP: (4, 1), MODE: (4, original_backend), BACKEND: (1, 2)}
    expected_order = (
        (FRAME, FLIP, PIXELS, MODE, BACKEND, WIDTH) if mode_number == 6 else
        (FRAME, WIDTH, PIXELS, BACKEND, MODE, FLIP)
    )
    expected_writes = [(offset, *common[offset]) for offset in expected_order]
    assert (writes == expected_writes if ordered else sorted(writes) == sorted(expected_writes))
    assert bytes(cpu.mem_read(DS + BACKEND - 1, 3)) == b'\xa5\x02\x5a'
    assert bytes(cpu.mem_read(STACK - 4, len(old_stack))) == old_stack
    assert cpu.reg_read(EIP) == state_stop

    def finish(emu, address, size, _):
        sp = emu.reg_read(ESP)
        assert sp == STACK - 4 and address == FINISH and size > 0
        ret, = unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(ESP, sp + 4)
        emu.reg_write(EIP, ret)

    cpu.hook_add(UC_HOOK_CODE, finish, begin=FINISH, end=FINISH)
    cpu.emu_start(RETURN, EXIT, count=10)
    assert tuple(cpu.reg_read(reg) for reg in (EBP, EDI, ESI, ECX)) == saved
    assert cpu.reg_read(EIP) == EXIT and cpu.reg_read(ESP) == STACK + 20
    return result, flags, writes

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--object', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    exe, blob = args.exe.read_bytes(), args.object.read_bytes()
    if sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    verify_context(blob)
    baseline = image(exe)
    placed = bytearray(baseline)
    pointers = read_le_fixups(exe)['pointers']
    for symbol, (_, start, size, address) in PHASES.items():
        code, refs = bind_leaf_details(blob, symbol, DATA, address=address)
        if code != exe[address + 0x25600:address + 0x25600 + size]:
            raise AssertionError('Placed stereo C bytes differ: ' + symbol)
        verify_leaf_relocations(code, refs, pointers, address)
        loaded = bytearray(code)
        for site, target in refs.items():
            loaded[site:site + 4] = pack('<I', DS + target)
        placed[address:address + size] = loaded
    # Natural compiler order excludes only the private save/restore/RET.
    private_base = 0x380000
    natural = {}
    for public in CONTEXTS:
        code, _ = bind_leaf_details(blob, public, {name: DS + target for name, target in DATA.items()},
                                    address=private_base)
        memory = bytearray(baseline)
        memory[private_base:private_base + len(code)] = code
        natural[public] = memory
    random = Random(0x4b2e0)
    cases = []
    for mode_number, public in ((6, SINGLE), (7, DOUBLE)):
        for original_backend in (0, 6, 7, 0x80, 0xff):
            for input_flags in (0x293, 0xe03):
                frame = random.getrandbits(32)
                live = tuple(random.getrandbits(32) for _ in range(7))
                saved = tuple(random.getrandbits(32) for _ in range(4))
                case = (mode_number, original_backend, frame, live, saved, input_flags)
                expected = run(baseline, *case)
                assert run(placed, *case) == expected
                private = run(natural[public], *case,
                              entry=private_base + (1 if mode_number == 6 else 0),
                              state_stop=private_base + 0x3f, ordered=False)
                assert private[:2] == expected[:2]
                cases.append(case)
    # Mutations must fail the independent output/write/register oracle.
    for offset, case in ((0x4b2e1, cases[0]), (0x4b2ed, cases[0]),
                         (0x4b30a, cases[0]), (0x4b354, cases[10])):
        mutant = bytearray(placed)
        mutant[offset] ^= 1
        try:
            run(mutant, *case)
        except AssertionError:
            pass
        else:
            raise AssertionError('Stereo oracle accepted a state code mutation')
    # Excluded private stack operations and returns remain guarded.
    for offset in (0, 0x3f, 0x40, 0x80):
        try:
            verify_context(mutate_context_byte(blob, offset))
        except ValueError as exc:
            if 'Stereo context code digest differs' not in str(exc):
                raise AssertionError('Stereo mutation did not reach the digest guard') from exc
        else:
            raise AssertionError('Stereo context accepted a changed private instruction')
    result = dict(status='PASS', cases=len(cases), executions=3 * len(cases),
                  bytes=125, le_sites=16, code_mutation_controls=4,
                  context_mutation_controls=4, original_placed_natural='PASS')
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
