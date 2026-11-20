"""Check signed line-edge rounding, endpoint stores, and the custom register ABI."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details,
    verify_leaf_relocations,
)

SYMBOL = 'intersect_clip_edge_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
STACK, STOP = 0x3ff000, 0x3fff00
X, Y = 0x3e0010, 0x3e0050
SAVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def short(value):
    return ((value + 32768) & 0xffff) - 32768


def trunc_div(numerator, denominator):
    quotient = abs(numerator) // denominator
    return -quotient if numerator < 0 else quotient


def oracle(case):
    x, y, other_x, other_y, edge = map(short, case)
    distance = abs(other_x - x)
    assert distance, 'zero denominator outside fixture domain'
    rise = 2 * (other_y - y)
    product = abs(edge - x) * rise
    biased = product + distance if product > 0 else product - distance
    assert -(1 << 31) <= product < (1 << 31)
    assert -(1 << 31) <= biased < (1 << 31)
    offset = trunc_div(biased, 2 * distance)
    result_y = y + offset
    assert -(1 << 31) <= result_y < (1 << 31)
    return short(edge), short(result_y)


def cases():
    result = []
    # Both signs of every axis, interpolation/extrapolation, zero/half ties.
    for x in (-120, 0, 145):
        for y in (-91, 0, 93):
            for dx in (-37, -1, 1, 29):
                for dy in (-47, 0, 31):
                    for edge_dx in (-25, 0, 1, 17, 43):
                        result.append((x, y, x + dx, y + dy, x + edge_dx))
    result += [
        (0, 0, 2, 1, 1), (0, 0, 2, -1, 1),
        (0, 0, -2, 1, -1), (0, 0, -2, -1, -1),
        (0, 32760, 10, 32767, 20),
        (0, -32760, 10, -32768, 20),
        (-32768, 0, 32767, 100, 0),
        (32767, 0, -32768, -100, 0),
        (-32768, 32767, -32767, 32766, -32768),
        (32767, -32768, 32766, -32767, 32767),
        (0, 32767, 1, 32767, -32768),
        (0, -32768, -1, -32768, 32767),
        (0, 0, 32767, 32767, -32768),
        (0, 0, -32768, -32768, 32767),
    ]
    for case in result:
        oracle(case)
    return result


def exercise(memory, body, test_cases, label):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)
    guards = b'\x93\x27\xc1\x6e\x4a\xd5\x08\xbf'
    stack_guard = b'\xa5' * 24
    for index, case in enumerate(test_cases):
        x, y, other_x, other_y, edge = case
        expected_x, expected_y = oracle(case)
        cpu.mem_write(X - 8, guards + pack('<h', x) + guards)
        cpu.mem_write(Y - 8, guards + pack('<h', y) + guards)
        # EAX/EDX point to shorts; EBX/ECX carry opposite coordinates.
        # The edge is one callee-cleaned stack dword. Poison high halves:
        # all arithmetic consumes signed low words, final store consumes AX.
        cpu.mem_write(STACK, pack('<II', STOP, 0xc3d40000 | (edge & 0xffff)) + stack_guard)
        cpu.mem_write(STACK - 96, guards)
        saved = {reg: 0x13570000 + index * 16 + n for n, reg in enumerate(SAVED)}
        for reg, value in saved.items():
            cpu.reg_write(reg, value)
        for reg, value in (
            (UC_X86_REG_EAX, X), (UC_X86_REG_EDX, Y),
            (UC_X86_REG_EBX, 0xa1b20000 | (other_x & 0xffff)),
            (UC_X86_REG_ECX, 0xe5f60000 | (other_y & 0xffff)),
            (UC_X86_REG_ESP, STACK),
        ):
            cpu.reg_write(reg, value)
        cpu.emu_start(ENTRY, STOP, count=200)
        context = (label, index, case)
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP, context
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 8, ('ret 4', context)
        assert all(cpu.reg_read(reg) == value for reg, value in saved.items()), ('saved registers', context)
        assert cpu.mem_read(STACK + 8, len(stack_guard)) == stack_guard, ('caller stack guard', context)
        assert cpu.mem_read(STACK - 96, len(guards)) == guards, ('lower stack guard', context)
        assert cpu.mem_read(X - 8, 18) == guards + pack('<h', expected_x) + guards, ('x/neighbor bytes', context)
        assert cpu.mem_read(Y - 8, 18) == guards + pack('<h', expected_y) + guards, ('y/neighbor bytes', context)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[RAW:RAW + SIZE], 'nonexact clip body'
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, {k: DS + v for k, v in DATA_OFFSETS.items()},
                                     address=ENTRY, functions=FUNCTION_ADDRESSES)
    test_cases = cases()
    exercise(memory, memory[ENTRY:ENTRY + SIZE], test_cases, 'original')
    exercise(memory, relocated, test_cases, 'restored')
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations; {len(test_cases)} original and {len(test_cases)} restored cases; endpoint guards, ESI/EDI/EBP, ESP and RET 4 preserved')


if __name__ == '__main__':
    main()