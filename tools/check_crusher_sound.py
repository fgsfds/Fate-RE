"""Check crusher sound dispatch and wrapped distance arithmetic."""
import argparse
from pathlib import Path
from struct import pack

from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32, Uc
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_EIP, UC_X86_REG_ESP

from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import DATA_OFFSETS, FUNCTION_ADDRESSES, LEAVES, bind_leaf_details, verify_leaf_relocations

SYMBOL = 'play_crusher_sound_'
STACK, STOP, POSITION = 0x3ff000, 0x3fff00, 0x3fc000
MASK = 0xffffffff


def magnitude(delta):
    delta &= MASK
    return min(delta, (-delta) & MASK)


def exercise(memory, body, entry):
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(entry, body)
    sound = FUNCTION_ADDRESSES['play_sound_']
    cpu.mem_write(sound, b'\xc3')
    calls = []
    cpu.hook_add(UC_HOOK_CODE, lambda uc, *_: calls.append(tuple(
        uc.reg_read(r) for r in (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
    )), begin=sound, end=sound)
    def put(address, *words):
        cpu.mem_write(address, pack('<' + 'I' * len(words), *(word & MASK for word in words)))

    cases = 0
    for mode in (0, 1):
        for px, py, x, y in (
            (0, 0, 0, 0), (0, 0, 8673, 0), (0, 0, -8674, 0),
            (0, 0, 4674, -4000), (-200, 100, 3800, 4773),
            (0, 0, 0x80000000, 0), (0, 0, 0x80000000, 0x80000000),
            (0, 0, 0x7fffffff, 0x7fffffff), (0xffffffff, 0, 1, -8672),
        ):
            put(DS + DATA_OFFSETS['_player_x'], px)
            put(DS + DATA_OFFSETS['_player_y'], py)
            put(POSITION + 41, x, y)
            put(STACK, STOP)
            calls.clear()
            cpu.reg_write(UC_X86_REG_EAX, POSITION)
            cpu.reg_write(UC_X86_REG_EDX, mode)
            cpu.reg_write(UC_X86_REG_ESP, STACK)
            cpu.emu_start(entry, STOP, count=200)
            assert cpu.reg_read(UC_X86_REG_EIP) == STOP
            assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
            total = (magnitude(px - x) + magnitude(py - y)) & MASK
            signed = total - (1 << 32) if total >> 31 else total
            expected = [(4, x & MASK, y & MASK, 0)] if signed < 8674 else []
            assert calls == expected, (mode, px, py, x, y, calls, expected)
            cases += 1
    return cases


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    args = parser.parse_args()
    exe, obj = args.executable.read_bytes(), args.object.read_bytes()
    raw, size = LEAVES[SYMBOL]
    entry = raw - 0x25600
    code, refs = bind_leaf_details(obj, SYMBOL, DATA_OFFSETS, address=entry, functions=FUNCTION_ADDRESSES)
    assert len(code) == size and code == exe[raw:raw + size]
    verify_leaf_relocations(code, refs, read_le_fixups(exe)['pointers'], entry)
    loaded = {name: DS + offset for name, offset in DATA_OFFSETS.items()}
    restored, _ = bind_leaf_details(obj, SYMBOL, loaded, address=entry, functions=FUNCTION_ADDRESSES)
    memory = image(exe)
    count = exercise(memory, memory[entry:entry + size], entry)
    assert exercise(memory, restored, entry) == count
    print(f'PASS: {size} bytes, {len(refs)} LE relocations, {count} original and {count} restored crusher sound cases')


if __name__ == '__main__':
    main()
