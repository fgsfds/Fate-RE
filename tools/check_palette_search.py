"""Verify palette bucket search and exhaustive weighted nearest-color selection."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOL = 'getclosestcol_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
STACK, STOP = 0x3ff000, 0x3fff00
WEIGHTS = (30, 59, 11)
SAVED = (UC_X86_REG_EBP, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_ESI)


def exercise(memory, body, colors, query, fallback, expected=None):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def address(name):
        return DS + DATA_OFFSETS['_' + name]

    palette_bytes = bytes(value for color in colors for value in color)
    cpu.mem_write(address('palette'), palette_bytes)
    for name, weight in zip(('red', 'green', 'blue'), WEIGHTS):
        table = [(i - 64) ** 2 * weight for i in range(129)]
        cpu.mem_write(address(name + '_color_distance'), pack('<129i', *table))
    cpu.mem_write(address('color_neighbor_order'), bytes((0, 1, 2, 3, 4, 3, 2, 1)))
    cpu.mem_write(address('pow2char'), bytes(1 << bit for bit in range(8)))
    neighbors = [r + g + b for r in (-64, 0, 64) for g in (-8, 0, 8) for b in (-1, 0, 1)]
    neighbors[13], neighbors[26] = neighbors[26], neighbors[13]
    cpu.mem_write(address('palette_neighbor_offsets'), pack('<28i', 0, *neighbors))

    bits, heads, links = bytearray(125), bytearray(1000), [-1] * 256
    for i in range(255, -1, -1):
        r, g, b = colors[i]
        bucket = (r >> 3) * 64 + (g >> 3) * 8 + (b >> 3) + 73
        mask = 1 << (bucket & 7)
        if bits[bucket >> 3] & mask:
            links[i] = heads[bucket]
        bits[bucket >> 3] |= mask
        heads[bucket] = i
    if fallback:
        bits[:] = bytes(len(bits))
    cpu.mem_write(address('occupied_palette_buckets'), bytes(bits))
    cpu.mem_write(address('palette_bucket_head'), bytes(heads))
    cpu.mem_write(address('palette_bucket_next'), pack('<256i', *links))

    # At this instruction the reference starts its exhaustive scan.
    fallback_visits = []
    def record_fallback(engine, _address, _size, _data):
        fallback_visits.append(True)
    cpu.hook_add(UC_HOOK_CODE, record_fallback, begin=ENTRY + 0x17c, end=ENTRY + 0x17c)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa7' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg in SAVED:
        cpu.reg_write(reg, 0x11220000 + reg)
    for reg, val in zip((UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX), query):
        cpu.reg_write(reg, val)
    cpu.emu_start(ENTRY, STOP, count=20000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa7' * 16
    assert all(cpu.reg_read(reg) == 0x11220000 + reg for reg in SAVED)
    if fallback:
        assert fallback_visits == [True]
    result = cpu.reg_read(UC_X86_REG_EAX)
    distances = [sum(weight * (channel - wanted) ** 2
                     for weight, channel, wanted in zip(WEIGHTS, color, query)) for color in colors]
    assert result < 256 and distances[result] == min(distances), (query, result)
    if expected is not None:
        assert result == expected, (query, result, expected)
    assert cpu.mem_read(address('palette'), 768) == palette_bytes
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[RAW:RAW + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, {k: DS + v for k, v in DATA_OFFSETS.items()},
                                     address=ENTRY, functions=FUNCTION_ADDRESSES)
    memory = image(exe)
    grid = [(i % 8 * 8, (i >> 3) % 8 * 8, (i >> 6) * 16) for i in range(256)]
    linked = [(0, 0, 0)] * 256
    linked[0], linked[1] = (32, 32, 32), (36, 36, 36)
    weighted = [(63, 63, 63)] * 256
    weighted[0], weighted[1] = (30, 35, 30), (37, 30, 30)
    cases = [(grid, q, f, None) for f in (False, True)
             for q in ((0, 0, 0), (63, 63, 63), (7, 8, 15), (36, 36, 36))]
    cases += [(linked, (36, 36, 36), False, 1),
              (weighted, (30, 30, 30), False, 1),
              ([(20, 20, 20)] * 256, (20, 20, 20), False, 0),
              ([(20, 20, 20)] * 256, (20, 20, 20), True, 255)]
    for case in cases:
        original = exercise(memory, memory[ENTRY:ENTRY + SIZE], *case)
        restored = exercise(memory, relocated, *case)
        assert original == restored
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} original and {len(cases)} restored palette cases')


if __name__ == '__main__':
    main()
