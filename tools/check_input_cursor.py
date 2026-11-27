"""Stable-memory oracle of cursor/map dispatch through mouse input blending."""
from dataclasses import dataclass,replace
from random import Random
DATA=0x80000
FIELDS={
 'cursor_mode':(0x3be5,1,False),'map_mode':(0x2bfa,2,True),
 'mouse_motion_disabled':(0x2bfc,2,True),'mouse_dx':(0x7deda,2,True),
 'mouse_dy':(0x7dedc,2,True),'mouse_buttons':(0x7dee2,2,False),
 'cursor_x':(0x8528e,2,True),'cursor_y':(0x8528c,2,True),
 'map_x':(0x2bf0,2,True),'map_scale_or_y':(0x2bf2,2,True),'map_offset_y':(0x2bf4,2,True),
 'active_mouse_buttons':(0x85290,2,False),'key_adjust_view':(0x13655,1,False),
 'key_strafe':(0x13642,1,False),'adjust_view_held':(0x12c34,1,False),
 'mouse_history_index':(0x12c35,2,True),'smoothed_mouse_dx':(0x7def2,2,True),
 'view_adjustment':(0x62f8c,4,True),'input_forward':(0x7def9,1,True),
 'input_strafe':(0x7defa,1,True),'input_turn':(0x7defb,1,True),
}
HISTORY=0x85292
def signed(v,bits):
    v&=(1<<bits)-1
    return v-(1<<bits) if v&(1<<(bits-1)) else v
def clamp(v,lo,hi):return min(max(v,lo),hi)

@dataclass(frozen=True)
class Case:
    state:dict
    keys:bytes
    history:tuple
    incoming_turn:int

class Memory:
    def __init__(self,case):
        self.bytes={};self.writes=[];self.history_reads=[]
        for n,value in case.state.items():self.store(n,value,record=False)
        for i,value in enumerate(case.history):self.write(HISTORY+2*i,2,value,record=False)
        for i,value in enumerate(case.keys):self.bytes[0x6793c+i]=value
        self.initial=dict(self.bytes)
    def read(self,address,size,signed_value=False):
        if size==2 and HISTORY<=address<=HISTORY+6:self.history_reads.append(address)
        value=int.from_bytes(bytes(self.bytes.get(address+i,0xa5) for i in range(size)),'little')
        return signed(value,8*size) if signed_value else value
    def get(self,name):return self.read(*FIELDS[name])
    def write(self,address,size,value,record=True):
        value&=(1<<(8*size))-1
        for i,b in enumerate(value.to_bytes(size,'little')):self.bytes[address+i]=b
        if record:self.writes.append((DATA+address,size,value))
    def store(self,name,value,record=True):
        address,size,_=FIELDS[name];self.write(address,size,value,record)

