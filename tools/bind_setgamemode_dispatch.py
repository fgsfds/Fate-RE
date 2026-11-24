"""Bind the checked video dispatch context and relocate its generated table."""
from dataclasses import asdict
from hashlib import sha256
from json import dumps

from bind_melee_group import bind_switch_group
from bind_setgamemode_display import CALLS, DATA as DISPLAY_DATA
from verify_c_leaf import parsed_leaf_object

BASE, SIZE = 0x4b02e, 32
PUBLIC = 'setgamemode_dispatch_context_'
PUBLIC_SIZE = 458
RAW_SHA256 = '91c9605e9bf4f4f5ac4e93a7461ede2eb2ede1637cbdcb32b433c7a3ce8418b9'
FIXUP_SHA256 = '006d87da6853c1a797d0853a270a42f0f3ebfb28c6a1649918878bc1359d896a'
DATA = {name: target for name, target in DISPLAY_DATA.items() if name != '_vidoption'}
DATA['_video_backend'] = DISPLAY_DATA['_vidoption']

PRIVATE_TARGETS = (0x49, 0xcc, 0xec, 0x101, 0x101, 0x101, 0x110, 0x178)
PLACED_TARGETS = (0x4b1f3, 0x4b275, 0x4b295, 0x4b2aa, 0x4b2aa, 0x4b2aa, 0x4b2b9, 0x4b320)
SLOT_OFFSETS = tuple(range(0, SIZE, 4))
DISPATCH_REF = 0x45
SECTIONS = {
    'setgamemode_backend_dispatch_setup_': (0x26, 0x38, 0x4b1d9),
    'setgamemode_backend_dispatch_jump_': (0x41, 0x49, 0x4b1eb),
}


def bind_context(blob, loaded=False, base=BASE):
    segments, publics, externals, _, fixups = parsed_leaf_object(bytes(blob))
    if publics != ((1, SIZE, PUBLIC),) or len(segments[1]['data']) != SIZE + PUBLIC_SIZE:
        raise ValueError('Video dispatch compiler public or extent differs')
    if sha256(segments[1]['data']).hexdigest() != RAW_SHA256:
        raise ValueError('Video dispatch raw group digest differs')
    if len(fixups) != 60:
        raise ValueError('Video dispatch OMF fixup count differs')
    forms = []
    for fix in fixups:
        method, index = fix.target
        if method == 2 and not 0 < index < len(externals):
            raise ValueError('Video dispatch external OMF index differs')
        target_name = externals[index] if method == 2 else None
        forms.append(dict(asdict(fix), target_name=target_name))
    encoded = dumps(forms, sort_keys=True, separators=(',', ':')).encode('ascii')
    if sha256(encoded).hexdigest() != FIXUP_SHA256:
        raise ValueError('Video dispatch OMF fixup sites, forms or targets differ')
    for start, stop, _ in SECTIONS.values():
        if any(fix.offset < cut < fix.offset + fix.width
               for fix in fixups for cut in (start, stop)):
            raise ValueError('Video dispatch selection splits an OMF fixup')
    code, data, pointers, calls = bind_switch_group(
        blob, base=base, loaded=loaded, symbol=PUBLIC, prefix_size=SIZE,
        data_targets=DATA, call_targets=CALLS)
    code_base = base if loaded else base - 0x10000
    if (set(pointers) != {*SLOT_OFFSETS, DISPATCH_REF}
            or tuple(pointers[site] - code_base for site in SLOT_OFFSETS) != PRIVATE_TARGETS
            or pointers[DISPATCH_REF] != code_base
            or code[DISPATCH_REF-4:DISPATCH_REF] != bytes.fromhex('2eff2495')):
        raise ValueError('Video dispatch private table, targets or jump differs')
    return code, data, pointers, calls


def bind_section(blob, symbol, address=None, code_bindings=None):
    if symbol not in SECTIONS:
        raise ValueError('Unknown video dispatch phase')
    start, stop, expected = SECTIONS[symbol]
    if address != expected:
        raise ValueError('Video dispatch linked phase placement differs')
    if not isinstance(code_bindings, dict) or code_bindings:
        raise ValueError('Video dispatch requires empty CODE binding metadata')
    code, data, pointers, calls = bind_context(blob)
    if any(start <= site < stop for site in calls):
        raise ValueError('Unexpected CALL fixup in video dispatch phase')
    refs = {site-start: target for site, target in data.items() if start <= site < stop}
    code_refs = {site-start: target for site, target in pointers.items() if start <= site < stop}
    expected_refs = ({4: DATA['_ydim'], 11: DATA['_xdim']}, {}) if start == 0x26 else (
        {}, {4: BASE - 0x10000})
    if (refs, code_refs) != expected_refs:
        raise ValueError('Video dispatch linked phase relocation differs')
    code_bindings.update(code_refs)
    return code[start:stop], refs | code_refs


def bind_table(blob):
    """Translate the guarded compiler slots to their linked backend case entries."""
    code, _, pointers, _ = bind_context(blob)
    translated = bytearray(code[:SIZE])
    case_map = dict(zip(PRIVATE_TARGETS, PLACED_TARGETS))
    refs = {}
    for site in SLOT_OFFSETS:
        source = pointers[site] - (BASE - 0x10000)
        target = case_map[source] - 0x10000
        translated[site:site+4] = target.to_bytes(4, 'little')
        refs[site] = target
    return bytes(translated), {}, refs, {}


bind = bind_table


def verified_context_tables(blob, routine_rows, table_rows):
    """Validate both selected phases and the translated table for marker attribution."""
    by_symbol = {row['symbol']: row for row in routine_rows}
    if len(routine_rows) != len(SECTIONS) or set(by_symbol) != set(SECTIONS):
        raise ValueError('Video dispatch attribution phase inventory differs')
    for symbol, (_, _, address) in SECTIONS.items():
        row = by_symbol[symbol]
        code, refs = bind_section(blob, symbol, address, code_bindings={})
        if (int(row['raw_offset'], 16) != address + 0x25600
                or row['bytes'] != len(code) or row['sha256'] != sha256(code).hexdigest()
                or row['le_pointers'] != len(refs)):
            raise ValueError('Video dispatch attribution phase differs')
    if len(table_rows) != 1:
        raise ValueError('Video dispatch attribution table inventory differs')
    table, _, refs, _ = bind_table(blob)
    row = table_rows[0]
    if (row['kind'] != 'compiler-generated jump table'
            or int(row['raw_offset'], 16) != BASE + 0x25600
            or row['bytes'] != SIZE or row['sha256'] != sha256(table).hexdigest()
            or row['le_pointers'] != len(refs)):
        raise ValueError('Video dispatch attribution translated table differs')
    return ((1, 0, SIZE),)
