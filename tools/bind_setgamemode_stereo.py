"""Checked ordinary-C phases for both stereo video state blocks."""
from hashlib import sha256

SINGLE = 'setgamemode_stereo_single_context_'
DOUBLE = 'setgamemode_stereo_double_context_'
CONTEXTS = {SINGLE: (0, 65), DOUBLE: (65, 64)}
GROUP_SHA256 = 'd0ece6c532f7c7ef4484ba1bd39a9edd781ef456f2571d9ac18c1c5ee6be508c'
DATA = {'_screen': 0x13ff0, '_frameplace': 0x286b74,
        '_video_backend': 0x2891db, '_page_flip_enabled': 0x14014,
        '_stereomode_fate': 0x286b24, '_stereopixelwidth': 0x286b44,
        '_stereowidth': 0x286b40}
# (public, compiler-relative start, byte count, original loaded address).
PHASES = {
    'setgamemode_stereo_backend_byte_': (SINGLE, 0x01, 0x02, 0x4b2e0),
    'setgamemode_stereo_flip_value_': (SINGLE, 0x19, 0x05, 0x4b2e2),
    'setgamemode_stereo_frame_': (SINGLE, 0x03, 0x11, 0x4b2e7),
    'setgamemode_stereo_flip_': (SINGLE, 0x1e, 0x06, 0x4b2f8),
    'setgamemode_stereo_mode_byte_': (SINGLE, 0x14, 0x05, 0x4b2fe),
    'setgamemode_stereo_pixel_': (SINGLE, 0x2e, 0x06, 0x4b303),
    'setgamemode_stereo_mode_width_': (SINGLE, 0x24, 0x0a, 0x4b309),
    'setgamemode_stereo_backend_width_': (SINGLE, 0x34, 0x0b, 0x4b313),
    'setgamemode_stereo_double_frame_': (DOUBLE, 0x00, 0x16, 0x4b347),
    'setgamemode_stereo_double_width_': (DOUBLE, 0x1d, 0x06, 0x4b35d),
    'setgamemode_stereo_double_zero_': (DOUBLE, 0x16, 0x02, 0x4b363),
    'setgamemode_stereo_double_pixel_': (DOUBLE, 0x2e, 0x06, 0x4b365),
    'setgamemode_stereo_double_mode_byte_': (DOUBLE, 0x18, 0x05, 0x4b36b),
    'setgamemode_stereo_double_backend_': (DOUBLE, 0x23, 0x0b, 0x4b370),
    'setgamemode_stereo_double_mode_flip_': (DOUBLE, 0x34, 0x0b, 0x4b37b),
}
FIXUPS = {
    4: '_screen', 14: '_frameplace', 21: '_video_backend',
    32: '_page_flip_enabled', 37: '_stereomode_fate',
    48: '_stereopixelwidth', 54: '_video_backend', 59: '_stereowidth',
    73: '_screen', 83: '_frameplace', 90: '_video_backend',
    96: '_stereowidth', 102: '_video_backend', 113: '_stereopixelwidth',
    118: '_stereomode_fate', 124: '_page_flip_enabled',
}


def verify_context(blob):
    from verify_c_leaf import parsed_leaf_object
    segments, publics, externals, flats, fixups = parsed_leaf_object(bytes(blob))
    if (publics != tuple((1, start, name) for name, (start, _) in CONTEXTS.items())
            or len(segments) < 2 or segments[1]['cls'] != 'CODE'
            or any(segment['data'] for segment in segments[2:])):
        raise ValueError('Stereo context public/segment layout differs')
    code = segments[1]['data']
    if len(code) != 129 or sha256(code).hexdigest() != GROUP_SHA256:
        raise ValueError('Stereo context code digest differs')
    if len(fixups) != len(FIXUPS) or {f.offset for f in fixups} != set(FIXUPS):
        raise ValueError('Stereo context fixup inventory differs')
    for fix in fixups:
        if (fix.segment != 1 or fix.width != 4 or fix.location != 9 or fix.relative
                or fix.frame[0] != 1 or fix.frame[1] not in flats
                or fix.target[0] != 2 or not 0 < fix.target[1] < len(externals)
                or externals[fix.target[1]] != FIXUPS[fix.offset]
                or fix.displacement or code[fix.offset:fix.offset + 4] != bytes(4)):
            raise ValueError('Stereo context fixup target/form/addend differs')
    return code
