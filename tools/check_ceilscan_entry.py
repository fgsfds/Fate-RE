"""Check the ceiling scan entry, palette/cache dispatch, and texture axes."""
import argparse
from dataclasses import dataclass
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI,
    UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations

ENTRY, SIZE, TEXTURE, RESTORE = 0x478B5, 871, 0x47C1C, 0x47F04
SET_PALETTE, ANIMATE, LOAD_TILE = 0x740E0, 0x50758, 0x4BB0D
SPANS = (
    ('ceilscan_', ENTRY, 66), ('ceilscan_check_height_', 0x478F7, 51),
    ('ceilscan_animate_tile_', 0x4792A, 32), ('ceilscan_require_tile_', 0x4794A, 53),
    ('ceilscan_touch_tile_', 0x4797F, 120), ('ceilscan_flat_axes_', 0x479F7, 89),
    ('ceilscan_wall_axes_', 0x47A50, 132), ('ceilscan_wall_length_', 0x47AD4, 28),
    ('ceilscan_project_axes_', 0x47AF0, 300),
)
STACK, STOP, TEXTURE_DATA = 0x3F0000, 0x3FF000, 0x350000
FRAME = STACK - 36
LEFT, RIGHT, SECTOR, WALL, POINT2 = 3, 19, 5, 18, 20
CAMERA_X, CAMERA_Y, CAMERA_Z = 490, 820, 600
WALL_X, WALL_Y, RAY_X, RAY_Y = 500, 900, 12473, -8217
BASE_VIS, SHADE, PALETTE, LOOKUP = 772, -13, 4, 0x351000
ANIMATION_STEP = 3
SAVED = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ECX)
PRIOR = (0x11223344, 0x22334455, 0x33445566, 0x44556677)
AXES = ('globalx1', 'globalx2', 'globaly1', 'globaly2', 'globalxpanning', 'globalypanning')
MASK = 0xFFFFFFFF


@dataclass(frozen=True)
class Case:
    name: str
    tile: int = 16
    height: int = -24
    size: tuple = (32, 64)
    animate: bool = False
    cached: bool = True
    palette_cached: bool = True
    visibility: int = 0
    lock: int = 12
    orientation: int = 0
    wall_delta: tuple = (16, 12)
    table_value: int = 0x2800


CASES = (
    Case('positive plane height rejects after palette selection', height=1, palette_cached=False),
    Case('missing tile width guard', size=(0, 64)),
    Case('nonpositive tile height guard', size=(32, -1)),
    Case('invalid tile maps to tile zero', tile=0x1004),
    Case('negative tile maps to tile zero', tile=-3),
    Case('animate, cache load, palette and visibility', animate=True, cached=False,
         palette_cached=False, visibility=255),
    Case('existing locked texture', lock=230, visibility=20),
    Case('wall-aligned small base wall', orientation=0x40),
    Case('wall-aligned scaled table lookup', orientation=0x40, wall_delta=(192, 53),
         table_value=0x1C00),
    Case('wall-aligned degenerate length fallback', orientation=0x40, wall_delta=(0, 0),
         table_value=0),
)


def active_tile(case):
    base = case.tile if 0 <= case.tile <= 0xFFF else 0
    return base, base + (ANIMATION_STEP if case.animate else 0)


def table_index(case):
    square = sum(delta * delta for delta in case.wall_delta)
    exponent = max(0, pack('<f', float(square))[3] - 0x44)
    return square >> (2 * exponent), exponent


def expected_axes(case):
    if not (case.orientation & 0x40):
        values = (RAY_Y, RAY_Y, RAY_X, RAY_X, CAMERA_X << 20, -(CAMERA_Y << 20))
    else:
        dx, dy = case.wall_delta
        _, exponent = table_index(case)
        length = (case.table_value << exponent) >> 10
        inverse = (1 << 20) // length if length else 1024
        x = (((dx * RAY_Y - dy * RAY_X) >> 10) * inverse) >> 10
        y = (((dx * RAY_X + dy * RAY_Y) >> 10) * inverse) >> 10
        qx = (WALL_X - CAMERA_X) << 6
        qy = (WALL_Y - CAMERA_Y) << 6
        projected_x = (qx * RAY_X + qy * RAY_Y) >> 14
        projected_y = (qy * RAY_X - qx * RAY_Y) >> 14
        values = (x, -x, y, -y, x * projected_y - y * projected_x,
                  -y * projected_y - x * projected_x)
    return tuple(value & MASK for value in values)


