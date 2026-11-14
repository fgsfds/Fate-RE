"""Bind the crush initializer CODE group, including its compiler-generated jump table.

Only the observed empty-FLAT, 32-bit external or same-CODE-segment fixups are
accepted. This does not patch resolved branches or synthesize original bytes.
"""
from match_objects import read_object
from omf_fixups import read_externals, read_fixups
from verify_c_leaf import flat_frame_groups

BASE, ENTRY, SIZE = 0x3fddf, 0x3fe1b, 1161
DATA = {'_crush_init_banks':0x174640, '_crush_init_sectors':0x27c3a0,
        '_crush_init_walls':0x2310a0, '_crush_current_sector':0x17ab08,
        '_crush_init_num_sectors':0x289154, '_crush_init_invalid_text':0x13a6,
        '_crush_init_limit_text':0x13c5}
FUNCTIONS = {'crush_init_error_':0x26a03, 'crush_init_clear_':0x3fd11,
             'crush_init_predicate_':0x3fccb}


def bind(blob, loaded=False, base=BASE):
    segments, publics = read_object(blob)
    if publics != [(1, 60, 'init_crush_bank_')]:
        raise ValueError('Unexpected crush initializer group public layout')
    if len(segments) < 2 or not segments[1] or segments[1]['cls'] != 'CODE' or any(len(s['data']) for s in segments[2:]):
        raise ValueError('Unexpected allocated crush initializer segments')
    code = bytearray(segments[1]['data'])
    externals, flats = read_externals(blob), flat_frame_groups(blob)
    occupied, data_refs, code_refs, calls = set(), {}, {}, {}
    for fix in read_fixups(blob):
        if fix.segment != 1 or fix.location != 9 or fix.width != 4 or fix.frame[0] != 1 or fix.frame[1] not in flats:
            raise ValueError('Unsupported crush initializer fixup location/frame')
        off = fix.offset
        if off < 0 or off + 4 > len(code) or occupied.intersection(range(off, off + 4)):
            raise ValueError('Invalid/overlapping crush initializer fixup')
        occupied.update(range(off, off + 4))
        addend = int.from_bytes(code[off:off + 4], 'little') + fix.displacement
        if fix.target == (0, 1) and not fix.relative:
            if not 0 <= addend < len(code):
                raise ValueError('Crush initializer CODE target outside group')
            value = addend + base - (0 if loaded else 0x10000)
            code_refs[off] = value
        elif fix.target[0] == 2:
            if not 0 < fix.target[1] < len(externals):
                raise ValueError('Invalid crush initializer external index')
            name = externals[fix.target[1]]
            if fix.relative:
                if name not in FUNCTIONS: raise ValueError('Unbound crush initializer call')
                value = addend + FUNCTIONS[name] - (base + off + 4)
                calls[off] = FUNCTIONS[name]
            else:
                if name not in DATA: raise ValueError('Unbound crush initializer data')
                value = addend + DATA[name] + (0x80000 if loaded else 0)
                data_refs[off] = value
        else:
            raise ValueError('Unsupported crush initializer target method')
        code[off:off + 4] = (value & 0xffffffff).to_bytes(4, 'little')
    if len(code_refs) != 16 or set(range(0, 60, 4)) - code_refs.keys():
        raise ValueError('Expected fifteen generated table slots and one CODE dispatch pointer')
    internal_base = base - (0 if loaded else 0x10000)
    if any(not internal_base + 60 <= code_refs[i] < internal_base + len(code) for i in range(0, 60, 4)):
        raise ValueError('Crush initializer table target is not inside function')
    extra = set(code_refs) - set(range(0, 60, 4))
    if len(extra) != 1 or code_refs[next(iter(extra))] != internal_base:
        raise ValueError('Crush initializer dispatch does not target table start')
    return bytes(code), data_refs, code_refs, calls
