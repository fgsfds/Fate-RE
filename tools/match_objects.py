"""Find exact 24-byte OMF code anchors in pinned FATE.EXE.

Discovery only: relocation fields are not resolved, and anchor matches are not
proof that a whole function/object matches. Never count these as rebuilt bytes.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
from compare_exe import TARGET_SHA256


def index(data, offset):
    value = data[offset]
    if value & 128:
        return ((value & 127) << 8) | data[offset+1], offset+2
    return value, offset+1


def read_object(blob):
    names = ['']
    segments = [None]
    publics = []
    offset = 0
    while offset < len(blob):
        kind = blob[offset]
        length = int.from_bytes(blob[offset+1:offset+3], 'little')
        end = offset+3+length
        if length < 1 or end > len(blob):
            raise ValueError('Truncated OMF record')
        if blob[end-1] and sum(blob[offset:end]) & 255:
            raise ValueError('Invalid OMF checksum')
        data = blob[offset+3:end-1]
        if kind == 0x96:
            cursor = 0
            while cursor < len(data):
                size = data[cursor]
                names.append(data[cursor+1:cursor+1+size].decode('ascii'))
                cursor += size+1
        elif kind in (0x98, 0x99):
            cursor = 1
            if data[0] >> 5 == 0:
                cursor += 3
            width = 4 if kind & 1 else 2
            size = int.from_bytes(data[cursor:cursor+width], 'little')
            cursor += width
            name, cursor = index(data, cursor)
            cls, cursor = index(data, cursor)
            segments.append(dict(name=names[name], cls=names[cls], data=bytearray(size)))
        elif kind in (0xa0, 0xa1):
            seg, cursor = index(data, 0)
            width = 4 if kind & 1 else 2
            start = int.from_bytes(data[cursor:cursor+width], 'little')
            payload = data[cursor+width:]
            if start+len(payload) > len(segments[seg]['data']):
                raise ValueError('LEDATA exceeds segment')
            segments[seg]['data'][start:start+len(payload)] = payload
        elif kind in (0x90, 0x91):
            group, cursor = index(data, 0)
            seg, cursor = index(data, cursor)
            if seg == 0:
                cursor += 2
            width = 4 if kind & 1 else 2
            while cursor < len(data):
                size = data[cursor]
                name = data[cursor+1:cursor+1+size].decode('ascii')
                cursor += size+1
                address = int.from_bytes(data[cursor:cursor+width], 'little')
                cursor += width
                type_index, cursor = index(data, cursor)
                publics.append((seg, address, name))
        elif kind in (0xa2, 0xa3):
            raise ValueError('LIDATA not supported')
        offset = end
    return segments, publics


def scan(blob, code):
    segments, publics = read_object(blob)
    matches = []
    for seg, start, name in publics:
        if seg == 0 or segments[seg]['cls'] != 'CODE':
            continue
        block = bytes(segments[seg]['data'])
        end = min([a for s, a, n in publics if s == seg and a > start] or [len(block)])
        votes = Counter()
        for off in range(start, end-23, 8):
            anchor = block[off:off+24]
            if len(set(anchor)) < 6:
                continue
            found = code.find(anchor)
            if found >= 0 and code.find(anchor, found+1) < 0:
                votes[found-(off-start)] += 1
        if votes:
            candidate, count = votes.most_common(1)[0]
            matches.append(dict(symbol=name, object_offset=hex(start),
                                candidate_address=hex(candidate+0x10000),
                                anchor_votes=count, public_span=end-start))
    return matches


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('objects', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    exe = args.executable.read_bytes()
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    code = exe[0x35600:0x35600+414639]
    result = {}
    for path in sorted(args.objects.rglob('*.OBJ')):
        blob = path.read_bytes()
        hits = scan(blob, code)
        result[str(path.relative_to(args.objects))] = dict(
            sha256=hashlib.sha256(blob).hexdigest(), matches=hits)
        print(path.parent.name, path.name, len(hits), 'public symbols with exact anchors')
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
