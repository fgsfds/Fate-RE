"""Exact deletion wrapper; rejected list bodies with independent list invariants."""
import argparse
import hashlib
import json
from pathlib import Path
import random
import struct
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32
from unicorn.x86_const import *
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
from compare_exe import TARGET_SHA256
from match_objects import read_object
from research_startup import layout
from verify_c_leaf import bind_leaf_details,verify_leaf_relocations,DATA_OFFSETS,FUNCTION_ADDRESSES
from le_fixups import read_le_fixups
from verify_sprite_insertion import DATA
import check_spritechange as change
import verify_assembly_suite as assembly

UNITS=[('insertsprite_',0x508b8,21),('insertspritesect_',0x508cd,158),
       ('insertspritestat_',0x5096b,158),('deletesprite_',0x50a09,20),
       ('deletespritesect_',0x50a1d,211),('deletespritestat_',0x50af0,211)]
FUNCTIONS={n:a for n,a,z in UNITS}
PUBLICS=[(1,o,n) for o,n in zip((0,21,177,332,352,563),(n for n,a,z in UNITS))]


def verify(exe,blob,owner):
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    segments,publics=read_object(blob);initialized,_=layout(blob)
    assert publics==PUBLICS and initialized=={1:set(range(774))}
    assert len(segments[1]['data'])==774 and all(not s['data'] for s in segments[2:])
    rows=[];pointers=read_le_fixups(exe)['pointers']
    for name,address,size in UNITS:
        code,refs=bind_leaf_details(blob,name,DATA,address=address,functions=FUNCTIONS)
        original=exe[address+0x25600:address+0x25600+size]
        exact=code==original
        assert exact==(name in ('insertsprite_','deletesprite_'))
        if exact:verify_leaf_relocations(code,refs,pointers,address)
        jumps=[i.address for i in Cs(CS_ARCH_X86,CS_MODE_32).disasm(original,address)
               if i.mnemonic=='jmp' and i.op_str=='0x4abbf']
        if not exact:assert len(jumps)==2
        rows.append(dict(symbol=name,original_address=hex(address),original_bytes=size,
            generated_bytes=len(code),exact=exact,original_shared_tail_jumps=[hex(a) for a in jumps],
            differing_offsets=[i for i,(a,b) in enumerate(zip(code,original)) if a!=b]))
    code,refs=bind_leaf_details(owner,'transmaskvline_',DATA_OFFSETS,address=0x4aa28,functions=FUNCTION_ADDRESSES)
    assert len(code)==413 and code==exe[0x70028:0x701c5]
    verify_leaf_relocations(code,refs,pointers,0x4aa28)
    assert code[0x197:]==bytes.fromhex('5f5e5a595bc3')
    return rows


def relocated_list(name, directory):
    _,_,filename,_,size,pointers=next(unit for unit in assembly.ROUTINES if unit[0]==name)
    start,_=assembly.GROUP_SLICES[name]
    code=bytearray((directory/filename).read_bytes()[start:start+size])
    for site,target in pointers.items():
        struct.pack_into('<I',code,site,target)
    return bytes(code)


