"""Select Watcom video-mode prompt instructions around the original NASM gaps."""

from hashlib import sha256

from bind_melee_group import bind_switch_group
from verify_c_leaf import parsed_leaf_object


BASE, ENTRY, END = 0x36cf2, 0x36d0a, 0x36f73
PREFIX, GROUP_SIZE = ENTRY - BASE, 647
CODE_BASE, DATA_BASE = 0x10000, 0x80000
PUBLIC = 'prompt_video_mode_context_'
GROUP_SHA256 = '4a90693dbb0828c518541509f16ee57b0259d5ca65bd0561efa8c998d565c3e2'

# Source offsets are relative to the private compiler public, excluding its
# table. Destinations are reference loaded addresses, including retained gaps.
SECTIONS = (
    ('video_prompt_entry_', 0x000, 0x01a, 0x36d0a),
    ('video_prompt_clamp_size_', 0x09d, 0x0bc, 0x36da1),
    ('video_prompt_match_size_', 0x0e4, 0x123, 0x36de8),
    ('video_prompt_heading_', 0x12a, 0x16c, 0x36e2e),
    ('video_prompt_placeholders_', 0x16f, 0x1b2, 0x36e73),
    ('video_prompt_print_size_', 0x1e8, 0x227, 0x36eec),
    ('video_prompt_footer_', 0x24a, 0x26f, 0x36f4e),
)

DATA = {
    '_first_mode_indices': 0x12d54,
    '_first_mode_widths': 0x12d48,
    '_first_mode_heights': 0x12d4e,
    '_second_mode_indices': 0x12d68,
    '_second_mode_widths': 0x12d60,
    '_second_mode_heights': 0x12d64,
    '_video_size_selection': 0x173d54,
    '_video_size_count': 0x173d56,
    '_requested_video_width': 0x12d74,
    '_requested_video_height': 0x12d78,
    '_video_mode_selection': 0x12d70,
    '_video_mode_names': 0x12d30,
    '_video_size_heading': 0x9e3,
    '_video_size_empty_row': 0x9eb,
    '_video_prompt_size_format': 0x9fd,
    '_video_size_footer': 0xa0d,
}

CODE = {
    '_video_default_indices': 0x2694a,
    '_video_default_width': 0x2694e,
    '_video_default_height': 0x26950,
}

FUNCTIONS = {
    'set_background_color_': 0x6f1bf,
    'set_text_color_': 0x6f25d,
    'get_text_color_': 0x6f22c,
    'print_video_text_at_': 0x36b0e,
}

TABLE_TARGETS = (0x59, 0x7a, 0x9b, 0x9b, 0x9b, 0x9b)
DISPATCH_SITE = 0x055

# Full group offsets, including all omitted context and its relative calls.
FIXUPS = {
    0x000: (None, False, 0x59),
    0x004: (None, False, 0x7a),
    0x008: (None, False, 0x9b),
    0x00c: (None, False, 0x9b),
    0x010: (None, False, 0x9b),
    0x014: (None, False, 0x9b),
    0x025: ('_video_default_indices', False, 0),
    0x02e: ('_video_default_width', False, 0),
    0x038: ('_video_default_height', False, 0),
    0x055: (None, False, 0),
    0x05a: ('_first_mode_indices', False, 0),
    0x05f: ('_first_mode_widths', False, 0),
    0x064: ('_first_mode_heights', False, 0),
    0x074: ('_video_size_count', False, 0),
    0x07b: ('_second_mode_indices', False, 0),
    0x080: ('_second_mode_widths', False, 0),
    0x085: ('_second_mode_heights', False, 0),
    0x095: ('_video_size_count', False, 0),
    0x0b1: ('_video_size_count', False, 0),
    0x0b7: ('_video_size_selection', False, 0),
    0x0be: ('_video_size_count', False, 0),
    0x0cc: ('_video_size_selection', False, 0),
    0x101: ('_requested_video_width', False, 0),
    0x10c: ('_requested_video_height', False, 0),
    0x115: ('_video_size_selection', False, 0),
    0x11d: ('_video_size_count', False, 0),
    0x126: ('_video_size_selection', False, 0),
    0x151: ('set_background_color_', True, 0),
    0x158: ('set_text_color_', True, 0),
    0x15d: ('_video_mode_selection', False, 0),
    0x164: ('_video_mode_names', False, 0),
    0x16a: ('_video_size_heading', False, 0),
    0x173: ('print_video_text_at_', True, 0),
    0x180: ('set_background_color_', True, 0),
    0x197: ('set_text_color_', True, 0),
    0x1a5: ('_video_size_count', False, 0),
    0x1ac: ('_video_size_empty_row', False, 0),
    0x1b5: ('print_video_text_at_', True, 0),
    0x1c4: ('_video_size_selection', False, 0),
    0x1dc: ('set_background_color_', True, 0),
    0x1e6: ('set_text_color_', True, 0),
    0x21a: ('_video_prompt_size_format', False, 0),
    0x223: ('print_video_text_at_', True, 0),
    0x22b: ('get_text_color_', True, 0),
    0x23b: ('set_background_color_', True, 0),
    0x252: ('set_text_color_', True, 0),
    0x26e: ('_video_size_footer', False, 0),
    0x277: ('print_video_text_at_', True, 0),
}

