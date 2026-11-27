"""Verify fade completion, tint priority, clock updates, and VGA palette calls."""
import argparse
from pathlib import Path
from struct import pack, unpack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import (
    UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_EBX, UC_X86_REG_ECX,
    UC_X86_REG_EDI, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESI, UC_X86_REG_ESP,
)

from check_start_hook import image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations

SYMBOL = 'update_palette_fade_'
ENTRY, SIZE, BASE = 0x366f2, 574, 0x80000
STACK, STOP = 0x3e0000, 0x3ff000
SCALE, WAIT, WRITE, RESTORE = 0x365b6, 0x40b82, 0x40b99, 0x36587
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)
OFFSET = {
    '_fade_level': 0x12d14, '_qsetmode': 0x140ba, '_totalclock': 0x287e88,
    '_palette_fade_up': 0x173d14, '_palette_fade_down': 0x173d18,
    '_palette_tint_a_ticks': 0x173d1c, '_palette_tint_b_ticks': 0x173d28, '_palette_tint_c_ticks': 0x173d20,
    '_palette_fade_step': 0x173d24, '_palette_fade_last_tick': 0x173d2c,
    '_palette_tint_a': 0x171614, '_palette_tint_b': 0x172214, '_palette_tint_c': 0x173114,
    '_brightness_palette': 0x27c0a0,
}
DATA = {name: BASE + offset for name, offset in OFFSET.items()}
CALLBACKS = {
    'scale_fade_palette_': SCALE, 'wait_vertical_retrace_': WAIT,
    'write_vga_palette_': WRITE, 'palette_fade_shared_return_': RESTORE,
    'palette_fade_changed_address_': 0x367ab,
}
STATE_FIELDS = ('_palette_fade_up', '_palette_fade_down', '_fade_level',
                '_palette_tint_a_ticks', '_palette_tint_b_ticks', '_palette_tint_c_ticks')


def exercise(body, restore, previous, mode):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0x10000, 0x3f0000)
    cpu.mem_write(ENTRY, body)
    cpu.mem_write(RESTORE, restore)
    for field, value in zip(STATE_FIELDS, previous):
        cpu.mem_write(DATA[field], pack('<i', value))
    for field, value in (('_qsetmode', mode), ('_totalclock', 100), ('_palette_fade_last_tick', 90),
                         ('_palette_fade_step', 3)):
        cpu.mem_write(DATA[field], pack('<i', value))

    seen = []

    def hook(machine, address, _size, _data):
        if address == SCALE:
            seen.append(('scale', machine.reg_read(UC_X86_REG_EAX)))
        elif address == WAIT:
            seen.append(('wait', machine.reg_read(UC_X86_REG_ECX)))
        elif address == WRITE:
            seen.append(('write', machine.reg_read(UC_X86_REG_ESI)))

    for address in (SCALE, WAIT, WRITE):
        cpu.mem_write(address, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, hook, begin=address, end=address)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP) + b'\xa5' * 16)
    for i, register in enumerate(SAVED, 1):
        cpu.reg_write(register, 0x77770000 | i)
    cpu.emu_start(ENTRY, STOP, count=400)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert cpu.mem_read(STACK + 4, 16) == b'\xa5' * 16
    for i, register in enumerate(SAVED, 1):
        assert cpu.reg_read(register) == 0x77770000 | i
    assert unpack('<i', cpu.mem_read(DATA['_palette_fade_last_tick'], 4))[0] == 100
    return tuple(unpack('<i', cpu.mem_read(DATA[field], 4))[0] for field in STATE_FIELDS), seen


def check(executable, obj):
    code, refs = bind_leaf_details(obj, SYMBOL, OFFSET, address=ENTRY, functions=CALLBACKS)
    raw = ENTRY + 0x25600
    assert len(refs) == 41 and len(code) == SIZE and code == executable[raw:raw + SIZE]
    verify_leaf_relocations(code, refs, read_le_fixups(executable)['pointers'], ENTRY)
    relocated, _ = bind_leaf_details(obj, SYMBOL, DATA, address=ENTRY, functions=CALLBACKS)
    mapped = image(executable)
    original = bytes(mapped[ENTRY:ENTRY + SIZE])
    restore = bytes(mapped[RESTORE:RESTORE + 7])

    def display(tint, row=0):
        palette = DATA['_brightness_palette' if tint is None else '_palette_tint_' + tint]
        return [('wait', 1), ('write', palette + 768 * row)]

    normal = display(None)
    cases = (
        ((0, 0, 40, 0, 0, 0), 200, (0, 0, 40, 0, 0, 0), []),
        ((0, 1, 20, 0, 0, 0), 200, (0, 1, 0, 0, 0, 0), [('scale', 20)] + normal),
        ((0, 1, 0, 0, 0, 0), 200, (0, 0, 0, 0, 0, 0), [('scale', 0)] + normal),
        ((1, 0, 240, 0, 0, 0), 200, (1, 0, 255, 0, 0, 0), [('scale', 240)] + normal),
        ((1, 0, 255, 0, 0, 0), 200, (0, 0, 255, 0, 0, 0), [('scale', 255)] + normal),
        ((0, 0, 80, 80, 60, 40), 200, (0, 0, 80, 70, 50, 30), display('a', 3)),
        ((0, 0, 80, 5, 24, 90), 200, (0, 0, 80, 0, 14, 80), display('b', 1)),
        ((0, 0, 80, 0, 0, 39), 200, (0, 0, 80, 0, 0, 29), display('c', 2)),
        ((0, 0, 80, 5, 0, 0), 200, (0, 0, 80, 0, 0, 0), normal),
        ((0, 0, 80, 20, 20, 20), 350, (0, 0, 80, 10, 10, 10), []),
    )
    for body in (original, relocated):
        for prior, mode, state, calls in cases:
            result = exercise(body, restore, prior, mode)
            assert result == (state, calls), (prior, mode, result, state, calls)
    print(f'PASS: {SIZE} exact bytes, {len(refs)} LE relocations, {len(cases)} palette scenarios for original and C')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    check(args.executable.read_bytes(), args.object.read_bytes())
