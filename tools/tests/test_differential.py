from argparse import Namespace
from contextlib import redirect_stdout
from hashlib import sha256
from io import StringIO
import json
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import differential as diff
from check_actor_movement import boundary_cases as actor_boundaries, randomized_cases as actor_random
from check_copytilepiece_candidate import boundary_cases as tile_boundaries, randomized_cases as tile_random
from test_watcom_marker_retry import object_with_code
from test_verify_c_leaf import fixture as relocated_object

ENTRY, STOP, STACK, DATA = 0x10000, 0x3ff000, 0x3f0000, 0x300000
REGISTERS = dict(eax=7, ebx=11, ecx=13, edx=17, esi=19, edi=23, ebp=29)


def execute(body, *, writable=(), contract=None):
    machine = diff.Machine(contract or diff.Contract(ENTRY, STOP, STACK, 4, results=('eax',)),
                           body, writable)
    return machine.run(REGISTERS)


class BehavioralContract(unittest.TestCase):
    def test_return_value_mismatch_is_reported(self):
        left, right = execute(b'\x40\xc3'), execute(b'\x48\xc3')
        self.assertIn('register eax', diff.first_difference(left, right))

    def test_missing_preserved_register_is_rejected(self):
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'preserved register edi'):
            execute(bytes.fromhex('31 ff c3'))

    def test_wrong_stack_cleanup_is_rejected(self):
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'stack cleanup'):
            execute(bytes.fromhex('c2 04 00'))

    def test_guard_write_is_rejected_even_when_value_is_unchanged(self):
        code = b'\xc6\x05' + (STACK + 4).to_bytes(4, 'little') + b'\xa5\xc3'
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'outside declared memory'):
            execute(code)

    def test_unexpected_store_is_rejected(self):
        code = b'\xc6\x05' + DATA.to_bytes(4, 'little') + b'\x00\xc3'
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'outside declared memory'):
            execute(code)

    def test_store_crossing_an_observable_region_boundary_is_rejected(self):
        body = b'\xc7\x05' + (DATA + 1).to_bytes(4, 'little') + bytes(4) + b'\xc3'
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'outside declared memory'):
            execute(body, writable=(diff.Region('word', DATA, 4),))

    def test_return_address_cannot_be_overwritten_even_with_the_same_value(self):
        body = bytes.fromhex('c7 04 24') + STOP.to_bytes(4, 'little') + b'\xc3'
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'outside declared memory'):
            execute(body)

    def test_signed_stack_argument_retains_all_32_bits_and_is_callee_cleaned(self):
        machine = diff.Machine(diff.Contract(ENTRY, STOP, STACK, 8, results=('eax',)),
                               bytes.fromhex('8b 44 24 04 c2 04 00'))
        self.assertEqual(machine.run(REGISTERS, (-1,)).registers['eax'], 0xffffffff)

    def test_partial_register_writes_preserve_upper_bits(self):
        for body, expected in ((bytes.fromhex('b0 ff c3'), 0x123456ff),
                               (bytes.fromhex('66 b8 ff ff c3'), 0x1234ffff),
                               (bytes.fromhex('0f be c0 c3'), 0xffffff80)):
            with self.subTest(body=body):
                machine = diff.Machine(diff.Contract(ENTRY, STOP, STACK, 4, results=('eax',)), body)
                self.assertEqual(machine.run({**REGISTERS, 'eax': 0x12345680}).registers['eax'], expected)

    def test_observable_memory_reports_first_difference(self):
        def store(value):
            return b'\xc6\x05' + DATA.to_bytes(4, 'little') + bytes((value,)) + b'\xc3'
        region = (diff.Region('result', DATA, 4),)
        left, right = execute(store(1), writable=region), execute(store(2), writable=region)
        self.assertIn('memory result+0x0', diff.first_difference(left, right))

    def test_only_explicit_abi_flags_are_compared(self):
        contract = diff.Contract(ENTRY, STOP, STACK, 4, flags_mask=1)
        left, right = execute(b'\xf8\xc3', contract=contract), execute(b'\xf9\xc3', contract=contract)
        self.assertIn('eflags', diff.first_difference(left, right))

    def test_infinite_loop_has_a_finite_instruction_budget(self):
        for wall_budget in (500000, 30000000):
            with self.subTest(wall_budget=wall_budget), self.assertRaisesRegex(
                    diff.BehaviorMismatch, 'execution budget'):
                execute(b'\xeb\xfe', contract=diff.Contract(ENTRY, STOP, STACK, 4,
                        instruction_limit=20, wall_timeout_us=wall_budget))

    def test_explicit_wall_budget_reaches_emulator_with_instruction_cap(self):
        contract = diff.Contract(ENTRY, STOP, STACK, 4, instruction_limit=20,
                                 wall_timeout_us=30000000)
        machine = diff.Machine(contract, b'\xc3')
        with patch.object(machine.cpu, 'emu_start', wraps=machine.cpu.emu_start) as run:
            machine.run(REGISTERS)
        self.assertEqual(run.call_args.kwargs['timeout'], 30000000)
        self.assertEqual(run.call_args.kwargs['count'], 20)

    def test_execution_budgets_cannot_be_disabled(self):
        for name in ('instruction_limit', 'wall_timeout_us'):
            for value in (0, -1, None, True, 0.5):
                with self.subTest(name=name, value=value), self.assertRaisesRegex(
                        ValueError, 'must be a positive integer'):
                    diff.Contract(ENTRY, STOP, STACK, 4, **{name: value})

    def test_execution_cannot_fall_through_into_uninitialized_memory(self):
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'escaped declared code'):
            execute(b'\x90')

    def test_an_instruction_may_not_straddle_the_declared_code_end(self):
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'escaped declared code'):
            execute(b'\xb8')

    def test_stack_argument_count_is_checked(self):
        machine = diff.Machine(diff.Contract(ENTRY, STOP, STACK, 8), b'\xc3')
        with self.assertRaisesRegex(ValueError, 'Stack arguments'):
            machine.run(REGISTERS)

    def test_call_order_and_arguments_are_observable(self):
        def run(order):
            code = bytearray()
            for target in order:
                code.extend(b'\xe8' + ((target - (ENTRY + len(code) + 5)) & 0xffffffff).to_bytes(4, 'little'))
            machine = diff.Machine(diff.Contract(ENTRY, STOP, STACK, 4), bytes(code) + b'\xc3')
            machine.stub(0x20000, lambda cpu: cpu.record('first', cpu.register('eax')))
            machine.stub(0x20010, lambda cpu: cpu.record('second', cpu.register('eax')))
            return machine.run(REGISTERS)
        left, right = run((0x20000, 0x20010)), run((0x20010, 0x20000))
        self.assertIn('call 0', diff.first_difference(left, right))

    def test_invalid_stub_arguments_produce_a_replayable_behavior_failure(self):
        displacement = 0x20000 - (ENTRY + 5)
        machine = diff.Machine(diff.Contract(ENTRY, STOP, STACK, 4),
                               b'\xe8' + displacement.to_bytes(4, 'little') + b'\xc3')
        machine.stub(0x20000, lambda cpu: {3: None}[cpu.register('eax')])
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'invalid external-call argument'):
            machine.run(REGISTERS)


