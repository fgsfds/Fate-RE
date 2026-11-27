"""Model the mode-toggle/selection prefix in its retained six-save frame."""
import argparse
from copy import deepcopy
from dataclasses import dataclass,replace
import hashlib
import json
from pathlib import Path
from random import Random
from struct import pack
from capstone import Cs,CS_ARCH_X86,CS_MODE_32,CS_GRP_JUMP,CS_GRP_CALL,CS_OP_IMM,CS_OP_MEM
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE,UC_HOOK_MEM_WRITE
from unicorn import x86_const as x86
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
import bind_input_selection as group
import verify_c_leaf as v

START,SIZE,DATA_BASE=0x2d51a,3097,0x80000
MD=Cs(CS_ARCH_X86,CS_MODE_32);MD.detail=True
MODEL_DATA={"_input_mode": 15619, "_key_state": 424252, "_key_toggle_mode": 79440, "_selection": 487624, "_selection_1_enabled": 8809, "_selection_2_alternate_stock": 8843, "_selection_2_enabled": 8811, "_selection_2_stock": 8827, "_selection_3_enabled": 8813, "_selection_3_stock": 8829, "_selection_4_enabled": 8815, "_selection_4_stock": 8831, "_selection_5_enabled": 8817, "_selection_5_stock": 8833, "_selection_6_enabled": 8819, "_selection_6_stock": 8835, "_selection_7_enabled": 8821, "_selection_7_stock": 8837, "_toggled_mode": 8805}
ASM_NAMES={name[1:]:value for name,value in MODEL_DATA.items()}

STACK = 0x200000
STOP = 0x19b
GENERAL = ('eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp')
REG = {name: getattr(x86, 'UC_X86_REG_' + name.upper())
       for name in (*GENERAL, 'esp', 'eip', 'eflags')}
STATUS_MASK = 0x8c5
BYTE_VALUES = (0, 1, 2, 0x80, 0xff)
WORD_VALUES = (-32768, -1, 0, 1, 2, 32767)
SELECTION_KEYS = tuple(range(2, 10))


def address(name):
    return DATA_BASE + ASM_NAMES[name]


KEYS = address('key_state')
MODE = address('toggled_mode')
SELECTION = address('selection')
ENTRIES = {
    0x06: ('input_mode', ()),
    0x1a: ('toggle_consumer', ('eax',)),
    0x32: ('selection_0', ()), 0x4b: ('selection_1', ()), 0x6c: ('selection_2', ()),
    0xa7: ('selection_3', ()), 0xd8: ('selection_4', ()), 0x109: ('selection_5', ()),
    0x139: ('selection_6', ()), 0x16a: ('selection_7', ()),
}


@dataclass(frozen=True)
class Case:
    input_mode: int
    toggle_key: int
    keys: bytes
    toggled_mode: int
    selection: int
    enabled: tuple
    stock: tuple
    alternate_stock: int
    registers: dict
    flags: int


def cases():
    rng = Random(0x2d51a)

    def make(input_mode, toggle_key, keys, enabled, stock, alternate):
        return Case(input_mode, toggle_key, bytes(keys), rng.randrange(256),
                    rng.randrange(0x100000000), enabled, stock, alternate,
                    {reg: rng.getrandbits(32) | 0x81000000 for reg in GENERAL},
                    0x202 | (rng.getrandbits(12) & STATUS_MASK))

    for toggle_key in range(256):
        for active in (False, True):
            keys = [rng.choice(BYTE_VALUES) for _ in range(256)]
            keys[toggle_key] = rng.choice(BYTE_VALUES[1:]) if active else 0
            yield make(0, toggle_key, keys, (1,) * 7, (1,) * 6, 0)
    for mask in range(256):
        keys = [0] * 256
        for number, key in enumerate(SELECTION_KEYS):
            if mask & (1 << number):
                keys[key] = BYTE_VALUES[1 + number % (len(BYTE_VALUES) - 1)]
        yield make(0, 255, keys, tuple(rng.choice(WORD_VALUES) for _ in range(7)),
                   tuple(rng.choice(WORD_VALUES) for _ in range(6)), rng.choice(WORD_VALUES))
    for number, key in enumerate(SELECTION_KEYS):
        for enabled_word in WORD_VALUES:
            for stock_word in WORD_VALUES:
                keys = [0] * 256
                keys[key] = 0xff
                yield make(0, 255, keys, (enabled_word,) * 7, (stock_word,) * 6, -1)
    for mode in BYTE_VALUES[1:]:
        yield make(mode, 4, [0xff] * 256, (1,) * 7, (1,) * 6, 1)
    keys = bytearray(256)
    keys[4] = 0x80
    for main in WORD_VALUES:
        for backup in WORD_VALUES:
            yield make(0, 255, keys, (1,) * 7, (main,) * 6, backup)


