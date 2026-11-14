import hashlib
import struct
import unittest
from unittest.mock import patch
from le_fixups import read_le_fixups


def fixture(records):
    blob = bytearray(0x400)
    struct.pack_into('<I', blob, 60, 0x40)
    blob[0x40:0x42] = b'LE'
    for offset, value in {0x14: 1, 0x28: 4096, 0x40: 0xb0,
                          0x44: 1, 0x68: 0x180, 0x6c: 0x200}.items():
        struct.pack_into('<I', blob, 0x40+offset, value)
    struct.pack_into('<6I', blob, 0xf0, 4096, 0x10000, 0, 1, 1, 0)
    struct.pack_into('<II', blob, 0x1c0, 0, len(records))
    blob[0x240:0x240+len(records)] = records
    return bytes(blob)


def parse_fixture(blob):
    with patch('le_fixups.TARGET_SHA256', hashlib.sha256(blob).hexdigest()):
        return read_le_fixups(blob)


class LeFixups(unittest.TestCase):
    def test_widths_and_duplicate(self):
        a = struct.pack('<BBhBH', 7, 0, 12, 1, 100)
        b = struct.pack('<BBhBI', 7, 16, 16, 1, 200)
        result = parse_fixture(fixture(a+b+a))
        self.assertEqual(result, dict(record_count=3,
                         pointers={0x1000c: 0x10064, 0x10010: 0x100c8}))

    def test_conflict(self):
        records = b''.join(struct.pack('<BBhBH', 7, 0, 12, 1, t) for t in (100, 101))
        with self.assertRaisesRegex(ValueError, 'Conflicting'):
            parse_fixture(fixture(records))

    def test_bad_target(self):
        with self.assertRaisesRegex(ValueError, 'target outside'):
            parse_fixture(fixture(struct.pack('<BBhBH', 7, 0, 12, 1, 4096)))

    def test_bad_source(self):
        with self.assertRaisesRegex(ValueError, 'source outside'):
            parse_fixture(fixture(struct.pack('<BBhBH', 7, 0, -1, 1, 10)))

    def test_truncated_record(self):
        with self.assertRaisesRegex(ValueError, 'Invalid LE fixup target'):
            parse_fixture(fixture(struct.pack('<BBhB', 7, 16, 12, 1)))

    def test_hash_guard(self):
        with self.assertRaisesRegex(ValueError, 'Unknown'):
            read_le_fixups(bytes(100))
