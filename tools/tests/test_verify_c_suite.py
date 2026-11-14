import unittest
from test_match_objects import record
from verify_c_suite import verify_group_layout


def fixture(second=4, size=8):
    blob = record(0x96, b'\x05_TEXT\x04CODE')
    blob += record(0x99, b'\x69'+size.to_bytes(4, 'little')+b'\x01\x02\x00')
    blob += record(0xa1, b'\x01'+bytes(4)+bytes(size))
    blob += record(0x91, b'\x00\x01\x01a'+bytes(5)+b'\x01b'+second.to_bytes(4, 'little')+b'\x00')
    return blob


class CompilerGroups(unittest.TestCase):
    def test_exact_layout(self):
        verify_group_layout(fixture(), 8, [('a', 0), ('b', 4)])

    def test_reject_moved_public(self):
        with self.assertRaisesRegex(ValueError, 'public'):
            verify_group_layout(fixture(second=5), 8, [('a', 0), ('b', 4)])

    def test_reject_extra_tail(self):
        with self.assertRaisesRegex(ValueError, 'size'):
            verify_group_layout(fixture(size=9), 8, [('a', 0), ('b', 4)])

    def test_reject_extra_public(self):
        with self.assertRaisesRegex(ValueError, 'public'):
            verify_group_layout(fixture(), 8, [('a', 0)])

    def test_reject_embedded_data(self):
        blob = fixture()+record(0x99, b'\x69\x01\x00\x00\x00\x01\x01\x00')
        with self.assertRaisesRegex(ValueError, 'non-code'):
            verify_group_layout(blob, 8, [('a', 0), ('b', 4)])
