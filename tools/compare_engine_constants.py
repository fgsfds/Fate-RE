"""Explain the October engine CONST shift without exporting original strings."""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
from compare_exe import TARGET_SHA256
from match_objects import read_object

OBJECT_SHA256 = 'e2fed37d656b26ff6e8faefc1052b83c7379269f16795fcf8298b5632283e721'


def strings(data):
    result, offset = [], 0
    while offset < len(data):
        end = data.index(0, offset)+1
        result.append((offset, data[offset:end]))
        offset = end
    return result


def compare(exe, obj):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    if hashlib.sha256(obj).hexdigest() != OBJECT_SHA256:
        raise ValueError('Unknown October ENGINE.OBJ')
    segments, _ = read_object(obj)
    source = bytes(segments[2]['data'])
    if segments[2]['name'] != 'CONST':
        raise ValueError('Unexpected segment')
    # Derived from verified VBE and showengineinfo absolute target constraints.
    target_base = 0x81944
    source_last = 323
    target_last = 0x81bdf
    target_file = 0x9b600+target_base-0x80000
    target_size = target_last-target_base+len(source)-source_last
    target = exe[target_file:target_file+target_size]
    old, new = strings(source), strings(target)
    matcher = difflib.SequenceMatcher(None, [s for _, s in old],
                                     [s for _, s in new], autojunk=False)
    blocks = []
    for kind, a, b, c, d in matcher.get_opcodes():
        blocks.append(dict(kind=kind, source_offsets=[hex(o) for o, _ in old[a:b]],
                           target_addresses=[hex(target_base+o) for o, _ in new[c:d]],
                           target_sizes=[len(s) for _, s in new[c:d]],
                           target_sha256=[hashlib.sha256(s).hexdigest() for _, s in new[c:d]]))
    return dict(executable_sha256=TARGET_SHA256, object_sha256=OBJECT_SHA256,
                source_bytes=len(source), target_bytes=len(target),
                source_strings=len(old), target_strings=len(new), blocks=blocks)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    result = compare(args.executable.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print({k: v for k, v in result.items() if k != 'blocks'})
    print('block operations:', [b['kind'] for b in result['blocks']])
