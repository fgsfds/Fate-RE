"""Guard complete compact, indexed and destination actor compiler contexts."""
import hashlib
import json
from pathlib import Path

LAYOUT = json.loads((Path(__file__).parent/'data/board-actor-layout.json').read_text(encoding='utf-8'))
INDEXED_LAYOUT = json.loads((Path(__file__).parent/'data'/LAYOUT['indexed_context_file']).read_text(encoding='utf-8'))
INDEXED_PUBLIC = INDEXED_LAYOUT['context']['public']
DESTINATION_LAYOUT = json.loads((Path(__file__).parent/'data'/LAYOUT['destination_context_file']).read_text(encoding='utf-8'))
DESTINATION_PUBLIC = DESTINATION_LAYOUT['context']['public']
PUBLICS = frozenset([p[2] for p in LAYOUT['publics']] + [INDEXED_PUBLIC, DESTINATION_PUBLIC])
GROUP_SHA256 = LAYOUT['sha256']
INDEXED_SHA256 = INDEXED_LAYOUT['context']['sha256']
DESTINATION_SHA256 = DESTINATION_LAYOUT['context']['sha256']


def structural_records(blob):
    """Keep public groups/types and complete segment/external definitions."""
    records = []; cursor = 0
    while cursor < len(blob):
        kind = blob[cursor]
        size = int.from_bytes(blob[cursor+1:cursor+3], 'little')
        end = cursor+3+size
        if size < 1 or end > len(blob):
            raise ValueError('Truncated board actor OMF record')
        if kind in (0x8c, 0x90, 0x91, 0x96, 0x98, 0x99, 0x9a):
            if sum(blob[cursor:end]) & 255:
                raise ValueError('Board actor structural OMF checksum differs')
            records.append([kind, bytes(blob[cursor+3:end-1]).hex()])
        cursor = end
    return records


def verify_context(blob, public_name=None):
    from verify_c_leaf import parsed_leaf_object
    segments, publics, names, flat, fixups = parsed_leaf_object(blob)
    if public_name is None:
        public_name = next((p[2] for p in publics if p[2] in (INDEXED_PUBLIC, DESTINATION_PUBLIC)), None)
    if public_name == DESTINATION_PUBLIC:
        layout, digest = DESTINATION_LAYOUT['context'], DESTINATION_SHA256
    elif public_name == INDEXED_PUBLIC:
        layout, digest = INDEXED_LAYOUT['context'], INDEXED_SHA256
    else:
        layout, digest = LAYOUT, GROUP_SHA256
    if [list(p) for p in publics] != layout['publics']:
        raise ValueError('Board actor public layout differs')
    if structural_records(blob) != layout['structure']:
        raise ValueError('Board actor structural OMF metadata differs')
    observed_segments = [[i, s['cls'], len(s['data'])]
                         for i, s in enumerate(segments) if s is not None]
    if observed_segments != layout['segments']:
        raise ValueError('Board actor segment layout differs')
    raw = bytes(segments[1]['data'])
    if digest is not None and hashlib.sha256(raw).hexdigest() != digest:
        raise ValueError('Board actor complete context digest differs')
    if any(f.target[0] == 2 and not 0 < f.target[1] < len(names) for f in fixups):
        raise ValueError('Board actor external index out of range')
    records = [[f.segment, f.offset, f.width, f.location, f.relative,
                list(f.frame), list(f.target), f.displacement,
                names[f.target[1]] if f.target[0] == 2 else None] for f in fixups]
    if sorted(flat) != layout['records']['flat_groups'] or records != layout['records']['fixups']:
        raise ValueError('Board actor complete fixup records differ')
    addends = {str(f.offset): int.from_bytes(raw[f.offset:f.offset+4], 'little') for f in fixups}
    if addends != layout['addends']:
        raise ValueError('Board actor complete fixup addends differ')
