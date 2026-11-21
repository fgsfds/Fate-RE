"""Exercise the menu-loop machine code with deterministic frame and input stubs."""
import argparse
from pathlib import Path
from struct import pack, unpack

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, bind_leaf_details, verify_leaf_relocations
from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDI,
    UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

ADDRESS, SIZE, ENTRY_SIZE = 0x3963b, 283, 17
RESET, FRAME, UPDATE, PREVIEW, TAIL = 0x36246, 0x39511, 0x39235, 0x39cfa, 0x386cd
DATA_BASE = 0x80000
STATE, PREVIEW_ENABLED = 0x12dd4, 0x1314d
DEMO_ROWS, SAVE_ROWS, ACTIVE_ROWS = 0x17455c, 0x173fc0, 0x174048
SELECTION, STORAGE, ROW_COUNT, ENABLED_ROWS = 0x1740f0, 0x1740f4, 0x1740f8, 0x1740fc
SELECTION_PTR, NORMAL_ROWS, TITLE = 0x310000, 0x320000, 0x322000
STACK, RETURN = 0x3f0000, 0x3ff000

VOLATILE_ARGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
SAVED_REGS = (UC_X86_REG_EBP, UC_X86_REG_EDI, UC_X86_REG_ESI)


def exercise(body, shared_tail, rows, start, updates):
    engine = Uc(UC_ARCH_X86, UC_MODE_32)
    engine.mem_map(0, 0x400000)
    engine.mem_write(ADDRESS, bytes(body))
    engine.mem_write(TAIL, bytes(shared_tail))
    for target, instruction in ((RESET, b'\xc3'), (FRAME, b'\xc2\x04\x00'),
                                (UPDATE, b'\xc3'), (PREVIEW, b'\xc3')):
        engine.mem_write(target, instruction)

    def read_dword(address):
        return unpack('<I', engine.mem_read(address, 4))[0]

    def write_data(offset, value):
        engine.mem_write(DATA_BASE + offset, pack('<I', value & 0xffffffff))

    entry_pointers = (0x330000, 0x330100, 0x330200)
    room_count = len(entry_pointers)
    for index, entry in enumerate(entry_pointers):
        engine.mem_write(entry, bytes([int(index != 1)]))
        engine.mem_write(rows + index * 4, pack('<I', entry))
    # Enter with enabled rows left over from a previous menu.
    write_data(ENABLED_ROWS, 0xffffffff)
    engine.mem_write(SELECTION_PTR, pack('<I', start))
    events = []
    input_events = iter(updates)

    def hook(cpu, address, _size, _userdata):
        if address == RESET:
            assert read_dword(DATA_BASE + STORAGE) == SELECTION_PTR
            assert read_dword(DATA_BASE + SELECTION) == start
            assert read_dword(DATA_BASE + ROW_COUNT) == room_count
            assert read_dword(DATA_BASE + ENABLED_ROWS) == 0b101
            assert unpack('<3I', cpu.mem_read(DATA_BASE + ACTIVE_ROWS, 12)) == entry_pointers
            events.append(('reset',))
            cpu.reg_write(UC_X86_REG_EAX, 0x11111111)
        elif address == FRAME:
            selection, count, tile, title = (cpu.reg_read(reg) for reg in VOLATILE_ARGS)
            assert count == room_count and title == TITLE
            assert read_dword(cpu.reg_read(UC_X86_REG_ESP) + 4) == rows
            events.append(('frame', selection, tile))
            for reg in VOLATILE_ARGS:
                cpu.reg_write(reg, 0x22222222)
        elif address == UPDATE:
            selection, state, preview_enabled = next(input_events)
            write_data(SELECTION, selection)
            write_data(STATE, state)
            cpu.mem_write(DATA_BASE + PREVIEW_ENABLED, bytes([preview_enabled]))
            cpu.reg_write(UC_X86_REG_EAX, 0x33333333)
        elif address == PREVIEW:
            events.append(('preview', cpu.reg_read(UC_X86_REG_EAX)))
            cpu.reg_write(UC_X86_REG_EAX, 0x44444444)

    for target in (RESET, FRAME, UPDATE, PREVIEW):
        engine.hook_add(UC_HOOK_CODE, hook, begin=target, end=target)

    incoming = dict(zip(SAVED_REGS, (0x9abc0001, 0x9abc0002, 0x9abc0003)))
    incoming.update(zip(VOLATILE_ARGS, (SELECTION_PTR, room_count, 0xabcdfffe, TITLE)))
    incoming[UC_X86_REG_ESP] = STACK
    for reg, value in incoming.items():
        engine.reg_write(reg, value)
    engine.mem_write(STACK, pack('<II', RETURN, rows) + b'\xa5' * 16)
    engine.emu_start(ADDRESS, RETURN, count=2000)
    assert engine.reg_read(UC_X86_REG_EIP) == RETURN
    assert engine.reg_read(UC_X86_REG_ESP) == STACK + 8
    assert engine.mem_read(STACK + 8, 16) == b'\xa5' * 16
    assert all(engine.reg_read(reg) == incoming[reg] for reg in SAVED_REGS)
    assert next(input_events, None) is None
    return events, engine.reg_read(UC_X86_REG_EAX), read_dword(DATA_BASE + STATE)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('entry', type=Path, help='assembled 17-byte menu entry')
    args = parser.parse_args()

    executable = args.executable.read_bytes()
    obj = args.object.read_bytes()
    unrelocated, refs = bind_leaf_details(
        obj, 'run_menu_loop_', DATA_OFFSETS, address=ADDRESS + ENTRY_SIZE, functions=FUNCTION_ADDRESSES)
    verify_leaf_relocations(unrelocated, refs, read_le_fixups(executable)['pointers'], ADDRESS + ENTRY_SIZE)
    entry = args.entry.read_bytes()
    assert len(entry) == ENTRY_SIZE
    assert len(unrelocated) == SIZE - ENTRY_SIZE and len(refs) == 19
    assert entry + unrelocated == executable[0x25600 + ADDRESS:0x25600 + ADDRESS + SIZE]
    compiled, _ = bind_leaf_details(
        obj, 'run_menu_loop_', {name: DATA_BASE + offset for name, offset in DATA_OFFSETS.items()},
        address=ADDRESS + ENTRY_SIZE, functions=FUNCTION_ADDRESSES)
    compiled = entry + compiled
    linked = image(executable)
    cases = (
        (NORMAL_ROWS, 2, ((1, -1, 1),),
         ([('reset',), ('frame', 2, 0xfffffffe)], 0, 0)),
        (DATA_BASE + DEMO_ROWS, 0, ((1, 1, 0), (2, 1, 0), (2, 2, 0)),
         ([('reset',), ('frame', 0, 0x874), ('frame', 1, 0x875), ('frame', 2, 0x875)], 1, 2)),
        (DATA_BASE + SAVE_ROWS, 0, ((1, 1, 1), (1, 1, 1), (2, 1, 2), (2, 1, 1), (0, -1, 1)),
         ([('reset',), ('frame', 0, 0xfffffffe), ('preview', 1), ('frame', 1, 0xfffffffe),
           ('frame', 1, 0xfffffffe), ('frame', 2, 0xfffffffe), ('frame', 2, 0xfffffffe), ('preview', 0)],
          0, 0)),
    )
    for rows, initial, updates, expected in cases:
        for body in (linked[ADDRESS:ADDRESS + SIZE], compiled):
            assert exercise(body, linked[TAIL:TAIL + 6], rows, initial, updates) == expected
    print(f'{len(cases)} menu-loop scenarios and {len(refs)} LE relocations passed.')


if __name__ == '__main__':
    main()
