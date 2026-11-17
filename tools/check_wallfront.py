"""Check exact wallfront code, signed wall ordering and the shared restore tail."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY = 0x45313
INNER = ENTRY + 5
SIZE = 532
RESTORE = 0x50347
STACK = 0x3F0000
RETURN = 0x3FF000

CASES = (
    ('parallel, camera with second wall', ((0, 10), (100, 10)), (50, 25), 1),
    ('parallel, camera across first wall', ((0, 10), (100, 10)), (50, -25), 0),
    ('parallel, camera on first wall', ((0, -10), (100, -10)), (50, 0), 1),
    ('both endpoints collinear', ((20, 0), (120, 0)), (50, 20), -1),
    ('first endpoint lies on line', ((10, 0), (110, 20)), (50, 25), 1),
    ('second endpoint lies on line', ((110, 20), (10, 0)), (50, -25), 0),
    ('second wall separates camera from first', ((200, -10), (200, 10)), (250, 0), 1),
    ('second wall has camera and first on same side', ((200, -10), (200, 10)), (0, 0), 0),
    ('both walls cross one another', ((50, -20), (50, 20)), (0, 0), -2),
    ('negative oriented wall coordinates', ((-180, -30), (-120, -10)), (-150, -45), 1),
)


def run_case(code, tail, second_wall, camera):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, tail)
    walls = ((0, 0), (100, 0)) + second_wall
    for index, (x, y) in enumerate(walls):
        cpu.mem_write(DS + DATA_OFFSETS['_wall'] + 32 * index,
                      pack('<iih', x, y, index ^ 1))
    scan_indices = DS + DATA_OFFSETS['_scan_wall_index']
    cpu.mem_write(scan_indices + 4, pack('<h', 0))
    cpu.mem_write(scan_indices + 14, pack('<h', 2))
    cpu.mem_write(DS + DATA_OFFSETS['_camera_x'], pack('<i', camera[0]))
    cpu.mem_write(DS + DATA_OFFSETS['_camera_y'], pack('<i', camera[1]))
    cpu.mem_write(STACK, pack('<I', RETURN))
    cpu.reg_write(UC_X86_REG_EAX, 2)
    cpu.reg_write(UC_X86_REG_EDX, 7)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    preserved = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_ESI,
                 UC_X86_REG_EDI, UC_X86_REG_EBP)
    values = tuple(0x10203040 + index for index in range(len(preserved)))
    for register, value in zip(preserved, values):
        cpu.reg_write(register, value)
    tail_stack = []

    def record_restore(machine, _address, _size, _user_data):
        tail_stack.append(machine.reg_read(UC_X86_REG_ESP))

    cpu.hook_add(UC_HOOK_CODE, record_restore, begin=RESTORE, end=RESTORE)
    cpu.emu_start(ENTRY, RETURN, count=2000)
    assert tail_stack == [STACK - 20], 'shared restore entry or saved frame differs'
    assert cpu.reg_read(UC_X86_REG_EIP) == RETURN, 'routine did not return through shared restore'
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4, 'stack cleanup differs'
    assert tuple(cpu.reg_read(register) for register in preserved) == values, 'register restore differs'
    result = cpu.reg_read(UC_X86_REG_EAX)
    return result if result < 0x80000000 else result - 0x100000000


def check(exe, obj):
    original = image(exe)
    spans = (('wallfront_', ENTRY, 5), ('wallfront_geometry_', INNER, SIZE - 5))
    restored_parts = []
    pointer_count = 0
    pointers = read_le_fixups(exe)['pointers']
    loaded_offsets = {name: value + DS for name, value in DATA_OFFSETS.items()}
    for symbol, address, size in spans:
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=address,
                                              functions=FUNCTION_ADDRESSES)
        raw = address + 0x25600
        assert len(code) == size and code == exe[raw:raw + size], f'{symbol}: machine code mismatch'
        verify_leaf_relocations(code, references, pointers, address)
        pointer_count += len(references)
        loaded, _ = bind_leaf_details(obj, symbol, loaded_offsets, address=address,
                                      functions=FUNCTION_ADDRESSES)
        restored_parts.append(loaded)
    restored = b''.join(restored_parts)
    tail = original[RESTORE:RESTORE + 6]
    assert tail == bytes.fromhex('5d 5f 5e 59 5b c3')
    for label, code in (('original', original[ENTRY:ENTRY + SIZE]), ('restored', restored)):
        for name, second_wall, camera, expected in CASES:
            assert run_case(code, tail, second_wall, camera) == expected, f'{label}: {name}'
    return pointer_count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing both wallfront spans')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, {len(CASES)} original and {len(CASES)} restored wall-ordering cases')


if __name__ == '__main__':
    main()
