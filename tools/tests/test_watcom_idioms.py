from contextlib import ExitStack, redirect_stdout
from copy import deepcopy
from hashlib import sha256
from io import StringIO
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import check_watcom_idioms as idioms
from differential import Contract, Machine
from test_match_objects import record
from test_watcom_marker_retry import object_with_code
from cache_contract import CompilerCacheContract

BASE, STOP, STACK, DATA = 0x10000, 0x3ff000, 0x3f0000, 0x300000


class IdiomSemantics(unittest.TestCase):
    def test_checked_in_inputs_and_variants_are_current(self):
        expected = json.loads(idioms.EXPECTED.read_text())
        self.assertEqual(expected['source_sha256'], idioms.digest(idioms.SOURCE))
        self.assertEqual(expected['flags'], idioms.VARIANTS)

    def test_snapshots_cover_register_widths_packing_clobbers_and_aborting_tail(self):
        expected = json.loads(idioms.EXPECTED.read_text())
        cases = (
            ('register_increment_', 0x7fffffff, 0, None, 0x80000000),
            ('signed_word_', 0xbeef8000, 0, None, 0xffff8000),
            ('signed_word_', 0x12347fff, 0, None, 0x7fff),
            ('unsigned_word_', 0xdeadbeef, 0, None, 0xbeef),
            ('low_byte_', 0x12345680, 0, None, 0x80),
            ('packed_value_', DATA, 0, b'\xaa\xef\xcd\xab\x89', 0x89abcdef),
            ('less_than_memory_', 0xfffffff6, DATA, b'\xf7\xff\xff\xff', 1),
            ('less_than_memory_', 9, DATA, b'\xf7\xff\xff\xff', 0),
            ('keep_edx_', 7, 5, None, 19),
            ('aborting_wrapper_', 7, 0, None, 7),
            ('rotate_idiom_', 0x12345678, 0, None, 0x34567812),
        )
        for variant, observation in expected['variants'].items():
            code = bytearray.fromhex(observation['segments'][0]['bytes'])
            for fixup in observation['fixups']:
                offset = fixup['offset']
                target = {1: 0x20000, 2: 0x20010}[fixup['target'][1]]
                code[offset:offset+4] = ((target - (BASE + offset + 4)) & 0xffffffff).to_bytes(4, 'little')
            publics = {name: offset for _, offset, name in observation['publics']}
            for symbol, eax, edx, memory, result in cases:
                with self.subTest(variant=variant, symbol=symbol, eax=eax):
                    contract = Contract(BASE + publics[symbol], STOP, STACK, 4,
                                        preserved=('ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp'),
                                        results=('eax',))
                    machine = Machine(contract, bytes(code), code_address=BASE)
                    machine.stub(0x20000, lambda cpu: {'eax': cpu.register('eax') * 2})
                    machine.stub(0x20010, lambda cpu: cpu.record('terminal', cpu.register('esp')))
                    if memory:
                        machine.write(DATA, memory)
                    actual = machine.run(dict(eax=eax, edx=edx, ebx=11, ecx=13, esi=17, edi=19, ebp=23))
                    self.assertEqual(actual.registers['eax'], result)
                    if symbol == 'aborting_wrapper_':
                        self.assertEqual(actual.calls, (('terminal', STACK),))

    def test_volatile_omf_comments_do_not_change_snapshot(self):
        original = object_with_code(b'\x40\xc3')
        comment = record(0x88, b'\x00\x00volatile timestamp')
        self.assertEqual(idioms.snapshot(original), idioms.snapshot(comment + original))

    def test_snapshot_checks_code_layout_and_fixup_metadata(self):
        original = idioms.snapshot(object_with_code(b'\x40\xc3'))
        for field in ('code', 'public', 'fixup'):
            changed = deepcopy(original)
            if field == 'code':
                changed['segments'][0]['bytes'] = '48c3'
            elif field == 'public':
                changed['publics'][0][1] = 1
            else:
                changed['fixups'].append({'offset': 1})
            with self.subTest(field=field), self.assertRaises(ValueError):
                idioms.verify_snapshot('test', changed, original)


class IdiomCache(CompilerCacheContract, unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        tools = self.root / 'tools'
        compiler = tools / 'inputs/watcom/binw'
        compiler.mkdir(parents=True)
        for name in ('wcc386.exe', 'w32run.exe'):
            (compiler / name).write_bytes(b'pinned tools')
        (tools / 'restoration_build.py').write_text('driver version')
        self.source = tools / 'idioms.c'
        self.source.write_text('int test(void) { return 0; }\n')
        self.obj = object_with_code(b'\x31\xc0\xc3')
        self.expected = tools / 'expected.json'
        self.identity = {'wcc386.exe': 'compiler', 'w32run.exe': 'runner', 'DOSBox.exe': 'dosbox'}
        self.expected.write_text(json.dumps(dict(
            schema=1, source_sha256=sha256(self.source.read_bytes()).hexdigest(),
            compiler_sha256='compiler', flags=idioms.VARIANTS,
            variants={name: idioms.snapshot(self.obj) for name in idioms.VARIANTS})))
        self.build = self.root / 'work/idioms'
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        for name, value in (('ROOT', self.root), ('TOOLS', tools),
                            ('SOURCE', self.source), ('EXPECTED', self.expected)):
            self.stack.enter_context(patch.object(idioms, name, value))
        self.stack.enter_context(patch.object(idioms, 'tool_identity', return_value=self.identity))
        self.compiler = self.stack.enter_context(
            patch.object(idioms, 'run_compiler_batch', side_effect=self.compile))
        self.stack.enter_context(redirect_stdout(StringIO()))

    def compile(self, build, units, _dosbox):
        for unit in units:
            (build / (unit.name + '.obj')).write_bytes(self.obj)
            (build / (unit.name + '.log')).write_text('2 lines, 0 warnings, 0 errors\n')

    def cache_build(self, *, clean):
        return idioms.check(self.build, clean=clean)['compiled']

    def cache_fail(self):
        self.compiler.side_effect = ValueError('failed compile')

    def cache_assert_invalid(self):
        self.assertEqual(json.loads((self.build / 'idiom-provenance.json').read_text()), {})
        self.assertEqual(json.loads((self.build / 'report.json').read_text())['status'], 'pending')

    def test_reuse_rechecks_snapshot_and_never_qualifies_game_coverage(self):
        self.assertEqual(idioms.check(self.build)['compiled'], 3)
        result = idioms.check(self.build)
        self.assertEqual(result['compiled'], 0)
        self.assertEqual(result['reused'], 3)
        self.assertFalse(result['inventory_eligible'])
        self.assertEqual(self.compiler.call_count, 1)
        expected = json.loads(self.expected.read_text())
        expected['variants']['id4']['segments'][0]['bytes'] = '48c3'
        self.expected.write_text(json.dumps(expected))
        with self.assertRaises(ValueError):
            idioms.check(self.build)
        self.assertEqual(json.loads((self.build / 'report.json').read_text())['status'], 'pending')

    def test_changed_object_recompiles_only_affected_probe(self):
        idioms.check(self.build)
        (self.build / 'id3.obj').write_bytes(b'corrupted')
        self.assertEqual(idioms.check(self.build)['compiled'], 1)

    def test_source_change_requires_explicit_review_not_automatic_acceptance(self):
        idioms.check(self.build)
        self.source.write_text('changed source')
        with self.assertRaisesRegex(ValueError, 'inputs changed'):
            idioms.check(self.build)
        before = self.expected.read_bytes()
        result = idioms.check(self.build, observe=True)
        self.assertEqual(result['status'], 'observed')
        self.assertEqual(self.expected.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
