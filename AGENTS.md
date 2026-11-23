# Fate-RE agent instructions

- Keep repository instructions, restoration notes, and reports in English.
- For exact C restoration, use the [fate-exact-restoration skill](.agents/skills/fate-exact-restoration/SKILL.md). Read it once per task and use the linked references only as needed.
- Work on the requested restoration branch. When asked to commit and push, use fgsfds <4870330+fgsfds@users.noreply.github.com>, sign with key 141D19E46490A9B1, and push the current restoration branch.
- Keep probes under ignored `work/` directories. If delegating, assign disjoint routines and scratch directories. The integrator owns the shared build, inventories, and commit.
- Avoid hand-written inline assembly whenever possible; prefer compiler-generated C.
- C rewrites must be byte-identical to the original binary, including LE relocation sites and targets, and replace the previous assembly recreation in the production build. Do not introduce a separate C build.
- Keep one concise note per unresolved compiler blocker in `docs/C-RESTORATION-ATTEMPTS.md` when the evidence changes the next probe. Include the flags, first meaningful mismatch, and next useful hypothesis. Remove the entry when the exact fix lands. Keep full logs in ignored scratch.
- Keep restoration commits focused on source, required registrations and inventories, and tests. Put the change and verification result in the commit message. Update the current attribution figures and audit reference in `docs/C-RESTORATION-PROGRESS.md` when measured coverage changes. Put reusable techniques in the relevant guide once.
- Delegate only concrete independent work. Default to 0-2 useful children within the host limit; a role catalog is not a worker quota. Use fresh bounded context and the cheapest suitable model. Escalate only a specific unresolved issue.
- Keep reusable skills under shared .agents/skills/. Use fate-restoration-coordination and the configured role profiles in docs/RESTORATION-AGENTS.md; load fate-compiler-research only for novel code-generation/ABI work. The writer may edit explicitly assigned docs/scripts/tests from frozen evidence; the integrator retains acceptance, shared registries/inventories, builds and commits. Stop restoration workers on pause. Explicit configuration tasks do not resume the goal.
- After pushes during active work, delegate exact-SHA CI watching to fate-ci-monitor. The integrator fixes reported pipeline failures and verifies the new SHA; pending or absent checks are not success. Stop monitoring on pause.
- Run DOSBox in windowless mode.
- Accept source-only restoration changes with `python tools/restore.py validate --build work/restoration-build` (`--exact` is an alias): build current sources with checked caches and provenance, then verify the pinned whole production executable, including relocations. Hashing an old output alone is not acceptance.
- Use `validate --full` for tooling changes or periodic broad regression checkpoints, not every source-only edit. Neither exact nor full runs game smoke by default; `--smoke` requires explicit `--full`. Skip game smoke for the current restoration task. Focused `probe` / `validate --changed` fixtures require `--fixtures`; `behavior` is a separate, nonexact diagnostic.
- Refresh code inventories when registrations, inventories, or coverage change, not for every source-only edit. Attribution audits remain separate and are required for honest C/assembly percentage claims.

## Subagent profiles

Use the authoritative profiles in `.codex/agents/` for suitable bounded, independent tasks. Read the selected TOML before assigning work and apply its model, reasoning effort, role instructions, and tool restrictions. Follow the [coordination workflow](docs/RESTORATION-AGENTS.md) for fresh context, task packets, compiler leases, and evidence handoffs. The integrator retains production acceptance, shared registries and inventories, commits, and pushes.

| Profile | Assignment |
| --- | --- |
| [fate-scout](.codex/agents/fate-scout.toml) | Read-only candidate triage from a bounded packet |
| [fate-probe](.codex/agents/fate-probe.toml) | Specified mechanical patches and bounded compiler experiments |
| [fate-research](.codex/agents/fate-research.toml) | Novel Watcom, ABI, and control-flow questions |
| [fate-review](.codex/agents/fate-review.toml) | Independent C-validity, ABI, and evidence review |
| [fate-verify](.codex/agents/fate-verify.toml) | Mechanical checks of frozen artifacts and attribution |
| [fate-writer](.codex/agents/fate-writer.toml) | Assigned documentation, scripts, and tests from frozen evidence |
| [fate-ci-monitor](.codex/agents/fate-ci-monitor.toml) | Read-only CI monitoring for the exact pushed SHA |

Keep assignments disjoint and within the host limit. A profile catalog does not require a fixed worker count. Stop restoration workers on pause; explicit configuration work remains allowed.

## Source code references

Consult these repositories for historical Build Engine algorithms, types, and compiler idioms. Source similarity does not replace exact binary and relocation verification. Preserve attribution and applicable licenses. See [pinned vanilla references](docs/BUILD-SOURCE-REFERENCES.md) and [additional source findings](docs/ADDITIONAL-BUILD-SOURCES.md) before repeating research.

- https://github.com/fabiensanglard/vanilla_duke3D
- https://github.com/NBlood/Redneck-Rampage-RE/
- https://github.com/videogamepreservation/dukenukem3d
- https://github.com/commercial-game-sources/duke_nukem_3d
- https://github.com/NBlood/Blood-RE
