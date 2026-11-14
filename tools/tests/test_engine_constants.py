import unittest
from compare_engine_constants import strings, compare


class EngineConstants(unittest.TestCase):
    def test_string_offsets_and_terminators(self):
        self.assertEqual(strings(b'a\0\0bc\0'), [(0, b'a\0'), (2, b'\0'), (3, b'bc\0')])

    def test_unterminated(self):
        with self.assertRaises(ValueError):
            strings(b'a\0bc')

    def test_unknown_executable(self):
        with self.assertRaisesRegex(ValueError, 'Unknown FATE'):
            compare(b'not the target', b'')