def run_case(code, original, case):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3F0000)
    cpu.mem_write(ENTRY, code)
    cpu.mem_write(RESTORE, original[RESTORE:RESTORE + 8])

    def address(name, offset=0):
        return DS + DATA_OFFSETS['_' + name] + offset

    def put(name, value, offset=0, fmt='i'):
        cpu.mem_write(address(name, offset), pack('<' + fmt, value))

    for name, value in (
        ('camera_x', CAMERA_X), ('camera_y', CAMERA_Y), ('camera_z', CAMERA_Z),
        ('view_ray_x', RAY_X), ('view_ray_y', RAY_Y), ('base_plane_visibility', BASE_VIS),
        ('current_palookup', LOOKUP if case.palette_cached else LOOKUP + 100),
    ):
        put(name, value)

    sector = SECTOR * 40
    put('sector', WALL, sector, 'h')
    put('sector', CAMERA_Z + case.height, sector + 4)
    put('sector', case.orientation, sector + 12, 'h')
    put('sector', case.tile, sector + 16, 'h')
    put('sector', SHADE, sector + 20, 'b')
    put('sector', PALETTE, sector + 21, 'B')
    put('sector', case.visibility, sector + 32, 'B')
    put('palookup', LOOKUP, PALETTE * 4)
    put('globalpicnum', 83, fmt='h')

    base, tile = active_tile(case)
    put('picanm', 0x80 if case.animate else 0, base * 4, 'B')
    put('tilesizx', case.size[0], tile * 2, 'h')
    put('tilesizy', case.size[1], tile * 2, 'h')
    put('waloff', TEXTURE_DATA if case.cached else 0, tile * 4)
    put('walock', case.lock, tile, 'B')
    frame_slot, frame_bit = divmod(tile, 8)
    put('gotpic', 0x80, frame_slot, 'B')
    for index in range(8):
        put('pow2char', 1 << index, index, 'B')
    for index, x, y in (
        (WALL, WALL_X, WALL_Y),
        (POINT2, WALL_X + case.wall_delta[0], WALL_Y + case.wall_delta[1]),
    ):
        put('wall', x, index * 32)
        put('wall', y, index * 32 + 4)
    put('wall', POINT2, WALL * 32 + 8, 'h')
    ix, _ = table_index(case)
    put('sqrtable', case.table_value, ix * 2, 'H')

    calls, handoff = [], []

    def on_call(machine, target, _size, _user_data):
        eax = machine.reg_read(UC_X86_REG_EAX)
        if target == ANIMATE:
            calls.append((target, eax, machine.reg_read(UC_X86_REG_EDX)))
            machine.reg_write(UC_X86_REG_EAX, ANIMATION_STEP)
        else:
            calls.append((target, eax))
        if target == LOAD_TILE:
            put('waloff', TEXTURE_DATA, eax * 4)

    def begin_texture(machine, _address, _size, _user_data):
        assert machine.reg_read(UC_X86_REG_ESP) == FRAME
        assert machine.reg_read(UC_X86_REG_EBP) == address('sector', sector)
        assert unpack('<2I', machine.mem_read(FRAME, 8)) == (RIGHT, LEFT)
        assert unpack('<4I', machine.mem_read(FRAME + 0x14, 16)) == PRIOR
        handoff.append(True)
        machine.emu_stop()

    for target in (SET_PALETTE, ANIMATE, LOAD_TILE):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, on_call, begin=target, end=target)
    cpu.mem_write(TEXTURE, b'\xc3')
    cpu.hook_add(UC_HOOK_CODE, begin_texture, begin=TEXTURE, end=TEXTURE)
    cpu.mem_write(STACK, pack('<I', STOP))
    for register, value in zip(SAVED, PRIOR):
        cpu.reg_write(register, value)
    for register, value in (
        (UC_X86_REG_EAX, LEFT), (UC_X86_REG_EBX, SECTOR),
        (UC_X86_REG_EDX, RIGHT), (UC_X86_REG_ESP, STACK),
    ):
        cpu.reg_write(register, value)

    cpu.emu_start(ENTRY, STOP, count=6000)
    assert unpack('<i', cpu.mem_read(address('globalzd'), 4))[0] == case.height
    assert unpack('<i', cpu.mem_read(address('current_palookup'), 4))[0] == LOOKUP
    assert unpack('<h', cpu.mem_read(address('globalpicnum'), 2))[0] == (83 if case.height > 0 else tile)
    expected_calls = [] if case.palette_cached else [(SET_PALETTE, LOOKUP)]
    if case.height <= 0 and case.animate:
        expected_calls.append((ANIMATE, base, SECTOR))

    ready = case.height <= 0 and min(case.size) > 0
    if ready:
        if not case.cached:
            expected_calls.append((LOAD_TILE, tile))
        assert handoff == [True] and cpu.reg_read(UC_X86_REG_EIP) == TEXTURE
        assert unpack('<i', cpu.mem_read(address('globalbufplc'), 4))[0] == TEXTURE_DATA
        assert unpack('<i', cpu.mem_read(address('globalshade'), 4))[0] == SHADE
        visibility = BASE_VIS if not case.visibility else BASE_VIS * ((case.visibility + 16) & 255) >> 4
        assert unpack('<i', cpu.mem_read(address('globvis'), 4))[0] == visibility
        assert unpack('<i', cpu.mem_read(address('globalorientation'), 4))[0] == case.orientation
        assert cpu.mem_read(address('walock', tile), 1)[0] == (199 if case.lock < 200 else case.lock)
        assert cpu.mem_read(address('gotpic', frame_slot), 1)[0] == 0x80 | (1 << frame_bit)
        axes = tuple(unpack('<I', cpu.mem_read(address(name), 4))[0] for name in AXES)
        assert axes == expected_axes(case), (axes, expected_axes(case))
    else:
        assert not handoff
        assert cpu.reg_read(UC_X86_REG_EIP) == STOP
        assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
        assert tuple(cpu.reg_read(register) for register in SAVED) == PRIOR
        assert cpu.mem_read(address('walock', tile), 1)[0] == case.lock
        assert cpu.mem_read(address('gotpic', frame_slot), 1)[0] == 0x80
    assert calls == expected_calls, (calls, expected_calls)


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
    parser.add_argument('object', type=Path, help='Watcom object containing the ceiling scan entry')
    args = parser.parse_args()
    relocations = check(args.executable.read_bytes(), args.object.read_bytes())
    print(f'PASS: {SIZE} bytes, {relocations} LE relocations, '
          f'{len(CASES)} original and {len(CASES)} restored ceiling entry cases')


if __name__ == '__main__':
    main()
