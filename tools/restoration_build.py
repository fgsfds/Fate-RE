"""Content-addressed, windowless Watcom compilation and build provenance."""
import argparse
from dataclasses import dataclass
from datetime import datetime
from hashlib import sha256
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / 'tools'
MANIFEST = TOOLS / 'data/restoration-units.txt'
DEFAULT_FLAGS = '/4r /s /or /bt=dos'
COMPILERS = {
    '105': '1b97a68f7b8a3efd89b05f64ce99836b1e533f398699305f96dc423254939d6a',
    '106': 'a257b6a25a95f02b404c4571839297af0a8cd941479f4dd19149ea949fd88c42',
}
RUNNER_HASH = 'f3b2864d171319728baaf95c1188e7b98d5b9ce2bb13768b5272e3ec5c94f4f4'
DOSBOX_HASH = 'dcfd46fa521f5ce89dce3bf026056f3a1d15533f80321ee887403e30d7949f5e'
HEADERS = ('fate/copybuf.h fate/menurec.h fate/menucall.h fate/cfgabi.h fate/dosio.h '
           'fate/navdata.h fate/sndslot.h fate/levmods.h fate/dpmiregs.h runtime/rtstream.h').split()
INCLUDES = dict(zip(
    'ceilhl cacheglo msgconst line256 line16 lines modes16 clear2d grid2d'.split(),
    ('engine/ceilhl cache/globals cache/messages_const engine/drawline256 engine/drawline16 '
     'engine/lines engine/modes16 engine/clear2dscreen engine/draw2dgrid').split()))
INCLUDES.update({'getpkt': 'network/getpkt', 'netctrl': 'network/netctrl',
                 'ipxctx': 'network/ipxctx'})
# Preserve existing initialized-DATA object provenance. CODE comparisons ignore
# volatile OMF timestamps; these historical DATA hashes still require them.
SOURCE_TIMES = {
    **dict.fromkeys(('animdefs.c', 'navdata.c', 'navdata.h'), '2026-11-13T04:23:26'),
    'cacheunt.c': '2026-11-13T00:54:54', 'cacheprf.c': '2026-11-13T00:11:44',
    'initcach.c': '2026-11-12T23:48:20', 'allocach.c': '2026-11-12T23:46:18',
    'agecache.c': '2026-11-12T23:42:00', 'report.c': '2026-11-13T00:07:36',
    'initgr.c': '2026-11-13T00:03:20', 'uninitgr.c': '2026-11-12T23:57:48',
    'kopen4.c': '2026-11-12T23:58:30', 'kread.c': '2026-11-12T23:57:48',
    'klseek.c': '2026-11-12T23:52:34', 'kfilelen.c': '2026-11-12T23:52:34',
    'kclose.c': '2026-11-12T23:55:20', 'msgconst.c': '2026-11-13T00:50:50',
    'cachemsg.c': '2026-11-13T00:35:06', 'cacheglo.c': '2026-11-13T00:38:36',
    'forcecon.c': '2026-11-13T02:41:10', 'maintext.c': '2026-11-13T03:37:10',
    'mousedef.c': '2026-11-13T10:47:10', 'netdefs.c': '2026-11-13T02:05:40',
}


def digest(path):
    return sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, value):
    path = Path(path)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')
    temporary.replace(path)


@dataclass(frozen=True)
class Unit:
    source: str
    name: str
    flags: str = DEFAULT_FLAGS
    staged: str = ''

    @property
    def filename(self):
        return (self.staged or self.name) + '.c'

    @property
    def command(self):
        return f'wcc386 {self.filename} {self.flags} /fo={self.name}.obj > {self.name}.log'


