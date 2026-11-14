"""Single-unit storage regressions using synthetic OMF, never game payloads."""
import unittest

from test_match_objects import record
from test_verify_cache_layout import fixture as cache_fixture
from verify_cache_messages import MESSAGES
from verify_cache_unit import verify_unit_layout


def fixture(attribute=0xa9, name='CONST', message_gap=False, alias=False, **kwargs):
    blob = cache_fixture(**kwargs)
    blob += record(0x96, bytes([len(name)]) + name.encode())  # LNAMES index 9
    blob += record(0x99, bytes([attribute]) + (387).to_bytes(4, 'little') + b'\x09\x04\x00')
    offset = 0
    for symbol, size in MESSAGES.items():
        public_offset = 254 if alias and symbol == '_group_offsets_allocation_error' else offset
        blob += record(0x91, b'\x00\x04' + bytes([len(symbol)]) + symbol.encode()
                       + public_offset.to_bytes(4, 'little') + b'\x00')
        offset += size
    if message_gap:
        blob += record(0xa1, b'\x04' + (1).to_bytes(4, 'little') + bytes(386))
    else:
        blob += record(0xa1, b'\x04' + bytes(4) + bytes(387))
    return blob


class CacheUnit(unittest.TestCase):
    def test_complete_unit_layout(self):
        segments, publics, chosen = verify_unit_layout(fixture())
        self.assertEqual(len(publics), 42)
        self.assertEqual(chosen, {'CODE': 1, 'DATA': 2, 'BSS': 3, 'CONST': 4})
        self.assertEqual(len(segments[chosen['CONST']]['data']), 387)

    def test_missing_const_contribution(self):
        with self.assertRaisesRegex(ValueError, 'segment extent: CONST'):
            verify_unit_layout(cache_fixture())

    def test_wrong_const_alignment(self):
        with self.assertRaisesRegex(ValueError, 'CONST alignment'):
            verify_unit_layout(fixture(attribute=0x69))

    def test_wrong_const_name(self):
        with self.assertRaisesRegex(ValueError, 'segment extent: CONST'):
            verify_unit_layout(fixture(name='OTHER'))

    def test_const_initialization_gap(self):
        with self.assertRaisesRegex(ValueError, 'complete explicit LEDATA'):
            verify_unit_layout(fixture(message_gap=True))

    def test_aliased_identical_diagnostics(self):
        with self.assertRaisesRegex(ValueError, 'public inventory/offsets'):
            verify_unit_layout(fixture(alias=True))

    def test_collapsed_bss(self):
        with self.assertRaisesRegex(ValueError, 'segment extent: BSS'):
            verify_unit_layout(fixture(bss_size=32))

    def test_global_initialization_gap(self):
        with self.assertRaisesRegex(ValueError, 'complete explicit LEDATA'):
            verify_unit_layout(fixture(chunks=[(1, 280)]))


if __name__ == '__main__':
    unittest.main()
