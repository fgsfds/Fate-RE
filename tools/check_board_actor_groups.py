"""Independent models for three native startup actor operations."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_MEM_WRITE
from unicorn.x86_const import *
from check_start_hook import image, DS
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
import bind_board_actor as group
import verify_c_leaf as v

DATA_SIZE, SP, STOP = 0x28a300, 0x3fef00, 0x3fff00
REGS = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
        UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def seed(original, number):
    memory = bytearray(original)
    pattern = bytes((i + number*29) & 255 for i in range(256))
    memory[DS:DS+DATA_SIZE] = (pattern*((DATA_SIZE+255)//256))[:DATA_SIZE]
    memory[SP-128:SP+68] = bytes([0xa7])*196
    struct.pack_into('<I', memory, SP, STOP)
    registers = [(0xabc01234 + i*0x1020311 + number*0x1234567) & 0xffffffff for i in range(7)]
    # Distinguish the unconsumed low byte from the activation value in AH.
    registers[0] = (registers[0] & ~255) | 0xa5
    registers = tuple(registers)
    return memory, registers


def live_registers(registers, phase):
    registers = list(registers)
    for name, value in phase['live_in'].items():
        if name == 'ah': registers[0] = (registers[0] & ~0xff00) | value << 8
        elif name == 'dl': registers[3] = (registers[3] & ~255) | value
        elif name == 'esi': registers[4] = value
        elif name == 'cx': registers[2] = (registers[2] & ~0xffff) | value
        else: raise AssertionError(name)
    return tuple(registers)


def model(memory, phase):
    memory = bytearray(memory)
    if phase['symbol'] == 'board_actor_activation_':
        writes = [(DS+0x7ecb7,1,5),(DS+0x7eac2,1,1)]
    elif phase['symbol'] == 'board_actor_destination_':
        writes = [(DS+0x729fc+16+n*4,4,0) for n in range(4)]
    else:
        assert phase['symbol'] == 'board_actor_tiles_'
        writes = [(DS+0x7abc0+103*18+n*2,2,2672) for n in range(7)]
    for address, size, value in writes:
        memory[address:address+size] = value.to_bytes(size,'little')
    return bytes(memory[DS:DS+DATA_SIZE]), writes


def execute(memory, registers, flags, body, address, *, function=False, full=False):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0,0x400000); cpu.mem_write(0,bytes(memory)); cpu.mem_write(address,body)
    for register, value in zip(REGS,registers): cpu.reg_write(register,value)
    cpu.reg_write(UC_X86_REG_ESP,SP); cpu.reg_write(UC_X86_REG_EFLAGS,flags)
    writes = []; lowest = SP; visited = set()
    def write(_cpu,_kind,where,size,value,_user):
        nonlocal lowest
        if DS <= where and where+size <= DS+DATA_SIZE:
            writes.append((where,size,value & ((1 << (size*8))-1)))
        else:
            assert function and SP-24 <= where and where+size <= SP
            lowest = min(lowest,where)
    def instruction(_cpu,where,size,_user):
        if where == STOP: cpu.emu_stop(); return
        assert address <= where < address+len(body),hex(where)
        if full:
            for phase in group.LAYOUT['phases']:
                if where == phase['address']:
                    current = tuple(cpu.reg_read(r) for r in REGS)
                    assert current == live_registers(current,phase),phase['symbol']
                    visited.add(phase['symbol'])
    cpu.hook_add(UC_HOOK_MEM_WRITE,write); cpu.hook_add(UC_HOOK_CODE,instruction)
    end = STOP if function else address+len(body)
    cpu.emu_start(address,end,count=50000 if full else 100)
    assert cpu.reg_read(UC_X86_REG_EIP) == end
    assert cpu.reg_read(UC_X86_REG_ESP) == SP+(4 if function else 0)
    assert bytes(cpu.mem_read(SP+4,64)) == bytes([0xa7])*64
    assert bytes(cpu.mem_read(SP-128,104)) == bytes([0xa7])*104
    return (bytes(cpu.mem_read(DS,DATA_SIZE)),writes,
            tuple(cpu.reg_read(r) for r in REGS),cpu.reg_read(UC_X86_REG_EFLAGS),SP-lowest,visited)


def bind_production(exe, build):
    layout = group.LAYOUT; blob = (build/'actorcfg.obj').read_bytes(); pointers = read_le_fixups(exe)['pointers']
    begin = layout['original_address']; size = layout['original_size']
    raw_body = bytearray(size); loaded_body = bytearray(size); covered = set(); slices = []
    def install(address, raw, loaded):
        region = set(range(address,address+len(raw)))
        assert region <= set(range(begin,begin+size)) and not covered & region
        covered.update(region); raw_body[address-begin:address-begin+len(raw)] = raw
        loaded_body[address-begin:address-begin+len(raw)] = loaded
    values = {k:DS+n for k,n in v.DATA_OFFSETS.items()}
    for phase in layout['phases']:
        fields = {}; address = phase['address']; symbol = phase['symbol']
        raw, data = v.bind_leaf_details(blob,symbol,v.DATA_OFFSETS,address=address,code_bindings=fields)
        assert not fields and raw == exe[address+0x25600:address+0x25600+len(raw)]
        v.verify_leaf_relocations(raw,data,pointers,address,code_bindings=fields)
        fields = {}; loaded, bindings = v.bind_leaf_details(blob,symbol,values,address=address,code_bindings=fields)
        assert not fields and bindings == {k:DS+n for k,n in data.items()}
        install(address,raw,loaded)
        fields = {}; natural, natural_data = v.bind_leaf_details(blob,phase['public'],values,address=0x50000,code_bindings=fields)
        assert not fields and len(natural_data) == len(data)
        slices.append((phase,loaded,natural))
    assembly = (build/'asm/board_actor_initialization.bin').read_bytes()
    assert len(assembly) == layout['assembly_size']
    for row in layout['retained']:
        address = row['address']; offset = row['binary_offset']; raw = assembly[offset:offset+row['size']]
        assert raw == exe[address+0x25600:address+0x25600+len(raw)]
        fields = {int(k):n for k,n in row['fixups'].items()}
        assert {site-address:n for site,n in pointers.between(address,address+len(raw))} == fields
        loaded = bytearray(raw)
        for site,target in fields.items(): loaded[site:site+4] = target.to_bytes(4,'little')
        install(address,raw,loaded)
    assert len(covered) == size and raw_body == exe[begin+0x25600:begin+0x25600+size]
    assert sum(len(code) for _,code,_ in slices) == 85
    return blob,bytes(loaded_body),slices


def moved_first_public(blob):
    from match_objects import index
    out = bytearray(); cursor = 0; changed = False
    while cursor < len(blob):
        kind = blob[cursor]; size = int.from_bytes(blob[cursor+1:cursor+3],'little')
        end = cursor+3+size; payload = bytearray(blob[cursor+3:end-1])
        if kind in (0x90,0x91) and not changed:
            _,pos = index(payload,0); segment,pos = index(payload,pos); assert segment == 1
            length = payload[pos]; name = bytes(payload[pos+1:pos+1+length]).decode('ascii')
            if name == group.LAYOUT['publics'][0][2]:
                pos += length+1; width = 4 if kind & 1 else 2
                assert int.from_bytes(payload[pos:pos+width],'little') == 0
                payload[pos:pos+width] = (1).to_bytes(width,'little'); changed = True
        record = bytearray([kind])+bytearray((len(payload)+1).to_bytes(2,'little'))+payload
        record.append((-sum(record)) & 255); out.extend(record); cursor = end
    assert changed
    before = v.parsed_leaf_object(blob); after = v.parsed_leaf_object(bytes(out))
    assert before[0] == after[0] and before[-1] == after[-1] and before[1] != after[1]
    return bytes(out)


def context_controls(blob):
    from dataclasses import replace
    from check_encounter_actor import rewrite_fixup
    from check_ripple_stack import mutate_public_byte
    from check_ripple_control import rename_external
    phase = group.LAYOUT['phases'][0]; controls = []
    def bind(b): return v.bind_leaf_details(b,phase['symbol'],v.DATA_OFFSETS,address=phase['address'],code_bindings={})
    def reject(b,message):
        try: bind(b)
        except ValueError as error: assert message in str(error),str(error)
        else: raise AssertionError(message)
    baseline = bind(blob); roundtrip,changed = rewrite_fixup(blob,lambda f:False,lambda f:f)
    assert not changed and bind(roundtrip) == baseline
    for name,public,offset in [('other_public_prefix','clear_first_actor_destination_',0),('other_public_return','assign_actor_103_tiles_',56)]:
        reject(mutate_public_byte(blob,public,offset),'complete context digest'); controls.append(name)
    reject(moved_first_public(blob),'public layout'); controls.append('moved_public_without_code_change')
    reject(rename_external(blob,b'_actor_tile_rows',b'_actor_tile_rowx'),'structural OMF metadata'); controls.append('other_public_external_name')
    # PUBDEF group is discarded by the normalized parser; pin its raw semantics too.
    bad = bytearray(blob); cursor = 0
    while bad[cursor] != 0x91:
        cursor += 3+int.from_bytes(bad[cursor+1:cursor+3],'little')
    end = cursor+3+int.from_bytes(bad[cursor+1:cursor+3],'little')
    assert bad[cursor+3] == 2
    bad[cursor+3] = 1
    bad[end-1] = (-sum(bad[cursor:end-1])) & 255
    assert v.parsed_leaf_object(bytes(bad)) == v.parsed_leaf_object(blob)
    reject(bytes(bad),'structural OMF metadata'); controls.append('PUBDEF_group_ignored_by_parser')
    for name,change in [('valid_DATA_target',lambda f:replace(f,target=(2,2))),('frame',lambda f:replace(f,frame=(1,1))),('displacement',lambda f:replace(f,displacement=1)),('relative_DATA',lambda f:replace(f,relative=True))]:
        bad,changed = rewrite_fixup(blob,lambda f:f.offset==7,change); assert changed
        reject(bad,'fixup records'); controls.append(name)
    saved = group.GROUP_SHA256; group.GROUP_SHA256 = None
    try:
        other = next(f for f in v.parsed_leaf_object(blob)[-1] if f.offset >= 48)
        reject(mutate_public_byte(blob,'assign_actor_103_tiles_',other.offset-48),'fixup addends')
        controls.append('other_public_addend_without_digest')
    finally: group.GROUP_SHA256 = saved
    return controls


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True); parser.add_argument('--build',type=Path,required=True); parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args(); exe = args.exe.read_bytes(); assert hashlib.sha256(exe).hexdigest() == TARGET_SHA256
    original = image(exe); blob,body,slices = bind_production(exe,args.build); cases = 0; controls = []
    for phase,placed,natural in slices:
        for number in range(8):
            memory,registers = seed(original,number); live = live_registers(registers,phase)
            expected,writes = model(memory,phase)
            for flags in (0x202,0xad7):
                address = phase['address']; reference = bytes(original[address:address+len(placed)])
                observed = execute(memory,live,flags,reference,address)
                actual = execute(memory,live,flags,placed,address)
                assert observed == actual and actual[:2] == (expected,writes),phase['symbol']
                assert actual[2:4] == (live,flags) and actual[4] == 0
                native = execute(memory,registers,flags,natural,0x50000,function=True)
                assert native[:2] == (expected,writes) and native[2][1:] == registers[1:]
                cases += 1
        # Each mutation keeps instruction length and address but selects a wrong value register.
        bad = bytearray(placed); site,old,new = ((1,0x25,0x05) if len(placed)==12 else (1,0x35,0x3d) if len(placed)==24 else (2,0x0d,0x15))
        assert bad[site] == old; bad[site] = new
        memory,registers = seed(original,7); actual = execute(memory,live_registers(registers,phase),0x202,bytes(bad),phase['address'])
        assert actual[0] != model(memory,phase)[0]; controls.append(phase['symbol'])
    whole = []
    for number in (2,7):
        memory,registers = seed(original,number); begin = group.LAYOUT['original_address']; size = group.LAYOUT['original_size']
        expected = execute(memory,registers,0xad7,bytes(original[begin:begin+size]),begin,function=True,full=True)
        actual = execute(memory,registers,0xad7,body,begin,function=True,full=True)
        assert actual == expected and actual[2][1:] == registers[1:] and actual[4] == 24
        assert actual[5] == {p['symbol'] for p in group.LAYOUT['phases']}
        whole.append(dict(seed=number,ordered_DATA_writes=len(actual[1])))
    report = dict(status='PASS',placed_c_bytes=85,DATA_sites=13,operation_cases=cases,private_cases=cases,whole_original_placed_cases=whole,context_controls=context_controls(blob),code_controls=controls,scope='Independent final-DATA/ordered-store models for three constant actor operations; unrelated bytes, adjacent slots, unused tile fields, all registers/flags and no stack use are checked for placed slices. Full private helpers separately check modeled effects and saved registers, not raw EAX/flags equivalence. Two whole-initializer replays compare original/placed DATA/write order/registers/flags/frame and verify selected live-ins. The full 32KB initializer is not claimed as C.')
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8'); print(json.dumps(report))


if __name__ == '__main__': main()
