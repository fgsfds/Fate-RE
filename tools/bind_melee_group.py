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
    segments, publics = read_object(blob)
    if publics != [(1, 32, 'melee_trigger_')]:
        raise ValueError('Unexpected melee group public layout')
    if len(segments) < 2 or not segments[1] or segments[1]['cls'] != 'CODE' or any(len(s['data']) for s in segments[2:]):
        raise ValueError('Unexpected allocated melee segments')
    code = bytearray(segments[1]['data'])
    externals, flats = read_externals(blob), flat_frame_groups(blob)
    occupied, data_refs, code_refs, calls = set(), {}, {}, {}
    for fix in read_fixups(blob):
        if fix.segment != 1 or fix.location != 9 or fix.width != 4 or fix.frame[0] != 1 or fix.frame[1] not in flats:
            raise ValueError('Unsupported melee fixup location/frame')
        off = fix.offset
        if off < 0 or off + 4 > len(code) or occupied.intersection(range(off, off + 4)):
            raise ValueError('Invalid/overlapping melee fixup')
        occupied.update(range(off, off + 4))
        addend = int.from_bytes(code[off:off + 4], 'little') + fix.displacement
        if fix.target == (0, 1) and not fix.relative:
            if not 0 <= addend < len(code):
                raise ValueError('Melee CODE target outside group')
            value = addend + base - (0 if loaded else 0x10000)
            code_refs[off] = value
        elif fix.target[0] == 2:
            if not 0 < fix.target[1] < len(externals):
                raise ValueError('Invalid melee external index')
            name = externals[fix.target[1]]
            if fix.relative:
                if name not in FUNCTIONS: raise ValueError('Unbound melee call')
                value = addend + FUNCTIONS[name] - (base + off + 4)
                calls[off] = FUNCTIONS[name]
            else:
                if name not in DATA: raise ValueError('Unbound melee data')
                value = addend + DATA[name] + (0x80000 if loaded else 0)
                data_refs[off] = value
        else:
            raise ValueError('Unsupported melee target method')
        code[off:off + 4] = (value & 0xffffffff).to_bytes(4, 'little')
    if len(code_refs) != 9 or set(range(0, 32, 4)) - code_refs.keys():
        raise ValueError('Expected eight generated table slots and one CODE dispatch pointer')
    internal_base = base - (0 if loaded else 0x10000)
    if any(not internal_base + 32 <= code_refs[i] < internal_base + len(code) for i in range(0, 32, 4)):
        raise ValueError('Melee table target is not inside function')
    extra = set(code_refs) - set(range(0, 32, 4))
    if len(extra) != 1 or code_refs[next(iter(extra))] != internal_base:
        raise ValueError('Melee dispatch does not target table start')
    return bytes(code), data_refs, code_refs, calls