def model(case):
    keys = bytearray(case.keys)
    toggle = case.toggled_mode
    selection = case.selection
    writes = []
    if case.input_mode == 0:
        armed = bool(keys[case.toggle_key])
        if armed:
            keys[case.toggle_key] = 0
            toggle ^= 1
            writes.extend(((KEYS + case.toggle_key, 1, 0), (MODE, 1, toggle)))
        inventory = (True, case.enabled[0] == 1,
                     case.enabled[1] == 1 and max(case.stock[0], case.alternate_stock) > 0,
                     *(enabled == 1 and stock > 0
                       for enabled, stock in zip(case.enabled[2:], case.stock[1:])))
        pressed = tuple(i for i, key in enumerate(SELECTION_KEYS) if keys[key])
        for number in pressed:
            key = SELECTION_KEYS[number]
            keys[key] = 0
            writes.append((KEYS + key, 1, 0))
            if inventory[number]:
                selection = number
                writes.append((SELECTION, 4, selection))
    return (bytes(keys), toggle, selection), tuple(writes)


def relocated(code, sites):
    result = bytearray(code)
    for site, target in sites.items():
        assert target >= DATA_BASE and int.from_bytes(code[site:site+4], 'little') == target - DATA_BASE
        result[site:site+4] = pack('<I', target)
    return bytes(result)


class Replay:
    def __init__(self, code, saves, private=False):
        self.saves = saves
        self.entries = {(0x03 if private and offset == 0x06 else offset): entry
                        for offset, entry in ENTRIES.items()}
        self.cpu = Uc(UC_ARCH_X86, UC_MODE_32)
        self.cpu.mem_map(0, 0x210000)
        self.cpu.mem_write(START, code)
        self.cpu.hook_add(UC_HOOK_CODE, self.on_pc)
        self.cpu.hook_add(UC_HOOK_MEM_WRITE, self.on_write)

    def on_pc(self, cpu, pc, size, data):
        off = pc - START
        assert 0 <= off < STOP and off + size <= STOP
        self.path.append(off)
        if off in self.entries:
            name, live = self.entries[off]
            self.observed[name] = {reg: cpu.reg_read(REG[reg]) for reg in live}

    def on_write(self, cpu, access, dest, size, value, data):
        if STACK - 4 * len(self.saves) <= dest < STACK:
            assert size == 4
            self.stack_writes.append((dest, value))
        else:
            assert ((KEYS <= dest < KEYS + 256 and size == 1)
                    or (dest == MODE and size == 1) or (dest == SELECTION and size == 4))
            self.writes.append((dest, size, value))

    def run(self, case):
        self.path, self.observed, self.writes, self.stack_writes = [], {}, [], []
        cpu = self.cpu
        cpu.mem_write(address('input_mode'), bytes([case.input_mode]))
        cpu.mem_write(address('key_toggle_mode'), bytes([case.toggle_key]))
        cpu.mem_write(KEYS, case.keys)
        cpu.mem_write(MODE, bytes([case.toggled_mode]))
        cpu.mem_write(SELECTION, pack('<I', case.selection))
        for number, value in enumerate(case.enabled, 1):
            cpu.mem_write(address(f'selection_{number}_enabled'), pack('<h', value))
        for number, value in enumerate(case.stock, 2):
            cpu.mem_write(address(f'selection_{number}_stock'), pack('<h', value))
        cpu.mem_write(address('selection_2_alternate_stock'), pack('<h', case.alternate_stock))
        cpu.mem_write(STACK - 48, b'\xa5' * 64)
        for reg, value in case.registers.items():
            cpu.reg_write(REG[reg], value)
        cpu.reg_write(REG['eflags'], case.flags)
        cpu.reg_write(REG['esp'], STACK)
        cpu.emu_start(START, START + STOP, count=180)
        assert cpu.reg_read(REG['eip']) == START + STOP
        assert cpu.reg_read(REG['esp']) == STACK - 4 * len(self.saves)
        assert [(STACK - 4 * i, case.registers[reg]) for i, reg in enumerate(self.saves, 1)] == self.stack_writes
        assert cpu.mem_read(STACK - 48, 48 - 4 * len(self.saves)) == b'\xa5' * (48 - 4 * len(self.saves))
        assert cpu.mem_read(STACK, 16) == b'\xa5' * 16
        memory = (bytes(cpu.mem_read(KEYS, 256)), cpu.mem_read(MODE, 1)[0],
                  int.from_bytes(cpu.mem_read(SELECTION, 4), 'little'))
        regs = {reg: cpu.reg_read(REG[reg]) for reg in GENERAL}
        return memory, tuple(self.writes), self.observed, regs, cpu.reg_read(REG['eflags']) & STATUS_MASK


