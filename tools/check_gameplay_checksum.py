"""Compare checksum_gameplay_state_ with the pinned original and CRC oracle."""
import argparse
import hashlib
import json
import random
import struct
from pathlib import Path

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EDI, UC_X86_REG_EBP, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from le_fixups import pointer_range, read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations,
)

ENTRY, RAW, SIZE, LE_SITES = 0x33c3f, 0x5923f, 1490, 71
STACK, STOP = 0x3ff000, 0x3fff00
PRESERVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
SYMBOLS = (
    '_checksum_player_sector', '_checksum_player_z', '_checksum_player_y',
    '_checksum_player_x', '_checksum_player_horizon', '_checksum_player_angle',
    '_checksum_status_right_tenths', '_checksum_checksum_table',
    '_checksum_next_player', '_checksum_first_player',
    '_checksum_next_sprite_stat', '_checksum_sprite', '_checksum_random_seed',
    '_checksum_hit_sprite_list_head',
)


def independent_crc(memory, players, sprite_ids, seed, table):
    crc = 0

    def update(data):
        nonlocal crc
        for byte in data:
            crc = ((crc << 8) ^ table[((crc >> 8) ^ byte) & 255]) & 0xffff

    update((seed & 0xffff).to_bytes(2, 'little'))
    for player in players:
        for offset, width in ((0x5ad9c, 4), (0x5ad5c, 4), (0x5ad1c, 4),
                              (0x6308c, 2), (0x62f8c, 4),
                              (0x6319c, 4), (0x5acfc, 2)):
            update(memory[DS + offset + player * width:DS + offset + (player + 1) * width])
    for sprite_id in sprite_ids:
        base = DS + 0x2040a0 + sprite_id * 44
        update(memory[base:base + 12])
        update(memory[base + 28:base + 30])
    return crc


def run(memory, body):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, bytes(memory))
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(STACK, struct.pack('<I', STOP) + b'\x5a' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for i, reg in enumerate(PRESERVED):
        cpu.reg_write(reg, 0xabcd1200 + i)
    cpu.reg_write(UC_X86_REG_EAX, 0xdeadbeef)
    sentinel = b'\x5a' * 16
    cpu.emu_start(ENTRY, STOP, count=20000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0xabcd1200 + i for i, reg in enumerate(PRESERVED))
    assert bytes(cpu.mem_read(STACK + 4, 16)) == sentinel
    return cpu.reg_read(UC_X86_REG_EAX) & 0xffffffff, bytes(cpu.mem_read(0, len(memory)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    executable = args.executable.read_bytes()
    assert hashlib.sha256(executable).hexdigest() == TARGET_SHA256
    pointers = read_le_fixups(executable)['pointers']
    assert len(pointer_range(pointers, ENTRY, SIZE)) == LE_SITES
    original_raw = executable[RAW:RAW + SIZE]
    assert len(original_raw) == SIZE
    values = {name: DATA_OFFSETS[name] for name in SYMBOLS}
    code, bindings = bind_leaf_details(args.object.read_bytes(), 'checksum_gameplay_state_',
                                       values, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(code) == SIZE and code == original_raw
    verify_leaf_relocations(code, bindings, pointers, ENTRY)
    memory = image(executable)
    original = memory[ENTRY:ENTRY + SIZE]
    loaded_data = {name: DS + offset for name, offset in values.items()}
    body, _ = bind_leaf_details(args.object.read_bytes(), 'checksum_gameplay_state_',
                                loaded_data, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert body == memory[ENTRY:ENTRY + SIZE]

    cases = [[], [0], [1, 4, 9], [15, 2, 7, 0]]
    rng = random.Random(0xC5A2026)
    cases.extend(rng.sample(range(16), rng.randrange(7)) for _ in range(60))
    extremes = (-0x80000000, -1, 0, 1, 0x7fffffff)
    for number, players in enumerate(cases):
        case_rng = random.Random(number + 1)
        memory_case = bytearray(memory)
        table = [case_rng.randrange(0x10000) for _ in range(256)]
        for index, value in enumerate(table):
            struct.pack_into('<I', memory_case, DS + 0x18f778 + index * 4,
                             (case_rng.randrange(0x10000) << 16) | value)
        seed = case_rng.randrange(0x100000000)
        struct.pack_into('<I', memory_case, DS + 0x287e78, seed)
        links = [-1] * 16
        for player, nxt in zip(players, players[1:]):
            links[player] = nxt
        struct.pack_into('<h', memory_case, DS + 0x19028a, players[0] if players else -1)
        struct.pack_into('<16h', memory_case, DS + 0x18fd78, *links)
        pattern = number % 5
        chains = {0: {}, 1: {7: [4095]}, 2: {7: [0, 4095]},
                  3: {0: [4095, 0]}, 4: {7: [0], 0: [4095]}}[pattern]
        heads = [-1] * 11
        sprite_ids = []
        for status, chain in chains.items():
            heads[status] = chain[0]
        struct.pack_into('<11h', memory_case, DS + 0x28811c, *heads)
        for status in range(7, -1, -1):
            chain = chains.get(status, [])
            sprite_ids.extend(chain)
            for sprite_id, next_id in zip(chain, chain[1:] + [-1]):
                struct.pack_into('<h', memory_case, DS + 0x1fbca0 + sprite_id * 2, next_id)
        for player in range(16):
            for offset in (0x5ad9c, 0x5ad5c, 0x5ad1c, 0x62f8c, 0x6319c):
                value = case_rng.choice(extremes) if number < 8 else case_rng.randrange(-0x80000000, 0x80000000)
                struct.pack_into('<i', memory_case, DS + offset + player * 4, value)
            for offset in (0x6308c, 0x5acfc):
                struct.pack_into('<h', memory_case, DS + offset + player * 2,
                                 case_rng.choice((-32768, -1, 0, 1, 32767)))
        for sprite_id in (0, 4095):
            base = DS + 0x2040a0 + sprite_id * 44
            for offset in (0, 4, 8):
                value = case_rng.choice(extremes) if number < 8 else case_rng.randrange(-0x80000000, 0x80000000)
                struct.pack_into('<i', memory_case, base + offset, value)
            struct.pack_into('<h', memory_case, base + 28, case_rng.choice((-32768, -1, 0, 1, 32767)))
        expected = independent_crc(memory_case, players, sprite_ids, seed, table)
        original_result, original_memory = run(memory_case, original)
        candidate_result, candidate_memory = run(memory_case, body)
        assert original_result == expected, (number, 'original vs independent', original_result, expected)
        assert candidate_result == expected, (number, 'candidate vs independent', candidate_result, expected)
        normalized = bytearray(candidate_memory)
        normalized[ENTRY:ENTRY + SIZE] = original_memory[ENTRY:ENTRY + SIZE]
        assert normalized == original_memory, (number, 'memory mismatch')
    print(json.dumps({'bytes': SIZE, 'le_sites': LE_SITES, 'cases': len(cases),
                      'original_and_candidate': 'passed'}))


if __name__ == '__main__':
    main()
