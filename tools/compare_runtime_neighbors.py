"""Compare bounded, explicitly delimited runtime bodies with pinned library members.

Library objects are dependency evidence only, never source reconstruction coverage.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_fixups, read_externals

LIBRARIES = {'105': '151fc7d895b171145466f77b1624d27952fa631971b0fc33d479e02eda3bbcc8',
             '110c': '6fb74d7e508f5839acf34586f56fd3d50431202db8257b666a0163e2ccddc7dd'}
# Explicit original function boundaries, not offsets extrapolated from anchors.
ROUTINES = [('accss', 'access_', 0x63130, 59), ('min', 'min_', 0x63201, 7),
            ('filelen', 'filelength_', 0x63208, 61), ('memcpy', 'memcpy_', 0x63245, 37),
            ('inp', 'inp_', 0x6326a, 8), ('fmemcpy', '_fmemcpy_', 0x63272, 40),
            ('strncpy', 'strncpy_', 0x6329a, 37), ('strncmp', 'strncmp_', 0x632bf, 41),
            ('div', 'div_', 0x632e8, 56), ('outpw', 'outpw_', 0x63320, 11)]
CALLS = {'lseek_': 0x615b6, '_dosret0_': 0x65711}


def compare(exe, archive, directory, revision):
    assert hashlib.sha256(exe).hexdigest() == TARGET_SHA256
    assert hashlib.sha256(archive).hexdigest() == LIBRARIES[revision]
    pointers = read_le_fixups(exe)['pointers']
    rows = []
    for filename, symbol, address, size in ROUTINES:
        if revision == '110c' and filename == 'div':
            filename = 'ldiv386'
        blob = (directory/(filename+'.obj')).read_bytes()
        archive_offset = archive.find(blob)
        assert archive_offset >= 0 and archive.find(blob, archive_offset+1) < 0
        segments, publics = read_object(blob)
        segment, start = [(seg, off) for seg, off, name in publics if name == symbol][0]
        assert start == 0 and segments[segment]['cls'] == 'CODE'
        # Includes aliases at the same start; compare the complete object CODE body.
        assert all(seg == segment and off == 0 for seg, off, name in publics)
        assert all(not s['data'] for i, s in enumerate(segments[1:], 1) if i != segment)
        code = bytearray(segments[segment]['data'])
        external_names = read_externals(blob)
        calls = []
        for fix in read_fixups(blob):
            # These bounded dependency objects use only self-relative calls.
            # Frame-by-target is valid here: both source and explicit target are
            # loaded CODE addresses, so the relative displacement cancels frame.
            assert fix.segment == segment and fix.location == 9 and fix.relative
            assert fix.frame == (5, None) and fix.target[0] == 2
            assert code[fix.offset-1] == 0xe8
            name = external_names[fix.target[1]]
            target = CALLS[name]
            addend = int.from_bytes(code[fix.offset:fix.offset+4], 'little')+fix.displacement
            assert addend == 0
            struct.pack_into('<I', code, fix.offset, (target-address-fix.offset-4)&0xffffffff)
            calls.append({'operand': hex(address+fix.offset), 'symbol': name, 'target': hex(target)})
        original = exe[address+0x25600:address+0x25600+size]
        assert not any(address <= site < address+size for site in pointers)
        differences = [i for i, (left, right) in enumerate(zip(code, original)) if left != right]
        rows.append(dict(symbol=symbol, object=filename+'.obj',
                         object_sha256=hashlib.sha256(blob).hexdigest(),
                         archive_member_offset=hex(archive_offset), loaded_address=hex(address),
                         raw_offset=hex(address+0x25600), original_bytes=size,
                         library_bytes=len(code), exact_body=bytes(code)==original,
                         differing_common_offsets=differences, relative_calls=calls,
                         original_le_pointers=0))
    return dict(library_sha256=LIBRARIES[revision], routines=rows,
                exact_dependency_bodies=sum(row['exact_body'] for row in rows),
                exact_dependency_bytes=sum(row['original_bytes'] for row in rows if row['exact_body']))


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable',type=Path)
    parser.add_argument('library105',type=Path)
    parser.add_argument('objects105',type=Path)
    parser.add_argument('library110c',type=Path)
    parser.add_argument('objects110c',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    exe=args.executable.read_bytes()
    results={rev:compare(exe,library.read_bytes(),directory,rev) for rev,library,directory in
             [('105',args.library105,args.objects105),('110c',args.library110c,args.objects110c)]}
    report=dict(target_sha256=TARGET_SHA256,source_coverage_change=0,
                original_runtime_identified=False,comparisons=results)
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    for revision,result in results.items():
        print(f"{revision}: {result['exact_dependency_bodies']} exact dependency bodies, "
              f"{result['exact_dependency_bytes']} bytes; source coverage unchanged")
