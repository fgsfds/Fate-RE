import unittest
import hashlib
from pathlib import Path
from unittest.mock import patch
import verify_assembly_suite as suite
from verify_assembly_suite import require_disjoint, verify_pointer_operands, c_coverage_ranges


class CoverageRanges(unittest.TestCase):
    def constant_inventory(self, c_spans=()):
        payload = bytes.fromhex('01000200')
        raw = 0x35600
        exe = bytes(raw)+payload
        target = hashlib.sha256(exe).hexdigest()
        with patch.multiple(suite, TARGET_SHA256=target, ROUTINES=[],
                NON_ROUTINE_UNITS=[('table', 'table.asm', 'table.bin', 0x10000, 4, {})]), \
                patch.object(Path, 'read_bytes', return_value=payload), \
                patch.object(suite, 'read_le_fixups', return_value={'pointers': {}}):
            return suite.verify(exe, Path('fixture'), dict(target_sha256=target, spans=list(c_spans)))

    def test_declared_code_table_is_not_a_routine(self):
        result = self.constant_inventory()
        self.assertEqual((result['routines'], result['unique_code_bytes']), (0, 4))
        self.assertEqual(result['spans'], [])
        self.assertEqual(len(result['non_routine_code_spans']), 1)
        self.assertNotIn('public_entry', result['non_routine_code_spans'][0])

    def test_declared_code_table_cannot_overlap_c(self):
        with self.assertRaisesRegex(ValueError, 'Overlapping'):
            self.constant_inventory([dict(raw_offset='0x35602', bytes=1)])

    def test_generated_table_prefix_participates_in_overlap_gate(self):
        inventory = dict(spans=[dict(raw_offset='0x20', bytes=8)],
                         non_routine_code_spans=[dict(raw_offset='0x10', bytes=16)])
        with self.assertRaisesRegex(ValueError, 'Overlapping'):
            require_disjoint(c_coverage_ranges(inventory)+[(0x18, 0x20)])

    def test_legacy_inventory_without_prefix(self):
        self.assertEqual(c_coverage_ranges(dict(spans=[dict(raw_offset='0x20', bytes=8)])),
                         [(0x20, 0x28)])

    def test_mixed_pointer_bases(self):
        verify_pointer_operands(bytes.fromhex('0400000008000000'),
                                {0: 0x10004, 4: 0x80008}, {4})

    def test_missing_data_classification(self):
        with self.assertRaisesRegex(ValueError, 'operand'):
            verify_pointer_operands(bytes(4), {0: 0x80000})

    def test_unbound_data_metadata(self):
        with self.assertRaisesRegex(ValueError, 'metadata'):
            verify_pointer_operands(bytes(4), {}, {0})

    def test_pointer_field_bounds(self):
        for offset in (-1, 1, 4):
            with self.subTest(offset=offset), self.assertRaisesRegex(ValueError, 'operand'):
                verify_pointer_operands(bytes(4), {offset: 0x10000})

    def test_adjacent_unsorted_ranges(self):
        require_disjoint([(20, 30), (10, 20), (40, 41)])

    def test_overlap_and_duplicate_rejected(self):
        for ranges in ([(10, 30), (20, 40)], [(10, 20), (10, 20)]):
            with self.subTest(ranges=ranges), self.assertRaisesRegex(ValueError, 'Overlapping'):
                require_disjoint(ranges)

    def test_invalid_ranges_rejected(self):
        for pair in ((-1, 1), (10, 10), (20, 10)):
            with self.subTest(pair=pair), self.assertRaisesRegex(ValueError, 'Invalid'):
                require_disjoint([pair])