def exercise(blob,changes,seed,exact_directory=None,tail=None):
    m=Uc(UC_ARCH_X86,UC_MODE_32);m.mem_map(0,0x400000)
    values={n:a+0x80000 for n,a in DATA.items()}
    functions=({n:0x10000+o for seg,o,n in PUBLICS}
               if exact_directory is None else FUNCTIONS.copy())
    for seg,offset,name in PUBLICS:
        address=functions[name]
        if exact_directory is not None and name not in ('insertsprite_', 'deletesprite_'):
            code=relocated_list(name,exact_directory)
        else:
            code,_=bind_leaf_details(blob,name,values,address=address,functions=functions)
        m.mem_write(address,code)
    if exact_directory is not None:
        m.mem_write(0x4abbf,tail)
    for i,(name,address,size) in enumerate(change.UNITS):
        functions[name]=0x20000+i*80
        code,_=bind_leaf_details(changes,name,values,address=functions[name],functions=functions)
        m.mem_write(functions[name],code)
    state={suffix:{0:[],5:[8,9,10],9:[11,12],1023:[13,14,15],1024:list(range(8))}
           for suffix in ('sect','stat')}
    def expected():
        arrays={}
        sprite=bytearray(b'\xa5'*(16*44))
        for suffix,lists in state.items():
            heads=[-1]*1025;prev=[-1]*4096;nxt=[-1]*4096;seen=[]
            for group,chain in lists.items():
                heads[group]=chain[0] if chain else -1
                for j,slot in enumerate(chain):
                    assert slot not in seen;seen.append(slot)
                    prev[slot]=chain[j-1] if j else -1
                    nxt[slot]=chain[j+1] if j+1<len(chain) else -1
                    struct.pack_into('<h',sprite,slot*44+(24 if suffix=='sect' else 26),group)
            assert sorted(seen)==list(range(16))
            arrays[values['_headsprite'+suffix]]=struct.pack('<1025h',*heads)
            arrays[values['_prevsprite'+suffix]]=struct.pack('<4096h',*prev)
            arrays[values['_nextsprite'+suffix]]=struct.pack('<4096h',*nxt)
        arrays[values['_sprite']]=bytes(sprite)
        return arrays
    initial=expected()
    for address,data in initial.items():m.mem_write(address,data)
    spans=sorted((a,a+len(d)) for a,d in initial.items());merged=[]
    for start,end in spans:
        if merged and start<=merged[-1][1]:merged[-1][1]=max(merged[-1][1],end)
        else:merged.append([start,end])
    for start,end in merged:m.mem_write(start-8,b'\x5a'*8);m.mem_write(end,b'\xa5'*8)
    # Model expresses list operations, not pointer-write instruction sequences.
    def insert(suffix,destination):
        groups=state[suffix]
        if destination>=1024 or not groups[1024]:return -1
        slot=groups[1024].pop(0);groups.setdefault(destination,[]).insert(0,slot);return slot
    def delete(suffix,slot):
        groups=state[suffix];current=next(g for g,c in groups.items() if slot in c)
        if current==1024:return -1
        groups[current].remove(slot);groups[1024].insert(0,slot);return 0
    def alter(suffix,slot,destination):
        groups=state[suffix];current=next(g for g,c in groups.items() if slot in c)
        if destination<0 or destination>1024:return -1
        if destination==current:return 0
        if current==1024:return -1
        assert delete(suffix,slot)==0;insert(suffix,destination);return 0
    rng=random.Random(seed)
    operations=[('insertsprite_',5,9),('deletesprite_',8,0),('changespritesect_',9,9),
        ('changespritestat_',10,1024),('insertspritesect_',1023,0),('insertspritestat_',1024,0),
        ('changespritesect_',11,1025),('changespritestat_',12,-1)]
    choices=list(functions)
    for _ in range(120):
        name=rng.choice(choices)
        x=rng.choice([0,5,9,1023,1024,1025]) if name.startswith('insert') else rng.randrange(16)
        y=rng.choice([0,5,9,1023,1024,1025] if name=='insertsprite_' else [-1,0,5,9,1023,1024,1025]);operations.append((name,x,y))
    for name,x,y in operations:
        if name=='insertsprite_':insert('stat',y);result=insert('sect',x)
        elif name=='deletesprite_':delete('stat',x);result=delete('sect',x)
        elif name.startswith('insertsprite'):result=insert(name[-5:-1],x)
        elif name.startswith('deletesprite'):result=delete(name[-5:-1],x)
        else:result=alter(name[-5:-1],x,y)
        saved={r:0x12345678+i*0x11111111 for i,r in enumerate((UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP))}
        for r,v in saved.items():m.reg_write(r,v)
        m.reg_write(UC_X86_REG_EAX,x&0xffffffff);m.reg_write(UC_X86_REG_EDX,y&0xffffffff)
        m.reg_write(UC_X86_REG_ESP,0x3f0000);m.mem_write(0x3f0000,struct.pack('<I',0x3ff000)+b'\xa5'*16)
        m.emu_start(functions[name],0x3ff000,count=10000)
        assert m.reg_read(UC_X86_REG_EAX)==result&0xffffffff,(name,x,y,result)
        assert m.reg_read(UC_X86_REG_EIP)==0x3ff000 and m.reg_read(UC_X86_REG_ESP)==0x3f0004
        assert all(m.reg_read(r)==v for r,v in saved.items())
        assert m.mem_read(0x3f0004,16)==b'\xa5'*16
        for address,data in expected().items():
            assert bytes(m.mem_read(address,len(data)))==data,(name,x,y,hex(address))
        for start,end in merged:
            assert m.mem_read(start-8,8)==b'\x5a'*8 and m.mem_read(end,8)==b'\xa5'*8
    return len(operations)


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('executable',type=Path)
    p.add_argument('lists',type=Path);p.add_argument('changes',type=Path);p.add_argument('tail_owner',type=Path)
    p.add_argument('--assembly-directory',type=Path);p.add_argument('--c-inventory',type=Path)
    p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    exe=a.executable.read_bytes();blob=a.lists.read_bytes();changes=a.changes.read_bytes()
    rows=verify(exe,blob,a.tail_owner.read_bytes());change.verify(exe,changes)
    count=sum(exercise(blob,changes,seed) for seed in (0,1,19961018,1024))
    exact_operations=0
    if (a.assembly_directory is None)!=(a.c_inventory is None):
        p.error('Exact list integration requires both assembly directory and C inventory')
    if a.assembly_directory is not None:
        inventory=json.loads(a.c_inventory.read_text(encoding='utf-8'))
        assembly.verify(exe,a.assembly_directory,inventory)
        owner,_=bind_leaf_details(a.tail_owner.read_bytes(),'transmaskvline_',DATA_OFFSETS,
                                  address=0x4aa28,functions=FUNCTION_ADDRESSES)
        exact_operations=sum(exercise(blob,changes,seed,a.assembly_directory,owner[0x197:])
                             for seed in (0,1,19961018,1024))
    result=dict(target_sha256=TARGET_SHA256,object_sha256=hashlib.sha256(blob).hexdigest(),
        rows=rows,generated_group_bytes=774,list_bodies_exact=False,whole_group_exact=False,
        newly_matched_bytes=20,newly_matched_le_targets=0,duplicate_insert_wrapper_bytes=21,
        source_candidate_operations=count,exact_assembly_operations=exact_operations,
        external_stubs=False,tail_owner_verified=True,
        resolved_branches_patched=False,final_linked_placement_verified=False)
    a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: exact 20-byte deletion wrapper; four list bodies rejected; {count} candidate list operations')
    if exact_operations:
        print(f'PASS: four exact assembly list bodies; {exact_operations} list operations')
