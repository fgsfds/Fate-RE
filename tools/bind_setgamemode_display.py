"""Select the video display reset while excluding its private switch table."""
from hashlib import sha256

from bind_melee_group import bind_switch_group
from verify_c_leaf import parsed_leaf_object

BASE = 0x4b02e
PUBLIC = 'setgamemode_display_context_'
ALIAS = 'setgamemode_display_reset_'
ADDRESS = 0x4b150
PREFIX = 32
PUBLIC_SIZE = 851
SIZE = 129
TABLE_TARGETS = (0x1b8, 0x246, 0x26c, 0x28d, 0x28d, 0x28d, 0x29c, 0x304)
DATA = {
    '_vidoption': 0x2891db,
    '_xdim': 0x287e90,
    '_ydim': 0x287e8c,
    '_horizlookup': 0x286ac4,
    '_horizlookup2': 0x286aec,
    '_horizycent': 0x286ae0,
    '_parallaxyoffs': 0x286b88,
    '_parallaxyscale': 0x286b8c,
    '_searchx': 0x289122,
    '_searchit': 0x28912a,
    '_xyaspect': 0x286bac,
    '_pskyoff': 0x1ed1a0,
    '_pskybits_fate': 0x289150,
    '_parallaxtype': 0x2891da,
    '_showinvisibility': 0x2891d9,
    '_paletteloaded': 0x140c2,
    '_palookup': 0x203ca0,
    '_waloff': 0x1ffca0,
    '_show2dsector': 0x1ec6a0,
    '_show2dsprite': 0x1ecfa0,
    '_show2dwall': 0x1ec920,
    '_automapping': 0x2891d8,
    '_pointhighlight': 0x289142,
    '_linehighlight': 0x28913c,
    '_highlightcnt': 0x28913a,
    '_visibility_fate': 0x286ba8,
    '_parallaxvisibility_fate': 0x286ba0,
    '_numpages_fate': 0x14004,
    '_chainstat': 0x14003,
    '_image_size': 0x286b48,
    '_chainplace': 0x286b4c,
    '_screen': 0x13ff0,
    '_frameplace': 0x286b74,
    '_stereomode_fate': 0x286b24,
    '_stereopixelwidth': 0x286b44,
    '_stereowidth': 0x286b40,
    '_page_flip_enabled': 0x14014,
    '_out_of_memory_message': 0x1af9,
    '_screen_allocation_message_0': 0x1b08,
    '_screen_allocation_message_1': 0x1b31,
    '_screen_allocation_message_2': 0x1b5a,
    '_screen_allocation_message_6': 0x1b83,
    '_screen_allocation_message_7': 0x1bac,
}
CALLS = {
    'initialize_video_backend_': 0x4a294,
    'finish_video_mode_setup_': 0x4a367,
    'engine_malloc_': 0x4478c,
    '_print_diagnostic': 0x40bb4,
    'runtime_exit_': 0x60353,
    'loadpalette_': 0x4c0b0,
}
DATA_SITES = (0x6, 0x19, 0x27, 0x35, 0x44, 0x4b, 0x52, 0x59, 0x65, 0x6b, 0x71, 0x77, 0x7d)


def bind_display_reset(blob, address):
    if address != ADDRESS:
        raise ValueError('Display reset requires its original placement')
    code, data, pointers, calls = bind_switch_group(
        blob, base=BASE, loaded=False, symbol=PUBLIC, prefix_size=PREFIX,
        data_targets=DATA, call_targets=CALLS)
    if len(code) != PREFIX + PUBLIC_SIZE:
        raise ValueError('Display context public extent differs')
    if (tuple(pointers[site] - (BASE - 0x10000) for site in range(0, PREFIX, 4)) != TABLE_TARGETS
            or set(pointers) != {*range(0, PREFIX, 4), 0x1b4}
            or code[0x1b0:0x1b4] != bytes.fromhex('2eff2485')):
        raise ValueError('Display context switch layout differs')
    start, end = ADDRESS - BASE, ADDRESS - BASE + SIZE
    _, _, _, _, fixups = parsed_leaf_object(bytes(blob))
    if any(f.offset < cut < f.offset + f.width for f in fixups for cut in (start, end)):
        raise ValueError('Display context fixup crosses the selected slice')
    selected_data = {site - start: value for site, value in data.items() if start <= site < end}
    selected_calls = {site - start: value for site, value in calls.items() if start <= site < end}
    if (tuple(sorted(selected_data)) != DATA_SITES or selected_calls != {0x5e: CALLS['loadpalette_']}
            or code[start + 0x5d] != 0xe8):
        raise ValueError('Display reset fixup inventory differs')
    return code[start:end], selected_data


def verified_context_tables(blob, rows):
    if len(rows) != 1 or rows[0]['symbol'] != ALIAS:
        raise ValueError('Display reset attribution inventory differs')
    row = rows[0]
    code, refs = bind_display_reset(blob, ADDRESS)
    if (int(row['raw_offset'], 16) != ADDRESS + 0x25600 or row['bytes'] != SIZE
            or row['sha256'] != sha256(code).hexdigest() or row['le_pointers'] != len(refs)):
        raise ValueError('Display reset attribution linked slice differs')
    return ((1, 0, PREFIX),)
