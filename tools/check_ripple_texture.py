"""Check ripple creation, seven-neighbor filtering, buffer guards and register ABI."""
from pathlib import Path
import struct
import argparse
import json
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import (DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES,
                           bind_leaf_details, verify_leaf_relocations)

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
                  mutation_controls=3, linked_c_bytes=152,
                  unique_compiler_body_bytes=38, unlinked_return_bytes=1,
                  le_sites=0)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
