"""Check the palette initializer's tables, bucket chains, and register ABI."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOL = 'initialize_color_lookup_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
STACK, STOP = 0x3ff000, 0x3fff00
SAVED = (UC_X86_REG_EBP, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_ESI)


def exercise(memory, body, colors, weights):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def address(name):
        return DS + DATA_OFFSETS['_' + name]

    palette = bytes(channel for color in colors for channel in color)
    powers = bytes(1 << i for i in range(8))
    cpu.mem_write(address('palette'), palette)
    cpu.mem_write(address('pow2char'), powers)
    fields = (('red_color_distance', 516), ('green_color_distance', 516),
              ('blue_color_distance', 516), ('palette_bucket_next', 1024),
              ('palette_neighbor_offsets', 112), ('occupied_palette_buckets', 125),
              ('palette_bucket_head', 1000))
    for name, length in fields:
        cpu.mem_write(address(name), b'\xa7' * length)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg in SAVED:
        cpu.reg_write(reg, 0x12340000 + reg)
    for reg, value in zip((UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX), weights):
        cpu.reg_write(reg, value & 0xffffffff)
    cpu.emu_start(ENTRY, STOP, count=30000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(reg) == 0x12340000 + reg for reg in SAVED)
    assert cpu.mem_read(address('palette'), len(palette)) == palette
    assert cpu.mem_read(address('pow2char'), len(powers)) == powers

    for channel, weight in zip(('red', 'green', 'blue'), weights):
        expected = pack('<129I', *((weight * (i - 64) ** 2) & 0xffffffff for i in range(129)))
        assert cpu.mem_read(address(channel + '_color_distance'), len(expected)) == expected, channel

    # Collect each chain in increasing palette-index order, independently of
    # the initializer's backward traversal and incremental bitset updates.
    chains = {}
    for i, (r, g, b) in enumerate(colors):
        bucket = (r // 8) * 64 + (g // 8) * 8 + b // 8 + 73
        chains.setdefault(bucket, []).append(i)
    bits, heads, links = bytearray(125), bytearray(1000), [-1] * 256
    for bucket, indices in chains.items():
        bits[bucket // 8] |= 1 << (bucket % 8)
        heads[bucket] = indices[0]
        for entry, following in zip(indices, indices[1:]):
            links[entry] = following
    assert cpu.mem_read(address('occupied_palette_buckets'), len(bits)) == bits
    assert cpu.mem_read(address('palette_bucket_head'), len(heads)) == heads
    assert cpu.mem_read(address('palette_bucket_next'), 1024) == pack('<256i', *links)

    neighbors = [r + g + b for r in (-64, 0, 64) for g in (-8, 0, 8) for b in (-1, 0, 1)]
    neighbors[13], neighbors[26] = neighbors[26], neighbors[13]
    assert cpu.mem_read(address('palette_neighbor_offsets'), 112) == b'\xa7' * 4 + pack('<27i', *neighbors)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(exe)
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == exe[RAW:RAW + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, {k: DS + v for k, v in DATA_OFFSETS.items()},
                                     address=ENTRY, functions=FUNCTION_ADDRESSES)
    grid = [(i % 8 * 8, (i >> 3) % 8 * 8, (i >> 6) * 16) for i in range(256)]
    cases = (
        (grid, (30, 59, 11)),
        ([(20, 20, 20)] * 256, (1, 1, 1)),
        ([(i % 64, 63 - i % 64, (i * 7) % 64) for i in range(256)], (9, 3, 7)),
        ([(0, 0, 0), (63, 63, 63)] * 128, (0x7fffffff, 0, -1)),
    )
    for body in (memory[ENTRY:ENTRY + SIZE], relocated):
        for colors, weights in cases:
            exercise(memory, body, colors, weights)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} original and {len(cases)} restored palette initializations')


if __name__ == '__main__':
    main()
