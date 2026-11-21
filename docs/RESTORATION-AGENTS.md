# Restoration agents

Use the shared [.agents skills](../.agents/skills/) and the configured role presets below. This is configuration guidance; it does not resume a paused restoration. Explicit configuration work may continue while restoration is paused.

| Role | Route | Assignment |
| --- | --- | --- |
| `fate-scout` | GPT-6 Luna, low | Read-only candidate triage |
| `fate-probe` | GPT-6 Luna, medium | Only specified transformations or experiments; escalate a novel ABI question to research |
| `fate-verify` | GPT-6 Luna, low | Check frozen artifacts and attribution |
| `fate-ci-monitor` | GPT-6 Luna, low | Watch exact pushed SHAs; report failed jobs and actionable diagnostics to the integrator |
| `fate-writer` | GPT-6 Luna, medium | Edit assigned docs, READMEs, scripts, or tests from frozen evidence |
| `fate-research` | GPT-6.1 Sol, high | Investigate ABI and compiler hypotheses |
| `fate-review` | GPT-6.1 Sol, medium; high only for hard ABI or undefined-behavior cases | Independent review of C validity and evidence |

- **Codex:** start a session rooted in this checkout. Project TOML files are in [`.codex/agents/`](../.codex/agents/).
- **OpenCode:** role bodies in [`.opencode/agents/`](../.opencode/agents/) are canonical. Use `/reload` if discovery needs a refresh.
- **DeepSeek Harness:** install [the project bundle](../.dsh/bundles/fate-agents/README.md) through Plugin Manager, then start a new session here with **Fate restoration**. Use its dedicated role tools.

Default to zero to two useful children. Add an independent review only when useful and within the host limit. Do not create busywork or maintain a fixed worker count. Keep jobs disjoint, sources frozen or isolated, and scratch under a unique ignored `work/` directory. A pause stops restoration work and replenishment; an explicit configuration task remains allowed.

For Codex children, use `fork_turns="none"`; on other hosts use a fresh child with a bounded task packet. Send a task packet of at most 150 words plus paths. Save routine context to a file and provide only bounded relevant context; never send full history. Changing a role label does not change a running worker's model: spawn a fresh worker when changing tiers. Parent supplies frozen evidence such as final audit/build reports, hashes, and model details. Derive metrics from JSON, never memory; exclude failed-then-resolved stories and report at most one blocker per routine.

All DOSBox compilation is serialized and owned by the parent unless an exclusive lease is granted. A writer changes only assigned docs, READMEs, scripts, or tests from frozen evidence. Writers do no game research, compiler work, registry or inventory work, commits, pushes, or new hypotheses. Parent reviews artifact claims and scripts.

## Pipeline monitoring

After each push during active work, assign `fate-ci-monitor` the repository,
branch, exact SHA, run IDs/attempts, previous findings and a bounded watch budget.
It reports failures immediately with run/job links and a small relevant error
excerpt. It uses read-only GitHub access, accounts for push-triggered workflows,
and treats pending or absent runs as unverified. The integrator fixes failures,
pushes a correction and has its new SHA checked. No monitor-driven retries,
workflow changes or public comments. Stop the monitor on pause; configuration
changes alone do not start it or resume restoration.

## Assignment and return

State the pause/active status, role, one bounded goal, owned paths, scratch path, frozen inputs, budget, and acceptance evidence. Return no more than 150 words (research/review: 200) plus artifact paths. Identify the first meaningful mismatch and report paths, not full logs. Avoid progress pings unless blocked. The parent owns production integration, builds, inventories, and commits.

See the [coordination skill](../.agents/skills/fate-restoration-coordination/SKILL.md), [workflow](RESTORATION-WORKFLOW.md), and [progress report](C-RESTORATION-PROGRESS.md) for operating commands and measured coverage.

## Evidence handoff

After the parent checks current freshness with `restore.py doctor`, create a
compact packet for the writer instead of copying inventories into chat:

```powershell
python tools/restoration_handoff.py work/palette-clear-build --audit work/palette-clear-audit.json --output work/writer-evidence.json
```

The helper checks saved executable, inventory and object identities, then derives
percentages. Its output describes saved artifacts; it does not replace the
current-source freshness check or prove a new restoration candidate is exact.
Read only selected fields and routine rows from larger reports. Keep detailed
logs in scratch and let the writer update only the named final artifacts.
