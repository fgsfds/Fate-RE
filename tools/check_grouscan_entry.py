"""Check the sloped-plane scan entry, including visibility and texture cache setup."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (
    DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations,
)

ENTRY, BODY, RESTORE = 0x5F1F8, 0x5F351, 0x5FED0
CEILING, FLOOR, ANIMATE, LOAD_TILE = 0x5DE70, 0x5DF75, 0x50758, 0x4BB0D
SPANS = (
    ('grouscan_', ENTRY, 123), ('grouscan_select_floor_', 0x5F273, 80),
    ('grouscan_select_tile_', 0x5F2C3, 36), ('grouscan_require_tile_', 0x5F2E7, 55),
    ('grouscan_touch_tile_', 0x5F31E, 51),
)
STACK, STOP, PIXELS = 0x3F0000, 0x3FF000, 0x350000
FRAME = STACK - 0x74
CAMERA_X, CAMERA_Y, CAMERA_Z = 490, 820, 600
LEFT, RIGHT, SECTOR, TILE, ANIM_STEP = 3, 19, 5, 18, 4
SAVED = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)
PRIOR = (0x11223344, 0x22334455, 0x33445566)


@dataclass(frozen=True)
class Case:
    name: str
    floor: bool = False
    relative_z: int = -12
    animate: bool = False
    width: int = 32
    height: int = 16
    cached: bool = True
    lock: int = 10


CASES = (
    Case('visible ceiling'),
    Case('visible floor', floor=True, relative_z=12),
    Case('ceiling on viewer plane', relative_z=0),
    Case('floor on viewer plane', floor=True, relative_z=0),
    Case('ceiling behind viewer', relative_z=12),
    Case('floor behind viewer', floor=True, relative_z=-12),
    Case('animated and uncached ceiling', animate=True, cached=False),
    Case('locked floor texture', floor=True, relative_z=12, lock=220),
    Case('animated floor with empty final width', floor=True, relative_z=12,
         animate=True, width=0, cached=False),
    Case('ceiling with negative texture height', height=-1),
)


def run_case(code, original, case):
    machine = Uc(UC_ARCH_X86, UC_MODE_32)
    machine.mem_map(0x10000, 0x3F0000)
    machine.mem_write(ENTRY, code)
    machine.mem_write(RESTORE, original[RESTORE:RESTORE + 7])

    def address(name, offset=0):
        return DS + DATA_OFFSETS['_' + name] + offset

    def write(name, value, offset=0, fmt='i'):
        machine.mem_write(address(name, offset), pack('<' + fmt, value))

    def read(name, offset=0, fmt='i'):
        return unpack('<' + fmt, machine.mem_read(address(name, offset),
                      {'b': 1, 'B': 1, 'h': 2, 'i': 4}[fmt]))[0]

    for name, value in (('camera_x', CAMERA_X), ('camera_y', CAMERA_Y), ('camera_z', CAMERA_Z)):
        write(name, value)
    sector = SECTOR * 40
    for offset, value, fmt in (
        (4, 610, 'i'), (8, 630, 'i'),
        (12, 6, 'h'), (14, 70, 'h'),
        (16, TILE, 'h'), (24, TILE, 'h'),
        (18, -9, 'h'), (26, 7, 'h'),
        (20, -5, 'b'), (28, 11, 'b'),
        (21, 2, 'B'), (29, 240, 'B'),
    ):
        write('sector', value, sector + offset, fmt)

    selected = TILE + (ANIM_STEP if case.animate else 0)
    write('globalpicnum', -1, fmt='h')
    write('picanm', 0x40 if case.animate else 0, TILE * 4, 'B')
    write('tilesizx', case.width, selected * 2, 'h')
    write('tilesizy', case.height, selected * 2, 'h')
    write('waloff', PIXELS if case.cached else 0, selected * 4)
    write('walock', case.lock, selected, 'B')
    slot, bit = divmod(selected, 8)
    for index in range(8):
        write('pow2char', 1 << index, index, 'B')
    write('gotpic', 0x80, slot, 'B')

    calls, handoffs = [], []

    def on_call(cpu, target, _size, _user):
        eax = cpu.reg_read(UC_X86_REG_EAX)
        edx = cpu.reg_read(UC_X86_REG_EDX)
        if target in (CEILING, FLOOR):
            calls.append((target, eax, edx, cpu.reg_read(UC_X86_REG_EBX)))
            cpu.reg_write(UC_X86_REG_EAX, CAMERA_Z + case.relative_z)
        elif target == ANIMATE:
            calls.append((target, eax, edx))
            cpu.reg_write(UC_X86_REG_EAX, ANIM_STEP)
        elif target == LOAD_TILE:
            calls.append((target, eax))
            write('waloff', PIXELS, eax * 4)

    def on_body(cpu, _target, _size, _user):
        assert cpu.reg_read(UC_X86_REG_ESP) == FRAME
        assert cpu.reg_read(UC_X86_REG_EBP) == address('sector', sector)
        assert unpack('<2I', cpu.mem_read(FRAME, 8)) == (RIGHT, LEFT)
        assert unpack('<3I', cpu.mem_read(FRAME + 0x68, 12)) == PRIOR
        for offset, expected in (
            (0x1C, 7 if case.floor else -9),
            (0x28, 630 if case.floor else 610),
        ):
            assert unpack('<i', cpu.mem_read(FRAME + offset, 4))[0] == expected
        handoffs.append(BODY)
        cpu.emu_stop()

    for target in (CEILING, FLOOR, ANIMATE, LOAD_TILE):
        machine.mem_write(target, b'\xc3')
        machine.hook_add(UC_HOOK_CODE, on_call, begin=target, end=target)
    machine.mem_write(BODY, b'\xc3')
    machine.hook_add(UC_HOOK_CODE, on_body, begin=BODY, end=BODY)
    machine.mem_write(STACK, pack('<I', STOP))
    for register, value in zip(SAVED, PRIOR):
        machine.reg_write(register, value)
    for register, value in (
        (UC_X86_REG_EAX, LEFT), (UC_X86_REG_EBX, SECTOR),
        (UC_X86_REG_ECX, int(case.floor)), (UC_X86_REG_EDX, RIGHT),
        (UC_X86_REG_ESP, STACK),
    ):
        machine.reg_write(register, value)

    machine.emu_start(ENTRY, STOP, count=6000)
    visible = case.relative_z > 0 if case.floor else case.relative_z < 0
    ready = visible and min(case.width, case.height) > 0
    expected_calls = [(FLOOR if case.floor else CEILING, SECTOR, CAMERA_X, CAMERA_Y)]
    if visible:
        assert read('globalpicnum', fmt='h') == selected
        assert read('globalorientation') == (70 if case.floor else 6)
        assert read('globalshade') == (11 if case.floor else -5)
        assert read('globalpal') == (240 if case.floor else 2)
        if case.animate:
            expected_calls.append((ANIMATE, TILE, SECTOR))
    else:
        assert read('globalpicnum', fmt='h') == -1
    if ready:
        assert handoffs == [BODY]
        assert machine.reg_read(UC_X86_REG_EIP) == BODY
        assert read('waloff', selected * 4) == PIXELS
        assert read('walock', selected, 'B') == max(case.lock, 199)
        assert read('gotpic', slot, 'B') == (0x80 | (1 << bit))
        if not case.cached:
            expected_calls.append((LOAD_TILE, selected))
    else:
        assert not handoffs
        assert machine.reg_read(UC_X86_REG_EIP) == STOP
        assert machine.reg_read(UC_X86_REG_ESP) == STACK + 4
        assert tuple(machine.reg_read(register) for register in SAVED) == PRIOR
        assert read('walock', selected, 'B') == case.lock
        assert read('gotpic', slot, 'B') == 0x80
    assert calls == expected_calls, (calls, expected_calls)


def check(executable, obj):
    original = image(executable)
    restored = bytearray()
    relocations = 0
    pointers = read_le_fixups(executable)['pointers']
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    for symbol, entry, size in SPANS:
        raw = entry + 0x25600
        code, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=entry,
                                             functions=FUNCTION_ADDRESSES)
        assert len(code) == size and code == executable[raw:raw + size], symbol
        verify_leaf_relocations(code, references, pointers, entry)
        relocations += len(references)
        code, _ = bind_leaf_details(obj, symbol, loaded, address=entry,
                                    functions=FUNCTION_ADDRESSES)
        restored.extend(code)
    assert len(restored) == BODY - ENTRY

    for label, code in (('original', original[ENTRY:BODY]), ('restored', bytes(restored))):
        for case in CASES:
            try:
                run_case(code, original, case)
            except AssertionError as error:
                raise AssertionError(f'{label}: {case.name}: {error}') from error
    return relocations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path, help='Pinned or byte-identical FATE.EXE')
    parser.add_argument('object', type=Path, help='Watcom object containing the slope scan entry')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {BODY - ENTRY} slope scan entry bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored cases')


if __name__ == '__main__':
    main()
