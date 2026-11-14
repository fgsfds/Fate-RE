"""Verify source-defined animation initial values, without claiming final linkage."""
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

SIZE, DS, RAW = 13, 0x12d84, 0xae384
PUBLICS = [('_prestep_value', 0), ('_prestep_direction', 4),
           ('_prestep_speed', 8), ('_prestep_hold', 12)]


def verify(exe, blob):
    return verify_scalars(exe, blob, RAW, DS, SIZE, PUBLICS)


def verify_scalars(exe, blob, raw, ds, size, symbols):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    segments, publics = read_object(blob)
    allocated = [(i, s) for i, s in enumerate(segments[1:], 1) if s['data']]
    if len(allocated) != 1:
        raise ValueError('Expected one initialized scalar segment')
    index, segment = allocated[0]
    initialized, _ = layout(blob)
    if (segment['name'], segment['cls'], len(segment['data'])) != ('_DATA', 'DATA', size):
        raise ValueError('Unexpected scalar storage')
    if initialized != {index: set(range(size))}:
        raise ValueError('Scalar payload must be entirely initialized')
    if publics != [(index, offset, name) for name, offset in symbols]:
        raise ValueError('Scalar public layout differs')
    if read_fixups(blob) or read_externals(blob) != [None]:
        raise ValueError('Unexpected scalar dependency or fixup')
    payload = bytes(segment['data'])
    if payload != exe[raw:raw+size] or payload != image(exe)[0x80000+ds:0x80000+ds+size]:
        raise ValueError('Scalars differ from original DATA')
    if any(0x80000+ds <= site < 0x80000+ds+size for site in read_le_fixups(exe)['pointers']):
        raise ValueError('Unexpected relocation inside scalars')
    return dict(target_sha256=TARGET_SHA256, object_sha256=hashlib.sha256(blob).hexdigest(),
                payload_sha256=hashlib.sha256(payload).hexdigest(), bytes=size,
                raw_offset=hex(raw), ds_offset=hex(ds), code_bytes=0, le_targets=0,
                publics={name: hex(ds+offset) for name, offset in symbols},
                original_module_boundary_unresolved=True,
                final_linked_placement_verified=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8', newline='\n')
    print('PASS: four animation defaults, 13 exact initialized DATA bytes, no CODE or relocations')
