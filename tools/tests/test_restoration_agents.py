"""Guard the authoritative Codex agent routes and supported capabilities."""
from pathlib import Path
import re
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
ROUTES = {
    'research': ('gpt-6.2-sol', 'high'),
    'review': ('gpt-6.2-sol', 'medium'),
}


class RestorationAgentTests(unittest.TestCase):
    def setUp(self):
        self.profiles = {
            path.stem: tomllib.loads(path.read_text(encoding='utf-8'))
            for path in (ROOT / '.codex/agents').glob('*.toml')
        }

    def test_profiles_have_the_expected_models_and_complete_roles(self):
        self.assertEqual(set(self.profiles), {'fate-' + role for role in ROUTES})
        for role, (model, effort) in ROUTES.items():
            with self.subTest(role=role):
                profile = self.profiles['fate-' + role]
                self.assertEqual(profile['name'], 'fate-' + role)
                self.assertEqual(profile['model'], model)
                self.assertEqual(profile['model_reasoning_effort'], effort)
                self.assertTrue(profile['description'].strip())
                self.assertTrue(profile['developer_instructions'].strip())

    def test_file_only_roles_disable_shell_access(self):
        for role in ('review',):
            with self.subTest(role=role):
                self.assertIs(self.profiles['fate-' + role]['features']['shell_tool'], False)

    def test_documented_routes_match_authoritative_profiles(self):
        text = (ROOT / 'docs/RESTORATION-AGENTS.md').read_text(encoding='utf-8')
        rows = {}
        for line in text.splitlines():
            columns = [column.strip() for column in line.split('|')]
            if len(columns) == 5:
                match = re.fullmatch(r'\[(fate-[a-z-]+)\]\([^)]+\)', columns[1])
                if match:
                    rows[match[1]] = columns[2]
        self.assertEqual(set(rows), set(self.profiles))
        model_names = {'gpt-6-luna': 'GPT-6 Luna', 'gpt-6.2-sol': 'GPT-6.2 Sol'}
        for name, profile in self.profiles.items():
            with self.subTest(role=name):
                self.assertIn(model_names[profile['model']], rows[name])
                self.assertIn(profile['model_reasoning_effort'], rows[name])


if __name__ == '__main__':
    unittest.main()
