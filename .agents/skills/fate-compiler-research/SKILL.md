---
name: fate-compiler-research
description: Research byte-identical Watcom 10.5 C replacements for remaining Fate assembly or inline instructions, with defined C semantics and exact LE relocation evidence
---

# Exact compiler research

All paths below are repository-relative. This shared skill supplements, rather than
replaces, `.agents/skills/fate-exact-restoration/SKILL.md`.

## Start from evidence

1. Confirm the task is active, ownership is disjoint, and the candidate compiler
   setup is isolated. Do not resume work merely because this skill is loaded.
2. Obtain `python tools/restore.py context <routine>`. Read the indicated source,
   ABI bindings, spans, fixtures, and only relevant attempt notes. For unfamiliar
   control flow, use `context <routine> --reference <verified.exe>` and the
   optional Ghidra draft in `docs/RESTORATION-WORKFLOW.md`. Check each draft
   hypothesis against the original instructions, callers, and LE relocations.
   For a second static view on a supported host, follow the optional REA
   procedure in the workflow and use its recorded entry address.
3. Consult `docs/BUILD-SOURCE-REFERENCES.md`,
   `docs/ADDITIONAL-BUILD-SOURCES.md`, and `docs/WATCOM-IDIOMS.md` as needed.
   The five pinned historical repositories have already been reviewed: reuse
   their documented hashes and findings instead of repeating broad research.
4. Record the original compiler flags, source/object hash, reference identity,
   expected complete spans, and LE sites/targets before changing a candidate.

## Trace behavior and data before naming it

- Start from a concrete anchor such as a filename, error string, dispatch
  slot, or DOS interrupt. Follow Ghidra cross-references to the caller and
  consumer before naming a routine, struct field, or opcode. Record the
  executable hash, loaded address, and instruction or call-site evidence.
  Mark uncertain names and layouts as hypotheses.
- For formats, derive field widths, record stride, bounds, and decoding from
  the original reader and consumers. Check representative assets in local
  scratch. Keep bytes, samples, and frames distinct. Trace codec output through
  the playback callers, where trimming or muting can differ by use.
- For scripts and timers, identify the lookup key, successor or deferred
  continuation, tick unit, reset rules, and live state across transitions.
  Use focused deterministic fixtures with before/after state and call traces
  to localize differences. Skip DOSBox gameplay smoke.
- When comparing builds, identify each executable by hash. Use normalized
  instruction signatures to find likely counterparts and confirm them with
  call sites, data references, and representative consumers. Run exact
  acceptance against the pinned Fate target.

See the [Harvester series notes](../../../docs/RESTORATION-WORKFLOW.md#research-patterns-from-harvester)
for sources and the distinction between interactive analysis and exact acceptance.

## Design a falsifiable probe

- Explain the semantic operation, the suspected compiler decision, the expected
  instruction change, and a bounded experiment budget.
- Prefer a whole readable C routine when feasible. Existing inline-heavy C
  objects are opportunities, not completed C restoration.
- Separate algorithm differences from ABI, allocation, scheduling, and encoding
  differences. Inspect the first meaningful instruction/LE mismatch, not merely
  an earlier changed branch displacement.
- Try small standalone idioms before repeatedly perturbing a large function.
  Delegate a fully specified matrix to fate-probe; keep ambiguous research here.
- After three failed distinct variants, stop and summarize unless the parent
  explicitly budgets more research. Do not repeat equivalent expression
  spellings or previously rejected flag matrices.

## Preserve C validity

- Model signedness, word widths, truncation, wrapping, pointer/object bounds,
  alignment, and volatile memory accesses explicitly.
- Never use signed overflow or an out-of-range C shift to imitate x86 behavior.
  A register getter does not prove its upper bits or shift count are valid.
- Preserve carry, signed high products, and full-width divide numerators.
  Watcom 10.5's rejected `__int64`/`long long` attempts are already documented.
- Empty ABI auxiliaries may constrain registers without emitting instructions.
  Document their input/output and conservative clobber contracts; do not hide
  required behavior behind a false constant/result or untracked stack effects.
- Treat EBP constraints, partial-register writes, outgoing arguments, custom
  stack cleanup, nonreturning continuations, and shared returns as explicit ABI
  questions. Do not substitute a private return for an external continuation.
- Compiler-generated instructions must replace handwritten ones in the real
  production path, not in a separate C-only executable.

## Verify and hand off

1. Run the assigned exact probe in `work/<unique-name>`, with the pinned,
   windowless compiler and a pinned reference. No game smoke.
2. Compare all assigned spans and LE sites/targets. Partial prefixes, matching
   relocation counts, object size, or behavior-only results do not qualify.
3. Save candidate source, commands, flags, logs, hashes, and the first mismatch
   before restoring an unsuccessful edit. A later failed probe must not be
   represented by an earlier successful report.
4. Propose focused independent-oracle cases for new behavior/ABI gaps. Do not
   modify shared fixture registries unless explicitly assigned.
5. Return either a stable exact patch or the restored baseline. Include source
   stability, measured versus estimated inline savings, and novel failed clues.
   Parent integration owns whole-image acceptance, marker attribution,
   inventories, documentation, and signed pushes.
