"""Exact sector/status change wrappers with original boundary behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from unicorn import Uc,UC_ARCH_X86,UC_MODE_32,UC_HOOK_CODE
from unicorn.x86_const import *
from compare_exe import TARGET_SHA256
from match_objects import read_object
from research_startup import layout
from verify_c_leaf import bind_leaf_details,verify_leaf_relocations
from le_fixups import read_le_fixups

DATA={'_sprite':0x2040a0}
FUNCTIONS=dict(deletespritesect_=0x50a1d,insertspritesect_=0x508cd,
               deletespritestat_=0x50af0,insertspritestat_=0x5096b)
UNITS=[('changespritesect_',0x50bc3,80),('changespritestat_',0x50c13,80)]


def verify(exe,blob):
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    segments,publics=read_object(blob);initialized,_=layout(blob)
    assert publics==[(1,0,'changespritesect_'),(1,80,'changespritestat_')]
    assert initialized=={1:set(range(160))} and len(segments[1]['data'])==160
    assert all(not s['data'] for s in segments[2:])
    for name,address,size in UNITS:
        code,refs=bind_leaf_details(blob,name,DATA,address=address,functions=FUNCTIONS)
        assert len(code)==size and code==exe[address+0x25600:address+0x25600+size] and len(refs)==1
        verify_leaf_relocations(code,refs,read_le_fixups(exe)['pointers'],address)
    # Independently anchored by the already matched movement caller.
    site=0x135e1;raw=site+0x25600
    assert exe[raw]==0xe8 and site+5+struct.unpack_from('<i',exe,raw+1)[0]==0x50bc3


def scenario(blob,status,index,current,destination,deleted,inserted):
    name,address,size=UNITS[int(status)]
    functions={n:0x18000+i*16 for i,n in enumerate(FUNCTIONS)}
    code,_=bind_leaf_details(blob,name,{'_sprite':0x30000},address=0x10000,functions=functions)
    m=Uc(UC_ARCH_X86,UC_MODE_32);m.mem_map(0,0x100000);m.mem_write(0x10000,code)
    for a in functions.values():m.mem_write(a,b'\xc3')
    record=0x30000+index*44;field=26 if status else 24
    initial=bytearray(b'\xa5'*76);struct.pack_into('<h',initial,16+field,current)
    m.mem_write(record-16,bytes(initial));expected=bytearray(initial)
    delete_name='deletespritestat_' if status else 'deletespritesect_'
    insert_name='insertspritestat_' if status else 'insertspritesect_'
    calls=[];reverse={a:n for n,a in functions.items()}
    def hook(uc,a,size,data):
        if 0x10000<=a<0x10050:return
        assert a in reverse;n=reverse[a];calls.append(n)
        if n==delete_name:
            assert uc.reg_read(UC_X86_REG_EAX)==index&0xffffffff
            if deleted>=0:m.mem_write(record+field,struct.pack('<h',1024))
            uc.reg_write(UC_X86_REG_EAX,deleted&0xffffffff)
        elif n==insert_name:
            assert uc.reg_read(UC_X86_REG_EAX)==destination
            assert struct.unpack('<h',m.mem_read(record+field,2))[0]==1024
            if inserted>=0:m.mem_write(record+field,struct.pack('<h',destination))
            uc.reg_write(UC_X86_REG_EAX,inserted&0xffffffff)
        else:raise AssertionError(n)
        uc.reg_write(UC_X86_REG_EDX,0x87654321)
    m.hook_add(UC_HOOK_CODE,hook)
    saved={r:0x12345678+i*0x11111111 for i,r in enumerate((UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP))}
    for r,v in saved.items():m.reg_write(r,v)
    m.reg_write(UC_X86_REG_EAX,(index&65535)|0xa5a50000)
    m.reg_write(UC_X86_REG_EDX,(destination&65535)|0x5a5a0000)
    m.reg_write(UC_X86_REG_ESP,0x8f000);m.mem_write(0x8f000,struct.pack('<I',0x90000)+b'\xa5'*16)
    m.emu_start(0x10000,0x90000,count=150)
    wanted=[];result=-1
    if 0<=destination<=1024:
        if current==destination:result=0
        elif current!=1024:
            wanted=[delete_name]
            if deleted>=0:
                wanted.append(insert_name);result=0
                struct.pack_into('<h',expected,16+field,destination if inserted>=0 else 1024)
    assert calls==wanted and m.reg_read(UC_X86_REG_EAX)==result&0xffffffff
    assert bytes(m.mem_read(record-16,76))==bytes(expected)
    assert m.reg_read(UC_X86_REG_EIP)==0x90000 and m.reg_read(UC_X86_REG_ESP)==0x8f004
    assert all(m.reg_read(r)==v for r,v in saved.items()) and m.mem_read(0x8f004,16)==b'\xa5'*16


def check(blob):
    cases=0
    for status in (False,True):
        for index in (-1,0,4095):
            for current in (-1,0,17,1023,1024):
                for destination in (-32768,-1,0,17,1023,1024,1025,32767):
                    for deleted,inserted in [(-1,0),(0,-1),(0,0),(7,4095)]:
                        scenario(blob,status,index,current,destination,deleted,inserted);cases+=1
    return cases


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('executable',type=Path)
    p.add_argument('object',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    blob=a.object.read_bytes();verify(a.executable.read_bytes(),blob);cases=check(blob)
    result=dict(source='src/engine/spritechange.c',target_sha256=TARGET_SHA256,
        object_sha256=hashlib.sha256(blob).hexdigest(),code_bytes=160,le_targets=2,behavior_cases=cases,
        public_spans=[dict(symbol=n,address=hex(ad),bytes=z) for n,ad,z in UNITS],
        provenance='reference/build/ENGINE.C at 88ffca1bdb8d93c731f6d02e62ae5119393bc73b',
        interfaces='explicit deletion/insertion list stubs',final_linked_placement_verified=False)
    a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: 160 bytes / 2 LE targets / {cases} boundary, list-interface and ABI cases')
