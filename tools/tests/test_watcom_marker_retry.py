import unittest
from unittest.mock import patch

from compare_watcom_markers import FIXED_SHORT_BRANCHES, JumpTable, compare, decode
from mark_watcom_aux import instrument
from test_match_objects import record


def object_with_code(code, additional_public=b''):
    blob = record(0x96, b'\x05_TEXT\x04CODE')
    blob += record(0x99, b'\x69' + len(code).to_bytes(4, 'little') + b'\x01\x02\x00')
    blob += record(0xa1, b'\x01\x00\x00\x00\x00' + code)
    return blob + record(0x91, b'\x00\x01\x04test\x00\x00\x00\x00\x00' + additional_public)


def shared_call_object(marked=False, *, callee=b'callee', relocated=True, addend=0, flat=True,
                       terminal_return=True, indirect=b''):
    prefix = b'\xf1\x90\xf4' if marked else b'\x90'
    body = prefix + b'\xe8' + addend.to_bytes(4, 'little') + b'\x89\xc3'
    body += indirect + (b'\xc3' if terminal_return else b'\x90')
    # Wrapper tail enters the earlier CALL, not its public.
    code = body + bytes((0xeb, (len(prefix)-len(body)-2)&255))
    blob = record(0x96, b'\x05_TEXT\x04CODE\x04' + (b'FLAT' if flat else b'FALT'))
    blob += record(0x99, b'\x69' + len(code).to_bytes(4, 'little') + b'\x01\x02\x00')
    blob += record(0x9a, b'\x03')
    blob += record(0x8c, bytes((len(callee),)) + callee + b'\x00')
    blob += record(0xa1, b'\x01' + bytes(4) + code)
    public = b'\x07wrapper' + len(body).to_bytes(4, 'little') + b'\x00'
    blob += record(0x91, b'\x00\x01\x04test' + bytes(5) + public)
    if relocated:
        blob += record(0x9d, bytes((0xa4, len(prefix)+1, 0x16, 1, 1)))
    return blob


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

    def test_shared_tail_external_call_survives_marker_shift_before_target(self):
        ordinary = shared_call_object()
        self.assertEqual(compare(ordinary, ordinary, 'wrapper'), (2, 0, [], [], 0))
        self.assertEqual(compare(ordinary, shared_call_object(True), 'wrapper'), (2, 0, [], [], 0))

    def test_shared_tail_rejects_changed_external_callee(self):
        with self.assertRaisesRegex(ValueError, 'Instruction changed'):
            compare(shared_call_object(), shared_call_object(True, callee=b'other'), 'wrapper')

    def test_shared_tail_rejects_changed_external_addend(self):
        with self.assertRaisesRegex(ValueError, 'Instruction changed'):
            compare(shared_call_object(), shared_call_object(True, addend=1), 'wrapper')

    def test_shared_tail_rejects_unrelocated_call_even_when_bytes_match(self):
        ordinary = shared_call_object(relocated=False)
        with self.assertRaisesRegex(ValueError, 'Instruction changed'):
            compare(ordinary, ordinary, 'wrapper')

    def test_shared_tail_rejects_call_without_verified_flat_frame(self):
        ordinary = shared_call_object(flat=False)
        with self.assertRaisesRegex(ValueError, 'Instruction changed'):
            compare(ordinary, ordinary, 'wrapper')

    def test_shared_tail_external_call_rejects_unchecked_fallthrough(self):
        ordinary = shared_call_object(terminal_return=False)
        with self.assertRaisesRegex(ValueError, 'Instruction changed'):
            compare(ordinary, shared_call_object(True, terminal_return=False), 'wrapper')

    def test_shared_tail_external_call_rejects_indirect_transfers(self):
        for transfer in (b'\xff\xe0', b'\xff\xd0'):
            with self.subTest(transfer=transfer.hex()), self.assertRaisesRegex(ValueError, 'Instruction changed'):
                ordinary = shared_call_object(indirect=transfer)
                compare(ordinary, shared_call_object(True, indirect=transfer), 'wrapper')

    def test_shared_tail_external_call_rejects_unverified_relative_loops(self):
        # Identical LOOP displacement reaches offset 0 in the ordinary owner,
        # but offset 2 (the end marker) after marker insertion in the other.
        for opcode in (0xe0, 0xe1, 0xe2):  # LOOPNE, LOOPE, LOOP
            transfer = bytes((opcode, 0xf6))
            ordinary = shared_call_object(indirect=transfer)
            marked = shared_call_object(True, indirect=transfer)
            with self.subTest(opcode=opcode), self.assertRaisesRegex(ValueError, 'Instruction changed'):
                compare(ordinary, marked, 'wrapper')

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


class SwitchAlignmentTests(unittest.TestCase):
    def decode_before_table(self, body):
        offset = len(body)
        public = b'\x04next' + (offset + 4).to_bytes(4, 'little') + b'\x00'
        blob = object_with_code(body + bytes(4) + b'\xc3', public)
        return decode(blob, 'test', False, (JumpTable(1, offset, 0, (offset + 4,)),))

    def test_observed_two_byte_watcom_alignment_is_not_tail_code(self):
        span = self.decode_before_table(b'\xc3\x90\x8b\xc0')
        self.assertEqual([bytes(ins.bytes) for ins in span.instructions], [b'\xc3'])
        self.assertEqual(span.positions, {0: 0, 1: 1})

    def test_alignment_requires_return_and_at_most_three_bytes(self):
        for body in (b'\x40\x90\x8b\xc0', b'\xc3\x8b\xc0\x8b\xc0',
                     b'\xc3\x90\x31\xc0'):
            with self.subTest(body=body), self.assertRaisesRegex(ValueError, 'alignment'):
                self.decode_before_table(body)
