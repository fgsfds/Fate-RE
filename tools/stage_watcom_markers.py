"""Stage an isolated marker build from the resulting exact DOS build inputs."""
import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import re
import subprocess
from shutil import copy2

from mark_watcom_aux import instrument


def stage(build, marker_dir, retry_report=None):
    build, marker_dir = build.resolve(), marker_dir.resolve()
    retry_objects = set()
    if retry_report:
        previous = json.loads(retry_report.read_text(encoding='utf-8'))
        if previous['inventory_sha256'] != sha256((build / 'c.json').read_bytes()).hexdigest():
            raise ValueError('Retry report belongs to a different exact build inventory')
        retry_objects = {
            row['object'].lower() for row in previous['routines']
            if row.get('reason', '').startswith(('Conflicting marker', 'Unbalanced markers'))
        }
        if not retry_objects:
            raise ValueError('Retry report has no unresolved marker pairs')
    marker_dir.mkdir(parents=True, exist_ok=False)
    for name in ('wcc386.exe', 'w32run.exe'):
        copy2(build / name, marker_dir / name)
    for path in build.iterdir():
        if path.suffix.lower() in ('.c', '.h', '.inc') and path.is_file():
            try:
                text, _ = instrument(path.read_text(encoding='latin-1'), unique_ends=bool(retry_objects))
            except (UnicodeError, ValueError) as error:
                text = f'#error Unsupported marker source {path.name}\n'
                print(f'Unsupported {path.name}: {error}')
            (marker_dir / path.name).write_text(text, encoding='latin-1')
    commands = ['@echo off', 'set WATCOM=C:\\']
    engine = (build / 'engine.bat').read_text(encoding='ascii')
    compile_lines = [line for line in engine.splitlines()
                     if re.match(r'^wcc386 \w+\.c ', line, re.I)]
    if retry_objects:
        compile_lines = [line for line in compile_lines
                         if any(arg[4:].lower() in retry_objects
                                for arg in line.split() if arg.lower().startswith('/fo='))]
    if not compile_lines:
        raise ValueError('Build command file has no compilations')
    commands.extend(compile_lines)
    commands.append('echo DONE > done.txt')
    (marker_dir / 'count.bat').write_text('\n'.join(commands)+'\n', encoding='ascii')
    config = f'''[sdl]
fullscreen=false
output=surface
[dosbox]
memsize=31
[cpu]
core=dynamic
cycles=max
[mixer]
nosound=true
[midi]
mpu401=none
[autoexec]
mount c "{marker_dir.as_posix()}"
c:
call count.bat
exit
'''
    (marker_dir / 'count.conf').write_text(config, encoding='ascii')
    print(f'Staged {len(compile_lines)} isolated compilations')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path)
    parser.add_argument('marker_dir', type=Path)
    parser.add_argument('--dosbox', type=Path, help='Run the staged count with this DOSBox executable')
    parser.add_argument('--retry-report', type=Path,
                        help='Retry objects with conflicting or missing end markers')
    args = parser.parse_args()
    stage(args.build, args.marker_dir, args.retry_report)
    if args.dosbox:
        directory = args.marker_dir.resolve()
        env = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
        subprocess.run([args.dosbox.resolve(), '-conf', directory / 'count.conf', '-noconsole'],
                       cwd=directory, env=env, check=True, timeout=180,
                       creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        if (directory / 'done.txt').read_text(encoding='ascii').strip() != 'DONE':
            raise ValueError('Marker compilation did not complete')
