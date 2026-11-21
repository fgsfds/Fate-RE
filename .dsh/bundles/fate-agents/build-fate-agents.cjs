const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const [project, output, ...options] = process.argv.slice(2);
assert(project && output, 'Usage: build-fate-agents.cjs <project> <output> [--sync-codex] [--check]');
assert(options.every(x => ['--sync-codex', '--check'].includes(x)), 'Unknown option');
const check = options.includes('--check');
const roles = ['scout', 'probe', 'verify', 'research', 'review', 'writer', 'ci-monitor'];
const plugin = (id, name, config) => ({
  id, name: '@deepseek-ai/dsh-' + name, ...(config === undefined ? {} : { config }),
});
const common = () => [
  plugin('agent-instructions', 'agent-instructions', { maxBytes: 65536 }),
  plugin('time-context', 'time-context'),
  plugin('skill-filesystem', 'skill-filesystem'),
  plugin('tool-skill', 'tool-skill'),
  plugin('tool-fs-search', 'tool-fs-search', { sampleOverCapGlobResults: false }),
  { id: 'compaction', name: 'cordis:group', group: true,
    isolate: { compaction: true, toolResultPruner: true }, config: [
      plugin('compaction-basic', 'compaction-basic'),
      plugin('command-compact', 'command-compact'),
      plugin('tool-result-pruner', 'compaction-tool-result-pruner',
        { thresholdChars: 4096, headChars: 2048, tailChars: 1024 }),
    ] },
];
const rows = [], sources = [];
for (const role of roles) {
  const id = 'fate-' + role;
  const source = fs.readFileSync(path.join(project, '.opencode', 'agents', id + '.md'), 'utf8').replaceAll('\r\n', '\n');
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/.exec(source);
  assert(match, 'Missing frontmatter: ' + id);
  const [, header, content] = match;
  const body = content.trim();
  const description = /^description: (.+)$/m.exec(header)?.[1].trim();
  const route = /^model: ([^/\s]+)\/([^#\s]+)#([^\s]+)$/m.exec(header);
  assert(description && route, 'Missing metadata: ' + id);
  const permissions = [...header.matchAll(/- action: (\w+)\r?\n\s+resource: "\*"\r?\n\s+effect: deny/g)]
    .map(m => m[1]);
  assert(permissions.includes('subagent'), 'Child delegation must be denied: ' + id);
  assert(permissions.every(p => ['edit', 'shell', 'subagent'].includes(p)), 'Unmapped permission: ' + id);
  const readOnly = permissions.includes('edit'), noShell = permissions.includes('shell');
  const plugins = [
    plugin('persona', 'persona', { prefix: body +
      '\n\nDSH adapter: paths are relative to the assigned working directory. No child tools are provided. ' +
      'Read only named skill sections. Configuration work does not resume restoration. ' +
      'Return missing inputs to the parent; do not bypass ownership or tool restrictions.' }),
    ...common(),
    plugin('tool-fs', 'tool-fs', { write: !readOnly, edit: !readOnly, applyPatch: false }),
  ];
  if (!noShell) plugins.push(plugin('tool-pwsh', 'tool-pwsh'));
  if (!noShell && role !== 'writer') plugins.push(plugin('tool-jobs', 'tool-jobs'));
  if (role === 'research') plugins.push(plugin('tool-web', 'tool-web', { fetch: true, searchTimeoutMs: 60000 }));
  rows.push({ id: 'preset-' + id, name: '@deepseek-ai/dsh-agent-preset', config: {
    id, name: 'Fate ' + role, description, order: 21 + roles.indexOf(role), plugins,
  } });
  sources.push({ id, role, description, body, noShell, readOnly,
    route: { provider: route[1], model: route[2], reasoningEffort: route[3] } });
}
const parent = {
  id: 'preset-fate-restoration', name: '@deepseek-ai/dsh-agent-preset', config: {
    id: 'fate-restoration', name: 'Fate restoration', order: 20,
    description: 'Integrator with seven economical, scoped roles; configuration does not resume restoration.',
    plugins: [
      plugin('persona', 'persona', { prefix:
        'You integrate Fate-RE restoration. Read AGENTS.md once and fate-restoration-coordination. ' +
        'Use dedicated role tools; their fixed model routes are not selected by a role label. ' +
        'Default to 0-2 useful children, not a headcount quota. Supply short fresh packets, owned paths, ' +
        'runtime paths, flags, one hypothesis and a budget. Use cheap scout/probe/verify/writer routes; ' +
        'research and independent review handle concrete uncertainty. Report unavailable routes without silently upgrading. ' +
        'After active-work pushes, assign the exact SHA to fate_ci_monitor. Fix reported pipeline failures, ' +
        'push the correction and recheck its new SHA; pending or absent runs are not success. ' +
        'Only one leased windowless DOSBox compiler at a time; verify exit before another starts. No game smoke. ' +
        'Keep shared acceptance, registries/inventories and commits centralized. After evidence freezes, ' +
        'delegate named docs/scripts/tests to fate_writer and review once before accepting. ' +
        'On pause stop restoration children; explicit configuration edits do not reactivate the goal.' }),
      ...common(),
      plugin('tool-fs', 'tool-fs', { applyPatch: false }),
      plugin('tool-pwsh', 'tool-pwsh'), plugin('tool-jobs', 'tool-jobs'),
      plugin('tool-subagent-control', 'tool-subagent-control', { interrupt: false }),
      plugin('tool-ask-user', 'tool-ask-user'),
      plugin('tool-todo', 'tool-todo', { allowParallelInProgress: true }),
      plugin('command-goal', 'command-goal'), plugin('tool-goal', 'tool-goal'),
      plugin('tool-web', 'tool-web', { fetch: true, searchTimeoutMs: 60000 }),
      ...sources.map(s => plugin('delegate-' + s.id, 'tool-subagent', {
        provider: 'spawn', toolName: s.id.replaceAll('-', '_'), agentPreset: s.id,
        maxDepth: 1, modelSelection: false, modelDiscovery: false, agentOptions: s.route,
      })),
    ],
  },
};
rows.unshift(parent);
assert.equal(rows.length, roles.length + 1);
assert.equal(new Set(rows.map(r => r.config.id)).size, rows.length);
for (const s of sources) {
  const child = rows.find(r => r.config.id === s.id), plugins = child.config.plugins;
  assert(plugins.find(p => p.id === 'persona').config.prefix.startsWith(s.body));
  assert(!plugins.some(p => /subagent|workflow|goal|schedule|plugin-manager/.test(p.name)));
  assert.equal(plugins.some(p => p.id === 'tool-pwsh'), !s.noShell);
  assert.equal(plugins.some(p => p.id === 'tool-jobs'), !s.noShell && s.role !== 'writer');
  const filesystem = plugins.find(p => p.id === 'tool-fs').config;
  assert.equal(filesystem.edit, !s.readOnly);
  assert.equal(filesystem.write, !s.readOnly);
  const delegate = parent.config.plugins.find(p => p.id === 'delegate-' + s.id).config;
  assert.equal(delegate.agentPreset, s.id);
  assert.deepEqual(delegate.agentOptions, s.route);
  assert.equal(delegate.maxDepth, 1);
}
function emit(filename, text) {
  if (check) {
    assert(fs.existsSync(filename), 'Missing generated file: ' + filename);
    assert.equal(fs.readFileSync(filename, 'utf8').replaceAll('\r\n', '\n'), text, 'Generated drift: ' + filename);
  } else {
    fs.mkdirSync(path.dirname(filename), { recursive: true });
    fs.writeFileSync(filename, text);
  }
}
emit(path.join(output, 'cordis.patch.yml'), JSON.stringify([{ insert: rows }], null, 2) + '\n');
emit(path.join(output, 'package.json'), JSON.stringify({
  name: '@local/fate-restoration-agents', version: '1.2.0', private: true, type: 'module',
  description: 'Fate-RE restoration presets and role-specific delegation tools for DeepSeek Harness.',
  exports: { './locale/*.json': './locale/*.json', './icon': './icon.svg' },
  files: ['cordis.patch.yml', 'locale', 'icon.svg', 'README.md', 'build-fate-agents.cjs'],
  dsh: { bundle: { patch: './cordis.patch.yml' } },
}, null, 2) + '\n');
emit(path.join(output, 'locale/en.json'), JSON.stringify({ meta: {
  title: 'Fate restoration agents',
  description: 'Integrator plus seven scoped roles. Luna handles scout/probe/verify/writer/ci-monitor; Sol handles research/review. ' +
    'Select Fate restoration in a new session after reinstalling. No default preset, credentials or goal state changes.',
} }, null, 2) + '\n');
if (options.includes('--sync-codex')) for (const s of sources) {
  assert.equal(s.route.provider, 'openai', 'Codex mapping requires an explicit OpenAI route');
  assert(!s.body.includes('"""'), 'Unsupported triple quote in role prompt');
  const q = JSON.stringify;
  const text = '# Generated from .opencode/agents; regenerate with --sync-codex.\n' +
    'name = ' + q(s.id) + '\ndescription = ' + q(s.description) +
    '\nmodel = ' + q(s.route.model) + '\nmodel_reasoning_effort = ' + q(s.route.reasoningEffort) +
    '\n\ndeveloper_instructions = """\n' + s.body.replaceAll('\\', '\\\\') + '\n"""\n' +
    (s.noShell ? '\n[features]\nshell_tool = false\n' : '');
  emit(path.join(project, '.codex/agents', s.id + '.toml'), text);
}
console.log('PASS: ' + (check ? 'checked' : 'generated') + ' ' + (roles.length + 1) + ' presets, ' + roles.length + ' routes and child tool boundaries' +
  (options.includes('--sync-codex') ? '; Codex mirrors checked' : ''));
