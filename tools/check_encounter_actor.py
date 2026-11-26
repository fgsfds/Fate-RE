"""Check encounter actor control, complete private contexts and placed handoffs."""
import argparse, hashlib, json, struct
from dataclasses import replace
from pathlib import Path
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from check_ripple_stack import mutate_public_byte
from check_ripple_control import rename_external
from omf_fixups import Reader, decode
from le_fixups import read_le_fixups
import verify_c_leaf as v
from verify_c_suite import OBJECT_NAMES
ENTRY, END, EXIT, NEAR = 0x1e23a, 0x1e299, 0x1e30b, 0x10610
STACK, DATA_SIZE = 0x3fe000, 0x360000
STATE, KIND = 0x127f6, 0x7f0df
REGS = (UC_X86_REG_EAX,UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
NAMES = ('load','condition','kind','kind_store','reset','continue')

def rewrite_fixup(blob, predicate, change):
    """Re-encode decoded fixups explicitly, preserving fields except one mutation."""
    out=bytearray();cursor=0;context=None;threads={};changed=False
    def index(n):
        return bytes([n]) if n<128 else bytes([0x80|(n>>8),n&255])
    while cursor<len(blob):
        kind=blob[cursor];length=int.from_bytes(blob[cursor+1:cursor+3],'little');end=cursor+3+length
        payload=blob[cursor+3:end-1]
        if kind in (0xa0,0xa1):
            reader=Reader(payload);seg=reader.index();start=reader.number(4 if kind&1 else 2)
            context=(seg,start,len(payload)-reader.pos)
        if kind in (0x9c,0x9d):
            rows=decode(payload,bool(kind&1),context,threads);data=bytearray()
            for f in rows:
                if not changed and predicate(f):f=change(f);changed=True
                offset=f.offset-context[1];assert 0<=offset<1024
                data.extend([0x80|(0 if f.relative else 64)|(f.location<<2)|(offset>>8),offset&255,(f.frame[0]<<4)|f.target[0]])
                if f.frame[0] in (0,1,2):data.extend(index(f.frame[1]))
                data.extend(index(f.target[1]));data.extend(struct.pack('<I',f.displacement))
            record=bytearray([0x9d])+struct.pack('<H',len(data)+1)+data
            record.append((-sum(record))&255);out.extend(record)
        else:out.extend(blob[cursor:end])
        cursor=end
    return bytes(out),changed

def bind(exe,build):
    pointers=read_le_fixups(exe)['pointers'];raw_parts=[];loaded_parts=[];cursor=ENTRY
    for name in NAMES:
        symbol='encounter_actor_'+name+'_';offset,size=v.LEAVES[symbol];address=offset-0x25600
        assert address==cursor
        blob=(build/(OBJECT_NAMES[symbol]+'.obj')).read_bytes()
        kwargs=dict(address=address,functions=v.FUNCTION_ADDRESSES,absolute_code=v.CODE_OFFSETS)
        code_refs={}
        raw,refs=v.bind_leaf_details(blob,symbol,v.DATA_OFFSETS,code_bindings=code_refs,**kwargs)
        assert not code_refs, 'Actor-state operands must all be DATA'
        assert raw==exe[offset:offset+size]
        v.verify_leaf_relocations(raw,refs,pointers,address,code_bindings=code_refs)
        loaded,_=v.bind_leaf_details(blob,symbol,{n:DS+x for n,x in v.DATA_OFFSETS.items()},code_bindings={},**kwargs)
        raw_parts.append(raw);loaded_parts.append(loaded);cursor+=size
    assert cursor==END and sum(map(len,raw_parts))==95
    return b''.join(loaded_parts)

def exercise(memory,code,case):
    state,kind,returns=case;cpu=Uc(UC_ARCH_X86,UC_MODE_32);cpu.mem_map(0,len(memory));cpu.mem_write(0,memory)
    cpu.mem_write(ENTRY,code);cpu.mem_write(DS+STATE,struct.pack('<h',state));cpu.mem_write(DS+KIND,bytes([kind]))
    cpu.mem_write(STACK-64,b'\xa7'*128);cpu.reg_write(UC_X86_REG_ESP,STACK)
    for n,reg in enumerate(REGS):cpu.reg_write(reg,0xbad00000+n)
    cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7);calls=[]
    def hook(cpu,address,size,user):
        if address in (END,EXIT):cpu.emu_stop();return
        if address==NEAR:
            calls.append((cpu.reg_read(UC_X86_REG_EAX),cpu.reg_read(UC_X86_REG_EDX)))
            value=returns[min(len(calls)-1,1)]
            cpu.reg_write(UC_X86_REG_EAX,value&0xffffffff);cpu.reg_write(UC_X86_REG_EFLAGS,0x8d7)
            sp=cpu.reg_read(UC_X86_REG_ESP);dest=int.from_bytes(cpu.mem_read(sp,4),'little')
            cpu.reg_write(UC_X86_REG_ESP,sp+4);cpu.reg_write(UC_X86_REG_EIP,dest)
    cpu.hook_add(UC_HOOK_CODE,hook);cpu.emu_start(ENTRY,0,count=200)
    end=cpu.reg_read(UC_X86_REG_EIP)
    assert end in (END,EXIT),'phase failed to hand off'
    return (end,tuple(cpu.reg_read(r) for r in REGS),cpu.reg_read(UC_X86_REG_ESP),cpu.reg_read(UC_X86_REG_EFLAGS)&~0x10,tuple(calls),bytes(cpu.mem_read(DS,DATA_SIZE)),bytes(cpu.mem_read(STACK-64,128)))

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    exe=a.exe.read_bytes();memory=image(exe);reference=memory[ENTRY:END];candidate=bind(exe,a.build)
    returns=((0,0),(0,1),(1,0),(-1,0),(0x7fff0000,0x80000000),(0x8000,0))
    cases=[(state,kind,pair) for state in (-32768,0,1,2,32767) for kind in (0,3,4,5,6,255) for pair in returns]
    for case in cases:
        original=exercise(memory,reference,case);actual=exercise(memory,candidate,case);assert actual==original,case
        state,kind,pair=case;reset=state==0 and ((pair[0]&0xffff)|(pair[1]&0xffff) or kind in (4,5))
        expected=bytearray(memory[DS:DS+DATA_SIZE]);struct.pack_into('<h',expected,STATE,1 if reset else state);expected[KIND]=0 if reset else kind
        assert original[0]==(END if state else EXIT)
        assert original[4]==(() if state else ((0x2a00,0x1000),(0x2a00,0x2000)))
        assert original[5]==bytes(expected),case
    # Machine-code controls target state value and entry branch direction.
    bad_state=bytearray(reference);bad_state[88]^=3
    bad_branch=bytearray(reference);bad_branch[10]^=1
    for bad,case in [(bytes(bad_state),(0,4,(0,0))),(bytes(bad_branch),(1,0,(0,0)))]:
        assert exercise(memory,bad,case)!=exercise(memory,reference,case)
    obj=(a.build/'enclatch.obj').read_bytes();symbol='encounter_actor_load_'
    def rejected(blob,message):
        try:v.bind_leaf_details(blob,symbol,v.DATA_OFFSETS,address=ENTRY,functions=v.FUNCTION_ADDRESSES,code_bindings={})
        except ValueError as error:assert message in str(error),str(error)
        else:raise AssertionError('Context mutation escaped')
    controls=[]
    for offset in (0x2ff,19):rejected(mutate_public_byte(obj,'encounter_latch_context_',offset),'context digest');controls.append('public_byte_'+str(offset))
    rejected(mutate_public_byte(obj,'encounter_latch_context_',-160),'literal prefix');controls.append('literal_prefix')
    rejected(rename_external(obj,b'_encounter_clock',b'_encounter_clocx'),'fixup records');controls.append('excluded_external_name')
    control,changed=rewrite_fixup(obj,lambda f:False,lambda f:f);assert not changed
    assert v.bind_leaf_details(control,symbol,v.DATA_OFFSETS,address=ENTRY,functions=v.FUNCTION_ADDRESSES,code_bindings={})==v.bind_leaf_details(obj,symbol,v.DATA_OFFSETS,address=ENTRY,functions=v.FUNCTION_ADDRESSES,code_bindings={})
    for name,predicate,change,message in [
        ('internal_target',lambda f:f.target[0]==0,lambda f:replace(f,target=(0,3)),'fixup records'),
        ('frame',lambda f:f.target[0]==0,lambda f:replace(f,frame=(1,1)),'fixup records'),
        ('displacement',lambda f:f.target[0]==0,lambda f:replace(f,displacement=1),'fixup records'),
        ('external_index',lambda f:f.target[0]==2,lambda f:replace(f,target=(2,127)),'external index')]:
        bad,changed=rewrite_fixup(obj,predicate,change);assert changed;rejected(bad,message);controls.append(name)
    helper=(a.build/'actreset.obj').read_bytes()
    try:v.bind_leaf_details(mutate_public_byte(helper,'reset_second_trigger_',9),'encounter_actor_reset_',v.DATA_OFFSETS,address=0x1e28b)
    except ValueError as error:assert 'context digest' in str(error)
    else:raise AssertionError('Helper private RET mutation escaped')
    controls.append('helper_private_ret')
    report=dict(status='PASS',cases=len(cases),native_bytes=95,LE_sites=4,context_controls=controls,code_controls=2,scope='phase differential with stubbed near-condition calls; full DS/register/frame/defined flags comparison; synthetic signed and poisoned high-word returns included',candidate_sha256=hashlib.sha256(candidate).hexdigest())
    a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
if __name__=='__main__':main()
