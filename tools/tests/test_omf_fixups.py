import unittest
from omf_fixups import decode, read_fixups, read_externals
from test_match_objects import record


class Fixups(unittest.TestCase):
    def test_external_indices(self):
        blob = record(0x8c, b'\x03one\x00') + record(0xb4, b'\x03two\x81\x01')
        self.assertEqual(read_externals(blob), [None, 'one', 'two'])

    def test_truncated_external_name(self):
        with self.assertRaisesRegex(ValueError, 'Truncated OMF name'):
            read_externals(record(0x8c, b'\x05abc'))

    def test_unsupported_external_index_record(self):
        with self.assertRaisesRegex(ValueError, 'external-index'):
            read_externals(record(0xb0, b''))

    def test_explicit_32(self):
        fix, = decode(bytes.fromhex('e4 04 10 01 02 78563412'), True, (1, 100, 8), {})
        self.assertEqual((fix.offset, fix.width, fix.frame, fix.target,
                          fix.displacement, fix.relative),
                         (104, 4, (1, 1), (0, 2), 0x12345678, False))

    def test_threads_across_records(self):
        blob = record(0xa1, b'\x01'+bytes(12))
        blob += record(0x9d, bytes.fromhex('44 01 08 8101'))
        blob += record(0x9d, bytes.fromhex('a4 00 8c'))
        fix, = read_fixups(blob)
        self.assertEqual((fix.frame, fix.target, fix.relative), ((1, 1), (2, 257), True))

    def test_16_bit_displacement(self):
        fix, = decode(bytes.fromhex('c4 00 50 01 3412'), False, (1, 0, 2), {})
        self.assertEqual((fix.width, fix.displacement), (2, 0x1234))

    def test_undefined_thread(self):
        with self.assertRaisesRegex(ValueError, 'Undefined'):
            decode(bytes.fromhex('e4 00 8c'), True, (1, 0, 4), {})

    def test_bounds(self):
        with self.assertRaisesRegex(ValueError, 'exceeds'):
            decode(bytes.fromhex('e4 01 54 01'), True, (1, 0, 4), {})

    def test_truncated_fields(self):
        data = bytes.fromhex('e4 00 10 01 02 78563412')
        for end in range(1, len(data)):
            with self.subTest(end=end), self.assertRaises(ValueError):
                decode(data[:end], True, (1, 0, 4), {})

    def test_no_data(self):
        with self.assertRaisesRegex(ValueError, 'without LEDATA'):
            decode(bytes.fromhex('e4 00 54 01'), True, None, {})

    def test_bad_checksum(self):
        blob = bytearray(record(0x9d, bytes.fromhex('44 01')))
        blob[-1] ^= 1
        with self.assertRaisesRegex(ValueError, 'checksum'):
            read_fixups(blob)