class ResearchMode(unittest.TestCase):
    def setUp(self):
        self.original = b'\x31\xc0\xc3'
        self.candidate = b'\xb8\x00\x00\x00\x00\xc3'
        self.executable = bytes(ENTRY + 0x25600) + self.original
        self.obj = object_with_code(self.candidate)

    def bind(self, research):
        with patch.object(diff, 'TARGET_SHA256', sha256(self.executable).hexdigest()), patch.object(
                diff, 'read_le_fixups', return_value={'pointers': {}}):
            return diff.bind_bodies(self.executable, self.obj, 'test', ENTRY,
                                    len(self.original), {}, {}, behavior_only=research)

    def test_behavior_only_accepts_a_different_candidate_extent(self):
        reference, candidate, _ = self.bind(True)
        self.assertNotEqual(reference, candidate)
        self.assertIsNone(diff.first_difference(execute(reference), execute(candidate)))

    def test_exact_mode_still_rejects_the_same_nonmatching_candidate(self):
        with self.assertRaisesRegex(ValueError, 'Code mismatch'):
            self.bind(False)

    def test_unknown_reference_is_rejected_even_in_behavior_only_mode(self):
        with self.assertRaisesRegex(ValueError, 'pinned October'):
            diff.bind_bodies(self.executable, self.obj, 'test', ENTRY, 3, {}, {}, behavior_only=True)

    def test_report_never_qualifies_research_for_exact_coverage(self):
        with TemporaryDirectory() as temporary, redirect_stdout(StringIO()):
            output = Path(temporary) / 'result.json'
            args = Namespace(behavior_only=True, output=output, seed=123)
            diff.finish(args, 'test', 1, 6, 0)
            result = json.loads(output.read_text())
            self.assertFalse(result['exact_verified'])
            self.assertFalse(result['inventory_eligible'])
            self.assertEqual(result['mode'], 'behavior-only')

    def test_unified_behavior_command_does_not_call_exact_verification(self):
        import restore
        with TemporaryDirectory() as temporary, redirect_stdout(StringIO()):
            root = Path(temporary)
            obj = root / 'candidate.obj'
            obj.write_bytes(b'research object')
            args = Namespace(reference=Path('original.exe'), routine='copytilepiece',
                             build=root / 'build', object=obj, dependencies=None,
                             seed=123, random_cases=1, case_file=None)

            def run(_name, *arguments):
                output = arguments[arguments.index('--output') + 1]
                Path(output).write_text(json.dumps(dict(
                    status='passed', mode='behavior-only', exact_verified=False,
                    inventory_eligible=False)))

            with patch.object(restore, 'verified_reference'), patch.object(
                    restore, 'resolve_units', return_value=[SimpleNamespace(name='tilecopy')]), patch.object(
                    restore, 'verify_objects') as exact, patch.object(
                    restore, 'compile_units') as compile_candidate, patch(
                    'validation_workflow.ensure_dependencies', return_value=Path('deps')), patch(
                    'validation_workflow.validation_inputs', return_value={}), patch(
                    'validation_workflow.StageRunner') as runner:
                runner.return_value.python.side_effect = run
                restore.behavior(args)
                exact.assert_not_called()
                compile_candidate.assert_not_called()
                self.assertIn('--behavior-only', runner.return_value.python.call_args.args)

    def test_registered_full_validation_fixtures_still_use_exact_mode(self):
        from restoration_registry import fixtures
        for fixture in fixtures({'actmove', 'tilecopy'}):
            self.assertNotIn('--behavior-only', fixture.arguments)


