"""Bounded scalar payload proof; no complete MULTI data-layout claim."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_fixups
from research_startup import layout, require

SCALARS=[('_syncstate',0,1,0x13cdc),('_hangup',1,1,0x13cdd),
         ('_multioption',2,1,0x13cde),('_comrateoption',3,1,0x13cdf),
         ('_numplayers',4,2,0x13ce0),('_myconnectindex',6,2,0x13ce2),
         ('_socket',8,2,0x13e64)]


def verify_object(blob):
    segments,publics=read_object(blob);initialized,groups=layout(blob)
    populated=[i for i,s in enumerate(segments) if s and len(s['data'])]
    require(len(populated)==1,'Extra nonempty segment')
    seg=populated[0]
    require(segments[seg]['name']=='_DATA' and segments[seg]['cls']=='DATA', 'Not scalar DATA')
    require(len(segments[seg]['data'])==10 and initialized=={seg:set(range(10))},'Incorrect complete DATA extent')
    require(sorted(publics)==sorted((seg,o,n) for n,o,z,a in SCALARS),'Wrong public layout')
    require(not read_fixups(blob),'Unexpected scalar fixup')
    return bytes(segments[seg]['data'])


def verify(exe,blob):
    require(hashlib.sha256(exe).hexdigest()==TARGET_SHA256,'Unknown executable')
    generated=verify_object(blob);pointers=read_le_fixups(exe)['pointers']
    header=struct.unpack_from('<I',exe,60)[0]
    def field(o):return struct.unpack_from('<I',exe,header+o)[0]
    objects=[struct.unpack_from('<6I',exe,header+field(0x40)+24*i) for i in range(field(0x44))]
    owner,=[o for o in objects if o[1]==0x80000]
    rows=[];ranges=[]
    for name,offset,size,ds in SCALARS:
        page,within=divmod(ds,4096);slot=header+field(0x48)+(owner[3]+page-1)*4
        physical=int.from_bytes(exe[slot:slot+3],'big')
        require(page<owner[4] and physical and exe[slot+3]==0 and within+size<=4096,'Unsupported physical range')
        raw=field(0x80)+(physical-1)*4096+within
        require(raw+size<=len(exe) and generated[offset:offset+size]==exe[raw:raw+size],'Scalar payload mismatch')
        require(not any(ds+0x80000<=s<ds+0x80000+size for s in pointers),'Unexpected scalar LE relocation')
        ranges.append((raw,raw+size));rows.append(dict(symbol=name,ds_offset=hex(ds),raw_offset=hex(raw),bytes=size))
    require(all(a[1]<=b[0] for a,b in zip(sorted(ranges),sorted(ranges)[1:])),'Overlapping original ranges')
    return dict(target_sha256=TARGET_SHA256,object_sha256=hashlib.sha256(blob).hexdigest(),
                strict_initialized_scalar_bytes=10,distinct_original_ranges=2,scalars=rows,
                source_code_coverage_change=0,whole_module_layout_match=False,bss_initialized_coverage=0)


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('executable',type=Path)
    p.add_argument('object',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    result=verify(a.executable.read_bytes(),a.object.read_bytes())
    a.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS: 10 scalar bytes in two distinct original ranges; no full module/BSS coverage claim')
