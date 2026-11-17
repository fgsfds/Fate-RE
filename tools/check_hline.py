"""Check exact horizontal spans, palette inputs, and planar raster dispatch."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_INSN
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX,
    UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x4A7F3, 565
SPANS = (
    ('hline_', ENTRY, 273), ('hline_planar_', 0x4A904, 178),
    ('hline_next_plane_', 0x4A9B6, 114),
)
RESTORE, POP_REGISTERS = 0x4551F, 0x50347
SHADE, SETUP, DRAW = 0x5FED7, 0x74110, 0x74150
FRAME, PLANAR, ASPECT = 0x350000, 0x360000, 0x370000
STACK, STOP = 0x3F0000, 0x3FF000
ROW, ROW_OFFSET, HORIZON, HORIZON_CENTER = 9, 6024, 3, 12
ASPECT_SAMPLE = 10231
GLOBAL_X1, GLOBAL_X2 = 7231, -19523
GLOBAL_Y1, GLOBAL_Y2 = 94280, -9177
PAN_X, PAN_Y, GLOBAL_SHADE, VISIBILITY = -68121, 32485, -19, 3018
INITIAL_STEPS = (0x11335577, 0x22446688)
MASK = 0xFFFFFFFF
RASTER_REGISTERS = (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDX, UC_X86_REG_ESI, UC_X86_REG_EDI,
)


@dataclass(frozen=True)
class Case:
    name: str
    left: int
    right: int
    view_offset: int
    height: int
    planar: bool = False


CASES = (
    Case('empty linear span', 6, 5, 1, 768),
    Case('empty planar span', 6, 5, 1, 768, True),
    Case('linear single pixel', 5, 5, 2, 768),
    Case('negative linear scale', 3, 28, 7, -560),
    Case('zero scale', 0, 11, 3, 0),
    Case('one VGA plane', 6, 6, 1, 768, True),
    Case('two VGA planes with wrap', 5, 6, 2, -560, True),
    Case('three VGA planes', 12, 14, 0, 768, True),
    Case('all VGA planes', 1, 31, 3, -560, True),
)


def shade_result(distance, shade):
    return (distance + shade) & 0x3F


def expected(case):
    if case.left > case.right:
        return [], [], INITIAL_STEPS
    scale = case.height * ASPECT_SAMPLE >> 10
    step_x = GLOBAL_X1 * scale >> 8
    step_y = GLOBAL_Y2 * scale >> 8
    texture_x = ((GLOBAL_X1 * case.left + GLOBAL_Y1) * scale >> 8) + PAN_X
    texture_y = ((GLOBAL_Y2 * case.left + GLOBAL_X2) * scale >> 8) + PAN_Y
    distance = abs(scale) * VISIBILITY >> 18
    palette = shade_result(distance, GLOBAL_SHADE) << 8
    calls = [(SHADE, (distance, GLOBAL_SHADE & MASK))]
    ports = []

    def draw(count, mode, x, y, dest):
        calls.append((DRAW, tuple(value & MASK for value in (count, mode, palette, y, x, dest))))

    if case.planar:
        steps = ((step_x << 2) & MASK, (step_y << 2) & MASK)
        calls.append((SETUP, steps))
        for plane, column in enumerate(range(case.left, min(case.right + 1, case.left + 4))):
            screen_x = case.view_offset + column
            ports.append((0x3C5, 1, 1 << (screen_x & 3)))
            draw((case.right - column) >> 2, MASK, texture_x + step_x * plane,
                 texture_y + step_y * plane, PLANAR + ROW_OFFSET + (screen_x >> 2))
    else:
        steps = (step_x & MASK, step_y & MASK)
        draw(case.right - case.left, 0, texture_x, texture_y,
             FRAME + ROW_OFFSET + case.view_offset + case.left)
    return calls, ports, steps


def run_case(code, original, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 8])
    cpu.mem_write(POP_REGISTERS, original[POP_REGISTERS:POP_REGISTERS + 6])

    def address(name, offset=0):
        return DS + DATA_OFFSETS['_' + name] + offset

    def put(name, value, offset=0):
        cpu.mem_write(address(name, offset), pack('<I', value & MASK))

    for name, value in (
        ('frameplace', FRAME), ('chainplace', PLANAR), ('viewoffset', case.view_offset),
        ('globalhoriz', HORIZON), ('horizycent', HORIZON_CENTER), ('horizon_aspect', ASPECT),
        ('globalzd', case.height), ('globalx1', GLOBAL_X1), ('globalx2', GLOBAL_X2),
        ('globaly1', GLOBAL_Y1), ('globaly2', GLOBAL_Y2), ('globalxpanning', PAN_X),
        ('globalypanning', PAN_Y), ('globalshade', GLOBAL_SHADE), ('globvis', VISIBILITY),
        ('asm1', INITIAL_STEPS[0]), ('asm2', INITIAL_STEPS[1]),
    ):
        put(name, value)
    put('lastx', case.left, ROW * 4)
    put('ylookup', ROW_OFFSET, ROW * 4)
    cpu.mem_write(address('chainstat'), bytes([case.planar]))
    cpu.mem_write(address('pow2char'), bytes(1 << bit for bit in range(8)))
    cpu.mem_write(ASPECT + (ROW - HORIZON + HORIZON_CENTER) * 4, pack('<i', ASPECT_SAMPLE))

    calls, ports, restore_stacks = [], [], []

    def record_call(machine, target, _size, _user_data):
        regs = {reg: machine.reg_read(reg) for reg in RASTER_REGISTERS}
        if target == SHADE:
            args = (regs[UC_X86_REG_EAX], regs[UC_X86_REG_EDX])
            machine.reg_write(UC_X86_REG_EAX, shade_result(*args))
        elif target == SETUP:
            args = (regs[UC_X86_REG_EAX], regs[UC_X86_REG_EBX])
        else:
            args = tuple(regs[reg] for reg in RASTER_REGISTERS)
            for reg in RASTER_REGISTERS:
                machine.reg_write(reg, 0x12345678)
        calls.append((target, args))

    def on_restore(machine, _address, _size, _user_data):
        restore_stacks.append(machine.reg_read(UC_X86_REG_ESP))

    def out_port(_machine, port, size, value, _user_data):
        ports.append((port, size, value))

    for target in (SHADE, SETUP, DRAW):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, record_call, begin=target, end=target)
    cpu.hook_add(UC_HOOK_CODE, on_restore, begin=RESTORE, end=RESTORE)
    cpu.hook_add(UC_HOOK_INSN, out_port, None, 1, 0, UC_X86_INS_OUT)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, case.right)
    cpu.reg_write(UC_X86_REG_EDX, ROW)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    prior = tuple(0x10203040 + index for index in range(len(saved)))
    for reg, value in zip(saved, prior):
        cpu.reg_write(reg, value)
    cpu.emu_start(ENTRY, STOP, count=4000)

    assert restore_stacks == [STACK - 60]
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior
    steps = tuple(unpack('<I', cpu.mem_read(address(name), 4))[0] for name in ('asm1', 'asm2'))
    assert (calls, ports, steps) == expected(case), (calls, ports, steps, expected(case))


def check(exe, obj):
    original = image(exe)
    restored = bytearray()
    relocations = 0
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: offset + DS for name, offset in DATA_OFFSETS.items()}
    for symbol, entry, length in SPANS:
        raw = entry + 0x25600
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry,
                                             functions=FUNCTION_ADDRESSES)
        assert len(code) == length and code == exe[raw:raw + length], f'{symbol}: machine code mismatch'
        verify_leaf_relocations(code, references, pointers, entry)
        relocations += len(references)
        code, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
        restored.extend(code)
    assert len(restored) == SIZE

    for label, code in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', bytes(restored))):
        for case in CASES:
            try:
                run_case(code, original, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the horizontal span wrapper')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored horizontal span cases')


if __name__ == '__main__':
    main()
