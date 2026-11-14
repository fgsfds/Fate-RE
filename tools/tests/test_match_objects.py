import unittest
from match_objects import index, read_object, scan


def record(kind, payload):
    prefix = bytes([kind])+(len(payload)+1).to_bytes(2, 'little')+payload
    return prefix+bytes([-sum(prefix) & 255])


class ObjectMatching(unittest.TestCase):
    def fixture(self):
        code = bytes(range(32))
        blob = record(0x96, b'\x05_TEXT\x04CODE')
        blob += record(0x99, b'\x69'+len(code).to_bytes(4, 'little')+b'\x01\x02\x00')
        blob += record(0xa1, b'\x01\x00\x00\x00\x00'+code)
        blob += record(0x91, b'\x00\x01\x04test\x00\x00\x00\x00\x00')
        return blob, code

    def test_indices(self):
        self.assertEqual(index(b'\x81\x23', 0), (291, 2))

    def test_records_and_anchor(self):
        blob, code = self.fixture()
        segments, publics = read_object(blob)
        self.assertEqual(bytes(segments[1]['data']), code)
        self.assertEqual(publics, [(1, 0, 'test')])
        self.assertEqual(scan(blob, b'abcdef'+code)[0]['candidate_address'], '0x10006')

    def test_repeated_anchor_is_not_unique(self):
        blob, code = self.fixture()
        self.assertEqual(scan(blob, code+code), [])

    def test_truncation(self):
        blob, _ = self.fixture()
        with self.assertRaises(ValueError):
            read_object(blob[:-1])

    def test_bad_checksum(self):
        blob, _ = self.fixture()
        changed = bytearray(blob)
        changed[4] ^= 1
        with self.assertRaises(ValueError):
            read_object(changed)
