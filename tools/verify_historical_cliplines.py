"""Verify the pinned October 1995 getcliplines object as a binary dependency."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from verify_c_leaf import verify_leaf_relocations

OBJECT_SHA256 = 'e2fed37d656b26ff6e8faefc1052b83c7379269f16795fcf8298b5632283e721'
ENTRY, SIZE, RAW, OFFSET = 0x52c88, 3941, 0x78288, 0xeef8
DATA = {
    '_clipnum': 0x289136, '_sqrtable': 0x1dfa60, '_clipsectnum': 0x28912e,
    '_clipsectorlist': 0x195f50, '_sector': 0x27c3a0, '_wall': 0x2310a0,
    '_editstatus': 0x14185, '_headspritesect': 0x28891e, '_sprite': 0x2040a0,
    '_tilesizy': 0x1f4020, '_picanm': 0x1ed3a0, '_sintable': 0x2300a0,
    '_tilesizx': 0x1f2020, '_rxi': 0x1990b0, '_ryi': 0x199110,
    '_nextspritesect': 0x1f9ca0,
}
CALLS = {
    'rintersect_': 0x5272c, 'getflorzofslope_': 0x5df75,
    'getceilzofslope_': 0x5de70, 'addclipline_': 0x53bed,
    'clipinsideboxline_': 0x4c1b2,
}


def bind_verified(exe, blob):
    return bind_span(exe, blob, 'getcliplines_', 'addclipline_', OFFSET,
                     ENTRY, SIZE, DATA, CALLS, 106, 19, 0x5299e)


def bind_span(exe, blob, name, next_name, offset, entry, size,
              data, functions, le_count, call_count, incoming, shared_return=None):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    if hashlib.sha256(blob).hexdigest() != OBJECT_SHA256:
        raise ValueError('Unknown historical ENGINE.OBJ')
    segments, publics = read_object(blob)
    public = (1, offset, name)
    following = (1, offset+size, next_name)
    if public not in publics or following not in publics or segments[1]['cls'] != 'CODE':
        raise ValueError('Historical object boundaries differ')
    if incoming is not None:
        site = incoming+0x25600
        if exe[site]!=0xe8 or incoming+5+struct.unpack_from('<i',exe,site+1)[0]!=entry:
            raise ValueError('Original incoming call target differs')
    source = segments[1]['data']
    body = bytearray(source[offset:offset+size])
    externals = read_externals(blob)
    references, calls = {}, {}
    sites = set()
    for fixup in read_fixups(blob):
        if fixup.segment!=1 or not offset <= fixup.offset < offset+size:
            continue
        off = fixup.offset-offset
        if (fixup.location!=9 or fixup.width!=4 or fixup.frame!=(1,2)
                or fixup.target[0]!=2 or fixup.displacement!=0 or off in sites
                or off+4>size):
            raise ValueError('Unsupported historical relocation')
        sites.add(off)
        name = externals[fixup.target[1]]
        addend = struct.unpack_from('<i',body,off)[0]
        if fixup.relative:
            if off==0 or body[off-1]!=0xe8 or addend!=0:
                raise ValueError('Unsupported historical call')
            target = functions[name]
            struct.pack_into('<i',body,off,target-(entry+off+4))
            calls[off] = name
        else:
            value = data[name]+addend
            struct.pack_into('<I',body,off,value)
            references[off] = value
    if shared_return is not None:
        object_tail, target = shared_return
        if (body[-5]!=0xe9 or any(site>=size-5 for site in sites)
                or offset+size+struct.unpack_from('<i',body,size-4)[0]!=object_tail
                or source[object_tail:object_tail+6]!=exe[target+0x25600:target+0x25606]):
            raise ValueError('Historical shared return differs')
        # Resolve the branch between two routines using their verified placements.
        struct.pack_into('<i',body,size-4,target-(entry+size))
    raw = entry+0x25600
    if len(references)!=le_count or len(calls)!=call_count or body!=exe[raw:raw+size]:
        raise ValueError(f'Historical {name} span differs')
    verify_leaf_relocations(body,references,read_le_fixups(exe)['pointers'],entry)
    return bytes(body), references


def verify(exe, blob):
    body, references = bind_verified(exe, blob)
    return dict(executable_sha256=TARGET_SHA256, object_sha256=OBJECT_SHA256,
                symbol='getcliplines_', address=hex(ENTRY), bytes=SIZE,
                le_targets=len(references), relative_calls=19,
                data_bindings={k:hex(v) for k,v in DATA.items()},
                call_bindings={k:hex(v) for k,v in CALLS.items()},
                reconstructed_source_bytes=0, complete_original_module=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    report = verify(args.executable.read_bytes(),args.object.read_bytes())
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS: historical getcliplines dependency, 3,941 bytes, 106 LE targets, 19 calls')
