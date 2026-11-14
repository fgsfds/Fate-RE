# Reproducing the October 1996 FATE.EXE

On 64-bit Windows, run from the repository root with PowerShell 7.4 or later
and 64-bit Python 3.12 on PATH, as used in CI.

```powershell
python tools/verify_ci_build.py
```

The Python entry point verifies the bundled inputs and installs the pinned test
wheels under the build directory. It calls the PowerShell compiler driver to
compile the C sources with Watcom 10.5 under DOSBox, then assembles the NASM
sources and packs the LE executable at `work/ci-build/FATE.EXE`.
It checks the pinned size of 741,347 bytes and SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
Move the previous output directory before rerunning the script.

The [pinned inputs](../tools/inputs.sha256) include the 10,832-byte DOS/4G stub
from `EDITART.EXE`, the Watcom 10.5 compiler and graphics library, NASM 3.02,
DOSBox 0.74-3, and `DOS4GW.EXE` for the smoke test. The builder also accepts
either of the pinned `EDITART.EXE` versions as its stub source.
Use `--graph-library` to supply the same graphics library from another path.

The packer generates the LE headers and page map. The
[relocation inventory](../tools/data/le-relocation-order.json)
records source offsets and target object numbers in the original order.
Target offsets and their encoding widths come from the generated operands.
The packer accounts for nine cross-page records and the implicit high zero
byte of the final CRT relocation.

## Running the result

Copy the demo directory, then replace `FATE.EXE` in that copy with the rebuilt
executable. Keep the demo's assets alongside it. In DOSBox, mount the copy and
start the map using the demo's documented `FATE mapname` syntax.

```text
mount c "C:\path\to\Fate demo copy"
c:
FATE START
```

Choose **New Game** and **Easy** to reach the prison cell. The original and
rebuilt executables both ran `FATE -HELP` in separate demo copies. Both
returned exit code zero and produced identical output with SHA-256
`a19103df99d7bcd78303e7557da8a8fb8d540ca1efe5664bb3c2e3a30baabb6d`.
See [the recorded gameplay observations](GAMEPLAY.md#dosbox-observations).

## Verification tools

After building, use the commands below with a separate copy of the original
demo to regenerate the C, assembly, DATA, and font reports. Run the commands
in the same PowerShell session if you plan to reproduce the
[START gameplay reports](GAMEPLAY.md#reproducing-the-door-and-barrel-reports).
The DATA and gameplay checks use Unicorn 2.1.4, and the gameplay checks also
use Capstone 5.0.9.

```powershell
$demo = 'C:/path/to/Fate demo'
$original = Join-Path $demo FATE.EXE
$build = 'work/ci-build'
$env:PYTHONPATH = "$build/python-deps"
python tools/compare_exe.py $original "$build/FATE.EXE"
python tools/verify_c_suite.py $original $build --output "$build/c.json"
python tools/verify_assembly_suite.py $original "$build/asm" "$build/c.json" --output "$build/assembly.json"
python tools/verify_initialized_suite.py $original $build "$build/asm" --output "$build/data.json"
python tools/graphics_font_dependency.py $original tools/inputs/watcom/lib386/dos/GRAPH.LIB --output "$build/fonts.json"
```

## GitHub Actions

To run the Python unit tests by themselves after installing the pinned wheels:

```powershell
$env:PYTHONPATH = "tools;work/ci-build/python-deps"
python -m unittest discover -s tools/tests -q
```

The [build workflow](../.github/workflows/build.yml) checks the bundled input
hashes, runs the Python tests, and verifies the rebuilt executable against the
pinned size and SHA-256. It also checks the START hook fixtures and runs
`FATE -HELP` in DOSBox.
