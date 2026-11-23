"""Check encounter trigger activation, sector clearing and clock advancement."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import struct
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from check_start_hook import DS, image
from compare_exe import TARGET_SHA256
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAF_CODE_SLICES, bind_leaf_details

ENTRY, PREPARE, LATCH, SOUND, STACK = 0x1df5b, 0x1e070, 0x1e1b0, 0x34f79, 0x3fe000
CLOCK, ADVANCE, ROTATING = DS + 0x12814, DS + 0x229b, DS + 0x7dec0
SPRITES, TRIGGERS, SECTORS = DS + 0x2040a0, DS + 0x77124, DS + 0x27c3a0
REGISTERS = (UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
             UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
VALID = (0x203, -10000, -8000)
TRIGGER_CASES = [(), (VALID,), ((0, -10000, -8000),), ((0x204, -10000, -8000),)]
TRIGGER_CASES += [((0x203, x, -8000),) for x in (-12291, -12290, -12289, -5124, -5123, -5122)]
TRIGGER_CASES += [((0x203, -10000, y),) for y in (-11532, -11531, -11530, -4615, -4614, -4613)]
TRIGGER_CASES += [(VALID, (0, 0, 0), VALID), ((0, 0, 0), VALID)]


def word(value):
    return ((value + 32768) & 65535) - 32768


def execute(memory, clock, advance, triggers, tags):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    for reg, value in zip(REGISTERS, (0x10203040, 0x21314151, 0x32425262, 0x43536373,
                                     0x54647484, 0x65758595, 0x768696a6)):
        cpu.reg_write(reg, value)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    for address, value in ((CLOCK, clock), (ADVANCE, advance), (ROTATING, 0x1234),
                           (DS + 0x3be6, len(triggers)), (DS + 0x289154, len(tags))):
        cpu.mem_write(address - 1, b'\xa5' + struct.pack('<h', value) + b'\x5a')
    sprite_records = []
    for index, (tag, x, y) in enumerate(triggers):
        record = bytearray(b'\x33' * 44)
        struct.pack_into('<ii', record, 0, x, y)
        struct.pack_into('<h', record, 40, tag)
        sprite_records.append(bytes(record))
        cpu.mem_write(SPRITES + index * 44, bytes(record))
        cpu.mem_write(TRIGGERS + (index + 1) * 4, struct.pack('<hh', index, 0))
    cpu.mem_write(SECTORS - 40, b'\xa5' * ((len(tags) + 2) * 40))
    for index, tag in enumerate(tags):
        cpu.mem_write(SECTORS + index * 40 + 34, struct.pack('<h', tag))
    calls = []

    def intercept(emu, address, size, data):
        if address in (PREPARE, LATCH):
            emu.emu_stop()
            return
        calls.append(tuple(emu.reg_read(reg) for reg in REGISTERS[:4]))
        # The pinned sound routine preserves ESI/EDI/EBP. Poison only its clobbers.
        for reg, value in zip(REGISTERS[:4], (0xdead1234, 0xbeef2345, 0xcafe3456, 0xabcd4567)):
            emu.reg_write(reg, value)
        sp = emu.reg_read(UC_X86_REG_ESP)
        ret, = struct.unpack('<I', emu.mem_read(sp, 4))
        emu.reg_write(UC_X86_REG_ESP, sp + 4)
        emu.reg_write(UC_X86_REG_EIP, ret)

    for address in (PREPARE, LATCH, SOUND):
        cpu.hook_add(UC_HOOK_CODE, intercept, begin=address, end=address)
    cpu.emu_start(ENTRY, PREPARE + 1, count=2000)
    activated = [item for item in triggers if item[0] == 0x203
                 and -12290 < item[1] < -5123 and -11531 < item[2] < -4614] if clock == 0 else []
    current = 1 if activated else clock
    prepares = clock != 10 and current > 0
    expected_clock = word(current + 1) if prepares and advance else current
    if cpu.mem_read(CLOCK - 1, 4) != b'\xa5' + struct.pack('<h', expected_clock) + b'\x5a':
        raise AssertionError('Encounter clock or boundary guards differ')
    expected_rotating = 0 if activated else 0x1234
    if cpu.mem_read(ROTATING - 1, 4) != b'\xa5' + struct.pack('<h', expected_rotating) + b'\x5a':
        raise AssertionError('Rotating sector count or boundary guards differ')
    expected_calls = [(sound, 0, 0, 0) for _ in activated for sound in (0x88, 0x87)]
    if calls != expected_calls:
        raise AssertionError('Encounter sound arguments or call count differ')
    expected_sectors = bytearray(b'\xa5' * ((len(tags) + 2) * 40))
    for index, tag in enumerate(tags):
        struct.pack_into('<h', expected_sectors, (index + 1) * 40 + 34,
                         0 if activated and tag == 14 else tag)
    sectors = bytes(cpu.mem_read(SECTORS - 40, len(expected_sectors)))
    if sectors != bytes(expected_sectors):
        raise AssertionError('Encounter sector tags or record guards differ')
    for index, record in enumerate(sprite_records):
        if cpu.mem_read(SPRITES + index * 44, 44) != record:
            raise AssertionError('Encounter trigger sprite changed')
    end = cpu.reg_read(UC_X86_REG_EIP)
    if (end != (PREPARE if prepares else LATCH) or cpu.reg_read(UC_X86_REG_ESP) != STACK
            or cpu.reg_read(UC_X86_REG_EBP) != 0x768696a6):
        raise AssertionError('Encounter spawn branch or frame handoff differs')
    return calls, expected_clock, sectors, tuple(cpu.reg_read(reg) for reg in REGISTERS), end


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    if sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unsupported executable SHA-256')
    memory = image(blob)
    # Bind the contiguous compiler order separately from the four production slices.
    alias = 'encounter_spawn_natural_'
    LEAF_CODE_SLICES[alias] = ('encounter_spawn_context_', 0x2c, 0x141, 1260)
    natural, _ = bind_leaf_details((args.build / 'encspawn.obj').read_bytes(), alias,
                                  {name: DS + value for name, value in DATA_OFFSETS.items()},
                                  address=ENTRY, functions=FUNCTION_ADDRESSES, code_bindings={})
    ordered = bytearray(memory)
    ordered[ENTRY:ENTRY + 277] = natural
    ordered = bytes(ordered)
    cases = 0
    for clock in (-1, 0, 1, 9, 10, 32767):
        for advance in (0, 1):
            for triggers in TRIGGER_CASES:
                for tags in ((), (14, 13, 14, -1, 0)):
                    expected = execute(memory, clock, advance, triggers, tags)
                    if execute(ordered, clock, advance, triggers, tags) != expected:
                        raise AssertionError('Natural compiler order differs from linked order')
                    cases += 1
    for offset, value in ((0x1df9b, 2), (0x1dff6, 0x86), (0x1e028, 13)):
        mutant = bytearray(memory)
        mutant[offset] = value
        try:
            execute(bytes(mutant), 0, 1, (VALID,), (14, 13))
        except AssertionError:
            pass
        else:
            raise AssertionError('Spawn oracle accepted a tag, sound, or sector mutation')
    report = dict(status='PASS', cases=cases, natural_order_cases=cases, mutation_controls=3)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
