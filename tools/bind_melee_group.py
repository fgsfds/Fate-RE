"""Bind the melee CODE group, including its compiler-generated jump table.

Only the observed empty-FLAT, 32-bit external or same-CODE-segment fixups are
accepted. This does not patch resolved branches or synthesize original bytes.
"""
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from verify_c_leaf import flat_frame_groups

BASE, ENTRY, SIZE = 0x10b6f, 0x10b8f, 459
DATA = {'_melee_enabled': 0x7dee6, '_melee_angle': 0x6308c,
        '_melee_horizon': 0x62f8c, '_melee_sector': 0x5acfc,
        '_melee_mode': 0x5ac8f, '_melee_sound_flag': 0x2297,
        '_melee_sprite_mapping': 0x709dc, '_melee_sines': 0x2300a0,
        '_melee_x': 0x5ad9c, '_melee_y': 0x5ad5c, '_melee_z': 0x5ad1c}
FUNCTIONS = {'melee_hitscan_': 0x50f15, 'melee_distance_': 0x4ca38,
             'melee_random_': 0x602d0, 'melee_sound_': 0x34f79,
             'melee_start_sequence_': 0x11fdd}


def bind(blob, loaded=False, base=BASE):
    return bind_switch_group(blob, base=base, loaded=loaded, symbol='melee_trigger_',
                             prefix_size=32, data_targets=DATA, call_targets=FUNCTIONS)


def bind_switch_group(blob, *, base, loaded, symbol, prefix_size, data_targets, call_targets):
    """Bind a single Watcom function with a leading same-segment switch table."""
    return bind_switch_groups(blob, base=base, loaded=loaded,
                              tables=((0, prefix_size, None, symbol),),
                              data_targets=data_targets, call_targets=call_targets)


def bind_switch_groups(blob, *, base, loaded, tables, data_targets, call_targets):
    """Bind adjacent publics; a zero prefix marks an ordinary companion."""
    segments, publics = read_object(blob)
    if publics != [(1, start + size, symbol) for start, size, _, symbol in tables]:
        raise ValueError('Unexpected switch-group public layout')
    if len(segments) < 2 or not segments[1] or segments[1]['cls'] != 'CODE' or any(len(s['data']) for s in segments[2:]):
        raise ValueError('Unexpected allocated switch-group segments')
    code = bytearray(segments[1]['data'])
    externals, flats = read_externals(blob), flat_frame_groups(blob)
    occupied, data_refs, code_refs, calls = set(), {}, {}, {}
    public_entries = {name: entry for _, entry, name in publics}
    for fix in read_fixups(blob):
        if fix.segment != 1 or fix.location != 9 or fix.width != 4 or fix.frame[0] != 1 or fix.frame[1] not in flats:
            raise ValueError('Unsupported switch-group fixup location/frame')
        off = fix.offset
        if off < 0 or off + 4 > len(code) or occupied.intersection(range(off, off + 4)):
            raise ValueError('Invalid/overlapping switch-group fixup')
        occupied.update(range(off, off + 4))
        addend = int.from_bytes(code[off:off + 4], 'little') + fix.displacement
        if fix.target == (0, 1) and not fix.relative:
            if not 0 <= addend < len(code):
                raise ValueError('Switch CODE target outside group')
            value = addend + base - (0 if loaded else 0x10000)
            code_refs[off] = value
        elif fix.target[0] == 2:
            if not 0 < fix.target[1] < len(externals):
                raise ValueError('Invalid switch-group external index')
            name = externals[fix.target[1]]
            if fix.relative:
                if name in public_entries:
                    if off == 0 or code[off - 1] != 0xe8 or addend != 0:
                        raise ValueError('Unexpected same-segment switch-group call')
                    target = base + public_entries[name]
                elif name in call_targets:
                    target = call_targets[name]
                else:
                    raise ValueError('Unbound switch-group call')
                value = addend + target - (base + off + 4)
                calls[off] = target
            else:
                if name not in data_targets:
                    raise ValueError('Unbound switch-group DATA')
                value = addend + data_targets[name] + (0x80000 if loaded else 0)
                data_refs[off] = value
        else:
            raise ValueError('Unsupported switch-group target method')
        code[off:off + 4] = (value & 0xffffffff).to_bytes(4, 'little')
    pairs = [(start, size, len(code) if end is None else end) for start, size, end, _ in tables]
    if any(start < 0 or size < 0 or size % 4 or not start + size < end <= len(code)
           for start, size, end in pairs):
        raise ValueError('Invalid switch-group table/function extent')
    pairs = [row for row in pairs if row[1]]
    table_slots = {site for start, size, _ in pairs for site in range(start, start + size, 4)}
    if len(code_refs) != len(table_slots) + len(pairs) or table_slots - code_refs.keys():
        raise ValueError('Expected generated table slots and one dispatch pointer per table')
    internal_base = base - (0 if loaded else 0x10000)
    dispatches = code_refs.keys() - table_slots
    for start, size, end in pairs:
        entry = start + size
        if any(not internal_base + entry <= code_refs[site] < internal_base + end
               for site in range(start, entry, 4)):
            raise ValueError('Switch table target is not inside its function')
        dispatch = {site for site in dispatches if entry <= site < end}
        if len(dispatch) != 1 or code_refs[next(iter(dispatch))] != internal_base + start:
            raise ValueError('Switch dispatch does not target its table start')
    return bytes(code), data_refs, code_refs, calls
