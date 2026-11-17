# Restoration agents

Use the shared [.agents skills](../.agents/skills/) and select the configured
role by name. Confirm model access before assigning work.

| Role | Model and reasoning | Assignment |
| --- | --- | --- |
| `fate-scout` | GPT-6 Luna, high | Read-only candidate triage |
| `fate-probe` | GPT-6.1 Sol, high | Bounded compiler experiment |
| `fate-verify` | GPT-6 Luna, high | Frozen artifact and attribution checks |
| `fate-research` | GPT-6.1 Sol, high | ABI and compiler hypotheses |
| `fate-review` | GPT-6.1 Sol, high | Independent C validity and evidence review |

- **Codex:** start a session rooted in this checkout. Project TOML files are in
  [`.codex/agents/`](../.codex/agents/). Scout and review disable the shell
  tool. All roles inherit the parent session's permissions.
- **OpenCode:** role files live in [`.opencode/agents/`](../.opencode/agents/).
  Use `/reload` if discovery needs a refresh.
- **DeepSeek Harness:** install the [project bundle](../.dsh/bundles/fate-agents/README.md)
  through Plugin Manager. Start a new session here with **Fate restoration**.
  Use its dedicated `fate_scout`, `fate_probe`, `fate_verify`,
  `fate_research`, and `fate_review` tools for the configured role presets.

While restoration is active, assign up to five useful, disjoint jobs within
the available concurrency limit. Keep tracked sources isolated and give
each worker a unique scratch directory. Scout and review are read-only.
Verifier shell use is limited to assigned checks. The integrator owns
the production build, inventories, and commits. Stop replenishing on pause.
See the [coordination skill](../.agents/skills/fate-restoration-coordination/SKILL.md).

## Assignment template

```text
State: restoration active; stop immediately if the parent requests pause.
Role: <fate-scout | fate-probe | fate-research | fate-verify | fate-review>
Goal/hypothesis: <one new, justified compiler question or mechanical check>
Owned files/objects: <explicit disjoint list; no shared integration files>
Working directory: <isolated worktree or frozen scratch-only compiler setup>
Scratch/build: work/<unique-task-name>
Context: <restore.py context output or saved context path>
Inputs: <pinned reference, flags, source/object hashes, relevant failure notes>
Budget: <at most three variants unless specifically extended>
Acceptance: <complete spans + LE sites/targets; optional named fixtures>
Return: stable exact patch or restored baseline, candidate/log/report paths,
        first meaningful mismatch, measured/estimated savings, next hypothesis.
Forbidden: shared production build, registry/inventory edits, commits, pushes,
           new inline instructions, undefined C, game smoke, child delegation.
```

The integrator chooses the locally installed Python and verified reference
paths rather than baking one developer's absolute paths into these profiles.
Compiler options come from `tools/data/restoration-units.txt`.

See the [workflow](RESTORATION-WORKFLOW.md) for exact commands and
[progress](C-RESTORATION-PROGRESS.md) for measured coverage.