class LoadedRelocations(unittest.TestCase):
    """Exercise the real OMF binder; only the synthetic EXE's LE table is supplied."""
    def bind(self, body, obj, pointers, *, research=False, base=0x100000, absolute_code=None,
             functions=None, execution_functions=None):
        executable = bytes(ENTRY + 0x25600) + body
        with patch.object(diff, 'TARGET_SHA256', sha256(executable).hexdigest()), patch.object(
                diff, 'read_le_fixups', return_value={'pointers': pointers}), patch.object(
                diff, 'CODE_OFFSETS', absolute_code or {}):
            return diff.bind_bodies(executable, obj, 'leaf', ENTRY, len(body),
                                    {'global': 0x24} if absolute_code is None else {}, functions or {},
                                    data_base=base, behavior_only=research,
                                    execution_functions=execution_functions)

    def test_data_fixup_addend_is_rebased_identically_for_reference_and_candidate(self):
        body = b'\xa1' + (0x28).to_bytes(4, 'little') + b'\xc3'
        obj = relocated_object(bytes.fromhex('e4 01 16 01 01'),
                               b'\xa1\x04\x00\x00\x00\xc3')
        for base in (0, 0x80000, 0x100000):
            with self.subTest(base=base):
                reference, candidate, count = self.bind(
                    body, obj, {ENTRY + 1: 0x80028}, base=base)
                self.assertEqual(reference, candidate)
                self.assertEqual(count, 1)
                self.assertEqual(int.from_bytes(candidate[1:5], 'little'), base + 0x28)

    def test_matching_bytes_with_wrong_le_site_or_target_never_pass_exact_mode(self):
        body = b'\xa1' + (0x28).to_bytes(4, 'little') + b'\xc3'
        obj = relocated_object(bytes.fromhex('e4 01 16 01 01'),
                               b'\xa1\x04\x00\x00\x00\xc3')
        for pointers in ({}, {ENTRY + 2: 0x80028}, {ENTRY + 1: 0x80029}):
            with self.subTest(pointers=pointers), self.assertRaisesRegex(ValueError, 'LE relocation'):
                self.bind(body, obj, pointers)

    def test_absolute_code_pointer_uses_code_load_base_not_data_base(self):
        body = b'\xb8' + (0x12004).to_bytes(4, 'little') + b'\xc3'
        obj = relocated_object(bytes.fromhex('e4 01 16 01 01'),
                               b'\xb8\x04\x00\x00\x00\xc3')
        reference, candidate, _ = self.bind(
            body, obj, {ENTRY + 1: 0x22004}, absolute_code={'global': 0x12000})
        self.assertEqual(reference, candidate)
        self.assertEqual(int.from_bytes(candidate[1:5], 'little'), 0x22004)

    def test_behavior_only_does_not_guess_unknown_external_bindings(self):
        obj = relocated_object(bytes.fromhex('e4 00 16 01 01'), external=b'unknown')
        with self.assertRaisesRegex(ValueError, 'Unbound'):
            self.bind(bytes(4), obj, {}, research=True)

    def test_shared_tail_execution_binding_can_differ_after_exact_acceptance(self):
        displacement = 0x20000 - (ENTRY + 5)
        body = b'\xe8' + displacement.to_bytes(4, 'little') + b'\xc3'
        obj = relocated_object(bytes.fromhex('a4 01 16 01 01'), b'\xe8' + bytes(4) + b'\xc3')
        reference, candidate, count = self.bind(
            body, obj, {}, functions={'global': 0x20000}, execution_functions={'global': 0x20020})
        self.assertEqual(reference, body)
        self.assertNotEqual(reference, candidate)
        self.assertEqual(int.from_bytes(candidate[1:5], 'little'), displacement + 0x20)
        self.assertEqual(count, 0)  # A relative call is not an absolute LE fixup.

    def test_partial_reference_pointer_cannot_cross_the_fixture_boundary(self):
        for research in (False, True):
            with self.subTest(research=research):
                body = b'\x90\xc3'
                # A matching candidate has no fixups: strict mode rejects the LE
                # mismatch; behavior-only must still reject the partial load.
                obj = object_with_code(body)
                executable = bytes(ENTRY + 0x25600) + body
                with patch.object(diff, 'TARGET_SHA256', sha256(executable).hexdigest()), patch.object(
                        diff, 'read_le_fixups', return_value={'pointers': {ENTRY + 1: 0x80024}}):
                    message = 'Partial reference relocation' if research else 'LE relocation'
                    with self.assertRaisesRegex(ValueError, message):
                        diff.bind_bodies(executable, obj, 'test', ENTRY, len(body), {}, {},
                                         behavior_only=research)


