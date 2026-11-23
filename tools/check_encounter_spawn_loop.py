"""Check encounter spawn setup, frame inputs, position handoff and loop guard."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from match_objects import index as omf_index
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, LEAF_CODE_SLICES,
                           bind_leaf_details, parsed_leaf_object)

ENTRY, BODY, TILE, END, STACK, ISLAND = 0x1e070, 0x1e086, 0x1e0e7, 0x1e1b0, 0x3fe000, 0x3d0000
RANDOM, SECTOR, SPAWN, LIST = 0x602d0, 0x542c4, 0x11073, 0x134c2
SPRITES, WIDTHS, TICKS = DS + 0x2040a0, DS + 0x1f2020, DS + 0x7a994
HEIGHT, IDS = -50170, (0, 4095)
POSITIONS = ((-10240,-6400),(-9728,-5632),(-8960,-5376),(-7936,-5888),
             (-7424,-5376),(-9984,-7168),(-8704,-6656),(-7936,-7424),
             (-7424,-7168),(-10752,-9216),(-10240,-8192),(-6912,-8448),
             (-9984,-9728),(-7680,-9728),(-8704,-10240),(-9216,-10752))
REPEATS = (60,30,30,15,15,15,15,15,15,15,15,7,7,7,7,7)
REGS = (UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,
        UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)


def run(memory, ticks, choice, tile_draw, xshift, yshift, hint):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    frame = struct.pack('<32i', *(value for xy in POSITIONS for value in xy))
    frame += bytes(value for repeat in REPEATS for value in (repeat, repeat)) + b'\xa5' * 24
    cpu.mem_write(STACK - 16, b'\xcc' * 16 + frame + b'\xdd' * 16)
    cpu.mem_write(STACK + 0xac, struct.pack('<h', 0x4321))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg, value in zip(REGS, (0x10203040,0x21314151,0x32425262,0x43536373,
                                0x54647484,0x65758595,0x768696a6)):
        cpu.reg_write(reg, value)
    cpu.mem_write(TICKS, struct.pack('<i', ticks))
    cpu.mem_write(WIDTHS + 0x350 * 2, struct.pack('<hh', 257, -257))
    records = {slot: bytearray(b'\x5a' * 44) for slot in IDS}
    for slot, record in records.items():
        cpu.mem_write(SPRITES + slot * 44 - 1, b'\xa5' + bytes(record) + b'\xa5')
    draws = (0x100 | choice, tile_draw, 0x200 | choice, 0x300 | xshift, 0x400 | yshift)
    events, random_count, spawn_count, listed_count = [], 0, 0, 0
    expected_x, expected_y = POSITIONS[choice]

    def intercept(emu, address, size, data):
        nonlocal random_count, spawn_count, listed_count
        if address == END:
            emu.emu_stop()
            return
        if address == TILE:
            slot = IDS[(spawn_count - 1) % len(IDS)]
            if (emu.reg_read(UC_X86_REG_EDI), emu.reg_read(UC_X86_REG_ESI)) != (slot, slot * 44):
                raise AssertionError('Spawn index did not narrow the AX return correctly')
            return
        if address == RANDOM:
            value = draws[random_count % 5]
            events.append(('random', value))
            random_count += 1
            emu.reg_write(UC_X86_REG_EAX, value)
        elif address == SECTOR:
            if (emu.reg_read(UC_X86_REG_EAX), emu.reg_read(UC_X86_REG_EDX),
                    emu.reg_read(UC_X86_REG_EBX)) != (expected_x & 0xffffffff,
                                                    expected_y & 0xffffffff, STACK + 0xac):
                raise AssertionError('Sector coordinate or hint-pointer argument differs')
            xyz = struct.unpack('<iii', emu.mem_read(STACK + 0xa0, 12))
            old_hint, = struct.unpack('<h', emu.mem_read(STACK + 0xac, 2))
            expected_hint = 0x4321 if spawn_count == 0 else hint
            if xyz != (expected_x, expected_y, HEIGHT) or old_hint != expected_hint:
                raise AssertionError('Position, height or incoming hint bytes differ')
            events.append(('sector', xyz, old_hint))
            emu.mem_write(STACK + 0xac, struct.pack('<h', hint))
            for reg in (UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_EDX):
                emu.reg_write(reg, 0x87654321)
        elif address == SPAWN:
            if tuple(emu.reg_read(reg) for reg in (UC_X86_REG_EAX,UC_X86_REG_EDX,
                                                  UC_X86_REG_EBX)) != (0x2b, STACK + 0xa0, hint & 0xffffffff):
                raise AssertionError('Sprite spawn arguments differ')
            slot = IDS[spawn_count % len(IDS)]
            spawn_count += 1
            events.append(('spawn', slot, hint))
            struct.pack_into('<iii', records[slot], 0, expected_x, expected_y, HEIGHT)
            emu.mem_write(SPRITES + slot * 44, bytes(records[slot]))
            emu.reg_write(UC_X86_REG_EAX, 0xdead0000 | slot)
            emu.reg_write(UC_X86_REG_EBX, 0x76543210)
            emu.reg_write(UC_X86_REG_EDX, 0xabcdef01)
        else:
            slot = IDS[listed_count % len(IDS)]
            if (emu.reg_read(UC_X86_REG_EAX), emu.reg_read(UC_X86_REG_EDX)) != (slot, listed_count + 2):
                raise AssertionError('Listed-sprite index or preserved counter differs')
            events.append(('list', slot, listed_count + 2))
            listed_count += 1
            tile = 0x350 + (tile_draw & 1)
            xrepeat, yrepeat = REPEATS[choice] >> xshift, REPEATS[choice] >> yshift
            struct.pack_into('<h', records[slot], 14, tile)
            records[slot][18] = (((257 if tile == 0x350 else -257) * xrepeat) >> 7) & 255
            records[slot][20:22] = bytes((xrepeat, yrepeat))
            emu.reg_write(UC_X86_REG_EAX, 0x12345678)
        sp = emu.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    for address in (RANDOM, SECTOR, SPAWN, LIST, TILE, END):
        cpu.hook_add(UC_HOOK_CODE, intercept, begin=address, end=address)
    cpu.emu_start(ENTRY, END + 1, count=3000)
    count = max(0, ticks * 2)
    counter, = struct.unpack('<I', cpu.mem_read(STACK + 0xb4, 4))
    if (random_count, spawn_count, listed_count, counter) != (count * 5, count, count, count + 1):
        raise AssertionError('Spawn loop iteration count differs')
    if (cpu.reg_read(UC_X86_REG_EIP), cpu.reg_read(UC_X86_REG_ESP),
            cpu.reg_read(UC_X86_REG_EBP)) != (END, STACK, HEIGHT & 0xffffffff):
        raise AssertionError('Spawn-loop register or frame handoff differs')
    if (cpu.mem_read(STACK - 16, 12) != b'\xcc' * 12
            or cpu.mem_read(STACK + 184, 16) != b'\xdd' * 16):
        raise AssertionError('Spawn frame boundary guard changed')
    for slot, record in records.items():
        if cpu.mem_read(SPRITES + slot * 44 - 1, 46) != b'\xa5' + bytes(record) + b'\xa5':
            raise AssertionError('Spawn sprite fields or boundary guards differ')
    return events, bytes(cpu.mem_read(STACK, 184)), tuple(cpu.reg_read(reg) for reg in REGS)


def mutate_unlinked_index(blob):
    segments, publics, *_ = parsed_leaf_object(blob)
    segment, public_start, _ = publics[0]
    target, modified, cursor = public_start + 0x161, bytearray(blob), 0
    while cursor < len(blob):
        kind, length = blob[cursor], int.from_bytes(blob[cursor + 1:cursor + 3], 'little')
        end = cursor + 3 + length
        if kind in (0xa0, 0xa1):
            data = blob[cursor + 3:end - 1]
            seg, position = omf_index(data, 0)
            width = 4 if kind == 0xa1 else 2
            origin = int.from_bytes(data[position:position + width], 'little')
            payload = position + width
            if seg == segment and origin <= target < origin + len(data) - payload:
                modified[cursor + 3 + payload + target - origin] = 0x90
                modified[end - 1] = 0
                modified[end - 1] = (-sum(modified[cursor:end])) & 255
                return bytes(modified)
        cursor = end
    raise AssertionError('Missing compiler index-extension bytes')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    memory, obj = image(blob), (args.build / 'encloop.obj').read_bytes()
    alias = 'encounter_loop_natural_position_'
    LEAF_CODE_SLICES[alias] = ('encounter_spawn_loop_context_', 0x152, 0x1b6, 1266)
    natural, _ = bind_leaf_details(obj, alias, {name: DS + value for name,value in DATA_OFFSETS.items()},
                                  address=ISLAND, functions=FUNCTION_ADDRESSES, code_bindings={})
    ordered = bytearray(memory)
    ordered[ISLAND:ISLAND + len(natural)] = natural
    ordered[ISLAND + len(natural):ISLAND + len(natural) + 5] = b'\xe9' + struct.pack('<i', TILE - (ISLAND + len(natural) + 5))
    ordered[BODY:BODY + 5] = b'\xe9' + struct.pack('<i', ISLAND - (BODY + 5))
    ordered = bytes(ordered)
    cases = [(1, choice, tile, sx, sy, hint) for choice in range(16)
             for tile in (0x100,0x7fff) for sx in (0,1) for sy in (0,1) for hint in (-1,0x1234)]
    cases += [(ticks,15,0x7fff,1,1,-1) for ticks in (-1,0,2)]
    for case in cases:
        if run(memory, *case) != run(ordered, *case):
            raise AssertionError('Natural position phase differs from linked order')
    for start, replacement in ((0x1e08d,b'\x90\x90'), (0x1e0e1,b'\x90\x90\x90'), (0x1e1ab,b'\x8c')):
        mutant = bytearray(memory)
        mutant[start:start + len(replacement)] = replacement
        try:
            run(bytes(mutant), 1, 3, 0x7fff, 1, 0, -1)
        except AssertionError:
            pass
        else:
            raise AssertionError('Loop oracle accepted an RNG, index, or guard mutation')
    try:
        bind_leaf_details(mutate_unlinked_index(obj), 'encounter_loop_position_', DATA_OFFSETS,
                          address=BODY, functions=FUNCTION_ADDRESSES, code_bindings={})
    except ValueError as error:
        if 'Unlinked spawn index extension differs' not in str(error):
            raise
    else:
        raise AssertionError('Unlinked index-extension mutation was accepted')
    report = dict(status='PASS', cases=len(cases), natural_order_cases=len(cases),
                  mutation_controls=3, unlinked_index_guard_controls=1)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
