# Restoration agents

Use these four authoritative profiles only when their work can proceed
independently. Configuration changes do not resume paused restoration.

| Profile | Model and reasoning | Use |
| --- | --- | --- |
| [fate-research](../.codex/agents/fate-research.toml) | GPT-6.2 Sol, high | One novel Watcom, ABI or allocation hypothesis |
| [fate-review](../.codex/agents/fate-review.toml) | GPT-6.2 Sol, medium | Independent C/ABI or verifier counterexample review; high only for a concrete hard ambiguity |
| [fate-probe](../.codex/agents/fate-probe.toml) | GPT-6 Luna, medium | A ready script or specified compiler matrix in owned scratch |
| [fate-ci-monitor](../.codex/agents/fate-ci-monitor.toml) | GPT-6 Luna, low | Exact published-SHA workflow/check monitoring |

The integrator handles short triage, file copying, packet preparation,
deterministic report extraction and small documentation updates. The former
scout, verifier and writer roles are consolidated into that work. A small task
that needs no independent judgment or meaningful overlap rarely merits a child.
There is no worker quota; use zero to two useful children within the host limit.

## Assignment and completion

Start a fresh child with `fork_turns="none"` and the selected profile's supported
model/reasoning. Reuse a worker only for the same role/routine with relevant
context. Supply at most 150 words plus paths: task status (active, configuration
only, or bounded trial), absolute repo cwd/runtime, one question or executable
plan, owned paths, frozen inputs, variant/watch budget, expected output files,
acceptance and stop rule. Link focused evidence; avoid full histories and
inventories. Give read-only roles excerpts if file APIs are unavailable.

A reply length limit does not limit execution. All requested artifacts must
exist before a completion report. Return partial work only for an explicit
budget/stop rule, pause, or a concrete missing input/tool/permission, with the
remaining artifact and blocker named. Resolve cwd/path discovery using the
provided absolute path. If a mechanical assignment returns a plan without its
outputs, inspect the cause; repair its packet once or finish it directly rather
than starting a repeated parent/child relay. Novel research gets a new hypothesis
before another probe budget, not a blind retry or automatic model upgrade.

## Ownership and validation

Workers own only assigned scratch or an isolated checkout. Separate scratch
directories do not isolate shared production files. The integrator owns source
integration, registries, inventories, build acceptance, metrics and commits.
Exactly one DOSBox compiler lease may run, including parent jobs; windowless,
no game smoke. Freeze production inputs while gates run. A source/hash change
invalidates its earlier evidence. Stop after the first useful experiment result.

Review source/ABI evidence independently while integration proceeds. The reviewer
checks the frozen assigned portion and states which final gates remain; pending
report updates do not invalidate an otherwise sound source review. The integrator
checks current freshness with `restore.py doctor` and can create a compact saved
evidence packet with `restoration_handoff.py`. Read relevant JSON fields directly
instead of assigning an agent merely to copy them. Neither helper replaces the
fresh exact whole-image gate. See the [exact skill](../.agents/skills/fate-exact-restoration/SKILL.md).

## Pipeline monitoring

Assign the repository, branch, exact SHA, known run/attempt IDs, expected push workflow/check names and a five-minute
watch budget after an authorized push. Monitor every push workflow/check and
follow pagination. Pending, absent and skipped required checks are unverified.
Use live handles, 30-60-second bounded polls and notifications; no unchanged status
narration, retries or public comments. The parent owns fixes and the new SHA.
A timeout observing a job is not proof that the job stopped.

## Measuring effectiveness and pause state

Record observable task results: completed artifacts, bounded compiler experiments,
parent correction/follow-up count, acceptance results and wall time where useful.
Record per-agent token usage only if the host exposes it. Cumulative goal tokens
cannot establish per-agent savings or a before/after speedup. Distinguish preserved
candidate requalification, newly converted assembly, newly attributed existing C,
and compiler-generated table data. More output tokens and lower model cost are
different quantities; do not claim either improved without measurements.

Keep the parent focused on the critical path. An existing pause of the broader goal does not cancel a subsequent explicit
configuration task or bounded trial. That request authorizes only its stated
scope and acceptance; publication follows existing user authorization and is
not an additional permission conferred by the trial. Leave the broader goal
paused afterward unless the user resumes it.

A new pause/stop instruction halts new hypotheses, assignments and launches in
the affected task. Observe an already running compiler through its live handle;
never treat an observation timeout as termination. Save its actual status and
artifacts, and release the compiler lease only after DOSBox is confirmed absent.
If observation cannot finish, return the live handle to the integrator. Finish
an already authorized checkpoint only when the user's pause instruction permits
it; do not turn that into a new restoration batch.