class ExecutionReuse(unittest.TestCase):
    def test_only_opted_in_identical_loaded_bodies_skip_the_second_execution(self):
        for reuse, candidate, expected_runs in (
                (True, b'\xc3', 1), (False, b'\xc3', 2), (True, b'\x90\xc3', 2)):
            with self.subTest(reuse=reuse, candidate=candidate):
                exercise = Mock(side_effect=lambda body, case: execute(body))
                oracle = Mock()
                self.assertEqual(diff.compare_cases(
                    'test', b'\xc3', candidate, [dict(name='one')], exercise,
                    check_reference=oracle, reuse_identical=reuse), 1)
                self.assertEqual(exercise.call_count, expected_runs)
                oracle.assert_called_once()

    def test_reuse_never_bypasses_reference_contract_or_named_expectations(self):
        for exercise, oracle in (
                (Mock(side_effect=diff.BehaviorMismatch('bad ABI')), None),
                (Mock(return_value=diff.Observation({}, {}, ())),
                 Mock(side_effect=AssertionError('bad expected state')))):
            with self.subTest(oracle=oracle), self.assertRaises(diff.BehaviorMismatch):
                diff.compare_cases('test', b'\xc3', b'\xc3', [{}], exercise,
                                   check_reference=oracle, reuse_identical=True)
            exercise.assert_called_once()

    def test_reference_failure_is_saved_as_reference_not_candidate_failure(self):
        with TemporaryDirectory() as temporary:
            path = Path(temporary) / 'failure.json'
            with self.assertRaises(diff.BehaviorMismatch):
                diff.compare_cases('test', b'\x31\xff\xc3', b'\xc3', [{}],
                                   lambda body, case: execute(body), failure_output=path)
            self.assertEqual(json.loads(path.read_text())['phase'], 'reference')


