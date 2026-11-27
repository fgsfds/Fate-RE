"""Independent stable-memory model of polling and packing local motion.

Mouse polling and scaling are stubbed contracts, not BIOS/x87 emulation.
"""
from dataclasses import dataclass,replace
from random import Random

def u32(v):return v&0xffffffff
def s32(v):return (v&0x7fffffff)-(v&0x80000000)
def clamp(v,lo,hi):return min(max(s32(v),lo),hi)

@dataclass(frozen=True)
class Case:
    keys:bytes
    indices:tuple  # forward, backward, strafe_left, strafe_right
    forward:int
    strafe:int
    turn:int
    step:int
    limit:int
    active_buttons:int
    raw_mouse:tuple
    scaled_mouse:tuple
    cursor:int

def model(case):
    forward,strafe,turn=map(u32,(case.forward,case.strafe,case.turn))
    f,b,l,r=case.indices
    writes=[('mouse_buttons',2,0)]
    if case.keys[f] or case.active_buttons&2:
        forward=u32(min(s32(forward+12),127));writes.append(('keyboard_forward',4,forward))
    if case.keys[b]:
        forward=u32(max(s32(forward-12),-128));writes.append(('keyboard_forward',4,forward))
    if case.keys[l]:
        strafe=u32(min(s32(strafe+3*case.step),s32(case.limit)));writes.append(('keyboard_strafe',4,strafe))
    if case.keys[r]:
        strafe=u32(max(s32(strafe-3*case.step),s32(-case.limit)));writes.append(('keyboard_strafe',4,strafe))
    values={'keyboard_turn':turn,'keyboard_strafe':strafe,'keyboard_forward':forward}
    for name,amount in (('keyboard_turn',36),('keyboard_strafe',6),('keyboard_forward',6)):
        if s32(values[name])<0:
            values[name]=u32(min(s32(values[name]+amount),0));writes.append((name,4,values[name]))
        if s32(values[name])>0:
            values[name]=u32(max(s32(values[name]-amount),0));writes.append((name,4,values[name]))
    packed=(clamp(values['keyboard_forward'],-120,119)&255,
            clamp(values['keyboard_strafe'],-120,119)&255,
            clamp(values['keyboard_turn'],-112,111)&255)
    writes.extend((name,1,value) for name,value in zip(('input_forward','input_strafe','input_turn'),packed))
    memory=(values['keyboard_forward'],values['keyboard_strafe'],values['keyboard_turn'],packed,
            tuple(v&0xffff for v in (*case.scaled_mouse,case.raw_mouse[2])))
    return memory,tuple(writes)

def cases():
    rng=Random(0x2d7d5)
    bounds=(-2147483648,-177,-176,-129,-128,-127,-121,-120,-119,-113,-112,-111,
            -37,-36,-35,-7,-6,-5,-1,0,1,5,6,7,35,36,37,110,111,112,118,119,120,126,127,128,175,176,2147483647,0xffffffff)
    base=Case(bytes(256),(240,241,242,243),0,0,0,1,127,0,(-32768,32767,0x8234),(123,-456),0x80)
    for mask in range(16):
        keys=bytearray(256)
        for i,index in enumerate(base.indices):keys[index]=255 if mask&(1<<i) else 0
        for field in ('forward','strafe','turn'):
            for value in bounds:
                yield replace(base,keys=bytes(keys),**{field:value})
        for step in bounds:
            for limit in (-2147483648,-128,0,127,2147483647):
                yield replace(base,keys=bytes(keys),forward=rng.choice(bounds),strafe=rng.choice(bounds),turn=rng.choice(bounds),step=step,limit=limit)
    for active in (0,1,2,3,128,255,256,0xff00,0xffff):
        for value in bounds:yield replace(base,active_buttons=active,forward=value)
    for index in range(256):
        yield replace(base,indices=(index,)*4,keys=bytes([1])*256,forward=rng.choice(bounds),strafe=rng.choice(bounds),turn=rng.choice(bounds))
    for a in range(4):
        for b in range(a+1,4):
            indices=list(base.indices);indices[b]=indices[a]
            for value in (0,1,2,128,255):yield replace(base,indices=tuple(indices),keys=bytes([value])*256)


