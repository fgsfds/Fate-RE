"""Compare the Watcom palette table candidate with the verified Fate routine."""
import argparse
from hashlib import sha256
from pathlib import Path
from random import Random
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import UC_X86_REG_EIP, UC_X86_REG_ESP

from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, bind_leaf_details, verify_leaf_relocations


RAW_OFFSET = 0x5b905
ORIGINAL_BYTES = 649
PALETTE_BYTES = 256 * 3
ARENA, ARENA_SIZE = 0x171000, 0x3000
ENTRY, RETURN, STACK = 0x1000, 0x2000, 0x4000


def run(code, palette):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(ENTRY, 0x2000)
    machine.mem_map(STACK, 0x1000)
    machine.mem_map(ARENA, ARENA_SIZE)
    machine.mem_write(ENTRY, code)
    machine.mem_write(ARENA, bytes([0xa5]) * ARENA_SIZE)
    machine.mem_write(DATA_OFFSETS['_saved_palette'], palette)
    machine.mem_write(STACK + 0xffc, pack('<I', RETURN))
    machine.reg_write(UC_X86_REG_ESP, STACK + 0xffc)
    machine.emu_start(ENTRY, RETURN, count=200000)
    if machine.reg_read(UC_X86_REG_EIP) != RETURN:
        raise ValueError('Palette table routine did not return')
    return machine.mem_read(ARENA, ARENA_SIZE)


def verify(executable, candidate):
    if sha256(executable).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    original = executable[RAW_OFFSET:RAW_OFFSET + ORIGINAL_BYTES]
    address = RAW_OFFSET - 0x25600
    code, bindings = bind_leaf_details(
        candidate, 'build_palette_fade_tables_', DATA_OFFSETS, address=address,
    )
    if code != original:
        raise ValueError('Palette fade table code differs')
    verify_leaf_relocations(code, bindings, read_le_fixups(executable)['pointers'], address)
    palettes = {
        'black': bytes(PALETTE_BYTES),
        'VGA white': bytes([63]) * PALETTE_BYTES,
        'threshold': bytes([64, 65, 127]) * 256,
        'all byte values': bytes((color * factor + shift) % 256
                                 for color in range(256)
                                 for factor, shift in ((1, 0), (3, 7), (5, 63))),
        'mixed': Random(0).randbytes(PALETTE_BYTES),
    }
    for name, palette in palettes.items():
        if run(code, palette) != run(original, palette):
            raise ValueError(f'Palette table or adjacent data differs for {name}')
    return len(palettes), len(code), len(bindings)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    cases, length, sites = verify(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: palette tables agree for {cases} inputs '
          f'({length} exact bytes, {sites} LE relocations)')
