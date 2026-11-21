"""Bounded main-menu differential fixture; this is not a DOS smoke test."""
import argparse
import hashlib
import itertools
import json
import struct
from pathlib import Path

from bind_main_menu_sections import BASE, DATA, FUNCTIONS, SECTIONS, bind_section
from check_start_hook import DS, image
from le_fixups import read_le_fixups
from verify_c_leaf import bind_leaf_details, verify_leaf_relocations, FUNCTION_ADDRESSES

ENTRY, SIZE = 0x3a148, 541
DS_SIZE = 3538944
STACK, STOP = 0x3ff000, 0x3fff00
PINNED_SHA256 = '61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f'

D = dict(DATA)
D['_main_menu_title'] = 0xd72
D['_loading_caption'] = 0xd7c
F = dict(FUNCTIONS)

from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *

NAMES = ('reset_menu_animation_clock', 'cache_menu_tiles', 'run_menu_loop',
         'run_options_menu', 'run_save_game_menu', 'run_load_game_menu',
         'confirm_menu_action', 'new_game_disabled', 'run_help_menu',
         'run_difficulty_menu', 'preload_game_tiles', 'nextpage',
         'rotatesprite', 'clearview', 'draw_menu_text')
CALLS = {F[name + '_']: name for name in NAMES}
ARGREGS = (UC_X86_REG_EAX, UC_X86_REG_EDX, UC_X86_REG_EBX, UC_X86_REG_ECX)
SAVED = (UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
         UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP)


