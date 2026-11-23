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


def bind_backend_geometry(blob, address):
    if address != 0x4b1f3:
        raise ValueError('Backend geometry requires its original placement')
    # Validate the shared context and its switch before selecting another phase.
    bind_display_reset(blob, ADDRESS)
    code, data, _, calls = bind_switch_group(
        blob, base=BASE, loaded=False, symbol=PUBLIC, prefix_size=PREFIX,
        data_targets=DATA, call_targets=CALLS)
    start, end = 0x1c4, 0x203
    _, _, _, _, fixups = parsed_leaf_object(bytes(blob))
    if any(f.offset < cut < f.offset + f.width for f in fixups for cut in (start, end)):
        raise ValueError('Backend geometry fixup crosses the selected slice')
    selected = {site - start: value for site, value in data.items() if start <= site < end}
    if (tuple(sorted(selected)) != (0xb, 0x1f, 0x28, 0x33, 0x3a)
            or any(start <= site < end for site in calls)):
        raise ValueError('Backend geometry fixup inventory differs')
    return code[start:end], selected


ALLOCATION_PHASES = {
    'setgamemode_allocate_planar_': (0x203, 0x246, 0x4b232),
    'setgamemode_allocate_padded_': (0x251, 0x26c, 0x4b27a),
    'setgamemode_allocate_linear_': (0x278, 0x28d, 0x4b295),
    'setgamemode_direct_frame_': (0x28d, 0x29c, 0x4b2aa),
    'setgamemode_allocate_stereo_': (0x29c, 0x2c3, 0x4b2b9),
    'setgamemode_allocate_stereo_double_': (0x304, 0x32b, 0x4b320),
}
ALLOCATION_BRANCHES = {
    0x203: (b'\x0f\x85', 0x369, 0x4b386),
    0x221: (b'\x75', 0x237, 0x4b266),
    0x241: (b'\xe9', 0x369, 0x4b386),
    0x263: (b'\x75', 0x237, 0x4b266),
    0x26a: (b'\xeb', 0x228, 0x4b257),
    0x284: (b'\x75', 0x237, 0x4b266),
    0x28b: (b'\xeb', 0x228, 0x4b257),
    0x297: (b'\xe9', 0x369, 0x4b386),
    0x2ad: (b'\x75', 0x2c3, 0x4b2e0),
    0x315: (b'\x75', 0x32b, 0x4b347),
}


def bind_allocation_phase(blob, symbol, address):
    start, end, expected_address = ALLOCATION_PHASES[symbol]
    if address != expected_address:
        raise ValueError('Video allocation phase requires its original placement')
    bind_display_reset(blob, ADDRESS)
    code, data, pointers, calls = bind_switch_group(
        blob, base=address - start, loaded=False, symbol=PUBLIC, prefix_size=PREFIX,
        data_targets=DATA, call_targets=CALLS)
    _, _, _, _, fixups = parsed_leaf_object(bytes(blob))
    if any(f.offset < cut < f.offset + f.width for f in fixups for cut in (start, end)):
        raise ValueError('Video allocation fixup crosses the selected slice')
    if any(start <= site < end for site in pointers):
        raise ValueError('Video allocation unexpectedly includes a CODE pointer')
    code = bytearray(code)
    for site, (opcode, target, placed) in ALLOCATION_BRANCHES.items():
        if not start <= site < end:
            continue
        width = 4 if len(opcode) == 2 or opcode == b'\xe9' else 1
        operand, next_instruction = site + len(opcode), site + len(opcode) + width
        if (code[site:operand] != opcode or next_instruction > end
                or next_instruction + int.from_bytes(code[operand:next_instruction],
                                                       'little', signed=True) != target):
            raise ValueError('Video allocation compiler branch differs')
        code[operand:next_instruction] = (placed - (address + next_instruction - start)).to_bytes(
            width, 'little', signed=True)
    return bytes(code[start:end]), {site - start: value for site, value in data.items()
                                   if start <= site < end}


def verified_context_tables(blob, rows):
    phases = {ALIAS: (ADDRESS, SIZE, bind_display_reset),
              'setgamemode_backend_geometry_': (0x4b1f3, 63, bind_backend_geometry)}
    for symbol, (start, end, address) in ALLOCATION_PHASES.items():
        phases[symbol] = (address, end - start,
                          lambda blob, address, symbol=symbol: bind_allocation_phase(blob, symbol, address))
    if len(rows) != len(phases) or {row['symbol'] for row in rows} != set(phases):
        raise ValueError('Display context attribution inventory differs')
    for row in rows:
        address, size, binder = phases[row['symbol']]
        code, refs = binder(blob, address)
        if (int(row['raw_offset'], 16) != address + 0x25600 or row['bytes'] != size
                or row['sha256'] != sha256(code).hexdigest() or row['le_pointers'] != len(refs)):
            raise ValueError('Display context attribution linked slice differs')
    return ((1, 0, PREFIX),)
