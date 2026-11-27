"""Reusable dependency environment, bounded stage logs, and fixture scheduling."""
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import threading
import time

from restoration_build import ROOT, TOOLS, digest, write_json
from restoration_registry import fixtures


def validation_inputs():
    paths = set(TOOLS.glob('*.py')) | set((TOOLS / 'tests').glob('*.py'))
    paths.update(path for path in (TOOLS / 'tests/fixtures').rglob('*')
                 if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc')
    paths.update(path for path in (ROOT / 'src').rglob('*')
                 if path.suffix.lower() in ('.c', '.h', '.asm'))
    paths.update(path for path in (TOOLS / 'data').iterdir() if path.is_file())
    paths.update((TOOLS / 'inputs.sha256', ROOT / 'docs/RECONSTRUCTION.md'))
    return {path.relative_to(ROOT).as_posix(): digest(path) for path in sorted(paths)}


def dependency_files(directory):
    return {p.relative_to(directory).as_posix(): digest(p)
            for p in sorted(directory.rglob('*')) if p.is_file()
            and '__pycache__' not in p.parts and p.suffix != '.pyc'
            and p.name != 'dependencies.json'}


def ensure_dependencies(directory=None):
    wheels = TOOLS / 'inputs/wheels'
    pins = dict(line.split('  ', 1)[::-1] for line in
                (TOOLS / 'inputs.sha256').read_text(encoding='ascii').splitlines())
    for wheel in wheels.glob('*.whl'):
        if digest(wheel) != pins.get('wheels/' + wheel.name):
            raise ValueError('Pinned dependency wheel changed: ' + wheel.name)
    identity = dict(python=sys.implementation.cache_tag, machine=platform.machine(),
                    wheels={p.name: digest(p) for p in sorted(wheels.glob('*.whl'))})
    key = sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()[:20]
    directory = Path(directory or ROOT / 'work/cache/python' / key).resolve()
    record = directory / 'dependencies.json'
    if directory.exists():
        if not record.is_file():
            raise ValueError(f'Incomplete/unmanaged dependency cache: {directory}; choose another directory')
        state = json.loads(record.read_text(encoding='utf-8'))
        if state['identity'] != identity or state['files'] != dependency_files(directory):
            raise ValueError(f'Dependency cache changed: {directory}; choose another directory')
    else:
        directory.mkdir(parents=True)
        result = subprocess.run(
            [sys.executable, '-m', 'pip', 'install', '--disable-pip-version-check',
             '--no-index', '--find-links', wheels, '--target', directory,
             'unicorn==2.1.4', 'capstone==5.0.9'],
            cwd=ROOT, capture_output=True, text=True)
        if result.returncode:
            (directory / 'install.log').write_text(result.stdout + result.stderr, encoding='utf-8')
            raise ValueError(f'Dependency install failed; {directory / "install.log"}\n'
                             + '\n'.join((result.stdout + result.stderr).splitlines()[-12:]))
        write_json(record, dict(identity=identity, files=dependency_files(directory)))
    return directory


def python_environment(dependencies):
    env = dict(os.environ)
    env['PYTHONPATH'] = os.pathsep.join((str(TOOLS), str(dependencies)))
    # Assertions are part of behavioral fixture validation. Never inherit -O.
    env.pop('PYTHONOPTIMIZE', None)
    return env


class StageRunner:
    def __init__(self, build, env):
        self.build = Path(build)
        self.env = env
        self.rows = []
        self.lock = threading.Lock()
        (self.build / 'logs').mkdir(parents=True, exist_ok=True)

    def call(self, name, command, timeout=180, quiet=False):
        path = self.build / 'logs' / (name + '.log')
        start = time.perf_counter()
        status = 'failed'
        try:
            with path.open('w', encoding='utf-8') as log:
                result = subprocess.run(command, cwd=ROOT, env=self.env, stdout=log,
                                        stderr=subprocess.STDOUT, timeout=timeout)
            if result.returncode:
                tail = '\n'.join(path.read_text(encoding='utf-8', errors='replace').splitlines()[-14:])
                raise ValueError(f'{name} failed ({result.returncode}); full log: {path}\n{tail}')
            status = 'passed'
        finally:
            seconds = round(time.perf_counter() - start, 4)
            with self.lock:
                self.rows.append(dict(stage=name, seconds=seconds, status=status,
                                      command=[str(arg) for arg in command], log=str(path)))
                write_json(self.build / 'stages.json', self.rows)
        if not quiet:
            print(f'{name}: PASS ({seconds:.2f}s)', flush=True)

    def python(self, name, *arguments):
        self.call(name, [sys.executable, *arguments])


def run_fixtures(runner, executable, objects=None, jobs=1):
    if not 1 <= jobs <= 8:
        raise ValueError('Fixture jobs must be between 1 and 8')
    selected = fixtures(objects)
    start = time.perf_counter()

    def run(fixture):
        runner.call(fixture.script, [sys.executable, *fixture.command(executable, runner.build)],
                    quiet=True)

    if jobs == 1:
        for fixture in selected:
            run(fixture)
    else:
        with ThreadPoolExecutor(max_workers=jobs) as pool:
            list(pool.map(run, selected))
    print(f'Fixtures: {len(selected)} passed ({time.perf_counter()-start:.2f}s, {jobs} workers)')
    return [fixture.script for fixture in selected]
