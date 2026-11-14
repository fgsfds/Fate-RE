"""Compare anchor-selected public spans excluding decoded OMF fixup fields.

Discovery only: target values and linker transformations are not validated.
"""
import argparse
import hashlib
import json
from pathlib import Path
from compare_exe import TARGET_SHA256
from match_objects import read_object, scan
from omf_fixups import read_fixups


def compare(blob, exe):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    code = exe[0x35600:0x35600+414639]
    segments, publics = read_object(blob)
    fixups = read_fixups(blob)
    masks = {}
    for fix in fixups:
        masks.setdefault(fix.segment, set()).update(range(fix.offset, fix.offset+fix.width))
    rows = []
    for hit in scan(blob, code):
        start = int(hit['object_offset'], 16)
        seg, = [s for s, a, n in publics if a == start and n == hit['symbol']]
        target = int(hit['candidate_address'], 16)-0x10000
        end = start + hit['public_span']
        if target < 0 or target+end-start > len(code):
            continue
        offsets = [i for i in range(start, end) if i not in masks.get(seg, set())]
        different = [i-start for i in offsets
                     if segments[seg]['data'][i] != code[target+i-start]]
        rows.append(dict(**hit, compared_bytes=len(offsets),
                         masked_bytes=end-start-len(offsets),
                         differing_bytes=len(different), first_differences=different[:8]))
    return dict(object_sha256=hashlib.sha256(blob).hexdigest(),
                fixup_count=len(fixups), spans=rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = compare(args.object.read_bytes(), args.executable.read_bytes())
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print('fixups:', result['fixup_count'], 'spans:', len(result['spans']),
          'equal outside fixups:', sum(r['differing_bytes'] == 0 for r in result['spans']))
