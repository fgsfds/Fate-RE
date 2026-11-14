"""Pinned startup dependency research; inferred relocation bindings are not linkage proof."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from compare_exe import TARGET_SHA256
from compare_runtime_neighbors import LIBRARIES
from le_fixups import read_le_fixups
from match_objects import read_object, index
from omf_fixups import read_fixups, read_externals


def require(condition, message):
    if not condition:
        raise ValueError(message)


def provenance(archive, blob, revision):
    require(hashlib.sha256(archive).hexdigest() == LIBRARIES[revision], 'Unknown library')
    offset = archive.find(blob)
    require(bool(blob) and offset >= 0 and archive.find(blob, offset+1) < 0,
            'Object must occur verbatim exactly once in pinned library')
    return dict(library_sha256=LIBRARIES[revision], object_sha256=hashlib.sha256(blob).hexdigest(),
                archive_member_offset=hex(offset))


def layout(blob, *, allow_local_symbols=False):
    """Reject unexamined payload forms; distinguish reservations from LEDATA."""
    initialized, groups, names = {}, [], ['']
    cursor = 0
    while cursor < len(blob):
        kind = blob[cursor]
        length = int.from_bytes(blob[cursor+1:cursor+3], 'little')
        end = cursor+3+length
        require(length > 0 and end <= len(blob), 'Invalid record bounds')
        data = blob[cursor+3:end-1]
        require(kind in (0x80,0x88,0x96,0x98,0x99,0x9a,0x8c,0x90,0x91,
                         0xa0,0xa1,0x9c,0x9d,0x8a,0x8b)
                or (allow_local_symbols and kind in (0xb4,0xb7)), 'Unexamined OMF record')
        if kind == 0x96:
            pos = 0
            while pos < len(data):
                n = data[pos]; names.append(data[pos+1:pos+1+n].decode('ascii')); pos += n+1
        elif kind == 0x9a:
            name, pos = index(data, 0)
            members = []
            while pos < len(data):
                require(data[pos] == 0xff, 'Unsupported group component')
                seg, pos = index(data, pos+1); members.append(seg)
            groups.append(dict(name=names[name], segments=members))
        elif kind in (0xa0,0xa1):
            seg, pos = index(data,0); width = 4 if kind & 1 else 2
            start = int.from_bytes(data[pos:pos+width], 'little')
            sites = set(range(start,start+len(data)-pos-width))
            require(not sites & initialized.get(seg,set()), 'Overlapping LEDATA')
            initialized.setdefault(seg,set()).update(sites)
        cursor = end
    return initialized, groups


def analyze(exe, archive, blob, revision):
    result = provenance(archive, blob, revision)
    require(hashlib.sha256(exe).hexdigest() == TARGET_SHA256, 'Unknown executable')
    header = struct.unpack_from('<I',exe,60)[0]
    entry_object, entry_offset = struct.unpack_from('<II',exe,header+0x18)
    table = header+struct.unpack_from('<I',exe,header+0x40)[0]
    objects = [struct.unpack_from('<6I',exe,table+24*i) for i in range(struct.unpack_from('<I',exe,header+0x44)[0])]
    def loaded_payload(start, size):
        owner, = [o for o in objects if o[1] <= start and start+size <= o[1]+o[0]]
        output = bytearray()
        while size:
            page, within = divmod(start-owner[1],4096)
            require(page < owner[4], 'Uninitialized LE page')
            entry = header+struct.unpack_from('<I',exe,header+0x48)[0]+(owner[3]+page-1)*4
            physical = int.from_bytes(exe[entry:entry+3],'big')
            require(physical and exe[entry+3] == 0, 'Expected physical LE page')
            raw = struct.unpack_from('<I',exe,header+0x80)[0]+(physical-1)*4096+within
            count = min(size,4096-within)
            require(raw+count <= len(exe), 'Truncated physical payload')
            output.extend(exe[raw:raw+count]); start += count; size -= count
        return bytes(output)
    address = objects[entry_object-1][1]+entry_offset
    require(address == 0x5ff08, 'Unexpected independent LE entry')
    segments, publics = read_object(blob)
    initialized, groups = layout(blob)
    require((1,0,'_cstart_') in publics, 'Startup public absent')
    code = segments[1]['data']; original = loaded_payload(address,len(code))
    require(initialized[1] == set(range(len(code))), 'Incomplete startup CODE')
    fixes = read_fixups(blob); externals = read_externals(blob)
    mask = set()
    for f in fixes:
        require(f.segment == 1 and f.width == 4 and f.location == 9, 'Unexpected fixup shape')
        sites = set(range(f.offset,f.offset+4))
        require(not sites & mask and max(sites) < len(code), 'Overlapping/outside fixup')
        mask.update(sites)
    differences = [i for i in range(len(code)) if i not in mask and code[i] != original[i]]
    result.update(entry_loaded=hex(address), code_bytes=len(code), groups=groups,
                  nonfixup_differing_offsets=differences, exact_dependency_match=False,
                  source_coverage_change=0)
    if revision != '105':
        result['relocation_constraints'] = 'Not inferred: nonfixup structure differs'
        return result
    require(len(code) == 727 and differences == [86], 'Changed 105 startup observation')
    pointers = read_le_fixups(exe)['pointers']; bindings = {}; rows = []
    expected_sites = {address+f.offset for f in fixes if not f.relative}
    require({s for s in pointers if address <= s < address+len(code)} == expected_sites,
            'LE site set differs from absolute OMF fixup set')
    for f in fixes:
        require(f.frame in ((5,None),(1,1)) and f.target[0] in (0,2), 'Unexamined frame/target')
        key = ('segment:' + str(f.target[1])) if f.target[0] == 0 else externals[f.target[1]]
        addend = int.from_bytes(code[f.offset:f.offset+4],'little')+f.displacement
        operand = int.from_bytes(original[f.offset:f.offset+4],'little')
        if f.relative:
            require(code[f.offset-1] == original[f.offset-1] == 0xe8, 'Not relative CALL')
            target = (address+f.offset+4+operand)&0xffffffff
            frame_base = None
        else:
            target = pointers[address+f.offset]
            owner, = [o for o in objects if o[1] <= target < o[1]+o[0]]
            frame_base = owner[1]
            require(frame_base in (0x10000,0x80000) and target == frame_base+operand,
                    'LE target/unrelocated operand base mismatch')
        inferred = (target-addend)&0xffffffff
        require(key not in bindings or bindings[key] == inferred, 'Inconsistent repeated binding')
        bindings[key] = inferred
        rows.append(dict(offset=f.offset, symbol_or_segment=key, frame=list(f.frame),
                         target=list(f.target), relative=f.relative, addend=addend,
                         inferred_loaded_target=hex(target), frame_base=hex(frame_base) if frame_base else None))
    require(bindings['segment:1'] == address, 'Internal CODE base disagrees with LE entry')
    payloads = []
    for seg in (2,3,4,18):
        data = segments[seg]['data']; anchor = bindings.get('segment:'+str(seg))
        item = dict(segment=seg,name=segments[seg]['name'],reserved_bytes=len(data),
                    initialized_bytes=len(initialized.get(seg,set())), inferred_address=hex(anchor) if anchor else None)
        if anchor is not None:
            require(initialized[seg] == set(range(len(data))), 'Incomplete anchored payload')
            require(not any(anchor <= s < anchor+len(data) for s in pointers), 'Unexpected payload LE fixup')
            item['equal_at_inferred_address'] = data == loaded_payload(anchor,len(data))
        payloads.append(item)
    result.update(hypothesized_bindings={k:hex(v) for k,v in bindings.items()},
                  relocation_constraints=rows, absolute_le_sites=len(expected_sites),
                  relative_calls=sum(f.relative for f in fixes), segment_payloads=payloads,
                  copyright_year_difference=dict(object='1995',original='1994',offset=86))
    return result


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('executable',type=Path)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args()
    root=Path(__file__).resolve().parents[1]
    libraries={'105':'reference/watcom105-full/LIB386/DOS/CLIB3R.LIB',
               '110c':'reference/watcom110c/lib386/dos/clib3r.lib'}
    report=dict(target_sha256=TARGET_SHA256,source_coverage_change=0,original_runtime_identified=False,
                comparisons={rev:analyze(a.executable.read_bytes(),(root/path).read_bytes(),
                             (root/f'work/clib{rev}'/('cstrt386.obj' if rev == '105' else 'cstart.obj')).read_bytes(),rev)
                             for rev,path in libraries.items()})
    a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Startup dependency research complete; zero source coverage added.')
