"""Independent stable-memory action/latch/brightness/FIFO tail model."""
from dataclasses import dataclass,replace
from random import Random
DATA,KEYS,PALETTE=0x80000,0x6793c,0x27c0a0
FIELDS={'selection':(0x770c8,4),'input_mode':(0x3d03,1),'input_actions':(0x7defc,2),
 'active_mouse_buttons':(0x85290,2),'saved_mouse_buttons':(0x3cfc,2),
 'button_latch_disabled':(0x2bf6,2),'prior_action_word':(0x5ac8f,2),
 'primary_button_latch':(0x12c37,2),'secondary_button_latch':(0x12c39,2),
 'button_alternate':(0x12c3b,2),'brightness':(0x3cfe,2),
 'key_fifo_read':(0x7f87b,1),'key_fifo_write':(0x7f878,1)}
KEY_FIELDS={'key_action_0':0x13645,'key_action_1':0x13646,'key_action_2':0x13647,
 'key_action_3':0x13648,'key_action_4':0x1364d,'key_action_5':0x1364e,
 'key_action_10':0x13644,'key_action_11':0x13643,'key_action_12':0x1364c,
 'key_run':0x13641,'key_latched_secondary':0x1364f}
def signed(v,bits):
    v&=(1<<bits)-1
    return v-(1<<bits) if v&(1<<(bits-1)) else v
@dataclass(frozen=True)
class Case:
    state:dict
    indices:dict
    keys:bytes
class Memory:
    def __init__(self,case):
        self.bytes={};self.writes=[];self.fifo_reads=[];self.calls=[];self.steps=0;self.terminates=True
        for n,value in case.state.items():self.store(n,value,False)
        for n,value in case.indices.items():self.write(KEY_FIELDS[n],1,value,False)
        for i,value in enumerate(case.keys):self.bytes[KEYS+i]=value
        self.initial=dict(self.bytes)
    def read(self,address,size):
        if address in (FIELDS['key_fifo_read'][0],FIELDS['key_fifo_write'][0]):self.fifo_reads.append(DATA+address)
        return int.from_bytes(bytes(self.bytes.get(address+i,0xa5) for i in range(size)),'little')
    def get(self,n):return self.read(*FIELDS[n])
    def key(self,n):return self.read(KEYS+self.read(KEY_FIELDS[n],1),1)
    def write(self,address,size,value,record=True):
        value&=(1<<(8*size))-1
        for i,b in enumerate(value.to_bytes(size,'little')):self.bytes[address+i]=b
        if record:self.writes.append((DATA+address,size,value))
    def store(self,n,value,record=True):self.write(*FIELDS[n],value,record)
def model(case,max_steps=64):
    m=Memory(case);g=m.get;w=m.store
    packed=(g('selection')<<13)&0xffff;w('input_actions',packed)
    if not g('input_mode'):
        packed|=(m.key('key_action_12')==1)<<12;w('input_actions',packed)
    for name,bit in (('key_action_0',0),('key_action_1',1),('key_action_4',4),('key_action_5',5),('key_run',8),('key_action_2',2),('key_action_3',3),('key_action_10',10),('key_action_11',11)):
        value=m.key(name)
        if bit in (10,11):value=int(value==1)
        packed=(packed|(value<<bit))&0xffff;w('input_actions',packed)
    packed|=int((g('active_mouse_buttons')&1)>(g('saved_mouse_buttons')&1))<<11
    w('input_actions',packed)
    if g('active_mouse_buttons')&1 and not g('button_latch_disabled'):
        if g('prior_action_word')&0xe000:w('button_alternate',0)
        if not g('primary_button_latch') and not g('secondary_button_latch'):
            if not g('button_alternate'):
                m.write(KEYS+case.indices['key_action_11'],1,1);w('primary_button_latch',1);w('button_alternate',1)
            else:
                m.write(KEYS+case.indices['key_latched_secondary'],1,1);w('secondary_button_latch',1);w('button_alternate',0)
    else:
        if g('primary_button_latch')==1:
            w('primary_button_latch',0);m.write(KEYS+case.indices['key_action_11'],1,0)
        if g('secondary_button_latch')==1:
            w('secondary_button_latch',0);m.write(KEYS+case.indices['key_latched_secondary'],1,0)
    w('saved_mouse_buttons',g('active_mouse_buttons'))
    if g('input_actions')&0x800 and g('selection')==3:
        m.write(FIELDS['saved_mouse_buttons'][0],1,g('saved_mouse_buttons')&0xfe)
    if m.read(KEYS+0x57,1):
        m.write(KEYS+0x57,1,0);w('brightness',g('brightness')+1)
        if signed(g('brightness'),16)>8:w('brightness',0)
        m.calls.append((signed(g('brightness'),16),DATA+PALETTE))
    if g('input_mode'):
        while True:
            if m.steps==max_steps:m.terminates=False;break
            if g('key_fifo_read')==g('key_fifo_write'):break
            g('key_fifo_read');g('key_fifo_read')
            w('key_fifo_read',(g('key_fifo_read')+2)&63);m.steps+=1
    return m
