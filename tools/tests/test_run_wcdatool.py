import struct
import unittest
from run_wcdatool import verify_metadata


def fixture():
    blob = bytearray(528)
    struct.pack_into('<I', blob, 60, 0x80)
    pairs = {'# module pages': (0x14, 1), 'object # for initial eip': (0x18, 1),
             'initial eip': (0x1c, 0), 'object # for initial esp': (0x20, 1),
             'initial esp': (0x24, 32), 'page size': (0x28, 4096),
             'last page size (le)/page shift (lx)': (0x2c, 16),
             '# of objects in module': (0x44, 1), 'object page map offset': (0x48, 0xf0),
             'offset of enumerated data pages': (0x80, 512),
             'offset of the debugging information': (0x98, 0),
             'size of the debugging information': (0x9c, 0)}
    for offset, value in pairs.values():
        struct.pack_into('<I', blob, 0x80+offset, value)
    struct.pack_into('<I', blob, 0x80+0x40, 0xb0)
    struct.pack_into('<6I', blob, 0x130, 32, 0x10000, 0x2005, 1, 1, 0)
    blob[0x170:0x174] = bytes.fromhex('00 00 01 00')
    blob[512:] = bytes(range(16))
    data = {name: value for name, (_, value) in pairs.items()}
    data['file offset'] = 0x80
    obj = {'virtual memory size': 32, 'relocation base address': 0x10000,
           'object flag bits': 0x2005, 'object page table index': 1,
           '# of object page table entries': 1, 'reserved': 0,
           'pages': {1: {'map page': 1, 'flags': 0, 'file offset': 512, 'valid': True,
                         'segments': {1: {'data': bytes(range(16))}}}}}
    return bytes(blob), {'linear exe header (os/2 v2.x) - le': {'data': data},
                         'object table': {'data': {1: obj}}}


class WdumpMetadata(unittest.TestCase):
    def test_agreement(self):
        blob, metadata = fixture()
        result = verify_metadata(blob, metadata)
        self.assertEqual(result['pages_checked'], 1)
        self.assertTrue(result['page_bytes_equal'])

    def test_wrong_header(self):
        blob, metadata = fixture()
        metadata['linear exe header (os/2 v2.x) - le']['data']['initial eip'] = 1
        with self.assertRaises(AssertionError):
            verify_metadata(blob, metadata)

    def test_wrong_page_bytes(self):
        blob, metadata = fixture()
        metadata['object table']['data'][1]['pages'][1]['segments'][1]['data'] = bytes(16)
        with self.assertRaises(AssertionError):
            verify_metadata(blob, metadata)

    def test_wrong_physical_page(self):
        blob, metadata = fixture()
        metadata['object table']['data'][1]['pages'][1]['map page'] = 2
        with self.assertRaises(AssertionError):
            verify_metadata(blob, metadata)
