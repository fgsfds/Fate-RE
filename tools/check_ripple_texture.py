"""Check ripple creation, seven-neighbor filtering, buffer guards and register ABI."""
from pathlib import Path
import struct
import argparse
import json
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from match_objects import index as omf_index
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES,
                           bind_leaf_details, verify_leaf_relocations, parsed_leaf_object)

ENTRY, STOP, STACK, TEXTURE = 0x2eb57, 0x3fff00, 0x3ff000, 0x380000
COUNT, FRAME, RADII, SPEED = 0x770e0, 0x770f4, 0x62fcc, 0x630fc
ORIGIN_X, ORIGIN_Y, BUFFER = 0x677bc, 0x6773c, 0x6331c
SAMPLES, OFF_X, OFF_Y = 0x5ae5c, 0x5aedc, 0x5eedc
REGS = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
        UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def expected(texture, radii, xs, ys, count, draws, speed):
    pixels = bytearray(texture)
    radii, xs, ys = list(radii), list(xs), list(ys)
    random_index = 0
    for _ in range(max(0, min(3, 31 - count) + 1)):
        xs[count], ys[count] = draws[random_index] & 127, draws[random_index + 1] & 127
        random_index += 2
        radii[count] = 1
        count += 1
    for i in range(count - 1, -1, -1):
        radius = radii[i]
        amount = speed[radius] * (1 if i % 2 else -1)
        # Samples are visited in reverse, and duplicates intentionally accumulate.
        for dx, dy in reversed(((-radius, 0), (radius, 0), (0, radius))):
            index = ((xs[i] + dx) % 128) * 128 + (ys[i] + dy) % 128
            pixels[index] = max(192, (pixels[index] + amount) % 256)
        radii[i] += 1
        if radii[i] > 10:
            count -= 1
            radii[i], xs[i], ys[i] = radii[count], xs[count], ys[count]
    masked = [v & 31 for v in pixels]
    output = bytearray(16384)
    for x in range(128):
        for y in range(128):
            total = sum(masked[((x + dx) % 128) * 128 + (y + dy) % 128]
                        for dx, dy in ((-1, -1), (-1, 0), (-1, 1), (0, -1),
                                       (0, 1), (1, -1), (1, 0)))
            output[x * 128 + y] = (total // 8 - 62) % 256
    return output, radii, xs, ys, count, random_index, pixels


def exercise(memory, count, seed, body=None):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    if body is not None:
        cpu.mem_write(ENTRY, body)
    def put(offset, values):
        cpu.mem_write(DS + offset, struct.pack('<' + 'I' * len(values),
                                             *(v & 0xffffffff for v in values)))
    radii = [1 + (i + seed) % 10 for i in range(32)]
    xs = [(i * 11 + seed * 31) % 128 for i in range(32)]
    ys = [(i * 7 + seed * 19) % 128 for i in range(32)]
    speed = [((i * 7 + seed) % 17) - 8 for i in range(16)]
    draws = [0xabc00000 + (i * 73 + seed * 41) for i in range(8)]
    texture = bytes(((i * (seed + 1) + i // 128 + seed * 17) & 255) for i in range(16384))
    if seed == 0:
        texture = b'\xff' * 16384
    want = expected(texture, radii, xs, ys, count, draws, speed)
    for offset, values in ((COUNT, [count]), (FRAME, [0xffffffff]),
                           (RADII, radii), (ORIGIN_X, xs), (ORIGIN_Y, ys),
                           (SPEED, speed), (SAMPLES, [3] * 16)):
        put(offset, values)
    for radius in range(16):
        put(OFF_X + radius * 512, [-radius, radius, 0])
        put(OFF_Y + radius * 512, [0, 0, radius])
    cpu.mem_write(TEXTURE - 16, b'\xa5' * 16 + texture + b'\x5a' * 16)
    cpu.mem_write(DS + BUFFER - 1, b'\xa7' * (132 * 130 + 2))
    cpu.mem_write(STACK, struct.pack('<I', STOP) + b'\xcc' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.reg_write(UC_X86_REG_EAX, TEXTURE)
    for index, reg in enumerate(REGS):
        cpu.reg_write(reg, 0x12340000 + index)
    random_index = 0
    def rng(uc, address, size, data):
        nonlocal random_index
        uc.reg_write(UC_X86_REG_EAX, draws[random_index])
        random_index += 1
        esp = uc.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', uc.mem_read(esp, 4))
        uc.reg_write(UC_X86_REG_ESP, esp + 4)
        uc.reg_write(UC_X86_REG_EIP, ret)
    cpu.hook_add(UC_HOOK_CODE, rng, begin=0x602d0, end=0x602d0)
    cpu.emu_start(ENTRY, STOP, count=500000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xcc' * 16
    assert all(cpu.reg_read(reg) == 0x12340000 + i for i, reg in enumerate(REGS))
    assert cpu.mem_read(TEXTURE, 16384) == want[0], ('texture', count, seed)
    for offset, values in ((RADII, want[1]), (ORIGIN_X, want[2]), (ORIGIN_Y, want[3]),
                           (COUNT, [want[4]]), (FRAME, [0])):
        assert cpu.mem_read(DS + offset, len(values) * 4) == struct.pack('<' + 'I' * len(values), *values), hex(offset)
    assert random_index == want[5]
    bordered = bytearray(b'\xa7' * (132 * 130))
    for x in range(130):
        for y in range(130):
            bordered[x * 132 + y] = want[6][((x - 1) % 128) * 128 + (y - 1) % 128] & 31
    # The original stores the unused last corner in the final padding byte.
    bordered[129 * 132 + 129] = 0xa7
    bordered[129 * 132 + 131] = want[6][0] & 31
    assert cpu.mem_read(DS + BUFFER, len(bordered)) == bordered, 'bordered snapshot'
    assert cpu.mem_read(TEXTURE - 16, 16) == b'\xa5' * 16
    assert cpu.mem_read(TEXTURE + 16384, 16) == b'\x5a' * 16
    assert cpu.mem_read(DS + BUFFER - 1, 1) == b'\xa7'
    assert cpu.mem_read(DS + BUFFER + 132 * 130, 1) == b'\xa7'



def check_leaf(body, samples):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x10000)
    cpu.mem_write(0x1000, body + b'\xc3')
    center, stack, stop = 0x4000, 0x8000, 0x9000
    for offset, value in zip((-133, -1, -132, 131, -131, 132, 1), samples):
        cpu.mem_write(center + offset, bytes([value]))
    cpu.mem_write(stack, struct.pack('<I', stop) + b'\xa5' * 16)
    cpu.reg_write(UC_X86_REG_ESP, stack)
    cpu.reg_write(UC_X86_REG_EAX, 0x12345678)
    cpu.reg_write(UC_X86_REG_EDX, 0x98765432)
    cpu.reg_write(UC_X86_REG_EBX, center)
    preserved = (UC_X86_REG_ECX, UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
    for i, reg in enumerate(preserved):
        cpu.reg_write(reg, 0xabc00000 + i)
    cpu.emu_start(0x1000, stop, count=40)
    assert cpu.reg_read(UC_X86_REG_EIP) == stop
    assert cpu.reg_read(UC_X86_REG_ESP) == stack + 4
    assert cpu.mem_read(stack + 4, 16) == b'\xa5' * 16
    assert cpu.reg_read(UC_X86_REG_EAX) == 0x12345600 | (sum(samples) & 255)
    partial = (samples[1] + samples[3] + samples[5]) & 255
    assert cpu.reg_read(UC_X86_REG_EDX) == 0x98765400 | partial
    assert cpu.reg_read(UC_X86_REG_EBX) == center
    assert all(cpu.reg_read(reg) == 0xabc00000 + i for i, reg in enumerate(preserved))



def check_control_leaf(code, kind, value, alignment=0):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x400000)
    entry = 0x2eb62 if kind == 'limit' else 0x2ecc8
    cpu.mem_write(entry, code + b'\xc3')
    cpu.mem_write(STACK, struct.pack('<I', STOP) + b'\xa5' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for i, reg in enumerate(REGS):
        cpu.reg_write(reg, 0xabc00000 + i)
    if kind == 'limit':
        cpu.mem_write(DS + COUNT, struct.pack('<i', value))
    else:
        source, destination = 0x300000 + alignment, 0x310001 + alignment
        pixels = bytes((i * value + value * 17) & 255 for i in range(128))
        cpu.mem_write(source - 16, b'\xcc' * 16 + pixels + b'\xdd' * 16)
        cpu.mem_write(destination - 16, b'\xa7' * 164)
        cpu.reg_write(UC_X86_REG_EAX, destination)
        cpu.reg_write(UC_X86_REG_ESI, source)
    cpu.emu_start(entry, STOP, count=1000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    if kind == 'limit':
        assert cpu.reg_read(UC_X86_REG_EAX) == min(3, 31 - value) & 0xffffffff
        assert all(cpu.reg_read(reg) == 0xabc00000 + i for i, reg in enumerate(REGS))
        assert cpu.mem_read(DS + COUNT, 4) == struct.pack('<i', value)
    else:
        assert cpu.reg_read(UC_X86_REG_EAX) == destination + 132
        assert cpu.reg_read(UC_X86_REG_EBX) == destination + 132
        assert cpu.reg_read(UC_X86_REG_ESI) == source + 128
        assert cpu.reg_read(UC_X86_REG_ECX) == 0
        assert cpu.reg_read(UC_X86_REG_EDI) == int.from_bytes(pixels[-4:], 'little') & 0x1f1f1f1f
        assert cpu.reg_read(UC_X86_REG_EDX) == 0xabc00002
        assert cpu.reg_read(UC_X86_REG_EBP) == 0xabc00005
        assert cpu.mem_read(destination - 16, 164) == (
            b'\xa7' * 16 + bytes(pixel & 31 for pixel in pixels) + b'\xa7' * 20)
        assert cpu.mem_read(source - 16, 160) == b'\xcc' * 16 + pixels + b'\xdd' * 16



def check_border(code, seed, alignment):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, 0x400000)
    entry, source = 0x2ecf1, 0x300000 + alignment
    cpu.mem_write(entry, code + b'\xc3')
    pixels = bytes((i * (seed + 1) + (i // 128) * 7 + seed * 41) & 255
                   for i in range(16384))
    cpu.mem_write(source - 16, b'\xcc' * 16 + pixels + b'\xdd' * 16)
    cpu.mem_write(DS + BUFFER - 1, b'\xa7' * 17162)
    cpu.mem_write(STACK, struct.pack('<I', STOP) + b'\xa5' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for i, reg in enumerate(REGS):
        cpu.reg_write(reg, 0xabc00000 + i)
    cpu.reg_write(UC_X86_REG_EAX, 0x11223344)
    cpu.reg_write(UC_X86_REG_EBX, 0x55667788)
    cpu.reg_write(UC_X86_REG_EDX, source)
    cpu.emu_start(entry, STOP, count=5000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    assert cpu.reg_read(UC_X86_REG_EAX) == 0x11223300 | (pixels[127] & 31)
    assert cpu.reg_read(UC_X86_REG_EBX) == 0x55667700 | (pixels[16383] & 31)
    assert cpu.reg_read(UC_X86_REG_ECX) == 128
    assert cpu.reg_read(UC_X86_REG_EDX) == source
    for reg, value in ((UC_X86_REG_ESI, 0xabc00003), (UC_X86_REG_EDI, 0xabc00004),
                       (UC_X86_REG_EBP, 0xabc00005)):
        assert cpu.reg_read(reg) == value
    expected_plane = bytearray(b'\xa7' * 17160)
    for i in range(128):
        expected_plane[1 + i] = pixels[16256 + i] & 31
        expected_plane[17029 + i] = pixels[i] & 31
    assert cpu.mem_read(DS + BUFFER - 1, 17162) == b'\xa7' + expected_plane + b'\xa7'
    assert cpu.mem_read(source - 16, 16416) == b'\xcc' * 16 + pixels + b'\xdd' * 16


def mutate_border_guard(blob, relative):
    _, publics, *_ = parsed_leaf_object(blob)
    segment, public_start, _ = next(row for row in publics if row[2] == 'ripple_border_columns_')
    target, changed, cursor = public_start + relative, bytearray(blob), 0
    while cursor < len(blob):
        kind = blob[cursor]
        length = int.from_bytes(blob[cursor + 1:cursor + 3], 'little')
        end = cursor + 3 + length
        if kind in (0xa0, 0xa1):
            data = blob[cursor + 3:end - 1]
            seg, position = omf_index(data, 0)
            width = 4 if kind == 0xa1 else 2
            origin = int.from_bytes(data[position:position + width], 'little')
            payload = position + width
            if seg == segment and origin <= target < origin + len(data) - payload:
                changed[cursor + 3 + payload + target - origin] ^= 1
                changed[end - 1] = 0
                changed[end - 1] = (-sum(changed[cursor:end])) & 255
                return bytes(changed)
        cursor = end
    raise AssertionError('Missing compiler border-copy guard bytes')


def require_rejected(action):
    try:
        action()
    except AssertionError:
        return
    raise AssertionError('Mutation control escaped the ripple oracle')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    executable = args.exe.read_bytes()
    memory = image(executable)
    obj = (args.build / 'ripsum.obj').read_bytes()
    code = None
    for symbol in ('ripple_sum_first_', 'ripple_sum_second_',
                   'ripple_sum_third_', 'ripple_sum_fourth_'):
        raw, size = LEAVES[symbol]
        body, bindings = bind_leaf_details(obj, symbol, DATA_OFFSETS,
                                           address=raw - 0x25600,
                                           functions=FUNCTION_ADDRESSES)
        assert body == executable[raw:raw + size]
        verify_leaf_relocations(body, bindings, read_le_fixups(executable)['pointers'],
                                raw - 0x25600)
        assert not bindings
        if code is not None:
            assert body == code
        code = body
    controls = {}
    obj_control = (args.build / 'ripctl.obj').read_bytes()
    for symbol, kind in (('ripple_spawn_limit_phase_', 'limit'),
                         ('ripple_mask_row_phase_', 'row')):
        raw, size = LEAVES[symbol]
        body, bindings = bind_leaf_details(obj_control, symbol, DATA_OFFSETS,
                                           address=raw - 0x25600,
                                           functions=FUNCTION_ADDRESSES)
        assert body == executable[raw:raw + size]
        verify_leaf_relocations(body, bindings, read_le_fixups(executable)['pointers'],
                                raw - 0x25600)
        relocated, _ = bind_leaf_details(
            obj_control, symbol, {name: DS + off for name, off in DATA_OFFSETS.items()},
            address=raw - 0x25600, functions=FUNCTION_ADDRESSES)
        controls[kind] = relocated
    for value in range(33):
        check_control_leaf(controls['limit'], 'limit', value)
    for value in (0, 1, 7, 255):
        for alignment in range(4):
            check_control_leaf(controls['row'], 'row', value, alignment)
    altered = bytearray(controls['limit'])
    assert altered[15] == 0x7c
    altered[15] = 0x7f
    require_rejected(lambda: check_control_leaf(bytes(altered), 'limit', 0))
    altered = bytearray(controls['row'])
    assert altered[12:16] == b'\x1f' * 4
    altered[12] = 0x1e
    require_rejected(lambda: check_control_leaf(bytes(altered), 'row', 1))
    altered = bytearray(controls['row'])
    assert altered[28] == 0x7f
    altered[28] = 0x7e
    require_rejected(lambda: check_control_leaf(bytes(altered), 'row', 1))
    border_obj = (args.build / 'ripbord.obj').read_bytes()
    border_code = b''
    for symbol in ('ripple_border_initialize_', 'ripple_border_loop_'):
        raw, size = LEAVES[symbol]
        body, bindings = bind_leaf_details(border_obj, symbol, DATA_OFFSETS,
                                           address=raw - 0x25600,
                                           functions=FUNCTION_ADDRESSES)
        assert body == executable[raw:raw + size]
        verify_leaf_relocations(body, bindings, read_le_fixups(executable)['pointers'],
                                raw - 0x25600)
        relocated, _ = bind_leaf_details(
            border_obj, symbol, {name: DS + off for name, off in DATA_OFFSETS.items()},
            address=raw - 0x25600, functions=FUNCTION_ADDRESSES)
        border_code += relocated
    for seed in range(4):
        for alignment in range(4):
            check_border(border_code, seed, alignment)
    for offset in (0, 5):
        altered_obj = mutate_border_guard(border_obj, offset)
        try:
            bind_leaf_details(altered_obj, 'ripple_border_initialize_', DATA_OFFSETS,
                              address=0x2ecf1, functions=FUNCTION_ADDRESSES)
        except ValueError as error:
            assert str(error) == 'Unlinked ripple pixel copy differs'
        else:
            raise AssertionError('Unlinked border guard mutation escaped')
    altered = bytearray(border_code)
    assert altered[13] == 0x1f
    altered[13] = 0x1e
    require_rejected(lambda: check_border(bytes(altered), 0, 0))
    altered = bytearray(border_code)
    assert altered[38] == 0x7c
    altered[38] = 0x7e
    require_rejected(lambda: check_border(bytes(altered), 0, 0))
    for count in (0, 1, 4, 28, 29, 30, 31, 32):
        for seed in range(4):
            exercise(memory, count, seed)
    samples = [(0,) * 7, (31,) * 7, (255,) * 7, (0, 255, 0, 255, 0, 255, 0)]
    samples += [tuple((i * 37 + j * 71) & 255 for j in range(7)) for i in range(64)]
    for values in samples:
        check_leaf(code, values)
    altered = bytearray(code)
    assert altered[-2:] == b'\x00\xd0'
    altered[-2] = 0x28
    require_rejected(lambda: check_leaf(bytes(altered), (31,) * 7))
    altered = bytearray(code)
    assert altered[17:21] == bytes.fromhex('83000000')
    altered[17] = 0x82
    require_rejected(lambda: check_leaf(bytes(altered), (31,) * 7))
    altered_image = bytearray(memory)
    altered_image[0x2edb0 + 36:0x2edb0 + 38] = b'\x90\x90'
    require_rejected(lambda: exercise(bytes(altered_image), 32, 2))
    result = dict(status='PASS', parent_cases=32, leaf_cases=len(samples),
                  mutation_controls=8, spawn_limit_cases=33, masked_row_cases=16,
                  border_cases=16, unlinked_border_guard_controls=2,
                  linked_c_bytes=246,
                  unique_compiler_body_bytes=132, unlinked_return_bytes=4,
                  unlinked_border_context_bytes=7,
                  le_sites=3)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