def exercise(memory, body, case):
    game, active, choice, confirm, disabled, difficulty, loaded, stop_options = case
    cpu = Uc(UC_ARCH_X86, UC_MODE_32)
    cpu.mem_map(0, len(memory))
    cpu.mem_write(0, memory)
    cpu.mem_write(BASE, body)

    def put(name, fmt, value):
        cpu.mem_write(DS + D['_' + name], struct.pack('<' + fmt, value))

    for name, value in (('game_in_progress', game), ('menu_dispatch_active', active),
                        ('totalclock', 0x1234567), ('menu_saved_tick', -34567),
                        ('menu_animation_clock', 128), ('main_menu_selection', 7),
                        ('loading_caption_columns', 25), ('presentation_width', 640),
                        ('presentation_height', 480), ('loaded_game_ready', -4),
                        ('menu_loop_state', 99)):
        put(name, 'i', value)
    put('new_game_requested', 'h', -3)
    put('difficulty_divisor', 'h', 7)
    trace, menus = [], 0

    def hook(engine, address, size, data):
        nonlocal menus
        name = CALLS.get(address)
        if name is None:
            return
        sp, pop, ret, args = engine.reg_read(UC_X86_REG_ESP), 0, 0, ()
        if name == 'run_menu_loop':
            pop = 4
            args = tuple(engine.reg_read(r) for r in ARGREGS) + (
                struct.unpack('<I', engine.mem_read(sp + 4, 4))[0],)
            expected = (DS + D['_main_menu_selection'], 8, 0x820,
                        DS + D['_main_menu_title'],
                        DS + D['_pause_entries' if game else '_main_entries'])
            assert args == expected, (args, expected)
            if menus == 0 and choice is not None:
                put('main_menu_selection', 'I', choice)
                ret = 1
            menus += 1
            assert menus <= 3
        elif name in ('rotatesprite', 'draw_menu_text'):
            pop = 32 if name == 'rotatesprite' else 4
            args = tuple(engine.reg_read(r) for r in ARGREGS) + struct.unpack(
                '<' + 'I' * (pop // 4), engine.mem_read(sp + 4, pop))
        elif name == 'clearview':
            args = (engine.reg_read(UC_X86_REG_EAX),)
        elif name == 'confirm_menu_action':
            ret = confirm
        elif name == 'new_game_disabled':
            ret = disabled
        elif name == 'run_difficulty_menu':
            ret = difficulty
        elif name == 'run_load_game_menu':
            ret = loaded
        elif name == 'run_options_menu' and stop_options:
            put('menu_dispatch_active', 'i', 0)
        elif name == 'reset_menu_animation_clock':
            put('menu_animation_clock', 'i', 0)
        trace.append((name, args))
        # Deliberately hostile callees check both saved clock values are restored.
        put('totalclock', 'i', 10000 + len(trace))
        put('menu_saved_tick', 'i', -10000 - len(trace))
        regs = ARGREGS if name in ('run_menu_loop', 'rotatesprite', 'draw_menu_text') else ARGREGS[:1]
        for register in regs:
            engine.reg_write(register, 0xa5c3f17e)
        engine.reg_write(UC_X86_REG_EAX, ret & 0xffffffff)
        target = struct.unpack('<I', engine.mem_read(sp, 4))[0]
        engine.reg_write(UC_X86_REG_ESP, sp + 4 + pop)
        engine.reg_write(UC_X86_REG_EIP, target)

    cpu.hook_add(UC_HOOK_CODE, hook)
    for i, reg in enumerate(SAVED):
        cpu.reg_write(reg, 0xabcd1230 + i)
    sentinel = b'\x5a' * 16
    cpu.mem_write(STACK, struct.pack('<I', STOP) + sentinel)
    cpu.reg_write(UC_X86_REG_ESP, STACK)
    cpu.emu_start(ENTRY, STOP, count=3000)
    assert cpu.reg_read(UC_X86_REG_EIP) == STOP
    assert cpu.reg_read(UC_X86_REG_ESP) == STACK + 4
    assert bytes(cpu.mem_read(STACK + 4, 16)) == sentinel
    assert all(cpu.reg_read(r) == 0xabcd1230 + i for i, r in enumerate(SAVED))
    ds_state = bytes(cpu.mem_read(DS, DS_SIZE))
    assert len(ds_state) == DS_SIZE
    assert struct.unpack_from('<i', ds_state, D['_totalclock'])[0] == 0x1234567, \
        'totalclock was not restored'
    assert struct.unpack_from('<i', ds_state, D['_menu_saved_tick'])[0] == -34567, \
        'menu_saved_tick was not restored'
    return cpu.reg_read(UC_X86_REG_EAX), trace, ds_state


def cases():
    basic = [(g, a, c, q, n, d, l, False)
             for g, a, c, q, n, d, l in itertools.product(
                 (0, 1), (0, 1), (None, 0, 1, 2, 3, 4, 5, 6, 7, 8),
                 (0, 1), (0, 1, -1), (0, 1, 3), (0, -1))]
    basic += [(g, 1, 1, 1, 0, 0, 0, True) for g in (0, 1)]
    assert len(basic) == 1442
    return basic


def resolve_object(build):
    path = Path(build)
    if path.is_dir():
        for name in ('mainmenu.obj', 'MAINMENU.OBJ', 'FRAME.OBJ'):
            candidate = path / name
            if candidate.is_file():
                return candidate
        raise FileNotFoundError(f'No mainmenu.obj in {path}')
    return path


def hash_file(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def artifact_hashes(object_path):
    object_path = Path(object_path)
    source = object_path.parent / 'mainmenu.c'
    prep_source = object_path.parent / 'menuprep.c'
    prep_object = object_path.parent / 'menuprep.obj'
    if not source.is_file():
        raise FileNotFoundError(f'Missing main menu source for hash report: {source}')
    for path in (prep_source, prep_object):
        if not path.is_file():
            raise FileNotFoundError(f'Missing menu preparation artifact for hash report: {path}')
    assembly = {}
    for name in ('main_menu_entry.bin', 'main_menu_resume.bin'):
        path = object_path.parent / 'asm' / name
        if not path.is_file():
            path = object_path.parent / name
        if not path.is_file():
            raise FileNotFoundError(f'Missing assembled gap for hash report: {path}')
        assembly[name] = hash_file(path)
    return {'source_sha256': hash_file(source),
            'object_sha256': hash_file(object_path),
            'menuprep_source_sha256': hash_file(prep_source),
            'menuprep_object_sha256': hash_file(prep_object),
            'asm_sha256': assembly}


def normalize_span(memory, address, size, pointers):
    result = bytearray(memory[address:address + size])
    for site, target in pointers.items():
        if address <= site < address + size:
            delta = 0x80000 if target >= 0x80000 else 0x10000
            off = site - address
            struct.pack_into('<I', result, off, (target - delta) & 0xffffffff)
    return bytes(result)


def verify_assembled_gaps(build, memory, pointers):
    build = Path(build)
    gaps = (('main_menu_entry.bin', 0x3a127, 74),
            ('main_menu_resume.bin', 0x3a2f3, 15))
    for name, address, size in gaps:
        path = build / name if build.is_dir() else build.parent / name
        if not path.is_file() and build.is_dir():
            path = build / 'asm' / name
        if not path.is_file():
            raise FileNotFoundError(f'Missing assembled main-menu gap: {path}')
        expected = normalize_span(memory, address, size, pointers)
        if path.read_bytes() != expected:
            raise ValueError(f'Assembled gap differs from pinned bytes: {name}')


def bind_fixture(exe_bytes, object_bytes, build):
    if hashlib.sha256(exe_bytes).hexdigest() != PINNED_SHA256:
        raise ValueError('Unsupported pinned FATE.EXE hash')
    memory = image(exe_bytes)
    pointers = read_le_fixups(exe_bytes)['pointers']
    original_normalized = normalize_span(memory, BASE, SIZE, pointers)
    group, le_sites = bytearray(original_normalized), []
    for symbol, start, end, address in SECTIONS:
        code_refs = {}
        code, bindings = bind_section(object_bytes, symbol, address=address,
                                      code_bindings=code_refs)
        if len(code) != end - start:
            raise ValueError(f'{symbol}: wrong selected section length')
        original = normalize_span(memory, address, len(code), pointers)
        if code != original:
            raise ValueError(f'{symbol}: section bytes differ from pinned image')
        verify_leaf_relocations(code, bindings, pointers, address,
                                code_bindings=code_refs)
        for site in bindings:
            le_sites.append(address + site)
        offset = address - BASE
        group[offset:offset + len(code)] = code
    prep_object = Path(build).parent / 'menuprep.obj' if not Path(build).is_dir() else Path(build) / 'menuprep.obj'
    if not prep_object.is_file():
        raise FileNotFoundError(f'Missing menu preparation object: {prep_object}')
    prep_bytes = prep_object.read_bytes()
    for symbol, address, size in (('main_menu_selection_', 0x3a171, 23),
                                  ('main_menu_caption_', 0x3a25c, 40)):
        code_bindings = {}
        code, bindings = bind_leaf_details(prep_bytes, symbol, DATA, address=address,
                                           functions=FUNCTION_ADDRESSES, code_bindings=code_bindings)
        if len(code) != size:
            raise ValueError(f'{symbol}: expected {size} bytes, got {len(code)}')
        original = normalize_span(memory, address, size, pointers)
        if code != original:
            raise ValueError(f'{symbol}: bytes differ from pinned image')
        verify_leaf_relocations(code, bindings, pointers, address,
                                code_bindings=code_bindings)
        le_sites.extend(address + site for site in bindings)
        offset = address - BASE
        group[offset:offset + size] = code
    if bytes(group) != original_normalized:
        raise ValueError('Reconstructed 541-byte group differs from pinned image')
    verify_assembled_gaps(build, memory, pointers)
    group_fixups = {site: target for site, target in pointers.items()
                    if BASE <= site < BASE + SIZE}
    if len(group_fixups) != 38:
        raise ValueError(f'Expected 38 original group LE fixups, got {len(group_fixups)}')
    for site, target in group_fixups.items():
        offset = site - BASE
        delta = 0x80000 if target >= 0x80000 else 0x10000
        raw_target = int.from_bytes(group[offset:offset + 4], 'little')
        if raw_target + delta != target:
            raise ValueError(f'Group relocation target differs at {site:#x}')
        struct.pack_into('<I', group, offset, target)
    if len(set(le_sites)) != 26:
        raise ValueError(f'Expected 26 selected LE fixups, got {len(set(le_sites))}')
    if sum(end - start for _, start, end, _ in SECTIONS) + 23 + 40 != 453:
        raise ValueError('Expected 453 selected main-menu bytes')
    return memory, bytes(group), sorted(set(le_sites))


def negative_controls(memory, group):
    # Wrong switch case target: case 0 is redirected to the retained case-1 target.
    wrong_case = bytearray(group)
    slot0, slot1 = struct.unpack_from('<II', wrong_case, 0)
    struct.pack_into('<I', wrong_case, 0, slot1)
    case = (0, 1, 0, 1, 0, 0, 0, False)
    assert exercise(memory, group, case) != exercise(memory, bytes(wrong_case), case), \
        'switch-target negative control escaped detection'

    # A wrong clock store must be caught by the mandatory restored-clock assertions.
    # Change the low byte of the menu_saved_tick displacement in its selected slice.
    exit_row = next(row for row in SECTIONS if row[0] == 'main_menu_exit_')
    _, start, end, address = exit_row
    probe = bytearray(group)
    section_off = address - BASE
    pattern = struct.pack('<I', 0x83cea)
    locations = [i for i in range(section_off, section_off + end - start - 3)
                 if probe[i:i + 4] == pattern]
    if not locations:
        raise ValueError('Could not locate menu_saved_tick store for negative control')
    probe[locations[-1]] ^= 1
    try:
        exercise(memory, bytes(probe), (0, 1, 8, 1, 0, 0, 0, False))
    except AssertionError as error:
        assert 'menu_saved_tick' in str(error) or 'totalclock' in str(error), error
    else:
        raise AssertionError('clock-store negative control escaped detection')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, help='Pinned source-built FATE.EXE')
    parser.add_argument('--build', required=True, help='mainmenu.obj or its build directory')
    parser.add_argument('--output', required=True, help='JSON report destination')
    args = parser.parse_args()
    exe_bytes = Path(args.exe).read_bytes()
    object_path = resolve_object(args.build)
    memory, group, le_sites = bind_fixture(exe_bytes, object_path.read_bytes(), args.build)
    negative_controls(memory, group)
    original = memory[BASE:BASE + SIZE]
    for index, case in enumerate(cases()):
        if exercise(memory, original, case) != exercise(memory, group, case):
            raise AssertionError(f'Behavior mismatch in case {index}: {case!r}')
    report = {'status': 'PASS', 'cases': 1442, 'sha256': PINNED_SHA256,
              **artifact_hashes(object_path),
              'group_bytes': SIZE, 'selected_bytes': sum(s[2] - s[1] for s in SECTIONS) + 23 + 40,
              'ds_bytes': DS_SIZE, 'selected_le_sites': le_sites, 'group_le_sites': 38,
              'negative_controls':
              {'clock_store': 'detected', 'switch_case_target': 'detected'},
              'scope': 'historical differential diagnostic; not a smoke test'}
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
