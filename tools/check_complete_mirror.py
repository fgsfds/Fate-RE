"""Verify complete mirror scanline reversal in linear and planar video memory."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import (
    Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_INSN,
    UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE,
)
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX,
    UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x5D91E, 1192
RESTORE, TIMER = 0x4ABBB, 0x31EC4
STACK, STOP, FRAME = 0x3F0000, 0x3FF000, 0x3A0000
STRIDE, ROWS, TOP, BOTTOM, MARKER_ROW = 32, 8, 2, 4, 3
CASES = (
    ('linear full viewport', False, False, 4, 19),
    ('linear clipped by marker', False, True, 4, 19),
    ('linear odd span and unaligned destination', False, False, 5, 15),
    ('linear invalid bounds', False, False, 19, 4),
    ('planar full viewport', True, False, 4, 19),
    ('planar clipped by marker', True, True, 4, 19),
    ('planar partial cells', True, False, 5, 15),
    ('planar invalid bounds', True, False, 19, 4),
)


def visible_span(row, left, right, clipped, planar):
    if not clipped:
        return left, right
    visible_left, visible_right = left, right
    while visible_left <= visible_right and row[visible_left] == 255:
        visible_left += 1
    while visible_right >= visible_left and row[visible_right] == 255:
        visible_right -= 1
    if visible_left > left:
        visible_left -= 1
    if visible_right < right:
        visible_right += 1
    if not planar:
        visible_right = min(right, left + ((visible_right - left) | 3))
    return visible_left, visible_right


def expected_frame(pixels, clipped, planar, left, right):
    expected = bytearray(pixels)
    marker = pixels[MARKER_ROW * STRIDE:(MARKER_ROW + 1) * STRIDE]
    start, end = visible_span(marker, left, right, clipped, planar)
    if end < start:
        return expected, 0, 0
    width = end - start
    dest = left + right - end
    for row in range(TOP, BOTTOM + 1):
        base = row * STRIDE
        if planar:
            line = pixels[base + start:base + end + 1]
        else:
            # The linear loop copies one pixel to the right and duplicates its last visible sample.
            line = pixels[base + start + 1:base + end + 1] + pixels[base + end:base + end + 1]
        expected[base + dest:base + dest + len(line)] = line[::-1]
    return expected, width * (BOTTOM - TOP), BOTTOM - TOP + 1


def run_case(code, original, planar, clipped, left, right):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 10])
    cpu.mem_write(TIMER, b'\xc3')

    def put(fmt, name, *values, offset=0):
        cpu.mem_write(DS + DATA_OFFSETS['_' + name] + offset, pack('<' + fmt, *values))

    def global_long(name):
        return unpack('<i', cpu.mem_read(DS + DATA_OFFSETS['_' + name], 4))[0]

    for name, value in (
        ('window_left', left), ('window_right', right), ('window_top', TOP),
        ('window_bottom', BOTTOM), ('frameplace', FRAME), ('chainplace', FRAME),
        ('mirror_z', 0 if clipped else 100), ('mirror_row', MARKER_ROW), ('transarea', 7),
    ):
        put('i', name, value)
    put('h', 'mirror_sector', 2)
    put('ii', 'sector', -100, 100, offset=40 * 2 + 4)
    put('B', 'chainstat', planar)
    put('4B', 'pow2char', 1, 2, 4, 8)

    pixels = bytearray((3 * x + 29 * y) % 251 for y in range(ROWS) for x in range(STRIDE))
    if clipped:
        start = MARKER_ROW * STRIDE
        pixels[start + left:start + left + 3] = b'\xff' * 3
        pixels[start + right - 2:start + right + 1] = b'\xff' * 3
    expected, transarea, timer_count = expected_frame(pixels, clipped, planar, left, right)
    ports = []
    banks = [bytearray(plane) for plane in (pixels[index::4] for index in range(4))]
    read_plane, write_plane = 0, 0
    if planar:
        put(f'{ROWS}i', 'ylookup', *(row * (STRIDE // 4) for row in range(ROWS)))

        def on_read(machine, _access, address, size, _value, _user):
            offset = address - FRAME
            machine.mem_write(address, bytes(banks[read_plane][offset:offset + size]))

        def on_write(_machine, _access, address, size, value, _user):
            offset = address - FRAME
            banks[write_plane][offset:offset + size] = value.to_bytes(size, 'little')

        cpu.hook_add(UC_HOOK_MEM_READ, on_read, begin=FRAME, end=FRAME + len(banks[0]) - 1)
        cpu.hook_add(UC_HOOK_MEM_WRITE, on_write, begin=FRAME, end=FRAME + len(banks[0]) - 1)
    else:
        put(f'{ROWS}i', 'ylookup', *(row * STRIDE for row in range(ROWS)))
        cpu.mem_write(FRAME, bytes(pixels))

    def on_port(_machine, port, width, value, _user):
        nonlocal read_plane, write_plane
        ports.append((port, width, value))
        assert width == 1
        if port == 0x3CF:
            assert 0 <= value <= 3
            read_plane = value
        elif port == 0x3C5:
            assert value in (1, 2, 4, 8)
            write_plane = value.bit_length() - 1
        else:
            assert (port, value) in ((0x3CE, 4), (0x3C4, 2))

    cpu.hook_add(UC_HOOK_INSN, on_port, None, 1, 0, UC_X86_INS_OUT)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    values = tuple(0x10203040 + index for index in range(len(saved)))
    for register, value in zip(saved, values):
        cpu.reg_write(register, value)
    tail_stack, ticks = [], []

    def on_tail(machine, _address, _size, _user):
        tail_stack.append(machine.reg_read(UC_X86_REG_ESP))

    def on_tick(machine, _address, _size, _user):
        ticks.append(1)
        machine.reg_write(UC_X86_REG_EAX, 0x897abcde)

    cpu.hook_add(UC_HOOK_CODE, on_tail, begin=RESTORE, end=RESTORE)
    cpu.hook_add(UC_HOOK_CODE, on_tick, begin=TIMER, end=TIMER)
    cpu.emu_start(ENTRY, STOP, count=25000)
    assert tail_stack == [STACK - 40]
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(register) for register in saved) == values
    assert global_long('transarea') == 7 + transarea
    assert len(ticks) == timer_count
    if planar:
        actual = bytes(pixel for cell in zip(*banks) for pixel in cell)
        assert ports[:2] == [(0x3CE, 1, 4), (0x3C4, 1, 2)]
        if timer_count:
            assert any(port == 0x3CF for port, _, _ in ports)
            assert any(port == 0x3C5 for port, _, _ in ports)
    else:
        actual = bytes(cpu.mem_read(FRAME, len(pixels)))
        assert not ports
    assert actual == expected, [(i, a, b) for i, (a, b) in enumerate(zip(actual, expected)) if a != b]


def check(exe, obj):
    original = image(exe)
    raw = ENTRY + 0x25600
    code, references = bind_leaf_details(obj, 'completemirror_', DATA_OFFSETS, address=ENTRY,
                                          functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[raw:raw + SIZE]
    verify_leaf_relocations(code, references, read_le_fixups(exe)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, 'completemirror_', {key: value + DS for key, value in DATA_OFFSETS.items()},
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
    parser.add_argument('object', type=Path, help='Watcom object containing completemirror_')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, {len(CASES)} original and {len(CASES)} restored mirror reversal cases')


if __name__ == '__main__':
    main()
