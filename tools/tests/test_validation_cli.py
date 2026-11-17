"""Lean/full CLI routing must never silently add regressions or game smoke."""
from contextlib import ExitStack, redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import json

import restore


class ValidationCLI(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        # Windows CI may spell TEMP with an 8.3 alias; match the CLI's resolved root.
        self.root = Path(self.temporary.name).resolve()
        self.build = self.root / 'work' / 'cli-test'

    def dispatch(self, *options):
        with patch.object(restore, 'ROOT', self.root), patch(
                'sys.argv', ['restore.py', 'validate', '--build', str(self.build), *options]), patch.object(
                restore.subprocess, 'call', return_value=0) as process:
            with self.assertRaises(SystemExit) as caught:
                restore.main()
            self.assertEqual(caught.exception.code, 0)
            return process.call_args.args[0]

    def test_default_routes_to_exact(self):
        command = self.dispatch()
        self.assertIn('--exact', command)
        self.assertNotIn('--full', command)
        self.assertNotIn('--smoke', command)
        self.assertNotIn('--resume', command)

    def test_existing_build_is_resumed(self):
        self.build.mkdir(parents=True)
        self.assertIn('--resume', self.dispatch('--exact'))

    def test_clean_does_not_resume_existing_build(self):
        self.build.mkdir(parents=True)
        self.assertNotIn('--resume', self.dispatch('--clean'))

    def test_full_forwards_reference_and_explicit_smoke(self):
        reference = self.root / 'original.exe'
        command = self.dispatch('--full', '--reference', str(reference), '--smoke')
        self.assertIn('--full', command)
        self.assertIn('--smoke', command)
        self.assertEqual(command[command.index('--reference') + 1], str(reference.resolve()))

    def test_reference_is_forwarded_in_default_exact_mode_too(self):
        reference = self.root / 'original.exe'
        command = self.dispatch('--reference', str(reference))
        self.assertEqual(command[command.index('--reference') + 1], str(reference.resolve()))

    def test_invalid_combinations_fail_without_launching_build(self):
        for options in (['--smoke'], ['--fixtures'], ['--changed', '--clean',
                                                   '--reference', 'unused.exe']):
            with self.subTest(options=options), patch.object(restore, 'ROOT', self.root), patch(
                    'sys.argv', ['restore.py', 'validate', '--build', str(self.build), *options]), patch.object(
                    restore.subprocess, 'call') as process, redirect_stderr(StringIO()):
                with self.assertRaises(SystemExit) as caught:
                    restore.main()
                self.assertEqual(caught.exception.code, 1)
                process.assert_not_called()

    def test_probe_fixtures_are_opt_in(self):
        for options, expected in (([], False), (['--fixtures'], True)):
            with self.subTest(options=options), patch.object(restore, 'ROOT', self.root), patch(
                    'sys.argv', ['restore.py', 'probe', 'leaf', '--build', str(self.build),
                                 '--reference', 'original.exe', *options]), patch.object(
                    restore, 'resolve_units', return_value=[SimpleNamespace(name='leaf')]), patch.object(
                    restore, 'targeted') as targeted:
                restore.main()
                self.assertEqual(targeted.call_args.args[0].fixtures, expected)


class TargetedFixtureModes(unittest.TestCase):
    def test_targeted_dependencies_and_fixtures_are_only_loaded_on_request(self):
        for requested in (False, True):
            with self.subTest(fixtures=requested), TemporaryDirectory() as directory, \
                    ExitStack() as stack, redirect_stdout(StringIO()):
                args = SimpleNamespace(build=Path(directory) / 'probe', reference=Path('original.exe'),
                                       command='probe', symbol=None, fixtures=requested,
                                       dependencies=None, jobs=1)
                for name, value in (
                        ('verified_reference', b'original'), ('compile_units', {}),
                        ('verify_objects', [{'symbol': 'leaf_'}]),
                        ('assert_fresh', {'leaf': {'key': 'fresh'}})):
                    stack.enter_context(patch.object(restore, name, return_value=value))
                fixtures = stack.enter_context(patch.object(
                    restore, 'fixtures', return_value=[SimpleNamespace(arguments=())]))
                stack.enter_context(patch('validation_workflow.validation_inputs',
                                          return_value={'source.c': 'current'}))
                dependencies = stack.enter_context(patch(
                    'validation_workflow.ensure_dependencies', return_value=Path(directory) / 'deps'))
                stack.enter_context(patch('validation_workflow.StageRunner', return_value=Mock()))
                run = stack.enter_context(patch('validation_workflow.run_fixtures',
                                                return_value=['check_leaf']))
                restore.targeted(args, ['leaf'])
                self.assertEqual(fixtures.call_count, int(requested))
                self.assertEqual(dependencies.call_count, int(requested))
                self.assertEqual(run.call_count, int(requested))
                report = json.loads((args.build / 'targeted-validation.json').read_text())
                self.assertEqual(report['fixtures_requested'], requested)
                self.assertFalse(report['whole_image_verified'])
                self.assertEqual(report['fixtures'], ['check_leaf'] if requested else [])


if __name__ == '__main__':
    unittest.main()
