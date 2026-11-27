"""Typed models and live-input replay for the indexed startup actor operations."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import bind_board_actor as group
import verify_c_leaf as v
import check_board_actor_groups as base
from check_start_hook import image, DS
from compare_exe import TARGET_SHA256

NAMES = ('eax','ebx','ecx','edx','esi','edi','ebp')
# Independent byte offsets, strides and widths of the actual typed fields.
FIELDS = {
    'saved_actor_positions.x': (0x772c4,12,4),
    'saved_actor_positions.y': (0x772c8,12,4),
    'actor_sequence_initial': (0x7e4e2,1,1),
    'actor_health': (0x7cefa,2,2),
    'saved_actor_lotag': (0x7d6ce,2,2),
    'actor_z_offset': (0x79214,4,4),
    'actor_profile': (0x7e8cc,1,1),
    'actor_projectile_type': (0x7eeab,1,1),
    'actor_mode': (0x7f67f,1,1),
    'actor_waypoints.first': (0x78a40,4,2),
}
KINDS = {name:(name,) for name in FIELDS if '.' not in name}
KINDS['saved_actor_positions'] = ('saved_actor_positions.x','saved_actor_positions.y')
KINDS['actor_waypoints'] = ('actor_waypoints.first',)


def validate_operations(layout):
    operations = layout['operations']; consumed = set()
    for operation in operations:
        assert tuple(operation['fields']) == KINDS.get(operation['operation']), 'incomplete operation fields'
        assert len(operation['fields']) == len(operation['writes']), 'incomplete operation writes'
    for phase in layout['phases']:
        start = phase['address']; end = start+phase['end']-phase['begin']
        members = sorted([(n,o) for n,o in enumerate(operations) if start<=o['original_start']<end],key=lambda pair:pair[1]['original_start'])
        assert members, 'empty operation partition'
        cursor,source = start,phase['begin']
        for n,operation in members:
            assert n not in consumed, 'overlapping operation partitions'
            assert (operation['original_start'],operation['candidate_start']) == (cursor,source), 'operation partition gap'
            cursor,source = operation['original_end'],operation['candidate_end']
            consumed.add(n)
        assert (cursor,source) == (end,phase['end']), 'incomplete operation partition'
    assert len(consumed) == len(operations), 'unplaced operation'


def live(registers, operation):
    registers = list(registers)
    for name,mask in operation['live_in_bitmasks'].items():
        pos = NAMES.index(name); value = operation['live_in_values'][name]
        assert value & ~mask == 0
        registers[pos] = (registers[pos] & ~mask) | value
    return tuple(registers)


def model(memory, operation):
    memory = bytearray(memory); writes = []
    assert 0 <= operation['slot'] < 501
    assert len(operation['fields']) == len(operation['writes'])
    for field,(_,recorded_address,recorded_width,value) in zip(operation['fields'],operation['writes']):
        origin,stride,width = FIELDS[field]
        address = origin+stride*operation['slot']
        assert (address,width) == (recorded_address,recorded_width)
        value &= (1 << (width*8))-1
        memory[DS+address:DS+address+width] = value.to_bytes(width,'little')
        writes.append((DS+address,width,value))
    return bytes(memory[DS:DS+base.DATA_SIZE]),writes


def watcher(operations, *, private=False):
    sites = {(0x50000+o['candidate_start'] if private else o['original_start']):o for o in operations}
    visited = set()
    def watch(cpu,address):
        if address not in sites: return
        operation = sites[address]
        for name,mask in operation['live_in_bitmasks'].items():
            actual = cpu.reg_read(base.REGS[NAMES.index(name)]) & mask
            assert actual == operation['live_in_values'][name],(hex(address),name,actual)
        visited.add(address)
    return watch,visited


def context_controls(blob, layout):
    from dataclasses import replace
    from check_encounter_actor import rewrite_fixup
    from check_ripple_stack import mutate_public_byte
    phase = layout['phases'][0]; context = layout['context']; public = context['public']; controls = []
    def bind(b): return v.bind_leaf_details(b,phase['symbol'],v.DATA_OFFSETS,address=phase['address'],code_bindings={})
    def reject(b,message):
        try: bind(b)
        except ValueError as error: assert message in str(error),str(error)
        else: raise AssertionError(message)
    unchanged,changed = rewrite_fixup(blob,lambda f:False,lambda f:f)
    assert not changed and bind(unchanged) == bind(blob)
    for label,site in [('excluded_prologue',0),('excluded_return',context['size']-1)]:
        reject(mutate_public_byte(blob,public,site),'complete context digest'); controls.append(label)
    _,_,names,_,fixups = v.parsed_leaf_object(blob)
    first = fixups[0]
    other = next(i for i in range(1,len(names)) if i != first.target[1])
    for label,change in [('valid_DATA_target',lambda f:replace(f,target=(2,other))),('frame',lambda f:replace(f,frame=(1,1))),('displacement',lambda f:replace(f,displacement=1)),('relative_DATA',lambda f:replace(f,relative=True))]:
        bad,changed = rewrite_fixup(blob,lambda f:f.offset==first.offset,change); assert changed
        reject(bad,'fixup records'); controls.append(label)
    # The normalized parser discards the public's group, but the raw guard must not.
    bad = bytearray(blob); cursor = 0
    while bad[cursor] != 0x91: cursor += 3+int.from_bytes(bad[cursor+1:cursor+3],'little')
    end = cursor+3+int.from_bytes(bad[cursor+1:cursor+3],'little')
    assert bad[cursor+3] == 2
    bad[cursor+3] = 1; bad[end-1] = (-sum(bad[cursor:end-1])) & 255
    assert v.parsed_leaf_object(bytes(bad)) == v.parsed_leaf_object(blob)
    reject(bytes(bad),'structural OMF metadata'); controls.append('PUBDEF_group')
    digest = group.INDEXED_SHA256; leaf_digest = v.LEAF_CONTEXT_SHA256.pop(public)
    group.INDEXED_SHA256 = None
    try:
        assert not any(p['begin'] <= first.offset < p['end'] for p in layout['phases'])
        reject(mutate_public_byte(blob,public,first.offset),'fixup addends')
        controls.append('excluded_addend_without_digests')
    finally:
        group.INDEXED_SHA256 = digest; v.LEAF_CONTEXT_SHA256[public] = leaf_digest
    return controls


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True); parser.add_argument('--build',type=Path,required=True); parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args(); exe = args.exe.read_bytes(); assert hashlib.sha256(exe).hexdigest() == TARGET_SHA256
    layout = group.INDEXED_LAYOUT; validate_operations(layout)
    operations = layout['operations']; assert len(operations) == 281
    original = image(exe); _,body,_ = base.bind_production(exe,args.build)
    blob = (args.build/'actsetup.obj').read_bytes(); values = {k:DS+n for k,n in v.DATA_OFFSETS.items()}; fields = {}
    natural,data = v.bind_leaf_details(blob,layout['context']['public'],values,address=0x50000,code_bindings=fields)
    assert not fields and len(natural) == 30235 and len(data) == 2579
    begin = group.LAYOUT['original_address']; cases = 0
    seed_registers = base.seed(original,0)[1]
    for operation in operations:
        address = operation['original_start']; size = operation['original_end']-address
        candidate = body[address-begin:address-begin+size]
        assert candidate == natural[operation['candidate_start']:operation['candidate_end']]
        for number in (0,7):
            memory,_ = base.seed(original,number)
            registers = seed_registers if number == 0 else tuple(r ^ 0xffffffff for r in seed_registers)
            registers = live(registers,operation); expected = model(memory,operation)
            flags = 0x202 if number == 0 else 0xad7
            reference = bytes(original[address:address+size])
            observed = base.execute(memory,registers,flags,reference,address)
            placed = base.execute(memory,registers,flags,candidate,address)
            assert placed == observed and placed[:2] == expected,hex(address)
            cases += 1
    whole = []; register_differences = flag_differences = 0
    for number in (0,1,0x7fff,0xdeadbeef,0xffffffff):
        memory,registers = base.seed(original,number)
        watch,visited = watcher(operations)
        reference = bytes(original[begin:begin+len(body)])
        expected = base.execute(memory,registers,0xad7,reference,begin,function=True,full=True,watch=watch)
        assert len(visited) == len(operations)
        watch,visited = watcher(operations)
        placed = base.execute(memory,registers,0xad7,body,begin,function=True,full=True,watch=watch)
        assert placed == expected and len(visited) == len(operations)
        watch,visited = watcher(operations,private=True)
        native = base.execute(memory,registers,0xad7,natural,0x50000,function=True,full=True,watch=watch)
        assert len(visited) == len(operations) and native[0] == expected[0]
        assert Counter(native[1]) == Counter(expected[1]) and len(native[1]) == 3079
        assert native[1][:501] == expected[1][:501]
        assert native[2][1:] == registers[1:]
        register_differences += native[2] != expected[2]; flag_differences += native[3] != expected[3]
        whole.append(dict(seed=number,ordered_placed_writes=len(placed[1]),private_writes=len(native[1])))
    # Wrong byte/word values and wrong 12-byte coordinate stride must affect the model.
    code_controls = []
    for field,width in [('actor_sequence_initial',1),('actor_health',2)]:
        operation = next(o for o in operations if o['fields'] == [field])
        address = operation['original_start']; code = bytearray(body[address-begin:operation['original_end']-begin])
        value = operation['writes'][0][3]
        assert code[-width:] == value.to_bytes(width,'little')
        code[-width] ^= 1
        memory,registers = base.seed(original,7); actual = base.execute(memory,live(registers,operation),0x202,bytes(code),address)
        assert actual[0] != model(memory,operation)[0]; code_controls.append(field+'_value')
    operation = next(o for o in operations if len(o['fields']) == 2)
    address = operation['original_start']; code = bytearray(body[address-begin:operation['original_end']-begin])
    from capstone import Cs,CS_ARCH_X86,CS_MODE_32
    decoder = Cs(CS_ARCH_X86,CS_MODE_32); decoder.detail = True
    instruction = next(i for i in decoder.disasm(bytes(code),0) if i.mnemonic == 'shl' and i.bytes[-1] == 2)
    code[instruction.address+instruction.size-1] = 1
    memory,registers = base.seed(original,7); actual = base.execute(memory,live(registers,operation),0x202,bytes(code),address)
    assert actual[0] != model(memory,operation)[0]; code_controls.append('saved_position_stride')
    from copy import deepcopy
    metadata_controls = []
    for label,change,message in [
        ('missing_saved_Y',lambda o:(o['fields'].pop(),o['writes'].pop()),'operation fields'),
        ('operation_partition_gap',lambda o:o.update(original_end=o['original_end']-1,candidate_end=o['candidate_end']-1),'partition')]:
        changed = deepcopy(operations)
        change(next(o for o in changed if o['operation'] == 'saved_actor_positions'))
        try: validate_operations(dict(operations=changed,phases=layout['phases']))
        except AssertionError as error: assert message in str(error),str(error)
        else: raise AssertionError('Metadata mutation escaped: '+label)
        metadata_controls.append(label)
    operation = deepcopy(operations[0]); assert operation['original_start'] == 0x2204e
    operation['live_in_bitmasks']['eax'] &= ~1; operation['live_in_values']['eax'] &= ~1
    memory,_ = base.seed(original,7); registers = tuple(r ^ 0xffffffff for r in seed_registers)
    address = operation['original_start']; code = body[address-begin:operation['original_end']-begin]
    actual = base.execute(memory,live(registers,operation),0x202,code,address)
    assert actual[0] != model(memory,operation)[0]; metadata_controls.append('omitted_AX_bit')
    report = dict(status='PASS',placed_c_bytes=4271,DATA_sites=318,operations=len(operations),runs=len(layout['phases']),operation_cases=cases,whole_cases=whole,private_register_difference_cases=register_differences,private_flag_difference_cases=flag_differences,context_controls=context_controls(blob,layout),code_controls=code_controls,scope='Independent typed field/slot/width/value models with poisoned unused register bits; original and placed operation DATA/write traces/registers/flags agree. Five whole original/placed runs preserve 3079 ordered writes and 281 entry contracts. Whole private C checks final DATA, write multiset, saved registers and the same masked entries; private raw EAX/flags and full store-order equivalence are not required. No whole-routine byte-exact C claim.')
    report['metadata_controls'] = metadata_controls
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8'); print(json.dumps(report))


if __name__ == '__main__': main()