def load_units(path=MANIFEST):
    units = []
    for number, line in enumerate(Path(path).read_text(encoding='ascii').splitlines(), 1):
        line = line.partition('#')[0].strip()
        if not line:
            continue
        fields = line.split(maxsplit=2)
        if len(fields) < 2:
            raise ValueError(f'Invalid unit at {path}:{number}')
        source, name = fields[:2]
        flags = fields[2] if len(fields) == 3 else DEFAULT_FLAGS
        if (not re.fullmatch(r'(engine|cache|fate|network|runtime)/[a-z0-9_]+', source)
                or not re.fullmatch(r'[a-z0-9_]{1,8}', name)
                or not all(re.fullmatch(r'/[A-Za-z0-9_=]+', f) for f in flags.split())):
            raise ValueError(f'Unsafe unit at {path}:{number}')
        units.append(Unit(source, name, flags))
    for board in range(25):
        suffix = f'{board + 1:02}'
        flags = '/4r /s' + (' /or' if board != 24 else '')
        units.append(Unit('fate/sprite_path_initializers', 'path' + suffix,
                          flags + f' /bt=dos /dBOARD_SUFFIX=_{suffix} /dBOARD_INDEX={board}',
                          'brdpath'))
    if len({unit.name for unit in units}) != len(units):
        raise ValueError('Duplicate DOS object name')
    return units


def staged_sources(units):
    files = {Path(name).name: ROOT / 'src' / name for name in HEADERS}
    files.update({name + '.c': ROOT / 'src' / (source + '.c')
                  for name, source in INCLUDES.items()})
    for unit in units:
        source = ROOT / 'src' / (unit.source + '.c')
        if unit.filename in files and files[unit.filename] != source:
            raise ValueError('Conflicting staged source: ' + unit.filename)
        files[unit.filename] = source
    return files


def dependencies(source, staged):
    """Conservatively include both preprocessor branches, including nested .c files."""
    found = {}
    # Windows TEMP may use an 8.3 alias (RUNNER~1), while resolving a file
    # expands it to the long name. Compare paths in the same canonical form.
    root = ROOT.resolve()

    def visit(path):
        path = path.resolve()
        relative = path.relative_to(root).as_posix()
        if relative in found:
            return
        blob = path.read_bytes()
        found[relative] = sha256(blob).hexdigest()
        for operand in re.findall(r'^\s*#\s*include\s+([^\r\n]+)', blob.decode('latin-1'), re.M):
            match = re.match(r'["<]([^">]+)[">]', operand)
            if match is None:
                raise ValueError(f'Cannot safely cache computed include in {relative}: {operand}')
            name = match[1]
            # Short-name branches refer to staged aliases; inactive long-name
            # branches are resolved against the original source directory.
            included = staged.get(name, path.parent / name)
            if not included.is_file():
                raise ValueError(f'Cannot resolve include {name} in {relative}')
            visit(included)

    visit(source)
    return dict(sorted(found.items()))


def tool_identity(compiler, dosbox, version):
    paths = {compiler / 'wcc386.exe': COMPILERS[version],
             compiler / 'w32run.exe': RUNNER_HASH, dosbox: DOSBOX_HASH}
    for path, expected in paths.items():
        if digest(path) != expected:
            raise ValueError(f'Tool hash mismatch: {path}')
    return {path.name.lower(): expected for path, expected in paths.items()}


def unit_state(unit, staged, identity):
    state = {
        'source': unit.source, 'staged': unit.filename, 'flags': unit.flags,
        'inputs': dependencies(ROOT / 'src' / (unit.source + '.c'), staged),
        'tools': identity, 'driver_sha256': digest(__file__),
        # Hash this unit's registration, not the entire manifest: adding an
        # unrelated restoration must not invalidate every existing object.
        'command': unit.command,
        # Include timezone for historical local timestamps embedded in OMF.
        'timezone': list(time.tzname),
    }
    key = sha256(json.dumps(state, sort_keys=True).encode()).hexdigest()
    return dict(key=key, **state)


def read_provenance(build):
    path = build / 'build-provenance.json'
    return json.loads(path.read_text(encoding='utf-8')) if path.is_file() else {'units': {}}