def cases():
    rng=Random(0x2de0c)
    state={n:0 for n in FIELDS};state.update(selection=3,input_actions=0x8134,brightness=7,saved_mouse_buttons=0x8100)
    indices={n:220+i for i,n in enumerate(KEY_FIELDS)}
    base=Case(state,indices,bytes(256))
    def make(changes={},keys=None,bindings=None):
        return replace(base,state={**state,**changes},keys=bytes(256) if keys is None else bytes(keys),indices=indices if bindings is None else bindings)
    for mask in range(1<<10):
        keys=bytearray(256)
        for i,n in enumerate(list(KEY_FIELDS)[:10]):keys[indices[n]]=1 if mask&(1<<i) else 0
        yield make(keys=keys)
    for field in KEY_FIELDS:
        for value in (0,1,2,0x80,0xff):
            keys=bytearray(256);keys[indices[field]]=value
            for mode in (0,1,0x80):yield make({'input_mode':mode},keys)
    for active in (0,1,2,3,0xff00,0xffff):
        for saved in (0,1,2,0xff00,0xffff):
            for primary in (0,1,2,0xffff):
                for secondary in (0,1,2,0xffff):
                    for alternate in (0,1,2):
                        yield make(dict(active_mouse_buttons=active,saved_mouse_buttons=saved,primary_button_latch=primary,secondary_button_latch=secondary,button_alternate=alternate,prior_action_word=rng.choice((0,0x2000,0xe000)),button_latch_disabled=rng.choice((0,0,1,0xffff))))
    for field in KEY_FIELDS:
        for index in range(256):
            if field not in ('key_action_11','key_latched_secondary') and index not in (0,87,255):continue
            bindings={**indices,field:index};keys=bytearray(256);keys[index]=1
            yield make({'active_mouse_buttons':1},keys,bindings)
            yield make({'primary_button_latch':1,'secondary_button_latch':1},keys,bindings)
    for brightness in (-32768,-2,-1,0,7,8,9,32767):
        for selection in (0,3,7,0x10003,0xffffffff):
            keys=bytearray(256);keys[87]=0xff;keys[indices['key_action_11']]=1
            yield make({'brightness':brightness,'selection':selection,'active_mouse_buttons':1},keys)
    for read in (0,1,2,62,63,64,127,254,255):
        for write in range(256):yield make({'input_mode':1,'key_fifo_read':read,'key_fifo_write':write})
    for level in (-2,7,32767):
        for read,write in ((62,0),(63,1),(255,63),(2,3),(127,127)):
            keys=bytearray(256);keys[87]=1
            yield make({'brightness':level,'input_mode':1,'key_fifo_read':read,'key_fifo_write':write},keys)


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
    for arg in ('exe','build','output'):parser.add_argument('--'+arg,type=Path,required=True)
    parser.add_argument('--asm',type=Path)
    args=parser.parse_args();exe=args.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    BASE,BEGIN,END,FIFO,CALL,STACK,STOP=0x2d51a,0x2de0c,0x2e133,0x2e101,0x59bee,0x3fef00,0x3fff00
    layout=group.ACTIONS_LAYOUT;ctx=layout['context'];public=ctx['public']
    _,original,placed,_,sites,_=bind_production(exe,args.build,stop=3097,asm=args.asm)
    assert original[:6]==bytes.fromhex('535152565755') and original[0xc12:]==bytes.fromhex('5d5f5e5a595bc3')
    blob=(args.build/(ctx['object']+'.obj')).read_bytes();code_fields={}
    private,data=v.bind_leaf_details(blob,public,layout['DATA'],address=BASE,functions={public:BASE,**layout['CODE']},code_bindings=code_fields)
    assert not code_fields and len(private)==3195 and len(data)==274
    assert layout['CODE']['setbrightness_']==CALL and layout['DATA']['_brightness_palette']==PALETTE
    assert all(layout['DATA']['_'+n]==address for n,(address,_) in FIELDS.items())
    assert all(layout['DATA']['_'+n]==address for n,address in KEY_FIELDS.items())
    old,new=decode(original),decode(private)
    expected=((0x8f2,0x901,0x956),(0x901,0x922,0x965),(0x924,0x937,0x98b),
              (0x937,0x9b3,0x99e),(0x9fc,0xa2b,0xa63),(0xa2b,0xa45,0xa94),
              (0xa45,0xa47,0xa92),(0xa47,0xa4c,0xaae),(0xaa8,0xae3,0xb11),
              (0xb2a,0xb4e,0xb95),(0xb4e,0xb62,0xbb9),(0xb64,0xb71,0xbcd),
              (0xb71,0xb9d,0xbda),(0xb9d,0xba8,0xc06),(0xba8,0xbad,0xc18),
              (0xbad,0xbb4,0xc11),(0xbb4,0xbde,0xc1d),(0xc13,0xc19,0xc75))
    def validate(candidate):
        assert candidate['selected_bytes']==514 and candidate['combined_selected_bytes']==1719 and candidate['assembly_size']==1378
        mapping={};owned=[];source_bytes=[]
        for row in candidate['instructions']:
            off=row['original']-BASE;source=row['private'];size=row['size']
            assert off not in mapping and old[off].size==new[source].size==size,'action instruction map'
            mapping[off]=source;owned.extend(range(off,off+size));source_bytes.extend(range(source,source+size))
            assert all(new[source].reg_name(op.mem.base)!='esp' and new[source].reg_name(op.mem.index)!='esp' for op in new[source].operands if op.type==CS_OP_MEM),'action private stack operand'
        assert owned==[i for lo,hi,_ in expected for i in range(lo,hi)],'action complete partition'
        assert len(set(source_bytes))==len(source_bytes)==514
        records={int(k):value for k,value in candidate['branches'].items()}
        entries={source:off for off,source in mapping.items()};entries.update({0xb70:0xb06,0xc47:0xbde})
        assert set(records)=={source for source in mapping.values() if branch(new[source]) is not None},'action branch inventory'
        calls=[]
        for off,source in mapping.items():
            ref,chosen=old[off],new[source];code=bytearray(chosen.bytes);target=branch(chosen)
            if chosen.group(CS_GRP_CALL):
                assert ref.group(CS_GRP_CALL) and chosen.imm_size==ref.imm_size==4
                destination=chosen.operands[0].imm+BASE
                assert destination==ref.operands[0].imm+BASE==CALL,'action CODE target'
                code[chosen.imm_offset:chosen.imm_offset+4]=(CALL-BASE-off-ref.size).to_bytes(4,'little',signed=True);calls.append(destination)
            elif target is not None:
                assert entries.get(target)==branch(ref),'action logical branch provenance'
                assert records[source]==[bytes(chosen.bytes[:chosen.imm_offset]).hex(),target,branch(ref)],'action branch metadata'
                assert (chosen.imm_offset,chosen.imm_size)==(ref.imm_offset,ref.imm_size)
                code[chosen.imm_offset:chosen.imm_offset+chosen.imm_size]=(branch(ref)-off-ref.size).to_bytes(chosen.imm_size,'little',signed=True)
            else:assert branch(ref) is None
            assert code==ref.bytes,'action selected instruction differs'
        assert calls==[CALL]
        phases=candidate['phases']
        assert [(p['address']-BASE,p['address']-BASE+p['end']-p['begin'],p['begin']) for p in phases]==list(expected),'action private operation provenance'
        phase_map={}
        for p in phases:
            assert p['public']==public
            for off,ins in decode(private[p['begin']:p['end']]).items():
                at=p['address']-BASE+off;assert at not in phase_map;phase_map[at]=p['begin']+off
        assert phase_map==mapping
        assert private[0xc72:0xc75]==bytes.fromhex('83c408') and private[0xc75:]==original[0xc13:],'borrowed return suffix'
        assert private[0x986:0x98b]==bytes.fromhex('25ff000000') and original[0x922:0x924]==bytes.fromhex('30e4')
        # The two normalizers differ only on dead flags; no flag consumer occurs
        # before SHL and OR redefine every subsequently observed status bit.
        for i in decode(original[0x924:0x937]).values():
            reads,_=i.regs_access();assert 'eflags' not in {i.reg_name(r) for r in reads},'normalizer live flags'
        assert original[0xb62:0xb64]==bytes.fromhex('31c0')
        returns=[off for off,i in old.items() if branch(i)==0xc12]
        assert len(returns)==2 and not any(0xc13<=branch(i)<0xc19 for i in old.values() if branch(i) is not None),'return entry edges'
        return mapping,returns
    mapping,return_edges=validate(layout)
    general=('eax','ebx','ecx','edx','esi','edi','ebp')
    reg={n:getattr(x,'UC_X86_REG_'+n.upper()) for n in (*general,'esp','eip','eflags')}
    saved_names=('ebp','edi','esi','edx','ecx','ebx')
    boundaries={BEGIN,*(p['address'] for p in layout['phases']),*(p['address']+p['end']-p['begin'] for p in layout['phases'])}
    boundaries.add(FIFO)
    def packed_keys(case,all_bits=False):
        result=(case.state['selection']<<13)&0xffff
        if not case.state['input_mode']:result|=(case.keys[case.indices['key_action_12']]==1)<<12
        sequence=(('key_action_0',0),('key_action_1',1),('key_action_4',4),('key_action_5',5),('key_run',8),('key_action_2',2),('key_action_3',3))
        if all_bits:sequence+= (('key_action_10',10),('key_action_11',11))
        for name,bit in sequence:
            value=case.keys[case.indices[name]]
            if bit in (10,11):value=int(value==1)
            result=(result|(value<<bit))&0xffff
        return result
    class Replay:
        def __init__(self,code):
            self.cpu=Uc(UC_ARCH_X86,UC_MODE_32);self.cpu.mem_map(0,0x410000)
            self.cpu.mem_write(DATA,b'\xa5'*0x28a300);self.cpu.mem_write(BASE,code);self.cpu.mem_write(CALL,b'\xc3');self.previous=set()
            self.cpu.hook_add(UC_HOOK_CODE,self.on_pc);self.cpu.hook_add(UC_HOOK_MEM_READ,self.on_read);self.cpu.hook_add(UC_HOOK_MEM_WRITE,self.on_write)
        def snapshot(self):
            values=self.cpu.reg_read_batch([reg[n] for n in (*general,'esp','eflags')])
            return tuple(values[:-1])+(values[-1]&0x8c5,)
        def on_write(self,cpu,access,address,size,value,user):
            if address==STACK-4:assert size==4;self.call_returns.append(value);return
            assert DATA<=address and address+size<=DATA+0x28a300,'tail DATA/frame write extent'
            self.writes.append((address,size,value))
            if address==DATA+FIELDS['key_fifo_read'][0]:self.steps+=1
        def on_read(self,cpu,access,address,size,value,user):
            if address in (DATA+FIELDS['key_fifo_read'][0],DATA+FIELDS['key_fifo_write'][0]):assert size==1;self.reads.append(address)
            if STACK<=address<STACK+28:assert size==4;self.frame_reads.append(address)
        def on_pc(self,cpu,pc,size,user):
            if pc==CALL:
                assert cpu.reg_read(reg['esp'])==STACK-4
                self.calls.append((signed(cpu.reg_read(reg['eax']),32),cpu.reg_read(reg['edx'])))
                for i,n in enumerate(('eax','ebx','ecx','edx','esi','edi')):cpu.reg_write(reg[n],(0xfedc8123+i*0x111)^self.poison)
                cpu.reg_write(reg['eflags'],0xa97);return
            assert BEGIN<=pc and pc+size<=END,'tail execution extent'
            if pc in boundaries:self.boundaries.append((pc,self.snapshot()))
            if pc==BASE+0x922:
                assert cpu.reg_read(reg['eax']) in (0,1),'mode Boolean EAX bridge';self.contracts.add('mode_boolean_EAX')
            if pc==BASE+0x9b3:
                assert cpu.reg_read(reg['eax'])==self.case.indices['key_run'],'run binding EAX bridge';self.contracts.add('run_binding_EAX')
            if pc==BASE+0x9fc:
                assert cpu.reg_read(reg['edi'])&0xffff==packed_keys(self.case),'packed DI bridge';self.contracts.add('packed_DI')
            if pc==BASE+0xa4c:
                assert cpu.reg_read(reg['ebx'])&0xffff==packed_keys(self.case,True),'packed BX bridge';self.contracts.add('packed_BX')
            if pc==BASE+0xaa8:
                assert cpu.reg_read(reg['esi'])&0xffff==0,'disabled SI bridge';self.contracts.add('disabled_SI')
            if pc==BASE+0xb64:
                assert cpu.reg_read(reg['eax'])==0,'secondary EAX bridge';self.contracts.add('secondary_EAX')
            if pc==BASE+0xc13:
                assert cpu.reg_read(reg['ebp'])==self.saved['ebp'] and cpu.reg_read(reg['esp'])==STACK+4,'borrowed five-word frame'
                self.contracts.add('return_frame')
            if pc==FIFO and self.steps==64:self.cycle=True;cpu.emu_stop()
        def run(self,case,poison=0,verify_reads=True,oracle=None):
            self.case=case;self.poison=poison;cpu=self.cpu;initial=Memory(case).initial
            for address,size in self.previous:cpu.mem_write(address,b'\xa5'*size)
            runs=[]
            for address in sorted(initial):
                if not runs or address!=runs[-1][0]+len(runs[-1][1]):runs.append((address,bytearray()))
                runs[-1][1].append(initial[address])
            for address,content in runs:cpu.mem_write(DATA+address,bytes(content))
            for i,n in enumerate(general):cpu.reg_write(reg[n],(0x81a3b5c7+i)^poison)
            self.saved={n:(0xc0111111+i*0x111111)^poison for i,n in enumerate(saved_names)}
            frame=b''.join(struct.pack('<I',v) for v in self.saved.values())+struct.pack('<I',STOP)
            cpu.mem_write(STACK-64,b'\x5a'*128);cpu.mem_write(STACK,frame);cpu.reg_write(reg['esp'],STACK);cpu.reg_write(reg['eflags'],0x202)
            self.writes=[];self.reads=[];self.calls=[];self.frame_reads=[];self.call_returns=[];self.boundaries=[];self.contracts=set();self.steps=0;self.cycle=False
            cpu.emu_start(BEGIN,STOP,count=5000);expected_model=oracle if oracle is not None else model(case)
            assert self.writes==expected_model.writes,'tail ordered writes'
            if verify_reads:assert self.reads==expected_model.fifo_reads,'FIFO volatile read observations'
            assert self.calls==expected_model.calls,'brightness call arguments'
            assert self.cycle==(not expected_model.terminates) and self.steps==expected_model.steps,'FIFO termination model'
            assert cpu.reg_read(reg['eip'])==(FIFO if self.cycle else STOP) and cpu.reg_read(reg['esp'])==(STACK if self.cycle else STACK+28),'tail return/cycle PC and ESP'
            assert self.frame_reads==([] if self.cycle else list(range(STACK,STACK+28,4))),'six-word return reads'
            assert self.call_returns==([0x2e0f8] if self.calls else [])
            if not self.cycle:assert all(cpu.reg_read(reg[n])==value for n,value in self.saved.items()),'saved register frame'
            assert cpu.mem_read(STACK,28)==frame and cpu.mem_read(STACK-64,60)==b'\x5a'*60 and cpu.mem_read(STACK+28,36)==b'\x5a'*36,'protected caller frame'
            for address,size,_ in self.writes:assert bytes(cpu.mem_read(address,size))==bytes(expected_model.bytes.get(address-DATA+i,0xa5) for i in range(size)),'tail final DATA'
            assert bytes(cpu.mem_read(DATA+KEYS,256))==bytes(expected_model.bytes[KEYS+i] for i in range(256)),'tail complete key array'
            self.previous={(address,size) for address,size,_ in self.writes}
            return tuple(self.writes),tuple(self.calls),tuple(self.reads),tuple(self.boundaries),self.snapshot(),self.cycle
    orig=Replay(relocated(original,sites));production=Replay(relocated(placed,sites));all_cases=list(cases())
    contracts=set();cycles=0
    for case in all_cases:
        m=model(case)
        for poison in (0,0xffffffff):
            assert orig.run(case,poison,oracle=m)==production.run(case,poison,oracle=m),'tail original/placed state'
            contracts.update(production.contracts)
            read,write=case.state['key_fifo_read'],case.state['key_fifo_write']
            reachable=not case.state['input_mode'] or read==write or (write<64 and (read&1)==(write&1))
            assert m.terminates==reachable and (m.steps<=32 if reachable else m.steps==64),'FIFO independent reachability'
            if not reachable:
                fifo_values=[value for address,_,value in m.writes if address==DATA+FIELDS['key_fifo_read'][0]]
                assert fifo_values[:32]==fifo_values[32:],'FIFO repeated parity cycle'
                cycles+=1
    assert len(all_cases)==6066 and cycles==4030
    assert contracts=={'mode_boolean_EAX','run_binding_EAX','packed_DI','packed_BX','disabled_SI','secondary_EAX','return_frame'}
    controls=[]
    def reject(label,fn,expected_message=None):
        try:fn()
        except (AssertionError,ValueError,KeyError,StopIteration) as error:
            if expected_message is not None:assert expected_message in str(error),str(error)
            controls.append(label)
        else:raise AssertionError('Action mutation escaped: '+label)
    for label,change in (('missing_instruction',lambda l:l['instructions'].pop()),('partial_return',lambda l:l['phases'][-1].update(end=3194)),('missing_branch',lambda l:l['branches'].pop(next(iter(l['branches']))))):
        changed=deepcopy(layout);change(changed);reject(label,lambda:validate(changed))
    changed=deepcopy(layout);row=next(r for r in changed['instructions'] if r['private']==2845);row['private']=0xc5e
    changed['branches'].pop('2845');changed['branches'][str(0xc5e)]=['74',0xc72,2749]
    reject('wrong_condition_substitution',lambda:validate(changed),'logical branch provenance')
    base=all_cases[0];keys=bytearray(256);keys[base.indices['key_action_12']]=1
    sample=replace(base,keys=bytes(keys))
    bad=bytearray(placed);bad[0x922+1]=0xc0
    reject('Boolean_normalizer_value',lambda:Replay(relocated(bytes(bad),sites)).run(sample))
    keys=bytearray(256);keys[87]=1
    sample=replace(base,state={**base.state,'brightness':0xfffe},keys=bytes(keys))
    load=next(i for off,i in old.items() if 0xbb4<=off<0xbde and i.mnemonic=='movsx' and any(op.type==CS_OP_MEM for op in i.operands))
    bad=bytearray(placed);bad[load.address+1]=0xb7
    reject('unsigned_brightness_argument',lambda:Replay(relocated(bytes(bad),sites)).run(sample),'brightness call arguments')
    bad=bytearray(placed);bad[0xc17]=0x58
    reject('wrong_return_register',lambda:Replay(relocated(bytes(bad),sites)).run(base),'saved register frame')
    sample=replace(base,state={**base.state,'input_mode':1,'key_fifo_read':62,'key_fifo_write':0})
    read_ins=next(i for off,i in old.items() if off>FIFO-BASE+8 and i.mnemonic=='mov' and i.op_str.startswith('al, byte ptr [0x7f87b]'))
    bad=bytearray(placed);bad[read_ins.address:read_ins.address+read_ins.size]=b'\x90'*read_ins.size
    reduced=dict(sites);reduced.pop(read_ins.address+read_ins.disp_offset)
    changed=Replay(relocated(bytes(bad),reduced));correct=orig.run(sample);actual=changed.run(sample,verify_reads=False)
    assert correct[:2]==actual[:2] and correct[3:]==actual[3:] and correct[2]!=actual[2],'read-observation-only counterexample'
    reject('omitted_FIFO_observation',lambda:changed.run(sample),'FIFO volatile read observations')
    from check_encounter_actor import rewrite_fixup
    from check_ripple_stack import mutate_public_byte
    from dataclasses import replace as fixup_replace
    _,_,external,_,fixups=v.parsed_leaf_object(blob)
    brightness_call=next(f for f in fixups if f.target[0]==2 and external[f.target[1]]=='setbrightness_')
    palette=next(f for f in fixups if f.target[0]==2 and external[f.target[1]]=='_brightness_palette')
    assert brightness_call.relative and not palette.relative and brightness_call.frame==palette.frame==(1,2)
    phase=layout['phases'][0]
    def bind(b):return v.bind_leaf_details(b,phase['symbol'],layout['DATA'],address=phase['address'],functions={public:BASE,**layout['CODE']},code_bindings={})
    for label,offset in (('excluded_normalizer',0x986),('private_stack_adjust',0xc72),('C_return_opcode',0xc7a)):
        reject(label,lambda:bind(mutate_public_byte(blob,public,offset)),'complete context digest')
    other=next(i for i,n in enumerate(external) if n=='_key_state')
    for label,change in (('call_DATA_target',lambda f:fixup_replace(f,target=(2,other))),('call_absolute',lambda f:fixup_replace(f,relative=False)),('call_frame',lambda f:fixup_replace(f,frame=(1,1)))):
        bad,changed=rewrite_fixup(blob,lambda f:f.offset==brightness_call.offset,change);assert changed
        reject(label,lambda:bind(bad),'fixup records')
    digest=group.ACTIONS_CONTEXT_SHA256;leaf=v.LEAF_CONTEXT_SHA256.pop(public);group.ACTIONS_CONTEXT_SHA256=None
    try:reject('call_addend_without_digests',lambda:bind(mutate_public_byte(blob,public,brightness_call.offset)),'fixup addends')
    finally:group.ACTIONS_CONTEXT_SHA256=digest;v.LEAF_CONTEXT_SHA256[public]=leaf
    report=dict(status='PASS',new_native_bytes=514,new_DATA_sites=52,relative_CODE_calls=1,operations=10,cases=len(all_cases),poison_seeds=2,terminating_cases_per_seed=4051,cyclic_cases_per_seed=2015,
                live_contracts=sorted(contracts),return_edges=[hex(BASE+x) for x in return_edges],controls=controls,
                scope='Independent original/placed action packing, latch aliases, wrapped signed brightness and FIFO-read/write model. Brightness stub checks typed arguments and stresses all six allowed register clobbers; no palette hardware I/O modeled. Real six-save frame and borrowed five-pop/RET suffix verified through return sentinel; malformed stable FIFO states are checked for 64 updates and repeated 32-step cycles, not normalized or claimed terminating. All phase-boundary GPRs and masked arithmetic flags, DATA writes and protected frame agree. No whole private-function ABI substitution or asynchronous producer model.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()
