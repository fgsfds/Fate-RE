const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const project = process.argv[2];
const output = process.argv[3];
assert(project && output, 'Usage: build-fate-agents.cjs <project> <output>');
const roles = ['scout', 'probe', 'verify', 'research', 'review'];
const plugin = (id, name, config) => ({ id, name: `@deepseek-ai/dsh-${name}`, ...(config === undefined ? {} : { config }) });
const common = () => [
  plugin('agent-instructions', 'agent-instructions', { maxBytes: 65536 }),
  plugin('time-context', 'time-context'),
  plugin('skill-filesystem', 'skill-filesystem'),
  plugin('tool-skill', 'tool-skill'),
  plugin('tool-fs-search', 'tool-fs-search', { sampleOverCapGlobResults: false }),
  { id: 'compaction', name: 'cordis:group', group: true, isolate: { compaction: true, toolResultPruner: true }, config: [
    plugin('compaction-basic', 'compaction-basic'),
    plugin('command-compact', 'command-compact'),
    plugin('tool-result-pruner', 'compaction-tool-result-pruner', { thresholdChars: 8192, headChars: 4096, tailChars: 1024 }),
  ] },
];
const rows = [];
const sources = [];
for (const role of roles) {
  const id = `fate-${role}`;
  const source = fs.readFileSync(path.join(project, '.opencode', 'agents', id + '.md'), 'utf8');
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/.exec(source);
  assert(match, `Missing frontmatter: ${id}`);
  const [, header, body] = match;
  const description = /^description: (.+)$/m.exec(header)?.[1].trim();
  const route = /^model: ([^/\s]+)\/([^#\s]+)#([^\s]+)$/m.exec(header);
  assert(description && route, `Missing metadata: ${id}`);
  const permissions = [...header.matchAll(/- action: (\w+)\r?\n\s+resource: "\*"\r?\n\s+effect: deny/g)].map(m => m[1]);
  assert(permissions.includes('subagent'));
  assert(permissions.every(p => ['edit', 'shell', 'subagent'].includes(p)), `Unmapped permission: ${id}`);
  const readOnly = permissions.includes('edit');
  const noShell = permissions.includes('shell');
  const plugins = [
    plugin('persona', 'persona', { prefix: body.trim() + '\n\nDSH adapter: repository paths are relative to the assigned working directory. Load the named skills with the skill tool. This preset intentionally has no child-delegation tools. Configuration or verification of these presets does not authorize restoration. If a required tool is unavailable, report the blocker to the parent; do not bypass the role restrictions.' }),
    ...common(),
    plugin('tool-fs', 'tool-fs', { write: !readOnly, edit: !readOnly, applyPatch: false }),
  ];
  if (!noShell) plugins.push(plugin('tool-pwsh', 'tool-pwsh'), plugin('tool-jobs', 'tool-jobs'));
  if (role === 'research') plugins.push(plugin('tool-web', 'tool-web', { fetch: true, searchTimeoutMs: 60000 }));
  rows.push({ id: `preset-${id}`, name: '@deepseek-ai/dsh-agent-preset', config: { id, name: `Fate ${role}`, description, order: 21 + roles.indexOf(role), plugins } });
  sources.push({ id, description, body: body.trim(), noShell, readOnly, route: { provider: route[1], model: route[2], reasoningEffort: route[3] } });
}
const parent = {
  id: 'preset-fate-restoration', name: '@deepseek-ai/dsh-agent-preset', config: {
    id: 'fate-restoration', name: 'Fate restoration', order: 20,
    description: 'Fate-RE integrator with five model-routed, tool-scoped restoration roles. Installing does not resume restoration.',
    plugins: [
      plugin('persona', 'persona', { prefix: `You are the Fate-RE restoration integrator. Read AGENTS.md and load fate-restoration-coordination before restoration work. Installing or testing configuration does not authorize resuming restoration. Use the dedicated tools fate_scout, fate_probe, fate_verify, fate_research, and fate_review for the corresponding project roles. A tool name uses underscores; child preset IDs use hyphens. These tools select independent child presets and fixed source-defined model routes; never substitute a generic subagent with only a role name. Luna routes may be unavailable in the current profile; report a route failure and ask for an authorized route change rather than silently using Sol. Assign explicit disjoint ownership, isolated worktrees or scratch-only probes, unique scratch directories, budgets and evidence requirements. Only maintain five useful workers while restoration is explicitly active and safe. Keep shared builds, registries, inventories, documentation integration and commits centralized. On pause, stop assigning work, tell every active child to stop, and collect their handoffs. No game smoke. Read docs/RESTORATION-AGENTS.md and .dsh/bundles/fate-agents/README.md for usage.` }),
      ...common(),
      plugin('tool-fs', 'tool-fs', { applyPatch: false }),
      plugin('tool-pwsh', 'tool-pwsh'), plugin('tool-jobs', 'tool-jobs'),
      plugin('tool-subagent-control', 'tool-subagent-control', { interrupt: false }),
      plugin('tool-ask-user', 'tool-ask-user'), plugin('tool-todo', 'tool-todo', { allowParallelInProgress: true }),
      plugin('command-goal', 'command-goal'), plugin('tool-goal', 'tool-goal'),
      plugin('tool-web', 'tool-web', { fetch: true, searchTimeoutMs: 60000 }),
      ...sources.map(s => plugin(`delegate-${s.id}`, 'tool-subagent', { provider: 'spawn', toolName: s.id.replaceAll('-', '_'), agentPreset: s.id, maxDepth: 1, modelSelection: false, modelDiscovery: false, agentOptions: s.route })),
    ],
  },
};
rows.unshift(parent);
const patch = [{ insert: rows }];
// JSON is a YAML subset, accepted by the Cordis YAML loader. No custom tags needed.
const text = JSON.stringify(patch, null, 2) + '\n';
const parsed = JSON.parse(text);
assert.equal(parsed[0].insert.length, 6);
assert.equal(new Set(rows.map(r => r.config.id)).size, 6);
for (const s of sources) {
  const child = rows.find(r => r.config.id === s.id);
  const plugins = child.config.plugins;
  assert(plugins.find(p => p.id === 'persona').config.prefix.startsWith(s.body));
  assert(!plugins.some(p => /subagent|workflow|goal|schedule|plugin-manager/.test(p.name)));
  assert.equal(plugins.some(p => p.id === 'tool-pwsh'), !s.noShell);
  const filesystem = plugins.find(p => p.id === 'tool-fs').config;
  assert.equal(filesystem.edit, !s.readOnly);
  assert.equal(filesystem.write, !s.readOnly);
  const delegate = parent.config.plugins.find(p => p.id === `delegate-${s.id}`).config;
  assert.equal(delegate.agentPreset, s.id);
  assert.deepEqual(delegate.agentOptions, s.route);
  assert.equal(delegate.maxDepth, 1);
}
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(path.join(output, 'cordis.patch.yml'), text);
fs.writeFileSync(path.join(output, 'package.json'), JSON.stringify({
  name: '@local/fate-restoration-agents', version: '1.0.0', private: true, type: 'module',
  description: 'Fate-RE restoration presets and role-specific delegation tools for DeepSeek Harness.',
  exports: { './locale/*.json': './locale/*.json', './icon': './icon.svg' },
  files: ['cordis.patch.yml', 'locale', 'icon.svg', 'README.md', 'build-fate-agents.cjs'],
  dsh: { bundle: { patch: './cordis.patch.yml' } },
}, null, 2) + '\n');
fs.mkdirSync(path.join(output, 'locale'), { recursive: true });
fs.writeFileSync(path.join(output, 'locale', 'en.json'), JSON.stringify({ meta: {
  title: 'Fate restoration agents',
  description: 'Adds the Fate restoration integrator and five scoped roles. Select Fate restoration in a new session rooted in Fate-RE. Scout/verifier preserve Luna-high routes and need that model enabled; other roles use Sol-high. Windows PowerShell is used for compiler roles. No default preset or restoration state is changed.',
} }, null, 2) + '\n');
console.log(`Electron ${process.versions.electron || 'not used'}; generated and checked six presets in ${output}`);
console.log(JSON.stringify(sources.map(({ id, route, readOnly, noShell }) => ({ id, route, readOnly, noShell })), null, 2));
