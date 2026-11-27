'''Verify the network readiness handshake with controlled receives and sends.'''
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


SYMBOL = 'synchronize_network_players_'
RAW_OFFSET, SIZE = LEAVES[SYMBOL]
ENTRY = RAW_OFFSET - 0x25600
RECEIVE = FUNCTION_ADDRESSES['receive_packets_']
SEND = FUNCTION_ADDRESSES['send_packet_']
STACK, STOP = 0x3ff000, 0x3fff00
BANK = {name: DS + DATA_OFFSETS[name] for name in (
    '_sync_player_count', '_sync_local_player', '_sync_first_player', '_sync_next_player',
    '_sync_peer_ready_stage', '_sync_packet', '_totalclock',
)}
PRESERVED = (UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
             UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_ESI)


def exercise(memory, body, role):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(ENTRY, body)

    def write(name, fmt, value):
        cpu.mem_write(BANK[name], pack('<' + fmt, value))

    write('_sync_player_count', 'h', 1 if role == 'solo' else 3)
    write('_sync_first_player', 'h', 0)
    write('_sync_local_player', 'h', 2 if role == 'client' else 0)
    write('_totalclock', 'i', 100)
    cpu.mem_write(BANK['_sync_next_player'], pack('<5h', 2, -1, 4, -1, -1))
    ready = BANK['_sync_peer_ready_stage']
    packet = BANK['_sync_packet']
    cpu.mem_write(ready, b'\x7f' * 5)
    cpu.mem_write(packet, b'\xa5\xa5')
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for register in PRESERVED:
        cpu.reg_write(register, 0x11220000 + register)

    sends = []
    polls = 0

    def receive(engine, _address, _size, _data):
        nonlocal polls
        polls += 1
        write('_totalclock', 'i', 100 + polls)
        if role == 'leader' and polls in (1, 10):
            assert engine.mem_read(ready + 2, 1) == engine.mem_read(ready + 4, 1) == b'\0'
        if role == 'client':
            assert engine.mem_read(ready, 1) == b'\0'
            engine.mem_write(ready, bytes([polls]))
            engine.mem_write(packet, bytes([5, polls]))

    def send(engine, _address, _size, _data):
        peer = engine.reg_read(UC_X86_REG_EAX)
        assert engine.reg_read(UC_X86_REG_EDX) == packet
        assert engine.reg_read(UC_X86_REG_EBX) == 2
        kind, stage = engine.mem_read(packet, 2)
        assert kind == 5
        sends.append((polls, peer, stage))
        if role == 'client':
            assert engine.mem_read(ready, 1) == b'\0'
        elif (peer, stage, polls) != (4, 1, 1):
            engine.mem_write(ready + peer, bytes([stage]))

    for address, callback in ((RECEIVE, receive), (SEND, send)):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, callback, begin=address, end=address)
    cpu.emu_start(ENTRY, STOP, count=3000)

    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert all(cpu.reg_read(reg) == 0x11220000 + reg for reg in PRESERVED)
    assert (polls, sends) == {
        'solo': (0, []),
        'leader': (10, [(1, 2, 1), (1, 4, 1), (9, 4, 1), (10, 2, 2), (10, 4, 2)]),
        'client': (2, [(1, 0, 1)]),
    }[role], (role, polls, sends)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    raw, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=ENTRY, functions=FUNCTION_ADDRESSES)
    assert len(raw) == SIZE and raw == exe[RAW_OFFSET:RAW_OFFSET + SIZE]
    verify_leaf_relocations(raw, refs, read_le_fixups(exe)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(
        obj, SYMBOL, {key: DS + value for key, value in DATA_OFFSETS.items()},
        address=ENTRY, functions=FUNCTION_ADDRESSES,
    )
    memory = image(exe)
    for body in (memory[ENTRY:ENTRY + SIZE], relocated):
        for role in ('solo', 'leader', 'client'):
            exercise(memory, body, role)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, 3 original and 3 restored handshake cases')


if __name__ == '__main__':
    main()
