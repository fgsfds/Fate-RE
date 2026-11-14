"""Strict file comparison for reconstruction builds. Nothing is normalized away."""
import argparse
import hashlib
import json
from pathlib import Path

TARGET_SHA256 = '61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f'


def compare(reference, candidate):
    differences = []
    different = 0
    first = None
    for offset in range(max(len(reference), len(candidate))):
        a = reference[offset] if offset < len(reference) else None
        b = candidate[offset] if offset < len(candidate) else None
        if a != b:
            different += 1
            if first is None:
                first = offset
        elif first is not None:
            differences.append([first, offset])
            first = None
    if first is not None:
        differences.append([first, max(len(reference), len(candidate))])
    return dict(identical=reference == candidate,
                reference_size=len(reference), candidate_size=len(candidate),
                reference_sha256=hashlib.sha256(reference).hexdigest(),
                candidate_sha256=hashlib.sha256(candidate).hexdigest(),
                differing_bytes=different, differing_range_count=len(differences),
                first_100_ranges_end_exclusive=differences[:100])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reference', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    reference = args.reference.read_bytes()
    if hashlib.sha256(reference).hexdigest() != TARGET_SHA256:
        parser.error('Reference is not the pinned October 1996 FATE.EXE')
    result = compare(reference, args.candidate.read_bytes())
    output = json.dumps(result, indent=2)+'\n'
    if args.output:
        args.output.write_text(output, encoding='utf-8')
    print(output, end='')
    raise SystemExit(0 if result['identical'] else 1)
