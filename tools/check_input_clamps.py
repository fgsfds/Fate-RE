"""Exact clamp placement plus an independent private-service ABI oracle."""
import argparse
from copy import deepcopy
from dataclasses import replace
import hashlib
import json
from pathlib import Path
from random import Random
import struct

from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE,UC_HOOK_MEM_WRITE
from unicorn import x86_const as x
from compare_exe import TARGET_SHA256
from check_input_selection import bind_production,decode,branch
from check_encounter_actor import rewrite_fixup
from check_ripple_stack import mutate_public_byte
import bind_input_selection as group
import verify_c_leaf as v

DATA,BASE,STACK,STOP=0x80000,0x2d51a,0x3fef00,0x3fff00
FIELDS=(0x8528e,0x8528c,0x2bf2)
LIMITS=((316,988),(364,440),(256,2048))


def cases():
    rows=[(500,400,512)]
    for field,(lo,hi) in enumerate(LIMITS):
        for value in sorted({-32768,-1,0,lo-1,lo,lo+1,hi-1,hi,hi+1,32767}):
            values=[500,400,512];values[field]=value;rows.append(tuple(values))
    rng=Random(0x2da67)
    rows.extend(tuple(rng.randrange(-32768,32768) for _ in range(3)) for _ in range(256))
    return sorted(set(rows))


