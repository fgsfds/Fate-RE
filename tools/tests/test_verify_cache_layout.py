"""Real synthetic OMF records for cache storage-layout regressions."""
import unittest

from test_match_objects import record
from verify_cache_layout import BSS, DATA, PUBLICS, SIZE, verify_layout


def fixture(bss_size=49424, moved_public=False, chunks=None,
            bss_payload=False, extra_extent=False, lidata=False):
    names = ('_TEXT', 'CODE', '_DATA', 'DATA', '_BSS', 'BSS', 'OTHER', 'OTHERCLASS')
    blob = record(0x96, b''.join(bytes([len(name)]) + name.encode() for name in names))
    for size, name, cls in [(SIZE, 1, 2), (281, 3, 4), (bss_size, 5, 6)]:
        blob += record(0x99, b'\x69' + size.to_bytes(4, 'little') + bytes([name, cls, 0]))
    if extra_extent:
        blob += record(0x99, b'\x69\x01\x00\x00\x00\x07\x08\x00')
    publics = [(1, offset, name) for name, offset in PUBLICS]
    publics += [(2, offset, name) for name, offset, _ in DATA]
    publics += [(3, offset, name) for name, offset, _ in BSS]
    for segment, offset, name in publics:
        if moved_public and name == '_filepos':
            offset = 49152  # Observed standalone-definition ordering mismatch.
        blob += record(0x91, bytes([0, segment, len(name)]) + name.encode()
                       + offset.to_bytes(4, 'little') + b'\0')
    # Invented zeros are enough for layout checks; no original code is embedded.
    blob += record(0xa1, b'\x01' + bytes(4) + bytes(SIZE))
    for offset, size in ([(0, 281)] if chunks is None else chunks):
        blob += record(0xa1, b'\x02' + offset.to_bytes(4, 'little') + bytes(size))
    if bss_payload:
        blob += record(0xa1, b'\x03' + bytes(5))
    if lidata:
        blob += record(0xa3, b'\x03' + bytes(4))
    return blob


class CacheLayout(unittest.TestCase):
    def test_valid_layout(self):
        segments, publics, chosen = verify_layout(fixture())
        self.assertEqual(chosen, {'CODE': 1, 'DATA': 2, 'BSS': 3})
        self.assertEqual(len(segments[chosen['BSS']]['data']), 49424)
        self.assertEqual(len(publics), 27)

    def test_valid_split_initialized_records(self):
        verify_layout(fixture(chunks=[(0, 21), (21, 4), (25, 256)]))

    def test_reject_wrong_include_order_collapsed_bss(self):
        with self.assertRaisesRegex(ValueError, 'segment extent: BSS'):
            verify_layout(fixture(bss_size=32))

    def test_reject_moved_public(self):
        with self.assertRaisesRegex(ValueError, 'public inventory/offsets'):
            verify_layout(fixture(moved_public=True))

    def test_reject_initialized_gap_even_when_missing_bytes_are_zero(self):
        with self.assertRaisesRegex(ValueError, 'complete explicit LEDATA'):
            verify_layout(fixture(chunks=[(0, 4), (5, 276)]))

    def test_reject_overlapping_initialized_records(self):
        with self.assertRaisesRegex(ValueError, 'Overlapping initialized global records'):
            verify_layout(fixture(chunks=[(0, 25), (21, 260)]))

    def test_reject_bss_ledata_even_when_zero(self):
        with self.assertRaisesRegex(ValueError, 'BSS unexpectedly has initialized LEDATA'):
            verify_layout(fixture(bss_payload=True))

    def test_reject_extra_segment_extent_without_ledata(self):
        with self.assertRaisesRegex(ValueError, 'Unexpected extra segment payload'):
            verify_layout(fixture(extra_extent=True))

    def test_reject_unsupported_lidata(self):
        with self.assertRaisesRegex(ValueError, 'LIDATA not supported'):
            verify_layout(fixture(lidata=True))


if __name__ == '__main__':
    unittest.main()
