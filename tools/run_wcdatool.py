"""Run pinned upstream wcdatool without its Windows exit prompt.

The upstream main routine is unchanged. All large output remains under work/.
An independent wdump pass is compared to raw pinned LE header/page metadata.
"""
import argparse
import contextlib
import hashlib
import json
import logging
from pathlib import Path
import struct
import subprocess
import sys
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from check_wcdatool_fixups import REVISION


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_hint(blob):
    pointers = read_le_fixups(blob)['pointers']
    start, end = 0xe74c, 0xe7b0
    targets = []
    for offset in range(start, end, 4):
        raw = struct.unpack_from('<I', blob, 0x35600+offset)[0]
        target = pointers[0x10000+offset]
        assert target == 0x10000+raw and 0x1e820 <= target <= 0x1e910
        targets.append(hex(target))
    assert len(targets) == len(set(targets)) == 25
    assert blob[0x35600+0xe809:0x35600+0xe80d] == bytes.fromhex('fe c8 3c 18')
    assert blob[0x35600+0xe80d:0x35600+0xe80f] == bytes.fromhex('0f 87')
    assert 0x1e813+struct.unpack_from('<i', blob, 0x35600+0xe80f)[0] == 0x1e915
    assert blob[0x35600+0xe813:0x35600+0xe818] == bytes.fromhex('25 ff 00 00 00')
    assert blob[0x35600+0xe818:0x35600+0xe81c] == bytes.fromhex('2e ff 24 85')
    assert pointers[0x1e81c] == 0x1e74c
    return dict(object=1, start=hex(start), end_exclusive=hex(end),
                entries=25, dispatch=hex(0x1e818), targets=targets)


def verify_metadata(blob, metadata):
    header = struct.unpack_from('<I', blob, 60)[0]
    field = lambda offset: struct.unpack_from('<I', blob, header+offset)[0]
    data = metadata['linear exe header (os/2 v2.x) - le']['data']
    checks = {'# module pages': 0x14, 'object # for initial eip': 0x18,
              'initial eip': 0x1c, 'object # for initial esp': 0x20,
              'initial esp': 0x24, 'page size': 0x28,
              'last page size (le)/page shift (lx)': 0x2c,
              '# of objects in module': 0x44, 'object page map offset': 0x48,
              'offset of enumerated data pages': 0x80,
              'offset of the debugging information': 0x98,
              'size of the debugging information': 0x9c}
    assert data['file offset'] == header
    assert all(data[name] == field(offset) for name, offset in checks.items())
    objects = metadata['object table']['data']
    assert len(objects) == field(0x44)
    rows, checked_pages = [], 0
    for number, obj in objects.items():
        expected = struct.unpack_from('<6I', blob, header+field(0x40)+(number-1)*24)
        keys = ('virtual memory size', 'relocation base address', 'object flag bits',
                'object page table index', '# of object page table entries', 'reserved')
        assert tuple(obj[key] for key in keys) == expected
        assert set(obj['pages']) == set(range(expected[3], expected[3]+expected[4]))
        for number2, page in obj['pages'].items():
            record = blob[header+field(0x48)+(number2-1)*4:][:4]
            physical = int.from_bytes(record[:3], 'big')
            offset = field(0x80)+(physical-1)*4096
            size = field(0x2c) if physical == field(0x14) else 4096
            assert page['map page'] == physical and page['flags'] == record[3] == 0
            assert page['file offset'] == offset and page['valid']
            content = b''.join(segment['data'] for segment in page['segments'].values())
            assert content == blob[offset:offset+size]
            checked_pages += 1
        rows.append(dict(object=number, virtual_size=expected[0], loaded_base=hex(expected[1]),
                         initialized_pages=expected[4]))
    return dict(header_fields=len(checks)+1, objects=rows, pages_checked=checked_pages,
                page_bytes_equal=True, declared_debug_size=data['size of the debugging information'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('--upstream', type=Path, default=Path('reference/wcdatool'))
    parser.add_argument('--wdump', type=Path, default=Path('work/wcdatool-full/wdump.exe'))
    parser.add_argument('--objdump', type=Path, default=Path('C:/msys64/mingw64/bin/objdump.exe'))
    parser.add_argument('--work', type=Path, default=Path('work/wcdatool-full'))
    parser.add_argument('--hints', type=Path, default=Path('tools/data/wcdatool-hints.txt'))
    parser.add_argument('--no-hints', action='store_true')
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    blob = args.executable.read_bytes()
    if hashlib.sha256(blob).hexdigest() != TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    revision = subprocess.check_output(['git', '-C', str(args.upstream), 'rev-parse', 'HEAD'], text=True).strip()
    if revision != REVISION:
        parser.error('Unexpected wcdatool revision')
    subprocess.run(['git', '-C', str(args.upstream), 'diff', '--exit-code', '--quiet',
                    'HEAD', '--', 'Wcdatool'], check=True)
    root_work = Path(__file__).resolve().parents[1]/'work'
    if not args.work.resolve().is_relative_to(root_work):
        parser.error('Large generated output must remain under the ignored work directory')
    args.work.mkdir(parents=True, exist_ok=True)
    hint_evidence = verify_hint(blob)
    sys.path.insert(0, str((args.upstream/'Wcdatool').resolve()))
    from modules.main_wdump import wdump_parse_output
    import wcdatool
    logpath = args.work/'console.log'
    with logpath.open('w', encoding='utf-8') as log, contextlib.redirect_stdout(log), contextlib.redirect_stderr(log):
        logging.disable(logging.CRITICAL)
        metadata = wdump_parse_output(str(args.executable), str(args.wdump), None, None,
                                      str(args.work/'validation_%s'))
        metadata_report = verify_metadata(blob, metadata)
        del metadata
        for handler in list(logging.getLogger().handlers):
            logging.getLogger().removeHandler(handler)
            handler.close()
        logging.disable(logging.NOTSET)
        sys.argv = ['wcdatool.py', '--wdump-exec', str(args.wdump), '--objdump-exec', str(args.objdump),
                    '--output-dir', str(args.work), '--color-mode', 'false']
        if not args.no_hints:
            sys.argv += ['--wdump-addout', str(args.hints)]
        sys.argv += [str(args.executable)]
        status = wcdatool.main()  # Deliberately omit only windows_enter_to_exit().
        logging.shutdown()
    if status != 0:
        raise SystemExit(f'wcdatool failed ({status}); inspect {logpath}')
    logtext = logpath.read_text(encoding='utf-8')
    files = {}
    for number in (1, 2):
        filename = args.work/f'{args.executable.name}_disasm_object_{number}_disassembly_formatted_deduplicated.asm'
        files[str(number)] = dict(bytes=filename.stat().st_size, sha256=digest(filename))
    result = dict(target_sha256=TARGET_SHA256, wcdatool_revision=revision,
                  wdump_sha256=digest(args.wdump), objdump_sha256=digest(args.objdump),
                  upstream_main_status=status, windows_exit_prompt_skipped=True,
                  header_page_validation=metadata_report,
                  hint=hint_evidence if not args.no_hints else None,
                  warning_lines=sum(line.startswith('Warning:') for line in logtext.splitlines()),
                  recovered_modules=0 if 'Wrote 0 modules to separate files' in logtext else None,
                  formatted_disassembly=files, source_coverage_added=0)
    args.report.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: full disassembly; {result['warning_lines']} warning lines; {metadata_report['pages_checked']} pages verified")
