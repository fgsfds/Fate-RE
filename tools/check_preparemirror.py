"""Exercise reflected camera coordinates, VGA marker writes, and the shared return."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_INSN
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x5D656, 712
RESTORE, GETANGLE = 0x52C82, 0x4C94C
STACK, STOP, OUTPUT = 0x3F0000, 0x3FF000, 0x3F2000
FRAME, PLANAR, STRIDE, ROWS = 0x3A0000, 0x3B0000, 24, 16
GUARD = 0xA7
START, X, Y, ANGLE = (100, 100), 125, 130, 128

# Wall endpoint, z, horizon, viewport x bounds, planar flag, reflected camera, marker row.
CASES = (
    ('horizontal, upper half', (200, 100), -50, 100, (6, 17), 0, (125, 70, 1920), 9),
    ('vertical, lower half', (100, 200), 50, 100, (6, 17), 0, (75, 130, 896), 7),
    ('diagonal reflected view', (200, 200), 0, 100, (1, 2), 0, (130, 125, 384), 9),
    ('linear row clamped to top', (200, 100), -50, -1000, (6, 17), 0, (125, 70, 1920), 3),
    ('linear row clamped to bottom', (200, 100), 50, 1000, (6, 17), 0, (125, 70, 1920), 13),
    ('four planar columns', (200, 100), -50, 100, (6, 17), 1, (125, 70, 1920), 9),
    ('two planar columns', (200, 100), 50, 100, (6, 7), 1, (125, 70, 1920), 7),
    ('camera on ceiling', (200, 100), -100, 100, (6, 17), 0, (125, 70, 1920), None),
    ('camera on floor', (200, 100), 100, 100, (6, 17), 1, (125, 70, 1920), None),
    ('zero-length wall', START, 0, 100, (6, 17), 0, None, None),
)


def run_case(code, original, endpoint, z, horizon, bounds, planar, reflection, marker_row):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(GETANGLE, original[GETANGLE:GETANGLE + 300])
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 6])

    def put(fmt, name, *values, offset=0):
        cpu.mem_write(DS + DATA_OFFSETS['_' + name] + offset, pack('<' + fmt, *values))

    def get(fmt, name, size):
        return unpack('<' + fmt, cpu.mem_read(DS + DATA_OFFSETS['_' + name], size))[0]

    put('iih', 'wall', *START, 3, offset=32)
    put('iih', 'wall', *endpoint, 1, offset=96)
    put('ii', 'sector', -100, 100, offset=40 * 2 + 4)
    left, right = bounds
    for name, value in (
        ('window_left', left), ('window_right', right), ('window_top', 3),
        ('window_bottom', 13), ('frameplace', FRAME), ('chainplace', PLANAR),
        ('mirror_z', -999), ('mirror_row', -1999),
    ):
        put('i', name, value)
    put('h', 'mirror_sector', -9)
    put('B', 'chainstat', planar)
    put('4B', 'pow2char', 1, 2, 4, 8)
    put(f'{ROWS}i', 'ylookup', *(row * STRIDE for row in range(ROWS)))
    output_guard = bytes([GUARD]) * 12
    cpu.mem_write(OUTPUT, output_guard)
    expected_frame = bytearray([GUARD]) * (ROWS * STRIDE)
    expected_planar = expected_frame.copy()
    cpu.mem_write(FRAME, bytes(expected_frame))
    cpu.mem_write(PLANAR, bytes(expected_planar))

    stack_args = (STOP, horizon, 1, 2, OUTPUT, OUTPUT + 4, OUTPUT + 8)
    cpu.mem_write(STACK, pack('<7I', *(value & 0xffffffff for value in stack_args)))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for register, value in zip(
            (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX),
            (X, Y, z, ANGLE)):
        cpu.reg_write(register, value)
    saved = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    values = (0x12345678, 0x23456789, 0x3456789a)
    for register, value in zip(saved, values):
        cpu.reg_write(register, value)
    ports = []
    tail_stack = []

    def record_port(_machine, port, width, value, _user):
        ports.append((port, width, value))

    def record_restore(machine, _address, _size, _user):
        tail_stack.append(machine.reg_read(UC_X86_REG_ESP))

    cpu.hook_add(UC_HOOK_INSN, record_port, None, 1, 0, UC_X86_INS_OUT)
    cpu.hook_add(UC_HOOK_CODE, record_restore, begin=RESTORE, end=RESTORE)
    cpu.emu_start(ENTRY, STOP, count=6000)

    assert tail_stack == [STACK - 12], 'shared return frame differs'
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP, 'did not return'
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 28, 'stack cleanup differs'
    assert tuple(cpu.reg_read(register) for register in saved) == values
    expected_output = output_guard if reflection is None else pack('<iih', *reflection) + output_guard[10:]
    assert bytes(cpu.mem_read(OUTPUT, 12)) == expected_output
    assert get('i', 'mirror_z', 4) == (-999 if reflection is None else z)
    assert get('h', 'mirror_sector', 2) == (-9 if reflection is None else 2)
    assert get('i', 'mirror_row', 4) == (-1999 if marker_row is None else marker_row)
    expected_ports = []
    if marker_row is not None:
        row = marker_row * STRIDE
        if planar:
            expected_ports.append((0x3C4, 1, 2))
            for column in range(min(left + 4, right + 1) - 1, left - 1, -1):
                expected_ports.append((0x3C5, 1, 1 << (column & 3)))
                start = row + (column >> 2)
                pixels = (right + 4 - column) >> 2
                expected_planar[start:start + pixels] = b'\xff' * pixels
        else:
            expected_frame[row + left:row + right + 1] = b'\xff' * (right - left + 1)
    assert ports == expected_ports
    assert cpu.mem_read(FRAME, len(expected_frame)) == expected_frame
    assert cpu.mem_read(PLANAR, len(expected_planar)) == expected_planar


def check(exe, obj):
    original = image(exe)
    raw = ENTRY + 0x25600
    code, references = bind_leaf_details(obj, 'preparemirror_', DATA_OFFSETS, address=ENTRY,
                                          functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[raw:raw + SIZE]
    verify_leaf_relocations(code, references, read_le_fixups(exe)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, 'preparemirror_', {name: value + DS for name, value in DATA_OFFSETS.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    for label, body in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', restored)):
        for name, *case in CASES:
            try:
                run_case(body, original, *case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {name}') from error
    return len(references)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing preparemirror_')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, {len(CASES)} original and {len(CASES)} restored mirror cases')


if __name__ == '__main__':
    main()
