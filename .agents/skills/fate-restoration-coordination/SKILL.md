---
name: fate-restoration-coordination
description: Coordinate cost-tiered Fate restoration subagents, five-job concurrency, isolated compiler probes, stable integration, exact evidence, and clean pause handoffs
---

# Restoration coordination

All paths are repository-relative. This skill lives in the shared `.agents/skills/`
directory. Read `docs/RESTORATION-AGENTS.md` for roles,
model choices, and an assignment template. Use
`.agents/skills/fate-exact-restoration/SKILL.md` for acceptance details.

## Authority and scheduling

- Configuration is not authorization to resume restoration. Honor the user's
  active/paused state; a pause stops replacement assignments immediately.
- While restoration is explicitly active, the requested budget is five active
  subagents, excluding the integrator. Replace a finished task with another
  useful disjoint assignment. If fewer safe independent tasks exist, explain
  the shortfall instead of inventing work or allowing overlapping ownership.
- Five role definitions are reusable capabilities, not a requirement to run
  exactly one of each. Reuse fate-research for independent hard routines;
  use fate-scout/fate-verify for cheap mechanical work and fate-probe for
  fully specified experiments. Rotate fate-review in before risky integration.
- Do not create perpetual jobs or automatic background restarts. Children do
  not delegate. Use completion notifications; do not poll child sessions.

## Isolation is more than different output directories

- Every assignment names owned files/objects, a scratch directory, a hypothesis,
  an experiment budget, and required evidence. Hand the scout or researcher a
  bounded `restore.py context` packet. Add reference disassembly or a Ghidra
  draft when it resolves a specific question. Keep raw images in ignored scratch.
  Give the probe worker the hypothesis and flags. Give the verifier the frozen
  candidate and the requested independent checks.
- Prefer independent worktrees for simultaneous tracked-source edits. Otherwise
  workers must compile staged scratch source only, with tracked source frozen.
- Distinct `work/` directories do not isolate sources:
  `restoration_build.py` stages the complete source set. Never run the shared
  build while workers are editing the checkout it reads.
- The integrator creates/assigns worktrees and shared baseline artifacts.
  Workers must not merge, cherry-pick, commit, push, or refresh shared
  inventories without explicit integrator authorization.
- Only the integrator edits shared registries, fixture registrations,
  inventories, progress/attempt notes, and production build artifacts. A
  verification agent may run checks in an explicitly handed-off directory
  exclusively, but may not edit tracked files through the shell.

## Stable handoff

1. Ask workers to stop new hypotheses and finish only an immediately pending
   verification. Preserve candidate/log evidence.
2. Require an exact stable patch or restoration of only that worker's failed
   changes; do not discard unrelated user/agent edits.
3. Collect source hashes, commands, flags, exact spans and LE evidence,
   current-report status, expected savings, and failed hypotheses.
4. Integrate reviewed patches serially into the production checkout. Re-run
   their targeted checks against the integrated snapshot and requested
   fixtures. Reject undefined C even if emitted bytes happen to match.
5. Use fresh default exact production validation; use `--full` for tooling
   changes or an intentional periodic checkpoint, not every source edit.
   Never run DOSBox game smoke. Keep compiler DOSBox windowless.
6. Refresh inventories when registrations/coverage change. Re-measure marker
   attribution when inline instructions change, including needed retries.
   Report compiler-generated, inline, standalone assembly, and unknown bytes
   against the complete CODE segment; count inline within remaining assembly.
7. Keep open probe clues concise and remove resolved entries. Record the
   accepted change and verification in the commit message and update measured
   coverage when it changes. Check the branch, diff, tests, and working tree
   before signed pushes.
8. On pause: stop all children, launch no replacements, finish the bounded
   integration/verification checkpoint, report what was retained or deferred,
   and leave restoration paused.
