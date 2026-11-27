"""Prove complete destination assignments whose address calculation was hoisted."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
from capstone import Cs,CS_ARCH_X86,CS_MODE_32,CS_OP_MEM,CS_OP_REG,CS_OP_IMM,CS_GRP_JUMP,CS_GRP_CALL
from capstone.x86_const import X86_REG_EDX,X86_REG_AX
import bind_board_actor as group
import verify_c_leaf as v
import check_board_actor_groups as base
from check_board_actor_indexed import live,model,context_controls,NAMES,watcher as original_watcher
from check_start_hook import image,DS
from compare_exe import TARGET_SHA256

SEEDS=(0,1,2,7,0x7fff,0xffff,0x8000,0xffffffff,0xdeadbeef,0x80000000,0x12345678,0x55aa55aa,0xaa55aa55,0x01010101,0xfefefefe)
MD=Cs(CS_ARCH_X86,CS_MODE_32);MD.detail=True


def decode(code):
    result=list(MD.disasm(bytes(code),0))
    assert sum(i.size for i in result)==len(code),'fragment instruction boundary'
    return result


def independent_store(code):
    """A MOVSX EDX,AX can move past a register-to-memory store with no EDX use."""
    instructions=decode(code);assert len(instructions)==1,'fragment gap instruction count'
    ins=instructions[0]
    assert ins.mnemonic=='mov' and len(ins.operands)==2,'fragment gap is not a store'
    dest,src=ins.operands
    assert dest.type==CS_OP_MEM and src.type==CS_OP_REG,'fragment gap memory effects'
    reads,writes=ins.regs_access()
    assert not writes and not ins.eflags,'fragment gap register/flag writes'
    # Include all partial-register aliases, including the effective address.
    assert not {'edx','dx','dh','dl'} & {ins.reg_name(r) for r in reads},'fragment gap depends on EDX'
    assert dest.size==src.size==2 and dest.mem.disp==DS+0x78a40 and not dest.mem.index and dest.mem.scale==1,'fragment gap field'
    return ins


def validate(layout,natural,original):
    assert layout['context_file']=='board-actor-value-layout.json','fragment context'
    assert [o['slot'] for o in layout['operations']]==[104,105],'fragment operation slots'
    expected=[];private_regions=[]
    for number,op in enumerate(layout['operations']):
        assert op['operation']=='actor_destinations.x' and op['fields']==['actor_destinations.x'],'fragment operation fields'
        assert op['original_end']-op['original_start']==14,'fragment operation extent'
        assert op['writes']==[[8,0x729fc+16*op['slot'],4,0]],'fragment store metadata'
        assert op['live_in_bitmasks']=={'eax':0xffff} and op['live_in_values']=={'eax':op['slot']},'fragment entry metadata'
        assert op['native_suffix_live_in_bitmasks']=={'edx':0xffffffff} and op['native_suffix_live_in_values']=={'edx':op['slot']},'fragment suffix metadata'
        first,last=op['fragments'];gap=op['omitted_store']
        assert first['end']-first['begin']==3 and last['end']-last['begin']==11,'fragment partition'
        assert (first['address'],last['address'])==(op['original_start'],op['original_start']+3),'fragment original partition'
        assert (gap['begin'],gap['end'])==(first['end'],last['begin']),'fragment gap partition'
        assert gap['field']=='actor_waypoints.first' and gap['slot']==op['slot'],'fragment gap metadata'
        assert natural[first['begin']:first['end']]==bytes.fromhex('0fbfd0'),'fragment address calculation'
        independent_store(natural[gap['begin']:gap['end']])
        code=b''.join(natural[f['begin']:f['end']] for f in op['fragments'])
        assert code==original[op['original_start']:op['original_end']],'fragment original bytes'
        ins=decode(code);assert [i.mnemonic for i in ins]==['movsx','shl','xor','mov'],'fragment complete assignment'
        assert ins[0].operands[0].reg==X86_REG_EDX and ins[0].operands[1].reg==X86_REG_AX
        assert ins[1].operands[0].reg==X86_REG_EDX and ins[1].operands[1].type==CS_OP_IMM and ins[1].operands[1].imm==4
        zero=ins[2].operands
        assert zero[0].type==zero[1].type==CS_OP_REG and zero[0].reg==zero[1].reg and zero[0].size==4,'fragment zero preparation'
        store=ins[3].operands
        assert ins[3].address==8 and store[0].type==CS_OP_MEM and store[0].size==4 and store[1].reg==zero[0].reg,'fragment destination store'
        assert store[0].mem.base==X86_REG_EDX and not store[0].mem.index and store[0].mem.disp==DS+0x729fc,'fragment destination field'
        for part,f in enumerate(op['fragments']):
            assert 0<=f['begin']<f['end']<=len(natural),'fragment source bounds'
            expected.append(dict(symbol=f'board_actor_fragment_{number:03}_{part}_',public=layout['context']['public'],**f))
            region=set(range(f['begin'],f['end']));assert all(not region&r for r in private_regions),'fragment source overlap'
            private_regions.append(region)
            assert not any(f['begin']<p['end'] and p['begin']<f['end'] for p in group.VALUE_LAYOUT['phases']),'fragment previous source overlap'
        assert not any(gap['begin']<p['end'] and p['begin']<gap['end'] for p in group.VALUE_LAYOUT['phases']),'fragment gap selected previously'
    assert layout['phases']==expected,'fragment placement metadata'
    # The complete constructor has no calls and no branch into a moved interval.
    regions=[(o['fragments'][0]['begin'],o['fragments'][1]['end']) for o in layout['operations']]
    for ins in decode(natural):
        assert not ins.group(CS_GRP_CALL),'fragment constructor call'
        if ins.group(CS_GRP_JUMP):
            assert ins.operands[0].type==CS_OP_IMM,'fragment indirect branch'
            assert not any(a<=ins.operands[0].imm<b for a,b in regions),'fragment incoming branch'


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();exe=args.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    original=image(exe);_,body,_=base.bind_production(exe,args.build);layout=group.FRAGMENT_LAYOUT
    blob=(args.build/'actvalue.obj').read_bytes();fields={};bindings={k:DS+n for k,n in v.DATA_OFFSETS.items()}
    natural,data=v.bind_leaf_details(blob,layout['context']['public'],bindings,address=0x50000,code_bindings=fields)
    assert not fields and len(natural)==31347 and len(data)==2579
    validate(layout,natural,original)
    commuted=bytearray(natural);cases=0;whole=[]
    for op in layout['operations']:
        first,last=op['fragments'];gap=op['omitted_store'];a,b,c=first['begin'],gap['begin'],gap['end']
        commuted[a:c]=natural[b:c]+natural[a:b]
        code=b''.join(natural[f['begin']:f['end']] for f in op['fragments'])
        for seed in SEEDS:
            memory,registers=base.seed(original,seed);registers=live(registers,op)
            flags=0x202 if seed&1 else 0xad7
            actual=base.execute(memory,registers,flags,code,op['original_start'])
            expected=base.execute(memory,registers,flags,bytes(original[op['original_start']:op['original_end']]),op['original_start'])
            assert actual==expected and actual[:2]==model(memory,op)
            cases+=1
    def watcher(reordered=False):
        visited=set()
        def watch(cpu,address):
            for op in layout['operations']:
                first,last=op['fragments']
                if address==0x50000+first['begin']:
                    assert cpu.reg_read(base.REGS[0])&0xffff==op['slot'];visited.add((op['slot'],'first'))
                if address==0x50000+last['begin']:
                    assert cpu.reg_read(base.REGS[3])==op['slot'];visited.add((op['slot'],'suffix'))
                gap=op['omitted_store']
                if address==0x50000+(first['begin'] if reordered else gap['begin']):
                    ins=independent_store(natural[gap['begin']:gap['end']])
                    base_name=ins.reg_name(ins.operands[0].mem.base)
                    source_name=ins.reg_name(ins.operands[1].reg)
                    source_root={'ax':'eax','bx':'ebx','cx':'ecx','dx':'edx','si':'esi','di':'edi','bp':'ebp'}[source_name]
                    assert cpu.reg_read(base.REGS[NAMES.index(base_name)])==4*op['slot']
                    assert cpu.reg_read(base.REGS[NAMES.index(source_root)])&0xffff==0
                    visited.add((op['slot'],'gap'))
        return watch,visited
    for seed in SEEDS:
        memory,registers=base.seed(original,seed);begin=group.LAYOUT['original_address']
        watch,visited=watcher();private=base.execute(memory,registers,0xad7,natural,0x50000,function=True,full=True,watch=watch)
        assert len(visited)==6
        watch,visited=watcher(reordered=True)
        reordered=base.execute(memory,registers,0xad7,bytes(commuted),0x50000,function=True,full=True,watch=watch)
        assert len(visited)==6
        assert reordered==private and len(private[1])==3079
        watch,visited=original_watcher(layout['operations'])
        reference=base.execute(memory,registers,0xad7,bytes(original[begin:begin+len(body)]),begin,function=True,full=True,watch=watch)
        assert len(visited)==2
        watch,visited=original_watcher(layout['operations'])
        placed=base.execute(memory,registers,0xad7,body,begin,function=True,full=True,watch=watch)
        assert len(visited)==2
        assert placed==reference
        whole.append(dict(seed=seed,ordered_private_writes=len(private[1]),ordered_placed_writes=len(placed[1])))
    controls=[]
    def reject(label,fn):
        try:fn()
        except (AssertionError,ValueError):controls.append(label)
        else:raise AssertionError('Fragment mutation escaped: '+label)
    for label,change in [
        ('missing_address',lambda o:o['fragments'][0].update(end=o['fragments'][0]['begin'])),
        ('instruction_boundary',lambda o:o['fragments'][0].update(begin=o['fragments'][0]['begin']+1)),
        ('include_gap',lambda o:o['fragments'][0].update(end=o['omitted_store']['end'])),
        ('missing_gap',lambda o:o['omitted_store'].update(end=o['omitted_store']['begin'])),
        ('wrong_store_offset',lambda o:o['writes'][0].__setitem__(0,7)),
        ('wrong_slot',lambda o:o['live_in_values'].update(eax=105)),
        ('wrong_suffix',lambda o:o['native_suffix_live_in_values'].update(edx=105))]:
        changed=deepcopy(layout);change(changed['operations'][0]);reject(label,lambda:validate(changed,natural,original))
    # The same bytes and DATA relocation recur at other actors. Their actual AX
    # must reject a coordinated metadata remap, even though static bytes agree.
    for number,duplicate in enumerate((0x21186,0x212d2)):
        changed=deepcopy(layout);op=changed['operations'][number]
        delta=duplicate-op['original_start'];op['original_start']+=delta;op['original_end']+=delta
        for part in range(2):
            op['fragments'][part]['address']+=delta
            changed['phases'][2*number+part]['address']+=delta
        validate(changed,natural,original)
        memory,registers=base.seed(original,7);begin=group.LAYOUT['original_address']
        watch,visited=original_watcher(changed['operations'])
        reject(f'duplicate_bytes_wrong_actor_{number}',lambda:base.execute(memory,registers,0xad7,bytes(original[begin:begin+len(body)]),begin,function=True,full=True,watch=watch))
    op=layout['operations'][0];gap=op['omitted_store'];gap_code=bytearray(natural[gap['begin']:gap['end']]);ins=decode(gap_code)[0]
    gap_code[ins.modrm_offset]=(gap_code[ins.modrm_offset]&~0x38)|(2<<3)
    reject('gap_reads_DX',lambda:independent_store(gap_code))
    # This dependency has a runtime counterexample, even though the store still targets the same word.
    memory,registers=base.seed(original,7);registers=list(live(registers,op));registers[3]=0x1234;registers[2]=4*op['slot']
    first=bytes.fromhex('0fbfd0');a=base.execute(memory,tuple(registers),0x202,first+bytes(gap_code),0x50000)
    b=base.execute(memory,tuple(registers),0x202,bytes(gap_code)+first,0x50000)
    assert a[1]!=b[1];controls.append('dependent_gap_runtime')
    code=bytearray(b''.join(natural[f['begin']:f['end']] for f in op['fragments']))
    for label,site,mask in [('wrong_stride',5,1),('wrong_zero_register',7,9),('wrong_destination',10,4)]:
        bad=bytearray(code);bad[site]^=mask;memory,registers=base.seed(original,7)
        actual=base.execute(memory,live(registers,op),0x202,bytes(bad),op['original_start'])
        assert actual[0]!=model(memory,op)[0];controls.append(label)
    report=dict(status='PASS',placed_c_bytes=28,DATA_sites=2,operations=2,phases=4,operation_cases=cases,whole_cases=whole,
        controls=controls,context_controls=context_controls(blob,group.VALUE_LAYOUT),
        scope='Two complete typed destination X assignments, each retaining both compiler fragments. A register-only MOVSX commutes past one disjoint register-to-waypoint store; EDX aliases and all register/flag/memory effects are checked. Independent operation models and complete natural/commuted contexts preserve ordered writes, final registers/flags and frame; original/placed production contexts remain identical. Existing contiguous-operation partition checks remain unchanged.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))


if __name__=='__main__':main()