# Source instruction offset, raw bytes, compiler destination, placed destination.
# Omitted jumps are pinned even when their destinations have no placed counterpart.
BRANCHES = {
    0x02e: ('0f8732020000', 0x266, None),
    0x060: ('eb3b', 0x09d, None),
    0x081: ('eb1a', 0x09d, None),
    0x0ad: ('7c09', 0x0b8, 0x36dbc),
    0x0ba: ('eb46', 0x102, 0x36e06),
    0x0ed: ('7512', 0x101, 0x36e05),
    0x0f8: ('7507', 0x101, 0x36e05),
    0x109: ('7cb1', 0x0bc, 0x36dc0),
    0x118: ('7d02', 0x11c, 0x36e20),
    0x12a: ('7407', 0x133, 0x36e37),
    0x131: ('eb05', 0x138, 0x36e3c),
    0x16f: ('7407', 0x178, 0x36e7c),
    0x176: ('eb05', 0x17d, 0x36e81),
    0x185: ('e9b5000000', 0x23f, 0x36f43),
    0x191: ('7c16', 0x1a9, 0x36ead),
    0x1a4: ('e995000000', 0x23e, 0x36f42),
    0x1b0: ('7520', 0x1d2, 0x36ed6),
    0x1b5: ('7407', 0x1be, None),
    0x1bc: ('eb05', 0x1c3, None),
    0x21b: ('7521', 0x23e, 0x36f42),
    0x22a: ('7407', 0x233, None),
    0x231: ('eb05', 0x238, None),
    0x24f: ('0f8c35ffffff', 0x18a, 0x36e8e),
}

# Group displacement offset, placed CALL address and target.
SELECTED_CALLS = {
    0x151: (0x36e3c, 0x6f1bf),
    0x158: (0x36e43, 0x6f25d),
    0x173: (0x36e5e, 0x36b0e),
    0x180: (0x36e6b, 0x6f1bf),
    0x197: (0x36e82, 0x6f25d),
    0x1b5: (0x36ea0, 0x36b0e),
    0x223: (0x36f0e, 0x36b0e),
    0x22b: (0x36f16, 0x6f22c),
    0x23b: (0x36f26, 0x6f1bf),
    0x277: (0x36f62, 0x36b0e),
}


