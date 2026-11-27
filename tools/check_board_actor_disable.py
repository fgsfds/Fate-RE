"""Model the complete actor-disable loop and the six saved production registers."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
import bind_board_actor as group
import verify_c_leaf as v
import check_board_actor_groups as base
from check_board_actor_indexed import context_controls
from check_start_hook import image,DS
from compare_exe import TARGET_SHA256


def branches(code):
    from capstone import Cs,CS_ARCH_X86,CS_MODE_32,CS_GRP_JUMP
    decoder=Cs(CS_ARCH_X86,CS_MODE_32);decoder.detail=True
    return [[i.address,i.bytes.hex(),i.operands[0].imm] for i in decoder.disasm(code,0) if i.group(CS_GRP_JUMP)]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();exe=args.exe.read_bytes();assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    original=image(exe);_,body,_=base.bind_production(exe,args.build)
    layout=group.DISABLE_LAYOUT;ctx=layout['context'];phase,=layout['phases'];address=phase['address']
    assert (phase['begin'],phase['end'],address)==(0,33,0x1e91a)
    blob=(args.build/'actdisab.obj').read_bytes();values={k:DS+n for k,n in v.DATA_OFFSETS.items()}
    fields={};native,data=v.bind_leaf_details(blob,ctx['public'],values,address=0x50000,code_bindings=fields)
    assert not fields and len(native)==30234 and len(data)==2579
    prefix=body[:33];reference=original[address:address+33]
    assert prefix==native[:33]==reference
    assert branches(native)==branches(prefix)==layout['branches']==[[10,'eb0a',22],[31,'7eeb',12]]
    cases=0;whole=[];differences=flags_differ=0
    for seed in (0,1,0x7fff,0xdeadbeef,0xffffffff):
        memory,registers=base.seed(original,seed)
        expected_memory=bytearray(memory);expected_memory[DS+0x7ecb6:DS+0x7ecb6+501]=b'\xff'*501
        writes=[(DS+0x7ecb6+n,1,255) for n in range(501)]
        expected_registers=list(registers);expected_registers[0]=501;expected_registers[2]=(registers[2]&~255)|255;expected_registers[3]=501
        expected_frame=b''.join(struct.pack('<I',registers[n]) for n in (6,5,4,3,2,1))
        for flags in (0x202,0xad7):
            observed=base.execute(memory,registers,flags,bytes(reference),address,borrowed_stack=24)
            actual=base.execute(memory,registers,flags,prefix,address,borrowed_stack=24)
            assert actual==observed
            assert actual[:2]==(bytes(expected_memory[DS:DS+base.DATA_SIZE]),writes)
            assert actual[2]==tuple(expected_registers) and actual[3]==flags&~0x8d5
            assert actual[4]==24 and actual[6]==expected_frame
            cases+=1
        expected=base.execute(memory,registers,0xad7,bytes(original[address:address+len(body)]),address,function=True,full=True)
        placed=base.execute(memory,registers,0xad7,body,address,function=True,full=True)
        private=base.execute(memory,registers,0xad7,native,0x50000,function=True,full=True)
        assert placed==expected and private[0]==expected[0] and Counter(private[1])==Counter(expected[1])
        assert len(private[1])==3079 and private[1][:501]==expected[1][:501]
        assert private[2][1:]==registers[1:] and private[4]==24
        differences+=private[2]!=expected[2];flags_differ+=private[3]!=expected[3]
        whole.append(dict(seed=seed,ordered_placed_writes=len(placed[1]),private_writes=len(private[1])))
    controls=[];memory,registers=base.seed(original,7)
    for label,site,value in [('last_slot_bound',27,0xf3),('entry_jump',11,21),('back_edge_condition',31,0x7c),('saved_EBX',0,0x50)]:
        bad=bytearray(prefix);assert bad[site]!=value;bad[site]=value
        observed=base.execute(memory,registers,0x202,prefix,address,borrowed_stack=24)
        actual=base.execute(memory,registers,0x202,bytes(bad),address,borrowed_stack=24)
        assert actual!=observed,label;controls.append(label)
    report=dict(status='PASS',placed_c_bytes=33,DATA_sites=1,prefix_cases=cases,whole_cases=whole,
        private_register_difference_cases=differences,private_flag_difference_cases=flags_differ,
        code_controls=controls,context_controls=context_controls(blob,layout),
        scope='Complete 501-slot loop and six-register entry frame, including both internal branches and the fallthrough to retained assembly. Independent DATA/order/register/flag/frame model; five whole original/placed routines agree. Complete private context checks final DATA, write multiset, ordered disables and saved registers, not full raw EAX/flags or store-order equivalence.')
    args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))


if __name__=='__main__':main()
