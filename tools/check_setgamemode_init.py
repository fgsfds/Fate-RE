"""Check the video initialization handoff with hardware and runtime calls stubbed."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
    UC_X86_REG_EFLAGS, UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from match_objects import index
from bind_setgamemode_display import bind_display_reset, ADDRESS

ENTRY, STOP, STACK = 0x4b04e, 0x4b149, 0x3ff000
BACKEND, MALLOC, DIAGNOSTIC, EXIT = 0x4a294, 0x4478c, 0x40bb4, 0x60353
ALLOCATIONS = (0x301000, 0x302000)
SAVES = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ECX)
SAVED_VALUES = (0x10203040, 0x50403020, 0x55667788, 0x87654321)
CASES = ((0, 320, 200, 0), (2, 640, 480, 0), (7, 800, 601, 0),
         (1, 320, 201, 1), (6, 1280, 719, 2))


def check(memory, mode, width, height, fail_at):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(STACK - 16, b'\xa5' * 16)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for reg, value in zip(SAVES, SAVED_VALUES):
        cpu.reg_write(reg, value)
    for reg, value in ((UC_X86_REG_EAX, mode), (UC_X86_REG_EDX, width), (UC_X86_REG_EBX, height)):
        cpu.reg_write(reg, value)

    dimensions = ((0x2891db, 'B', mode), (0x287e90, 'I', width), (0x287e8c, 'I', height))
    setup = ((0x286ae0, 'I', 3 * height // 2), (0x286bac, 'i', -1),
             (0x1ed1a0, 'H', 0), (0x289150, 'H', 0), (0x2891da, 'B', 2),
             (0x286b88, 'I', 0), (0x286b8c, 'I', 65536), (0x2891d9, 'B', 0),
             (0x140c2, 'B', 0), (0x28912a, 'H', 0), (0x289122, 'h', -1))

    def read(offset, fmt):
        count = struct.calcsize('<' + fmt)
        return struct.unpack('<' + fmt, cpu.mem_read(DS + offset, count))[0]

    for offset, fmt, _ in (*dimensions, *setup):
        cpu.mem_write(DS + offset, b'\xa5' * struct.calcsize('<' + fmt))

    calls = []
    allocation_count = 0

    def intercept(emu, address, size, data):
        nonlocal allocation_count
        calls.append(address)
        sp = emu.reg_read(UC_X86_REG_ESP)
        if address == EXIT:
            if emu.reg_read(UC_X86_REG_EAX) != 0:
                raise AssertionError('Unexpected allocator failure exit status')
            emu.emu_stop()
            return
        result = 0
        if address == BACKEND:
            if any(read(off, fmt) != value for off, fmt, value in dimensions):
                raise AssertionError('Video dimensions are not visible to the backend')
        elif address == MALLOC:
            allocation_count += 1
            if emu.reg_read(UC_X86_REG_EAX) != height * 12 or allocation_count > 2:
                raise AssertionError('Unexpected horizon allocator request')
            result = 0 if fail_at == allocation_count else ALLOCATIONS[allocation_count - 1]
        elif address == DIAGNOSTIC:
            arg, = struct.unpack('<I', emu.mem_read(sp + 4, 4))
            if arg != DS + 0x1af9:
                raise AssertionError('Unexpected out-of-memory diagnostic pointer')
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_EAX, result)
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    for address in (BACKEND, MALLOC, DIAGNOSTIC, EXIT):
        cpu.hook_add(UC_HOOK_CODE, intercept, begin=address, end=address)
    cpu.emu_start(ENTRY, STOP, count=150)
    if struct.unpack('<4I', cpu.mem_read(STACK - 16, 16)) != SAVED_VALUES:
        raise AssertionError('Video initialization altered the saved register layout')
    if fail_at:
        if calls != [BACKEND] + [MALLOC] * fail_at + [DIAGNOSTIC, EXIT]:
            raise AssertionError(f'Incorrect allocator failure path: {calls!r}')
        offset = (0x286ac4, 0x286aec)[fail_at - 1]
        if read(offset, 'I') != 0 or cpu.reg_read(UC_X86_REG_EIP) != EXIT:
            raise AssertionError('Failure path did not record the failed allocation and exit')
        return

    if calls != [BACKEND, MALLOC, MALLOC]:
        raise AssertionError(f'Unexpected initialization calls: {calls!r}')
    if (cpu.reg_read(UC_X86_REG_EIP), cpu.reg_read(UC_X86_REG_EAX),
            cpu.reg_read(UC_X86_REG_ESP)) != (STOP, 0, STACK - 16):
        raise AssertionError('Palette loop did not receive index zero and the original frame')
    for offset, fmt, expected in (*dimensions, *setup, (0x286ac4, 'I', ALLOCATIONS[0]),
                                  (0x286aec, 'I', ALLOCATIONS[1])):
        if read(offset, fmt) != expected:
            raise AssertionError(f'Video setup field at {offset:#x} differs')


def check_display_reset(memory, mode, fill):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(DS + 0x2891db, bytes((mode,)))
    stereo_fields = (0x286b24, 0x286b40, 0x286b44, 0x14014)
    for offset in stereo_fields:
        cpu.mem_write(DS + offset, b'\xa5' * 4)
    buffers = ((0x1ffca0, 4096 * 4), (0x1ec6a0, 32 * 4),
               (0x1ecfa0, 128 * 4), (0x1ec920, 256 * 4))
    before_call = ((0x2891d8, 'B', 0), (0x28913a, 'h', 0),
                   (0x289142, 'h', -1), (0x28913c, 'h', -1))
    after_call = ((0x286ba8, 'I', 512), (0x286ba0, 'I', 512),
                  (0x14004, 'I', 0), (0x14003, 'B', 0))
    for offset, count in buffers:
        cpu.mem_write(DS + offset - 1, b'\xa5' + bytes((fill,)) * count + b'\x5a')
    for offset, fmt, _ in (*before_call, *after_call):
        cpu.mem_write(DS + offset, bytes((fill,)) * struct.calcsize('<' + fmt))
    calls = []

    def check_fields(fields):
        for offset, fmt, expected in fields:
            actual, = struct.unpack('<' + fmt,
                                    cpu.mem_read(DS + offset, struct.calcsize('<' + fmt)))
            if actual != expected:
                raise AssertionError(f'Unexpected display reset field at {offset:#x}: {actual}')

    def intercept(emu, address, size, data):
        calls.append(address)
        check_fields(before_call)
        for offset, count in buffers:
            if emu.mem_read(DS + offset - 1, count + 2) != b'\xa5' + bytes(count) + b'\x5a':
                raise AssertionError(f'Display buffer at {offset:#x} or its guard differs')
        sp = emu.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    cpu.hook_add(UC_HOOK_CODE, intercept, begin=0x4c0b0, end=0x4c0b0)
    cpu.emu_start(0x4b150, 0x4b1d1, count=6000)
    if (calls != [0x4c0b0] or cpu.reg_read(UC_X86_REG_EIP) != 0x4b1d1
            or cpu.reg_read(UC_X86_REG_EAX) & 255 != mode
            or cpu.reg_read(UC_X86_REG_ESP) != STACK):
        raise AssertionError('Backend dispatch did not receive the original mode and stack')
    check_fields(after_call)


def check_palette_lookup(memory, first):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    base = DS + 0x203ca0
    cpu.mem_write(base - 4, b'\xa5' * (256 * 4 + 8))
    cpu.reg_write(UC_X86_REG_EAX, first)
    cpu.reg_write(UC_X86_REG_EBX, 0x12345678)
    cpu.reg_write(UC_X86_REG_ECX, 0x89abcdef)
    cpu.reg_write(UC_X86_REG_EDX, 0x76543210)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(0x4b13d, 0x4b150, count=2000)
    if cpu.reg_read(UC_X86_REG_EIP) != 0x4b150:
        raise AssertionError('Palette lookup did not reach the display reset')
    expected = b'\xa5' * (4 + first * 4) + bytes((256 - first) * 4) + b'\xa5' * 4
    if cpu.mem_read(base - 4, len(expected)) != expected:
        raise AssertionError('Palette lookup contents or boundary guards differ')
    if (cpu.reg_read(UC_X86_REG_EAX), cpu.reg_read(UC_X86_REG_EBX),
            cpu.reg_read(UC_X86_REG_ECX), cpu.reg_read(UC_X86_REG_EDX),
            cpu.reg_read(UC_X86_REG_ESP)) != (256, 0x12345678,
                0 if first < 256 else 0x89abcdef, 0x76543210, STACK):
        raise AssertionError('Palette lookup register or stack handoff differs')


def check_backend_geometry(memory, pixels, chain):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.reg_write(UC_X86_REG_EAX, pixels)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(DS + 0x14003, bytes((chain,)))
    cpu.emu_start(0x4b1f3, 0x4b232, count=30)
    if cpu.reg_read(UC_X86_REG_EIP) != 0x4b232:
        raise AssertionError('Backend geometry did not reach the allocation decision')
    size = ((pixels >> 2) + 255) & ~255
    pages, remainder = divmod(65536, size)
    expected = ((0x286b48, size), (0x286b4c, 0xa0000), (0x14004, pages))
    for offset, value in expected:
        if cpu.mem_read(DS + offset, 4) != struct.pack('<I', value):
            raise AssertionError('Backend geometry output differs')
    if cpu.mem_read(DS + 0x14003, 1) != bytes((1 if pages >= 2 else chain,)):
        raise AssertionError('Backend geometry chain flag differs')
    if tuple(cpu.reg_read(reg) for reg in (UC_X86_REG_EAX, UC_X86_REG_EBX,
                                         UC_X86_REG_EDX, UC_X86_REG_ESP)) != (pages, size, remainder, STACK):
        raise AssertionError('Backend geometry register handoff differs')
    if bool(cpu.reg_read(UC_X86_REG_EFLAGS) & 0x40) != (pages == 1):
        raise AssertionError('Backend geometry zero flag differs')


def check_backend_allocation(memory, mode, fail, width=320, height=480):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    allocation = 0 if fail else 0x301000
    for offset, value in ((0x287e90, width), (0x287e8c, height), (0x286b74, 0x12345678)):
        cpu.mem_write(DS + offset, struct.pack('<I', value))
    cpu.mem_write(DS + 0x2891db, bytes((mode,)))
    stereo_fields = (0x286b24, 0x286b40, 0x286b44, 0x14014)
    for offset in stereo_fields:
        cpu.mem_write(DS + offset, b'\xa5' * 4)
    cpu.reg_write(UC_X86_REG_EAX, mode)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    requests, diagnostics = [], []
    messages = {0: 0x1b08, 1: 0x1b31, 2: 0x1b5a, 6: 0x1b83, 7: 0x1bac}

    def intercept(emu, address, size, data):
        sp = emu.reg_read(UC_X86_REG_ESP)
        if address == EXIT:
            if emu.reg_read(UC_X86_REG_EAX) != 0:
                raise AssertionError('Allocation error exit status differs')
            emu.emu_stop()
            return
        if address == MALLOC:
            requests.append(emu.reg_read(UC_X86_REG_EAX))
            emu.reg_write(UC_X86_REG_EAX, allocation)
        else:
            diagnostics.append(struct.unpack('<I', emu.mem_read(sp + 4, 4))[0])
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    for address in (MALLOC, DIAGNOSTIC, EXIT):
        cpu.hook_add(UC_HOOK_CODE, intercept, begin=address, end=address)
    cpu.emu_start(0x4b1d1, 0x4b386, count=150)
    expected_request = {0: width * height, 1: (width + 8) * height,
                        2: width * height, 6: 65536, 7: 131072}.get(mode)
    if mode == 0 and 65536 // (((width * height >> 2) + 255) & ~255) != 1:
        expected_request = None
    if requests != ([] if expected_request is None else [expected_request]):
        raise AssertionError('Backend allocator request differs')
    if fail:
        if diagnostics != [DS + messages[mode]] or cpu.reg_read(UC_X86_REG_EIP) != EXIT:
            raise AssertionError('Backend allocation failure path differs')
        return
    expected_frame = (allocation if expected_request is not None else
                      0xa0000 if 3 <= mode <= 5 else 0x12345678)
    if (cpu.mem_read(DS + 0x286b74, 4) != struct.pack('<I', expected_frame)
            or diagnostics or cpu.reg_read(UC_X86_REG_EIP) != 0x4b386
            or cpu.reg_read(UC_X86_REG_ESP) != STACK):
        raise AssertionError('Backend allocation success handoff differs')
    expected_stereo = (mode, 32768, 32, 1) if mode in (6, 7) else (0xa5a5a5a5,) * 4
    if (tuple(struct.unpack('<I', cpu.mem_read(DS + offset, 4))[0]
              for offset in stereo_fields) != expected_stereo
            or cpu.mem_read(DS + 0x2891db, 1) != bytes((2 if mode in (6, 7) else mode,))):
        raise AssertionError('Stereo state width, pixel, mode or page-flip fields differ')


def check_video_return(memory, values):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    stop = 0x90000
    cpu.mem_write(STACK, struct.pack('<5I', *values, stop))
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    calls = []

    def intercept(emu, address, size, data):
        calls.append(address)
        sp = emu.reg_read(UC_X86_REG_ESP)
        if sp != STACK - 4:
            raise AssertionError('Video finish call stack differs')
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    cpu.hook_add(UC_HOOK_CODE, intercept, begin=0x4a367, end=0x4a367)
    cpu.emu_start(0x4b386, stop, count=20)
    if (cpu.reg_read(UC_X86_REG_EIP) != stop or calls != [0x4a367] or tuple(cpu.reg_read(reg) for reg in SAVES) != values
            or cpu.reg_read(UC_X86_REG_ESP) != STACK + 20):
        raise AssertionError('Video return register or stack restoration differs')


def mutate_context_byte(blob, target):
    """Change one CODE LEDATA byte while preserving its OMF checksum."""
    mutant = bytearray(blob)
    offset = 0
    while offset < len(mutant):
        kind = mutant[offset]
        length = int.from_bytes(mutant[offset + 1:offset + 3], 'little')
        end = offset + 3 + length
        if kind in (0xa0, 0xa1):
            payload = mutant[offset + 3:end - 1]
            segment, cursor = index(payload, 0)
            width = 4 if kind & 1 else 2
            start = int.from_bytes(payload[cursor:cursor + width], 'little')
            data = offset + 3 + cursor + width
            if segment == 1 and start <= target < start + end - 1 - data:
                mutant[data + target - start] ^= 1
                mutant[end - 1] = (-sum(mutant[offset:end - 1])) & 255
                return bytes(mutant)
        offset = end
    raise AssertionError('Context mutation did not find its LEDATA byte')


def check_context_guards(blob):
    bind_display_reset(blob, ADDRESS)
    # Check a table entry, an unlinked stereo instruction and a selected branch.
    for target in (0, 0x2d0, 0x203):
        try:
            bind_display_reset(mutate_context_byte(blob, target), ADDRESS)
        except ValueError as exc:
            if 'Display context code digest differs' not in str(exc):
                raise AssertionError('Context mutation did not reach the digest guard') from exc
        else:
            raise AssertionError('Display context accepted a changed compiler byte')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--object', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    check_context_guards(args.object.read_bytes())
    memory = image(blob)
    for case in CASES:
        check(memory, *case)
    display_cases = ((0, 0x33), (7, 0x94), (255, 0xfe))
    for mode, fill in display_cases:
        check_display_reset(memory, mode, fill)
    for first in (0, 255, 256):
        check_palette_lookup(memory, first)
    for offset in (0x4b13f, 0x4b145):
        mutant = bytearray(memory)
        mutant[offset] ^= 1
        try:
            check_palette_lookup(bytes(mutant), 0)
        except AssertionError:
            pass
        else:
            raise AssertionError('Palette lookup oracle accepted a code or pointer mutation')
    for pixels in (320 * 200, 320 * 350, 640 * 480, 1024 * 1024):
        for chain in (0, 1):
            check_backend_geometry(memory, pixels, chain)
    for offset in (0x4b1f5, 0x4b21b):
        mutant = bytearray(memory)
        mutant[offset] ^= 1
        try:
            check_backend_geometry(bytes(mutant), 320 * 200, 0)
        except AssertionError:
            pass
        else:
            raise AssertionError('Geometry oracle accepted a code or pointer mutation')
    for mode in range(9):
        check_backend_allocation(memory, mode, False)
    for width, height in ((320, 200), (1024, 1024)):
        check_backend_allocation(memory, 0, False, width, height)
    for mode in (0, 1, 2, 6, 7):
        check_backend_allocation(memory, mode, True)
    for offset, mode in ((0x4b24a, 0), (0x4b2ba, 6)):
        mutant = bytearray(memory)
        mutant[offset] ^= 1
        try:
            check_backend_allocation(bytes(mutant), mode, False)
        except AssertionError:
            pass
        else:
            raise AssertionError('Allocation oracle accepted a pointer or request mutation')
    for values in (SAVED_VALUES, (0xffffffff, 0x12345678, 0x89abcdef, 0)):
        check_video_return(memory, values)
    mutant = bytearray(memory)
    mutant[0x4b38b] = 0x5b
    try:
        check_video_return(bytes(mutant), SAVED_VALUES)
    except AssertionError:
        pass
    else:
        raise AssertionError('Video return oracle accepted a POP register mutation')
    result = {'context_mutation_controls': 3, 'video_return_cases': 2, 'video_return_mutation_controls': 1, 'backend_allocation_mutation_controls': 2, 'backend_allocation_cases': 16, 'backend_geometry_mutation_controls': 2, 'backend_geometry_cases': 8, 'palette_lookup_mutation_controls': 2, 'palette_lookup_cases': 3, 'status': 'PASS', 'cases': len(CASES) + len(display_cases) + 29,
              'allocator_failure_cases': 2, 'display_reset_cases': len(display_cases)}
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
