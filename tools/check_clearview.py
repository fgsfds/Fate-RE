"""Check exact viewport fill for linear, planar VGA, and stereo modes."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE, UC_HOOK_INSN, UC_HOOK_MEM_WRITE
from unicorn.x86_const import (
    UC_X86_INS_OUT, UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX,
    UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP,
    UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE = 0x5CD99, 751
SPANS = (
    ('clearview_', ENTRY, 115), ('clearview_stereo_row_', 0x5CE0C, 149),
    ('clearview_check_stereo_row_', 0x5CEA1, 17), ('clearview_check_planar_', 0x5CEB2, 346),
    ('clearview_linear_', 0x5D00C, 114), ('clearview_service_timer_', 0x5D07E, 10),
)
RESTORE, POP_REGISTERS, TIMER = 0x4BB05, 0x4ABBE, 0x31EC4
FRAME, STEREO, PLANAR = 0x350000, 0x360000, 0x380000
STACK, STOP, STRIDE, ROWS = 0x3F0000, 0x3FF000, 36, 8
STEREO_OFFSET = 0x10000
GUARD = 0x6B


@dataclass(frozen=True)
class Case:
    name: str
    left: int
    right: int
    top: int = 1
    bottom: int = 4
    graphics: bool = True
    stereo: bool = False
    planar: bool = False
    pixel: int = 0xAD


CASES = (
    Case('text mode', 1, 8, graphics=False),
    Case('one linear pixel', 3, 3),
    Case('two linear pixels', 2, 3),
    Case('three linear pixels', 1, 3),
    Case('unaligned linear rows', 1, 17),
    Case('empty linear viewport', 2, 14, top=4, bottom=3),
    Case('stereo dual short rows', 3, 5, stereo=True),
    Case('unaligned stereo dual rows', 1, 18, stereo=True, planar=True, pixel=255),
    Case('planar aligned viewport', 4, 19, planar=True),
    Case('planar left edge', 2, 19, planar=True),
    Case('planar right edge', 4, 18, planar=True),
    Case('planar both edges', 1, 18, planar=True),
    Case('planar edges only', 2, 5, planar=True),
)


def expected_buffer(case, active):
    expected = bytearray([GUARD]) * (STRIDE * ROWS)
    if active:
        for row in range(case.top, case.bottom + 1):
            left = row * STRIDE + case.left
            right = row * STRIDE + case.right + 1
            expected[left:right] = bytes([case.pixel]) * (right - left)
    return expected


def expected_planes(case):
    mask_writes = [(0x3C4, 1, 2)]
    end = case.right + 1
    if case.left & 3:
        mask_writes.append((0x3C5, 1, 16 - (1 << (case.left & 3))))
    if end & 3:
        mask_writes.append((0x3C5, 1, (1 << (end & 3)) - 1))
    if (case.left + 3) // 4 < end // 4:
        mask_writes.append((0x3C5, 1, 15))
    pixels = {(row, column): case.pixel for row in range(case.top, case.bottom + 1)
             for column in range(case.left, case.right + 1)}
    return mask_writes, pixels


def run_case(code, original, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 8])
    cpu.mem_write(POP_REGISTERS, original[POP_REGISTERS:POP_REGISTERS + 7])
    guard_bytes = bytes([GUARD]) * (STRIDE * ROWS)
    for address in (FRAME, STEREO, STEREO + STEREO_OFFSET):
        cpu.mem_write(address, guard_bytes)

    def put(name, fmt, *values):
        cpu.mem_write(DS + DATA_OFFSETS['_' + name], pack('<' + fmt, *values))

    put('qsetmode', 'I', 0xC8 if case.graphics else 3)
    put('stereofps', 'I', case.stereo)
    put('chainstat', 'B', case.planar)
    put('windowx1', 'I', case.left)
    put('windowx2', 'I', case.right)
    put('windowy1', 'I', case.top)
    put('windowy2', 'I', case.bottom)
    put('frameplace', 'I', FRAME)
    put('clear_stereo_buffer', 'I', STEREO)
    put('chainplace', 'I', PLANAR)
    put('ylookup', f'{ROWS}I', *(STRIDE * row for row in range(ROWS)))
    put('pow2char', '8B', *(1 << bit for bit in range(8)))

    ports, pixels, timer_stacks, restore_stacks = [], {}, [], []
    plane_mask = 0

    def out_port(_machine, port, size, value, _user_data):
        nonlocal plane_mask
        ports.append((port, size, value))
        if port == 0x3C5:
            plane_mask = value

    def planar_write(_machine, _access, address, size, value, _user_data):
        assert plane_mask, 'planar byte written without enabling a plane'
        for byte in range(size):
            row, cell = divmod(address + byte - PLANAR, STRIDE)
            for plane in range(4):
                if plane_mask & (1 << plane):
                    pixels[row, cell * 4 + plane] = (value >> (byte * 8)) & 0xff

    def on_timer(machine, _address, _size, _user_data):
        timer_stacks.append(machine.reg_read(UC_X86_REG_ESP))

    def on_restore(machine, _address, _size, _user_data):
        restore_stacks.append(machine.reg_read(UC_X86_REG_ESP))

    cpu.mem_write(TIMER, b'\xc3')
    cpu.hook_add(UC_HOOK_CODE, on_timer, begin=TIMER, end=TIMER)
    cpu.hook_add(UC_HOOK_CODE, on_restore, begin=RESTORE, end=RESTORE)
    cpu.hook_add(UC_HOOK_INSN, out_port, None, 1, 0, UC_X86_INS_OUT)
    cpu.hook_add(UC_HOOK_MEM_WRITE, planar_write, begin=PLANAR - 32, end=PLANAR + STRIDE * ROWS + 32)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, case.pixel)
    saved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESI,
             UC_X86_REG_EDI, UC_X86_REG_EBP)
    prior = tuple(0x10203040 + index for index in range(len(saved)))
    for register, value in zip(saved, prior):
        cpu.reg_write(register, value)
    cpu.emu_start(ENTRY, STOP, count=8000)

    active_planar = case.graphics and case.planar and not case.stereo
    assert (ports, pixels) == (expected_planes(case) if active_planar else ([], {}))
    linear = case.graphics and not (case.stereo or case.planar)
    assert cpu.mem_read(FRAME, len(guard_bytes)) == expected_buffer(case, linear)
    stereo = expected_buffer(case, case.graphics and case.stereo)
    assert cpu.mem_read(STEREO, len(stereo)) == stereo
    assert cpu.mem_read(STEREO + STEREO_OFFSET, len(stereo)) == stereo
    assert timer_stacks == ([STACK - 36] if case.graphics else [])
    assert restore_stacks == [STACK - 32]
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert tuple(cpu.reg_read(reg) for reg in saved) == prior


def check(exe, obj):
    original = image(exe)
    restored = bytearray()
    relocations = 0
    pointers = read_le_fixups(exe)['pointers']
    loaded = {name: offset + DS for name, offset in DATA_OFFSETS.items()}
    for symbol, entry, length in SPANS:
        raw = entry + 0x25600
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry,
                                             functions=FUNCTION_ADDRESSES)
        assert len(code) == length and code == exe[raw:raw + length], f'{symbol}: machine code mismatch'
        verify_leaf_relocations(code, references, pointers, entry)
        relocations += len(references)
        code, _ = bind_leaf_details(obj, symbol, loaded, address=entry, functions=FUNCTION_ADDRESSES)
        restored.extend(code)
    assert len(restored) == SIZE

    for label, code in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', bytes(restored))):
        for case in CASES:
            try:
                run_case(code, original, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the viewport clear spans')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored viewport-clear cases')


if __name__ == '__main__':
    main()
