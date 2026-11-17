"""Verify exact waypoint-sector setup and actor zone selection."""
import argparse
from pathlib import Path
from struct import pack, unpack_from

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations,
)
from verify_c_suite import ROUTE_BOUNDS_ENTRIES, ROUTE_CROSSING_ENTRIES, ROUTE_SECTOR_ENTRIES

START = FUNCTION_ADDRESSES['resolve_route_sectors_']
STOP = FUNCTION_ADDRESSES['route_find_actor_sprite_']
FORMAT = FUNCTION_ADDRESSES['format_route_error_']
REPORT = FUNCTION_ADDRESSES['report_route_error_']
UPDATE = FUNCTION_ADDRESSES['updatesector_']
STACK, WAYPOINTS, SECTORS = 0x3f0000, 0x100000, 0x101000


def scan(code, zones):
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0, 0x110000)
    emulator.mem_map(STACK - 0x1000, 0x2000)
    emulator.mem_write(START, code)
    for target in (UPDATE, FORMAT, REPORT):
        emulator.mem_write(target, b'\xc3')
    emulator.reg_write(UC_X86_REG_ESP, STACK)
    emulator.mem_write(DATA_OFFSETS['_route_last_zone'], pack('<h', len(zones) - 1))
    calls, logs, reports = [], [], []

    def update(cpu, address, size, user_data):
        x = cpu.reg_read(UC_X86_REG_EAX)
        y = cpu.reg_read(UC_X86_REG_EDX)
        output = cpu.reg_read(UC_X86_REG_EBX)
        assert output == STACK + 0x24
        calls.append((x, y))
        cpu.mem_write(output, pack('<h', -1 if x == 99 else x + y))

    def format_error(cpu, address, size, user_data):
        pointer = cpu.reg_read(UC_X86_REG_ESP) + 4
        _, message, zone = unpack_from('<III', cpu.mem_read(pointer, 12))
        logs.append((message, zone))
        if message == DATA_OFFSETS['_route_bad_waypoint']:
            assert tuple(unpack_from('<III', cpu.mem_read(pointer + 12, 12))) == (0, 99, 3)

    def report_error(cpu, address, size, user_data):
        reports.append(cpu.reg_read(UC_X86_REG_EAX))

    for index, points in enumerate(zones):
        waypoints = WAYPOINTS + index * 512
        sectors = SECTORS + index * 128
        record = DATA_OFFSETS['_route_records'] + index * 22
        emulator.mem_write(record, pack('<II', waypoints, sectors))
        emulator.mem_write(waypoints, b''.join(pack('<ii', *point) for point in points))
        emulator.mem_write(sectors, pack('<h', -3) * 52)
    for hook, target in ((update, UPDATE), (format_error, FORMAT), (report_error, REPORT)):
        emulator.hook_add(UC_HOOK_CODE, hook, begin=target, end=target)

    emulator.emu_start(START, STOP, count=4000)
    assert emulator.reg_read(UC_X86_REG_EIP) == STOP
    assert emulator.reg_read(UC_X86_REG_ESP) == STACK
    assert reports == [DATA_OFFSETS['_route_error_buffer']] * len(logs)
    output = [unpack_from('<52h', emulator.mem_read(SECTORS + i * 128, 104))
              for i in range(len(zones))]
    return calls, logs, output


def zone_selection(code, actor, destination, bounds, expected, *, scripted=False):
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0, 0x300000)
    emulator.mem_map(STACK - 0x1000, 0x2000)
    emulator.mem_write(STOP, code)
    emulator.reg_write(UC_X86_REG_ESP, STACK)
    x, y = destination
    emulator.mem_write(STACK + 4, pack('<iii', y, x, 2))
    emulator.mem_write(STACK + 0x2c, pack('<ii', -1, 0))
    emulator.mem_write(STACK + 0x34, pack('<i', -1))
    emulator.mem_write(DATA_OFFSETS['_route_actor_sprite'] + 4, pack('<h', 3))
    emulator.mem_write(DATA_OFFSETS['_route_actor_sequence'] + 2, b'\x19')
    sprite = 44 * 3
    emulator.mem_write(DATA_OFFSETS['_route_sprite_x'] + sprite, pack('<ii', *actor))
    emulator.mem_write(DATA_OFFSETS['_route_sprite_hitag'] + sprite, pack('<h', 0x4000 if scripted else 0))
    emulator.mem_write(DATA_OFFSETS['_route_zone_bounds'], pack('<I', WAYPOINTS))
    emulator.mem_write(DATA_OFFSETS['_route_last_zone'], pack('<h', len(bounds) - 1))
    emulator.mem_write(WAYPOINTS, b''.join(pack('<iiii', *row) for row in bounds))
    end = FUNCTION_ADDRESSES['finish_actor_route_'] if scripted else STOP + len(code)
    emulator.emu_start(STOP, end, count=1000)
    assert emulator.reg_read(UC_X86_REG_EIP) == end
    assert emulator.reg_read(UC_X86_REG_ESP) == STACK
    assert unpack_from('<h', emulator.mem_read(STACK + 0x28, 2))[0] == 3
    selection = (unpack_from('<i', emulator.mem_read(STACK + 0x2c, 4))[0],
                 unpack_from('<i', emulator.mem_read(STACK + 0x34, 4))[0])
    assert selection == expected, selection
    if not scripted:
        assert emulator.mem_read(STACK + 0x38, 1) == b'\x19'