def bind_context(blob, *, loaded=False, base=BASE):
    """Bind and guard the full private compiler group, including omitted bytes."""
    segments, publics, externals, flat_groups, fixups = parsed_leaf_object(bytes(blob))
    if publics != ((1, PREFIX, PUBLIC),) or len(segments[1]['data']) != GROUP_SIZE:
        raise ValueError('Video prompt compiler group extent/public differs')
    raw = segments[1]['data']
    if sha256(raw).hexdigest() != GROUP_SHA256:
        raise ValueError('Video prompt compiler CODE digest differs')
    if len(fixups) != len(FIXUPS) or {fix.offset for fix in fixups} != FIXUPS.keys():
        raise ValueError('Video prompt compiler fixup inventory differs')
    for fix in fixups:
        site = fix.offset
        name, relative, addend = FIXUPS[site]
        if name is None:
            correct_target = fix.target == (0, 1)
        else:
            kind, index = fix.target
            correct_target = kind == 2 and 0 < index < len(externals) and externals[index] == name
        if (fix.segment != 1 or fix.location != 9 or fix.width != 4
                or fix.frame[0] != 1 or fix.frame[1] not in flat_groups
                or not correct_target or fix.relative != relative or fix.displacement
                or int.from_bytes(raw[site:site+4], 'little') != addend
                or (relative and raw[site-1:site] != b'\xe8')):
            raise ValueError('Video prompt compiler fixup form/target/addend differs')
        if any(site < PREFIX+boundary < site+4 for _, lo, hi, _ in SECTIONS
               for boundary in (lo, hi)):
            raise ValueError('Video prompt compiler fixup crosses a section boundary')

    for source, (encoding, compiler_target, placed_target) in BRANCHES.items():
        instruction = bytes.fromhex(encoding)
        size = len(instruction)
        relative_width = 1 if size == 2 else 4
        displacement = int.from_bytes(instruction[-relative_width:], 'little', signed=True)
        if raw[PREFIX+source:PREFIX+source+size] != instruction or source+size+displacement != compiler_target:
            raise ValueError('Video prompt compiler branch encoding or destination differs')
        places = [dest + compiler_target - start for _, start, end, dest in SECTIONS
                  if start <= source < end and source+size <= end]
        if places != ([] if placed_target is None else [placed_target]):
            raise ValueError('Video prompt placed branch destination differs')

    # bind_switch_group's external absolute operands are modeled as DATA.
    # Adjust the CODE extern inputs so loaded addressing uses its own base.
    code_adjustment = CODE_BASE-DATA_BASE if loaded else 0
    external_targets = DATA | {name: offset+code_adjustment for name, offset in CODE.items()}
    code, data, code_refs, calls = bind_switch_group(blob, base=base, loaded=loaded, symbol=PUBLIC,
        prefix_size=PREFIX, data_targets=external_targets, call_targets=FUNCTIONS)
    code_origin = base if loaded else base-CODE_BASE
    if (tuple(code_refs[i]-code_origin for i in range(0, PREFIX, 4)) != TABLE_TARGETS
            or code_refs[DISPATCH_SITE] != code_origin
            or raw[DISPATCH_SITE-4:DISPATCH_SITE] != bytes.fromhex('2eff2485')):
        raise ValueError('Video prompt internal dispatch table differs')
    for site, (name, _, _) in FIXUPS.items():
        if name in CODE:
            code_refs[site] = data.pop(site)
    if (len(data), len(code_refs), len(calls)) != (25, 10, 13):
        raise ValueError('Video prompt compiler binding counts differ')
    return code, data, code_refs, calls


def bind_section(blob, symbol, address=None, code_bindings=None, *, loaded=False):
    """Select one original placement and adjust only its OMF-backed CALL operands.

    For disk linking, metadata contains object-relative DATA and CODE offsets.
    For ``loaded=True`` both returned maps and instructions use linear addresses.
    """
    selected = [(start, end, target) for name, start, end, target in SECTIONS if name == symbol]
    if len(selected) != 1:
        raise ValueError('Unknown video prompt section')
    start, end, target = selected[0]
    if address != target:
        raise ValueError('Video prompt section placement differs')
    if not isinstance(code_bindings, dict) or code_bindings:
        raise ValueError('Video prompt CODE binding requires empty output metadata')
    code, data, code_refs, calls = bind_context(blob, loaded=loaded)
    lo, hi = PREFIX+start, PREFIX+end
    placed = bytearray(code[lo:hi])
    for site, destination in calls.items():
        if lo <= site < hi:
            offset = site-lo
            instruction_address = address+offset-1
            if offset < 1 or SELECTED_CALLS.get(site) != (instruction_address, destination):
                raise ValueError('Video prompt selected call placement or destination differs')
            displacement = destination-(instruction_address+5)
            placed[offset:offset+4] = displacement.to_bytes(4, 'little', signed=True)
    code_bindings.update({site-lo: value for site, value in code_refs.items() if lo <= site < hi})
    refs = {site-lo: value for site, value in (data | code_refs).items() if lo <= site < hi}
    return bytes(placed), refs


def verified_context_tables(blob, rows):
    """Confirm attribution against placed bytes while excluding the private table."""
    by_symbol = {row['symbol']: row for row in rows}
    if len(rows) != len(SECTIONS) or set(by_symbol) != {row[0] for row in SECTIONS}:
        raise ValueError('Video prompt attribution section inventory differs')
    for symbol, start, end, address in SECTIONS:
        row = by_symbol[symbol]
        code, refs = bind_section(blob, symbol, address, {})
        if (int(row['raw_offset'], 16) != address+0x25600 or row['bytes'] != end-start
                or row['sha256'] != sha256(code).hexdigest() or row['le_pointers'] != len(refs)):
            raise ValueError('Video prompt attribution linked section differs')
    return ((1, 0, PREFIX),)
