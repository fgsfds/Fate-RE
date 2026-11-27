# Fast reconstruction and validation

Run from the repository root with 64-bit Python 3.12. The exact build no longer
requires PowerShell; `tools/run_engine_dos.ps1 -Leaves` remains a compatibility
wrapper. Compiler invocations remain pinned, windowless Watcom 10.5 in DOSBox.

## Discover only the relevant context

```powershell
python tools/restore.py doctor
python tools/restore.py doctor --build work/restoration-build
python tools/restore.py context run_menu_loop
python tools/restore.py context strcpy_
```

The optional `doctor --build` check accepts current exact or full validation
reports and checks artifact hashes. It rejects stale results, source/tool changes,
and modified compiler/assembly artifacts.

`context` supports accepted C routines, DOS object names, source names, and
remaining assembly routines. Its bounded JSON includes source locations,
compiler options, exact spans, fixtures, nearby examples, and relevant failed
attempts. Follow those locations rather than reading complete registries,
inventories, or the entire attempts document.

## Prepare a worker context packet

ReverseApoc uses bounded per-function packets, Ghidra drafts, and an
independent exact gate. Fate uses the same discovery pattern with its existing
Watcom 10.5, OMF/LE, and whole-executable checks. ReverseApoc's original-image
splice and objdiff scores serve a different build and reporting model.
See [ReverseApoc workflow](https://github.com/ayrtondenner/ReverseApoc/blob/main/docs/workflow.md).

Use a routine symbol for reference-backed context. The packet adds a bounded
Capstone listing, the exact span and pinned hash, and a sample of LE sites and
targets. Supply the existing Capstone dependency directory when needed.

```powershell
python tools/restore.py context write_stream_descriptor --reference work/restoration-build/FATE.EXE --dependencies work/ci-build/python-deps --ghidra-dir work/ghidra-descriptor
```

Omit `--ghidra-dir` when the JSON alone is enough. The export directory must be
new. It contains `context.json` and a local flat image with LE pages placed at
their analysis addresses and internal 32-bit relocations applied. Keep both
files under ignored `work/`. The Capstone listing uses the original on-disk
operands. Use the LE sites and targets to relate those operands to Ghidra's
mapped addresses.

Run the optional draft step with a local Ghidra installation and its required
JDK. The raw image starts at address zero, so the entry and span values from
the packet can be used directly. This bypasses the need for a third-party LE
loader for the bounded analysis.

```powershell
$packet = Get-Content work/ghidra-descriptor/context.json -Raw | ConvertFrom-Json
& '<Ghidra>/support/analyzeHeadless.bat' work/ghidra-descriptor fate-context `
  -import work/ghidra-descriptor/fate-mapped.bin -loader BinaryLoader `
  -processor x86:LE:32:default -noanalysis -scriptPath tools/ghidra `
  -postScript FateContext.java $packet.ghidra.entry $packet.ghidra.span_bytes `
  -deleteProject *> work/ghidra-descriptor/ghidra.log
```

The Ghidra 12.2 command was tested on Windows with the software unsigned
integer-to-float conversion. If the launcher fails during Felix bundle
initialization, set application settings and cache paths inside the scratch
directory for that run. This resolved the Windows startup failure.

```powershell
$scratch = (Resolve-Path work/ghidra-descriptor).Path
$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    $env:JAVA_TOOL_OPTIONS = "$previousJavaOptions -Dapplication.settingsdir=""$scratch/settings"" -Dapplication.cachedir=""$scratch/cache"""
    # Run the headless command above in this block.
} finally {
    $env:JAVA_TOOL_OPTIONS = $previousJavaOptions
}
```

Ghidra supplies hypotheses about control flow and data use. Verify Watcom
parameter registers, flags, partial-register lifetimes, jump tables, and
shared tails against the disassembly and callers. A span that is a table or a
fragment of a larger routine may need manual analysis in Ghidra. The focused
probe and whole-image validation remain the acceptance checks.

## Optional REA inspection

REA can provide a second view of a selected routine through its Ghidra
provider. Use a host and REA release that support explicit raw 32-bit x86
imports. The documented Windows Ghidra provider excludes raw x86, and the
DOS MZ provider excludes LE executables. On Windows use the headless Ghidra
command above. [REA raw binary guide](https://github.com/morluto/rea/blob/main/docs/providers/raw-binary.md) · [Windows provider limits](https://github.com/morluto/rea/blob/main/docs/providers/windows-ghidra-p0.md)

```powershell
python tools/restore.py context i32_to_float --reference work/restoration-build/FATE.EXE --dependencies work/ci-build/python-deps --ghidra-dir work/rea-signed-float --rea-span
```

On a supported host with the REA CLI and Ghidra provider configured, run:

```sh
rea instructions /absolute/path/to/rea-span.bin 0x73f73 --target-format raw-binary --architecture x86 --entry-point 0x73f73 --provider ghidra --json
```

Both addresses in the example come from `rea.entry_point` in `context.json`.
REA maps file offset zero at that address. `rea-span.bin` contains exactly the
selected routine's loaded bytes, after Fate's internal LE relocations have
been applied. The packet records its SHA-256 and the reference executable's
SHA-256. The span omits surrounding code and data. Use the full mapped Ghidra
image to trace calls, cross-references, or branches that leave the span.
Save useful REA results in the same ignored scratch directory. The reference
disassembly, Watcom probe, relocation checks, and whole-image comparison
determine exact acceptance. [REA CLI guide](https://github.com/morluto/rea/blob/main/docs/getting-started/cli.md)

## Research patterns from Harvester

Alex Bevilacqua's Harvester series used Ghidra to guide a ScummVM
reimplementation. For Fate, apply those research methods before the normal
Watcom and byte-matching gates.

| When investigating | Evidence to capture |
| --- | --- |
| Unnamed functions | Follow filename, error-string, and interrupt references through their callers. Name symbols after the callers and consumers agree. [Part 1](https://alexbevi.com/blog/2026/03/14/reverse-engineering-a-dos-game-with-ghidra-and-codex/) |
| Visible behavior | Pick one concrete symptom, trace the state it reads or changes, and turn it into a focused regression scenario. [Part 2](https://alexbevi.com/blog/2026/03/17/reverse-engineering-harvester-with-ghidra-and-codex-part-2/) |
| File formats | Record proven field widths, offsets, strides, and which files supply directory metadata. Trace consumers alongside parsers. [Part 3](https://alexbevi.com/blog/2026/03/23/reverse-engineering-harvester-with-ghidra-and-codex-part-3-file-formats/) |
| Command interpreters | Trace entry sources, label lookup, branches, and the consumer of deferred actions. Document each opcode's arguments according to use. [Part 4](https://alexbevi.com/blog/2026/03/23/reverse-engineering-harvester-with-ghidra-and-codex-part-4-command-opcodes/) |
| Audio | Separate decoding from playback policy. Compare decoded bytes, sample widths, trim offsets, and per-caller buffer treatment. [Part 5](https://alexbevi.com/blog/2026/03/29/reverse-engineering-harvester-with-ghidra-and-codex-part-5-debugging-audio-issues/) |
| Timers | Capture enabled state, remaining ticks, expiry action, and transition persistence before and after each fixture step. [Part 6](https://alexbevi.com/blog/2026/04/14/reverse-engineering-harvester-with-ghidra-and-codex-part-6-timers/) |
| Comparing versions | Use normalized instruction signatures to locate likely counterparts, then check reference differences and actual call paths against each executable's hash. [Part 7](https://alexbevi.com/blog/2026/07/11/reverse-engineering-harvester-with-ghidra-and-codex-part-7-demo-support/) |

Fate's mapped image supports the local headless route. A persistent Ghidra
project can help when many routines in one subsystem share types and names.
Keep project files and generated drafts under ignored scratch. Record durable
findings in the relevant repository notes with enough evidence to revisit
them independently of that project.

## Probe a single translation unit

Use a pinned original executable or a previously hash-verified rebuilt image
as the reference. Keep it separate from the build output.

```powershell
python tools/restore.py probe run_menu_loop --build work/restoration-build --reference work/ci-build/FATE.EXE
```

This stages the current sources, compiles/reuses the containing object, verifies
its registered CODE spans and LE sites/targets. Registered fixtures are opt-in
with `--fixtures`.
Registered mixed-routine selectors such as `collect_input` probe all their
compiler contexts. Fixture object prerequisites are built and freshness-checked
without expanding the requested fixture set. Input fixtures declare and use
`--asm {asm}`, so both whole-routine and fragment probes work in fresh build
directories. Research `--symbol` probes still require one compiler object.
It does **not** refresh coverage or claim that the whole executable was linked.
Full logs stay under the build directory; failures print only bounded diagnostics.
Some fixtures require a complete baseline build and fresh `c.json`.

For an unregistered research routine, first add its source/object/options to
`tools/data/restoration-units.txt`, then specify the independently established
public and reference span:

```powershell
python tools/restore.py probe candidate --symbol candidate_ --raw-offset 0x12345 --size 123 --reference <verified.exe>
```

The offset above is a syntax example, not a valid Fate CODE span. Binding still
requires observed DATA/CODE symbols and ABI information in the verifiers.
Research probes never automatically accept spans or modify inventories. DATA-only
objects require whole-executable validation. Preserve authoritative assembly until replacement
bytes **and** relocations qualify.

## Test behavior before matching compiler output

Actor movement, tile copying, and the mouse-button menu support a research-only differential mode:

```powershell
python tools/restore.py behavior move_actor --build work/behavior-probe --reference <verified.exe>
python tools/restore.py behavior run_mouse_button_menu --build work/behavior-probe --reference <verified.exe>
python tools/restore.py behavior copytilepiece --object work/candidate/tilecopy.obj --build work/behavior-probe --reference <verified.exe> --seed 0xFACE --random-cases 128
```

Without `--object`, the selected current translation unit is compiled or reused.
With it, the existing research object is bound directly. Neither path requires
the candidate's instruction bytes, size, or LE sites to match the reference.
OMF fixups still require explicit, supported symbol bindings; unsupported object
forms fail rather than guessing a linker transformation.

New research fixtures should reuse `Machine`, `Contract`, and `Region` from
`tools/differential.py`. Include every relevant data range and the confirmed
callee register changes. For a callee-popped stub, register actual `RET n`
bytes with `add_code` and `stubs`; do not manually advance ESP before a plain
RET. Add a bad-branch and preserved-register mutation to check the oracle.

Each candidate and the original run independently with the same inputs. The
shared harness checks return values where defined, preserved registers, stack
cleanup/guards, declared memory writes, and external-call arguments/order.
Guest instruction counts, wall time, and executable/writable ranges are bounded.
Long bounded waits may set `Contract.wall_timeout_us` explicitly (in microseconds)
for slower CI hosts; keep the guest instruction limit and exact polling-count
checks unchanged. Both execution budgets must be positive integers.
Actor fixtures include distance/angle boundaries; tile fixtures include negative
and zero counts, clipping edges, transparency, lazy loads, and overlapping buffers.
Seeds are deterministic. A passing scenario suite is evidence, not a proof for
every possible input.

The tile fixture also checks the original against an independent Python
specification, so comparing two equally wrong observations cannot pass silently.
Overlapping buffers use forward, column-major writes—not snapshot/memmove
semantics. In strict mode only, an identical **loaded** body can reuse the
reference execution after byte/LE acceptance. Different loaded bodies (including
rebased shared tails) and all behavior-only runs still execute both sides.

On failure, `work/<build>/behavior-failure.json` records the first differing
observation and the complete small input case. Replay it with:

```powershell
python tools/restore.py behavior copytilepiece --object work/candidate/tilecopy.obj --build work/behavior-probe --reference <verified.exe> --case-file work/behavior-probe/behavior-failure.json
```

The registered fixture scripts also accept `--behavior-only`, `--seed`, `--random-cases`,
`--case-file`, `--failure-output`, and `--output` directly. Their default mode still
requires exact bytes and LE relocations. In exact mode they also self-test by
rejecting known bad branches/stores, stack cleanup, and register preservation.

**A behavior-only PASS never qualifies code for the exact inventory.** Its
`behavior-validation.json` explicitly sets `exact_verified` and
`inventory_eligible` to false. Use `probe`, then the exact whole-executable gate,
for acceptance.

## Reuse compiler idiom evidence

```powershell
python tools/check_watcom_idioms.py
```

Nine small idioms compile together under three established flag combinations.
Subsequent runs reuse content-verified objects but recheck code, public layout,
external symbols, and OMF fixups against checked-in expectations. OMF timestamp
comments are excluded. See [Watcom idiom evidence](WATCOM-IDIOMS.md) before
repeating register-width, packed-field, clobber, tail-call, or scheduling probes.

The full validation gate runs this suite as well. Clean mode recompiles it;
resumed builds reuse only verified probe objects. `--observe` writes observations
under `work/` without updating or passing the expected snapshots. Compiler probes
never enter production linking or game coverage.

## Reusable conversion regression tests

Run unit tests with `tools` and the verified dependency cache on `PYTHONPATH`:

```powershell
python -m unittest discover -s tools/tests -q
```

- `test_differential.py`: synthetic ABI, partial-register widths, signed stack
  arguments, full-width write/code boundaries, loaded DATA/CODE fixups and
  addends, exact-versus-behavior separation, and replay/identical-body reuse.
- `test_tile_copy_spec.py`: hand-calculated expected pixels, clipping/wrapping,
  transparency, lazy-load order, and forward overlap. Extend these cases before
  changing tile-copy logic; the full fixture compares the model to the original.
- `test_watcom_idioms.py`: compiler-output semantics and snapshot/cache safety.
  Add small compiler experiments as described in `docs/WATCOM-IDIOMS.md`.
- `test_restoration_coverage.py`: synthetic inventory rendering and safe block
  replacement. Real document freshness stays in the CI `coverage-docs` stage.

`tests/cache_contract.py` shares clean-build and failed-rebuild guarantees across
the production and idiom compiler tests. Keep implementation-specific cache
invalidation cases local. Fixture registrations are checked for uniqueness and
valid dependencies, not a fixed count that every new conversion must update.

## Exact whole-executable acceptance

Run the production gate from current sources. The default mode, also named
`--exact`, verifies the pinned whole executable including LE relocations.
An optional independently verified `--reference` must differ from the
output path and adds a direct byte comparison.

```powershell
python tools/restore.py validate --build work/restoration-build
```

## Focused edit loop and broad regressions

| Mode | When to use it |
| --- | --- |
| `probe` or `validate --changed` | Compare selected compiler units and LE sites/targets during a probe. The changed mode needs a provenance baseline. Add `--fixtures` for affected fixtures. |
| `validate --full` | Check tooling, binder, fixture, NASM and inventory changes or run a broad checkpoint. It adds the tooling tests, compiler idioms, per-span checks, coverage docs, and registered fixtures to the exact gate. |
| `validate --clean --build work/<new-name>` | Force an uncached exact build in a new directory. Combine with `--full` for an uncached broad check. |

Changed mode selects compiler units only. A no-change result runs no checks.
All normal modes verify cached inputs and outputs before reuse. Full checks
use pinned dependency wheels. Use `--dependencies <new-directory>` for an
isolated environment and `--jobs 1..8` for fixture parallelism. Compiler,
linker, and inventory operations remain serial. Skip game smoke during
restoration. CI uses exact checks for source and documentation pushes and
the broad suite for tooling or configuration changes.

## Registrations and evidence

- `tools/data/restoration-units.txt`: source/DOS object names and complete compiler
  options. Omitted options mean `/4r /s /or /bt=dos`. Board variants and staging
  aliases are expanded by `tools/restoration_build.py`.
- `tools/data/restoration-fixtures.txt`: fixture arguments and explicit affected
  object lists, shared by targeted and full validation.
- `tools/restoration_registry.py`: switch binders shared by verification/linking.
- Existing verifiers: independent expected ABI, placement, branch, and relocation
  evidence. Do not generate expected bytes from candidate objects.

When integrating a restoration, update the relevant build unit and verifier
evidence, register any fixture, and remove its assembly registration. When
registrations, inventories, or coverage change, compile and run
`tools/refresh_code_inventory.py <build> <verified-reference.exe>`; do not refresh
inventories for every source-only edit.
Refresh requires fresh compiler provenance, verifies the whole image, and also
updates the generated coverage overview. CI rejects stale overview figures.
Attribution and marker audits remain separate from exact acceptance and are
required to report C/assembly percentages honestly. Keep mixed C objects separate
from assembly-free C, and distinguish standalone assembly from measured inline
assembly.

For unchanged C sections around a small assembly gap, `LEAF_CODE_SLICES`
records the actual OMF public, selected bounds, and required full public size.
Keep the assembly gap at its original address without added transfers or
opcode patches. Prove instruction boundaries, live register/frame handoffs,
each section's bytes and LE sites, then the complete image; credit only the
selected C bytes. Marker attribution currently requires sliced publics to
have zero inline-assembly invocations; otherwise keep those slices unknown.

For a private context containing literal-prefix or other internal relocations,
`LEAF_CONTEXT_RECORDS` can pin the complete ordered parsed OMF fixup records,
resolved external names and FLAT group indices. Pair this with the full public
SHA and literal-prefix digest; record snapshots do not replace byte guards.
Numeric indices intentionally make layout changes require requalification.
Mutation fixtures should re-encode an unchanged object successfully first, then
assert each mutation reaches its intended diagnostic instead of accepting any
exception as proof of the relevant guard.

## Artifacts and freshness

- `build-provenance.json`: per-object content keys, input hashes, output hashes,
  compiler identity, and the most recent compile/cache-hit list.
- `stages.json` and `logs/`: individual timings, commands, full diagnostics.
- `targeted-validation.json`: explicit targeted-only results.
- `behavior-validation.json` / `behavior-failure.json`: research-only behavior
  results and a replayable counterexample, never exact acceptance.
- `validation.json`: exact or full success only after the selected gate passes;
  the report records the validation scope.
- `engine.bat`: the **complete** compiler plan, even after a one-object probe;
  marker audits continue to use it. Marker objects never enter production links.

A valid executable hash proves image identity, not freshness of nearby objects,
reports, or sources. The CLI checks compiler provenance, pinned inputs, artifact
hashes, and snapshot stability separately. Input caches are never proof of a
restoration. Fresh whole-image equality covers code and LE relocations for exact
acceptance; focused span reports, fixtures, and attribution audits serve their
separate diagnostic, regression, and coverage-reporting roles.