def current_states(units, identity):
    staged = staged_sources(load_units())
    return {unit.name: unit_state(unit, staged, identity) for unit in units}


def is_current(build, name, state, previous):
    row = previous.get(name, {})
    output = build / (name + '.obj')
    return (row.get('key') == state['key'] and output.is_file()
            and digest(output) == row.get('object_sha256'))


def assert_fresh(build, names=None):
    previous = read_provenance(build)
    identity = previous.get('tools')
    if not identity:
        raise ValueError('No build provenance; recompile before validating')
    all_units = load_units()
    if names is not None and set(names) - {unit.name for unit in all_units}:
        raise ValueError('Unknown objects requested for freshness validation')
    units = [unit for unit in all_units if names is None or unit.name in names]
    states = current_states(units, identity)
    stale = [unit.name for unit in units
             if not is_current(build, unit.name, states[unit.name], previous['units'])]
    if stale:
        raise ValueError('Stale/missing objects: ' + ', '.join(stale[:12])
                         + (' ...' if len(stale) > 12 else '') + '; recompile first')
    return states


def select_units(units, names):
    if not names:
        return units
    wanted = {Path(name).stem.lower() for name in names}
    known = {unit.name for unit in units}
    if wanted - known:
        raise ValueError('Unknown objects: ' + ', '.join(sorted(wanted - known)))
    return [unit for unit in units if unit.name in wanted]