def model(case):
    m=Memory(case);g=m.get;w=m.store
    w('input_turn',case.incoming_turn)
    if g('cursor_mode') or g('map_mode'):
        dx=dy=0;w('active_mouse_buttons',0)
        if not g('map_mode'):
            w('cursor_x',g('cursor_x')+g('mouse_dx'))
            w('cursor_y',g('cursor_y')+g('mouse_dy'))
            w('cursor_x',clamp(g('cursor_x'),316,988))
            w('cursor_y',clamp(g('cursor_y'),364,440))
            w('map_x',g('cursor_x')>>2);w('map_scale_or_y',g('cursor_y')>>2)
            if g('mouse_buttons')&2:w('cursor_mode',0)
        elif not g('mouse_buttons')&2:
            w('map_x',g('map_x')-g('mouse_dx'))
            w('map_scale_or_y',g('map_scale_or_y')-g('mouse_dy'))
            w('map_scale_or_y',clamp(g('map_scale_or_y'),256,2048))
            limit=g('map_scale_or_y')-(g('map_scale_or_y')>>3)
            w('map_x',clamp(g('map_x'),-limit,limit))
        else:
            w('map_offset_y',g('map_offset_y')+g('mouse_dy'))
            w('map_offset_y',clamp(g('map_offset_y'),-256,256))
    else:
        if g('mouse_motion_disabled'):dx=dy=buttons=0
        else:dx,dy,buttons=g('mouse_dx'),g('mouse_dy'),g('mouse_buttons')
        w('active_mouse_buttons',buttons)
    if case.keys[g('key_adjust_view')]==1:w('adjust_view_held',1)
    elif g('adjust_view_held')==1:
        w('adjust_view_held',0);w('view_adjustment',100)
    if not case.keys[g('key_strafe')]:
        w('mouse_history_index',g('mouse_history_index')+1)
        if g('mouse_history_index')>3:w('mouse_history_index',0)
        index=g('mouse_history_index')
        m.write(HISTORY+2*index,2,dx)
        total=sum(m.read(HISTORY+2*i,2,True) for i in (1,0,2,3))
        w('smoothed_mouse_dx',total>>2)
        if g('adjust_view_held'):
            if dy>0:
                w('view_adjustment',g('view_adjustment')+4)
                if g('view_adjustment')>200:w('view_adjustment',200)
            elif dy<0:
                w('view_adjustment',g('view_adjustment')-4)
                if g('view_adjustment')<0:w('view_adjustment',0)
        else:w('input_forward',clamp(g('input_forward')-dy*8,-128,127))
    else:
        delta=g('input_turn')-dx*8
        w('smoothed_mouse_dx',0)
        w('input_strafe',g('input_strafe')+clamp(delta,-128,127))
    return m

def cases():
    rng=Random(0x2da1b)
    state={n:0 for n in FIELDS}
    state.update(cursor_x=500,cursor_y=400,map_scale_or_y=512,map_offset_y=0,
                 key_adjust_view=240,key_strafe=241,mouse_dx=17,mouse_dy=-9,
                 view_adjustment=100,input_forward=37,input_strafe=-41,
                 active_mouse_buttons=0x8134,smoothed_mouse_dx=-321)
    base=Case(state,bytes(256),(-32768,-1,1,32767),23)
    def changed(changes,strafe=0,adjust=0,indices=(240,241)):
        s=dict(state);s.update(changes);s['key_adjust_view'],s['key_strafe']=indices
        keys=bytearray(256);keys[indices[0]]=adjust;keys[indices[1]]=strafe
        return replace(base,state=s,keys=bytes(keys))
    modes=((0,0),(1,0),(0,1),(1,1),(128,-1),(255,32767),(0,-32768))
    for cursor,mode in modes:
        for strafe in (0,1,255):
            for adjust in (0,1,2):
                for held in (0,1,2,255):
                    for buttons in (0,2,0xff00,0xffff):
                        for disabled in (0,1):
                            yield changed(dict(cursor_mode=cursor,map_mode=mode,adjust_view_held=held,
                                               mouse_buttons=buttons,mouse_motion_disabled=disabled),strafe,adjust)
    bounds=(-32768,-989,-257,-256,-1,0,255,256,315,316,363,364,439,440,987,988,2048,32767)
    for field in ('cursor_x','cursor_y','map_x','map_scale_or_y','map_offset_y'):
        for value in bounds:
            for cursor,mode,buttons in ((1,0,0),(0,1,0),(0,1,2)):
                for dx,dy in ((-32768,32767),(-1,-1),(0,0),(32767,-32768)):
                    yield changed({field:value,'cursor_mode':cursor,'map_mode':mode,'mouse_buttons':buttons,'mouse_dx':dx,'mouse_dy':dy})
    indices={-32768,-32767,-2,-1,0,1,2,3,4,32767}
    for address,size,_ in FIELDS.values():
        for at in range(address,address+size):
            slot=(at-HISTORY)//2
            if -32768<=slot<=3:indices.add(signed(slot-1,16))
    for index in sorted(indices):
        for dx in (-32768,-1,0,1,32767):
            for held in (0,1,255):
                yield changed(dict(mouse_history_index=index,mouse_dx=dx,adjust_view_held=held))
    for view in (-2147483648,-1,0,1,3,4,5,199,200,201,2147483647):
        for dy in (-32768,-1,0,1,32767):
            yield changed(dict(view_adjustment=view,mouse_dy=dy,adjust_view_held=255))
    for index in range(256):
        yield changed({},strafe=index%3,adjust=index%3,indices=(index,index))
    for strafe in (0,255):
        for field in ('input_forward','input_strafe'):
            for value in (-128,-127,-1,0,1,126,127):
                for dx,dy in ((-17,-17),(-16,-16),(-15,-15),(-1,-1),(0,0),(1,1),(15,15),(16,16),(17,17)):
                    for turn in (-112,-1,0,1,111):
                        yield replace(changed({field:value,'mouse_dx':dx,'mouse_dy':dy},strafe),incoming_turn=turn)
    for history in ((-32768,)*4,(32767,)*4,(-1,0,0,0),(3,0,0,0)):
        yield replace(changed({'mouse_dx':history[0]}),history=history)


