"""Generate/check the coverage overview from independent checked-in inventories."""
import argparse
import json
from pathlib import Path

from compare_exe import TARGET_SHA256

ROOT = Path(__file__).resolve().parents[1]
START = '<!-- restoration-coverage:start -->'
END = '<!-- restoration-coverage:end -->'


def coverage_text(directory=ROOT / 'tools/data'):
    def read(name):
        report = json.loads((directory / (name + '.json')).read_text(encoding='utf-8'))
        if report['target_sha256'] != TARGET_SHA256:
            raise ValueError('Coverage target differs: '+name)
        return report

    c, asm = read('matching-routines'), read('matching-assembly')
    total = c['unique_code_bytes'] + asm['unique_code_bytes']
    if total != 414639:
        raise ValueError('CODE coverage total differs')
    data, fonts = read('matching-initialized'), read('matching-graphics-font-dependency')
    return '\n'.join((
        START,
        f'- [C CODE inventory](../tools/data/matching-routines.json) covers {c["routines"]:,} routines',
        f'  and compiler-generated tables, totaling {c["unique_code_bytes"]:,} bytes '
        f'({100*c["unique_code_bytes"]/total:.2f}% of CODE).',
        '  This includes mixed C/inline-assembly objects, not just assembly-free C.',
        '- [Assembly CODE inventory](../tools/data/matching-assembly.json) covers',
        f'  {asm["unique_code_bytes"]:,} bytes ({100*asm["unique_code_bytes"]/total:.2f}% of CODE).',
        '- [Source DATA inventory](../tools/data/matching-initialized.json) covers',
        f'  {data["initialized_data_bytes"]:,} stored bytes.',
        '- [Watcom font dependency](../tools/data/matching-graphics-font-dependency.json) supplies',
        f'  {fonts["dependency_data_bytes"]:,} stored bytes from the pinned `GRAPH.LIB`.',
        END))


def update_document(text, generated):
    if text.count(START) != 1 or text.count(END) != 1:
        raise ValueError('Expected one generated coverage block')
    start, end = text.index(START), text.index(END)
    if end < start:
        raise ValueError('Invalid coverage block')
    return text[:start] + generated + text[end + len(END):]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--write', action='store_true')
    args = parser.parse_args()
    path = ROOT / 'docs/RECONSTRUCTION.md'
    text = path.read_text(encoding='utf-8')
    result = update_document(text, coverage_text())
    if args.write:
        path.write_text(result, encoding='utf-8', newline='\n')
    elif result != text:
        parser.exit(1, 'Coverage overview is stale; run python tools/restoration_coverage.py --write\n')
    print('PASS: coverage overview matches inventories')


if __name__ == '__main__':
    main()
