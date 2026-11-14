"""Check joint cache code, initialized globals and uninitialized storage layout.

This uses externally constrained segment bases, not a final executable link.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object, index
from omf_fixups import read_fixups
from verify_cache_prefix import ADDRESS, FILE_OFFSET, SIZE, PUBLICS
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details,
                          verify_leaf_relocations)

DATA_BASE, BSS_BASE = 0x13bc0, 0x17aba4
DATA = [('_cachecount', 0, 4), ('_zerochar', 4, 1), ('_cachestart', 5, 4),
        ('_cachesize', 9, 4), ('_cacnum', 13, 4), ('_agecount', 17, 4),
        ('_groupfil', 21, 4), ('_filehandle', 25, 256)]
BSS = [('_filepos', 0, 256), ('_handptr', 256, 16384),
       ('_lockptr', 16640, 16384), ('_cacleng', 33024, 16384),
       ('_filelist', 49408, 4), ('_numfiles', 49412, 4),
       ('_groupfilpos', 49416, 4), ('_fileoffs', 49420, 4)]


def verify_layout(blob):
    """Validate complete object storage/public layout without needing FATE bytes."""
    segments, publics = read_object(blob)
    chosen = {}
    for cls, size in [('CODE', SIZE), ('DATA', 281), ('BSS', 49424)]:
        matches = [i for i, s in enumerate(segments) if s and s['cls'] == cls and s['data']]
        if len(matches) != 1 or len(segments[matches[0]]['data']) != size:
            raise ValueError('Unexpected cache segment extent: ' + cls)
        chosen[cls] = matches[0]
    if any(s and s['data'] and i not in chosen.values() for i, s in enumerate(segments)):
        raise ValueError('Unexpected extra segment payload')
    expected = [(chosen['CODE'], offset, name) for name, offset in PUBLICS]
    for cls, rows in [('DATA', DATA), ('BSS', BSS)]:
        expected += [(chosen[cls], offset, name) for name, offset, size in rows]
    if sorted(publics) != sorted(expected):
        raise ValueError('Cache public inventory/offsets differ')
    # read_object initializes reserved memory to zero; distinguish actual LEDATA
    # records from reservations rather than counting those synthetic zeros.
    cursor = 0
    initialized_sites = set()
    while cursor < len(blob):
        kind = blob[cursor]
        length = int.from_bytes(blob[cursor + 1:cursor + 3], 'little')
        if kind in (0xa0, 0xa1):
            record = blob[cursor + 3:cursor + 2 + length]
            segment, position = index(record, 0)
            if segment == chosen['BSS']:
                raise ValueError('BSS unexpectedly has initialized LEDATA')
            if segment == chosen['DATA']:
                width = 4 if kind & 1 else 2
                offset = int.from_bytes(record[position:position + width], 'little')
                payload_size = len(record) - position - width
                sites = set(range(offset, offset + payload_size))
                if sites & initialized_sites:
                    raise ValueError('Overlapping initialized global records')
                initialized_sites.update(sites)
        cursor += length + 3
    if initialized_sites != set(range(281)):
        raise ValueError('Initialized globals lack complete explicit LEDATA')
    fixups = read_fixups(blob)
    if any(f.segment != chosen['CODE'] for f in fixups):
        raise ValueError('Unexpected non-code fixups')
    return segments, publics, chosen


def verify(exe, blob):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    segments, publics, chosen = verify_layout(blob)
    # Symbol bases derive from the verified definition offsets. Existing pinned
    # bindings independently constrain those bases; no internal target is guessed.
    values = dict(DATA_OFFSETS)
    for base, rows in [(DATA_BASE, DATA), (BSS_BASE, BSS)]:
        for name, offset, size in rows:
            if values[name] != base + offset:
                raise ValueError('Defined symbol conflicts with accepted LE binding')
            values[name] = base + offset
    functions = dict(FUNCTION_ADDRESSES)
    functions.update({name: ADDRESS + offset for name, offset in PUBLICS})
    code, bindings = bytearray(), {}
    for position, (name, offset) in enumerate(PUBLICS):
        end = PUBLICS[position + 1][1] if position + 1 < len(PUBLICS) else SIZE
        leaf, pointers = bind_leaf_details(blob, name, values,
                                           address=ADDRESS + offset, functions=functions)
        if len(leaf) != end - offset:
            raise ValueError('Unexpected cache code span')
        code.extend(leaf)
        bindings.update({offset + site: target for site, target in pointers.items()})
    if code != exe[FILE_OFFSET:FILE_OFFSET + SIZE]:
        raise ValueError('Cache code differs')
    verify_leaf_relocations(code, bindings, read_le_fixups(exe)['pointers'], ADDRESS)
    header = struct.unpack_from('<I', exe, 60)[0]
    def field(offset):
        return struct.unpack_from('<I', exe, header + offset)[0]
    obj = struct.unpack_from('<6I', exe, header + field(0x40) + 24)
    if obj[1] != 0x80000 or field(0x28) != 4096:
        raise ValueError('Unexpected data object layout')
    page, within = divmod(DATA_BASE, 4096)
    entry = header + field(0x48) + (obj[3] + page - 1) * 4
    physical = int.from_bytes(exe[entry:entry + 3], 'big')
    if page >= obj[4] or within + 281 > 4096 or not physical or exe[entry + 3] != 0:
        raise ValueError('Expected initialized data page')
    raw = field(0x80) + (physical - 1) * 4096 + within
    if segments[chosen['DATA']]['data'] != exe[raw:raw + 281]:
        raise ValueError('Initialized globals differ')
    if BSS_BASE < obj[4] * 4096 or BSS_BASE + 49424 > obj[0]:
        raise ValueError('BSS is not wholly within the unmapped virtual tail')
    return dict(target_sha256=TARGET_SHA256, object_sha256=hashlib.sha256(blob).hexdigest(),
                exact_code_bytes=SIZE, original_le_targets=len(bindings),
                additional_code_coverage=0, matching_initialized_data_bytes=281,
                initialized_ds_base=hex(DATA_BASE), initialized_raw_offset=hex(raw),
                bss_ds_base=hex(BSS_BASE), bss_layout_bytes=49424,
                bss_initialized_data_coverage=0, final_linked_placement_verified=False,
                complete_original_module=False,
                definitions=[dict(symbol=n, ds_offset=hex(base + o), bytes=s, storage=cls)
                             for base, cls, rows in [(DATA_BASE, 'DATA', DATA), (BSS_BASE, 'BSS', BSS)]
                             for n, o, s in rows])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 2273 code bytes / 140 LE targets; 281 initialized bytes; '
          '49424 BSS layout bytes (not initialized coverage)')
