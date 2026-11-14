"""Verify diagnostic payloads and the historical CONST segment attributes."""
import argparse
import json
from pathlib import Path

from match_objects import read_object
from verify_cache_messages import verify as verify_messages


def verify_const_layout(blob):
    segments, _ = read_object(blob)
    populated = [i for i, s in enumerate(segments) if s and s['data']]
    if len(populated) != 1:
        raise ValueError('Expected one populated CONST segment')
    wanted = populated[0]
    segment = segments[wanted]
    if segment['name'] != 'CONST' or segment['cls'] != 'DATA' or len(segment['data']) != 387:
        raise ValueError('Expected historical CONST/DATA payload extent')
    cursor, number, attribute = 0, 0, None
    while cursor < len(blob):
        kind = blob[cursor]
        length = int.from_bytes(blob[cursor + 1:cursor + 3], 'little')
        if kind in (0x98, 0x99):
            number += 1
            if number == wanted:
                attribute = blob[cursor + 3]
                if kind != 0x99 or attribute != 0xa9:
                    raise ValueError('Expected DWORD-aligned public USE32 CONST segment')
        cursor += length + 3
    if attribute is None:
        raise ValueError('Missing CONST SEGDEF')
    return dict(segment_name='CONST', segment_class='DATA',
                segment_attribute=hex(attribute), payload_bytes=387)


def verify(exe, blob):
    result = verify_messages(exe, blob)
    result.update(verify_const_layout(blob))
    result.update(additional_initialized_coverage=0,
                  anonymous_literal_pool_recreated=False,
                  final_linked_placement_verified=False)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.object.read_bytes())
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 387 existing diagnostic bytes in historical CONST/DATA class and alignment')