def decode(code):
    rows={i.address:i for i in MD.disasm(bytes(code),0)}
    assert sum(i.size for i in rows.values())==len(code),'input instruction boundary'
    return rows


def branch(ins):
    assert not ins.group(CS_GRP_CALL),'input prefix call'
    if ins.group(CS_GRP_JUMP):
        assert ins.operands[0].type==CS_OP_IMM and ins.imm_size in (1,4),'input branch form'
        return ins.operands[0].imm


def resources(ins):
    aliases={alias:root for root,names in {'eax':('al','ah','ax'),'ebx':('bl','bh','bx'),'ecx':('cl','ch','cx'),'edx':('dl','dh','dx')}.items() for alias in names}
    reads,writes=ins.regs_access()
    normalized=lambda ids:{aliases.get(ins.reg_name(r),ins.reg_name(r)) for r in ids}
    memory=set()
    for op in ins.operands:
        if op.type==CS_OP_MEM:
            assert op.mem.base==op.mem.index==op.mem.segment==0,'input reordered indexed access'
            memory.update(range(op.mem.disp,op.mem.disp+op.size))
    return normalized(reads),normalized(writes),memory


def validate_layout(layout,original,natural):
    assert layout['original_address']==START and layout['original_size']==SIZE and layout['prefix_size']==STOP
    assert layout['DATA']==MODEL_DATA,'input DATA model bindings'
    old,new=decode(original),decode(natural);mapping={};owned=[];private=[]
    for row in layout['instructions']:
        off=row['original']-START;source=row['private'];size=row['size']
        assert off not in mapping and old[off].size==new[source].size==size,'input instruction map'
        mapping[off]=source;owned.extend(range(off,off+size));private.extend(range(source,source+size))
    assert owned==list(range(6,19))+list(range(26,STOP)),'input original partition'
    assert sorted(private)==list(range(3,16))+list(range(26,STOP)),'input private partition'
    normal={off:off-3 if off<19 else off for off in mapping}
    assert len(layout['swaps'])==len({tuple(pair) for pair in layout['swaps']})==6,'input unique swap inventory'
    for left,right in layout['swaps']:
        a,b=old[left],old[right];assert left+a.size==right,'input swap adjacency'
        ar,aw,am=resources(a);br,bw,bm=resources(b)
        assert not (aw&(br|bw) or bw&ar),'input swap register/flag dependency'
        assert not am&bm,'input swap memory dependency'
        normal[left],normal[right]=left+b.size,left
    assert mapping==normal,'input reorder map'
    entries={source:off for off,source in mapping.items()};entries[STOP]=STOP
    records={int(k):value for k,value in layout['branches'].items()}
    assert set(records)=={off for off,ins in new.items() if branch(ins) is not None},'input complete branch set'
    for off,source in mapping.items():
        ref,chosen=old[off],new[source];code=bytearray(chosen.bytes)
        target=branch(chosen);ref_target=branch(ref)
        if target is not None:
            assert entries[target]==ref_target,'input logical branch target'
            assert records[source]==[bytes(chosen.bytes[:chosen.imm_offset]).hex(),target,ref_target],'input branch metadata'
            assert (ref.imm_offset,ref.imm_size)==(chosen.imm_offset,chosen.imm_size)
            code[ref.imm_offset:ref.imm_offset+ref.imm_size]=(ref_target-off-ref.size).to_bytes(ref.imm_size,'little',signed=True)
        else:assert ref_target is None
        assert code==ref.bytes,'input selected instruction differs'
    phase_map={};phase_original=[]
    for phase in layout['phases']:
        assert phase['public']==layout['context']['public']
        selected=natural[phase['begin']:phase['end']];instructions=decode(selected)
        for offset,ins in instructions.items():
            old_off=phase['address']-START+offset;new_off=phase['begin']+offset
            assert old_off not in phase_map;phase_map[old_off]=new_off
            phase_original.extend(range(old_off,old_off+ins.size))
    assert phase_map==mapping and phase_original==owned,'input placement partition'
    assert original[:6]==bytes.fromhex('535152565755') and original[19:26]==bytes.fromhex('31c0a050360100'),'input retained entry/producer'
    assert natural[:3]==bytes.fromhex('535152') and natural[STOP:]==bytes.fromhex('5a595bc3'),'input private frame/return'
    assert natural[16:26]==bytes.fromhex('a05036010025ff000000'),'input alternate producer'
    return old


