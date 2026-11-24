# Restoration agents

Use a child for independent judgment or useful overlap, not as a wrapper around
a ready command. The integrator runs short probes, triage, report extraction,
CI observation and small documentation edits directly.

| Profile | Model and reasoning | Use |
| --- | --- | --- |
| [fate-research](../.codex/agents/fate-research.toml) | GPT-6.2 Sol, high | One unresolved Watcom, ABI or allocation hypothesis |
| [fate-review](../.codex/agents/fate-review.toml) | GPT-6.2 Sol, medium | Independent C/ABI or verifier review; high only for a named hard ambiguity |

The former scout, verifier, writer, probe and CI-monitor roles are retired.
The [workflow comparison](WORKFLOW-COMPARISON.md) records the evidence and limits;
fewer profiles alone do not prove lower token use. Neither retained role has a
worker quota. Research is retained for a distinct unresolved question, not on a
claim that this comparison measured its speed.

## Assignment and ownership

Use a fresh child with `fork_turns="none"` and its TOML model/reasoning. Supply
an absolute cwd/runtime, one question, owned scratch, frozen input paths, explicit
variant budget and required evidence. Keep the packet at most 150 words plus
paths. Read-only reviewers use file APIs or bounded parent excerpts. Give a
reviewer the request and raw evidence without the intended verdict or seeded fault.

The integrator owns production edits, registries, inventories, acceptance and
unsigned publication. Researchers write only assigned scratch. Exactly one
windowless DOSBox lease may run, including parent jobs; no game smoke. Freeze
source/tool inputs during gates. Stop after the first useful result and verify
required outputs exist. A short reply limit does not excuse an unfinished task.
On failure inspect the actual command and output before repairing a packet once
or finishing directly; do not maintain a repeated relay.

Review the assigned frozen source and guard contracts while the integrator
handles acceptance. Pending metrics/docs are not a source-review blocker. Keep
the [exact gates](../.agents/skills/fate-exact-restoration/SKILL.md), context hashes,
LE classes/sites/targets, fixtures and honest attribution unchanged. Existing
handoff/report tools can extract evidence directly; another agent is not needed
to copy JSON fields.

## CI observation by the integrator

Use connected GitHub `github_fetch` GET requests for:

- `/repos/{owner}/{repo}/actions/runs?head_sha={sha}&event=push&per_page=100&page={page}`
- `/repos/{owner}/{repo}/actions/runs/{run}/attempts/{attempt}/jobs?per_page=100&page={page}`

Follow pagination using `total_count`, check the exact SHA/event and all expected
workflows/jobs (currently `Build and verify Fate` / `build`). Inspect any additional
commit checks/statuses rather than assuming the workflow list covers them.
The `fetch_commit_workflow_runs` wrapper is PR-only and cannot prove push success.
Retain run/job handles and poll at 30–60-second intervals. Measure any watch deadline
with actual clock timestamps, not a guessed number of tool calls. Pending, absent
or skipped required checks are unverified; observation timeouts do not terminate
jobs. Do not retry/cancel jobs or post comments as part of observation.

Judge required gates separately from additional checks. A combined `pending`
status with zero status contexts does not itself identify a pending required
check. Always report additional failures. If their required/optional policy is
unknown, determine it before claiming overall CI success; report the established
required-gate result and the outstanding policy separately.

## Scope and measurement

An existing broader-goal pause permits subsequently requested configuration work
or a bounded test, but does not authorize open-ended restoration. Publication
follows existing user authorization. A new pause stops new launches in its scope;
observe any live compiler and release its lease only after DOSBox is absent.
Return live handles when observation cannot finish.

Record dispatch-to-observed-completion separately from script/compiler time,
including parent diagnosis and corrections. Compare identical frozen inputs,
flags and cache conditions; record incomplete outputs as failures. Separate
requalification from fresh rewrites. Profile text sizes, model prices and
cumulative goal tokens are not measured token savings. Repeat or broaden a test
only for a new uncertainty or changed behavior.
