"""Check fixed-point wall projection, interpolation, clamps and horizontal flip."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x4751E, 919
SPANS = (
    ('prepwall_', ENTRY, 300), ('prepwall_more_columns_', 0x4764A, 233),
    ('prepwall_last_pair_', 0x47733, 141), ('prepwall_last_column_', 0x477C0, 245),
)
RESTORE, POP_REGISTERS = 0x4551F, 0x50347
WALL, STACK, STOP = 0x3E0000, 0x3F0000, 0x3FF000
SCAN, WIDTH, HALF_WIDTH, PROJECTION_SCALE = 11, 320, 160, 65536
VIEW_X1, VIEW_X2 = 8192, 4096
TEXTURE_GUARD, SCALE_GUARD = 0x12345, 0x54321
CASES = (
    ('single sample', 160, 0, 128, -256, 16, False),
    ('one-column remainder', 160, 1, 128, -256, 16, False),
    ('two-column remainder', 160, 2, 128, -256, 16, False),
    ('two- and one-column remainders', 160, 3, 128, -256, 16, False),
    ('four-column group', 160, 4, 128, -256, 16, False),
    ('repeated four-column groups with remainders', 155, 11, 128, -256, 16, False),
    ('left clamp', 160, 4, -32, -416, 16, False),
    ('right clamp', 160, 2, 512, 128, 16, False),
    ('flipped and clamped endpoint', 160, 7, 512, 128, 16, True),
    ('zero repeat', 160, 7, 128, -256, 0, False),
    ('zero final denominator', 160, 1, 128, 152, 16, False),
)


def projected_columns(left, span, rx1, rx2, repeat, flip):
    right = left + span
    repeat *= 8
    scale = (VIEW_X2 * PROJECTION_SCALE) >> 19
    delta_scale = ((VIEW_X1 - VIEW_X2) * PROJECTION_SCALE) >> 16
    step_num = -(VIEW_X2 >> 2)
    step_den = (VIEW_X1 - VIEW_X2) >> 8
    offset = left - HALF_WIDTH
    num = ((rx1 * WIDTH) >> 5) + ((step_num * offset) >> 2)
    den = (((rx1 - rx2) * WIDTH) >> 11) + ((step_den * offset) >> 2)
    textures, scales = {}, {}

    def sample(x):
        assert den != 0
        fixed = (abs(num) << 12) // abs(den)
        if (num < 0) != (den < 0):
            fixed = -fixed
        scales[x] = ((fixed * delta_scale) >> 21) + scale
        texture = fixed * repeat
        textures[x] = texture >> 18
        return texture

    x = left
    texture = sample(x)
    while x + 4 <= right:
        num += step_num
        den += step_den
        other = sample(x + 4)
        midpoint = (texture + other) >> 1
        textures[x + 1] = (texture + midpoint) >> 19
        textures[x + 2] = (texture + other) >> 19
        textures[x + 3] = (midpoint + other) >> 19
        scales[x + 2] = (scales[x] + scales[x + 4]) >> 1
        scales[x + 1] = (scales[x] + scales[x + 2]) >> 1
        scales[x + 3] = (scales[x + 2] + scales[x + 4]) >> 1
        texture = other
        x += 4
    if x + 2 <= right:
        num += step_num >> 1
        den += step_den >> 1
        other = sample(x + 2)
        textures[x + 1] = (texture + other) >> 19
        scales[x + 1] = (scales[x] + scales[x + 2]) >> 1
        x += 2
    if x + 1 <= right:
        num += step_num >> 2
        den += step_den >> 2
        if den:
            sample(x + 1)

    textures[left] = max(0, textures[left])
    if repeat:
        textures[right] = min(repeat - 1, textures.get(right, TEXTURE_GUARD))
    if flip:
        for column in range(left, right + 1):
            textures[column] = repeat - 1 - textures.get(column, TEXTURE_GUARD)
    indexes = range(left - 1, right + 2)
    return (
        tuple(textures.get(column, TEXTURE_GUARD) for column in indexes),
        tuple(scales.get(column, SCALE_GUARD) for column in indexes),
    )


def run_case(code, original, left, span, rx1, rx2, repeat, flip):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 8])
    cpu.mem_write(POP_REGISTERS, original[POP_REGISTERS:POP_REGISTERS + 6])

    def address(name, index=0):
        return DS + DATA_OFFSETS['_' + name] + index * 4

    for name, index, value in (
        ('xb1', SCAN, left), ('xb2', SCAN, left + span), ('rx1', SCAN, rx1),
        ('rx2', SCAN, rx2), ('view_x1', SCAN, VIEW_X1), ('view_x2', SCAN, VIEW_X2),
        ('xdimen', 0, WIDTH), ('half_view_width', 0, HALF_WIDTH),
        ('viewingrange_reciprocal_scaled', 0, PROJECTION_SCALE),
    ):
        cpu.mem_write(address(name, index), pack('<i', value))
    count = span + 3
    outputs = (address('lwall', left - 1), address('swall', left - 1))
    for dest, guard in zip(outputs, (TEXTURE_GUARD, SCALE_GUARD)):
        cpu.mem_write(dest, pack('<i', guard) * count)

    cpu.mem_write(WALL + 14, pack('<H', 8 if flip else 0))
    cpu.mem_write(WALL + 22, pack('<B', repeat))
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_EAX, SCAN)
    cpu.reg_write(UC_X86_REG_EDX, WALL)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    prior = tuple(0x10203040 + index for index in range(len(saved)))
    for reg, value in zip(saved, prior):
        cpu.reg_write(reg, value)
    restore_stack = []

    def at_restore(machine, _address, _size, _user):
        restore_stack.append(machine.reg_read(UC_X86_REG_ESP))

    cpu.hook_add(UC_HOOK_CODE, at_restore, begin=RESTORE, end=RESTORE)
    cpu.emu_start(ENTRY, STOP, count=4000)
    assert restore_stack == [STACK - 60], 'shared restore entry or frame differs'
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP, 'routine failed to return'
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4, 'stack cleanup differs'
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior, 'register restore differs'
    return tuple(unpack(f'<{count}i', cpu.mem_read(dest, count * 4)) for dest in outputs)


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

    for label, code in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', bytes(restored))):
        for name, *case in CASES:
            expected = projected_columns(*case)
            actual = run_case(code, original, *case)
            assert actual == expected, f'{label}: {name}: {actual} != {expected}'
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the prepwall spans')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, {len(CASES)} original and {len(CASES)} restored projection cases')


if __name__ == '__main__':
    main()
