import unittest

from test_match_objects import record
from verify_cache_const import verify_const_layout


def fixture(name='CONST', attribute=0xa9, size=387):
    names = bytes([len(name)]) + name.encode() + b'\x04DATA'
    return (record(0x96, names)
            + record(0x99, bytes([attribute]) + size.to_bytes(4, 'little') + b'\x01\x02\x00')
            + record(0xa1, b'\x01' + bytes(4) + bytes(size)))


class CacheConst(unittest.TestCase):
    def test_valid_historical_attributes(self):
        self.assertEqual(verify_const_layout(fixture())['segment_attribute'], '0xa9')

    def test_wrong_segment_name(self):
        with self.assertRaisesRegex(ValueError, 'CONST/DATA'):
            verify_const_layout(fixture(name='_DATA'))

    def test_wrong_alignment(self):
        with self.assertRaisesRegex(ValueError, 'DWORD-aligned'):
            verify_const_layout(fixture(attribute=0x69))

    def test_wrong_extent(self):
        with self.assertRaisesRegex(ValueError, 'CONST/DATA'):
            verify_const_layout(fixture(size=388))


if __name__ == '__main__':
    unittest.main()
