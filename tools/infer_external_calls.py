"""Infer external target addresses from matching spans and relative OMF fixups.

Only ordinary relative 32-bit offsets to EXTDEF symbols are used. This is
candidate symbol evidence, not a fully linked object match.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path
from compare_object_spans import compare
from match_objects import read_object
from omf_fixups import read_externals, read_fixups


def infer(blob, exe):
    comparison = compare(blob, exe)  # pins original hash
    segments, publics = read_object(blob)
    names = read_externals(blob)
    fixups = read_fixups(blob)
    candidates = defaultdict(lambda: defaultdict(list))
    for span in comparison['spans']:
        if span['differing_bytes']:
            continue
        start = int(span['object_offset'], 16)
        address = int(span['candidate_address'], 16)
        seg, = [s for s, a, n in publics if a == start and n == span['symbol']]
        for fix in fixups:
            if (fix.segment != seg or not start <= fix.offset < start+span['public_span']
                    or not fix.relative or fix.location != 9 or fix.target[0] != 2):
                continue
            if fix.offset+4 > start+span['public_span']:
                raise ValueError('Fixup crosses public span')
            target_index = fix.target[1]
            if not 0 < target_index < len(names):
                raise ValueError('External index outside table')
            operand_address = address+fix.offset-start
            file_offset = operand_address-0x10000+0x35600
            linked = int.from_bytes(exe[file_offset:file_offset+4], 'little', signed=True)
            addend = int.from_bytes(segments[seg]['data'][fix.offset:fix.offset+4],
                                    'little', signed=True)
            target = (operand_address+4+linked-addend-fix.displacement) & 0xffffffff
            candidates[names[target_index]][hex(target)].append(dict(
                caller=span['symbol'], operand_address=hex(operand_address),
                object_addend=addend, target_displacement=fix.displacement))
    return dict(object_sha256=comparison['object_sha256'],
                candidates={name: dict(values) for name, values in sorted(candidates.items())})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = infer(args.object.read_bytes(), args.executable.read_bytes())
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    for name, candidates in result['candidates'].items():
        print(name, {address: len(sites) for address, sites in candidates.items()})
