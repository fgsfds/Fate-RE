"""Check palette fade dispatch and its transfers to neighboring routines."""

import argparse
from pathlib import Path
from struct import pack

from unicorn import Uc, UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations


STACK, STOP = 0x3ff000, 0x3fff00
INPUT = FUNCTION_ADDRESSES['presentation_input_']
START_IN = FUNCTION_ADDRESSES['start_fade_in_']
START_OUT = FUNCTION_ADDRESSES['start_fade_out_']
CHECK_OUT = FUNCTION_ADDRESSES['check_fade_out_']
RESET = 0x366a5
RETURN = 0x365ed


def exercise(memory, address, body, *, active, fade_out, input_result, finished=False):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(address, body)

    def put(name, value):
        cpu.mem_write(DS + DATA_OFFSETS[name], pack('<I', value))

    put('_fade_in_active', active)
    put('_fade_out_active', fade_out)
    put('_fade_speed', 9)
    calls = []

    def stub(engine, target, _size, _data):
        if target in (START_IN, START_OUT):
            calls.append((target, engine.reg_read(UC_X86_REG_EAX)))
            if target == START_IN and finished:
                put('_fade_in_active', 0)
        else:
            calls.append((target,))
            if target == INPUT:
                engine.reg_write(UC_X86_REG_EAX, input_result)

    assert memory[RETURN] == 0xc3
    for target in (START_IN, START_OUT, INPUT, CHECK_OUT, RESET, RETURN):
        cpu.mem_write(target, b'\xc3')
        cpu.hook_add(UC_HOOK_CODE, stub, begin=target, end=target)
    cpu.reg_write(UC_X86_REG_EAX, 17)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.mem_write(STACK, pack('<I', STOP))
    cpu.emu_start(address, STOP, count=100)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    return calls


CASES = (
    ('run_palette_fade_', dict(active=0, fade_out=0, input_result=0), [(RETURN,)]),
    ('run_palette_fade_', dict(active=1, fade_out=0, input_result=0), [(START_IN, 9), (INPUT,), (CHECK_OUT,)]),
    ('run_palette_fade_', dict(active=1, fade_out=1, input_result=1), [(START_IN, 9), (INPUT,), (START_OUT, 255)]),
    ('run_palette_fade_', dict(active=1, fade_out=0, input_result=1), [(START_IN, 9), (INPUT,), (START_IN, 255)]),
    ('run_palette_fade_', dict(active=1, fade_out=0, input_result=1, finished=True), [(START_IN, 9), (INPUT,), (RETURN,)]),
    ('palette_fade_out_entry_', dict(active=0, fade_out=0, input_result=0), [(START_OUT, 17), (RESET,)]),
)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    executable, obj = args.executable.read_bytes(), args.object.read_bytes()
    memory = image(executable)
    pointers = read_le_fixups(executable)['pointers']
    relocated = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    for symbol, case, expected in CASES:
        raw, size = LEAVES[symbol]
        address = raw - 0x25600
        ordinary, references = bind_leaf_details(obj, symbol, DATA_OFFSETS, address=address,
                                                  functions=FUNCTION_ADDRESSES)
        assert len(ordinary) == size and ordinary == executable[raw:raw + size]
        verify_leaf_relocations(ordinary, references, pointers, address)
        restored, _ = bind_leaf_details(obj, symbol, relocated, address=address,
                                        functions=FUNCTION_ADDRESSES)
        for body in (memory[address:address + size], restored):
            assert exercise(memory, address, body, **case) == expected
    print('PASS: 71 bytes, four LE relocations, six palette fade dispatch cases for original and C')
