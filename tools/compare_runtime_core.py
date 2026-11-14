"""Whole bounded runtime dependencies, never reconstructed source coverage."""
import argparse
import json
from pathlib import Path
import struct
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from research_startup import provenance, layout, require

DATA = {'__ASTACKSIZ':0x14484,'__ASTACKPTR':0x14488,
        '____Argv':0x289250,'____Argc':0x28924c,
        'XIB':0x199b4,'XIE':0x199d8,'YIB':0x199d8,'YIE':0x199e4}
CALLS = {'stackavail_':0x67006,'__CommonInit_':0x67474,'main_':0x1002c,
         'exit_':0x60353,'__STOSB':0x62de0}
UNITS = [('cmain386',0x6332b,79,[('__CMain',0)]),
         ('inirt386',0x6337a,154,[('__InitRtns',0),('__FiniRtns',75)]),
         ('set386',0x61350,24,[('memset_',0)]),
         ('__stos',0x62de0,163,[('__STOSB',0),('__STOSD',55)])]


def compare(exe, archive, blob, revision, address, size, expected_publics, exact_candidate):
    report=provenance(archive,blob,revision)
    if not exact_candidate and revision=='110c' and address==0x6336e:
        report.update(exact_dependency_body=False, source_coverage_change=0,
                      comparison_kind='Not compared: local PUBDEF/EXTDEF records B7/B4 require a dedicated decoder')
        return report
    segments,publics=read_object(blob); initialized,groups=layout(blob)
    code=bytearray(segments[1]['data']); original=exe[address+0x25600:address+0x25600+size]
    require(segments[1]['cls']=='CODE' and initialized[1]==set(range(len(code))), 'Incomplete CODE')
    require(all(len(s['data'])==0 for s in segments[2:]), 'Unexpected other segment extent')
    fixes=read_fixups(blob); names=read_externals(blob); pointers=read_le_fixups(exe)['pointers']
    report.update(loaded_address=hex(address),original_bytes=size,object_code_bytes=len(code),
                  publics=[dict(name=n,offset=o,segment=s) for s,o,n in publics],groups=groups,
                  source_coverage_change=0)
    if not exact_candidate:
        mask={i for f in fixes for i in range(f.offset,f.offset+f.width)}
        report.update(exact_dependency_body=False,
                      common_nonfixup_differing_offsets=[i for i in range(min(len(code),size)) if i not in mask and code[i]!=original[i]],
                      comparison_kind='Negative structural comparison; no bindings accepted')
        return report
    require(len(code)==size and sorted(publics)==sorted((1,o,n) for n,o in expected_publics), 'Public/body bounds differ')
    sites=set(); rows=[]; occupied=set()
    for f in fixes:
        require(f.segment==1 and f.width==4 and f.location==9 and f.frame in ((5,None),(1,1)), 'Unsupported fixup')
        field=set(range(f.offset,f.offset+4))
        require(not field&occupied and max(field)<size, 'Overlapping/outside fixup'); occupied|=field
        require(f.target[0] in (0,2), 'Unsupported target')
        name=names[f.target[1]] if f.target[0]==2 else segments[f.target[1]]['name']
        addend=int.from_bytes(code[f.offset:f.offset+4],'little')+f.displacement
        require(addend==0, 'Unexpected addend')
        if f.relative:
            require(code[f.offset-1]==0xe8 and f.target[0]==2, 'Unsupported relative fixup')
            target=CALLS[name]; value=(target-address-f.offset-4)&0xffffffff
        else:
            value=DATA[name]; target=0x80000+value; sites.add(address+f.offset)
            require(pointers.get(address+f.offset)==target, 'Wrong original LE target')
        struct.pack_into('<I',code,f.offset,value)
        rows.append(dict(offset=f.offset,symbol=name,relative=f.relative,target_loaded=hex(target)))
    require({s for s in pointers if address<=s<address+size}==sites, 'Unexpected LE site set')
    report.update(exact_dependency_body=bytes(code)==original,
                  differing_offsets=[i for i in range(size) if code[i]!=original[i]],
                  absolute_le_sites=len(sites),bindings=rows,
                  comparison_kind='Whole object CODE with explicit bindings and complete LE-site check')
    return report


def tables(exe):
    """Describe original XI/YI six-byte records; do not claim library payload match."""
    header=struct.unpack_from('<I',exe,60)[0]
    def field(o):return struct.unpack_from('<I',exe,header+o)[0]
    objects=[struct.unpack_from('<6I',exe,header+field(0x40)+i*24) for i in range(field(0x44))]
    owner,=[o for o in objects if o[1]==0x80000]
    pointers=read_le_fixups(exe)['pointers']; rows=[]
    for name,start,end in [('XI',0x199b4,0x199d8),('YI',0x199d8,0x199e4)]:
        require((end-start)%6==0,'Partial table entry')
        expected=set(); entries=[]
        for offset in range(start,end,6):
            page,within=divmod(offset,4096); slot=header+field(0x48)+(owner[3]+page-1)*4
            physical=int.from_bytes(exe[slot:slot+3],'big')
            require(physical and exe[slot+3]==0 and within+6<=4096,'Unbacked table')
            raw=field(0x80)+(physical-1)*4096+within
            if raw+6>len(exe):
                site=0x80000+offset+2
                require(raw<len(exe) and site in pointers, 'Unexpected truncated table')
                expected.add(site)
                entries.append(dict(ds_offset=hex(offset),raw_offset=hex(raw),
                                    present_bytes=len(exe)-raw,required_bytes=6,
                                    target_loaded=hex(pointers[site]),
                                    status='Truncated physical record; operand equality not checked'))
                continue
            kind,priority,operand=struct.unpack_from('<BBI',exe,raw)
            site=0x80000+offset+2
            if operand:
                expected.add(site); require(pointers.get(site)==operand+0x10000,'Table CODE pointer mismatch')
            entries.append(dict(ds_offset=hex(offset),kind=kind,priority=priority,
                                target_loaded=hex(operand+0x10000) if operand else None))
        require({s for s in pointers if 0x80000+start<=s<0x80000+end}==expected,'Extra table LE pointer')
        rows.append(dict(name=name,start_ds=hex(start),end_ds=hex(end),bytes=end-start,
                         entries=entries,library_payload_match=False))
    return rows


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('executable',type=Path)
    p.add_argument('--output',type=Path,required=True);a=p.parse_args();exe=a.executable.read_bytes()
    root=Path(__file__).resolve().parents[1];results={}
    for rev,path in [('105','reference/watcom105-full/LIB386/DOS/CLIB3R.LIB'),('110c','reference/watcom110c/lib386/dos/clib3r.lib')]:
        archive=(root/path).read_bytes();rows=[]
        for filename,address,size,publics in UNITS:
            name=({'inirt386':'initrtns','set386':'memset'}.get(filename,filename) if rev=='110c' else filename)
            blob=(root/f'work/clib{rev}/{name}.obj').read_bytes()
            # 110c InitRtns is at12; align its public to the independently known entry.
            if rev=='110c' and filename=='inirt386': address-=12;size+=12
            row=compare(exe,archive,blob,rev,address,size,publics,rev=='105' or filename in ('set386','__stos'))
            row['member']=name+'.obj';rows.append(row)
        results[rev]=rows
    report=dict(target_sha256=TARGET_SHA256,source_coverage_change=0,original_runtime_identified=False,
                comparisons=results,original_initializer_tables=tables(exe))
    a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    for rev,rows in results.items():
        print(rev, sum(r['original_bytes'] for r in rows if r['exact_dependency_body']),
              'exact dependency CODE bytes; source coverage unchanged')
