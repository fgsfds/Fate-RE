from contextlib import ExitStack, redirect_stdout, redirect_stderr
from hashlib import sha256
from io import StringIO
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import restoration_build as build
from restoration_build import Unit
from restoration_registry import fixtures, switch_groups
from restore import registrations, routine_context
from restoration_context import reference_span
from le_fixups import RelocationIndex, pointer_range
from validation_workflow import StageRunner, run_fixtures
import validation_workflow as workflow
from build_assembly import source_dependencies
from verification_diagnostics import code_mismatch, relocation_mismatch
from verify_c_leaf import parsed_leaf_object, bind_leaf_details
from test_verify_c_leaf import fixture
from cache_contract import CompilerCacheContract


class Registrations(unittest.TestCase):
    def test_all_registered_code_objects_have_build_units(self):
        units = build.load_units()
        names = {unit.name for unit in units}
        self.assertEqual(len(names), len(units))
        self.assertFalse({row['object'] for row in registrations().values()} - names)
        for unit in units:
            self.assertTrue((build.ROOT / 'src' / (unit.source + '.c')).is_file())
        # Includes in inactive long-name branches must also resolve safely.
        staged = build.staged_sources(units)
        for unit in units:
            self.assertTrue(build.dependencies(build.ROOT / 'src' / (unit.source + '.c'), staged))

    def test_special_flags_and_generated_board_variants(self):
        units = {unit.name: unit for unit in build.load_units()}
        self.assertEqual(units['timercb'].flags, '/3r /s /od /bt=dos')
        self.assertEqual(units['peffspn'].flags, '/3r /s /or /oa /bt=dos')
        self.assertEqual(units['rtmemcpy'].flags, '/4r /s /or /ot /ms /r /bt=dos')
        self.assertIn('/dFATE_DOS_SHORT_NAMES', units['cacheunt'].flags)
        self.assertEqual(units['path01'].filename, 'brdpath.c')
        self.assertIn('/dBOARD_INDEX=24', units['path25'].flags)
        self.assertNotIn('/or', units['path25'].flags)
        self.assertIn('/or', units['path24'].flags)

    def test_unknown_object_selection_fails(self):
        with self.assertRaisesRegex(ValueError, 'Unknown objects'):
            build.select_units(build.load_units(), ['typo.obj'])

    def test_fixture_dependencies_are_explicit_and_complete(self):
        names = {unit.name for unit in build.load_units()}
        entries = fixtures()
        self.assertTrue(entries)
        self.assertEqual(len({entry.script for entry in entries}), len(entries))
        for entry in entries:
            self.assertTrue(entry.objects)
            self.assertFalse(entry.objects - names)
            for argument in entry.arguments:
                if argument.endswith('.obj'):
                    self.assertIn(Path(argument).stem, entry.objects)
        self.assertEqual([row.script for row in fixtures({'menuloop'})], ['check_run_menu_loop'])
        self.assertEqual(fixtures({'krand'}), [])

    def test_switch_group_spans_partition_binder_extents(self):
        for filename, (_, _, size, parts, _) in switch_groups().items():
            with self.subTest(filename=filename):
                self.assertEqual(parts[0][0], 0)
                self.assertEqual(parts[-1][1], size)
                self.assertTrue(all(left[1] == right[0] for left, right in zip(parts, parts[1:])))

    def test_context_is_bounded_and_finds_attempts(self):
        context = routine_context('run_menu_loop')
        self.assertEqual(context['units'][0]['object'], 'menuloop.obj')
        self.assertEqual(context['fixtures'], ['check_run_menu_loop'])
        self.assertTrue(context['attempts']['lines'])
        self.assertLess(len(json.dumps(context)), 10000)

    def test_context_supports_unconverted_assembly(self):
        from verify_assembly_suite import ROUTINES
        symbols = registrations()
        routine = next(row[0] for row in ROUTINES if row[0] not in symbols)
        context = routine_context(routine)
        self.assertTrue(context['assembly'])
        self.assertLess(len(json.dumps(context)), 10000)


    def test_reference_context_maps_c_and_assembly_symbols_to_loaded_spans(self):
        self.assertEqual(reference_span(routine_context('write_stream_descriptor'),
                                        'write_stream_descriptor'), (0x6aebe, 124))
        context = routine_context('initialize_board_actors')
        self.assertEqual(reference_span(context, 'initialize_board_actors'), (0x1e91a, 32303))

    def test_reference_context_requires_routine_symbol(self):
        with self.assertRaisesRegex(ValueError, 'unambiguous routine symbol'):
            reference_span(routine_context('dwrite'), 'dwrite')