class PrivateReplay:
    def __init__(self,code):
        self.cpu=Uc(UC_ARCH_X86,UC_MODE_32);self.cpu.mem_map(0,0x410000)
        self.cpu.mem_write(DATA,b'\xa5'*0x28a300);self.cpu.mem_write(BASE,code)
        self.cpu.hook_add(UC_HOOK_MEM_WRITE,self.on_write);self.cpu.hook_add(UC_HOOK_CODE,self.on_code)
    def on_write(self,cpu,access,address,size,value,user):
        assert address in {DATA+f for f in FIELDS} and size==2,'private write extent'
        self.writes.append((address,size,value))
    def on_code(self,cpu,pc,size,user):
        assert BASE<=pc and pc+size<=BASE+176,'private execution extent'
        self.path.append(pc-BASE)
    def run(self,values,poison=0):
        cpu=self.cpu;names=('eax','ecx','edx','esi','edi','ebp')
        saved={name:((0x91e12345+i*0x1111)^poison)&0xffffffff for i,name in enumerate(names)}
        saved['esi']=(saved['esi']&0xffff0000)|(values[2]&0xffff)
        for name,value in saved.items():cpu.reg_write(getattr(x,'UC_X86_REG_'+name.upper()),value)
        cpu.reg_write(x.UC_X86_REG_EBX,values[0]&0xffffffff)
        for offset,value in zip(FIELDS,values):cpu.mem_write(DATA+offset,struct.pack('<h',value))
        cpu.mem_write(STACK-64,b'\x5a'*132);cpu.mem_write(STACK,struct.pack('<I',STOP))
        cpu.reg_write(x.UC_X86_REG_ESP,STACK);cpu.reg_write(x.UC_X86_REG_EFLAGS,0x202)
        self.writes=[];self.path=[];cpu.emu_start(BASE,STOP,count=200)
        expected=tuple(min(max(value,lo),hi) for value,(lo,hi) in zip(values,LIMITS))
        assert self.writes==[(DATA+offset,2,value) for offset,value in zip(FIELDS,expected)],'private ordered clamp writes'
        assert all(cpu.reg_read(getattr(x,'UC_X86_REG_'+name.upper()))==value for name,value in saved.items()),'private preserved GPRs'
        assert cpu.reg_read(x.UC_X86_REG_EIP)==STOP and cpu.reg_read(x.UC_X86_REG_ESP)==STACK+4,'private return frame'
        assert cpu.mem_read(STACK,4)==struct.pack('<I',STOP) and cpu.mem_read(STACK-64,64)==b'\x5a'*64 and cpu.mem_read(STACK+4,64)==b'\x5a'*64,'private protected frame'
        assert tuple(struct.unpack('<h',cpu.mem_read(DATA+f,2))[0] for f in FIELDS)==expected
        return self.path


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('exe','build','output'):parser.add_argument('--'+name,type=Path,required=True)
    parser.add_argument('--asm',type=Path)
    args=parser.parse_args();exe=args.exe.read_bytes()
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    _,original,placed,_,_,_=bind_production(exe,args.build,stop=3097,asm=args.asm);assert original==placed
    layout=group.CLAMP_LAYOUT;ctx=layout['context'];public=ctx['public'];blob=(args.build/(ctx['object']+'.obj')).read_bytes()
    def bind(b):
        fields={};code,data=v.bind_leaf_details(b,public,layout['DATA'],address=BASE,functions={public:BASE},code_bindings=fields)
        assert not fields and len(code)==176 and len(data)==7
        return code,data
    private,data=bind(blob);old,new=decode(original),decode(private)
    expected=((0x54d,0x5c2,0),(0x64e,0x685,0x78))
    def validate(candidate):
        assert candidate['selected_bytes']==172 and candidate['combined_selected_bytes']==2000 and candidate['assembly_size']==1097
        assert candidate['DATA']==dict(zip(('_cursor_x','_cursor_y','_map_scale_or_y'),FIELDS)) and candidate['CODE']=={},'clamp typed bindings'
        phases=candidate['phases'];assert [(p['address']-BASE,p['address']-BASE+p['end']-p['begin'],p['begin']) for p in phases]==list(expected),'clamp complete phases'
        assert all(p['public']==public for p in phases)
        rows=[dict(original=BASE+lo+at-source,private=at,size=i.size) for lo,hi,source in expected for at,i in new.items() if source<=at<source+hi-lo]
        assert candidate['instructions']==rows,'clamp instruction provenance'
        entries={r['private']:r['original']-BASE for r in rows}
        records={int(k):value for k,value in candidate['branches'].items()}
        assert set(records)=={source for source in entries if branch(new[source]) is not None} and len(records)==12,'clamp branch inventory'
        for row in rows:
            at,source=row['original']-BASE,row['private'];a,b=old[at],new[source]
            assert a.size==b.size and a.bytes==b.bytes,'clamp selected byte identity'
            target=branch(b)
            if target is not None:
                assert entries[target]==branch(a),'clamp logical successor'
                assert records[source]==[b.bytes[:b.imm_offset].hex(),target,branch(a)],'clamp branch metadata'
        assert data=={24:FIELDS[0],51:FIELDS[0],58:FIELDS[1],86:FIELDS[1],113:FIELDS[1],144:FIELDS[2],171:FIELDS[2]},'clamp DATA fields'
        assert private[0x75:0x78]==bytes.fromhex('0fbfde') and private[0xaf:]==b'\xc3','clamp excluded SI/return'
    validate(layout)
    relocated=bytearray(private)
    for site,offset in data.items():struct.pack_into('<I',relocated,site,DATA+offset)
    replay=PrivateReplay(bytes(relocated));all_cases=cases();outcomes={int(site):set() for site in layout['branches']}
    for values in all_cases:
        for poison in (0,0xffffffff):
            path=replay.run(values,poison)
            for here,nxt in zip(path,path[1:]):
                if here in outcomes:
                    target=branch(new[here]);assert nxt==target or nxt==here+new[here].size
                    outcomes[here].add(nxt==target)
    assert len(all_cases)>=280
    assert all(values==({True} if new[site].mnemonic=='jmp' else {False,True}) for site,values in outcomes.items()),outcomes
    controls=[]
    def reject(label,fn,message):
        try:fn()
        except (AssertionError,ValueError) as error:
            assert message in str(error),str(error);controls.append(label)
        else:raise AssertionError('Clamp mutation escaped: '+label)
    changed=deepcopy(layout);changed['phases'][0]['end']-=1
    reject('partial_Y_store',lambda:validate(changed),'clamp complete phases')
    changed=deepcopy(layout);changed['instructions'].pop()
    reject('missing_scale_store',lambda:validate(changed),'clamp instruction provenance')
    changed=deepcopy(layout);changed['branches']['6'][2]+=1
    reject('wrong_successor',lambda:validate(changed),'clamp branch metadata')
    changed=deepcopy(layout);changed['DATA']['_cursor_x']+=2
    reject('wrong_DATA_binding',lambda:validate(changed),'clamp typed bindings')
    for label,offset in (('excluded_SI_bridge',0x75),('excluded_RET',0xaf),('clamp_opcode',0)):
        reject(label,lambda:bind(mutate_public_byte(blob,public,offset)),'complete context digest')
    _,_,names,_,fixups=v.parsed_leaf_object(blob);field=next(f for f in fixups if f.offset==24)
    other=names.index('_cursor_y')
    for label,change in (('DATA_target',lambda f:replace(f,target=(2,other))),('DATA_relative',lambda f:replace(f,relative=True)),('DATA_frame',lambda f:replace(f,frame=(1,1)))):
        bad,count=rewrite_fixup(blob,lambda f:f.offset==field.offset,change);assert count
        reject(label,lambda:bind(bad),'fixup records')
    digest=group.CLAMP_CONTEXT_SHA256;leaf=v.LEAF_CONTEXT_SHA256.pop(public);group.CLAMP_CONTEXT_SHA256=None
    try:reject('DATA_addend_without_digests',lambda:bind(mutate_public_byte(blob,public,field.offset)),'fixup addends')
    finally:group.CLAMP_CONTEXT_SHA256=digest;v.LEAF_CONTEXT_SHA256[public]=leaf
    bad=bytearray(relocated);bad[0x76]=0xb7
    reject('unsigned_private_SI',lambda:PrivateReplay(bytes(bad)).run((500,400,-1)),'private ordered clamp writes')
    bad=bytearray(relocated);bad[0x75:0x78]=bytes.fromhex('31f690')
    reject('private_ESI_clobber',lambda:PrivateReplay(bytes(bad)).run((500,400,-1)),'private preserved GPRs')
    report=dict(status='PASS',new_native_bytes=172,DATA_sites=7,branches=12,operations=3,private_cases=len(all_cases),poison_seeds=2,private_branch_outcomes={hex(k):sorted(v) for k,v in outcomes.items()},controls=controls,scope='Exact placed X/Y/scale operations; separate complete void-helper model checks stable signed-word inputs, ordered X/Y/scale stores, every branch outcome, signed SI, all promised GPR preservation and RET through a sentinel. Private SI setup and RET stay excluded from production placement. Void has no C return-value contract. The cursor fixture separately replays the original/placed cursor/map collect_input fragment 0x2d9fe..0x2de0c with its mode dispatch and live entry contracts; no interrupts or BIOS behavior modeled.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))


if __name__=='__main__':main()
