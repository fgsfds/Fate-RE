"""Verify Board 7 sector and key triggers against the original and Watcom C code."""
import argparse
from pathlib import Path
from struct import pack, unpack

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

SYMBOL = 'update_board_7_script_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
SOUND, ACTIVATE, REMOVE = (FUNCTION_ADDRESSES[name] for name in
                           ('play_sound_', 'activate_sector_', 'sequence_remove_sprite_'))
STACK, STOP = 0x3f0000, 0x3ff000
DATA = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
SECTORS = tuple(range(10, 26))
OLD_SECTOR_TAGS = tuple(range(80, 96))
OLD_FLAGS, OLD_WALL_TILE = 0xb2, 987
SAVED = {
    register: 0xda7a0000 + index
    for index, register in enumerate((UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
                                      UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP))
}


def exercise(body, reset, previous, sector_sprites, consumed, key_events):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    trace = []

    def write(name, fmt, value, offset=0):
        cpu.mem_write(DATA[name] + offset, pack(fmt, value))

    def read(name, fmt, offset=0):
        width = len(pack(fmt, 0))
        return unpack(fmt, cpu.mem_read(DATA[name] + offset, width))[0]

    def hook(machine, address, _size, _data):
        eax, edx, ebx, ecx = (machine.reg_read(register) for register in
                              (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
        if address == SOUND:
            trace.append(('sound', eax, edx, ebx, ecx))
        elif address == ACTIVATE:
            assert eax in SECTORS and read('_board7_sector_lotag', '<h', 40 * eax) == 6
            trace.append(('sector', eax, edx))
            write('_board7_sector_lotag', '<h', 0x773, 40 * eax)
        elif address == REMOVE:
            trace.append(('remove', eax))

    for address in (SOUND, ACTIVATE, REMOVE):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    write('_board7_reset', '<h', reset)
    write('_board7_present', '<h', 0x773)
    write('_board7_previous_present', '<h', previous)
    write('_board7_sector_head', '<h', sector_sprites[0] if sector_sprites else -1)
    for sprite, following in zip(sector_sprites, (*sector_sprites[1:], -2)):
        write('_nextspritesect', '<h', following, 2 * sprite)
    for slot, (sector, old_tag) in enumerate(zip(SECTORS, OLD_SECTOR_TAGS)):
        write('_board7_trigger_sectors', '<h', sector, 2 * slot)
        write('_board7_sector_lotag', '<h', old_tag, 40 * sector)
    write('_board7_key_wall_tile', '<h', OLD_WALL_TILE)
    write('_board7_level_flags', '<B', OLD_FLAGS)
    write('_board7_key_consumed', '<i', consumed)
    write('_sprite_event_count', '<h', len(key_events))
    # Slot zero contains a matching event but is outside the one-based scan.
    for slot, (sprite, target, tile) in enumerate(((15, 0x405d, 0x20f), *key_events)):
        write('_sprite_events', '<h', sprite, 4 * slot)
        write('_sprite_events', '<H', target, 4 * slot + 2)
        write('_board7_sprite_tile', '<h', tile, 44 * sprite)

    for register, value in SAVED.items():
        cpu.reg_write(register, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    cpu.emu_start(ENTRY, STOP, count=2000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP and cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert all(cpu.reg_read(register) == value for register, value in SAVED.items())
    assert read('_board7_reset', '<h') == reset
    return (
        read('_board7_present', '<h'), read('_board7_previous_present', '<h'),
        tuple(read('_board7_sector_lotag', '<h', 40 * sector) for sector in SECTORS),
        read('_board7_key_consumed', '<i'), read('_board7_level_flags', '<B'),
        read('_board7_key_wall_tile', '<h'), trace,
    )


def expected(reset, previous, sector_sprites, consumed, key_events):
    present = int(bool(sector_sprites))
    changed = previous != present
    trace = [('sound', 156, 0, 0, 0)] if changed else []
    if changed:
        trace.extend(('sector', sector, slot) for slot, sector in enumerate(SECTORS))
    flags, wall_tile = OLD_FLAGS, OLD_WALL_TILE
    if not consumed:
        for sprite, target, tile in key_events:
            if target < 0x8000 and ((target - 0x4000) & 0xffff) == 0x5d and tile == 0x20f:
                trace.append(('remove', sprite))
                flags, wall_tile, consumed = flags | 1, 0x689, 1
    tags = (0,) * len(SECTORS) if changed or not reset else OLD_SECTOR_TAGS
    return present, present, tags, consumed, flags, wall_tile, trace


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == executable[RAW:RAW + SIZE] and len(refs) == 23
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    code, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=FUNCTION_ADDRESSES)
    original = image(executable)[ENTRY:ENTRY + SIZE]
    matches = ((3, 0x405d, 0x20f), (5, 0x405d, 0x20f))
    rejects = ((4, 0x805d, 0x20f), (6, 0x405c, 0x20f), (8, 0x405d, 0x20e))
    cases = (
        (0, 0, (), 0, ()), (1, 0, (), 0, ()), (1, 1, (), 0, ()),
        (0, 0, (7, 9), 0, ()), (1, 1, (7, 9), 0, ()), (1, 0, (7,), 0, rejects),
        (1, 0, (), 0, (*rejects, *matches)), (1, 0, (), 7, matches),
        (0, 0, (7,), 0, matches),
    )
    for args in cases:
        outcome = expected(*args)
        for body in (original, code):
            result = exercise(body, *args)
            assert result == outcome, (args, result, outcome)
    print(f'PASS: 361 exact bytes, 23 LE pointers, {len(cases)} Board 7 scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
