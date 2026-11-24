# Fate-RE agent instructions

- Keep repository instructions, restoration notes, and reports in English.
- Keep triage, ready probes, deterministic checks, CI observation and small documentation edits with the integrator. Delegate an independent compiler hypothesis to [research](.codex/agents/fate-research.toml) or a meaningful C/ABI or verifier question to [review](.codex/agents/fate-review.toml); see [routing](docs/RESTORATION-AGENTS.md) and follow the selected TOML model, reasoning, scope and restrictions.
- For exact C restoration, use the [fate-exact-restoration skill](.agents/skills/fate-exact-restoration/SKILL.md). Read it once per task and use the linked references only as needed.
- Work on the requested restoration branch. Use fgsfds <4870330+fgsfds@users.noreply.github.com> and unsigned commits/pushes for this restoration unless the user requests otherwise.
- Keep probes under ignored `work/` directories. If delegating, assign disjoint routines and scratch directories. The integrator owns the shared build, inventories, and commit.
- Avoid hand-written inline assembly whenever possible; prefer compiler-generated C.
- C rewrites must be byte-identical to the original binary, including LE relocation sites and targets, and replace the previous assembly recreation in the production build. Do not introduce a separate C build.
- Keep one concise note per unresolved compiler blocker in `docs/C-RESTORATION-ATTEMPTS.md` when the evidence changes the next probe. Include the flags, first meaningful mismatch, and next useful hypothesis. Remove the entry when the exact fix lands. Keep full logs in ignored scratch.
- Keep restoration commits focused on source, required registrations and inventories, and tests. Put the change and verification result in the commit message. Update the current attribution figures and audit reference in `docs/C-RESTORATION-PROGRESS.md` when measured coverage changes. Put reusable techniques in the relevant guide once.
- Delegate only concrete independent work. Default to 0-2 useful children within the host limit; a role catalog is not a worker quota. Use fresh bounded context and the profile model; a lower-priced model alone does not establish a useful assignment. Escalate only a specific unresolved issue.
- Keep reusable skills under shared .agents/skills/. Use fate-restoration-coordination for delegation and fate-compiler-research only for novel code-generation/ABI questions. The integrator owns production changes, registries, inventories, acceptance, metrics and publication. Configuration work and explicitly requested bounded trials do not resume a paused open-ended goal.
- After an authorized push, the integrator observes CI for its exact SHA through the paginated push-run API; see the routing guide. Keep live run/job handles until terminal or an actual stated deadline. Pending/absent required checks are unverified. Report additional failures and resolve their required/optional policy; an empty aggregate status list is not a pending required check. Configuration work does not resume the broader goal.
- Run DOSBox in windowless mode.
- Accept source-only restoration changes with `python tools/restore.py validate --build work/restoration-build` (`--exact` is an alias): build current sources with checked caches and provenance, then verify the pinned whole production executable, including relocations. Hashing an old output alone is not acceptance.
- Use `validate --full` for tooling changes or periodic broad regression checkpoints, not every source-only edit. Neither exact nor full runs game smoke by default; `--smoke` requires explicit `--full`. Skip game smoke for the current restoration task. Focused `probe` / `validate --changed` fixtures require `--fixtures`; `behavior` is a separate, nonexact diagnostic.
- Refresh code inventories when registrations, inventories, or coverage change, not for every source-only edit. Attribution audits remain separate and are required for honest C/assembly percentage claims.

## Source code references

Consult these repositories for historical Build Engine algorithms, types, and compiler idioms. Source similarity does not replace exact binary and relocation verification. Preserve attribution and applicable licenses. See [pinned vanilla references](docs/BUILD-SOURCE-REFERENCES.md) and [additional source findings](docs/ADDITIONAL-BUILD-SOURCES.md) before repeating research.

- https://github.com/fabiensanglard/vanilla_duke3D
- https://github.com/NBlood/Redneck-Rampage-RE/
- https://github.com/videogamepreservation/dukenukem3d
- https://github.com/commercial-game-sources/duke_nukem_3d
- https://github.com/NBlood/Blood-RE
