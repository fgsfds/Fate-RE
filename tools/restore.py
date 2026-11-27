"""Focused probes, default exact builds, and opt-in regression validation."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

from compare_exe import TARGET_SHA256
from restoration_build import (
    ROOT, TOOLS, load_units, select_units, compile_units, assert_fresh,
    read_provenance, current_states, is_current, write_json,
    digest,
)
from restoration_registry import fixtures, switch_groups, BEHAVIOR_FIXTURES
from verification_diagnostics import code_mismatch


def registrations():
    # Import the suite too: it supplies additional observed timer entries.
    from verify_c_suite import LEAVES, OBJECT_NAMES
    result = {}
    for symbol, (offset, size) in LEAVES.items():
        name = OBJECT_NAMES.get(symbol, symbol[:-1])
        result[symbol] = dict(object=name, raw_offset=offset, bytes=size)
    for filename, (_, base, _, parts, _) in switch_groups().items():
        for start, end, symbol, _, _ in parts:
            if symbol:
                result[symbol] = dict(object=Path(filename).stem,
                                      raw_offset=base + 0x25600 + start, bytes=end - start)
    return result


def mixed_routine(selector):
    """Keep original routine context after its coverage is split into phases."""
    from verify_c_leaf import WEAPON_ANIMATION_LAYOUT, BOARD_ACTOR_LAYOUT, BOARD_ACTOR_PLACEMENT_LAYOUTS
    layouts = {'update_weapon_animation': WEAPON_ANIMATION_LAYOUT,
               'initialize_board_actors': BOARD_ACTOR_LAYOUT}
    name = selector.rstrip('_')
    if name not in layouts:
        return None
    layout = layouts[name]
    objects = ({c['object'] for c in layout['contexts']} if 'contexts' in layout
               else {layout['object']})
    phases = list(layout['phases'])
    if name == 'initialize_board_actors':
        for actor_layout in BOARD_ACTOR_PLACEMENT_LAYOUTS:
            objects.add(actor_layout['context']['object'])
            phases += actor_layout['phases']
    return dict(symbol=name, loaded_address=hex(layout['original_address']),
                bytes=layout['original_size'],
                compiler_bytes=sum(p['end']-p['begin'] for p in phases),
                assembly_bytes=layout['assembly_size'], objects=objects,
                assembly_symbols={r['symbol'] for r in layout['retained']})


def resolve_units(selector):
    registered = registrations()
    symbol = selector if selector in registered else selector.rstrip('_') + '_'
    if symbol in registered:
        return select_units(load_units(), [registered[symbol]['object']])
    mixed = mixed_routine(selector)
    if mixed:
        return select_units(load_units(), sorted(mixed['objects']))
    normalized = selector.removeprefix('src/').removesuffix('.c')
    units = [unit for unit in load_units()
             if unit.source == normalized or unit.name == Path(selector).stem]
    if not units:
        raise ValueError(f'No build unit for {selector}; register the candidate in '
                         'tools/data/restoration-units.txt first')
    return units


def routine_context(selector):
    from verify_assembly_suite import ROUTINES, NON_ROUTINE_UNITS
    mixed = mixed_routine(selector)
    assembly = [row for row in ROUTINES + NON_ROUTINE_UNITS
                if row[0].rstrip('_') == selector.rstrip('_')
                or mixed and row[0] in mixed['assembly_symbols']]
    try:
        units = resolve_units(selector)
    except ValueError:
        if not assembly:
            raise
        units = []
    names = {unit.name for unit in units}
    registered = registrations()
    entries = [(symbol, row) for symbol, row in registered.items() if row['object'] in names]
    wanted = selector.rstrip('_') + '_'
    entries.sort(key=lambda item: (item[0] != wanted, item[1]['raw_offset']))
    attempts_path = ROOT / 'docs/C-RESTORATION-ATTEMPTS.md'
    attempts = attempts_path.read_text(encoding='utf-8').splitlines()
    def normalize(text):
        return text.lower().replace('_', ' ').replace('`', '')
    terms = normalize(selector.rstrip('_')).split()
    needles = {normalize(selector.rstrip('_')),
               *(normalize(Path(unit.source).name) for unit in units)}
    if len(terms) >= 3:
        needles.add(' '.join(terms[-2:]))
    hits = [i for i, line in enumerate(attempts)
            if any(needle and needle in normalize(line) for needle in needles)]
    attempt_lines = sorted({j for i in hits[:3]
                            for j in range(max(0, i-1), min(len(attempts), i+7))})[:24]
    source_hints = []
    for unit in units[:2]:
        path = ROOT / 'src' / (unit.source + '.c')
        lines = path.read_text(encoding='latin-1').splitlines()
        relevant = [i for i, line in enumerate(lines) if selector.rstrip('_') in line][:4]
        matching = list(dict.fromkeys(relevant + [
            i for i, line in enumerate(lines) if '#pragma aux' in line]))[:8]
        source_hints.append(dict(path=path.relative_to(ROOT).as_posix(),
                                 lines=[dict(line=i+1, text=lines[i][:180]) for i in matching]))
    inventory = json.loads((TOOLS / 'data/matching-routines.json').read_text())
    spans = sorted(inventory['spans'], key=lambda row: int(row['raw_offset'], 16))
    address = (entries[0][1]['raw_offset'] if entries else
               assembly[0][3] + 0x25600 if assembly else 0)
    neighbors = sorted(spans, key=lambda row: abs(int(row['raw_offset'], 16) - address))[:3]
    return dict(
        enclosing_routine=({k: value for k,value in mixed.items()
                            if k not in ('objects','assembly_symbols')} if mixed else None),
        units=[dict(source='src/'+unit.source+'.c', object=unit.name+'.obj', flags=unit.flags)
               for unit in units[:4]], omitted_units=max(0, len(units)-4),
        routines=[dict(symbol=symbol, **row) for symbol, row in entries[:12]],
        assembly=[dict(symbol=symbol, source='src/'+source, binary=binary,
                       loaded_address=hex(address), bytes=size, relocation_count=len(pointers),
                       relocation_sample={hex(site): hex(target) for site, target
                                          in sorted(pointers.items())[:12]})
                  for symbol, source, binary, address, size, pointers in assembly[:2]],
        omitted_routines=max(0, len(entries)-12), source_hints=source_hints,
        omitted_assembly=max(0, len(assembly)-2),
        fixtures=[fixture.script for fixture in fixtures(names)],
        behavior_fixtures=[BEHAVIOR_FIXTURES[name] for name in sorted(names)
                           if name in BEHAVIOR_FIXTURES],
        attempts=dict(path=attempts_path.relative_to(ROOT).as_posix(),
                      lines=[dict(line=i+1, text=attempts[i]) for i in attempt_lines]),
        nearby_exact_examples=[{key: row[key] for key in ('symbol', 'object', 'raw_offset', 'bytes')}
                               for row in neighbors],
        evidence='Expected addresses, ABI bindings, and relocations remain in the independent verifiers.')


def verified_reference(path):
    blob = path.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Reference does not match the pinned FATE.EXE SHA-256')
    return blob


def verify_objects(reference, build, names):
    from le_fixups import read_le_fixups
    from verify_c_leaf import (
        bind_leaf_details, verify_leaf_relocations, DATA_OFFSETS, CODE_OFFSETS, FUNCTION_ADDRESSES,
    )
    from verify_c_suite import verify_compiler_groups
    exe = verified_reference(reference)
    pointers = read_le_fixups(exe)['pointers']
    assert_fresh(build, names)
    verify_compiler_groups(exe, build, names)
    entries = registrations()
    rows = []
    groups = switch_groups()
    for name in sorted(names):
        blob = (build / (name + '.obj')).read_bytes()
        selected = [(symbol, row) for symbol, row in entries.items() if row['object'] == name]
        if not selected:
            raise ValueError(f'{name}: no exact CODE registration; use full validation for DATA-only '
                             'objects, or supply --symbol, --raw-offset and --size for a research probe')
        if name + '.obj' in groups:
            binder, base, size, _, counts = groups[name + '.obj']
            code, data_refs, code_refs, calls = binder(blob)
            if (len(data_refs), len(code_refs), len(calls)) != counts:
                raise ValueError('Switch-group binding inventory differs: '+name)
            expected = exe[base+0x25600:base+0x25600+size]
            if code != expected:
                raise ValueError(code_mismatch(name, code, expected, base))
            verify_leaf_relocations(code, data_refs | code_refs, pointers, base, code_bindings=code_refs)
        else:
            for symbol, row in selected:
                offset, size = row['raw_offset'], row['bytes']
                code_refs = {}
                code, refs = bind_leaf_details(
                    blob, symbol, DATA_OFFSETS, address=offset-0x25600,
                    functions=FUNCTION_ADDRESSES, absolute_code=CODE_OFFSETS, code_bindings=code_refs)
                expected = exe[offset:offset+size]
                if code != expected:
                    raise ValueError(code_mismatch(symbol, code, expected, offset-0x25600))
                verify_leaf_relocations(code, refs, pointers, offset-0x25600, code_bindings=code_refs)
        rows.extend(dict(symbol=symbol, **row) for symbol, row in selected)
    return rows


def research_probe(args, unit):
    from le_fixups import read_le_fixups
    from verify_c_leaf import (
        bind_leaf_details, verify_leaf_relocations, DATA_OFFSETS, CODE_OFFSETS, FUNCTION_ADDRESSES,
    )
    exe = verified_reference(args.reference)
    address = args.raw_offset - 0x25600
    if args.size <= 0 or args.raw_offset < 0x35600 or args.raw_offset + args.size > 0x35600 + 414639:
        raise ValueError('Research span must lie entirely in CODE')
    refs = {}
    code, bindings = bind_leaf_details(
        (args.build / (unit.name + '.obj')).read_bytes(), args.symbol,
        DATA_OFFSETS, address=address, functions=FUNCTION_ADDRESSES,
        absolute_code=CODE_OFFSETS, code_bindings=refs)
    expected = exe[args.raw_offset:args.raw_offset+args.size]
    if code != expected:
        raise ValueError(code_mismatch(args.symbol, code, expected, address))
    verify_leaf_relocations(code, bindings, read_le_fixups(exe)['pointers'],
                            address, code_bindings=refs)
    return [dict(symbol=args.symbol, raw_offset=args.raw_offset, bytes=args.size,
                 object=unit.name, research_only=True)]


def targeted(args, names):
    from validation_workflow import (
        ensure_dependencies, python_environment, StageRunner, run_fixtures, validation_inputs,
    )
    verified_reference(args.reference)
    snapshot = validation_inputs()
    args.build.mkdir(parents=True, exist_ok=True)
    report_path = args.build / 'targeted-validation.json'
    write_json(report_path, dict(status='pending', mode='targeted'))
    result = compile_units(args.build, names, incremental=True)
    if args.command == 'probe' and args.symbol:
        rows = research_probe(args, select_units(load_units(), names)[0])
    else:
        rows = verify_objects(args.reference, args.build, set(names))
    # Byte/LE verification needs only stdlib; install/reuse emulator dependencies
    # only when fixtures are requested and this object has a registered fixture.
    selected = fixtures(set(names)) if args.fixtures else []
    checks = []
    if selected:
        dependencies = ensure_dependencies(args.dependencies)
        print(f'Dependencies: {dependencies}')
        runner = StageRunner(args.build, python_environment(dependencies))
        if any('{asm}' in arg for fixture in selected for arg in fixture.arguments):
            runner.python('targeted-assembly', TOOLS / 'build_assembly.py',
                          TOOLS / 'inputs/nasm/nasm.exe', args.build / 'asm', '--incremental')
        checks = run_fixtures(runner, args.reference, set(names), args.jobs)
    assert_fresh(args.build, set(names))
    if validation_inputs() != snapshot:
        raise ValueError('Sources or validation tools changed during the probe; rerun it')
    write_json(report_path, dict(
        status='passed', mode='targeted', whole_image_verified=False,
        reference_sha256=TARGET_SHA256, routines=rows, fixtures=checks,
        fixtures_requested=args.fixtures, compile=result,
        validation_inputs=snapshot,
        unit_keys={name: row['key'] for name, row in assert_fresh(args.build, set(names)).items()}))
    print(f'PASS: {len(rows)} exact CODE spans, {len(checks)} fixtures; {report_path}')
    if not checks:
        print('Bytes and LE sites/targets only; '
              + ('no behavioral fixture registered.' if args.fixtures
                 else 'behavioral fixtures skipped (opt in with --fixtures).'))


def behavior(args):
    from validation_workflow import ensure_dependencies, python_environment, StageRunner, validation_inputs
    verified_reference(args.reference)
    units = resolve_units(args.routine)
    if len(units) != 1 or units[0].name not in BEHAVIOR_FIXTURES:
        raise ValueError('No behavior-only fixture registered for this selection')
    unit = units[0]
    snapshot = validation_inputs()
    args.build.mkdir(parents=True, exist_ok=True)
    report = args.build / 'behavior-validation.json'
    write_json(report, dict(status='pending', mode='behavior-only', inventory_eligible=False))
    if args.object is None:
        compile_units(args.build, [unit.name], incremental=True)
        obj = args.build / (unit.name + '.obj')
    else:
        obj = args.object.resolve()
    object_hash = digest(obj)
    runner = StageRunner(args.build, python_environment(ensure_dependencies(args.dependencies)))
    options = ['--case-file', args.case_file.resolve()] if args.case_file else []
    runner.python(
        'behavior-' + unit.name, TOOLS / (BEHAVIOR_FIXTURES[unit.name] + '.py'),
        args.reference, obj, '--behavior-only', '--seed', str(args.seed),
        '--random-cases', str(args.random_cases), '--output', report,
        '--failure-output', args.build / 'behavior-failure.json', *options)
    if digest(obj) != object_hash or validation_inputs() != snapshot:
        write_json(report, dict(status='stale', mode='behavior-only', inventory_eligible=False))
        raise ValueError('Candidate or validation inputs changed during behavioral checks')
    print(f'PASS: behavior only; exact bytes/LE sites are NOT qualified. Report: {report}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    doctor = commands.add_parser('doctor', help='Check the interpreter and pinned tool inputs')
    doctor.add_argument('--build', type=Path, help='Also check freshness of a completed exact/full build')
    context = commands.add_parser('context', help='Print bounded routine-specific context')
    context.add_argument('routine')
    context.add_argument('--reference', type=Path,
                         help='Include target disassembly and LE relocations from pinned FATE.EXE')
    context.add_argument('--ghidra-dir', type=Path,
                         help='Export a new analysis directory directly under work/ (requires --reference)')
    context.add_argument('--rea-span', action='store_true',
                         help='Also export a raw x86 routine for REA (requires --ghidra-dir)')
    context.add_argument('--dependencies', type=Path,
                         help='Directory containing the pinned Capstone package')
    probe = commands.add_parser('probe', help='Compile one unit and check bytes/LE targets')
    probe.add_argument('routine')
    probe.add_argument('--symbol', help='Unregistered research public (does not update inventories)')
    probe.add_argument('--raw-offset', type=lambda value: int(value, 0))
    probe.add_argument('--size', type=lambda value: int(value, 0))
    behavioral = commands.add_parser('behavior', help='Test nonmatching candidates without exact acceptance')
    behavioral.add_argument('routine')
    behavioral.add_argument('--object', type=Path, help='Use an existing research object instead of compiling')
    behavioral.add_argument('--seed', type=lambda value: int(value, 0), default=0xFACE)
    behavioral.add_argument('--random-cases', type=int, default=48)
    behavioral.add_argument('--case-file', type=Path)
    validate = commands.add_parser('validate')
    modes = validate.add_mutually_exclusive_group()
    modes.add_argument('--exact', action='store_true',
                       help='Fresh whole-image acceptance without regression suites (default)')
    modes.add_argument('--changed', action='store_true', help='Requires an existing provenance baseline')
    modes.add_argument('--full', action='store_true',
                       help='Also run tooling tests, compiler regressions, inventories and fixtures')
    validate.add_argument('--clean', action='store_true', help='Uncached exact/full build in a NEW directory')
    validate.add_argument('--smoke', action='store_true',
                          help='Opt into DOSBox game smoke (requires --full)')
    for command in (probe, validate):
        command.add_argument('--fixtures', action='store_true',
                             help='Run affected behavioral fixtures with probe/--changed')
    for command in (probe, validate, behavioral):
        command.add_argument('--build', type=Path, default=ROOT / 'work/restoration-build')
        command.add_argument('--reference', type=Path,
                             help='Pinned original or a previously verified FATE.EXE (required for probes)')
        command.add_argument('--dependencies', type=Path)
        command.add_argument('--jobs', type=int, choices=range(1, 9), default=1)
    args = parser.parse_args()
    try:
        if sys.flags.optimize:
            raise ValueError('Validation requires assertions; do not use Python -O')
        if args.command == 'doctor':
            from verify_ci_build import verify_inputs
            print(f'Python: {sys.executable} ({sys.version.split()[0]})')
            if sys.version_info[:2] != (3, 12):
                raise ValueError('Use 64-bit Python 3.12 for the pinned test wheels')
            verify_inputs()
            print(f'PASS: pinned inputs; {len(load_units())} compiler units; {len(fixtures())} fixtures')
            print('PowerShell: ' + (shutil.which('pwsh') or 'not on PATH (optional for exact builds)'))
            if args.build:
                from validation_workflow import validation_inputs
                build = args.build.resolve()
                report = json.loads((build / 'validation.json').read_text(encoding='utf-8'))
                if (report.get('status') != 'passed' or report.get('mode') not in ('exact', 'full')
                        or report.get('validation_inputs') != validation_inputs()):
                    raise ValueError('Build validation is missing, incomplete, or stale; rerun validate')
                artifacts = report.get('artifact_hashes', {})
                if not artifacts or any(digest(build / name) != value for name, value in artifacts.items()):
                    raise ValueError('Validated build artifacts changed; rerun validate')
                assembly = json.loads((build / 'asm/assembly-build.json').read_text(encoding='utf-8'))
                if any(digest(build / 'asm' / row['binary']) != row['binary_sha256']
                       for row in assembly['units']):
                    raise ValueError('Validated assembly output changed; rerun validate')
                assert_fresh(build)
                verified_reference(build / 'FATE.EXE')
                print(f'PASS: completed {report["mode"]} validation is current')
            return
        if args.command == 'context':
            if args.rea_span and not args.ghidra_dir:
                raise ValueError('--rea-span requires --ghidra-dir')
            if args.ghidra_dir and not args.reference:
                raise ValueError('--ghidra-dir requires --reference')
            context = routine_context(args.routine)
            if args.reference:
                from restoration_context import add_reference_context
                if args.dependencies:
                    sys.path.insert(0, str(args.dependencies.resolve()))
                add_reference_context(context, args.routine,
                                      verified_reference(args.reference), args.ghidra_dir,
                                      rea_span=args.rea_span)
            print(json.dumps(context, indent=2))
            return
        args.build = args.build.resolve()
        if args.build.parent != ROOT / 'work' or not re.fullmatch(r'[A-Za-z0-9_-]+', args.build.name):
            raise ValueError('--build must be a named directory directly under work/')
        if args.command == 'validate' and args.smoke and not args.full:
            raise ValueError('--smoke requires --full')
        if args.command == 'validate' and not args.changed:
            if args.fixtures:
                raise ValueError('--fixtures requires probe or validate --changed; use --full for all fixtures')
            options = ['--resume'] if args.build.exists() and not args.clean else []
            options.append('--full' if args.full else '--exact')
            if args.reference:
                options.extend(('--reference', str(args.reference.resolve())))
            if args.smoke:
                options.append('--smoke')
            if args.dependencies:
                options.extend(('--dependencies', str(args.dependencies)))
            raise SystemExit(subprocess.call([
                sys.executable, str(TOOLS / 'verify_ci_build.py'), '--build', str(args.build),
                '--jobs', str(args.jobs), *options], cwd=ROOT))
        if args.reference is None:
            raise ValueError('--reference is required for targeted checks')
        args.reference = args.reference.resolve()
        if args.command == 'behavior':
            behavior(args)
            return
        if args.command == 'probe':
            provided = (args.symbol is not None, args.raw_offset is not None, args.size is not None)
            if any(provided) and not all(provided):
                raise ValueError('Research probes require --symbol, --raw-offset, and --size together')
            units = resolve_units(args.routine)
            if len(units) != 1:
                raise ValueError('Choose a single variant by its DOS object name')
            names = [units[0].name]
        else:
            if args.clean:
                raise ValueError('--clean requires an exact or full build, not --changed')
            previous = read_provenance(args.build)
            if not previous.get('tools'):
                raise ValueError('No provenance baseline; run validate first')
            states = current_states(load_units(), previous['tools'])
            names = [name for name, state in states.items()
                     if not is_current(args.build, name, state, previous['units'])]
            if not names:
                print('No changed compiler units; no validation performed.')
                return
        targeted(args, names)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f'FAIL: {error}\n')


if __name__ == '__main__':
    main()