def main():
    import argparse,hashlib,json,struct
    from copy import deepcopy
    from pathlib import Path
    from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE,UC_HOOK_MEM_READ,UC_HOOK_MEM_WRITE
    from unicorn import x86_const as x
    from capstone import CS_GRP_CALL,CS_OP_MEM
    from compare_exe import TARGET_SHA256
    from check_input_selection import bind_production,decode,branch,relocated
    import bind_input_selection as group
    import verify_c_leaf as v
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True);parser.add_argument('--build',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--asm',type=Path)
    args=parser.parse_args();exe=args.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    BASE,BEGIN,END,STACK,DATA_SIZE=0x2d51a,0x2d9fe,0x2de0c,0x400000,0x28a300
    header=struct.unpack_from('<I',exe,0x3c)[0];table=struct.unpack_from('<I',exe,header+0x40)[0]
    assert struct.unpack_from('<2I',exe,header+table+24)==(DATA_SIZE,DATA),'actual LE DATA extent'
    assert 0<=HISTORY-32768*2 and HISTORY+3*2+2<=DATA_SIZE
    layout=group.CURSOR_LAYOUT;ctx=layout['context'];public=ctx['public']
    assert layout['DATA']['_input_cursor_data_words']==0
    _,original,placed,_,sites,_=bind_production(exe,args.build,stop=END-BASE,asm=args.asm)
    blob=(args.build/(ctx['object']+'.obj')).read_bytes();fields={}
    private,data=v.bind_leaf_details(blob,public,layout['DATA'],address=BASE,functions={public:BASE,**layout['CODE']},code_bindings=fields)
    assert not fields and len(private)==2395 and len(data)==197
    old,new=decode(original),decode(private)
    ranges=((0x501,0x51c),(0x51c,0x54d),(0x5c2,0x5e4),(0x61f,0x64e),(0x6c3,0x6dd),(0x743,0x785),(0x79a,0x7fb),(0x804,0x82e))
    def resources(ins):
        aliases={alias:root for root,names in {'eax':('ax','al','ah'),'ebx':('bx','bl','bh'),'ecx':('cx','cl','ch'),'edx':('dx','dl','dh'),'esi':('si',),'edi':('di',),'ebp':('bp',),'esp':('sp',)}.items() for alias in names}
        reads,writes=ins.regs_access();normalize=lambda ids:{aliases.get(ins.reg_name(r),ins.reg_name(r)) for r in ids}
        memory=set()
        for op in ins.operands:
            if op.type==CS_OP_MEM:
                assert op.mem.base==op.mem.index==op.mem.segment==0,'cursor reordered indexed memory'
                memory.update(range(op.mem.disp,op.mem.disp+op.size))
        return normalize(reads),normalize(writes),memory
    def independent(a,b):
        ar,aw,am=resources(a);br,bw,bm=resources(b)
        assert not (aw&(br|bw) or bw&ar or am&bm),'cursor reorder dependency'
    def validate(candidate):
        assert candidate['selected_bytes']==388 and candidate['combined_selected_bytes']==1205 and candidate['assembly_size']==1892
        mapping={};owned=[];private_owned=[]
        for row in candidate['instructions']:
            off=row['original']-BASE;source=row['private'];size=row['size']
            assert off not in mapping and old[off].size==new[source].size==size,'cursor instruction map'
            mapping[off]=source;owned.extend(range(off,off+size));private_owned.extend(range(source,source+size))
            assert not new[source].group(CS_GRP_CALL)
            assert all(new[source].reg_name(op.mem.base)!='esp' and new[source].reg_name(op.mem.index)!='esp' for op in new[source].operands if op.type==CS_OP_MEM),'selected private stack access'
        assert owned==[i for lo,hi in ranges for i in range(lo,hi)],'cursor complete operation partition'
        assert len(set(private_owned))==len(private_owned)==388,'cursor private overlap'
        records={int(k):value for k,value in candidate['branches'].items()}
        assert set(records)=={source for source in mapping.values() if branch(new[source]) is not None},'cursor branch inventory'
        entries={source:off for off,source in mapping.items()}
        entries.update({0x634:0x608,0x7cb:0x785,0x952:0x8f2})
        for off,source in mapping.items():
            ref,chosen=old[off],new[source];code=bytearray(chosen.bytes);target=branch(chosen)
            if target is not None:
                assert entries[target]==branch(ref),'cursor logical branch provenance'
                assert records[source]==[bytes(chosen.bytes[:chosen.imm_offset]).hex(),target,branch(ref)],'cursor branch target'
                assert (chosen.imm_offset,chosen.imm_size)==(ref.imm_offset,ref.imm_size)
                code[chosen.imm_offset:chosen.imm_offset+chosen.imm_size]=(branch(ref)-off-ref.size).to_bytes(chosen.imm_size,'little',signed=True)
            else:assert branch(ref) is None
            assert code==ref.bytes,'cursor selected instruction differs'
        phase_map={}
        for phase in candidate['phases']:
            assert phase['public']==public
            for off,ins in decode(private[phase['begin']:phase['end']]).items():
                at=phase['address']-BASE+off;assert at not in phase_map
                phase_map[at]=phase['begin']+off
        assert phase_map==mapping,'cursor phase partition'
        expected=((0x501,0x50c,0x527),(0x50c,0x51c,0x539),(0x51c,0x54d,0x549),
                  (0x5c2,0x5c9,0x5ef),(0x5c9,0x5e4,0x5fc),
                  (0x61f,0x63d,0x644),(0x63d,0x644,0x665),(0x644,0x647,0x662),(0x647,0x64e,0x66c),
                  (0x6c3,0x6dd,0x6f4),(0x743,0x785,0x789),(0x79a,0x7c1,0x7e0),(0x7c1,0x7fb,0x80a),(0x804,0x82e,0x851))
        assert [(p['address']-BASE,p['address']-BASE+p['end']-p['begin'],p['begin']) for p in candidate['phases']]==list(expected),'cursor private operation provenance'
        assert candidate['swaps']==[[0x63d,0x644]],'cursor swap inventory'
        independent(old[0x63d],old[0x644])
        original_targets={branch(i) for i in old.values() if branch(i) is not None}
        private_targets={branch(i) for i in new.values() if branch(i) is not None}
        assert not {0x63d,0x644}&original_targets,'branch enters original pan swap'
        assert not {mapping[0x63d],mapping[0x644]}&private_targets,'branch enters private pan swap'
        # The private X load crosses an AX-based Y store. The production BX-based
        # Y store remains before the placed load; it is not commuted.
        assert private[0x5f6:0x5fc]==bytes.fromhex('66a38c520800')
        independent(new[0x5ef],new[0x5f6])
        assert private[0x532:0x539]==bytes.fromhex('89142489542404')
        assert private[0x807:0x80a]==bytes.fromhex('8b1424')
        return mapping
    mapping=validate(layout)
    boundaries={BEGIN,END,*(p['address'] for p in layout['phases']),*(p['address']+p['end']-p['begin'] for p in layout['phases'])}
    general=('eax','ebx','ecx','edx','esi','edi','ebp')
    reg={n:getattr(x,'UC_X86_REG_'+n.upper()) for n in (*general,'esp','eip','eflags')}
    class Replay:
        def __init__(self,code):
            self.cpu=Uc(UC_ARCH_X86,UC_MODE_32);self.cpu.mem_map(0,0x410000)
            self.cpu.mem_write(DATA,b'\xa5'*DATA_SIZE);self.cpu.mem_write(BASE,code);self.previous=[]
            self.cpu.hook_add(UC_HOOK_CODE,self.on_pc);self.cpu.hook_add(UC_HOOK_MEM_WRITE,self.on_write);self.cpu.hook_add(UC_HOOK_MEM_READ,self.on_read)
        def snapshot(self):return tuple(self.cpu.reg_read(reg[n]) for n in general)+(self.cpu.reg_read(reg['esp']),self.cpu.reg_read(reg['eflags'])&0x8c5)
        def on_pc(self,cpu,pc,size,user):
            assert BEGIN<=pc and pc+size<=END,'cursor execution extent'
            self.path.append(pc-BASE)
            if pc in boundaries:self.boundaries.append((pc,self.snapshot()))
            if pc==BASE+0x7c1:
                assert signed(cpu.reg_read(reg['edx']),16)==self.dx,'history DX input contract'
                self.contracts.add('history_DX')
            if pc==BASE+0x7fb:
                assert signed(cpu.reg_read(reg['eax']),16)==self.dy,'history AX continuation contract'
                assert (cpu.reg_read(reg['ecx'])>>8)&255==self.held,'history CH continuation contract'
                self.contracts.add('history_AX_CH')
            if pc==BASE+0x54d:
                address,size,_=FIELDS['cursor_x'];assert cpu.reg_read(reg['ebx'])&0xffffffff==int.from_bytes(cpu.mem_read(DATA+address,size),'little',signed=True)&0xffffffff
                self.contracts.add('cursor_EBX')
            if pc==BASE+0x63d:
                assert signed(cpu.reg_read(reg['esi']),16)==signed(self.case.state['map_scale_or_y']-self.case.state['mouse_dy'],16)
                assert signed(cpu.reg_read(reg['ecx']),16)==signed(self.case.state['map_x']-self.case.state['mouse_dx'],16)
                self.contracts.add('pan_SI_ECX')
        def on_write(self,cpu,access,address,size,value,user):
            assert DATA<=address and address+size<=DATA+DATA_SIZE,'cursor DATA/stack write extent'
            self.writes.append((address,size,value))
        def on_read(self,cpu,access,address,size,value,user):
            if DATA+HISTORY<=address<=DATA+HISTORY+6:
                assert size==2;self.history_reads.append(address-DATA)
        def run(self,case,poison=0,verify_reads=True):
            self.case=case;cpu=self.cpu;initial=Memory(case).initial
            for address,size,_ in self.previous:cpu.mem_write(address,b'\xa5'*size)
            addresses=sorted(initial);runs=[]
            for address in addresses:
                if not runs or address!=runs[-1][0]+len(runs[-1][1]):runs.append((address,bytearray()))
                runs[-1][1].append(initial[address])
            for address,content in runs:cpu.mem_write(DATA+address,bytes(content))
            for i,n in enumerate(general):cpu.reg_write(reg[n],(0x81a3b5c7+i)^poison)
            cpu.reg_write(reg['eax'],case.incoming_turn&0xffffffff)
            cpu.mem_write(STACK-64,b'\x5a'*128);cpu.reg_write(reg['esp'],STACK);cpu.reg_write(reg['eflags'],0x202)
            game=not(case.state['cursor_mode'] or case.state['map_mode']) and not case.state['mouse_motion_disabled']
            self.dx=case.state['mouse_dx'] if game else 0;self.dy=case.state['mouse_dy'] if game else 0
            held=case.state['adjust_view_held'];key=case.keys[case.state['key_adjust_view']]
            self.held=1 if key==1 else 0 if held==1 else held
            self.writes=[];self.history_reads=[];self.path=[];self.boundaries=[];self.contracts=set()
            cpu.emu_start(BEGIN,END,count=350)
            assert cpu.reg_read(reg['eip'])==END and cpu.reg_read(reg['esp'])==STACK
            assert cpu.mem_read(STACK-64,128)==b'\x5a'*128,'cursor protected stack'
            self.boundaries.append((END,self.snapshot()));expected=model(case)
            assert self.writes==expected.writes,'cursor ordered DATA writes'
            if verify_reads:assert self.history_reads==expected.history_reads,'volatile history read order'
            for address,size,_ in self.writes:
                assert bytes(cpu.mem_read(address,size))==bytes(expected.bytes.get(address-DATA+i,0xa5) for i in range(size)),'cursor final written bytes'
            for address,size,_ in FIELDS.values():
                assert bytes(cpu.mem_read(DATA+address,size))==bytes(expected.bytes[address+i] for i in range(size)),'cursor final modeled DATA'
            self.previous=list(self.writes)
            return tuple(self.writes),tuple(self.history_reads),tuple(self.boundaries),self.snapshot()
    orig=Replay(relocated(original,sites));production=Replay(relocated(placed,sites));all_cases=list(cases())
    outcomes={off:set() for off in mapping if branch(old[off]) is not None};contracts=set()
    for poison in (0,0xffffffff):
        for case in all_cases:
            assert orig.run(case,poison)==production.run(case,poison),'cursor original/placed live state'
            contracts.update(production.contracts)
            for here,next_pc in zip(orig.path,orig.path[1:]+[END-BASE]):
                if here in outcomes:
                    taken=next_pc==branch(old[here]);assert taken or next_pc==here+old[here].size
                    outcomes[here].add(taken)
    assert len(all_cases)==4941 and len(outcomes)==7
    assert all(values==({True} if old[off].mnemonic=='jmp' else {False,True}) for off,values in outcomes.items()),outcomes
    assert contracts=={'history_DX','history_AX_CH','cursor_EBX','pan_SI_ECX'}
    assert any(c.state['mouse_history_index']==-14798 for c in all_cases),'packed-input history alias case'

    controls=[]
    def reject(label,fn,expected=None):
        try:fn()
        except (AssertionError,ValueError,KeyError,StopIteration) as error:
            if expected is not None:assert expected in str(error),str(error)
            controls.append(label)
        else:raise AssertionError('Cursor mutation escaped: '+label)
    for label,change in (
        ('missing_instruction',lambda l:l['instructions'].pop()),
        ('partial_phase',lambda l:l['phases'][-1].update(end=l['phases'][-1]['end']-1)),
        ('missing_branch',lambda l:l['branches'].pop(next(iter(l['branches'])))),
        ('wrong_branch_target',lambda l:next(iter(l['branches'].values())).__setitem__(2,0)),
        ('missing_pan_swap',lambda l:l['swaps'].clear())):
        changed=deepcopy(layout);change(changed);reject(label,lambda:validate(changed))
    changed=deepcopy(layout)
    row=next(r for r in changed['instructions'] if r['original']==BASE+0x516)
    row['private']=0x63e;changed['branches'].pop(str(0x543))
    changed['branches'][str(0x63e)]=['0f85',0x6f4,0x608]
    reject('wrong_condition_branch_substitution',lambda:validate(changed),'logical branch provenance')
    def counterexample(label,code,sample,relocations=None,expected=None):
        replay=Replay(relocated(bytes(code),sites if relocations is None else relocations))
        reject(label,lambda:replay.run(sample),expected)
    # Same registers and sum, different volatile observation order.
    bad=bytearray(placed);a,b=old[0x7c9],old[0x7d0];assert a.size==b.size==7
    bad[a.address:b.address+b.size]=b.bytes+a.bytes
    sample=next(c for c in all_cases if c.state['mouse_history_index']==-14798 and c.state['mouse_dx']==32767)
    swapped_sites=dict(sites);left=a.address+a.disp_offset;right=b.address+b.disp_offset
    swapped_sites[left],swapped_sites[right]=swapped_sites[right],swapped_sites[left]
    reordered=Replay(relocated(bytes(bad),swapped_sites))
    expected=orig.run(sample);actual=reordered.run(sample,verify_reads=False)
    assert expected[0]==actual[0] and expected[2:]==actual[2:] and expected[1]!=actual[1],'read-order-only counterexample'
    counterexample('reordered_volatile_reads',bad,sample,swapped_sites,'volatile history read order')
    assert signed(32767>>8,8)!=sample.state['input_forward'],'alias changes packed forward byte'
    # Change the ring bound from3 to2; index2 then resets at the wrong time.
    hist=next(i for off,i in old.items() if 0x79a<=off<0x7c1 and i.mnemonic=='cmp')
    bad=bytearray(placed);bad[hist.address+hist.imm_offset]=2
    sample=replace(all_cases[0],state={**all_cases[0].state,'cursor_mode':0,'map_mode':0,'mouse_history_index':2},keys=bytes(256))
    counterexample('history_bound',bad,sample)
    view=next(i for off,i in old.items() if 0x804<=off<0x82e and i.mnemonic=='add')
    bad=bytearray(placed);bad[view.address+view.imm_offset]=5
    sample=replace(sample,state={**sample.state,'adjust_view_held':255,'mouse_dy':1,'view_adjustment':100})
    counterexample('view_step',bad,sample)
    dependent_store=decode(bytes.fromhex('66891d8c520800'))[0]
    reject('projection_store_register_dependency',lambda:independent(new[0x5ef],dependent_store),'reorder dependency')

    from check_encounter_actor import rewrite_fixup
    from check_ripple_stack import mutate_public_byte
    from dataclasses import replace as fixup_replace
    _,_,external,_,fixups=v.parsed_leaf_object(blob)
    history=[f for f in fixups if f.target[0]==2 and external[f.target[1]]=='_input_cursor_data_words']
    assert len(history)==5 and all(not f.relative and f.width==4 and f.location==9 and f.frame==(1,2) and f.displacement==0 for f in history)
    assert [int.from_bytes(private[f.offset:f.offset+4],'little') for f in history]==[HISTORY,HISTORY+2,HISTORY,HISTORY+4,HISTORY+6]
    phase=layout['phases'][0]
    def bind(b):return v.bind_leaf_details(b,phase['symbol'],layout['DATA'],address=phase['address'],functions={public:BASE,**layout['CODE']},code_bindings={})
    for label,offset in (('excluded_stack_spills',0x532),('excluded_stack_reload',0x807),('excluded_projection_store',0x5f6),('excluded_return',2394)):
        reject(label,lambda:bind(mutate_public_byte(blob,public,offset)),'complete context digest')
    other=next(i for i,n in enumerate(external) if n=='_key_state')
    for label,change in (
        ('history_wrong_DATA_target',lambda f:fixup_replace(f,target=(2,other))),
        ('history_relative',lambda f:fixup_replace(f,relative=True)),
        ('history_frame',lambda f:fixup_replace(f,frame=(1,1)))):
        bad,changed=rewrite_fixup(blob,lambda f:f.offset==history[0].offset,change);assert changed
        reject(label,lambda:bind(bad),'fixup records')
    digest=group.CURSOR_CONTEXT_SHA256;leaf=v.LEAF_CONTEXT_SHA256.pop(public);group.CURSOR_CONTEXT_SHA256=None
    try:reject('history_addend_without_digests',lambda:bind(mutate_public_byte(blob,public,history[0].offset)),'fixup addends')
    finally:group.CURSOR_CONTEXT_SHA256=digest;v.LEAF_CONTEXT_SHA256[public]=leaf
    report=dict(status='PASS',new_native_bytes=388,new_DATA_sites=41,new_branches=7,operations=8,cases=len(all_cases),poison_seeds=2,
                live_contracts=sorted(contracts),branch_outcomes={hex(BASE+k):sorted(v) for k,v in outcomes.items()},controls=controls,
                scope='Original and freshly bound production cursor/map/mouse blend agree with independent mutable-byte DATA model on all ordered writes, volatile history read order, final modeled/written bytes, GPR/defined-flag fragment boundaries and protected stack. Covers signed history-index aliases and both positive-view exits. Full DATA extent is checked from LE headers. Private compiler frame/full routine ABI is not substituted; no interrupts, BIOS calls or action-packing continuation modeled.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()
