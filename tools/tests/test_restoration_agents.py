"""Cross-runtime agent routing and capability boundaries must not drift."""
import json
from pathlib import Path
import re
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
ROUTES = {
    'scout': ('gpt-6-luna', 'low'),
    'probe': ('gpt-6-luna', 'medium'),
    'verify': ('gpt-6-luna', 'low'),
    'writer': ('gpt-6-luna', 'medium'),
    'research': ('gpt-6.1-sol', 'high'),
    'review': ('gpt-6.1-sol', 'medium'),
}


def source(role):
    text = (ROOT / '.opencode/agents' / ('fate-' + role + '.md')).read_text(encoding='utf-8')
    match = re.fullmatch(r'---\n(.*?)\n---\n\n(.*)', text, re.S)
    if match is None:
        raise ValueError('Invalid role frontmatter: ' + role)
    return match.groups()


class RestorationAgentTests(unittest.TestCase):
    def setUp(self):
        self.rows = json.loads((ROOT / '.dsh/bundles/fate-agents/cordis.patch.yml').read_text(encoding='utf-8'))[0]['insert']
        self.presets = {row['config']['id']: row['config'] for row in self.rows}
        self.parent = self.presets['fate-restoration']

    def test_all_six_routes_agree_across_runtimes(self):
        self.assertEqual(len(self.rows), 7)
        for role, (model, effort) in ROUTES.items():
            with self.subTest(role=role):
                header, body = source(role)
                self.assertIn('model: openai/' + model + '#' + effort, header)
                profile = tomllib.loads((ROOT / '.codex/agents' / ('fate-' + role + '.toml')).read_text(encoding='utf-8'))
                self.assertEqual(profile['model'], model)
                self.assertEqual(profile['model_reasoning_effort'], effort)
                self.assertEqual(profile['developer_instructions'].strip(), body.strip())
                delegate = next(p['config'] for p in self.parent['plugins'] if p['id'] == 'delegate-fate-' + role)
                self.assertEqual(delegate['agentOptions'], dict(provider='openai', model=model, reasoningEffort=effort))
                self.assertFalse(delegate['modelSelection'])
                self.assertEqual(delegate['agentPreset'], 'fate-' + role)
                self.assertEqual(delegate['toolName'], 'fate_' + role)

    def test_child_delegation_is_absent_and_depth_is_bounded(self):
        for role in ROUTES:
            header, _ = source(role)
            self.assertIn('action: subagent', header)
            child = self.presets['fate-' + role]
            for plugin in child['plugins']:
                self.assertFalse(re.search(r'subagent|workflow|goal|schedule|plugin-manager', plugin['name']))
            delegate = next(p['config'] for p in self.parent['plugins'] if p['id'] == 'delegate-fate-' + role)
            self.assertEqual(delegate['maxDepth'], 1)

    def test_read_only_roles_and_writer_tools(self):
        for role in ROUTES:
            plugins = {p['id']: p for p in self.presets['fate-' + role]['plugins']}
            readonly = role in ('scout', 'verify', 'review')
            self.assertEqual(plugins['tool-fs']['config']['write'], not readonly)
            self.assertEqual(plugins['tool-fs']['config']['edit'], not readonly)
            self.assertEqual('tool-pwsh' in plugins, role not in ('scout', 'review'))
            self.assertEqual('tool-web' in plugins, role == 'research')
            profile = tomllib.loads((ROOT / '.codex/agents' / ('fate-' + role + '.toml')).read_text(encoding='utf-8'))
            if role in ('scout', 'review'):
                self.assertFalse(profile['features']['shell_tool'])
            _, body = source(role)
            persona = plugins['persona']['config']['prefix']
            self.assertTrue(persona.startswith(body.strip()))
        writer = {p['id']: p for p in self.presets['fate-writer']['plugins']}
        self.assertNotIn('tool-jobs', writer)
        self.assertTrue(writer['tool-fs']['config']['write'])


if __name__ == '__main__':
    unittest.main()
