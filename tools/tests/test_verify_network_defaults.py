import unittest
from unittest.mock import patch
from verify_network_defaults import SCALARS, verify_object


class NetworkDefaultsTests(unittest.TestCase):
    def check(self, *, extra=False, moved=False, gap=False, fixup=False, cls='DATA'):
        segments=[None,dict(name='_DATA',cls=cls,data=bytes(10))]
        if extra:segments.append(dict(name='_BSS',cls='BSS',data=bytes(1)))
        publics=[(1,o+(1 if moved and n=='_socket' else 0),n) for n,o,z,a in SCALARS]
        sites=set(range(10))
        if gap:sites.remove(4)
        with patch('verify_network_defaults.read_object',return_value=(segments,publics)), \
             patch('verify_network_defaults.layout',return_value=({1:sites},[])), \
             patch('verify_network_defaults.read_fixups',return_value=[object()] if fixup else []):
            return verify_object(b'synthetic')

    def test_valid(self):self.assertEqual(len(self.check()),10)
    def test_moved_public(self):
        with self.assertRaises(ValueError):self.check(moved=True)
    def test_extra_extent(self):
        with self.assertRaises(ValueError):self.check(extra=True)
    def test_missing_initialized_byte(self):
        with self.assertRaises(ValueError):self.check(gap=True)
    def test_fixup_rejected(self):
        with self.assertRaises(ValueError):self.check(fixup=True)
    def test_wrong_class(self):
        with self.assertRaises(ValueError):self.check(cls='BSS')


if __name__=='__main__':unittest.main()
