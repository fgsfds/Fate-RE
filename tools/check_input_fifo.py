"""Check the complete FIFO context, placed tail and relocation rejection controls."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path

from capstone import CS_OP_MEM
from compare_exe import TARGET_SHA256
from check_input_selection import bind_production, decode, branch
from check_encounter_actor import rewrite_fixup
from check_ripple_stack import mutate_public_byte
from dataclasses import replace
import bind_input_selection as group
import verify_c_leaf as v


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('exe','build','output'):parser.add_argument('--'+name,type=Path,required=True)
    parser.add_argument('--asm',type=Path)
    args=parser.parse_args();exe=args.exe.read_bytes()
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    BASE=0x2d51a;layout=group.FIFO_LAYOUT;ctx=layout['context'];public=ctx['public']
    _,original,placed,_,_,_=bind_production(exe,args.build,stop=3097,asm=args.asm)
    assert original==placed
    blob=(args.build/(ctx['object']+'.obj')).read_bytes()
    def bind(b):
        fields={}
        code,data=v.bind_leaf_details(b,public,layout['DATA'],address=BASE,functions={public:BASE,**layout['CODE']},code_bindings=fields)
        assert not fields and len(code)==3204 and len(data)==278
        return code,data
    private,data=bind(blob);old,new=decode(original),decode(private)
    expected_branches={0xc4e:['74',0xc7b,0xc12],0xc5b:['74',0xc7b,0xc12],0xc79:['eb',0xc50,0xbe7]}
    def validate(candidate):
        assert candidate['selected_bytes']==52 and candidate['combined_selected_bytes']==1771 and candidate['assembly_size']==1326
        assert candidate['DATA']['_input_fifo_read_index']==0x7f87b and candidate['DATA']['_input_fifo_write_index']==0x7f878,'FIFO alias DATA binding'
        assert candidate['phases']==[dict(symbol='input_fifo_drain_0_',begin=0xc47,end=0xc7b,address=0x2e0f8,public=public)],'FIFO complete phase'
        expected=[dict(original=BASE+0xbde+off-0xc47,private=off,size=i.size) for off,i in new.items() if 0xc47<=off<0xc7b]
        assert candidate['instructions']==expected and len(expected)==14,'FIFO instruction provenance'
        assert {int(k):r for k,r in candidate['branches'].items()}==expected_branches,'FIFO branch provenance'
        for row in expected:
            at,source=row['original']-BASE,row['private'];a,b=old[at],new[source];code=bytearray(b.bytes)
            assert a.size==b.size
            assert all(b.reg_name(op.mem.base)!='esp' and b.reg_name(op.mem.index)!='esp' for op in b.operands if op.type==CS_OP_MEM)
            if branch(b) is not None:
                opcode,target,destination=expected_branches[source]
                assert b.bytes[:b.imm_offset].hex()==opcode and branch(b)==target and branch(a)==destination
                code[b.imm_offset:b.imm_offset+b.imm_size]=(destination-at-b.size).to_bytes(b.imm_size,'little',signed=True)
            assert code==a.bytes,'FIFO selected instruction identity'
        assert private[0xc7b:0xc7e]==bytes.fromhex('83c408') and original[0xc12]==0x5d,'excluded cleanup and retained EBP pop'
        fields={site:offset for site,offset in data.items() if 0xc47<=site<0xc7b}
        assert fields=={0xc49:0x3d03,0xc51:0x7f87b,0xc57:0x7f878,0xc60:0x7f87b,0xc67:0x7f87b,0xc6c:0x7f87b,0xc75:0x7f87b},'FIFO typed DATA fields'
    validate(layout)
    controls=[]
    def reject(label,fn,message):
        try:fn()
        except (AssertionError,ValueError) as error:
            assert message in str(error),str(error);controls.append(label)
        else:raise AssertionError('FIFO mutation escaped: '+label)
    for alias in ('_input_fifo_read_index','_input_fifo_write_index'):
        changed=deepcopy(layout);changed['DATA'][alias]+=1
        reject('wrong_alias_'+alias,lambda:validate(changed),'FIFO alias DATA binding')
    changed=deepcopy(layout);changed['phases'][0]['end']-=2
    reject('missing_loop_backedge',lambda:validate(changed),'FIFO complete phase')
    changed=deepcopy(layout);changed['instructions'].pop(6)
    reject('missing_repeated_read',lambda:validate(changed),'FIFO instruction provenance')
    changed=deepcopy(layout);changed['branches'][str(0xc4e)][2]=0xc13
    reject('skip_EBP_restore',lambda:validate(changed),'FIFO branch provenance')
    for label,offset in (('excluded_cleanup',0xc7b),('excluded_return',0xc83),('FIFO_read_opcode',0xc5f)):
        reject(label,lambda:bind(mutate_public_byte(blob,public,offset)),'complete context digest')
    _,_,names,_,fixups=v.parsed_leaf_object(blob)
    read=next(f for f in fixups if f.offset==0xc60)
    write_symbol=names.index('_input_fifo_write_index')
    for label,change in (('read_alias_target',lambda f:replace(f,target=(2,write_symbol))),('read_alias_relative',lambda f:replace(f,relative=True)),('read_alias_frame',lambda f:replace(f,frame=(1,1)))):
        bad,count=rewrite_fixup(blob,lambda f:f.offset==read.offset,change);assert count
        reject(label,lambda:bind(bad),'fixup records')
    digest=group.FIFO_CONTEXT_SHA256;leaf=v.LEAF_CONTEXT_SHA256.pop(public);group.FIFO_CONTEXT_SHA256=None
    try:reject('read_alias_addend_without_digests',lambda:bind(mutate_public_byte(blob,public,read.offset)),'fixup addends')
    finally:group.FIFO_CONTEXT_SHA256=digest;v.LEAF_CONTEXT_SHA256[public]=leaf
    report=dict(status='PASS',new_native_bytes=52,DATA_sites=7,branches=3,context_bytes=3204,context_DATA_sites=278,context_CODE_calls=3,controls=controls,scope='Exact FIFO placement and complete private-context/typed-fixup guards. The existing 6066-case action fixture replays this production FIFO with two poisons, stable-memory read observations, terminating queues, bounded cycles and the original six-save return frame. No asynchronous producer or private-frame substitution is modeled.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))


if __name__=='__main__':main()
