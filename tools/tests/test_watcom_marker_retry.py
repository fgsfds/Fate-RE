import unittest
from unittest.mock import patch

from compare_watcom_markers import FIXED_SHORT_BRANCHES, compare
from mark_watcom_aux import instrument
from test_match_objects import record


def object_with_code(code, additional_public=b''):
    blob = record(0x96, b'\x05_TEXT\x04CODE')
    blob += record(0x99, b'\x69' + len(code).to_bytes(4, 'little') + b'\x01\x02\x00')
    blob += record(0xa1, b'\x01\x00\x00\x00\x00' + code)
    return blob + record(0x91, b'\x00\x01\x04test\x00\x00\x00\x00\x00' + additional_public)


class MarkerRetryTests(unittest.TestCase):
    def test_instruction_bodies_get_distinct_end_markers(self):
        source = (
            '#pragma aux one = "inc eax" modify exact [eax];\n'
            '#pragma aux abi = "" parm [eax] modify exact [];\n'
            '#pragma aux two = "dec eax" modify exact [eax];\n'
        )
        marked, count = instrument(source, unique_ends=True)
        self.assertEqual(count, 2)
        self.assertIn('0xf1 "inc eax" 0xcd 0x81', marked)
        self.assertIn('0xf1 "dec eax" 0xcd 0x82', marked)
        self.assertIn('#pragma aux abi = "" parm [eax] modify exact [];', marked)

    def test_retry_counts_only_original_instruction_bytes(self):
        ordinary = object_with_code(b'\x90\x40\x48\xc3')
        merged = object_with_code(b'\x90\xf1\x40\xf1\x48\xf4\xc3')
        separate = object_with_code(b'\x90\xf1\x40\xcd\x81\xf1\x48\xcd\x82\xc3')
        with self.assertRaisesRegex(ValueError, 'Conflicting marker'):
            compare(ordinary, merged, 'test')
        self.assertEqual(compare(ordinary, separate, 'test'), (4, 2, [(1, 3)], [], 2))

    def test_tail_branch_to_public_entry_with_internal_control_flow(self):
        code = b'\x31\xc0\x74\x01\x40\xc3'
        public = b'\x07wrapper\x06\x00\x00\x00\x00'
        ordinary = object_with_code(code + b'\xeb\xf8', public)
        wrong_target = object_with_code(code + b'\xeb\xfa', public)
        self.assertEqual(compare(ordinary, ordinary, 'wrapper'), (2, 0, [], [], 0))
        with self.assertRaisesRegex(ValueError, 'Instruction changed'):
            compare(ordinary, wrong_target, 'wrapper')

    def test_fixed_external_short_branch_must_keep_the_original_encoding(self):
        ordinary = object_with_code(b'\xeb\x7f')
        marked = object_with_code(b'\xf1\xeb\x7f\xf4')
        wrong = object_with_code(b'\xf1\xeb\x7e\xf4')
        with patch.dict(FIXED_SHORT_BRANCHES, {'test': {0: b'\xeb\x7f'}}):
            self.assertEqual(compare(ordinary, marked, 'test'), (2, 2, [(0, 2)], [], 1))
            with self.assertRaisesRegex(ValueError, 'Instruction changed'):
                compare(ordinary, wrong, 'test')

    def test_markers_adjust_only_annotated_branches(self):
        source = '#pragma aux test = "db 7dh, 3eh" /* marker-rel8 +3 */ "db 7ch, 92h" modify exact [];'
        standard, _ = instrument(source)
        retry, _ = instrument(source, unique_ends=True)
        self.assertIn('"db 7dh, 44h" "db 7ch, 92h"', standard)
        self.assertIn('"db 7dh, 47h" "db 7ch, 92h"', retry)

    def test_marker_adjustment_rejects_out_of_range_jump(self):
        source = '#pragma aux test = "db 7dh, 7fh" /* marker-rel8 +1 */ modify exact [];'
        with self.assertRaisesRegex(ValueError, 'exceeds signed byte range'):
            instrument(source)

    def test_annotation_covers_short_jump_and_distinct_marker_counts(self):
        source = (
            '#pragma aux forward = "db 0ebh, 6eh" /* marker-rel8 +4 */ modify exact [];\n'
            '#pragma aux backward = "db 7dh, 8ah" /* marker-rel8 -4,-3 */ modify exact [];\n'
        )
        standard, count = instrument(source)
        retry, retry_count = instrument(source, unique_ends=True)
        self.assertEqual((count, retry_count), (2, 2))
        self.assertIn('"db 0ebh, 76h"', standard)
        self.assertIn('"db 7dh, 83h"', standard)
        self.assertIn('"db 0ebh, 7ah"', retry)
        self.assertIn('"db 7dh, 80h"', retry)

    def test_forward_unconditional_marker_jump_can_opt_in_to_widening(self):
        source = ('#pragma aux test = "db 0ebh, 72h" '
                  '/* marker-rel8 +9,+10 widen */ modify exact [];')
        standard, _ = instrument(source)
        retry, _ = instrument(source, unique_ends=True)
        self.assertIn('"db 0e9h, 085h, 000h, 000h, 000h"', standard)
        self.assertIn('"db 0e9h, 08fh, 000h, 000h, 000h"', retry)
        with self.assertRaisesRegex(ValueError, 'unconditional jump'):
            instrument(source.replace('0ebh', '74h'))
        with self.assertRaisesRegex(ValueError, 'exceeds signed byte range'):
            instrument(source.replace(' widen', ''))

    def test_backward_marker_jump_accounts_for_near_instruction_size(self):
        source = ('#pragma aux test = "db 0ebh, 8eh" '
                  '/* marker-rel8 -10,-9 widen */ modify exact [];')
        standard, _ = instrument(source)
        retry, _ = instrument(source, unique_ends=True)
        self.assertIn('"db 0e9h, 078h, 0ffh, 0ffh, 0ffh"', standard)
        self.assertIn('"db 0e9h, 06fh, 0ffh, 0ffh, 0ffh"', retry)