def bind_production(exe,build):
    layout=group.LAYOUT;pointers=read_le_fixups(exe)['pointers'];blob=(build/'inpsel.obj').read_bytes()
    original=exe[START+0x25600:START+0x25600+SIZE];output=bytearray(SIZE);covered=set();C_sites=0
    def install(address,code):
        region=set(range(address,address+len(code)));assert not covered&region
        assert region<=set(range(START,START+SIZE));covered.update(region)
        output[address-START:address-START+len(code)]=code
    for phase in layout['phases']:
        fields={};code,data=v.bind_leaf_details(blob,phase['symbol'],MODEL_DATA,address=phase['address'],functions={group.PUBLIC:START},code_bindings=fields)
        assert not fields and code==original[phase['address']-START:phase['address']-START+len(code)]
        v.verify_leaf_relocations(code,data,pointers,phase['address'],code_bindings=fields)
        install(phase['address'],code);C_sites+=len(data)
    assembly=(build/'asm/collect_input.bin').read_bytes();assert len(assembly)==2699
    for row in layout['retained']:
        code=assembly[row['binary_offset']:row['binary_offset']+row['size']]
        assert code==original[row['address']-START:row['address']-START+row['size']]
        assert {site-row['address']:target for site,target in pointers.between(row['address'],row['address']+row['size'])}=={int(k):value for k,value in row['fixups'].items()}
        install(row['address'],code)
    assert len(covered)==SIZE and output==original and C_sites==42
    fields={};natural,data=v.bind_leaf_details(blob,group.PUBLIC,MODEL_DATA,address=START,functions={group.PUBLIC:START},code_bindings=fields)
    assert not fields and len(natural)==415 and len(data)==43
    sites={site-START:target for site,target in pointers.between(START,START+STOP)}
    assert len(sites)==43
    return blob,bytes(original[:STOP]),bytes(output[:STOP]),natural,sites,{off:DATA_BASE+target for off,target in data.items()}


