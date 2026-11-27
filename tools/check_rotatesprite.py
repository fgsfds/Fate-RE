"""Verify and exercise the rotated-sprite wrapper with emulated renderer calls.

The pinned executable and Watcom object are checked for exact bytes and LE data
relocations before both versions run through the same modeled queue cases.
"""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_ESP, UC_X86_REG_EBP, UC_X86_REG_EIP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)

SYMBOL = 'rotatesprite_'
ENTRY, STACK, STOP = 0x57181, 0x3ff000, 0x3fff00
ANIMATE = FUNCTION_ADDRESSES['animateoffs_']
DRAW = FUNCTION_ADDRESSES['draw_rotated_sprite_']
DATA = {
    name: DS + DATA_OFFSETS['_' + name]
    for name in (
        'picanm', 'tilesizx', 'tilesizy', 'display_page_count', 'permanent_sprite_tail',
        'permanent_sprite_head', 'permanent_sprite_queue', 'permanent_sprite_phase',
        'draw_single_page_sprite',
    )
}
ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
SAVED = (UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
MASK = 0xffffffff
QUEUE_SIZE, RECORD_SIZE = 512, 36
CLIP = (2, 3, 55, 74)
CASES = (
    (16, CLIP, (12, 17), True, 2, 128, 8, 0, False),
    (256, (6, 3, 4, 50), (12, 17), True, 2, 0, 8, 0, False),
    (256, (6, 5, 17, 2), (12, 17), True, 2, 0, 8, 0, False),
    (256, CLIP, (0, 17), True, 2, 128, 8, 0, False),
    (256, CLIP, (12, -1), True, 2, 128, 8, 0, False),
    (256, CLIP, (12, 17), False, 2, 0, 8, 0, False),
    (256, CLIP, (12, 17), True, 1, 192, 2, 2, True),
    (256, CLIP, (12, 17), True, 2, 128, 511, 3, True),
    (256, CLIP, (12, 17), False, 3, 192, 1, 0, True),
    (256, CLIP, (6, 8), False, 3, 192, 81, 1, True),
    (256, (-2, -3, 5, 7), (32, 29), True, 6, 192, 1, 2, True),
)


def pack_sprite(x, y, zoom, angle, tile, shade, palette, flags, pages, clip):
    return pack('<3i2h4B4i', x, y, zoom, angle, tile, shade & 255, palette, flags, pages, *clip)


def check_case(code, zoom, clip, dimensions, animated, page_count, flags, tail, phase, scan_records):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3f0000)
    machine.mem_write(ENTRY, code)
    machine.mem_write(ANIMATE, b'\xc3')
    machine.mem_write(DRAW, b'\xc2\x20\x00')

    def put(name, fmt, *values, offset=0):
        machine.mem_write(DATA[name] + offset, pack('<' + fmt, *values))

    def get(name, length, offset=0):
        return bytes(machine.mem_read(DATA[name] + offset, length))

    x, y, angle, tile, shade, palette = -500, 294, 311, 47, -11, 123
    put('picanm', 'I', 0x40 if animated else 0, offset=4 * tile)
    drawn_tile = tile + int(animated)
    old_tile = drawn_tile + 1
    old_dimensions = (7, 9)
    for index, (width, height) in ((drawn_tile, dimensions), (old_tile, old_dimensions)):
        put('tilesizx', 'h', width, offset=2 * index)
        put('tilesizy', 'h', height, offset=2 * index)
    head = (tail - 5) % QUEUE_SIZE if scan_records else tail
    put('display_page_count', 'i', page_count)
    put('permanent_sprite_tail', 'i', tail)
    put('permanent_sprite_head', 'i', head)
    put('permanent_sprite_phase', 'B', phase)
    put('draw_single_page_sprite', 'B', 77)

    queue = [b'\x99' * RECORD_SIZE for _ in range(QUEUE_SIZE)]
    prior_entries = []
    if scan_records:
        left, top, right, bottom = clip
        variants = (
            (y, angle, 3, (left + 1, top + 2, right - 1, bottom - 2)),
            (y + 5, angle, 3, clip),
            (y, angle + 1, 3, clip),
            (y, angle, 0x80, clip),
            (y, angle, 3, (left - 1, top, right, bottom)),
        )
        for i, (old_y, old_angle, active_pages, old_clip) in enumerate(variants):
            index = (head + i) % QUEUE_SIZE
            prior_entries.append((index, old_y, old_angle, active_pages, old_clip))
            queue[index] = pack_sprite(
                x, old_y, zoom, old_angle, old_tile, shade, palette, flags, active_pages, old_clip,
            )
    machine.mem_write(DATA['permanent_sprite_queue'] - 4, b'left' + b''.join(queue) + b'edge')

    calls = []

    def record_call(emu, address, _size, _data):
        if address == ANIMATE:
            calls.append(('animate', emu.reg_read(UC_X86_REG_EAX), emu.reg_read(UC_X86_REG_EDX)))
            emu.reg_write(UC_X86_REG_EAX, 1)
        elif address == DRAW:
            registers = tuple(emu.reg_read(reg) for reg in ARGS)
            stacked = unpack('<8I', emu.mem_read(emu.reg_read(UC_X86_REG_ESP) + 4, 32))
            calls.append(('draw', *registers, *stacked))

    machine.hook_add(UC_HOOK_CODE, record_call)
    for index, reg in enumerate(SAVED):
        machine.reg_write(reg, 0x123400 + index)
    for reg, value in zip(ARGS, (x, y, zoom, angle)):
        machine.reg_write(reg, value & MASK)
    machine.reg_write(UC_X86_REG_ESP, STACK)
    machine.mem_write(STACK, pack('<I8i', STOP, tile, shade, palette, flags, *clip))
    machine.emu_start(ENTRY, STOP, count=1400)

    legal = zoom > 16 and clip[0] <= clip[2] and clip[1] <= clip[3]
    drawn = legal and all(dimension > 0 for dimension in dimensions)
    expected_calls = []
    if legal and animated:
        expected_calls.append(('animate', tile, -16384 & MASK))
    if drawn:
        expected_calls.append((
            'draw', x & MASK, y, zoom, angle, drawn_tile, shade & MASK, palette, flags,
            *(bound & MASK for bound in clip),
        ))
    assert calls == expected_calls, (calls, expected_calls)

    next_tail, single_page = tail, 77
    if drawn and flags & 128:
        if page_count < 2:
            single_page = 1
        else:
            pages = (page_count + ((phase & 1) << 7)) & 255
            queue[tail] = pack_sprite(x, y, zoom, angle, drawn_tile, shade, palette, flags, pages, clip)
            if flags & 64 and all(old <= new for old, new in zip(old_dimensions, dimensions)):
                for index, old_y, old_angle, active_pages, old_clip in prior_entries:
                    covered = (all(old >= new for old, new in zip(old_clip[:2], clip[:2]))
                               and all(old <= new for old, new in zip(old_clip[2:], clip[2:])))
                    if active_pages & 127 and old_y == y and old_angle == angle and covered:
                        queue[index] = queue[index][:19] + b'\0' + queue[index][20:]
            next_tail = (tail + 1) % QUEUE_SIZE

    assert get('permanent_sprite_queue', QUEUE_SIZE * RECORD_SIZE + 8, -4) == (
        b'left' + b''.join(queue) + b'edge'
    )
    assert get('permanent_sprite_tail', 4) == pack('<i', next_tail)
    assert get('permanent_sprite_head', 4) == pack('<i', head)
    assert get('draw_single_page_sprite', 1) == bytes([single_page])
    assert machine.reg_read(UC_X86_REG_EIP) == STOP
    assert machine.reg_read(UC_X86_REG_ESP) == STACK + 36
    assert [machine.reg_read(reg) for reg in SAVED] == [0x123400 + i for i in range(len(SAVED))]


def check(executable, obj):
    original = image(executable)
    raw, size = LEAVES[SYMBOL]
    assert raw - 0x25600 == ENTRY
    code, bindings = bind_leaf_details(
        obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    assert len(code) == size and code == executable[raw:raw + size]
    verify_leaf_relocations(code, bindings, read_le_fixups(executable)['pointers'], ENTRY)
    restored, _ = bind_leaf_details(
        obj, SYMBOL, {'_' + name: offset for name, offset in DATA.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    for source in (original[ENTRY:ENTRY + size], restored):
        for case in CASES:
            check_case(source, *case)
    return size, len(bindings), len(CASES)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing rotatesprite_')
    args = parser.parse_args()
    size, relocations, cases = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {size} bytes, {relocations} LE relocations, {cases} original and {cases} restored rotated-sprite cases')