def zone_crossing(code, x, y, expected):
    entry = LEAVES['route_read_zone_route_'][0] - 0x25600
    exit_route = FUNCTION_ADDRESSES['route_move_to_zone_exit_']
    restore = FUNCTION_ADDRESSES['finish_actor_route_']
    abs_long = FUNCTION_ADDRESSES['absolute_long_']
    change_sector = FUNCTION_ADDRESSES['changespritesect_']
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0, 0x300000)
    emulator.mem_map(STACK - 0x1000, 0x2000)
    emulator.mem_write(entry, code)
    for routine in (abs_long, change_sector):
        emulator.mem_write(routine, b'\xc3')
    emulator.reg_write(UC_X86_REG_ESP, STACK)
    emulator.reg_write(UC_X86_REG_EBX, 1)
    emulator.reg_write(UC_X86_REG_EDX, x)
    for offset, value in ((0x0c, 2), (0x1c, y), (0x28, 3), (0x2c, 0), (0x34, 1)):
        emulator.mem_write(STACK + offset, pack('<i', value))

    data = DATA_OFFSETS
    route_table = WAYPOINTS + 0x400
    emulator.mem_write(data['_route_zone_routes'], pack('<I', route_table))
    emulator.mem_write(route_table + 3, bytes((1, 2, 1)))
    emulator.mem_write(data['_route_last_zone'], pack('<h', 1))
    for zone, point in enumerate(((400, 500), (1000, 1100))):
        waypoints = WAYPOINTS + zone * 32
        sectors = SECTORS + zone * 32
        emulator.mem_write(waypoints, pack('<ii', *point))
        emulator.mem_write(sectors, pack('<h', 7))
        emulator.mem_write(data['_route_records'] + zone * 22, pack('<II', waypoints, sectors))
    sprite = 3 * 44
    emulator.mem_write(data['_route_sprite_x'] + sprite, pack('<iii', x, y, 780))
    emulator.mem_write(data['_route_sprite_sector'] + sprite, pack('<h', 3))
    for index, floor in ((3, 4000), (7, 8000)):
        emulator.mem_write(data['_route_sector_floor_z'] + index * 40, pack('<i', floor))
    cache = data['_actor_route_cache'] + 2 * 8
    emulator.mem_write(cache, pack('<ii', 23, 25))
    changes = []

    def get_absolute(cpu, address, size, user_data):
        value = cpu.reg_read(UC_X86_REG_EAX)
        signed = value - 0x100000000 if value & 0x80000000 else value
        cpu.reg_write(UC_X86_REG_EAX, abs(signed))

    def set_sector(cpu, address, size, user_data):
        changes.append((cpu.reg_read(UC_X86_REG_EAX), cpu.reg_read(UC_X86_REG_EDX)))

    emulator.hook_add(UC_HOOK_CODE, get_absolute, begin=abs_long, end=abs_long)
    emulator.hook_add(UC_HOOK_CODE, set_sector, begin=change_sector, end=change_sector)
    end = restore if expected else exit_route
    emulator.emu_start(entry, end, count=500)
    assert emulator.reg_read(UC_X86_REG_EIP) == end
    assert emulator.reg_read(UC_X86_REG_ESP) == STACK
    assert changes == ([(3, 7)] if expected else [])
    expected_position = (1000, 1100, 4780) if expected else (x, y, 780)
    assert unpack_from('<iii', emulator.mem_read(data['_route_sprite_x'] + sprite, 12)) == expected_position
    assert unpack_from('<ii', emulator.mem_read(cache, 8)) == ((-1, 25) if expected else (23, 25))


