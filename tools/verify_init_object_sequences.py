"""Exact sequence initializer and descriptors produced by compiled C alone."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED, image
from match_objects import read_object
from omf_fixups import read_externals
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

ADDRESS, SIZE = 0x3b609, 18114
TABLE, TABLE_SIZE = 0xe807c, 256*120
DATA = {'_object_sequence_definitions':0x6807c}
SELECTED = (28,29,50,55,61)


def bind(blob, loaded=False, address=ADDRESS):
    segments,publics=read_object(blob)
    if publics!=[(1,0,'init_object_sequences_')]:raise ValueError('Unexpected initializer public layout')
    if len(segments)<2 or segments[1]['cls']!='CODE' or len(segments[1]['data'])!=SIZE:
        raise ValueError('Expected one complete 18114-byte initializer')
    if any(len(s['data']) for s in segments[2:]):raise ValueError('Unexpected initializer allocated data')
    if read_externals(blob)!=[None,'_object_sequence_definitions']:
        raise ValueError('Unexpected initializer dependency')
    return bind_leaf_details(blob,'init_object_sequences_',
        {k:v+(0x80000 if loaded else 0) for k,v in DATA.items()},address=address)


def execute(code, address, initial):
    """Run only supplied initializer bytes; no EXE image or runtime calls needed."""
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_MEM_WRITE
    from unicorn.x86_const import (UC_X86_REG_EBX as BX, UC_X86_REG_ECX as CX,
        UC_X86_REG_EDX as DX, UC_X86_REG_ESI as SI, UC_X86_REG_EDI as DI,
        UC_X86_REG_EBP as BP, UC_X86_REG_ESP as SP, UC_X86_REG_EIP as IP)
    if len(initial)!=TABLE_SIZE:raise ValueError('Wrong descriptor table fixture size')
    uc=Uc(UC_ARCH_X86,UC_MODE_32);uc.mem_map(0,0x400000)
    uc.mem_write(address,code);uc.mem_write(TABLE,initial)
    writes={}
    def hook(machine,access,site,size,value,user):
        if 0x3fefe0<=site<0x3ff000:return
        if not TABLE<=site or site+size>TABLE+TABLE_SIZE or size!=2 or (site-TABLE)%2:
            raise AssertionError('Initializer wrote outside descriptor words')
        if site in writes:raise AssertionError('Duplicate descriptor write')
        writes[site]=value
    uc.hook_add(UC_HOOK_MEM_WRITE,hook)
    for reg in (BX,CX,DX,SI,DI,BP):uc.reg_write(reg,0x12345678)
    uc.reg_write(SP,0x3ff000);uc.mem_write(0x3ff000,struct.pack('<I',0x3fff00))
    uc.emu_start(address,0x3fff00,count=10000)
    assert uc.reg_read(IP)==0x3fff00 and uc.reg_read(SP)==0x3ff004
    assert all(uc.reg_read(reg)==0x12345678 for reg in (BX,CX,DX,SI,DI,BP))
    after=bytes(uc.mem_read(TABLE,TABLE_SIZE))
    changed_bytes={site-TABLE+j for site in writes for j in (0,1)}
    assert all(after[i]==initial[i] for i in range(TABLE_SIZE) if i not in changed_bytes)
    return after,writes


def compiled_descriptors(blob):
    """Return recover_sequences' selected row structure from compiled source only.

    Call verify(exe, blob) first when accepting a newly built object's exactness.
    This function never reads or runs FATE.EXE; untouched fields model zeroed BSS.
    """
    code,_=bind(blob,loaded=True,address=0x380000)
    table,writes=execute(code,0x380000,b'\0'*TABLE_SIZE)
    if len(writes)!=1956:raise ValueError('Wrong initializer store count')
    result={}
    for index in SELECTED:
        row=struct.unpack_from('<60h',table,index*120)
        result[index]=dict(start=row[0],end=row[1],final=row[2],next=row[3],
                           debris=list(row[4:52]),sounds=list(row[52:]))
    return result


def verify(exe,blob):
    """Verify explicit executable/object bytes; callers own file loading."""
    if hashlib.sha256(exe).hexdigest()!=EXPECTED:raise ValueError('Unsupported executable hash')
    code,refs=bind(blob)
    if code!=exe[ADDRESS+0x25600:ADDRESS+0x25600+SIZE]:raise ValueError('Sequence initializer code mismatch')
    verify_leaf_relocations(code,refs,read_le_fixups(exe)['pointers'],ADDRESS)
    original=image(exe)[ADDRESS:ADDRESS+SIZE]
    compiled,loaded_refs=bind(blob,loaded=True,address=0x380000)
    fixtures=[]
    write_values=None
    for name,initial in [('zero_bss',b'\0'*TABLE_SIZE),('nonzero_sentinel',b'\xa5'*TABLE_SIZE),
                         ('varying_words',bytes((i*73+19)&255 for i in range(TABLE_SIZE)))]:
        before,w1=execute(original,ADDRESS,initial)
        after,w2=execute(compiled,0x380000,initial)
        assert before==after and w1==w2
        assert set(w2)==set(loaded_refs.values()) and len(w2)==1956
        if write_values is not None:assert w2==write_values
        write_values=w2
        again,w3=execute(compiled,0x380000,after)
        assert again==after and w3==w2
        fixtures.append(dict(case=name,original_and_compiled_match=True,
                             repeat_idempotent=True,word_writes=len(w2),untouched_words=TABLE_SIZE//2-len(w2)))
    descriptors=compiled_descriptors(blob)
    assert {i:[descriptors[i][n] for n in ('start','end','final','next')] for i in SELECTED}=={
        28:[1516,1516,1516,29],29:[1517,1521,1521,0],50:[1014,1019,0,0],
        55:[1014,1019,0,0],61:[1408,1408,0,0]}
    rows=sorted({(site-TABLE)//120 for site in write_values})
    assert rows==list(range(1,74))
    return dict(executable_sha256=EXPECTED,object_sha256=hashlib.sha256(blob).hexdigest(),
        entry=hex(ADDRESS),end_exclusive=hex(ADDRESS+SIZE),bytes=SIZE,exact_code=True,
        original_le_targets=len(refs),relative_calls=0,initialized_data_bytes_added=0,
        table_object_offset='0x6807c',table_record_bytes=120,records_touched=rows,
        unique_word_stores=1956,compiled_fixture_address='0x380000',fixtures=fixtures,
        descriptor_provenance='compiled source with zeroed BSS; no original initializer execution',
        sequences=descriptors)


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('executable',type=Path);p.add_argument('object',type=Path)
    p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    a.output.write_text(json.dumps(verify(a.executable.read_bytes(),a.object.read_bytes()),indent=2)+'\n',encoding='utf-8')
    print('PASS: 18114 exact bytes, 1956 LE targets, 3 sentinel fixtures plus repeats; descriptors generated from compiled C')
