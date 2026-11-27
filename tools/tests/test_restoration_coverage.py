"""Synthetic renderer tests; real inventory/document drift is checked by CI."""
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from compare_exe import TARGET_SHA256
from restoration_coverage import START, END, coverage_text, update_document


class CoverageRendering(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        for name, values in (
                ('matching-routines', dict(routines=1234, unique_code_bytes=100000)),
                ('matching-assembly', dict(unique_code_bytes=314639)),
                ('matching-initialized', dict(initialized_data_bytes=2345)),
                ('matching-graphics-font-dependency', dict(dependency_data_bytes=6789))):
            self.write(name, **values)

    def write(self, name, **values):
        (self.directory / (name + '.json')).write_text(
            json.dumps(dict(target_sha256=TARGET_SHA256, **values)), encoding='utf-8')

    def test_renders_independent_inventories_and_mixed_code_caveat(self):
        text = coverage_text(self.directory)
        for expected in ('1,234 routines', '100,000 bytes', '24.12%', '314,639 bytes',
                         '75.88%', '2,345 stored bytes', '6,789 stored bytes',
                         'mixed C/inline-assembly'):
            self.assertIn(expected, text)
        self.assertTrue(text.startswith(START))
        self.assertTrue(text.endswith(END))

    def test_wrong_target_in_any_inventory_is_rejected(self):
        for path in sorted(self.directory.glob('*.json')):
            with self.subTest(inventory=path.stem):
                original = path.read_text()
                payload = json.loads(original)
                payload['target_sha256'] = 'unverified'
                path.write_text(json.dumps(payload))
                with self.assertRaisesRegex(ValueError, 'Coverage target differs'):
                    coverage_text(self.directory)
                path.write_text(original)

    def test_missing_code_bytes_cannot_disappear_from_the_denominator(self):
        self.write('matching-assembly', unique_code_bytes=314638)
        with self.assertRaisesRegex(ValueError, 'CODE coverage total differs'):
            coverage_text(self.directory)

    def test_replacement_preserves_handwritten_sections_and_is_idempotent(self):
        text = 'Introduction\n' + START + '\nold\n' + END + '\nNotes\n'
        generated = coverage_text(self.directory)
        result = update_document(text, generated)
        self.assertEqual(result, 'Introduction\n' + generated + '\nNotes\n')
        self.assertEqual(update_document(result, generated), result)

    def test_missing_duplicate_or_reversed_markers_are_rejected(self):
        for text in ('no block', START, END, START + START + END,
                     START + END + END, END + START):
            with self.subTest(text=text), self.assertRaises(ValueError):
                update_document(text, 'replacement')


if __name__ == '__main__':
    unittest.main()
