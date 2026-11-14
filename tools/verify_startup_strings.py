"""Verify four source-defined startup strings, without claiming final linkage."""
import argparse
import hashlib
import json
from pathlib import Path
from compare_exe import TARGET_SHA256
from check_start_hook import image
from le_fixups import read_le_fixups
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from research_startup import layout

SIZE, DS, RAW = 82, 4, 0x9b604
PUBLICS = [('_main_cleanup_message', 0), ('_main_group_name', 44),
           ('_main_load_error', 54), ('_main_default_selection', 76)]


def verify(exe, blob):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    segments, publics = read_object(blob)
    allocated = [(i, s) for i, s in enumerate(segments[1:], 1) if s['data']]
    if len(allocated) != 1:
        raise ValueError('Expected one initialized string segment')
    index, segment = allocated[0]
    initialized, _ = layout(blob)
    if (segment['name'], segment['cls'], len(segment['data'])) != ('CONST', 'DATA', SIZE):
        raise ValueError('Unexpected string storage')
    if initialized != {index: set(range(SIZE))}:
        raise ValueError('String payload must be entirely initialized')
    if publics != [(index, offset, name) for name, offset in PUBLICS]:
        raise ValueError('String public layout differs')
    if read_fixups(blob) or read_externals(blob) != [None]:
        raise ValueError('Unexpected string dependency or fixup')
    payload = bytes(segment['data'])
    if payload != exe[RAW:RAW+SIZE] or payload != image(exe)[0x80000+DS:0x80000+DS+SIZE]:
        raise ValueError('Startup strings differ from original DATA')
    if any(0x80000+DS <= site < 0x80000+DS+SIZE for site in read_le_fixups(exe)['pointers']):
        raise ValueError('Unexpected relocation inside startup strings')
    return dict(target_sha256=TARGET_SHA256, object_sha256=hashlib.sha256(blob).hexdigest(),
                payload_sha256=hashlib.sha256(payload).hexdigest(), bytes=SIZE,
                raw_offset=hex(RAW), ds_offset=hex(DS), code_bytes=0, le_targets=0,
                publics={name: hex(DS+offset) for name, offset in PUBLICS},
                explicit_const_placement_is_reconstruction_choice=True,
                final_linked_placement_verified=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8', newline='\n')
    print('PASS: four startup strings, 82 exact initialized DATA bytes, no CODE or relocations')
