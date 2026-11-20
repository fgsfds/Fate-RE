---
name: fate-restoration-coordination
description: Route bounded Fate restoration work to economical roles, isolate compiler jobs, and hand verified evidence to a writer.
---

# Restoration coordination

Read docs/RESTORATION-AGENTS.md for routes and the task packet. Load the exact
skill only for acceptance/compilation, and compiler-research only for novel ABI
or code-generation work. Read guidance once per session; do not reload entire
skills, inventories or attempt logs for every follow-up.

## Route only useful work

- No worker quota: default 0-2 useful children, optional independent review within
  the host limit. Never refill slots just because a task finished. Paused
  restoration stays paused; explicit configuration work is separate.
- Scout, specified probe, verifier and writer use Luna. Research uses Sol-high;
  routine independent review uses Sol-medium. Escalate a concrete ambiguity,
  not all tasks. If a route is unavailable, report it and use an available
  comparable/lower tier; do not silently upgrade or invent provider/model IDs.
- On Codex start with fork_turns="none" and an explicit supported model/effort;
  use the host's fresh-child mechanism elsewhere.
  Reuse a worker only for the same routine/role while its context is relevant.
  Renaming its task does not change its existing model or clear old context.
- Send <=150 words plus paths: objective, owned files, context/evidence, runtime
  paths, flags, hypothesis, budget, acceptance. Supply bounded excerpts when a
  read-only role cannot open files. Include the discovered Python executable,
  PYTHONPATH and working directory once; avoid rediscovering WindowsApps aliases.
- Use notifications, not progress polling of idle children. Returns are <=150
  words (research/review <=200) with decisive status and artifact paths. Put full
  logs/listings/source in ignored scratch. No unchanged status pings or children.

## Isolation and acceptance

- Separate scratch folders do not isolate shared sources. Workers change only
  assigned scratch or an isolated worktree. Freeze tracked inputs during builds.
- The integrator owns shared registries/inventories, production artifacts,
  acceptance, signing and pushes. It leases one compiler job at a time, including
  workers: windowless DOSBox, check absent before launch and after exit; no smoke.
- Default one specified probe, at most three explicitly budgeted. Stop when the
  first useful result resolves the question; a failure needs a new hypothesis
  before widening. A source/hash change invalidates its earlier evidence.
- Integrate reviewed candidates serially. Exact bytes plus LE sites/targets and
  a fresh whole image are mandatory; behavior alone never earns C coverage.
  Use default exact validation for source-only edits; full for tool changes or
  justified checkpoints. Refresh inventories only when registrations change,
  and attribution when inline bytes change. Reuse only provenance-checked inputs.
- Freeze the final report packet before assigning fate-writer. Run doctor for
  current freshness, then restoration_handoff.py for saved-artifact identity and
  compact metrics. The writer may edit named docs/READMEs/scripts/tests; it cannot
  accept code, change registries/inventories, or infer results. Never validate
  while it edits files included in the validation snapshot.
- Finish writer output before final acceptance if it changes scripts/fixtures.
  Review its arithmetic, links and script behavior once; do not rewrite correct
  text just for style. Keep one current blocker per routine, remove solved
  failures, and avoid duplicating reports in commit messages.
- On pause: stop new hypotheses/assignments, finish only the pending bounded
  checkpoint, collect artifacts, stop all children and preserve a concise resume
  note. Configuration tasks alone do not reactivate restoration.
