"""Structural regressions independent of local saved build artifacts."""
import unittest
from check_encounter_exit import (ENTRY, SIZE, EPILOGUE, validate_epilogue,
                                  validate_phase_edges)


def phase():
    code = bytearray(b'\x90'*SIZE+EPILOGUE)
    for address in (0x1e354,0x1e364,0x1e3a5,0x1e3b0,0x1e3b8,0x1e3ee):
        opcode = b'\x0f\x84' if address < 0x1e370 else b'\x74'
        width = 4 if len(opcode) == 2 else 1
        site = address-ENTRY
        end = site+len(opcode)+width
        code[site:end] = opcode+(SIZE-end).to_bytes(width,'little',signed=True)
    for address,target in ((0x1e3bf,0x14897),(0x1e3e2,0x10433),(0x1e3fe,0x50a09)):
        site=address-ENTRY
        code[site:site+5]=b'\xe8'+(target-address-5).to_bytes(4,'little',signed=True)
    return code


class EncounterExitGuards(unittest.TestCase):
    def test_pinned_epilogue_rejects_a_changed_save_sequence(self):
        validate_epilogue(EPILOGUE)
        with self.assertRaisesRegex(ValueError,'epilogue hash'):
            validate_epilogue(EPILOGUE[:-2]+b'\x90\xc3')

    def test_accepts_only_the_expected_calls_and_exit_edges(self):
        validate_phase_edges(phase())
        code=phase();code[:5]=b'\xe9'+(-6).to_bytes(4,'little',signed=True)
        with self.assertRaisesRegex(ValueError,'exit edges'):
            validate_phase_edges(code)

    def test_rejects_a_changed_call_target(self):
        code=phase();code[0x1e3c0-ENTRY]^=1
        with self.assertRaisesRegex(ValueError,'call edges'):
            validate_phase_edges(code)

    def test_rejects_an_instruction_crossing_the_shared_frame_boundary(self):
        code=phase();code[SIZE-1:SIZE+4]=b'\xb8'+bytes(4)
        with self.assertRaisesRegex(ValueError,'boundary'):
            validate_phase_edges(code)
