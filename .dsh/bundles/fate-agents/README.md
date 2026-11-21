# Fate restoration agents for DeepSeek Harness

This installable, configuration-only bundle targets DSH 0.2.2-rc.2. It does not override Standard, select a primary model, change provider credentials, or resume restoration. Configuration work may proceed while restoration is paused.

## Install and use

1. Install this directory with DSH Plugin Manager as a local bundle.
2. Start a new session rooted at the Fate-RE checkout (or assigned worktree) and select **Fate restoration**. Existing sessions retain their loaded preset revision and tool catalog.
3. Dispatch with the dedicated role tools, supplying a complete bounded task, owned paths, scratch path, and acceptance evidence. Do not use generic subagent dispatch to simulate a route.
4. Default to zero to two useful children; request an independent review only when useful and within the host limit. No fixed worker count or busywork. A pause stops restoration work; explicit configuration tasks remain allowed.

| Role | Dedicated tool | Route | Tool boundary |
| --- | --- | --- | --- |
| `fate-scout` | `fate_scout` | `openai/gpt-6-luna`, low | No write/edit, shell, or delegation |
| `fate-probe` | `fate_probe` | `openai/gpt-6-luna`, medium | Specified transformations/experiments only; novel ABI questions go to research; no delegation |
| `fate-verify` | `fate_verify` | `openai/gpt-6-luna`, low | Assigned frozen checks; no write/edit or delegation |
| `fate-ci-monitor` | `fate_ci_monitor` | `openai/gpt-6-luna`, low | Read-only CI watching for assigned SHA; report to parent; no retries or delegation |
| `fate-writer` | `fate_writer` | `openai/gpt-6-luna`, medium | Assigned docs, READMEs, scripts, or tests from frozen evidence |
| `fate-research` | `fate_research` | `openai/gpt-6.1-sol`, high | ABI/compiler research; no delegation |
| `fate-review` | `fate_review` | `openai/gpt-6.1-sol`, medium; high only for hard ABI or UB | Independent review; no write/edit, shell, or delegation |

Use fresh children with task packets of at most 150 words plus paths; Codex callers use `fork_turns="none"`. Save routine context and pass bounded excerpts, never full history. A role-label change does not change an existing worker's model; spawn fresh at the intended tier. Parent supplies frozen audit/build reports, hashes, and model details. Derive metrics from JSON, not memory; omit resolved failures and report one blocker per routine. Return at most 150 words (research/review: 200) plus artifact paths, the first meaningful mismatch, and report paths rather than full logs. Avoid progress pings unless blocked.

After active-work pushes, give `fate_ci_monitor` the exact SHA, known runs,
previous findings and a watch budget. The parent fixes reported failures and
checks the correction SHA. A pause stops the watcher; no background schedule
is installed by this bundle.

## Security and ownership

Tool omission is a boundary only where stated. Shell-enabled tools remain subject to session permissions; verifier shell is for assigned checks. Keep scratch in ignored `work/` paths. All DOSBox compilation is serialized and parent-owned unless an exclusive lease is granted. Writers may edit only assigned artifacts from frozen evidence and do no game research, compiler/registry/inventory work, commits, pushes, or new hypotheses. Parent reviews artifact claims and scripts and owns integration.

## Regenerate

OpenCode files in `.opencode/agents/*.md` are canonical for role bodies. From the repository root, run:

```powershell
node .dsh/bundles/fate-agents/build-fate-agents.cjs . .dsh/bundles/fate-agents --sync-codex
```

This generates eight presets (parent plus seven roles), including the `fate_ci_monitor` tool. With no `--sync-codex` flag, generation remains DSH-only. Reinstall the local bundle after regeneration and use a new session to load changes. Use `--sync-codex --check` to detect generated profile drift without writing files.
