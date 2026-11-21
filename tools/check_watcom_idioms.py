"""Cached, timestamp-independent Watcom idiom regressions; never game coverage."""
import argparse
from dataclasses import asdict
from hashlib import sha256
import json
from pathlib import Path
import re
import shutil

from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from restoration_build import (
    ROOT, TOOLS, Unit, digest, run_compiler_batch, tool_identity, write_json,
)
from verification_diagnostics import code_mismatch

SOURCE = TOOLS / 'tests/fixtures/watcom_idioms.c'
EXPECTED = TOOLS / 'data/watcom-idioms.json'
VARIANTS = {
    'id4': '/4r /s /or /bt=dos',
    'id3': '/3r /s /bt=dos',
    'idsize': '/4r /s /os /bt=dos',
}


def snapshot(blob):
    """Retain code, layout and fixups, excluding volatile OMF comment records."""
    segments, publics = read_object(blob)
    return dict(
        segments=[dict(segment=index, name=segment['name'], cls=segment['cls'],
                       bytes=bytes(segment['data']).hex())
                  for index, segment in enumerate(segments) if segment is not None],
        publics=[list(public) for public in publics],
        externals=read_externals(blob)[1:],
        fixups=json.loads(json.dumps([asdict(fixup) for fixup in read_fixups(blob)])))


def probe_key(source_hash, flags, identity):
    inputs = dict(source_sha256=source_hash, flags=flags, tools=identity,
                  runner_sha256=digest(__file__),
                  compiler_driver_sha256=digest(TOOLS / 'restoration_build.py'))
    return sha256(json.dumps(inputs, sort_keys=True).encode()).hexdigest()


def verify_snapshot(name, actual, expected):
    if actual == expected:
        return
    if actual['segments'] != expected['segments']:
        for left, right in zip(actual['segments'], expected['segments']):
            if left['bytes'] != right['bytes']:
                raise ValueError(code_mismatch(
                    'Watcom idiom ' + name, bytes.fromhex(left['bytes']), bytes.fromhex(right['bytes'])))
    raise ValueError(f'Watcom idiom {name}: public layout, segment metadata, externals, or fixups changed')


def check(build, output=None, *, clean=False, observe=False):
    build = Path(build).resolve()
    work = (ROOT / 'work').resolve()
    output = Path(output).resolve() if output else build / 'report.json'
    if build == work or not build.is_relative_to(work) or not output.is_relative_to(work):
        raise ValueError('Compiler probes and reports must stay under ignored work/ directories')
    compiler = TOOLS / 'inputs/watcom/binw'
    dosbox = TOOLS / 'inputs/dosbox/DOSBox.exe'
    identity = tool_identity(compiler, dosbox, '105')
    source_hash = digest(SOURCE)
    expected = None
    if not observe:
        expected = json.loads(EXPECTED.read_text(encoding='utf-8'))
        if (expected.get('schema') != 1 or expected['source_sha256'] != source_hash
                or expected['compiler_sha256'] != identity['wcc386.exe']
                or expected['flags'] != VARIANTS):
            raise ValueError('Compiler-probe inputs changed; review an --observe report before updating expectations')
    build.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    write_json(output, dict(status='pending', purpose='compiler-regression', inventory_eligible=False))
    state_path = build / 'idiom-provenance.json'
    state = json.loads(state_path.read_text()) if state_path.is_file() else {}
    units = [Unit('compiler-probe', name, flags, 'idioms') for name, flags in VARIANTS.items()]
    keys = {name: probe_key(source_hash, flags, identity) for name, flags in VARIANTS.items()}
    dirty = []
    for unit in units:
        previous = state.get(unit.name, {})
        obj, log = build / (unit.name + '.obj'), build / (unit.name + '.log')
        if (clean or previous.get('key') != keys[unit.name] or not obj.is_file() or not log.is_file()
                or digest(obj) != previous.get('object_sha256')
                or digest(log) != previous.get('log_sha256')):
            dirty.append(unit)
            state.pop(unit.name, None)
    write_json(state_path, state)
    shutil.copy2(SOURCE, build / 'idioms.c')
    for name in ('wcc386.exe', 'w32run.exe'):
        shutil.copy2(compiler / name, build / name)
    if dirty:
        run_compiler_batch(build, dirty, dosbox)
    observed = {}
    for unit in units:
        obj, log = build / (unit.name + '.obj'), build / (unit.name + '.log')
        text = log.read_text(encoding='ascii', errors='replace')
        if re.search(r'\bError!', text) or not re.search(r',\s*0 errors', text):
            raise ValueError('Compiler-probe diagnostic errors: ' + str(log))
        observed[unit.name] = snapshot(obj.read_bytes())
        if expected is not None:
            verify_snapshot(unit.name, observed[unit.name], expected['variants'][unit.name])
        state[unit.name] = dict(key=keys[unit.name], object_sha256=digest(obj), log_sha256=digest(log))
    write_json(state_path, state)
    result = dict(schema=1, purpose='compiler-regression', inventory_eligible=False,
                  status='observed' if observe else 'passed', source_sha256=source_hash,
                  compiler_sha256=identity['wcc386.exe'], flags=VARIANTS, variants=observed,
                  compiled=len(dirty), reused=len(units)-len(dirty))
    write_json(output, result)
    print(f'{"OBSERVED" if observe else "PASS"}: Watcom idioms; '
          f'{len(dirty)} compiled, {len(units)-len(dirty)} reused; {output}')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, default=ROOT / 'work/watcom-idioms')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--clean', action='store_true')
    parser.add_argument('--observe', action='store_true',
                        help='Record observations under work/ without changing or passing expected snapshots')
    args = parser.parse_args()
    check(args.build, args.output, clean=args.clean, observe=args.observe)


if __name__ == '__main__':
    main()
