"""Synthetic negative controls for startup provenance and payload research."""
import hashlib
import unittest
from unittest.mock import patch
from research_startup import layout, provenance


def record(kind, data):
    return bytes([kind])+(len(data)+1).to_bytes(2,'little')+data+b'\0'


class StartupResearchTests(unittest.TestCase):
    def test_unique_pinned_member(self):
        archive=b'prefix member suffix'
        with patch.dict('research_startup.LIBRARIES',{'test':hashlib.sha256(archive).hexdigest()}):
            self.assertEqual(provenance(archive,b'member','test')['archive_member_offset'],'0x7')
            with self.assertRaises(ValueError): provenance(archive,b'absent','test')
            with self.assertRaises(ValueError): provenance(archive,b'','test')

    def test_repeated_member(self):
        archive=b'member member'
        with patch.dict('research_startup.LIBRARIES',{'test':hashlib.sha256(archive).hexdigest()}):
            with self.assertRaises(ValueError): provenance(archive,b'member','test')

    def test_unpinned_archive(self):
        with self.assertRaises(ValueError): provenance(b'bad',b'bad','105')

    def test_initialized_extent_not_reservation(self):
        blob=record(0xa1,b'\x01'+(3).to_bytes(4,'little')+b'ab')
        self.assertEqual(layout(blob),({1:{3,4}},[]))

    def test_overlapping_extents(self):
        blob=record(0xa1,b'\x01'+bytes(4)+b'ab')
        with self.assertRaises(ValueError): layout(blob+blob)

    def test_unsupported_iterated_payload(self):
        with self.assertRaises(ValueError): layout(record(0xa3,b''))

    def test_truncated_record(self):
        with self.assertRaises(ValueError): layout(b'\xa1\xff\x00')


if __name__ == '__main__':
    unittest.main()
