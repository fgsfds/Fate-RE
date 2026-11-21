import json
from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import Mock, patch
from contextlib import ExitStack, redirect_stderr, redirect_stdout
from io import StringIO

import verify_ci_build as ci
from verify_ci_build import verify_code_inventory


class CodeInventory(unittest.TestCase):
    def compare(self, observed, expected):
        with TemporaryDirectory() as directory:
            report = Path(directory) / "report.json"
            inventory = Path(directory) / "inventory.json"
            for path, row in ((report, observed), (inventory, expected)):
                path.write_text(json.dumps({
                    "spans": [row],
                    "non_routine_code_spans": [],
                }), encoding="utf-8")
            verify_code_inventory(report, inventory)

    def test_ignores_object_hash_differences(self):
        row = dict(symbol="leaf_", raw_offset="0x35600", bytes=8, le_pointers=1)
        self.compare(dict(row, object_sha256="fresh"), dict(row, object_sha256="recorded"))

    def test_rejects_stale_relocation_coverage(self):
        row = dict(symbol="leaf_", raw_offset="0x35600", bytes=8, le_pointers=1)
        with self.assertRaisesRegex(ValueError, "coverage differs"):
            self.compare(dict(row, le_pointers=0), row)


class ReferenceSafety(unittest.TestCase):
    def test_reference_is_optional(self):
        self.assertIsNone(ci.reference_bytes(None, Path('output.exe')))

    def test_rejects_reference_output_alias_before_reading(self):
        with self.assertRaisesRegex(ValueError, 'separate files'):
            ci.reference_bytes(Path('same.exe'), Path('same.exe'))

    def test_rejects_unpinned_reference(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'original.exe'
            path.write_bytes(b'not Fate')
            with self.assertRaisesRegex(ValueError, 'pinned'):
                ci.reference_bytes(path, Path(directory) / 'output.exe')

    def test_returns_verified_reference_bytes(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'original.exe'
            path.write_bytes(b'verified original')
            with patch('compare_exe.TARGET_SHA256', sha256(path.read_bytes()).hexdigest()):
                self.assertEqual(ci.reference_bytes(path, Path(directory) / 'output.exe'),
                                 b'verified original')


class ValidationModes(unittest.TestCase):
    """Test orchestration without compiling, launching games, or recursion."""
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        # Windows CI may spell TEMP with an 8.3 alias; match the CLI's resolved root.
        self.root = Path(self.temporary.name).resolve()
        self.build = self.root / 'work' / 'test-build'
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(patch.object(ci, 'ROOT', self.root))
        self.runner = Mock()
        self.runner.rows = []
        self.runner.python.side_effect = self.stage
        self.stack.enter_context(patch.object(ci, 'StageRunner', return_value=self.runner))
        self.mocks = {}
        for name in ('verify_inputs', 'assert_fresh', 'read_provenance', 'load_units',
                     'validation_inputs', 'ensure_dependencies', 'run_fixtures',
                     'verify_code_inventory', 'digest'):
            self.mocks[name] = self.stack.enter_context(patch.object(ci, name))
        self.mocks['validation_inputs'].return_value = {'source.c': 'current'}
        self.mocks['ensure_dependencies'].return_value = self.root / 'deps'
        self.mocks['load_units'].return_value = []
        self.mocks['read_provenance'].return_value = {'units': {}}
        self.mocks['run_fixtures'].return_value = []
        self.mocks['digest'].return_value = 'artifact-hash'

    def stage(self, name, *args):
        self.runner.rows.append({'stage': name})
        if name == 'link':
            (self.build / 'FATE.EXE').write_bytes(b'fresh linked executable')

    def run_main(self, *options):
        with patch('sys.argv', ['verify_ci_build.py', '--build', str(self.build), *options]), \
                redirect_stdout(StringIO()):
            ci.main()

    def report(self):
        return json.loads((self.build / 'validation.json').read_text())

    def stages(self):
        return [call.args[0] for call in self.runner.python.call_args_list]

    def test_default_exact_skips_regression_suites_and_smoke(self):
        self.run_main()
        self.assertEqual(self.stages(), ['compile', 'assemble', 'link'])
        for name in ('ensure_dependencies', 'run_fixtures', 'verify_code_inventory'):
            self.mocks[name].assert_not_called()
        self.assertEqual(self.mocks['verify_inputs'].call_count, 2)
        self.assertEqual(self.mocks['assert_fresh'].call_count, 2)
        report = self.report()
        self.assertEqual((report['status'], report['mode']), ('passed', 'exact'))
        self.assertTrue(report['whole_image_verified'])
        self.assertFalse(report['regression_checks'])
        self.assertIsNone(report['dependencies'])
        self.assertNotIn('c.json', report['artifact_hashes'])
        self.assertEqual(report['game_smoke'], 'skipped (opt-in)')

    def test_full_runs_regressions_but_never_smokes_by_default(self):
        self.run_main('--full')
        self.assertEqual(self.stages(), ['unit-tests', 'watcom-idioms', 'compile',
                                         'assemble', 'link', 'verify-c',
                                         'verify-assembly', 'coverage-docs'])
        self.mocks['run_fixtures'].assert_called_once()
        self.assertEqual(self.mocks['verify_code_inventory'].call_count, 2)
        self.assertEqual(self.report()['mode'], 'full')
        self.assertIn('c.json', self.report()['artifact_hashes'])
        self.assertEqual(self.report()['game_smoke'], 'skipped (opt-in)')

    def test_smoke_is_explicit_opt_in(self):
        self.run_main('--full', '--smoke')
        self.assertEqual(self.stages()[-1], 'smoke')
        self.assertEqual(self.report()['game_smoke'], 'passed')

    def test_smoke_without_full_is_rejected(self):
        with redirect_stderr(StringIO()), self.assertRaises(SystemExit) as caught:
            self.run_main('--smoke')
        self.assertEqual(caught.exception.code, 2)
        self.assertEqual(self.stages(), [])

    def test_link_failure_cannot_leave_previous_pass(self):
        self.build.mkdir(parents=True)
        (self.build / 'validation.json').write_text('{"status":"passed","mode":"full"}')
        self.runner.python.side_effect = RuntimeError('link failed')
        with self.assertRaisesRegex(RuntimeError, 'link failed'):
            self.run_main('--resume')
        self.assertEqual(self.report()['status'], 'pending')

    def test_input_change_during_build_is_rejected(self):
        self.mocks['validation_inputs'].side_effect = [{'source.c': 'before'},
                                                       {'source.c': 'after'}]
        with self.assertRaisesRegex(ValueError, 'changed during'):
            self.run_main()
        self.assertEqual(self.report()['status'], 'pending')

    def test_explicit_reference_is_actually_compared(self):
        with patch.object(ci, 'reference_bytes', return_value=b'fresh linked executable') as reference:
            self.run_main('--reference', str(self.root / 'original.exe'))
        reference.assert_called_once_with(self.root / 'original.exe', self.build / 'FATE.EXE')
        self.assertTrue(self.report()['reference_compared'])

    def test_reference_mismatch_cannot_pass(self):
        with patch.object(ci, 'reference_bytes', return_value=b'different original'):
            with self.assertRaisesRegex(ValueError, 'differs from the pinned reference'):
                self.run_main('--reference', str(self.root / 'original.exe'))
        self.assertEqual(self.report()['status'], 'pending')

    def test_exact_rerun_does_not_certify_stale_full_reports(self):
        self.build.mkdir(parents=True)
        (self.build / 'c.json').write_text('stale inventory')
        self.run_main('--resume', '--exact')
        self.assertEqual(self.report()['mode'], 'exact')
        self.assertNotIn('c.json', self.report()['artifact_hashes'])
        self.assertIn('--incremental', self.runner.python.call_args_list[0].args)
