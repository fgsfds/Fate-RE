"""Bind the October 1995 vertical collision routine at the FATE placement."""
import argparse
import json
from pathlib import Path
from verify_historical_cliplines import (
    bind_span, DATA as CLIP_DATA, OBJECT_SHA256, TARGET_SHA256,
)

ENTRY, SIZE = 0x562f9, 2966
DATA = {key: CLIP_DATA[key] for key in (
    '_clipsectorlist', '_clipsectnum', '_sector', '_wall', '_editstatus',
    '_headspritesect', '_sprite', '_tilesizy', '_picanm', '_sintable',
    '_tilesizx', '_nextspritesect',
)}
CALLS = {'getzsofslope_': 0x5e07a, 'clipinsideboxline_': 0x4c1b2}


def bind_verified(exe, blob):
    return bind_span(exe, blob, 'getzrange_', 'makeradarang_', 0x1253b,
                     ENTRY, SIZE, DATA, CALLS, 37, 3, 0x13636,
                     shared_return=(0xeef2, 0x52c82))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for arg in ('executable', 'object'):
        parser.add_argument(arg, type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    bind_verified(args.executable.read_bytes(), args.object.read_bytes())
    report = dict(executable_sha256=TARGET_SHA256, object_sha256=OBJECT_SHA256,
                  symbol='getzrange_', address=hex(ENTRY), bytes=SIZE,
                  le_targets=37, relative_calls=3, shared_return='0x52c82',
                  object_shared_return='0xeef2', reconstructed_source_bytes=0)
    args.output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print('PASS: historical getzrange, 2,966 bound bytes, 37 LE pointers and three calls')
