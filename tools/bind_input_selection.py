"""Guard the complete input-selection compiler context before phase placement."""
import hashlib
import json
from pathlib import Path
from bind_board_actor import structural_records

LAYOUT=json.loads((Path(__file__).parent/'data/input-selection-layout.json').read_text(encoding='utf-8'))
PUBLIC=LAYOUT['context']['public']
CONTEXT_SHA256=LAYOUT['context']['sha256']
CURSOR_LAYOUT=json.loads((Path(__file__).parent/'data'/LAYOUT['cursor_context_file']).read_text(encoding='utf-8'))
CURSOR_PUBLIC=CURSOR_LAYOUT['context']['public']
CURSOR_CONTEXT_SHA256=CURSOR_LAYOUT['context']['sha256']
ACTIONS_LAYOUT=json.loads((Path(__file__).parent/'data'/LAYOUT['actions_context_file']).read_text(encoding='utf-8'))
ACTIONS_PUBLIC=ACTIONS_LAYOUT['context']['public']
ACTIONS_CONTEXT_SHA256=ACTIONS_LAYOUT['context']['sha256']
FIFO_LAYOUT=json.loads((Path(__file__).parent/'data'/LAYOUT['fifo_context_file']).read_text(encoding='utf-8'))
FIFO_PUBLIC=FIFO_LAYOUT['context']['public']
FIFO_CONTEXT_SHA256=FIFO_LAYOUT['context']['sha256']
PLACEMENT_LAYOUTS=(LAYOUT,CURSOR_LAYOUT,ACTIONS_LAYOUT,FIFO_LAYOUT)
PUBLICS=frozenset((PUBLIC,CURSOR_PUBLIC,ACTIONS_PUBLIC,FIFO_PUBLIC))


def verify_context(blob,public_name=None):
    from verify_c_leaf import parsed_leaf_object
    segments,publics,names,flat,fixups=parsed_leaf_object(blob)
    public_name=public_name or next((p[2] for p in publics if p[2] in PUBLICS),None)
    if public_name==PUBLIC:ctx,digest=LAYOUT['context'],CONTEXT_SHA256
    elif public_name==CURSOR_PUBLIC:ctx,digest=CURSOR_LAYOUT['context'],CURSOR_CONTEXT_SHA256
    elif public_name==ACTIONS_PUBLIC:ctx,digest=ACTIONS_LAYOUT['context'],ACTIONS_CONTEXT_SHA256
    elif public_name==FIFO_PUBLIC:ctx,digest=FIFO_LAYOUT['context'],FIFO_CONTEXT_SHA256
    else:raise ValueError('Unknown input compiler context')
    if [list(p) for p in publics]!=ctx['publics']:
        raise ValueError('Input selection public layout differs')
    if structural_records(blob)!=ctx['structure']:
        raise ValueError('Input selection structural OMF metadata differs')
    if [[i,s['cls'],len(s['data'])] for i,s in enumerate(segments) if s is not None]!=ctx['segments']:
        raise ValueError('Input selection segment layout differs')
    raw=bytes(segments[1]['data'])
    if digest is not None and hashlib.sha256(raw).hexdigest()!=digest:
        raise ValueError('Input selection complete context digest differs')
    if any(f.target[0]==2 and not 0<f.target[1]<len(names) for f in fixups):
        raise ValueError('Input selection external index differs')
    records=[[f.segment,f.offset,f.width,f.location,f.relative,list(f.frame),list(f.target),f.displacement,names[f.target[1]] if f.target[0]==2 else None] for f in fixups]
    if sorted(flat)!=ctx['records']['flat_groups'] or records!=ctx['records']['fixups']:
        raise ValueError('Input selection complete fixup records differ')
    if {str(f.offset):int.from_bytes(raw[f.offset:f.offset+4],'little') for f in fixups}!=ctx['addends']:
        raise ValueError('Input selection complete fixup addends differ')
