"""Select unchanged Watcom main-menu sections around retained assembly.

Only displacement operands are linked. The original switch table remains ASM:
its resume slots intentionally enter the retained resume block. The excluded
compiler table is still checked against its exact source destinations.
"""
from bind_melee_group import bind_switch_group
from verify_c_leaf import parsed_leaf_object, bind_section_branches

BASE, ENTRY, GROUP_SIZE, PUBLIC_SIZE = 0x3a128, 0x3a148, 529, 497
PUBLIC = 'dispatch_main_menu_'
SECTIONS = (('main_menu_loop_', 0x43, 0x117, 0x3a188),
            ('main_menu_actions_', 0x13f, 0x1ae, 0x3a284),
            ('main_menu_exit_', 0x1ae, 0x1f1, 0x3a302),
            ('main_menu_save_', 0, 17, 0x3a148),
            ('main_menu_tick_', 19, 25, 0x3a159),
            ('main_menu_zero_', 17, 19, 0x3a15f),
            ('main_menu_initialize_', 25, 41, 0x3a161))
# Instruction-aligned entry phases cover compiler bytes[0,41) exactly once.
# The independent tick load and register zero are placed in original order.
ENTRY_CONTEXT = bytes.fromhex(
    '53 51 52 56 57 55 be 01 00 00 00 8b 3d 00 00 00 00 '
    '31 d2 8b 2d 00 00 00 00 e8 00 00 00 00 89 15 00 00 00 00 e8 00 00 00 00')
