"""Check a single-source cache unit: code, CONST, globals and BSS layout.

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
from verify_cache_messages import MESSAGES
from verify_cache_prefix import ADDRESS, FILE_OFFSET, SIZE, PUBLICS
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details,
                          verify_leaf_relocations)

from verify_cache_layout import DATA_BASE, BSS_BASE, DATA, BSS


def verify_unit_layout(blob):
    """Validate complete object storage/public layout without needing FATE bytes."""
    segments, publics = read_object(blob)
    chosen = {}
    for cls, size, name in [('CODE', SIZE, '_TEXT'), ('DATA', 281, '_DATA'),
                            ('BSS', 49424, '_BSS'), ('CONST', 387, 'CONST')]:
        actual_class = 'DATA' if cls == 'CONST' else cls
        matches = [i for i, s in enumerate(segments)
                   if s and s['cls'] == actual_class and s['name'] == name and s['data']]
        if len(matches) != 1 or len(segments[matches[0]]['data']) != size:
            raise ValueError('Unexpected cache segment extent: ' + cls)
        chosen[cls] = matches[0]
    if any(s and s['data'] and i not in chosen.values() for i, s in enumerate(segments)):
        raise ValueError('Unexpected extra segment payload')
    expected = [(chosen['CODE'], offset, name) for name, offset in PUBLICS]
    for cls, rows in [('DATA', DATA), ('BSS', BSS)]:
        expected += [(chosen[cls], offset, name) for name, offset, size in rows]
    message_offset = 0
    for name, size in MESSAGES.items():
        expected.append((chosen['CONST'], message_offset, name))
        message_offset += size
    if sorted(publics) != sorted(expected):
        raise ValueError('Cache public inventory/offsets differ')
    # read_object initializes reserved memory to zero; distinguish actual LEDATA
    # records from reservations rather than counting those synthetic zeros.
    cursor = 0
    initialized_sites = {chosen['DATA']: set(), chosen['CONST']: set()}
    segment_number = 0
    while cursor < len(blob):
        kind = blob[cursor]
        length = int.from_bytes(blob[cursor + 1:cursor + 3], 'little')
        if kind in (0x98, 0x99):
            segment_number += 1
            if segment_number == chosen['CONST'] and (kind != 0x99 or blob[cursor + 3] != 0xa9):
                raise ValueError('Unexpected CONST alignment/combine/use32 attributes')
        if kind in (0xa0, 0xa1):
            record = blob[cursor + 3:cursor + 2 + length]
            segment, position = index(record, 0)
            if segment == chosen['BSS']:
                raise ValueError('BSS unexpectedly has initialized LEDATA')
            if segment in initialized_sites:
                width = 4 if kind & 1 else 2
                offset = int.from_bytes(record[position:position + width], 'little')
                payload_size = len(record) - position - width
                sites = set(range(offset, offset + payload_size))
                if sites & initialized_sites[segment]:
                    raise ValueError('Overlapping initialized global records')
                initialized_sites[segment].update(sites)
        cursor += length + 3
    if (initialized_sites[chosen['DATA']] != set(range(281))
            or initialized_sites[chosen['CONST']] != set(range(387))):
        raise ValueError('Initialized globals lack complete explicit LEDATA')
    fixups = read_fixups(blob)
    if any(f.segment != chosen['CODE'] for f in fixups):
        raise ValueError('Unexpected non-code fixups')
    return segments, publics, chosen


def verify(exe, blob):
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    segments, publics, chosen = verify_unit_layout(blob)
    # Symbol bases derive from the verified definition offsets. Existing pinned
    # bindings independently constrain those bases; no internal target is guessed.
    values = dict(DATA_OFFSETS)
    for base, rows in [(DATA_BASE, DATA), (BSS_BASE, BSS)]:
        for name, offset, size in rows:
            if values[name] != base + offset:
                raise ValueError('Defined symbol conflicts with accepted LE binding')
            values[name] = base + offset
    message_offset = 0
    for name, size in MESSAGES.items():
        if values[name] != 0x1748 + message_offset:
            raise ValueError('Diagnostic definition conflicts with accepted binding')
        values[name] = 0x1748 + message_offset
        message_offset += size
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
    raw_offsets = {}
    for cls, base, size in [('DATA', DATA_BASE, 281), ('CONST', 0x1748, 387)]:
        page, within = divmod(base, 4096)
        entry = header + field(0x48) + (obj[3] + page - 1) * 4
        physical = int.from_bytes(exe[entry:entry + 3], 'big')
        if page >= obj[4] or within + size > 4096 or not physical or exe[entry + 3] != 0:
            raise ValueError('Expected initialized data page')
        raw = field(0x80) + (physical - 1) * 4096 + within
        if segments[chosen[cls]]['data'] != exe[raw:raw + size]:
            raise ValueError('Initialized payload differs: ' + cls)
        raw_offsets[cls] = hex(raw)
    if BSS_BASE < obj[4] * 4096 or BSS_BASE + 49424 > obj[0]:
        raise ValueError('BSS is not wholly within the unmapped virtual tail')
    return dict(target_sha256=TARGET_SHA256, object_sha256=hashlib.sha256(blob).hexdigest(),
                exact_code_bytes=SIZE, original_le_targets=len(bindings),
                additional_code_coverage=0, matching_initialized_data_bytes=668,
                initialized_ds_base=hex(DATA_BASE), initialized_raw_offsets=raw_offsets,
                bss_ds_base=hex(BSS_BASE), bss_layout_bytes=49424,
                bss_initialized_data_coverage=0, final_linked_placement_verified=False,
                complete_original_module=False, single_source_unit=True,
                diagnostic_segment_name='CONST', diagnostic_bytes=387,
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
    print('PASS: 2273 code bytes / 140 LE targets; 668 initialized bytes; '
          '49424 BSS layout bytes (not initialized coverage)')
