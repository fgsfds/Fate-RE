"""Cross-check FATE pointers with the external wcdatool record decoder.

Header/page metadata is supplied locally; wdump and full disassembly are not run.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups

REVISION = '69c770f477652bf43c7b1237f9a9f2b72712b289'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('--upstream', type=Path, default=Path('reference/wcdatool'))
    parser.add_argument('--work', type=Path, default=Path('work/wcdatool'))
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    revision = subprocess.check_output(['git', '-C', str(args.upstream), 'rev-parse', 'HEAD'], text=True).strip()
    if revision != REVISION:
        parser.error('Unexpected wcdatool revision; review it before changing the pin')
    blob = args.executable.read_bytes()
    if hashlib.sha256(blob).hexdigest() != TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    sys.path.insert(0, str((args.upstream/'Wcdatool').resolve()))
    from modules.main_fixup_relocation import fixup_relocation_read_decode
    header = struct.unpack_from('<I', blob, 60)[0]
    def field(offset):
        return struct.unpack_from('<I', blob, header+offset)[0]
    fields = {'file offset': header, 'fixup section size': field(0x30),
              'offset of fixup page table': field(0x68),
              'offset of fixup record table': field(0x6c),
              'offset of import module name table': field(0x70),
              'offset of import procedure name table': field(0x78)}
    objects = [struct.unpack_from('<6I', blob, header+field(0x40)+i*24)
               for i in range(field(0x44))]
    # The decoder only needs page lengths to derive object-relative source sites.
    # These zero-filled placeholders are metadata, not a loaded executable image.
    metadata = {'linear exe header (os/2 v2.x) - le': {'data': fields},
                'object table': {'data': {}}}
    for number, obj in enumerate(objects, 1):
        pages = {page: {'num': page, 'segments': {1: {'num': 1, 'data': bytes(4096)}}}
                 for page in range(obj[3], obj[3]+obj[4])}
        metadata['object table']['data'][number] = {'num': number, 'pages': pages}
    args.work.mkdir(parents=True, exist_ok=True)
    decoded = fixup_relocation_read_decode(metadata, str(args.executable),
                                          str(args.work/'FATE_%s'))
    pointers = {}
    for record in decoded['record table'].values():
        assert record['source flags type'] == 7 and record['target flags type'] == 0
        site = objects[record['source object']-1][1]+record['source offset 2']
        target = objects[record['target object']-1][1]+record['target offset']
        assert site not in pointers or pointers[site] == target
        pointers[site] = target
    expected = read_le_fixups(blob)
    assert len(decoded['record table']) == expected['record_count']
    assert pointers == expected['pointers']
    report = dict(target_sha256=TARGET_SHA256, wcdatool_revision=revision,
                  records=len(decoded['record table']), unique_pointer_sites=len(pointers),
                  duplicate_records=len(decoded['record table'])-len(pointers),
                  all_sites_and_targets_equal=True, full_disassembly_run=False,
                  header_metadata_independently_decoded=False)
    args.output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: {report['records']} records and {len(pointers)} unique pointer sites agree")