class ReplayAndMutation(unittest.TestCase):
    def test_first_failure_is_saved_and_can_be_replayed(self):
        case = dict(name='small failing input', pixels=b'\x00\xff', value=7)
        with TemporaryDirectory() as temporary:
            path = Path(temporary) / 'failure.json'
            with self.assertRaisesRegex(diff.BehaviorMismatch, 'register eax'):
                diff.compare_cases('test', b'\x40\xc3', b'\x48\xc3', [case],
                                   lambda body, _case: execute(body), failure_output=path, seed=123)
            report = json.loads(path.read_text())
            self.assertEqual(diff.replay_case(path, 'test'), case)
            self.assertEqual(report['phase'], 'candidate')
            self.assertEqual(report['seed'], 123)
            self.assertFalse(report['inventory_eligible'])
            with self.assertRaisesRegex(ValueError, 'another fixture'):
                diff.replay_case(path, 'other')

    def test_real_mutants_are_rejected_but_equivalent_code_is_not_called_a_defect(self):
        runner = lambda body, _case: execute(body)
        self.assertEqual(diff.require_mutations_detected(
            'test', b'\x40\xc3', [('bad result', b'\x48\xc3', {})], runner), ['bad result'])
        with self.assertRaisesRegex(AssertionError, 'missed mutation'):
            diff.require_mutations_detected('test', b'\x31\xc0\xc3',
                                           [('not defective', b'\xb8\x00\x00\x00\x00\xc3', {})], runner)

    def test_invalid_reference_does_not_count_as_a_detected_mutation(self):
        with self.assertRaisesRegex(diff.BehaviorMismatch, 'preserved register'):
            diff.require_mutations_detected('test', b'\x31\xff\xc3',
                                           [('anything', b'\xc3', {})],
                                           lambda body, _case: execute(body))

    def test_no_cases_cannot_pass(self):
        with self.assertRaisesRegex(ValueError, 'No behavioral cases'):
            diff.compare_cases('test', b'', b'', [], lambda body, case: None)

    def test_seeded_cases_are_repeatable_and_seed_sensitive(self):
        for generate in (actor_random, tile_random):
            self.assertEqual(list(generate(8, 123)), list(generate(8, 123)))
            self.assertNotEqual(list(generate(8, 123)), list(generate(8, 124)))
        self.assertTrue(any('overlapping' in case['name'] for case in tile_boundaries()))
        self.assertTrue(any('256' in case['name'] for case in actor_boundaries()))


if __name__ == '__main__':
    unittest.main()