DATA = {
    '_difficulty_divisor': 0x7deec,
    '_game_in_progress': 0x772b8,
    '_loaded_game_ready': 0x77114,
    '_loading_caption': 0xd7c,
    '_loading_caption_columns': 0x12df8,
    '_main_entries': 0x173ff0,
    '_main_menu_selection': 0x1740ec,
    '_main_menu_title': 0xd72,
    '_menu_animation_clock': 0x13150,
    '_menu_dispatch_active': 0x77118,
    '_menu_loop_state': 0x12dd4,
    '_menu_saved_tick': 0x3cea,
    '_new_game_requested': 0x2265,
    '_pause_entries': 0x174028,
    '_presentation_height': 0x287e8c,
    '_presentation_width': 0x287e90,
    '_totalclock': 0x287e88,
}
FUNCTIONS = {
    'cache_menu_tiles_': 0x39488,
    'clearview_': 0x5cd99,
    'confirm_menu_action_': 0x3a0ce,
    'draw_menu_text_': 0x386d3,
    'menu_selection_return_': 0x3947f,
    'new_game_disabled_': 0x3a6e5,
    'nextpage_': 0x4b496,
    'preload_game_tiles_': 0x3b14b,
    'reset_menu_animation_clock_': 0x390bc,
    'rotatesprite_': 0x57181,
    'run_difficulty_menu_': 0x3ae7c,
    'run_help_menu_': 0x3a8bc,
    'run_load_game_menu_': 0x39f1f,
    'run_menu_loop_': 0x3963b,
    'run_options_menu_': 0x397f4,
    'run_save_game_menu_': 0x39d95,
}
TABLE_TARGETS = (184, 371, 381, 442, 452, 497, 497, 462)
FIXUPS = {
    0x0: (None, False, 0xb8, b''),
    0x4: (None, False, 0x173, b''),
    0x8: (None, False, 0x17d, b''),
    0xc: (None, False, 0x1ba, b''),
    0x10: (None, False, 0x1c4, b''),
    0x14: (None, False, 0x1f1, b''),
    0x18: (None, False, 0x1f1, b''),
    0x1c: (None, False, 0x1ce, b''),
    0x2d: ('_totalclock', False, 0x0, b''),
    0x35: ('_menu_saved_tick', False, 0x0, b''),
    0x3a: ('reset_menu_animation_clock_', True, 0x0, b'\xe8'),
    0x40: ('_menu_animation_clock', False, 0x0, b''),
    0x45: ('cache_menu_tiles_', True, 0x0, b'\xe8'),
    0x4b: ('_game_in_progress', False, 0x0, b''),
    0x57: ('_main_menu_selection', False, 0x0, b''),
    0x5f: ('_main_menu_selection', False, 0x0, b''),
    0x65: ('_menu_dispatch_active', False, 0x0, b''),
    0x72: ('_game_in_progress', False, 0x0, b''),
    0x7a: ('_main_entries', False, 0x0, b''),
    0x81: ('_pause_entries', False, 0x0, b''),
    0x86: ('_main_menu_title', False, 0x0, b''),
    0x95: ('_main_menu_selection', False, 0x0, b''),
    0x9a: ('run_menu_loop_', True, 0x0, b'\xe8'),
    0xa7: ('_main_menu_selection', False, 0x0, b''),
    0xb4: (None, False, 0x0, b''),
    0xbe: ('_game_in_progress', False, 0x0, b''),
    0xc5: ('_new_game_requested', False, 0x0, b''),
    0xce: ('confirm_menu_action_', True, 0x0, b'\xe8'),
    0xd7: ('new_game_disabled_', True, 0x0, b'\xe8'),
    0xea: ('run_difficulty_menu_', True, 0x0, b'\xe8'),
    0xfe: ('clearview_', True, 0x0, b'\xe8'),
    0x103: ('_presentation_height', False, 0x0, b''),
    0x10b: ('_presentation_width', False, 0x0, b''),
    0x133: ('rotatesprite_', True, 0x0, b'\xe8'),
    0x139: ('_loading_caption_columns', False, 0x0, b''),
    0x143: ('_loading_caption', False, 0x0, b''),
    0x160: ('draw_menu_text_', True, 0x0, b'\xe8'),
    0x165: ('nextpage_', True, 0x0, b'\xe8'),
    0x16a: ('preload_game_tiles_', True, 0x0, b'\xe8'),
    0x174: ('run_options_menu_', True, 0x0, b'\xe8'),
    0x17f: ('_game_in_progress', False, 0x0, b''),
    0x187: ('confirm_menu_action_', True, 0x0, b'\xe8'),
    0x194: ('run_load_game_menu_', True, 0x0, b'\xe8'),
    0x1ad: ('_loaded_game_ready', False, 0x0, b''),
    0x1b4: ('_difficulty_divisor', False, 0x0, b''),
    0x1bb: ('run_save_game_menu_', True, 0x0, b'\xe8'),
    0x1c5: ('run_help_menu_', True, 0x0, b'\xe8'),
    0x1cf: ('confirm_menu_action_', True, 0x0, b'\xe8'),
    0x1df: ('_menu_dispatch_active', False, 0x0, b''),
    0x1e5: ('_game_in_progress', False, 0x0, b''),
    0x1eb: ('_menu_loop_state', False, 0x0, b''),
    0x1f3: ('_game_in_progress', False, 0x0, b''),
    0x202: ('_totalclock', False, 0x0, b''),
    0x208: ('_menu_saved_tick', False, 0x0, b''),
    0x20d: ('menu_selection_return_', True, 0x0, b'\xe9'),
}
BRANCHES = {
    0x4a: (b'\x0f\x84', 0x1e0, 0x1ec),
    0x57: (b'u', 0x60, 0x5d),
    0x5e: (b'\xeb', 0x65, 0x62),
    0x80: (b'\x0f\x84', 0x1d1, 0x1dd),
    0x8e: (b'w', 0x43, 0x40),
    0xab: (b't', 0xb6, 0xb3),
    0xb4: (b't', 0x43, 0x40),
    0xbd: (b'~', 0xc9, 0xc6),
    0xc4: (b'\xe9', 0x1e0, 0x1ec),
    0xd0: (b'\x0f\x84', 0x43, 0x40),
    0x14e: (b'\xe9', 0x1e0, 0x1ec),
    0x158: (b'\xe9', 0x43, 0x40),
    0x164: (b't', 0x173, 0x170),
    0x16d: (b'\x0f\x84', 0x43, 0x40),
    0x17b: (b'\x0f\x84', 0x43, 0x40),
    0x198: (b'\xeb', 0x149, 0x146),
    0x19f: (b'\xe9', 0x43, 0x40),
    0x1a9: (b'\xe9', 0x43, 0x40),
    0x1b5: (b'\x0f\x84', 0x43, 0x40),
    0x1cf: (b'\xeb', 0x1e0, 0x1ec),
    0x1d8: (b'\x0f\x85', 0xbf, 0xbc),
}


