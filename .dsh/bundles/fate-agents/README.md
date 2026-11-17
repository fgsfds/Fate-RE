# Fate restoration agents for DeepSeek Harness

Converted for DSH 0.2.2-rc.2. This is an installable, configuration-only bundle,
not an OpenCode configuration directory. It does not override Standard, select a
primary model, change provider credentials, or resume restoration.

## Start here

1. Install this directory with DSH Plugin Manager (local directory). The bundle
   registers six presets. The project directory alone is not auto-discovered as
   agent configuration.
2. Create a **new session**, set its working directory to the Fate-RE repository
   (or an assigned worktree), and select **Fate restoration**. Existing sessions
   keep their original preset revision and tool catalog.
3. The integrator uses the dedicated tools below, not generic `subagent` with a
   role name. Give each child a complete assignment, owned files, an isolated
   scratch/worktree directory, a budget, and evidence requirements.
4. Resume restoration only on explicit user instruction. Installation/testing
   is configuration work, not permission to start compiler experiments.

| Role preset | Integrator tool | Fixed child route | Tool restrictions |
| --- | --- | --- | --- |
| `fate-scout` | `fate_scout` | `openai/gpt-6-luna`, `high` | No write/edit, shell, or delegation |
| `fate-probe` | `fate_probe` | `openai/gpt-6.1-sol`, `high` | No delegation |
| `fate-verify` | `fate_verify` | `openai/gpt-6-luna`, `high` | No write/edit or delegation; assigned shell checks only |
| `fate-research` | `fate_research` | `openai/gpt-6.1-sol`, `high` | No delegation |
| `fate-review` | `fate_review` | `openai/gpt-6.1-sol`, `high` | No write/edit, shell, or delegation |

The routes above come from the actual `.opencode/agents/*.md` frontmatter,
not the older prose table in `docs/RESTORATION-AGENTS.md`. On conversion, the
current session exposed only Sol. Luna defaults are deliberately preserved at
the user's request: enable an authorized Luna route before using scout/verifier.
A missing model must fail visibly; do not silently upgrade cheap work to Sol.
The fixed routes apply when dispatched by the integrator's dedicated tools.
Selecting a child preset directly in the UI does not choose its model; select
the route manually there. Presets define tools/personas, not session models.

## Mapping and limitations

- The original prompt bodies are embedded unchanged at the start of each
  child's persona, followed by a small DSH adapter note.
- Role restrictions are implemented by omitting tools, not just telling a
  general-purpose child to behave. Children have no delegation/workflow tools;
  the integrator's delegation tools also cap absolute depth at one.
- Read-only roles disable both filesystem mutation tools. Scout/review also
  omit shell and job tools. Verifier needs shell for assigned checks, so its
  shell write prohibition remains an instruction, **not an OS security boundary**.
  Compiler roles likewise rely on explicit ownership plus the session sandbox.
- Shell-enabled presets use PowerShell, matching this Windows installation.
- Shared `.agents/skills/` and `AGENTS.md` are loaded using DSH's filesystem
  skill provider and repository-instructions plugin; skills are not duplicated.
- Research additionally has web search/fetch. Parent owns shared integration.
- Keep five useful disjoint workers only while restoration is explicitly active.
  On pause, stop new assignments and message every active child to stop.
- Installation registers profile-wide presets but changes no default preset,
  provider configuration, or user files outside this bundle and the usage guide.
- The bundle has original network-node artwork; stock declaration rows retain
  their own DSH package artwork. UI rendering requires a new session and has
  not been browser-verified by the converter.

## Regenerate after editing OpenCode profiles

The OpenCode files remain canonical for role prompts and model defaults.
Run from this repository with a normal Node.js runtime:

```powershell
node .dsh/bundles/fate-agents/build-fate-agents.cjs . .dsh/bundles/fate-agents
```

This regenerates the manifest, patch and English locale and asserts source
prompt preservation, role routes, and tool omissions. It leaves this README,
icon, and the OpenCode files unchanged. Reinstall the local bundle after changes,
check activation results, and use new sessions. The patch is JSON-form YAML so
it needs no code plugin, dependencies, build scripts, or custom YAML tags.
