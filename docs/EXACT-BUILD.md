# Reproducing the October 1996 FATE.EXE

On 64-bit Windows, run from the repository root with 64-bit Python 3.12 on PATH,
as used in CI. PowerShell is optional for the exact build.

```powershell
python tools/verify_ci_build.py
```

The Python entry point verifies the bundled inputs and calls the Python compiler driver to
compile the C sources with Watcom 10.5 under DOSBox, then assembles the NASM
sources and packs the LE executable at `work/ci-build/FATE.EXE`.
It checks the pinned size of 741,347 bytes and SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
Use `--resume` to rebuild and recheck image identity while reusing only verified compiler and
NASM outputs, or use `--build work/<new-name>` for another clean build.
Default validation is exact-image acceptance only: no unit-test suite, behavioral
fixtures, test-wheel installation, or game smoke. Add `--full --jobs 4` for the
broad regression suite on tooling changes or periodic checkpoints; fixtures then
run concurrently. Smoke requires the separate, explicit `--full --smoke` option
and is skipped for the current restoration task.
See the [focused restoration workflow](RESTORATION-WORKFLOW.md) for probes,
changed-unit checks, provenance, bounded logs, and stage timings.

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

The explicit `--full` build writes and checks `work/ci-build/c.json` and
`work/ci-build/assembly.json` against the checked-in CODE inventories. It checks
the Watcom bytes and LE pointer sites and targets against the hash-verified
executable, so these checks run from a fresh checkout.

After building, use the commands below with a separate copy of the original
demo to compare directly and regenerate the C, assembly, DATA, and font reports. Run the commands
in the same PowerShell session if you plan to reproduce the
[START gameplay reports](GAMEPLAY.md#reproducing-the-door-and-barrel-reports).
The DATA and gameplay checks use Unicorn 2.1.4, and the gameplay checks also
use Capstone 5.0.9.

```powershell
$demo = 'C:/path/to/Fate demo'
$original = Join-Path $demo FATE.EXE
$build = 'work/ci-build'
$env:PYTHONPATH = '<dependency-cache-directory>'
python tools/compare_exe.py $original "$build/FATE.EXE"
python tools/verify_c_suite.py $original $build --output "$build/c.json"
python tools/verify_assembly_suite.py $original "$build/asm" "$build/c.json" --output "$build/assembly.json"
python tools/verify_initialized_suite.py $original $build "$build/asm" --output "$build/data.json"
python tools/graphics_font_dependency.py $original tools/inputs/watcom/lib386/dos/GRAPH.LIB --output "$build/fonts.json"
```

## GitHub Actions

To run the Python unit tests by themselves after installing the pinned wheels:

```powershell
$env:PYTHONPATH = "tools;<dependency-cache-directory>"
python -m unittest discover -s tools/tests -q
```

The [build workflow](../.github/workflows/build.yml) always checks the bundled
inputs and verifies the freshly rebuilt executable against the pinned size and
SHA-256. Source/documentation-only pushes use exact mode. Tooling/configuration
changes, first pushes, and manual workflow runs use `--full`, adding Python tests,
compiler regressions, C/assembly inventories, and behavioral fixtures.
Neither mode runs game smoke implicitly.