def bind_section(blob, symbol, address=None, code_bindings=None):
    selected = [(a, b, target) for name, a, b, target in SECTIONS if name == symbol]
    if len(selected) != 1:
        raise ValueError('Unknown main-menu section')
    start, end, target = selected[0]
    if address != target:
        raise ValueError('Main-menu section placement differs')
    if not isinstance(code_bindings, dict) or code_bindings:
        raise ValueError('Main-menu CODE binding requires empty output metadata')
    segments, publics, externals, flats, fixups = parsed_leaf_object(bytes(blob))
    if publics != ((1, 32, PUBLIC),) or len(segments[1]['data']) != GROUP_SIZE:
        raise ValueError('Main-menu compiler group extent/public differs')
    raw = segments[1]['data']
    if raw[32:73] != ENTRY_CONTEXT:
        raise ValueError('Main-menu entry context differs')
    if len(fixups) != len(FIXUPS) or {f.offset for f in fixups} != FIXUPS.keys():
        raise ValueError('Main-menu fixup inventory differs')
    for f in fixups:
        name, relative, addend, opcode = FIXUPS[f.offset]
        if name is None:
            expected_target = (0, 1)
        else:
            if not (f.target[0] == 2 and 0 < f.target[1] < len(externals)
                    and externals[f.target[1]] == name):
                raise ValueError('Main-menu external semantic target differs')
            expected_target = f.target
        if (f.target != expected_target or f.relative != relative or f.displacement
                or int.from_bytes(raw[f.offset:f.offset+4], 'little') != addend
                or (opcode and raw[f.offset-1:f.offset] != opcode)):
            raise ValueError('Main-menu fixup form/addend/opcode differs')
        site = f.offset - 32
        if any(site < boundary < site+4 for boundary in (start, end)):
            raise ValueError('Main-menu fixup crosses section boundary')
    code, data, pointers, calls = bind_switch_group(blob, base=BASE, loaded=False,
        symbol=PUBLIC, prefix_size=32, data_targets=DATA, call_targets=FUNCTIONS)
    if (len(data), len(pointers), len(calls)) != (28, 9, 18):
        raise ValueError('Main-menu binding counts differ')
    if tuple(pointers[i] - (BASE-0x10000) for i in range(0, 32, 4)) != TABLE_TARGETS:
        raise ValueError('Main-menu excluded table target differs')
    body = bytearray(code[32:])
    fields = {byte-32 for f in fixups for byte in range(f.offset, f.offset+4) if byte >= 32}
    bind_section_branches(body, PUBLIC, target-start, {PUBLIC: ENTRY}, fields, start, end,
                          metadata=(PUBLIC_SIZE, 509, BRANCHES))
    # These are OMF-backed external CALLs plus the shared-frame tail JMP.
    # Their opcode, width, zero addend and semantic destination were checked above.
    for site, destination in calls.items():
        site -= 32
        if start <= site < end:
            displacement = destination - (target + site-start + 4)
            body[site:site+4] = displacement.to_bytes(4, 'little', signed=True)
    refs = {site-32-start: value for site,value in (data | pointers).items()
            if start <= site-32 < end}
    code_bindings.update({site-32-start: value for site,value in pointers.items()
                          if start <= site-32 < end})
    return bytes(body[start:end]), refs


def verified_context_tables(blob, rows):
    """Validate omitted compiler table context without crediting any table bytes."""
    from hashlib import sha256
    by_symbol = {row['symbol']: row for row in rows}
    if len(rows) != len(SECTIONS) or set(by_symbol) != {row[0] for row in SECTIONS}:
        raise ValueError('Main-menu attribution section inventory differs')
    for symbol,start,end,target in SECTIONS:
        row=by_symbol[symbol]
        pointers={}
        code,refs=bind_section(blob,symbol,address=target,code_bindings=pointers)
        if (int(row['raw_offset'],16) != target+0x25600 or row['bytes'] != end-start
                or row['sha256'] != sha256(code).hexdigest()
                or row['le_pointers'] != len(refs)):
            raise ValueError('Main-menu attribution linked section differs')
    return ((1,0,32),)
