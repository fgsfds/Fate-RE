"""Verify and exercise the linked sprite list routines against list invariants."""
import argparse
import hashlib
import json
from pathlib import Path
import random
import struct
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32
from unicorn.x86_const import *
from compare_exe import TARGET_SHA256
from check_start_hook import image
from match_objects import read_object
from research_startup import layout
from verify_c_leaf import bind_leaf_details,verify_leaf_relocations,DATA_OFFSETS,FUNCTION_ADDRESSES
from le_fixups import read_le_fixups
from verify_sprite_insertion import DATA
import check_spritechange as change

UNITS=[('insertsprite_',0x508b8,21),('insertspritesect_',0x508cd,158),
       ('insertspritestat_',0x5096b,158),('deletesprite_',0x50a09,20),
       ('deletespritesect_',0x50a1d,211),('deletespritestat_',0x50af0,211)]
FUNCTIONS={n:a for n,a,z in UNITS}
EPILOGUE = FUNCTION_ADDRESSES['shared_graphics_epilogue_']
DELETE_FUNCTIONS = {**FUNCTIONS, 'shared_graphics_epilogue_': EPILOGUE}
PUBLICS=[(1,o,n) for o,n in zip((0,21,177,332,352,563),(n for n,a,z in UNITS))]


def verify(exe,blob,owner):
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    segments,publics=read_object(blob);initialized,_=layout(blob)
    assert publics==PUBLICS and initialized=={1:set(range(774))}
    assert len(segments[1]['data'])==774 and all(not s['data'] for s in segments[2:])
    rows=[];pointers=read_le_fixups(exe)['pointers']
    for name,address,size in UNITS[3:]:
        code,refs=bind_leaf_details(blob,name,DATA,address=address,functions=DELETE_FUNCTIONS)
        original=exe[address+0x25600:address+0x25600+size]
        assert code == original
        verify_leaf_relocations(code,refs,pointers,address)
        rows.append(dict(symbol=name,original_address=hex(address),bytes=size,le_targets=len(refs)))
    code,refs=bind_leaf_details(owner,'transmaskvline_',DATA_OFFSETS,address=0x4aa28,functions=FUNCTION_ADDRESSES)
    assert len(code)==413 and code==exe[0x70028:0x701c5]
    verify_leaf_relocations(code,refs,pointers,0x4aa28)
    assert code[0x197:]==bytes.fromhex('5f5e5a595bc3')
    return rows


def exercise_initialization(exe, blob, linked_image):
    entry = 0x507e3
    name = 'initspritelists_'
    values = {name: address + 0x80000 for name, address in DATA.items()}
    code, refs = bind_leaf_details(blob, name, DATA, address=entry, functions=FUNCTION_ADDRESSES)
    raw = entry + 0x25600
    assert len(code) == 213 and code == exe[raw:raw + 213]
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], entry)
    linked, _ = bind_leaf_details(blob, name, values, address=entry, functions=FUNCTION_ADDRESSES)

    # Start with dirty memory and compare all affected bytes, including array
    # bounds and every sprite field that the initializer must leave alone.
    count, groups, stride = 4096, 1024, 44
    low = min(values.values()) - 8
    high = max(values['_sprite'] + count * stride,
               values['_headspritesect'] + 2 * (groups + 1)) + 8
    expected = bytearray(b'\xa5' * (high - low))
    m = Uc(UC_ARCH_X86, UC_MODE_32)
    m.mem_map(0, 0x400000)
    m.mem_write(low, bytes(expected))
    for suffix, field in (('sect', 24), ('stat', 26)):
        def store(prefix, data):
            offset = values['_' + prefix + suffix] - low
            expected[offset:offset + len(data)] = data
        store('headsprite', struct.pack('<1025h', *([-1] * groups + [0])))
        store('prevsprite', struct.pack('<4096h', *range(-1, count - 1)))
        store('nextsprite', struct.pack('<4096h', *range(1, count), -1))
        offset = values['_sprite'] - low + field
        for i in range(count):
            struct.pack_into('<h', expected, offset + stride * i, groups)

    m.mem_write(entry, linked)
    m.mem_write(EPILOGUE, linked_image[EPILOGUE:EPILOGUE + 6])
    stack, stop = 0x3f0000, 0x3ff000
    m.reg_write(UC_X86_REG_ESP, stack)
    m.mem_write(stack, struct.pack('<I', stop) + b'\xa5' * 16)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    for reg in saved:
        m.reg_write(reg, 0x12345678 + reg)
    m.emu_start(entry, stop, count=150000)
    assert m.reg_read(UC_X86_REG_EIP) == stop and m.reg_read(UC_X86_REG_ESP) == stack + 4
    assert all(m.reg_read(reg) == 0x12345678 + reg for reg in saved)
    assert m.mem_read(stack + 4, 16) == b'\xa5' * 16
    assert m.mem_read(low, len(expected)) == expected
    return dict(sprite_slots=count, sector_heads=groups + 1, status_heads=groups + 1,
                le_targets=len(refs))


def exercise(blob,changes,seed,linked_image,*,use_compiled):
    m=Uc(UC_ARCH_X86,UC_MODE_32);m.mem_map(0,0x400000)
    values={n:a+0x80000 for n,a in DATA.items()}
    functions=FUNCTIONS.copy()
    for name,address,size in UNITS:
        if use_compiled and name.startswith('delete'):
            code,_=bind_leaf_details(blob,name,values,address=address,functions=DELETE_FUNCTIONS)
        else:
            code=linked_image[address:address+size]
        m.mem_write(address,code)
    m.mem_write(EPILOGUE,linked_image[EPILOGUE:EPILOGUE+6])
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
    p.add_argument('--init-object',type=Path)
    p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    exe=a.executable.read_bytes();blob=a.lists.read_bytes();changes=a.changes.read_bytes()
    rows=verify(exe,blob,a.tail_owner.read_bytes());change.verify(exe,changes)
    linked_image=image(exe)
    seeds=(0,1,19961018,1024)
    compiled=sum(exercise(blob,changes,seed,linked_image,use_compiled=True) for seed in seeds)
    linked=sum(exercise(blob,changes,seed,linked_image,use_compiled=False) for seed in seeds)
    result=dict(target_sha256=TARGET_SHA256,object_sha256=hashlib.sha256(blob).hexdigest(),
        rows=rows,compiled_deletion_operations=compiled,linked_operations=linked,
        external_stubs=False,tail_owner_verified=True)
    if a.init_object:
        result['initialization'] = exercise_initialization(exe, a.init_object.read_bytes(), linked_image)
        print(f"PASS: initializer wrote both free lists for {result['initialization']['sprite_slots']} sprite slots")
    a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: {compiled} operations with compiled deletion and {linked} with linked list routines')
