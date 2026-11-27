from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import restoration_handoff as handoff


def digest(data):
    return hashlib.sha256(data).hexdigest()


class RestorationHandoffTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.build = self.root / 'build'
        self.build.mkdir()
        self.exe = b'fixture executable'
        (self.build / 'FATE.EXE').write_bytes(self.exe)
        obj = b'object image fixture'
        (self.build / 'unit.obj').write_bytes(obj)
        self.target = digest(self.exe)
        inventory = {
            'target_sha256': self.target,
            'spans': [{'object': 'unit.obj', 'object_sha256': digest(obj)}],
            'non_routine_code_spans': [],
        }
        self.inventory_bytes = json.dumps(inventory).encode()
        (self.build / 'c.json').write_bytes(self.inventory_bytes)
        self.validation = {
            'status': 'passed', 'mode': 'full', 'whole_image_verified': True,
            'executable_sha256': self.target, 'fixtures': ['one', 'two'],
        }
        self._write_validation()
        self.audit_path = self.root / 'audit.json'
        self.audit = {
            'target_sha256': self.target,
            'inventory_sha256': digest(self.inventory_bytes),
            'code_segment': {
                'compiler_generated': {'bytes': 3},
                'inline_assembly': {'bytes': 2},
                'standalone_assembly': {'bytes': 4},
                'unattributed': {'bytes': 1},
            },
            'totals': {'target_routines': 11, 'measured_routines': 7},
        }
        self._write_audit()

    def _write_validation(self):
        (self.build / 'validation.json').write_text(json.dumps(self.validation), encoding='utf-8')

    def _write_audit(self):
        self.audit_path.write_text(json.dumps(self.audit), encoding='utf-8')

    def run_summary(self):
        with patch.object(handoff, 'TARGET_SHA256', self.target), patch.object(handoff, 'CODE_SIZE', 10):
            return handoff.summarize(self.build, self.audit_path)

    def test_success_recomputes_percentages_and_compact_fields(self):
        result = self.run_summary()
        self.assertEqual(result['fixture_count'], 2)
        self.assertEqual(result['remaining_assembly_bytes'], 6)
        self.assertEqual(result['categories']['compiler_generated']['percent'], 30.0)
        self.assertEqual(result['categories']['standalone_assembly']['percent'], 40.0)
        self.assertEqual(result['target_routines'], 11)
        self.assertIn('restore.py doctor', result['scope'])

    def test_rejects_mismatched_executable_hashes(self):
        self.audit['target_sha256'] = 'bad'
        self._write_audit()
        with self.assertRaisesRegex(ValueError, 'executable SHA-256'):
            self.run_summary()

    def test_rejects_tampered_executable_and_inventory_target(self):
        (self.build / 'FATE.EXE').write_bytes(b'tampered executable')
        with self.assertRaisesRegex(ValueError, 'executable SHA-256'):
            self.run_summary()
        (self.build / 'FATE.EXE').write_bytes(self.exe)
        inventory = json.loads(self.inventory_bytes)
        inventory['target_sha256'] = 'bad'
        (self.build / 'c.json').write_text(json.dumps(inventory), encoding='utf-8')
        self.audit['inventory_sha256'] = digest((self.build / 'c.json').read_bytes())
        self._write_audit()
        with self.assertRaisesRegex(ValueError, 'C inventory target'):
            self.run_summary()

    def test_rejects_audit_inventory_digest_mismatch(self):
        self.audit['inventory_sha256'] = 'bad'
        self._write_audit()
        with self.assertRaisesRegex(ValueError, 'C inventory SHA-256'):
            self.run_summary()

    def test_rejects_object_digest_mismatch_and_missing_object(self):
        (self.build / 'unit.obj').write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError, 'Object SHA-256'):
            self.run_summary()
        (self.build / 'unit.obj').unlink()
        with self.assertRaises(FileNotFoundError):
            self.run_summary()

    def test_rejects_object_path_traversal(self):
        inventory = json.loads(self.inventory_bytes)
        inventory['spans'][0]['object'] = '../outside.obj'
        (self.build / 'c.json').write_text(json.dumps(inventory), encoding='utf-8')
        self.audit['inventory_sha256'] = digest((self.build / 'c.json').read_bytes())
        self._write_audit()
        with self.assertRaisesRegex(ValueError, 'escapes build'):
            self.run_summary()

    def test_rejects_category_total_mismatch(self):
        self.audit['code_segment']['unattributed']['bytes'] = 0
        self._write_audit()
        with self.assertRaisesRegex(ValueError, 'do not sum'):
            self.run_summary()

    def test_rejects_extra_category(self):
        self.audit['code_segment']['extra'] = {'bytes': 0}
        self._write_audit()
        with self.assertRaisesRegex(ValueError, 'exactly the four'):
            self.run_summary()

    def test_rejects_negative_and_boolean_category_counts(self):
        for value in (-1, True):
            self.audit['code_segment']['inline_assembly']['bytes'] = value
            self._write_audit()
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, 'Invalid byte count'):
                self.run_summary()

    def test_rejects_incomplete_or_non_whole_image_validation(self):
        baseline = dict(self.validation)
        for key, value in (('status', 'pending'), ('mode', 'targeted'),
                           ('whole_image_verified', False)):
            self.validation = dict(baseline)
            self.validation[key] = value
            self._write_validation()
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, 'passed whole-image'):
                self.run_summary()

    def test_cli_prints_parseable_json_and_writes_same_json(self):
        with patch.object(handoff, 'TARGET_SHA256', self.target), patch.object(handoff, 'CODE_SIZE', 10):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                handoff.main([str(self.build), '--audit', str(self.audit_path)])
            printed = json.loads(stdout.getvalue())
            output_path = self.root / 'summary.json'
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                handoff.main([str(self.build), '--audit', str(self.audit_path),
                              '--output', str(output_path)])
        self.assertEqual(json.loads(output_path.read_text(encoding='utf-8')), printed)
        self.assertTrue(stdout.getvalue().startswith('PASS:'))

    def test_cli_rejects_output_collision_with_saved_inputs(self):
        with patch.object(handoff, 'TARGET_SHA256', self.target), patch.object(handoff, 'CODE_SIZE', 10):
            inputs = [self.build / 'FATE.EXE', self.build / 'validation.json',
                      self.build / 'c.json', self.audit_path, self.build / 'unit.obj']
            for path in inputs:
                with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'overwrite an input artifact'):
                    handoff.main([str(self.build), '--audit', str(self.audit_path),
                                  '--output', str(path)])
        self.assertEqual((self.build / 'FATE.EXE').read_bytes(), self.exe)


if __name__ == '__main__':
    unittest.main()
