"""Check both saved-player loops, real crusher wrappers and stream completion."""
import argparse
import json
import struct
from pathlib import Path
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
import verify_c_leaf as v
from check_start_hook import image, DS
from check_save_status_message import private_image
from check_ripple_stack import mutate_public_byte
from le_fixups import read_le_fixups

EXTENT = 0x28a300
PRIVATE, STREAM, STACK, STOP = 0x400000, 0x4f8000, 0x4ff000, 0x4fff00
REGS = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
        UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def machine(memory, seed):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x500000)
    cpu.mem_write(0, memory)
    pattern = bytes((i*73+seed*31)&255 for i in range(256))
    data = bytearray((pattern*((EXTENT+255)//256))[:EXTENT])
    cpu.mem_write(DS-16, b'\x5a'*16+bytes(data)+b'\xa5'*16)
    frame = struct.pack('<I', STOP)+b'\xcc'*60
    cpu.mem_write(STACK, frame)
    cpu.mem_write(STACK-256, b'\x6c'*256)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    want = {reg: 0xabc00000+i for i, reg in enumerate(REGS)}
    want[UC_X86_REG_ESI] = STREAM
    for reg, value in want.items():
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_EFLAGS, 0x8d7)
    return cpu, data, frame, want


def returned(cpu, esp, ret):
    cpu.reg_write(UC_X86_REG_ESP, esp+4)
    cpu.reg_write(UC_X86_REG_EIP, ret)


def guards(cpu, data, frame, want, private=False):
    assert cpu.mem_read(DS-16, EXTENT+32) == b'\x5a'*16+bytes(data)+b'\xa5'*16
    assert cpu.mem_read(STACK, len(frame)) == frame
    assert cpu.mem_read(STACK-256, 160) == b'\x6c'*160
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK+(4 if private else 0)
    assert all(cpu.reg_read(reg) == value for reg, value in want.items())


def players(memory, phase, code, chain, seed, mutable):
    cpu, data, frame, want = machine(memory, seed)
    first = chain[0] if chain else -1
    links = [-1]*16
    for left, right in zip(chain, chain[1:]):
        links[left] = right
    struct.pack_into('<h', data, 0x19028a, first)
    struct.pack_into('<16h', data, 0x18fd78, *links)
    cpu.mem_write(DS, bytes(data))
    entry = phase['address']
    cpu.mem_write(entry, code)
    expected_visits = [0, 1] if mutable else chain
    seen = []
    def hook(m, address, size, user):
        index = expected_visits[len(seen)]
        assert m.reg_read(UC_X86_REG_EAX) == index
        assert m.reg_read(UC_X86_REG_EDI) == index
        assert m.reg_read(UC_X86_REG_ESI) == STREAM
        esp = m.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', m.mem_read(esp, 4))
        assert esp == STACK-4 and ret == entry+17
        if mutable and not seen:
            # The next link must be loaded after the returning initializer.
            struct.pack_into('<h', data, 0x18fd78, 1)
            struct.pack_into('<h', data, 0x19028a, 2)
            m.mem_write(DS+0x18fd78, struct.pack('<h', 1))
            m.mem_write(DS+0x19028a, struct.pack('<h', 2))
        seen.append(index)
        m.reg_write(UC_X86_REG_EAX, 0xa0000000+index)
        returned(m, esp, ret)
    cpu.hook_add(UC_HOOK_CODE, hook, begin=0x2e14f, end=0x2e14f)
    cpu.emu_start(entry, entry+29, count=300)
    assert seen == expected_visits
    want[UC_X86_REG_EDI] = 0xffffffff
    if seen:
        want[UC_X86_REG_EAX] = 0xa0000000+seen[-1]
    guards(cpu, data, frame, want)
    assert cpu.reg_read(UC_X86_REG_EIP) == entry+29
    assert cpu.reg_read(UC_X86_REG_EFLAGS)&0x8c5 == 0x84


def finish(memory, placed, private_code, context, reading, seed, full_private, amount):
    cpu, data, frame, want = machine(memory, seed)
    for address, code in placed.items():
        cpu.mem_write(address, code)
    if full_private:
        cpu.mem_write(PRIVATE, private_code)
    entry = PRIVATE+context['start'] if full_private else 0x30934
    end = STOP if full_private else entry+14
    target = 0x60638 if reading else 0x60944
    payload = bytes((i*43+seed*97)&255 for i in range(0x64c8))
    expected_output = bytes(data[0x174640:0x174640+amount])
    output = bytearray()
    trace = []
    def hook(m, address, size, user):
        esp = m.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', m.mem_read(esp, 4))
        if address == target:
            args = tuple(m.reg_read(r) for r in (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX))
            assert args == (DS+0x174640, 0x64c8, 1, STREAM)
            assert esp == STACK-20 and ret == (0x40371 if reading else 0x4034b)
            if reading:
                data[0x174640:0x174640+amount] = payload[:amount]
                if amount:
                    m.mem_write(DS+0x174640, payload[:amount])
            else:
                output.extend(m.mem_read(DS+0x174640, amount))
            for reg, value in ((UC_X86_REG_EAX, int(amount==0x64c8)), (UC_X86_REG_EBX, 0xbad00001),
                               (UC_X86_REG_ECX, 0xbad00002), (UC_X86_REG_EDX, 0xbad00003)):
                m.reg_write(reg, value)
            trace.append('transfer')
        else:
            assert address == 0x60802 and trace == ['transfer']
            assert m.reg_read(UC_X86_REG_EAX) == STREAM
            assert esp == STACK-4
            assert ret == (PRIVATE+14 if full_private else entry+14)
            m.reg_write(UC_X86_REG_EAX, 0xffffffff if seed else 0)
            trace.append('close')
        assert m.reg_read(UC_X86_REG_ESI) == STREAM
        returned(m, esp, ret)
    for address in (target, 0x60802):
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.emu_start(entry, end, count=100)
    assert trace == ['transfer', 'close']
    if not reading:
        assert output == expected_output
    want[UC_X86_REG_EAX] = 0xffffffff if seed else 0
    if full_private:
        want[UC_X86_REG_EBX] = want[UC_X86_REG_EAX]
    guards(cpu, data, frame, want, full_private)
    assert cpu.reg_read(UC_X86_REG_EIP) == end


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe', type=Path, required=True)
    p.add_argument('--build', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    a = p.parse_args()
    exe = a.exe.read_bytes()
    memory = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    phases = [r for r in v.SAVE_DYNAMIC_LAYOUT['phases'] if r['phase'].startswith('save_players_') or r['object']=='svfinish']
    blobs = {name: (a.build/(name+'.obj')).read_bytes() for name in ('svoread', 'svfinish')}
    placed = {}
    offsets = dict(v.DATA_OFFSETS, _first_player=DS+0x19028a, _next_player=DS+0x18fd78)
    for phase in phases:
        address = phase['address']
        blob = blobs[phase['object']]
        code, refs = v.bind_leaf_details(blob, phase['phase'], v.DATA_OFFSETS, address=address, functions=v.FUNCTION_ADDRESSES)
        assert code == exe[address+0x25600:address+0x25600+len(code)]
        v.verify_leaf_relocations(code, refs, pointers, address)
        placed[address] = v.bind_leaf_details(blob, phase['phase'], offsets, address=address, functions=v.FUNCTION_ADDRESSES)[0]
    chains = [[]]+[[i] for i in range(16)]+[list(range(16)), list(range(15,-1,-1)), [(i*7)%16 for i in range(16)]]
    loop_cases = 0
    for phase in phases:
        if not phase['phase'].startswith('save_players_'):
            continue
        for seed in (0, 1):
            for chain in chains:
                players(memory, phase, placed[phase['address']], chain, seed, False)
                loop_cases += 1
            players(memory, phase, placed[phase['address']], [0, 15], seed, True)
            loop_cases += 1
    obj = next(o for o in v.SAVE_DYNAMIC_LAYOUT['objects'] if o['object']=='svfinish')
    private = private_image(blobs['svfinish'], obj)
    finish_cases = 0
    for reading in (True, False):
        context = obj['contexts'][0 if reading else 1]
        for full_private in ((False, True) if reading else (True,)):
            for seed in (0, 1):
                for amount in (0, 1, 0x64c7, 0x64c8):
                    finish(memory, placed, private, context, reading, seed, full_private, amount)
                    finish_cases += 1
    controls = 0
    for phase, offset in ((next(r for r in phases if r['phase'].startswith('save_players_')), 234),
                          (next(r for r in phases if r['object']=='svfinish'), 16)):
        bad = mutate_public_byte(blobs[phase['object']], phase['public'], offset)
        try:
            v.bind_leaf_details(bad, phase['phase'], v.DATA_OFFSETS, address=phase['address'], functions=v.FUNCTION_ADDRESSES)
        except ValueError as exc:
            assert 'context' in str(exc).lower()
            controls += 1
        else:
            raise AssertionError('Excluded context mutation escaped')
    result = dict(status='PASS', player_loop_cases=loop_cases, crusher_finish_cases=finish_cases,
                  actual_crusher_wrappers=True, primitive_io_close_and_initializer_stubs=True,
                  full_data_and_caller_frame_guards=True, context_controls=controls)
    a.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
