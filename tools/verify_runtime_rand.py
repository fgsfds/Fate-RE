"""Verify the Watcom 10.5 rand/srand dependency used by object sequences."""
import hashlib
import struct

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from research_startup import layout, provenance, require
from verify_c_leaf import verify_leaf_relocations

ADDRESS, SEED = 0x602ca, 0x141a4


def bind(exe, archive, blob):
    require(hashlib.sha256(exe).hexdigest()==TARGET_SHA256, 'Unknown FATE.EXE')
    provenance(archive, blob, '105')
    segments, publics = read_object(blob)
    initialized, _ = layout(blob, allow_local_symbols=True)
    cursor, local_publics = 0, []
    while cursor<len(blob):
        end = cursor+3+int.from_bytes(blob[cursor+1:cursor+3],'little')
        if blob[cursor]==0xb7:
            local_publics.append(blob[cursor+3:end-1])
        cursor = end
    require(local_publics==[b'\0\x01\rinitrandnext_'+bytes(5),
                            b'\x01\x04\x05_next'+bytes(5)], 'Unexpected local symbol layout')
    code = bytearray(segments[1]['data'])
    require(publics==[(1,6,'rand_'),(1,42,'srand_')] and len(code)==58
            and segments[1]['cls']=='CODE', 'Unexpected random CODE layout')
    require(initialized=={1:set(range(58)),4:set(range(4))}, 'Unexpected initialized extents')
    require(segments[4]['name']=='_DATA' and segments[4]['cls']=='DATA'
            and bytes(segments[4]['data'])==struct.pack('<I',1)
            and exe[0xaf7a4:0xaf7a8]==struct.pack('<I',1), 'Random seed differs')
    names = read_externals(blob)
    fixes = read_fixups(blob)
    require(len(fixes)==3, 'Wrong random fixup count')
    fields = set()
    for fix in fixes:
        require(fix.segment==1 and fix.width==4 and fix.location==9
                and fix.frame==(5,None) and fix.displacement==0 and fix.target[0]==2,
                'Unsupported random fixup')
        off = fix.offset
        require(off not in fields and 1<=off<=54 and code[off:off+4]==bytes(4),
                'Unexpected random fixup field')
        fields.add(off)
        if off==1:
            require(not fix.relative and names[fix.target[1]]=='_next', 'Unexpected seed reference')
            struct.pack_into('<I',code,off,SEED)
        else:
            require(off in (8,46) and fix.relative and code[off-1]==0xe8
                    and names[fix.target[1]]=='initrandnext_', 'Unexpected seed accessor call')
            struct.pack_into('<i',code,off,-off-4)
    require(fields=={1,8,46} and code==exe[0x858ca:0x85904], 'Random dependency bytes differ')
    verify_leaf_relocations(code,{1:SEED},read_le_fixups(exe)['pointers'],ADDRESS)
    struct.pack_into('<I',code,1,0x80000+SEED)
    return bytes(code)
