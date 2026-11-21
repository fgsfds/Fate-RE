"""Build the exact production image; opt into broader regression checks."""
import argparse
import json
import os
import shutil
import subprocess
import sys
from hashlib import sha256
from pathlib import Path
import re

from graphics_font_dependency import GRAPH_LIBRARY
from restoration_build import assert_fresh, read_provenance, write_json, digest, load_units
from validation_workflow import (
    ensure_dependencies, python_environment, StageRunner, run_fixtures, validation_inputs,
)

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent
INPUTS = TOOLS / 'inputs'


def verify_inputs():
    for line in (TOOLS / 'inputs.sha256').read_text(encoding='ascii').splitlines():
        match = re.fullmatch(r'([0-9a-f]{64})  (.+)', line)
        if match is None:
            raise ValueError(f'Invalid checksum entry: {line}')
        expected, relative = match.groups()
        if sha256((INPUTS / relative).read_bytes()).hexdigest() != expected:
            raise ValueError(f'SHA-256 mismatch: {relative}')


def verify_code_inventory(report, expected):
    def comparable(path):
        inventory = json.loads(path.read_text(encoding='utf-8'))
        for row in inventory['spans'] + inventory['non_routine_code_spans']:
            row.pop('object_sha256', None)  # Volatile Watcom OMF timestamps.
        return inventory

    if comparable(report) != comparable(expected):
        raise ValueError(f'Verified coverage differs from {expected.name}')


def reference_bytes(reference, output):
    """Read a pinned, independent reference before anything can overwrite it."""
    if reference is None:
        return None
    if reference.resolve() == output.resolve():
        raise ValueError('Reference and build output must be separate files')
    from compare_exe import TARGET_SHA256
    payload = reference.read_bytes()
    if sha256(payload).hexdigest() != TARGET_SHA256:
        raise ValueError('Reference does not match the pinned FATE.EXE SHA-256')
    return payload


