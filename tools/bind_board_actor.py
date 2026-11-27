"""Guard the entire three-public actor-configuration compiler object."""
import hashlib
import json
from pathlib import Path

LAYOUT = json.loads((Path(__file__).parent/'data/board-actor-layout.json').read_text(encoding='utf-8'))
PUBLICS = frozenset(p[2] for p in LAYOUT['publics'])
GROUP_SHA256 = LAYOUT['sha256']


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


def verify_context(blob):
    from verify_c_leaf import parsed_leaf_object
    segments, publics, names, flat, fixups = parsed_leaf_object(blob)
    if [list(p) for p in publics] != LAYOUT['publics']:
        raise ValueError('Board actor public layout differs')
    if structural_records(blob) != LAYOUT['structure']:
        raise ValueError('Board actor structural OMF metadata differs')
    observed_segments = [[i, s['cls'], len(s['data'])]
                         for i, s in enumerate(segments) if s is not None]
    if observed_segments != LAYOUT['segments']:
        raise ValueError('Board actor segment layout differs')
    raw = bytes(segments[1]['data'])
    if GROUP_SHA256 is not None and hashlib.sha256(raw).hexdigest() != GROUP_SHA256:
        raise ValueError('Board actor complete context digest differs')
    if any(f.target[0] == 2 and not 0 < f.target[1] < len(names) for f in fixups):
        raise ValueError('Board actor external index out of range')
    records = [[f.segment, f.offset, f.width, f.location, f.relative,
                list(f.frame), list(f.target), f.displacement,
                names[f.target[1]] if f.target[0] == 2 else None] for f in fixups]
    if sorted(flat) != LAYOUT['records']['flat_groups'] or records != LAYOUT['records']['fixups']:
        raise ValueError('Board actor complete fixup records differ')
    addends = {str(f.offset): int.from_bytes(raw[f.offset:f.offset+4], 'little') for f in fixups}
    if addends != LAYOUT['addends']:
        raise ValueError('Board actor complete fixup addends differ')
