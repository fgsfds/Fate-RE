"""Exact historical integer square-root wrapper and table-based numerical oracle."""
import argparse
import hashlib
import math
from pathlib import Path
import random
import struct
from unicorn import Uc,UcError,UC_ARCH_X86,UC_MODE_32,UC_HOOK_MEM_INVALID,UC_MEM_READ_UNMAPPED
from unicorn.x86_const import *
from compare_exe import TARGET_SHA256
from match_objects import read_object
from research_startup import layout
from verify_c_leaf import bind_leaf_details,verify_leaf_relocations
from le_fixups import read_le_fixups

ADDRESS=0x4ca38
SIZE=54
DATA={'_sqrtable':0x1dfa60}


def incoming(exe,melee_blob):
    from bind_melee_group import BASE,SIZE as MELEE_SIZE,bind
    code,data,internal,calls=bind(melee_blob)
    assert len(code)==MELEE_SIZE==459 and code==exe[BASE+0x25600:BASE+0x25600+MELEE_SIZE]
    pointers=read_le_fixups(exe)['pointers']
    expected={BASE+off:target+0x80000 for off,target in data.items()}
    expected.update({BASE+off:target+0x10000 for off,target in internal.items()})
    assert {site:target for site,target in pointers.items() if BASE<=site<BASE+MELEE_SIZE}==expected
    offset=0x10c50-BASE
    assert code[offset]==0xe8 and 0x10c55+struct.unpack_from('<i',code,offset+1)[0]==ADDRESS
    assert calls[offset+1]==ADDRESS


def verify(exe,blob):
    assert hashlib.sha256(exe).hexdigest()==TARGET_SHA256
    segments,publics=read_object(blob);initialized,_=layout(blob)
    assert publics==[(1,0,'ksqrt_')] and len(segments[1]['data'])==SIZE
    assert segments[1]['cls']=='CODE' and initialized=={1:set(range(SIZE))}
    assert all(not segment['data'] for segment in segments[2:])
    code,bindings=bind_leaf_details(blob,'ksqrt_',DATA,address=ADDRESS)
    assert code==exe[0x72038:0x7206e] and len(code)==SIZE and len(bindings)==2
    assert exe.find(code)==0x72038 and exe.find(code,0x72039)<0
    verify_leaf_relocations(code,bindings,read_le_fixups(exe)['pointers'],ADDRESS)


def table_value(index):
    square=index<<20;root=math.isqrt(square)
    return root+int((root+1)**2-square < square-root**2)


def oracle(value,table):
    magnitude=abs(value)
    if magnitude==0:return 0
    exponent=magnitude.bit_length()-1
    shift=0 if exponent<11 else (exponent-9)&~1
    return (table[magnitude>>shift]<<(shift//2))>>10


def check(blob):
    code,_=bind_leaf_details(blob,'ksqrt_',{'_sqrtable':0x30000},address=0x10000)
    m=Uc(UC_ARCH_X86,UC_MODE_32)
    for address in (0x10000,0x30000,0x40000):m.mem_map(address,0x1000)
    m.mem_write(0x10000,code)
    table=[table_value(i) for i in range(2048)];table_bytes=struct.pack('<2048H',*table)
    m.mem_write(0x30000,table_bytes)
    samples=set(range(2048))
    for bit in range(31):
        for delta in (-1,0,1):
            value=(1<<bit)+delta
            if 0<=value<=0x7fffffff:samples.add(value)
    for root in (1,2,31,32,45,46,255,256,1023,1024,32767,46340):
        for delta in (-1,0,1):samples.add(root*root+delta)
    rng=random.Random(19961018);samples.update(rng.randrange(0x80000000) for _ in range(5000))
    cases=[value for magnitude in sorted(samples) for value in ((magnitude,-magnitude) if magnitude else (0,))]
    saved=(UC_X86_REG_EBX,UC_X86_REG_ECX,UC_X86_REG_EDX,UC_X86_REG_ESI,UC_X86_REG_EDI,UC_X86_REG_EBP)
    def invoke(value,ecx=0x12345678):
        for reg in saved:m.reg_write(reg,ecx if reg==UC_X86_REG_ECX else 0x12345678)
        m.reg_write(UC_X86_REG_EAX,value&0xffffffff)
        m.reg_write(UC_X86_REG_ESP,0x40f00);m.mem_write(0x40f00,struct.pack('<I',0x1ffff))
        m.emu_start(0x10000,0x1ffff,count=100)
        assert m.reg_read(UC_X86_REG_EIP)==0x1ffff and m.reg_read(UC_X86_REG_ESP)==0x40f04
        assert all(m.reg_read(reg)==(ecx if reg==UC_X86_REG_ECX else 0x12345678) for reg in saved)
    for value in cases:
        invoke(value);assert m.reg_read(UC_X86_REG_EAX)==oracle(value,table),value
    # BSR's destination is undefined for zero; exercise every incoming low byte
    # without treating this emulator's choice as a recovered hardware guarantee.
    for initial_cl in range(256):
        invoke(0,0x12345600|initial_cl);assert m.reg_read(UC_X86_REG_EAX)==0
    assert m.mem_read(0x30000,4096)==table_bytes
    invalid=[]
    def fault(uc,access,address,size,value,data):
        invalid.append((access,address,size));return False
    m.hook_add(UC_HOOK_MEM_INVALID,fault)
    try:invoke(-0x80000000)
    except UcError:pass
    else:raise AssertionError('INT_MIN unexpectedly stayed within table')
    assert invalid==[(UC_MEM_READ_UNMAPPED,0x2fc00,2)]
    return len(cases),256


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable',type=Path);parser.add_argument('object',type=Path)
    parser.add_argument('--melee-object',type=Path)
    args=parser.parse_args();blob=args.object.read_bytes();exe=args.executable.read_bytes();verify(exe,blob)
    if args.melee_object:incoming(exe,args.melee_object.read_bytes())
    cases,zeros=check(blob)
    print(f'PASS: 54 exact bytes/2 LE; {cases} signed numerical cases, {zeros} zero-state cases; original INT_MIN out-of-table access characterized')