def context_controls(blob):
    from check_ripple_stack import mutate_public_byte
    from check_encounter_actor import rewrite_fixup
    from check_ripple_control import rename_external
    phase=group.LAYOUT['phases'][0];controls=[]
    def bind(b):return v.bind_leaf_details(b,phase['symbol'],MODEL_DATA,address=phase['address'],functions={group.PUBLIC:START},code_bindings={})
    def reject(label,b,expected):
        try:bind(b)
        except ValueError as error:assert expected in str(error),str(error)
        else:raise AssertionError('Input context mutation escaped: '+label)
        controls.append(label)
    unchanged,changed=rewrite_fixup(blob,lambda f:False,lambda f:f)
    assert not changed and bind(unchanged)==bind(blob)
    for label,off in [('private_save',0),('excluded_index_producer',16),('excluded_return',414)]:
        reject(label,mutate_public_byte(blob,group.PUBLIC,off),'complete context digest')
    _,_,names,_,fixups=v.parsed_leaf_object(blob);excluded=next(f for f in fixups if f.offset==17)
    other=next(n for n in range(1,len(names)) if n!=excluded.target[1])
    for label,change in [('excluded_DATA_target',lambda f:replace(f,target=(2,other))),('frame',lambda f:replace(f,frame=(1,1))),('displacement',lambda f:replace(f,displacement=1)),('relative_DATA',lambda f:replace(f,relative=True))]:
        bad,changed=rewrite_fixup(blob,lambda f:f.offset==17,change);assert changed
        reject(label,bad,'fixup records')
    reject('excluded_external_name',rename_external(blob,b'_key_toggle_mode',b'_key_toggle_modx'),'structural OMF metadata')
    for label,index,value,expected in [('PUBDEF_group',0,1,'structural OMF metadata'),('moved_public',2,1,'public layout')]:
        bad=bytearray(blob);cursor=0
        while bad[cursor]!=0x91:cursor+=3+int.from_bytes(bad[cursor+1:cursor+3],'little')
        end=cursor+3+int.from_bytes(bad[cursor+1:cursor+3],'little')
        assert bad[cursor+3]==2 and bad[cursor+4]==1
        site=cursor+3 if index==0 else cursor+6+bad[cursor+5]
        if index!=0:assert bad[site:site+4]==bytes(4)
        bad[site]=value;bad[end-1]=(-sum(bad[cursor:end-1]))&255
        reject(label,bytes(bad),expected)
    saved=group.CONTEXT_SHA256;leaf=v.LEAF_CONTEXT_SHA256.pop(group.PUBLIC);group.CONTEXT_SHA256=None
    try:reject('excluded_addend_without_digests',mutate_public_byte(blob,group.PUBLIC,17),'fixup addends')
    finally:group.CONTEXT_SHA256=saved;v.LEAF_CONTEXT_SHA256[group.PUBLIC]=leaf
    return controls


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True);parser.add_argument('--build',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();exe=args.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    blob,original,placed,private,sites,private_sites=bind_production(exe,args.build)
    rows=validate_layout(group.LAYOUT,original,private)
    orig=Replay(relocated(original,sites),('ebx','ecx','edx','esi','edi','ebp'))
    production=Replay(relocated(placed,sites),orig.saves)
    natural=Replay(relocated(private,private_sites),('ebx','ecx','edx'),private=True)
    outcomes={off:set() for off,ins in rows.items() if branch(ins) is not None};all_cases=list(cases())
    for case in all_cases:
        expected=orig.run(case);actual=production.run(case);compiled=natural.run(case)
        assert expected==actual==compiled and expected[:2]==model(case)
        if case.input_mode==0:assert expected[2]['toggle_consumer']=={'eax':case.toggle_key}
        else:assert expected[2]=={'input_mode':{}}
        for here,next_pc in zip(orig.path,orig.path[1:]+[STOP]):
            if here in outcomes:
                taken=next_pc==branch(rows[here]);assert taken or next_pc==here+rows[here].size
                outcomes[here].add(taken)
    assert len(all_cases)==1096 and len(outcomes)==24 and all(v=={False,True} for v in outcomes.values())
    controls=[]
    def reject(label,fn):
        try:fn()
        except (AssertionError,ValueError,KeyError):controls.append(label)
        else:raise AssertionError('Input mutation escaped: '+label)
    for label,change in [
        ('missing_branch',lambda l:l['branches'].pop('10')),
        ('wrong_branch_target',lambda l:l['branches']['10'].__setitem__(2,50)),
        ('missing_swap',lambda l:l['swaps'].pop()),
        ('duplicate_swap',lambda l:l['swaps'].append(l['swaps'][0])),
        ('omitted_instruction',lambda l:l['instructions'].pop()),
        ('partial_phase',lambda l:l['phases'][0].update(end=15)),
        ('wrong_placement',lambda l:l['phases'][0].update(address=START+7))]:
        changed=deepcopy(group.LAYOUT);change(changed);reject(label,lambda:validate_layout(changed,original,private))
    template=all_cases[0]
    def sample(keys,main=1,backup=1,mode=0):
        data=bytearray(256)
        for key,value in keys.items():data[key]=value
        return replace(template,input_mode=mode,toggle_key=255,keys=bytes(data),enabled=(1,)*7,stock=(main,)*6,alternate_stock=backup)
    for label,off,new_byte,case in [
        ('mode_guard',14,0x84,sample({9:255})),
        ('unsigned_key_byte',57,0x7e,sample({2:128})),
        ('signed_stock',155,0x76,sample({4:255},-1,-1)),
        ('saved_EBX',0,0x50,sample({}))]:
        bad=bytearray(placed);assert bad[off]!=new_byte;bad[off]=new_byte
        replay=Replay(relocated(bytes(bad),sites),orig.saves)
        def run_bad():assert replay.run(case)[:2]==model(case)
        reject(label,run_bad)
    toggle=next(i for i in rows.values() if i.mnemonic=='xor' and i.operands[0].type==CS_OP_MEM and i.operands[0].mem.disp==MODEL_DATA['_toggled_mode'])
    bad=bytearray(placed);bad[toggle.address+toggle.size-1]=2;replay=Replay(relocated(bytes(bad),sites),orig.saves);case=sample({255:1})
    def run_bad_toggle():assert replay.run(case)[:2]==model(case)
    reject('toggle_mask',run_bad_toggle)
    first_phase=group.LAYOUT['phases'][0];code,data=v.bind_leaf_details(blob,first_phase['symbol'],MODEL_DATA,address=first_phase['address'],functions={group.PUBLIC:START},code_bindings={})
    pointers=read_le_fixups(exe)['pointers']
    try:v.verify_leaf_relocations(code,data,pointers,first_phase['address'],code_bindings=data)
    except ValueError as error:
        assert str(error).startswith('Original LE relocation sites or targets differ from bound leaf:'),str(error)
        controls.append('DATA_as_CODE')
    else:raise AssertionError('Input DATA-as-CODE mutation escaped')
    report=dict(status='PASS',placed_c_bytes=398,DATA_sites=42,branches=24,cases=len(all_cases),branch_outcomes={hex(START+k):sorted(v) for k,v in outcomes.items()},code_metadata_controls=controls,context_controls=context_controls(blob),
        scope='Independent stable-memory model for one-shot toggle and ordered selection eligibility. Original and placed prefixes retain six saves; the private prefix retains three and stops before its epilogue. All ordered writes, key bytes, mode/selection, entry EAX, exit GPRs, guarded frames and defined EFLAGS mask0x8c5 agree. No keyboard/mouse continuation, interrupt interleavings or full collect_input C claim.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))


if __name__=='__main__':main()