def smoke_test(build):
    smoke = build / 'smoke'
    smoke.mkdir(exist_ok=True)
    shutil.copyfile(build / 'FATE.EXE', smoke / 'FATE.EXE')
    shutil.copyfile(INPUTS / 'demo/DOS4GW.EXE', smoke / 'DOS4GW.EXE')
    # A failed rerun must not inherit the previous PASS.
    (smoke / 'STATUS.TXT').write_text('PENDING', encoding='ascii')
    (smoke / 'HELP.TXT').write_bytes(b'')
    (smoke / 'smoke.bat').write_text(
        '@echo off\nFATE -HELP > HELP.TXT\nif errorlevel 1 goto done\n'
        'echo PASS > STATUS.TXT\n:done\n', encoding='ascii', newline='\r\n')
    config = build / 'smoke.conf'
    config.write_text(
        '[dosbox]\nmemsize=31\n[mixer]\nnosound=true\n[autoexec]\n'
        f'mount c "{smoke}"\nc:\ncall smoke.bat\nexit\n', encoding='ascii')
    env = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
    subprocess.run(
        [INPUTS / 'dosbox/DOSBox.exe', '-conf', config, '-noconsole'],
        cwd=smoke, env=env, timeout=30, check=True,
        creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0),
        stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    if (smoke / 'STATUS.TXT').read_text(encoding='ascii').strip() != 'PASS':
        raise ValueError('FATE -HELP failed')
    expected = 'a19103df99d7bcd78303e7557da8a8fb8d540ca1efe5664bb3c2e3a30baabb6d'
    if sha256((smoke / 'HELP.TXT').read_bytes()).hexdigest() != expected:
        raise ValueError('FATE -HELP output differs')
    print('PASS: FATE -HELP in DOSBox')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, default=ROOT / 'work/ci-build')
    parser.add_argument('--dependencies', type=Path)
    parser.add_argument('--resume', action='store_true',
                        help='Reuse only content-verified compiler/NASM outputs; rerun selected checks')
    parser.add_argument('--jobs', type=int, choices=range(1, 9), default=1)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--exact', action='store_true',
                       help='Whole-image acceptance only (default); no regression suites')
    modes.add_argument('--full', action='store_true',
                       help='Also run tooling tests, compiler regressions, inventories and fixtures')
    parser.add_argument('--reference', type=Path,
                        help='Optional pinned original; compare directly as well as the packer hash')
    parser.add_argument('--smoke', action='store_true',
                        help='Opt into DOSBox game smoke (requires --full)')
    parser.add_argument('--smoke-only', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.smoke and not args.full:
        parser.error('--smoke requires --full')
    build = args.build.resolve()
    if args.smoke_only:
        smoke_test(build)
        return
    if sys.flags.optimize:
        parser.error('Validation requires Python assertions (do not use -O)')
    if build.parent != ROOT / 'work' or not re.fullmatch(r'[A-Za-z0-9_-]+', build.name):
        parser.error('--build must be directly under work/')
    executable = build / 'FATE.EXE'
    expected = reference_bytes(args.reference, executable)
    build.mkdir(parents=True, exist_ok=args.resume)
    # Never leave a prior whole-build PASS behind after a failed resumed run.
    mode = 'full' if args.full else 'exact'
    write_json(build / 'validation.json', dict(status='pending', mode=mode))
    verify_inputs()
    snapshot = validation_inputs()
    dependencies = ensure_dependencies(args.dependencies) if args.full else None
    if dependencies is not None:
        print(f'Dependencies: {dependencies}', flush=True)
    # Exact builds need only stdlib; emulator dependencies belong to the opt-in
    # regression suite. Preserve the interpreter's environment without -O.
    env = python_environment(dependencies) if dependencies is not None else dict(os.environ)
    env.pop('PYTHONOPTIMIZE', None)
    runner = StageRunner(build, env)
    if args.full:
        runner.python('unit-tests', '-m', 'unittest', 'discover', '-s', TOOLS / 'tests', '-q')
        runner.python('watcom-idioms', TOOLS / 'check_watcom_idioms.py',
                      '--build', build / 'watcom-idioms', *([] if args.resume else ['--clean']))
    options = ['--incremental'] if args.resume else []
    runner.python('compile', TOOLS / 'restoration_build.py', build, *options)
    assert_fresh(build)
    assembly = build / 'asm'
    runner.python('assemble', TOOLS / 'build_assembly.py', INPUTS / 'nasm/nasm.exe', assembly,
                  *(['--incremental'] if args.resume else []))
    runner.python('link', TOOLS / 'build_fate_exe.py', build, assembly,
                  INPUTS / 'demo/dos-stub.bin', executable, '--graph-library', ROOT / GRAPH_LIBRARY)
    # build_fate_exe.py is the single mandatory whole-image hash gate. A supplied
    # original is additionally compared byte for byte, never silently ignored.
    if expected is not None and executable.read_bytes() != expected:
        raise ValueError('Linked executable differs from the pinned reference')
    extra_artifacts = []
    checks = []
    if args.full:
        c_report, assembly_report = build / 'c.json', build / 'assembly.json'
        runner.python('verify-c', TOOLS / 'verify_c_suite.py', executable, build, '--output', c_report)
        runner.python('verify-assembly', TOOLS / 'verify_assembly_suite.py', executable, assembly,
                      c_report, '--output', assembly_report)
        verify_code_inventory(c_report, TOOLS / 'data/matching-routines.json')
        verify_code_inventory(assembly_report, TOOLS / 'data/matching-assembly.json')
        runner.python('coverage-docs', TOOLS / 'restoration_coverage.py', '--check')
        checks = run_fixtures(runner, executable, jobs=args.jobs)
        extra_artifacts = ['c.json', 'assembly.json', 'watcom-idioms/report.json']
    if args.smoke:
        runner.python('smoke', __file__, '--build', build, '--smoke-only')
    assert_fresh(build)
    verify_inputs()
    if validation_inputs() != snapshot:
        raise ValueError('Sources or validation tools changed during the build; rerun validation')
    write_json(build / 'validation.json', dict(
        status='passed', mode=mode, whole_image_verified=True,
        executable_sha256=sha256(executable.read_bytes()).hexdigest(),
        reference=str(args.reference.resolve()) if args.reference else None,
        reference_compared=expected is not None,
        game_smoke='passed' if args.smoke else 'skipped (opt-in)',
        fixtures=checks, regression_checks=args.full,
        validation_inputs=snapshot, python=sys.version,
        dependencies=str(dependencies) if dependencies is not None else None,
        artifact_hashes={name: digest(build / name)
                         for name in ('FATE.EXE', 'asm/assembly-build.json', *extra_artifacts,
                                      *(unit.name + '.obj' for unit in load_units()))},
        units={name: row['key'] for name, row in read_provenance(build)['units'].items()},
        stages=runner.rows))
    print(f'PASS: {mode} build and validation; game smoke '
          f'{"passed" if args.smoke else "SKIPPED"}; {build / "validation.json"}')


if __name__ == '__main__':
    main()
