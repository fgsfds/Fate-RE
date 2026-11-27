"""Verify the 25 board route dispatch entries and their shared continuation."""
import argparse
from pathlib import Path
from struct import pack, unpack_from

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EIP, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    CODE_OFFSETS, DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, SPRITE_PATH_BOARDS,
    bind_leaf_details, verify_leaf_relocations,
)

ENTRY_SYMBOL = 'route_actor_toward_target_'
SYMBOL = 'initialize_board_routes_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
RESOLVE = FUNCTION_ADDRESSES['resolve_route_sectors_']
STACK = 0x3f0000
ARGUMENT_REGISTERS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
ARGUMENTS = tuple(DATA_OFFSETS[name] for name in (
    '_route_last_zone', '_route_zone_routes', '_route_zone_bounds', '_route_records',
))


def check_dispatch(code, destinations):
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0x10000, 0x30000)
    emulator.mem_map(STACK - 0x1000, 0x1000)
    emulator.mem_write(ENTRY, code)
    initializers = [FUNCTION_ADDRESSES[name] for name in reversed(SPRITE_PATH_BOARDS)]
    for address in initializers:
        emulator.mem_write(address, b'\xc3')
    called = []

    def record_call(cpu, address, size, user_data):
        called.append((address, tuple(cpu.reg_read(reg) for reg in ARGUMENT_REGISTERS)))

    emulator.hook_add(UC_HOOK_CODE, record_call, begin=min(initializers), end=max(initializers))
    for case, (destination, initializer) in enumerate(zip(destinations, initializers), 1):
        called.clear()
        emulator.reg_write(UC_X86_REG_ESP, STACK)
        emulator.emu_start(destination, RESOLVE, count=12)
        assert emulator.reg_read(UC_X86_REG_EIP) == RESOLVE, case
        assert emulator.reg_read(UC_X86_REG_ESP) == STACK, case
        assert called == [(initializer, ARGUMENTS)], (case, called)


def check_route_cache(code, destinations):
    entry = FUNCTION_ADDRESSES[ENTRY_SYMBOL]
    find_sprite = FUNCTION_ADDRESSES['route_find_actor_sprite_']
    dispatch = CODE_OFFSETS['_route_navigation_dispatch']
    loaded_board = DATA_OFFSETS['_route_loaded_board']
    current_board = DATA_OFFSETS['_route_current_board']
    cache = DATA_OFFSETS['_actor_route_cache']
    seed = pack('<II', 17, 23)
    cleared = pack('<II', 0xffffffff, 23)
    for loaded, current, target in (
        (1, 1, find_sprite),
        (2, 1, destinations[0]),
        (1, 25, destinations[-1]),
        (1, 0, RESOLVE),
        (1, 26, RESOLVE),
        (1, -1, RESOLVE),
    ):
        emulator = Uc(UC_ARCH_X86, UC_MODE_32)
        emulator.mem_map(0, 0x100000)
        emulator.mem_map(STACK - 0x1000, 0x1000)
        emulator.mem_write(entry, code)
        emulator.mem_write(dispatch, pack('<25I', *destinations))
        emulator.mem_write(loaded_board, pack('<h', loaded))
        emulator.mem_write(current_board, pack('<b', current))
        emulator.mem_write(cache, seed * 501)
        emulator.reg_write(UC_X86_REG_ESP, STACK)
        emulator.emu_start(entry, target, count=4000)
        assert emulator.reg_read(UC_X86_REG_EIP) == target, (loaded, current)
        assert emulator.reg_read(UC_X86_REG_ESP) == STACK - 0x48
        assert emulator.mem_read(loaded_board, 2) == pack('<h', current)
        expected_cache = seed if loaded == current else cleared
        assert emulator.mem_read(cache, 501 * len(seed)) == expected_cache * 500 + seed


def check(executable, obj):
    restored, bindings = bind_leaf_details(
        obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    expected = executable[RAW:RAW + SIZE]
    assert restored == expected
    pointers = read_le_fixups(executable)['pointers']
    verify_leaf_relocations(restored, bindings, pointers, ENTRY)
    destinations = [offset + 0x10000 for offset in unpack_from('<25I', executable, 0x4298a)]
    assert destinations[0] == ENTRY and all(ENTRY <= dest < RESOLVE for dest in destinations)
    for code in (expected, restored):
        check_dispatch(code, destinations)
    raw, size = LEAVES[ENTRY_SYMBOL]
    entry = FUNCTION_ADDRESSES[ENTRY_SYMBOL]
    code_bindings = {}
    head, head_bindings = bind_leaf_details(
        obj, ENTRY_SYMBOL, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES,
        absolute_code=CODE_OFFSETS, code_bindings=code_bindings,
    )
    expected_head = executable[raw:raw + size]
    assert head == expected_head
    verify_leaf_relocations(head, head_bindings, pointers, entry, code_bindings=code_bindings)
    for code in (expected_head, head):
        check_route_cache(code, destinations)
    return len(bindings) + len(head_bindings)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    sites = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE + LEAVES[ENTRY_SYMBOL][1]} exact bytes, {sites} LE relocations, '
          '25 dispatch and 6 cache cases for original and restored routing')


if __name__ == '__main__':
    main()
