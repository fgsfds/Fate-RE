"""Verify lead-player promotion, input invalidation, and announcement state."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX,
    UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOL = 'rotate_network_lead_player_'
RAW, SIZE = LEAVES[SYMBOL]
ENTRY = RAW - 0x25600
STACK, STOP = 0x3ff000, 0x3fff00
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_ESI)


def exercise(memory, body, enabled, requests, local, tick):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def address(name):
        return DS + DATA_OFFSETS['_rotate_' + name]

    def put(name, fmt, value, offset=0):
        cpu.mem_write(address(name) + offset, pack('<' + fmt, value))

    def get(name, fmt, offset=0):
        return unpack('<' + fmt, cpu.mem_read(address(name) + offset, len(pack('<' + fmt, 0))))[0]

    players = (3, 8, 1)
    put('network_enabled', 'B', enabled)
    put('first_player', 'h', players[0])
    put('local_player', 'h', local)
    cpu.mem_write(address('next_player'), pack('<16h', *([-1] * 16)))
    for a, b in zip(players, players[1:]):
        put('next_player', 'h', b, 2 * a)
    for i in range(16):
        put('player_input_word', 'H', 0x200 if i in requests else 0, 5 * i)
        for name, value in (('current_a', 254), ('current_b', 255), ('current_c', i)):
            put(name, 'B', value, 5 * i)
        put('current_word', 'H', 0xffff - i, 5 * i)
        cpu.mem_write(address('previous_a') + 5 * i, b'\xa5' * 5)
    for name, value in (('local_a', 255), ('local_b', 4), ('local_c', 127)):
        put(name, 'B', value)
    put('local_word', 'H', 0xffff)
    cpu.mem_write(address('saved_local_a'), b'\xa5' * 5)
    for name in ('event_read', 'event_state', 'event_write', 'saved_clock', 'last_tick', 'text_deadline'):
        put(name, 'I', 0x12345678)
    put('actor_clock', 'I', tick)
    cpu.mem_write(DS + DATA_OFFSETS['_totalclock'], pack('<I', 0x11223344))
    text = b'local lead text!\0\xa5'
    assert len(text) == 18
    cpu.mem_write(address('local_lead_message'), text)
    cpu.mem_write(address('lead_message'), b'\xa5' * 64)
    put('lead_text_length', 'B', 0xa5)
    calls = []
    expected_order = list(players)
    promoted = enabled and len(requests) == 1 and requests[0] in players[1:]
    if promoted:
        selected = requests[0]
        expected_order.remove(selected)
        expected_order.insert(0, selected)
    ordinal = expected_order.index(local) + 1

    def read_text(pos):
        value = bytearray()
        for i in range(64):
            byte = cpu.mem_read(pos + i, 1)[0]
            if not byte:
                return bytes(value)
            value.append(byte)
        raise AssertionError('Unterminated announcement')

    def format_message(engine, _address, _size, _data):
        stack = engine.reg_read(UC_X86_REG_ESP)
        dest, fmt, number = unpack('<III', engine.mem_read(stack + 4, 12))
        assert dest == address('lead_text')
        assert fmt == address('remote_lead_format')
        assert number == ordinal
        output = f'player {number} leads'.encode()
        engine.mem_write(dest, output + b'\0')
        engine.reg_write(UC_X86_REG_EAX, len(output))
        calls.append(('format', number))

    def length(engine, _address, _size, _data):
        pos = engine.reg_read(UC_X86_REG_EAX)
        assert pos == address('lead_text')
        engine.reg_write(UC_X86_REG_EAX, len(read_text(pos)))
        calls.append(('length',))

    for target, hook in ((FUNCTION_ADDRESSES['sprintf_'], format_message),
                         (FUNCTION_ADDRESSES['strlen_'], length)):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=target, end=target)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg in SAVED:
        cpu.reg_write(reg, 0x98760000 + reg)
    cpu.emu_start(ENTRY, STOP, count=6000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x98760000 + reg for reg in SAVED)
    actual = []
    index = get('first_player', 'h')
    while index >= 0:
        assert index not in actual
        actual.append(index)
        index = get('next_player', 'h', 2 * index)
    assert actual == expected_order
    for i in range(16):
        want = pack('<BBBH', 255, 0, i + 1, (0x10000 - i) & 0xffff) if promoted else b'\xa5' * 5
        assert cpu.mem_read(address('previous_a') + 5 * i, 5) == want
    if promoted:
        assert cpu.mem_read(address('saved_local_a'), 5) == pack('<BBBH', 0, 5, 128, 0)
        assert all(get(name, 'I') == 0 for name in ('event_read', 'event_state', 'event_write'))
        assert all(get(name, 'I') == tick for name in ('saved_clock', 'last_tick'))
        assert unpack('<I', cpu.mem_read(DS + DATA_OFFSETS['_totalclock'], 4))[0] == tick
        assert get('text_deadline', 'I') == (tick + 120) & 0xffffffff
        expected = text.split(b'\0')[0] if ordinal == 1 else f'player {ordinal} leads'.encode()
        assert read_text(address('lead_text')) == expected
        assert get('lead_text_length', 'B') == len(expected)
        assert calls == ([('length',)] if ordinal == 1 else [('format', ordinal), ('length',)])
        if ordinal == 1:
            assert cpu.mem_read(address('lead_message'), 18) == text
    else:
        assert calls == []
        assert get('text_deadline', 'I') == 0x12345678
        assert cpu.mem_read(address('saved_local_a'), 5) == b'\xa5' * 5


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
    cases = ((False, (8,), 3, 100), (True, (), 3, 100), (True, (3, 8), 3, 100),
             (True, (3,), 3, 100), (True, (8,), 8, 100), (True, (1,), 3, 0x7fffffe0))
    for body in (memory[ENTRY:ENTRY + SIZE], relocated):
        for case in cases:
            exercise(memory, body, *case)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} original and {len(cases)} restored promotion cases')


if __name__ == '__main__':
    main()
