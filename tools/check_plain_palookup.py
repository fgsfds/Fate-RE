"""Check makepalookup's plain remap, allocation staging, and shared return ABI.

The expected table is computed by direct shade/column indexing. Allocation hooks
only replace the two allocator callees; original frame cleanup and RET 8 execute.
Tint interpolation is outside this fixture's scope.
"""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
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

SYMBOL = 'makepalookup_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
STACK, STOP = 0x3ff000, 0x3fff00
SCRATCH, SCRATCH_SIZE = 0x500000, 0x80000
SOURCE, OUTPUT, REMAP = 0x510040, 0x530040, 0x550040
GUARD = b'\xa7' * 64
SAVED = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)
MALLOC = FUNCTION_ADDRESSES['engine_malloc_']
CACHE = FUNCTION_ADDRESSES['allocache_']


def address(name):
    return DS + DATA_OFFSETS['_' + name]


def exercise(memory, body, *, shades, remap, slot=17, loaded=1, build=1,
             tint=(0, 0, 0), allocation='preallocated'):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_map(SCRATCH, SCRATCH_SIZE)
    cpu.mem_write(ENTRY, body)
    assert len(remap) == 256 and 1 <= slot <= 255
    assert -32768 <= shades <= 32767
    storage_shades = max(1, shades) if 0 <= shades <= 256 else 1
    length = storage_shades * 256
    source = bytes((shade * 73 + color * 29 + (shade ^ color) * 11) & 255
                   for shade in range(storage_shades) for color in range(256))
    initial_output = b'\xd3' * length
    for pointer, contents in ((SOURCE, source), (OUTPUT, initial_output), (REMAP, remap)):
        cpu.mem_write(pointer - len(GUARD), GUARD + contents + GUARD)
    table = bytearray(1024)
    table[0:4] = pack('<I', SOURCE)
    if allocation == 'preallocated':
        table[slot * 4:slot * 4 + 4] = pack('<I', OUTPUT)
    cpu.mem_write(address('palookup'), bytes(table))
    cpu.mem_write(address('numpalookups'), pack('<h', shades))
    cpu.mem_write(address('palette_loaded'), bytes((loaded,)))
    cpu.mem_write(address('palette_lock'), b'\x77')
    r, g, b = tint
    stack_tail = pack('<II', b & 0xffffffff, build & 0xffffffff) + b'\x5a' * 16
    cpu.mem_write(STACK - 128, b'\xc7' * 128)
    cpu.mem_write(STACK, pack('<I', STOP) + stack_tail)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    saved = {reg: 0x12340000 + reg for reg in SAVED}
    for reg, value in saved.items():
        cpu.reg_write(reg, value)
    for reg, value in ((UC_X86_REG_EAX, slot), (UC_X86_REG_EDX, REMAP),
                       (UC_X86_REG_EBX, r), (UC_X86_REG_ECX, g)):
        cpu.reg_write(reg, value & 0xffffffff)
    calls = []

    def return_from_mock(engine):
        sp = engine.reg_read(UC_X86_REG_ESP)
        ret, = unpack('<I', engine.mem_read(sp, 4))
        engine.reg_write(UC_X86_REG_ESP, sp + 4)
        engine.reg_write(UC_X86_REG_EIP, ret)

    def malloc(engine, _address, _size, _data):
        calls.append(('malloc', engine.reg_read(UC_X86_REG_EAX)))
        # The declared allocator ABI preserves ECX, the palette-table offset.
        engine.reg_write(UC_X86_REG_EAX, OUTPUT if allocation == 'malloc' else 0)
        return_from_mock(engine)

    def cache(engine, _address, _size, _data):
        args = tuple(engine.reg_read(reg) for reg in
                     (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX))
        calls.append(('cache',) + args)
        assert args == (address('palookup') + slot * 4, (shades * 256) & 0xffffffff,
                        address('palette_lock')), args
        engine.mem_write(args[0], pack('<I', OUTPUT))
        # Exercise the declared volatile registers while preserving the others.
        for reg, value in ((UC_X86_REG_EAX, 0xa1a1a1a1),
                           (UC_X86_REG_EDX, 0xd2d2d2d2),
                           (UC_X86_REG_EBX, 0xb3b3b3b3)):
            engine.reg_write(reg, value)
        return_from_mock(engine)

    cpu.hook_add(UC_HOOK_CODE, malloc, begin=MALLOC, end=MALLOC)
    cpu.hook_add(UC_HOOK_CODE, cache, begin=CACHE, end=CACHE)
    cpu.emu_start(ENTRY, STOP, count=1_500_000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP, 'did not return'
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 12, 'shared RET 8 cleanup'
    assert cpu.mem_read(STACK + 4, len(stack_tail)) == stack_tail, 'incoming stack arguments'
    assert cpu.mem_read(STACK - 128, 64) == b'\xc7' * 64, 'stack frame guard'
    assert all(cpu.reg_read(reg) == value for reg, value in saved.items()), 'saved registers'

    expected_calls = []
    if loaded and allocation != 'preallocated':
        expected_calls.append(('malloc', (shades * 256) & 0xffffffff))
        if allocation == 'cache':
            expected_calls.append(('cache', address('palookup') + slot * 4,
                                   (shades * 256) & 0xffffffff, address('palette_lock')))
        table[slot * 4:slot * 4 + 4] = pack('<I', OUTPUT)
    assert calls == expected_calls, (calls, expected_calls)
    assert cpu.mem_read(address('palookup'), 1024) == table, 'palette pointer table'
    assert cpu.mem_read(address('palette_lock'), 1) == b'\x77', 'mock lock guard'
    assert cpu.mem_read(address('numpalookups'), 2) == pack('<h', shades)
    assert cpu.mem_read(address('palette_loaded'), 1) == bytes((loaded,))

    generated = bool(loaded and (build & 255) and all((v & 255) == 0 for v in tint) and shades > 0)
    if generated:
        assert 1 <= shades <= storage_shades
        expected = bytes(source[shade * 256 + remap[column]]
                         for shade in range(shades) for column in range(256))
    else:
        expected = initial_output
    assert cpu.mem_read(OUTPUT, length) == expected, 'independent remap oracle'
    for pointer, contents in ((SOURCE, source), (REMAP, remap)):
        assert cpu.mem_read(pointer, len(contents)) == contents, 'input mutated'
    for pointer, size in ((SOURCE, length), (OUTPUT, length), (REMAP, 256)):
        assert cpu.mem_read(pointer - len(GUARD), len(GUARD)) == GUARD, 'prefix guard'
        assert cpu.mem_read(pointer + size, len(GUARD)) == GUARD, 'suffix guard'
    return bytes(cpu.mem_read(OUTPUT, length)), calls


def cases():
    identity = bytes(range(256))
    reverse = identity[::-1]
    pattern = bytes((i * 73 + (i >> 2) * 19 + 7) & 255 for i in range(256))
    result = []
    for shades in (1, 2, 32, 256):
        for name, remap in (('identity', identity), ('reverse', reverse), ('pattern', pattern)):
            result.append((f'{shades}-{name}', dict(shades=shades, remap=remap)))
    for slot in (1, 255):
        result.append((f'slot-{slot}', dict(shades=2, remap=pattern, slot=slot)))
    controls = (
        ('not-loaded', dict(loaded=0)),
        ('not-loaded-unallocated', dict(loaded=0, allocation='cache')),
        ('not-built', dict(build=0)),
        ('build-low-byte-zero', dict(build=0x11223300)),
        ('loaded-nonzero', dict(loaded=2)),
        ('high-tint-bits-ignored', dict(tint=(0x12340000, 0x56780000, 0x90ab0000), build=0x123401)),
        ('invalid-red', dict(tint=(64, 0, 0))),
        ('invalid-green', dict(tint=(0, 128, 0))),
        ('invalid-blue', dict(tint=(0, 0, 255))),
        ('zero-shades', dict(shades=0)),
        ('negative-shades', dict(shades=-1)),
        ('short-minimum-no-shades', dict(shades=-32768)),
        ('short-minimum-bypass', dict(shades=-32768, build=0)),
        ('short-maximum-bypass', dict(shades=32767, build=0)),
    )
    for name, overrides in controls:
        result.append((name, dict(dict(shades=2, remap=pattern), **overrides)))
    for mode in ('malloc', 'cache'):
        for name, overrides in (('generate', {}), ('bypass', dict(build=0)),
                                ('invalid-tint', dict(tint=(64, 0, 0)))):
            result.append((f'{mode}-{name}', dict(dict(shades=32, remap=reverse, allocation=mode), **overrides)))
    for mode in ('malloc', 'cache'):
        for shades in (-32768, -1, 32767):
            result.append((f'{mode}-signed-boundary-{shades}',
                           dict(shades=shades, remap=pattern, allocation=mode, build=0)))
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
    restored, _ = bind_leaf_details(obj, SYMBOL, {k: DS + v for k, v in DATA_OFFSETS.items()},
                                    address=ENTRY, functions=FUNCTION_ADDRESSES)
    memory = image(exe)
    scenarios = cases()
    for name, arguments in scenarios:
        try:
            original = exercise(memory, memory[ENTRY:ENTRY + SIZE], **arguments)
            candidate = exercise(memory, restored, **arguments)
            assert original == candidate
        except Exception as error:
            raise AssertionError(f'plain palookup case {name}: {error}') from error
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, '
          f'{len(scenarios)} original and {len(scenarios)} restored plain palookups')


if __name__ == '__main__':
    main()