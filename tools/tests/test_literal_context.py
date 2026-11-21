"""Guard omitted compiler literals, fixup instruction fields and private tails."""
from hashlib import sha256
import unittest
from unittest.mock import patch
from test_match_objects import record
from verify_c_leaf import (LEAF_CONTEXT_LITERALS, LEAF_CONTEXT_SUFFIXES,
                           LEAF_CODE_SLICES, bind_leaf_details)

PAYLOAD = b'abcd'
SUFFIX = b'\x90'*4+b'\xc3'
BODY = b'\x90'*4+b'\xbe'+bytes(4)+b'\x90'+SUFFIX
INTERNAL = bytes.fromhex('e4 09 14 01 01')


def fixture(*, code=PAYLOAD+BODY, fixups=INTERNAL, public=4):
    blob = record(0x96, b'\x05_TEXT\x04CODE\x04FLAT')
    blob += record(0x99, b'\x69'+len(code).to_bytes(4,'little')+b'\x01\x02\x00')
    blob += record(0x9a, b'\x03')
    blob += record(0x8c, b'\x06global\x00')
    blob += record(0xa1, b'\x01'+bytes(4)+code)
    blob += record(0x91, b'\x00\x01\x04leaf'+public.to_bytes(4,'little')+b'\x00')
    return blob+record(0x9d, fixups)


class LiteralContext(unittest.TestCase):
    def bind(self, blob=None, *, symbol='view', address=0x2000d):
        with patch.dict(LEAF_CONTEXT_LITERALS,
                        {'leaf': (4, sha256(PAYLOAD).hexdigest(), {5: 0})}), \
             patch.dict(LEAF_CONTEXT_SUFFIXES, {'leaf': SUFFIX}), \
             patch.dict(LEAF_CODE_SLICES, {'view': ('leaf', 9, 10, len(BODY))}):
            codes = {}
            code, refs = bind_leaf_details(fixture() if blob is None else blob,
                                          symbol, {'global': 0x1000000},
                                          address=address, code_bindings=codes)
            return code, refs, codes

    def test_crops_literals_and_their_relocation_metadata(self):
        self.assertEqual(self.bind(), (b'\x90', {}, {}))

    def test_rejects_payload_public_and_literal_opcode_changes(self):
        for blob in (fixture(code=b'xbcd'+BODY), fixture(public=3),
                     fixture(code=PAYLOAD+BODY[:4]+b'\xbf'+BODY[5:])):
            with self.subTest(blob=blob), self.assertRaises(ValueError):
                self.bind(blob)

    def test_rejects_missing_extra_and_duplicate_internal_fixups(self):
        for fixups in (b'', INTERNAL*2, INTERNAL+bytes.fromhex('e4 0a 14 01 01')):
            with self.subTest(fixups=fixups), self.assertRaises(ValueError):
                self.bind(fixture(fixups=fixups))

    def test_rejects_changed_literal_target_addend_frame_and_kind(self):
        changed = bytearray(PAYLOAD+BODY); changed[9] = 1
        bad = [fixture(code=bytes(changed))]
        for fixups in ('e4 09 16 01 01', 'e4 09 14 01 02',
                       'a4 09 14 01 01', 'e4 09 14 02 01'):
            bad.append(fixture(fixups=bytes.fromhex(fixups)))
        for blob in bad:
            with self.subTest(blob=blob), self.assertRaises(ValueError):
                self.bind(blob)

    def test_rejects_fixups_in_omitted_prefix_and_pinned_suffix(self):
        for extra in ('e4 00 14 01 01', 'e4 0e 16 01 01'):
            with self.subTest(extra=extra), self.assertRaisesRegex(ValueError, 'prefix or context suffix'):
                self.bind(fixture(fixups=INTERNAL+bytes.fromhex(extra)))

    def test_rejects_literal_opcode_overlap_in_either_record_order(self):
        overlap = bytes.fromhex('e4 05 16 01 01')
        for fixups in (INTERNAL+overlap, overlap+INTERNAL):
            with self.subTest(fixups=fixups), self.assertRaisesRegex(ValueError, 'literal instruction'):
                self.bind(fixture(fixups=fixups))

    def test_rejects_linking_private_literal_operands_or_missing_placement(self):
        with self.assertRaisesRegex(ValueError, 'remain unlinked'):
            self.bind(symbol='leaf')
        with self.assertRaisesRegex(ValueError, 'loaded address'):
            self.bind(address=None)


class LiteralMarkerComparison(unittest.TestCase):
    def compare(self, ordinary, marked):
        from compare_watcom_markers import compare, decode
        from report_watcom_markers import placed_measurement
        from verify_c_leaf import LEAVES
        decode.cache_clear()
        with patch.dict(LEAF_CONTEXT_LITERALS,
                        {'leaf': (4, sha256(PAYLOAD).hexdigest(), {5: 0})}), \
             patch.dict(LEAF_CONTEXT_SUFFIXES, {'leaf': SUFFIX}), \
             patch.dict(LEAF_CODE_SLICES, {'view': ('leaf', 9, 10, len(BODY))}), \
             patch.dict(LEAVES, {'view': (0x4560d, 1)}):
            try:
                return placed_measurement('view', 1, compare(ordinary, marked, 'leaf'))
            finally:
                decode.cache_clear()

    def test_checked_literals_normalize_without_earning_table_credit(self):
        self.assertEqual(self.compare(fixture(), fixture()), (1, 0, [], [], 0))

    def test_marker_context_must_pass_the_same_literal_and_fixup_guards(self):
        for marked in (fixture(code=b'xbcd'+BODY),
                       fixture(fixups=bytes.fromhex('e4 09 16 01 01')),
                       fixture(fixups=INTERNAL+bytes.fromhex('e4 0e 16 01 01'))):
            with self.subTest(marked=marked), self.assertRaises(ValueError):
                self.compare(fixture(), marked)
