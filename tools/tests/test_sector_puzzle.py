"""Reject extra phase edges and instruction-splitting puzzle cuts."""
import unittest
from check_sector_puzzle import BRANCHES, SIZE, verify_phase_edges


def fixture():
    code = bytearray(b'\x90' * SIZE)
    for site, target in BRANCHES:
        opcode = b'\x0f\x85' if site < 0x170 else b'\x75'
        width = 4 if len(opcode) == 2 else 1
        end = site + len(opcode) + width
        code[site:end] = opcode + (target-end).to_bytes(width, 'little', signed=True)
    return code


class SectorPuzzleEdges(unittest.TestCase):
    def test_accepts_the_five_expected_edges(self):
        verify_phase_edges(fixture())

    def test_rejects_an_unregistered_cross_phase_edge(self):
        code = fixture()
        code[0x20:0x25] = b'\xe9' + (0x1da-0x25).to_bytes(4, 'little')
        with self.assertRaisesRegex(ValueError, 'cross-phase'):
            verify_phase_edges(code)

    def test_rejects_a_cut_inside_an_instruction(self):
        code = fixture()
        code[0x197:0x19c] = b'\xb8\x00\x00\x00\x00'
        with self.assertRaisesRegex(ValueError, 'boundary'):
            verify_phase_edges(code)
