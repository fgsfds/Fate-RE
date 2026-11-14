"""Build FATE.EXE with the pinned tools and run the CI checks."""

import os
import shutil
import subprocess
import sys
from hashlib import sha256
from pathlib import Path
import re

from graphics_font_dependency import GRAPH_LIBRARY


TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent
INPUTS = TOOLS / "inputs"


def verify_inputs():
    for line in (TOOLS / "inputs.sha256").read_text(encoding="ascii").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if match is None:
            raise ValueError(f"Invalid checksum entry: {line}")
        expected, relative = match.groups()
        if sha256((INPUTS / relative).read_bytes()).hexdigest() != expected:
            raise ValueError(f"SHA-256 mismatch: {relative}")

def smoke_test(build):
    smoke = build / "smoke"
    smoke.mkdir()
    shutil.copyfile(build / "FATE.EXE", smoke / "FATE.EXE")
    shutil.copyfile(INPUTS / "demo" / "DOS4GW.EXE", smoke / "DOS4GW.EXE")
    (smoke / "smoke.bat").write_text(
        "@echo off\nFATE -HELP > HELP.TXT\nif errorlevel 1 goto done\n"
        "echo PASS > STATUS.TXT\n:done\n", encoding="ascii", newline="\r\n",
    )
    config = build / "smoke.conf"
    config.write_text(
        f'[dosbox]\nmemsize=31\n[mixer]\nnosound=true\n[autoexec]\n'
        f'mount c "{smoke}"\nc:\ncall smoke.bat\nexit\n', encoding="ascii",
    )
    env = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy")
    subprocess.run(
        [INPUTS / "dosbox" / "DOSBox.exe", "-conf", config, "-noconsole"],
        cwd=smoke, env=env, timeout=30, check=True,
        creationflags=subprocess.CREATE_NO_WINDOW,
    )
    status = smoke / "STATUS.TXT"
    if not status.is_file() or status.read_text(encoding="ascii").strip() != "PASS":
        raise ValueError("FATE -HELP failed")
    expected = "a19103df99d7bcd78303e7557da8a8fb8d540ca1efe5664bb3c2e3a30baabb6d"
    if sha256((smoke / "HELP.TXT").read_bytes()).hexdigest() != expected:
        raise ValueError("FATE -HELP output differs")
    print("PASS: FATE -HELP in DOSBox")


def main():
    verify_inputs()
    build = ROOT / "work" / "ci-build"
    build.mkdir(parents=True, exist_ok=False)
    dependencies = build / "python-deps"
    subprocess.run(
        [sys.executable, "-m", "pip", "install", "--disable-pip-version-check",
         "--no-index", "--find-links", INPUTS / "wheels", "--target", dependencies,
         "unicorn==2.1.4", "capstone==5.0.9"],
        cwd=ROOT, check=True,
    )

    env = dict(os.environ, PYTHONPATH=os.pathsep.join((str(TOOLS), str(dependencies))))

    def python(*args):
        subprocess.run([sys.executable, *args], cwd=ROOT, env=env, check=True)

    python("-m", "unittest", "discover", "-s", TOOLS / "tests", "-q")
    compile_result = subprocess.run(
        ["pwsh", "-NoProfile", "-File", TOOLS / "run_engine_dos.ps1",
         "-Version", "105", "-Leaves", "-ScratchName", build.name,
         "-CompilerDirectory", INPUTS / "watcom" / "binw",
         "-DosboxDirectory", INPUTS / "dosbox"],
        cwd=ROOT, stdout=subprocess.PIPE, text=True,
    )
    lines = compile_result.stdout.splitlines()
    print("\n".join(lines if compile_result.returncode else lines[-6:]), flush=True)
    compile_result.check_returncode()
    assembly = build / "asm"
    executable = build / "FATE.EXE"
    python(TOOLS / "build_assembly.py", INPUTS / "nasm" / "nasm.exe", assembly)
    python(TOOLS / "build_fate_exe.py", build, assembly, INPUTS / "demo" / "dos-stub.bin",
           executable, "--graph-library", ROOT / GRAPH_LIBRARY)
    python(TOOLS / "check_start_hook.py", executable, "--output", build / "start-hook.json")
    smoke_test(build)


if __name__ == "__main__":
    main()