def main():
    import argparse,hashlib,json
    from copy import deepcopy
    from pathlib import Path
    from struct import pack
    from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE,UC_HOOK_MEM_WRITE
    from unicorn import x86_const as x
    from capstone import CS_GRP_CALL
    from compare_exe import TARGET_SHA256
    from check_input_selection import bind_production,validate_layout,relocated,decode,branch,functions
    import bind_input_selection as group
    import verify_c_leaf as v

    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True)
    parser.add_argument('--build',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--asm',type=Path)
    args=parser.parse_args();exe=args.exe.read_bytes()
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    START,POLL,END,STACK=0x2d51a,0x2d7d5,0x2da09,0x200000
    GET,SCALE=0x54424,0x3a96d
    blob,original,placed,private,sites,private_sites=bind_production(exe,args.build,stop=0x4ef,asm=args.asm)
    validate_layout(group.LAYOUT,original,private)
    ranges=((699,743,701,745),(797,836,801,840),(995,1043,1014,1062))
    old,new=decode(original),decode(private)

    def validate(layout):
        assert layout['CODE']=={'getmousevalues_':GET,'scale_mouse_':SCALE},'mouse call targets'
        assert layout['selected_bytes']==817 and layout['assembly_size']==1326
        records={int(k):value for k,value in layout['branches'].items()}
        selected=[r for r in layout['instructions'] if r['original']>=POLL]
        mapping={};owned=[];sources=[]
        for row in selected:
            off=row['original']-START;source=row['private'];size=row['size']
            assert off not in mapping and old[off].size==new[source].size==size,'mouse instruction map'
            mapping[off]=source;owned.extend(range(off,off+size));sources.extend(range(source,source+size))
        assert owned==[a for lo,hi,_,_ in ranges for a in range(lo,hi)],'mouse original partition'
        assert sources==[a for _,_,lo,hi in ranges for a in range(lo,hi)],'mouse private partition'
        entries={source:off for off,source in mapping.items()}
        entries.update({hi:old_hi for _,old_hi,_,hi in ranges})
        selected_branches={source for source in mapping.values() if branch(new[source]) is not None}
        assert {site for site in records if site>=701}==selected_branches,'mouse selected branch set'
        calls=[]
        for off,source in mapping.items():
            ref,chosen=old[off],new[source];code=bytearray(chosen.bytes)
            target=branch(chosen)
            if chosen.group(CS_GRP_CALL):
                assert ref.group(CS_GRP_CALL) and chosen.imm_size==ref.imm_size==4
                target=chosen.operands[0].imm+START
                assert target==ref.operands[0].imm+START and target in (GET,SCALE),'mouse CODE call target'
                code[chosen.imm_offset:chosen.imm_offset+4]=(target-START-off-ref.size).to_bytes(4,'little',signed=True)
                calls.append(target)
            elif target is not None:
                assert entries[target]==branch(ref),'mouse logical branch target'
                assert records[source]==[bytes(chosen.bytes[:chosen.imm_offset]).hex(),target,branch(ref)],'mouse branch metadata'
                assert (chosen.imm_offset,chosen.imm_size)==(ref.imm_offset,ref.imm_size)
                code[chosen.imm_offset:chosen.imm_offset+chosen.imm_size]=(branch(ref)-off-ref.size).to_bytes(chosen.imm_size,'little',signed=True)
            else:assert branch(ref) is None and not ref.group(CS_GRP_CALL)
            assert code==ref.bytes,'mouse selected instruction differs'
        assert calls==[GET,SCALE]
        phases=[p for p in layout['phases'] if p['address']>=POLL]
        assert [(p['address']-START,p['address']-START+p['end']-p['begin'],p['begin'],p['end']) for p in phases]==list(ranges),'mouse phase partition'
        assert all(p['public']==layout['context']['public'] for p in phases)
        return phases,selected_branches

    phases,selected_branches=validate(group.LAYOUT)
    offsets={'key_forward':0x1363d,'key_backward':0x1363e,'key_strafe_left':0x1364a,'key_strafe_right':0x1364b,
             'keyboard_forward':0x770e8,'keyboard_strafe':0x770e4,'keyboard_turn':0x770ec,
             'strafe_step':0x13ba3,'strafe_limit':0x13b9f,'mouse_dx':0x7deda,'mouse_dy':0x7dedc,
             'mouse_buttons':0x7dee2,'active_mouse_buttons':0x85290,'cursor_mode':0x3be5,
             'input_forward':0x7def9,'input_strafe':0x7defa,'input_turn':0x7defb,'key_state':0x6793c}
    names={n:0x80000+address for n,address in offsets.items()}
    assert all(group.LAYOUT['DATA']['_'+n]==a for n,a in offsets.items() if n!='cursor_mode'),'mouse model DATA bindings'
    general=('eax','ebx','ecx','edx','esi','edi','ebp')
    reg={n:getattr(x,'UC_X86_REG_'+n.upper()) for n in (*general,'esp','eip','eflags')}
    accumulators=('keyboard_forward','keyboard_strafe','keyboard_turn')
    packed=('input_forward','input_strafe','input_turn');mouse=('mouse_dx','mouse_dy','mouse_buttons')
    fields=('mouse_buttons',*accumulators,*packed)

    class Replay:
        def __init__(self,code,private=False):
            self.begin=START+701 if private else POLL
            self.end=START+1294 if private else END
            self.returns=[START+730,START+745] if private else [START+728,START+743]
            self.cpu=Uc(UC_ARCH_X86,UC_MODE_32);self.cpu.mem_map(0,0x210000)
            self.cpu.mem_write(START,code)
            for target in (GET,SCALE):self.cpu.mem_write(target,b'\xc3')
            self.cpu.hook_add(UC_HOOK_CODE,self.on_pc);self.cpu.hook_add(UC_HOOK_MEM_WRITE,self.on_write)

        def read(self,n,width):return int.from_bytes(self.cpu.mem_read(names[n],width),'little')

        def on_write(self,cpu,access,address,size,value,user):
            if address==STACK-4:
                assert size==4;self.stack_writes.append(value);return
            field=next(n for n in fields if names[n]==address)
            assert size==(2 if field=='mouse_buttons' else 1 if field in packed else 4)
            self.writes.append((field,size,value))

        def on_pc(self,cpu,pc,size,user):
            if pc not in (GET,SCALE):
                assert self.begin<=pc and pc+size<=self.end,'mouse execution extent'
                self.path.append(pc-START);return
            assert cpu.reg_read(reg['esp'])==STACK-4
            args=tuple(cpu.reg_read(reg[n]) for n in ('eax','edx','ebx'))
            assert args[:2]==(names['mouse_dx'],names['mouse_dy']),'mouse pointer arguments'
            if pc==GET:
                assert not self.calls and args[2]==names['mouse_buttons']
                assert self.read('mouse_buttons',2)==0,'mouse initial clear'
                for n,value in zip(mouse,self.case.raw_mouse):cpu.mem_write(names[n],pack('<H',value&0xffff))
            else:
                assert [row[0] for row in self.calls]==[GET],'mouse call order'
                assert tuple(self.read(n,2) for n in mouse)==tuple(v&0xffff for v in self.case.raw_mouse)
                for n,value in zip(mouse,self.case.scaled_mouse):cpu.mem_write(names[n],pack('<H',value&0xffff))
            self.calls.append((pc,args[:3] if pc==GET else args[:2]))
            for i,n in enumerate(general[:4]):cpu.reg_write(reg[n],(0xfedc8123+i*0x111)^self.poison)
            cpu.reg_write(reg['eflags'],0xa97)

        def run(self,case,poison=0):
            self.case=case;self.poison=poison;cpu=self.cpu
            self.writes=[];self.calls=[];self.stack_writes=[];self.path=[]
            cpu.mem_write(names['key_state'],case.keys)
            for n,value in zip(('key_forward','key_backward','key_strafe_left','key_strafe_right'),case.indices):cpu.mem_write(names[n],bytes([value]))
            for n,value in zip((*accumulators,'strafe_step','strafe_limit'),(case.forward,case.strafe,case.turn,case.step,case.limit)):cpu.mem_write(names[n],pack('<I',u32(value)))
            cpu.mem_write(names['active_mouse_buttons'],pack('<H',case.active_buttons));cpu.mem_write(names['cursor_mode'],bytes([case.cursor]))
            for n in mouse:cpu.mem_write(names[n],b'\xa5\x5a')
            for n in packed:cpu.mem_write(names[n],b'\xa5')
            for i,n in enumerate(general):cpu.reg_write(reg[n],(0x81a3b5c7+i)^poison)
            cpu.mem_write(STACK-64,b'\xa5'*128);cpu.reg_write(reg['esp'],STACK);cpu.reg_write(reg['eflags'],0x202)
            cpu.emu_start(self.begin,self.end,count=220)
            assert cpu.reg_read(reg['eip'])==self.end and cpu.reg_read(reg['esp'])==STACK
            assert cpu.mem_read(STACK-64,60)==b'\xa5'*60 and cpu.mem_read(STACK,64)==b'\xa5'*64,'mouse stack guards'
            assert [row[0] for row in self.calls]==[GET,SCALE] and self.stack_writes==self.returns
            assert cpu.mem_read(names['key_state'],256)==case.keys
            memory=(*(self.read(n,4) for n in accumulators),tuple(self.read(n,1) for n in packed),tuple(self.read(n,2) for n in mouse))
            return (memory,tuple(self.writes),tuple(self.calls)),tuple(cpu.reg_read(reg[n]) for n in general),cpu.reg_read(reg['eflags'])&0x8c5

    orig=Replay(relocated(original,sites));production=Replay(relocated(placed,sites));natural=Replay(relocated(private,private_sites),private=True)
    all_cases=list(cases());outcomes={old_off:set() for lo,hi,_,_ in ranges for old_off,i in old.items() if lo<=old_off<hi and branch(i) is not None}
    reg_differences=flag_differences=0
    for poison in (0,0xffffffff):
        for case in all_cases:
            expected=orig.run(case,poison);actual=production.run(case,poison);compiled=natural.run(case,poison)
            assert expected==actual and expected[0][:2]==model(case),'mouse original/placed model'
            assert compiled[0]==expected[0],'mouse full private DATA/write/call model'
            reg_differences+=compiled[1]!=expected[1];flag_differences+=compiled[2]!=expected[2]
            for here,next_pc in zip(orig.path,orig.path[1:]+[END-START]):
                if here in outcomes:
                    taken=next_pc==branch(old[here]);assert taken or next_pc==here+old[here].size
                    outcomes[here].add(taken)
    assert len(all_cases)==5766 and len(outcomes)==6 and all(v=={False,True} for v in outcomes.values())

    controls=[]
    def reject(label,fn,expected=None):
        try:fn()
        except (AssertionError,ValueError,KeyError,StopIteration) as error:
            if expected is not None:assert expected in str(error),str(error)
            controls.append(label)
        else:raise AssertionError('Mouse mutation escaped: '+label)
    for label,change in (
        ('omitted_mouse_instruction',lambda l:l['instructions'].pop()),
        ('partial_mouse_phase',lambda l:l['phases'][-1].update(end=l['phases'][-1]['end']-1)),
        ('missing_mouse_branch',lambda l:l['branches'].pop(str(min(selected_branches)))),
        ('wrong_CODE_target',lambda l:l['CODE'].update(getmousevalues_=GET+1))):
        changed=deepcopy(group.LAYOUT);change(changed);reject(label,lambda:validate(changed))

    def run_bad(code):
        replay=Replay(relocated(bytes(code),sites))
        for case in all_cases:
            try:actual=replay.run(case)
            except (AssertionError,StopIteration):return
            if actual[0][:2]!=model(case):return
        raise ValueError('mutation matched all modeled cases')
    def rejects_behavior(label,code):
        # An escaped mutation raises; an observed counterexample returns.
        run_bad(code);controls.append(label)
    call=next(i for i in old.values() if i.group(CS_GRP_CALL))
    for label,target in (('wrong_callee_entry',GET+1),('reversed_mouse_calls',SCALE)):
        bad=bytearray(placed);bad[call.address+call.imm_offset:call.address+call.imm_offset+4]=(target-START-call.address-call.size).to_bytes(4,'little',signed=True)
        rejects_behavior(label,bad)
    back=next(i for off,i in old.items() if 797<=off<836 and i.mnemonic=='jg')
    bad=bytearray(placed);bad[back.address]=0x77;rejects_behavior('unsigned_backward_clamp',bad)
    decay=next(i for off,i in old.items() if 995<=off<1043 and i.mnemonic=='lea')
    bad=bytearray(placed);bad[decay.address+decay.disp_offset]=7;rejects_behavior('strafe_decay_step',bad)

    from check_encounter_actor import rewrite_fixup
    from check_ripple_stack import mutate_public_byte
    from check_ripple_control import rename_external
    from dataclasses import replace as fixup_replace
    _,_,external,_,fixups=v.parsed_leaf_object(blob)
    calls=[f for f in fixups if f.target[0]==2 and external[f.target[1]] in group.LAYOUT['CODE']]
    assert len(calls)==2 and all(f.relative and f.width==4 and f.location==9 and f.frame==(1,2) and f.displacement==0 for f in calls),'mouse CODE fixup forms'
    data_target=next(n for n,name in enumerate(external) if name=='_mouse_dx')
    phase=phases[0]
    def bind(b):return v.bind_leaf_details(b,phase['symbol'],group.LAYOUT['DATA'],address=phase['address'],functions=functions(),code_bindings={})
    for label,change in (
        ('CODE_as_DATA_target',lambda f:fixup_replace(f,target=(2,data_target))),
        ('absolute_CODE_call',lambda f:fixup_replace(f,relative=False)),
        ('CODE_frame',lambda f:fixup_replace(f,frame=(1,1))),
        ('CODE_displacement',lambda f:fixup_replace(f,displacement=1))):
        bad,changed=rewrite_fixup(blob,lambda f:f.offset==calls[0].offset,change);assert changed
        reject(label,lambda:bind(bad),'fixup records')
    reject('CODE_external_name',lambda:bind(rename_external(blob,b'getmousevalues_',b'getmousevaluex_')),'structural OMF metadata')
    digest=group.CONTEXT_SHA256;leaf=v.LEAF_CONTEXT_SHA256.pop(group.PUBLIC);group.CONTEXT_SHA256=None
    try:reject('CODE_addend_without_digests',lambda:bind(mutate_public_byte(blob,group.PUBLIC,calls[0].offset)),'fixup addends')
    finally:group.CONTEXT_SHA256=digest;v.LEAF_CONTEXT_SHA256[group.PUBLIC]=leaf
    report=dict(status='PASS',new_native_bytes=131,new_DATA_sites=14,relative_CODE_calls=2,cases=len(all_cases),poison_seeds=2,
                selected_branches=6,branch_outcomes={hex(START+k):sorted(v) for k,v in outcomes.items()},controls=controls,
                private_register_difference_cases=reg_differences,private_flag_difference_cases=flag_differences,
                scope='Original and placed polling/movement/decay/packing agree on modeled DATA, ordered writes/calls, all GPRs, flags and checked call-return stack. Full private post-poll C matches DATA/write/call model; its raw registers/flags are diagnostic. Mouse BIOS and x87 scaling are stubbed with checked pointer arguments and outputs. Stable memory; no interrupt interleavings, cursor/map continuation or complete input-routine C replacement claimed.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()