def path_arguments(same_zone, exit_path, *, same):
    same_entry = LEAVES['route_choose_actor_target_'][0] - 0x25600
    exit_entry = FUNCTION_ADDRESSES['route_move_to_zone_exit_']
    select = FUNCTION_ADDRESSES['select_sprite_path_target_']
    return_address = 0x22000
    emulator = Uc(UC_ARCH_X86, UC_MODE_32)
    emulator.mem_map(0, 0x110000)
    emulator.mem_map(STACK - 0x1000, 0x2000)
    emulator.mem_write(same_entry, same_zone)
    emulator.mem_write(exit_entry, exit_path)
    emulator.mem_write(select, bytes((0xc2, 36, 0)))
    emulator.reg_write(UC_X86_REG_ESP, STACK)
    slots = (
        (0, 8), (4, 92), (8, 32), (0x0c, 2), (0x20, 6), (0x28, 3),
        (0x2c, 1), (0x34, 1 if same else 0), (0x38, 19),
        (0x3c, 0x765), (0x40, 0x456), (0x44, 0x123), (0x48, return_address),
    )
    for offset, value in slots:
        emulator.mem_write(STACK + offset, pack('<i', value))
    record = DATA_OFFSETS['_route_records'] + 22
    emulator.mem_write(record, pack('<IIIhii', WAYPOINTS, SECTORS, SECTORS + 512, 8, 440, 380))
    captured = []

    def record_args(cpu, address, size, user_data):
        registers = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
        captured.append((tuple(cpu.reg_read(reg) for reg in registers),
                         unpack_from('<9i', cpu.mem_read(cpu.reg_read(UC_X86_REG_ESP) + 4, 36))))

    emulator.hook_add(UC_HOOK_CODE, record_args, begin=select, end=select)
    emulator.emu_start(same_entry if same else exit_entry, return_address, count=150)
    expected = (-1 if same else 6, WAYPOINTS, SECTORS, SECTORS + 512, 8, 440, 380,
                19, DATA_OFFSETS['_actor_route_cache'] + 16)
    assert captured == [((3, 32, 92, 8), expected)]
    assert emulator.reg_read(UC_X86_REG_EIP) == return_address
    assert emulator.reg_read(UC_X86_REG_ESP) == STACK + 0x4c
    assert tuple(emulator.reg_read(reg) for reg in (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)) == (
        0x765, 0x456, 0x123,
    )


def bind_blocks(executable, obj, symbols):

    original, restored = bytearray(), bytearray()
    pointers = read_le_fixups(executable)['pointers']
    sites = 0
    start = LEAVES[symbols[0]][0] - 0x25600
    for symbol in symbols:
        raw, size = LEAVES[symbol]
        entry = raw - 0x25600
        assert entry == start + len(original)
        expected = executable[raw:raw + size]
        code, bindings = bind_leaf_details(
            obj, symbol, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES,
        )
        assert code == expected, symbol
        verify_leaf_relocations(code, bindings, pointers, entry)
        original.extend(expected)
        restored.extend(code)
        sites += len(bindings)

    return bytes(original), bytes(restored), sites


def check(executable, obj):
    original, restored, sites = bind_blocks(executable, obj, ROUTE_SECTOR_ENTRIES)
    for body in (original, restored):
        calls, logs, output = scan(body, [[(4, 7), (2, 9), (-1, 0)], [(3, 5), (-1, 0)]])
        assert calls == [(4, 7), (2, 9), (3, 5)] and not logs
        assert output == [(11, 11) + (-3,) * 50, (8,) + (-3,) * 51]
        calls, logs, output = scan(body, [[(99, 3), (-1, 0)]])
        assert calls == [(99, 3)] and logs == [(DATA_OFFSETS['_route_bad_waypoint'], 0)]
        assert output == [(-1,) + (-3,) * 51]
        calls, logs, output = scan(body, [[(i, 1) for i in range(51)]])
        assert calls == [(i, 1) for i in range(51)]
        assert logs == [(DATA_OFFSETS['_route_missing_terminator'], 0)]
        assert output == [tuple(range(1, 52)) + (-3,)]
    old_bounds, new_bounds, bounds_sites = bind_blocks(executable, obj, ROUTE_BOUNDS_ENTRIES)
    bounds = [(10, 10, 0, 0), (7, 7, 20, 20)]
    for body in (old_bounds, new_bounds):
        zone_selection(body, (1, 1), (15, 15), bounds, (0, 1))
        zone_selection(body, (8, 8), (10, 10), bounds, (1, 1))
        zone_selection(body, (-1, 0), (2, -1), bounds, (-1, -1))
        zone_selection(body, (1, 1), (15, 15), bounds, (-1, -1), scripted=True)
    old_crossing, new_crossing, crossing_sites = bind_blocks(executable, obj, ROUTE_CROSSING_ENTRIES)
    for body in (old_crossing, new_crossing):
        zone_crossing(body, 145, 755, True)
        zone_crossing(body, 144, 500, False)
        zone_crossing(body, 400, 756, False)
    old_same, new_same, same_sites = bind_blocks(executable, obj, ('route_choose_actor_target_',))
    old_exit, new_exit, exit_sites = bind_blocks(
        executable, obj, ('route_move_to_zone_exit_', 'route_select_target_tail_'),
    )
    for same_body, exit_body in ((old_same, old_exit), (new_same, new_exit)):
        path_arguments(same_body, exit_body, same=True)
        path_arguments(same_body, exit_body, same=False)
    size = len(original) + len(old_bounds) + len(old_crossing) + len(old_same) + len(old_exit)
    print(f'PASS: {size} exact bytes, {sites + bounds_sites + crossing_sites + same_sites + exit_sites} LE relocations, '
          '12 waypoint, zone selection, crossing and path-call cases for original and restored routing')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())


if __name__ == '__main__':
    main()