def run_compiler_batch(build, units, dosbox):
    """Run already-staged, pinned compiler inputs in one bounded hidden DOSBox."""
    (build / 'compile.bat').write_text(batch_commands(units), encoding='ascii', newline='')
    config = build / 'engine.conf'
    config.write_text(
        '[sdl]\nfullscreen=false\noutput=surface\n[dosbox]\nmemsize=31\n'
        '[cpu]\ncore=dynamic\ncycles=max\n[mixer]\nnosound=true\n[midi]\nmpu401=none\n'
        f'[autoexec]\nmount c "{build}"\nc:\ncall compile.bat\nexit\n', encoding='ascii')
    (build / 'matrix.txt').write_text('PENDING', encoding='ascii')
    env = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
    with (build / 'dosbox.log').open('w') as log:
        result = subprocess.run(
            [dosbox, '-conf', config, '-noconsole'], cwd=build, env=env,
            stdout=log, stderr=subprocess.STDOUT, timeout=180,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    if result.returncode or (build / 'matrix.txt').read_text().strip() != 'PASS':
        status = (build / 'active.txt').read_text().strip() if (build / 'active.txt').exists() else '?'
        logfile = build / (status + '.log')
        tail = '\n'.join(logfile.read_text(errors='replace').splitlines()[-12:]) if logfile.exists() else ''
        raise ValueError(f'Compiler failed in {status}; log: {logfile}\n{tail}')


def compile_units(build, names=None, *, incremental=False, version='105',
                  compiler=None, dosbox=None, cache=None):
    start = time.perf_counter()
    build = Path(build).resolve()
    if build.parent != (ROOT / 'work').resolve() or not re.fullmatch(r'[\w-]+', build.name, re.ASCII):
        raise ValueError('Compiler scratch must be a named directory directly under work/')
    default_compiler = (TOOLS / 'inputs/watcom/binw' if version == '105'
                        else ROOT / 'reference/watcom106/binw')
    compiler = Path(compiler or default_compiler).resolve()
    dosbox = Path(dosbox or TOOLS / 'inputs/dosbox/DOSBox.exe').resolve()
    identity = tool_identity(compiler, dosbox, version)
    units = load_units()
    selected = select_units(units, names)
    states = current_states(selected, identity)
    previous = read_provenance(build)
    dirty = [unit for unit in selected if not incremental
             or not is_current(build, unit.name, states[unit.name], previous['units'])]
    build.mkdir(parents=True, exist_ok=True)
    staged = staged_sources(units)
    for name, source in staged.items():
        shutil.copy2(source, build / name)
    for name, value in SOURCE_TIMES.items():
        stamp = datetime.fromisoformat(value).timestamp()
        os.utime(build / name, (stamp, stamp))
    for name in ('wcc386.exe', 'w32run.exe'):
        shutil.copy2(compiler / name, build / name)
    # Always retain the COMPLETE plan for marker builds, even after a one-unit probe.
    (build / 'engine.bat').write_text(batch_commands(units), encoding='ascii', newline='')
    cache = Path(cache or ROOT / 'work/cache/objects')
    hits, pending = [], []
    for unit in dirty:
        entry = cache / states[unit.name]['key']
        record = entry / 'entry.json'
        try:
            cached = json.loads(record.read_text())
            valid = (incremental and cached['key'] == states[unit.name]['key']
                     and digest(entry / 'code.obj') == cached['object_sha256']
                     and digest(entry / 'compile.log') == cached['log_sha256'])
        except (OSError, ValueError, KeyError):
            valid = False
        if valid:
            shutil.copy2(entry / 'code.obj', build / (unit.name + '.obj'))
            shutil.copy2(entry / 'compile.log', build / (unit.name + '.log'))
            hits.append(unit)
        else:
            pending.append(unit)
    provenance_file = build / 'build-provenance.json'
    # Invalidate pending entries BEFORE launching DOSBox: failed/partial compiles
    # must never inherit a previous successful provenance entry.
    for unit in dirty:
        previous['units'].pop(unit.name, None)
    previous['tools'] = identity
    write_json(provenance_file, previous)
    if pending:
        run_compiler_batch(build, pending, dosbox)
    for unit in dirty:
        obj, log = build / (unit.name + '.obj'), build / (unit.name + '.log')
        text = log.read_text(encoding='ascii', errors='replace')
        if re.search(r'\bError!', text) or not re.search(r',\s*0 errors', text):
            raise ValueError(f'Compiler diagnostics failed: {log}\n' + '\n'.join(text.splitlines()[-12:]))
        row = dict(states[unit.name], object_sha256=digest(obj), log_sha256=digest(log))
        previous['units'][unit.name] = row
        if unit in pending:
            entry = cache / row['key']
            entry.mkdir(parents=True, exist_ok=True)
            shutil.copy2(obj, entry / 'code.obj')
            shutil.copy2(log, entry / 'compile.log')
            write_json(entry / 'entry.json', row)
    previous['last_run'] = {
        'selected': [unit.name for unit in selected],
        'compiled': [unit.name for unit in pending], 'cache_hits': [unit.name for unit in hits],
        'seconds': round(time.perf_counter() - start, 4),
    }
    write_json(provenance_file, previous)
    print(f'Compile: {len(pending)} compiled, {len(hits)} cache hits, '
          f'{len(selected) - len(dirty)} unchanged; {previous["last_run"]["seconds"]:.2f}s')
    return previous['last_run']


def batch_commands(units):
    lines = ['@echo off', 'set WATCOM=C:\\']
    for unit in units:
        lines.extend((f'echo {unit.name} > active.txt', unit.command, 'if errorlevel 1 goto failed'))
    lines.extend(('echo PASS > matrix.txt', 'goto done', ':failed', 'echo FAIL > matrix.txt', ':done'))
    return '\r\n'.join(lines) + '\r\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path)
    parser.add_argument('--objects', nargs='+')
    parser.add_argument('--incremental', action='store_true')
    parser.add_argument('--version', choices=COMPILERS, default='105')
    parser.add_argument('--compiler', type=Path)
    parser.add_argument('--dosbox', type=Path)
    args = parser.parse_args()
    compile_units(args.build, args.objects, incremental=args.incremental,
                  version=args.version, compiler=args.compiler, dosbox=args.dosbox)


if __name__ == '__main__':
    main()
