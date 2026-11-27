"""Guard the complete input-selection compiler context before phase placement."""
import hashlib
import json
from pathlib import Path
from bind_board_actor import structural_records

LAYOUT=json.loads((Path(__file__).parent/'data/input-selection-layout.json').read_text(encoding='utf-8'))
PUBLIC=LAYOUT['context']['public']
CONTEXT_SHA256=LAYOUT['context']['sha256']


def verify_context(blob):
    from verify_c_leaf import parsed_leaf_object
    segments,publics,names,flat,fixups=parsed_leaf_object(blob);ctx=LAYOUT['context']
    if [list(p) for p in publics]!=ctx['publics']:
        raise ValueError('Input selection public layout differs')
    if structural_records(blob)!=ctx['structure']:
        raise ValueError('Input selection structural OMF metadata differs')
    if [[i,s['cls'],len(s['data'])] for i,s in enumerate(segments) if s is not None]!=ctx['segments']:
        raise ValueError('Input selection segment layout differs')
    raw=bytes(segments[1]['data'])
    if CONTEXT_SHA256 is not None and hashlib.sha256(raw).hexdigest()!=CONTEXT_SHA256:
        raise ValueError('Input selection complete context digest differs')
    if any(f.target[0]==2 and not 0<f.target[1]<len(names) for f in fixups):
        raise ValueError('Input selection external index differs')
    records=[[f.segment,f.offset,f.width,f.location,f.relative,list(f.frame),list(f.target),f.displacement,names[f.target[1]] if f.target[0]==2 else None] for f in fixups]
    if sorted(flat)!=ctx['records']['flat_groups'] or records!=ctx['records']['fixups']:
        raise ValueError('Input selection complete fixup records differ')
    if {str(f.offset):int.from_bytes(raw[f.offset:f.offset+4],'little') for f in fixups}!=ctx['addends']:
        raise ValueError('Input selection complete fixup addends differ')