class IncrementalCompiler(CompilerCacheContract, unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.scratch = self.root / 'work/test'
        self.source = self.root / 'src/engine/sample.c'
        self.source.parent.mkdir(parents=True)
        self.source.write_text('#include "sample.h"\nint sample;\n')
        (self.source.parent / 'sample.h').write_text('#include "nested.h"\n')
        (self.source.parent / 'nested.h').write_text('/* include cycle */\n#include "sample.h"\n')
        self.manifest = self.root / 'manifest.txt'
        self.manifest.write_text('engine/sample sample')
        self.units = [Unit('engine/sample', 'sample')]
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        for attribute, value in (
                ('ROOT', self.root), ('MANIFEST', self.manifest), ('HEADERS', []),
                ('INCLUDES', {}), ('SOURCE_TIMES', {})):
            self.stack.enter_context(patch.object(build, attribute, value))
        self.stack.enter_context(patch.object(build, 'load_units', return_value=self.units))
        self.stack.enter_context(patch.object(build, 'tool_identity', return_value={'wcc386.exe': 'pinned'}))
        self.process = self.stack.enter_context(patch.object(build.subprocess, 'run', side_effect=self.compile))
        self.stack.enter_context(redirect_stdout(StringIO()))

    def compile(self, *args, **kwargs):
        self.scratch.joinpath('sample.obj').write_bytes(b'compiled object')
        self.scratch.joinpath('sample.log').write_text('3 lines, 0 warnings, 0 errors\n')
        self.scratch.joinpath('matrix.txt').write_text('PASS')
        return SimpleNamespace(returncode=0)

    def run_build(self, incremental=True):
        return build.compile_units(self.scratch, incremental=incremental, cache=self.root / 'cache')

    def cache_build(self, *, clean):
        return len(self.run_build(incremental=not clean)['compiled'])

    def cache_fail(self):
        self.process.side_effect = None
        self.process.return_value = SimpleNamespace(returncode=1)

    def cache_assert_invalid(self):
        with self.assertRaisesRegex(ValueError, 'Stale/missing'):
            build.assert_fresh(self.scratch)

    def test_noop_skips_compiler_and_retains_complete_marker_plan(self):
        self.assertEqual(self.run_build()['compiled'], ['sample'])
        self.process.reset_mock()
        self.assertEqual(self.run_build()['compiled'], [])
        self.process.assert_not_called()
        self.assertIn('wcc386 sample.c', (self.scratch / 'engine.bat').read_text())
        build.assert_fresh(self.scratch)

    def test_nested_include_change_invalidates_cache(self):
        self.run_build()
        (self.source.parent / 'nested.h').write_text('/* changed */')
        with self.assertRaisesRegex(ValueError, 'Stale/missing'):
            build.assert_fresh(self.scratch)
        self.assertEqual(self.run_build()['compiled'], ['sample'])

    def test_timestamp_only_change_does_not_recompile(self):
        self.run_build()
        os.utime(self.source, (1234567890, 1234567890))
        self.assertEqual(self.run_build()['compiled'], [])

    def test_output_corruption_is_restored_only_from_verified_cache(self):
        self.run_build()
        (self.scratch / 'sample.obj').write_bytes(b'corrupt')
        result = self.run_build()
        self.assertEqual(result['compiled'], [])
        self.assertEqual(result['cache_hits'], ['sample'])
        self.assertEqual((self.scratch / 'sample.obj').read_bytes(), b'compiled object')

    def test_corrupt_cache_forces_recompile(self):
        self.run_build()
        state = build.read_provenance(self.scratch)['units']['sample']
        (self.root / 'cache' / state['key'] / 'code.obj').write_bytes(b'corrupt')
        (self.scratch / 'sample.obj').write_bytes(b'corrupt')
        self.assertEqual(self.run_build()['compiled'], ['sample'])

    def test_flags_change_invalidates_cache(self):
        self.run_build()
        self.units[:] = [Unit('engine/sample', 'sample', '/3r /s /bt=dos')]
        self.assertEqual(self.run_build()['compiled'], ['sample'])

    def test_unrelated_manifest_entry_does_not_recompile_existing_unit(self):
        self.run_build()
        self.manifest.write_text('engine/sample sample\nengine/other other\n')
        self.assertEqual(self.run_build()['compiled'], [])

    def test_failed_compile_cannot_inherit_successful_provenance(self):
        self.run_build()
        self.source.write_text('broken code')
        self.process.side_effect = None
        self.process.return_value = SimpleNamespace(returncode=1)
        with self.assertRaisesRegex(ValueError, 'Compiler failed'):
            self.run_build()
        with self.assertRaisesRegex(ValueError, 'Stale/missing'):
            build.assert_fresh(self.scratch)

    def test_no_freshness_claim_without_provenance_or_for_unknown_units(self):
        with self.assertRaisesRegex(ValueError, 'No build provenance'):
            build.assert_fresh(self.scratch)
        self.run_build()
        with self.assertRaisesRegex(ValueError, 'Unknown objects'):
            build.assert_fresh(self.scratch, {'typo'})

    def test_unresolved_include_fails_closed(self):
        self.source.write_text('#include HEADER_MACRO')
        with self.assertRaisesRegex(ValueError, 'computed include'):
            self.run_build()

    def test_scratch_must_be_under_ignored_work(self):
        with self.assertRaisesRegex(ValueError, 'directly under work'):
            build.compile_units(self.root / 'elsewhere')


class IndexedVerification(unittest.TestCase):
    def test_index_matches_dict_at_boundaries(self):
        pointers = {100: 200, 104: 201, 109: 202, 110: 203}
        index = RelocationIndex(pointers)
        self.assertEqual(index, pointers)
        self.assertEqual(index[104], 201)
        for start, size in ((100, 10), (101, 9), (110, 1), (0, 100), (100, 0)):
            self.assertEqual(pointer_range(index, start, size), pointer_range(pointers, start, size))
        with self.assertRaises(KeyError):
            _ = index[101]

    def test_cached_omf_is_immutable_and_placement_independent(self):
        blob = fixture(bytes.fromhex('e4 00 16 01 01'))
        parsed = parsed_leaf_object(blob)
        with self.assertRaises(TypeError):
            parsed[0][1]['data'][0] = 0
        first, _ = bind_leaf_details(blob, 'leaf', {'global': 100})
        second, _ = bind_leaf_details(blob, 'leaf', {'global': 200})
        self.assertEqual(first, (104).to_bytes(4, 'little'))
        self.assertEqual(second, (204).to_bytes(4, 'little'))
        self.assertIs(parsed_leaf_object(blob), parsed)

    def test_size_only_mismatch_identifies_first_missing_byte(self):
        report = code_mismatch('test', b'\x90', b'\x90\xc3', 0x10000)
        self.assertIn('+0x1', report)
        self.assertIn('1 generated vs 2 expected', report)

    def test_relocation_difference_is_bounded(self):
        report = relocation_mismatch({i: 10 for i in range(100)}, {}, limit=3)
        self.assertEqual(report.count('expected'), 3)
        self.assertIn('absent', report)


class DependencyPathNormalization(unittest.TestCase):
    def test_root_and_source_use_the_same_canonical_path(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            source = root / 'sample.c'
            source.write_text('#include "nested.h"\n')
            (root / 'nested.h').write_text('int sample;\n')
            alias = root / 'unused' / '..'
            with patch.object(build, 'ROOT', alias):
                result = build.dependencies(source, {})
            self.assertEqual(set(result), {'sample.c', 'nested.h'})

    @unittest.skipUnless(os.name == 'nt', 'Windows 8.3 path regression')
    def test_windows_short_root_and_long_source(self):
        import ctypes
        from ctypes import wintypes
        with TemporaryDirectory(prefix='fate restoration long path ') as temporary:
            root = Path(temporary).resolve()
            source = root / 'sample.c'
            source.write_text('int sample;\n')
            get_short_path = ctypes.WinDLL('kernel32', use_last_error=True).GetShortPathNameW
            get_short_path.argtypes = (wintypes.LPCWSTR, wintypes.LPWSTR, wintypes.DWORD)
            get_short_path.restype = wintypes.DWORD
            buffer = ctypes.create_unicode_buffer(32768)
            length = get_short_path(str(root), buffer, len(buffer))
            if not length or length >= len(buffer) or Path(buffer.value) == root:
                self.skipTest('8.3 aliases are not available on this volume')
            with patch.object(build, 'ROOT', Path(buffer.value)):
                self.assertEqual(set(build.dependencies(source, {})), {'sample.c'})

    def test_canonicalization_still_rejects_sources_outside_root(self):
        with TemporaryDirectory() as temporary:
            parent = Path(temporary).resolve()
            root = parent / 'repo'
            root.mkdir()
            outside = parent / 'outside.c'
            outside.write_text('int outside;\n')
            with patch.object(build, 'ROOT', root):
                with self.assertRaises(ValueError):
                    build.dependencies(outside, {})


class StageLogging(unittest.TestCase):
    def test_failure_saves_full_log_but_bounds_diagnostics(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            runner = StageRunner(root, {})

            def failed(command, **kwargs):
                kwargs['stdout'].write('\n'.join(f'line {i}' for i in range(100)))
                return SimpleNamespace(returncode=1)

            with patch('validation_workflow.subprocess.run', side_effect=failed):
                with self.assertRaisesRegex(ValueError, 'full log') as caught:
                    runner.call('failing-check', ['fake-command'])
            self.assertNotIn('line 0\n', str(caught.exception))
            self.assertIn('line 99', str(caught.exception))
            self.assertIn('line 0\n', (root / 'logs/failing-check.log').read_text())
            self.assertEqual(json.loads((root / 'stages.json').read_text())[0]['status'], 'failed')

    def test_bounded_workers_and_targeted_fixture_selection(self):
        with TemporaryDirectory() as temporary, redirect_stdout(StringIO()):
            runner = StageRunner(Path(temporary), {})
            with patch.object(runner, 'call') as call:
                self.assertEqual(run_fixtures(runner, Path('reference.exe'), {'menuloop'}, jobs=2),
                                 ['check_run_menu_loop'])
                self.assertEqual(call.call_count, 1)
            with self.assertRaisesRegex(ValueError, 'between 1 and 8'):
                run_fixtures(runner, Path('reference.exe'), jobs=0)


class DependencyReuse(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.wheels = self.root / 'inputs/wheels'
        self.wheels.mkdir(parents=True)
        self.wheel = self.wheels / 'test.whl'
        self.wheel.write_bytes(b'pinned wheel')
        (self.root / 'inputs.sha256').write_text(
            sha256(self.wheel.read_bytes()).hexdigest() + '  wheels/test.whl\n')
        self.directory = self.root / 'deps'

    def install(self, command, **kwargs):
        (self.directory / 'module.py').write_text('pinned installed module')
        return SimpleNamespace(returncode=0, stdout='', stderr='')

    def test_reuses_only_matching_installed_file_hashes(self):
        with patch.object(workflow, 'TOOLS', self.root), patch.object(
                workflow.subprocess, 'run', side_effect=self.install) as installer:
            workflow.ensure_dependencies(self.directory)
            workflow.ensure_dependencies(self.directory)
            self.assertEqual(installer.call_count, 1)
            (self.directory / 'module.py').write_text('changed')
            with self.assertRaisesRegex(ValueError, 'Dependency cache changed'):
                workflow.ensure_dependencies(self.directory)

    def test_changed_wheel_rejected_before_using_cache(self):
        self.wheel.write_bytes(b'tampered')
        with patch.object(workflow, 'TOOLS', self.root):
            with self.assertRaisesRegex(ValueError, 'Pinned dependency wheel changed'):
                workflow.ensure_dependencies(self.directory)

    def test_unmanaged_existing_directory_is_not_overwritten(self):
        self.directory.mkdir()
        with patch.object(workflow, 'TOOLS', self.root):
            with self.assertRaisesRegex(ValueError, 'Incomplete/unmanaged'):
                workflow.ensure_dependencies(self.directory)

    def test_python_optimization_environment_is_removed(self):
        with patch.dict(os.environ, {'PYTHONOPTIMIZE': '2'}):
            self.assertNotIn('PYTHONOPTIMIZE', workflow.python_environment(Path('deps')))


class AssemblyDependencies(unittest.TestCase):
    def test_nested_include_is_part_of_cache_key(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'entry.asm'
            included = root / 'nested.asm'
            source.write_text('%include "nested.asm"\nret\n')
            included.write_text('nop\n')
            before = source_dependencies(source, root)
            self.assertEqual(set(before), {'entry.asm', 'nested.asm'})
            included.write_text('int3\n')
            self.assertNotEqual(before, source_dependencies(source, root))

    def test_computed_include_is_not_silently_omitted(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'entry.asm'
            source.write_text('%include SOME_MACRO\n')
            with self.assertRaisesRegex(ValueError, 'computed assembly dependency'):
                source_dependencies(source, root)


class TargetedSafety(unittest.TestCase):
    def test_group_validation_can_be_restricted_without_reading_other_objects(self):
        from verify_c_suite import verify_compiler_groups
        verify_compiler_groups(b'', Path('nonexistent'), names=set())

    def test_incomplete_research_arguments_are_rejected(self):
        from restore import main
        arguments = ['restore.py', 'probe', 'krand', '--reference', 'unused.exe',
                     '--raw-offset', '0x35600']
        with patch('sys.argv', arguments), redirect_stderr(StringIO()):
            with self.assertRaises(SystemExit) as caught:
                main()
        self.assertEqual(caught.exception.code, 1)


if __name__ == '__main__':
    unittest.main()
