"""Verify source-generated initialized DATA ranges without counting BSS or duplicates."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from verify_assembly_suite import require_disjoint


def verify(exe, directory, binaries):
    from verify_cache_unit import verify as cache_verify
    from verify_network_defaults import verify as defaults_verify
    from check_realcom import verify as handler_verify
    from verify_nearby_force_constants import verify as force_verify
    from verify_startup_strings import verify as strings_verify
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    cache = cache_verify(exe, (directory/'cacheunt.obj').read_bytes())
    defaults = defaults_verify(exe, (directory/'netdefs.obj').read_bytes())
    handler = handler_verify(exe, (binaries/'realcom.bin').read_bytes())
    force = force_verify(exe, (directory/'forcecon.obj').read_bytes())
    rows = [dict(kind='nearby-force floating constants', object='forcecon.obj',
                 object_sha256=force['object_sha256'], bytes=force['bytes'],
                 raw_offset=force['raw_file_offset'], ds_offset=force['data_object_offset'])]
    for segment, size in [('CONST', cache['diagnostic_bytes']),
                          ('DATA', cache['matching_initialized_data_bytes']-cache['diagnostic_bytes'])]:
        rows.append(dict(kind='cache '+segment, object='cacheunt.obj',
                         object_sha256=cache['object_sha256'], bytes=size,
                         raw_offset=cache['initialized_raw_offsets'][segment]))
    for row in defaults['scalars']:
        rows.append(dict(row, kind='network scalar', object='netdefs.obj',
                         object_sha256=defaults['object_sha256']))
    rows.append(dict(kind='real-mode handler stored in DATA', binary='realcom.bin',
                     payload_sha256=handler['payload_sha256'], bytes=handler['initialized_bytes'],
                     raw_offset=handler['raw_offset'], ds_offset=handler['ds_offset']))
    strings = strings_verify(exe, (directory/'maintext.obj').read_bytes())
    rows.append(dict(kind='startup strings', object='maintext.obj',
                     object_sha256=strings['object_sha256'], bytes=strings['bytes'],
                     raw_offset=strings['raw_offset'], ds_offset=strings['ds_offset']))
    from verify_animation_defaults import verify as animation_verify, verify_scalars
    animation = animation_verify(exe, (directory/'animdefs.obj').read_bytes())
    rows.append(dict(kind='animation defaults', object='animdefs.obj',
                     object_sha256=animation['object_sha256'], bytes=animation['bytes'],
                     raw_offset=animation['raw_offset'], ds_offset=animation['ds_offset']))
    mouse = verify_scalars(exe, (directory/'mousedef.obj').read_bytes(), 0xaf081,
                           0x13a81, 8, [('_mouse_scale_x', 0), ('_mouse_scale_y', 4)])
    rows.append(dict(kind='mouse sensitivity defaults', object='mousedef.obj',
                     object_sha256=mouse['object_sha256'], bytes=mouse['bytes'],
                     raw_offset=mouse['raw_offset'], ds_offset=mouse['ds_offset']))
    navigation = verify_scalars(exe, (directory/'navdata.obj').read_bytes(), 0xa031c,
                                0x4d1c, 56008, [('_board_path_data', 0)])
    rows.append(dict(kind='board navigation layouts', object='navdata.obj',
                     object_sha256=navigation['object_sha256'], bytes=navigation['bytes'],
                     payload_sha256=navigation['payload_sha256'],
                     raw_offset=navigation['raw_offset'], ds_offset=navigation['ds_offset']))
    from check_start_hook import image
    loaded = image(exe)
    pointers = read_le_fixups(exe)['pointers']
    for kind, binary, raw, ds, size in (
        ('level modification and status strings', 'level_modification_strings.bin', 0x9b658, 0x58, 160),
        ('save game file and status strings', 'save_game_strings.bin', 0x9bbdc, 0x5dc, 63),
        ('save slot menu strings', 'save_slot_menu_strings.bin', 0x9c319, 0xd19, 107),
        ('game timer diagnostics', 'game_timer_messages.bin', 0x9bc1c, 0x61c, 184),
        ('game audio configuration and diagnostics', 'game_audio_strings.bin', 0x9bcd4, 0x6d4, 624),
        ('configuration digit and Boolean strings', 'configuration_strings.bin', 0x9bf44, 0x944, 28),
        ('video settings filename', 'video_settings_filename.bin', 0x9bfc1, 0x9c1, 10),
        ('video menu and command-line help', 'video_menu_strings.bin', 0x9c051, 0xa51, 303),
        ('CD audio status messages', 'cd_audio_messages.bin', 0x9c180, 0xb80, 58),
        ('text archive filename and diagnostics', 'text_archive_strings.bin', 0x9c1bc, 0xbbc, 74),
        ('game configuration filename', 'game_configuration_filename.bin', 0x9c2e4, 0xce4, 11),
        ('game tile archive and allocation diagnostic', 'game_subsystem_strings.bin', 0x9c91c, 0x131c, 42),
        ('crusher runtime diagnostics', 'crusher_runtime_strings.bin', 0x9ca5c, 0x145c, 564),
        ('crusher sprite diagnostics', 'crushed_sprite_strings.bin', 0x9cd10, 0x1710, 55),
        ('network startup diagnostics', 'network_startup_messages.bin', 0x9cecc, 0x18cc, 81),
        ('VESA signatures and diagnostics', 'vesa_mode_messages.bin', 0x9cfe2, 0x19e2, 79),
        ('engine signature and video mode strings', 'video_mode_strings.bin', 0x9d031, 0x1a31, 200),
        ('engine frame rate format', 'frame_rate_format.bin', 0x9d1df, 0x1bdf, 29),
        ('audio driver and timer defaults', 'audio_timer_defaults.bin', 0xb1c50, 0x16650, 448),
        ('audio detector initial state', 'audio_detector_state.bin', 0xb1e10, 0x16810, 500),
        ('audio driver exchange and mixer state', 'audio_mixer_state.bin', 0xb210c, 0x16b0c, 324),
        ('runtime static stream defaults', 'static_stream_defaults.bin', 0xaf84e, 0x1424e, 527),
        ('real-mode IPX callback stored in DATA', 'ipx_receive_callback.bin', 0xaf466, 0x13e66, 384),
        ('Build video and capture defaults', 'video_state_defaults.bin', 0xaf5e6, 0x13fe6, 446),
        ('keyboard binding defaults', 'key_binding_defaults.bin', 0xaec1c, 0x1361c, 58),
        ('input and audio pan defaults', 'audio_pan_defaults.bin', 0xae228, 0x12c28, 200),
        ('runtime heap defaults', 'runtime_heap_defaults.bin', 0xb2a92, 0x17492, 10),
        ('runtime x87 emulator state', 'fpu_emulator_defaults.bin', 0xb2a10, 0x17410, 128),
        ('graphics font descriptor defaults', 'graphics_font_descriptor_defaults.bin', 0xb414e, 0x18b4e, 14),
        ('HMI status messages', 'hmi_status_messages.bin', 0x9d24a, 0x1c4a, 566),
        ('HMI driver modes and selectors', 'hmi_driver_tables.bin', 0xb2064, 0x16a64, 32),
        ('engine video allocation diagnostics', 'video_allocation_messages.bin', 0x9d0f9, 0x1af9, 220),
        ('DPMI video memory diagnostics', 'dpmi_video_messages.bin', 0x9cf44, 0x1944, 158),
        ('gameplay board modification extension', 'gameplay_mod_extension.bin', 0x9b8d0, 0x2d0, 5),
        ('fatal error newline', 'fate_error_newline.bin', 0x9ba0c, 0x40c, 2),
        ('game shutdown message', 'fate_game_over_message.bin', 0x9c948, 0x1348, 17),
        ('game subsystem flags', 'fate_shutdown_flags.bin', 0xaf1a8, 0x13ba8, 8),
        ('numbered board extension and diagnostics', 'numbered_board_messages.bin', 0x9ba84, 0x484, 69),
        ('board preparation diagnostics', 'board_setup_messages.bin', 0x9bacc, 0x4cc, 53),
        ('player health messages', 'player_health_messages.bin', 0x9bb1e, 0x51e, 24),
        ('board loader extensions and diagnostics', 'board_loader_messages.bin', 0x9ba10, 0x410, 115),
        ('actor restoration diagnostic', 'restore_actor_message.bin', 0x9b9e0, 0x3e0, 43),
        ('weapon animation tables after shared offset', 'weapon_animation_tables.bin', 0xade6a, 0x1286a, 958),
        ('board script configuration and defaults', 'level_script_defaults.bin', 0xaddf4, 0x127f4, 118),
        ('navigation and puzzle state defaults', 'navigation_puzzle_defaults.bin', 0xadde4, 0x127e4, 16),
        ('level transition defaults and board names', 'level_name_defaults.bin', 0x9d62c, 0x202c, 561),
        ('inventory, actor waypoints and sprite templates', 'actor_initial_state.bin', 0x9d85d, 0x225d, 2431),
        ('interaction configuration and defaults', 'interaction_configuration.bin', 0x9f1ec, 0x3bec, 280),
        ('interaction defaults and sprite templates', 'interaction_sprite_templates.bin', 0x9e1dc, 0x2bdc, 4112),
        ('terminal records and inventory defaults', 'terminal_and_inventory_defaults.bin', 0x9f404, 0x3e04, 3864),
        ('key names and action captions', 'key_binding_captions.bin', 0x9c384, 0xd84, 719),
        ('main menu captions', 'main_menu_captions.bin', 0x9c206, 0xc06, 222),
        ('configuration menu captions', 'configuration_menu_captions.bin', 0x9c653, 0x1053, 713),
        ('keyboard scan code to ASCII tables', 'keyboard_ascii_tables.bin', 0x9f304, 0x3d04, 256),
        ('sprite navigation diagnostics', 'sprite_navigation_messages.bin', 0x9b978, 0x378, 103),
        ('sprite path diagnostics', 'sprite_path_messages.bin', 0x9b8d8, 0x2d8, 158),
        ('level board transition diagnostics', 'level_board_transition_messages.bin', 0x9b888, 0x288, 71),
        ('teleport terminal diagnostic', 'teleport_terminal_message.bin', 0x9b868, 0x268, 29),
        ('float sprite list overflow diagnostic', 'float_sprites_message.bin', 0x9b844, 0x244, 34),
        ('actor projectile list overflow diagnostic', 'actor_projectile_message.bin', 0x9b7f8, 0x1f8, 33),
        ('projectile list overflow diagnostic', 'player_projectile_message.bin', 0x9b7d4, 0x1d4, 34),
        ('sector panning overflow diagnostic', 'sector_panning_message.bin', 0x9b78c, 0x18c, 36),
        ('graphics vendor mode numbers', 'graphics_vendor_modes.bin', 0xb2748, 0x17148, 132),
        ('graphics two-plane color map', 'graphics_two_plane_colors.bin', 0xb24c4, 0x16ec4, 4),
        ('planar graphics logical operation bits', 'graphics_planar_actions.bin', 0xb24c0, 0x16ec0, 4),
        ('Hercules CRT timing registers', 'graphics_hercules_crtc.bin', 0xb2464, 0x16e64, 12),
        ('graphics adapter classes and memory sizes', 'graphics_adapter_classes.bin', 0xb231c, 0x16d1c, 88),
        ('graphics fill pattern defaults', 'graphics_fill_defaults.bin', 0xb2284, 0x16c84, 19),
        ('graphics EGA palette tables', 'graphics_ega_palette.bin', 0xb298c, 0x1738c, 68),
        ('graphics adapter ROM signatures', 'graphics_rom_signatures.bin', 0x9d4fc, 0x1efc, 27),
        ('graphics adapter mode masks', 'graphics_mode_masks.bin', 0xb4f5c, 0x1995c, 72),
        ('graphics coordinate defaults', 'graphics_coordinate_defaults.bin', 0xb22d5, 0x16cd5, 34),
        ('HMI detector filename', 'audio_detector_filename.bin', 0x9d4f0, 0x1ef0, 11),
        ('HMI driver filename', 'audio_driver_filename.bin', 0x9d480, 0x1e80, 11),
        ('delimiter bit masks', 'delimiter_bit_masks.bin', 0x9d624, 0x2024, 8),
        ('runtime file translation default', 'stdio_mode.bin', 0xafa5d, 0x1445d, 4),
        ('runtime random seed', 'rand_seed.bin', 0xaf7a4, 0x141a4, 4),
        ('runtime DOS errno mapping', 'dos_errno_table.bin', 0xb209c, 0x16a9c, 20),
        ('runtime PATH variable name', 'spawn_path_variable.bin', 0x9d518, 0x1f18, 5),
        ('runtime stack selector and overflow message', 'stack_defaults.bin', 0xb2250, 0x16c50, 20),
        ('runtime initial x87 control word', 'fpu_default.bin', 0xb2a90, 0x17490, 2),
        ('runtime DPMI vendor name', 'fpu_vendor.bin', 0x9d4b0, 0x1eb0, 16),
        ('runtime shell and spawn strings', 'system_strings.bin', 0x9d1fc, 0x1bfc, 78),
        ('missing floating-point support message', 'float_message.bin', 0x9d48c, 0x1e8c, 36),
    ):
        payload = (binaries/binary).read_bytes()
        address = 0x80000 + ds
        if (len(payload) != size or payload != exe[raw:raw + size]
                or payload != loaded[address:address + size]
                or any(address <= site < address + size for site in pointers)):
            raise ValueError(f'{kind} DATA differs')
        rows.append(dict(kind=kind, binary=binary, bytes=size,
                         payload_sha256=hashlib.sha256(payload).hexdigest(),
                         raw_offset=hex(raw), ds_offset=hex(ds)))
    for kind, binary, raw, ds, target_base, targets in (
        ('graphics bitmap dispatch defaults', 'graphics_bitmap_defaults.bin', 0xb4fac, 0x199ac,
         0x10000, (0x73b60, 0x73b6f)),
        ('graphics bank selectors', 'graphics_bank_selectors.bin', 0xb27cc, 0x171cc,
         0x10000, (0x7286a, 0x72897, 0x72912, 0x72936, 0x72963, 0x72986, 0x729a9, 0x729cc,
          0x729f2, 0x72a20, 0x72a4d, 0x72912)),
        ('configuration digit string pointer', 'configuration_hex_pointer.bin', 0xae2f0, 0x12cf0,
         0x80000, (0x80944,)),
        ('graphics font descriptors', 'graphics_font_descriptors.bin', 0xb4146, 0x18b46,
         0x80000, (0x986c4, 0x97ec4)),
        ('HMI status message pointers', 'hmi_status_pointers.bin', 0xb2004, 0x16a04,
         0x80000, (0x81c4c, 0x81c72, 0x81c91, 0x81cab, 0x81cd3, 0x81ce5,
                   0x81cff, 0x81d11, 0x81d22, 0x81d4b, 0x81d78, 0x81d87,
                   0x81d9c, 0x81db4, 0x81dc8, 0x81dda, 0x81df5, 0x81e04,
                   0x81e12, 0x81e20, 0x81e32, 0x81e49, 0x81e56, 0x81e6c)),
        ('HMI driver initialization dispatch', 'hmi_driver_close_dispatch.bin', 0xb2084, 0x16a84,
         0x10000, (0x620d6, 0x620f9, 0x6211c, 0x6213f, 0x62162)),
    ):
        payload = (binaries/binary).read_bytes()
        size = 4 * len(targets)
        address = 0x80000 + ds
        expected_sites = {address + 4*i: target for i, target in enumerate(targets)}
        if (len(payload) != size or payload != exe[raw:raw + size]
                or {site: value for site, value in pointers.items()
                    if address <= site < address + size} != expected_sites
                or struct.unpack(f'<{len(targets)}I', payload) != tuple(t - target_base for t in targets)
                or loaded[address:address + size] != struct.pack(f'<{len(targets)}I', *targets)):
            raise ValueError(f'{kind} DATA differs')
        rows.append(dict(kind=kind, binary=binary, bytes=size,
                         payload_sha256=hashlib.sha256(payload).hexdigest(),
                         raw_offset=hex(raw), ds_offset=hex(ds), le_targets=len(targets)))
    # Verify repeated pointer fields and retain the surrounding scalar fields.
    for binary, ds, size, offsets, target_base in (
        ('crt_startup_defaults.bin', 0x14461, 173, (0, 68), (0x80000, 0x10000)),
        ('difficulty_audio_control_menus.bin', 0x13a89, 287,
         (*range(10, 199, 21), *range(218, 281, 21)), 0x80000),
        ('graphics_hercules_device_table.bin', 0x16e70, 80, range(0, 80, 4), 0x10000),
        ('graphics_cga_device_tables.bin', 0x16d74, 240, range(0, 176, 4), 0x10000),
        ('graphics_planar_device_tables.bin', 0x16ec8, 640, range(0, 640, 4), 0x10000),
        ('graphics_banked_device_tables.bin', 0x171fc, 400, range(0, 400, 4), 0x10000),
        ('graphics_mode_device_map.bin', 0x141c4, 138, range(2, 134, 6), 0x80000),
        ('key_scan_name_pointers.bin', 0x13154, 1024, range(0, 1024, 4), 0x80000),
        ('key_binding_action_table.bin', 0x13554, 200, range(4, 204, 8), 0x80000),
        ('key_binding_menu_records.bin', 0x13656, 525, range(3, 528, 21), 0x80000),
        ('video_configuration_defaults.bin', 0x12cf4, 144, range(36, 84, 4), 0x80000),
        ('main_menu_records.bin', 0x12e18, 828,
         (*range(3, 465, 21), 507, 528, *range(719, 824, 21)), 0x80000),
        ('options_menu_records.bin', 0x13863, 542,
         (*range(3, 171, 21), *range(172, 277, 21), 319, 340, 361,
          381, 385, 389, 393, 404, 408, 412, *range(419, 545, 21)), 0x80000),
    ):
        payload = (binaries/binary).read_bytes()
        address = 0x80000 + ds
        raw = 0x9b600 + ds
        if len(payload) != size or payload != exe[raw:raw + size]:
            raise ValueError(f'{binary} DATA differs')
        expected = {}
        relocated = bytearray(payload)
        bases = (target_base,) * len(offsets) if isinstance(target_base, int) else target_base
        for offset, base in zip(offsets, bases, strict=True):
            target = struct.unpack_from('<I', payload, offset)[0] + base
            expected[address + offset] = target
            struct.pack_into('<I', relocated, offset, target)
        if ({site: target for site, target in pointers.items()
                if address <= site < address + size} != expected
                or loaded[address:address + size] != relocated):
            raise ValueError(f'{binary} DATA relocation differs')
        rows.append(dict(kind=binary.removesuffix('.bin').replace('_', ' '),
                         binary=binary, bytes=size,
                         payload_sha256=hashlib.sha256(payload).hexdigest(),
                         raw_offset=hex(raw), ds_offset=hex(ds), le_targets=len(offsets)))
    raw, ds = 0xafb0e, 0x1450e
    size = 0x16650 - ds
    address = 0x80000 + ds
    irq_defaults = (binaries/'irq_stack_defaults.bin').read_bytes()
    irq_stack_top = 0x1651e
    irq_targets = {address: 0x80000 + irq_stack_top}
    if (len(irq_defaults) != size or irq_defaults != exe[raw:raw + size]
            or {site: target for site, target in pointers.items()
                if address <= site < address + size} != irq_targets
            or struct.unpack_from('<I', irq_defaults)[0] != irq_stack_top
            or loaded[address:address + size] != struct.pack('<I', irq_targets[address]) + irq_defaults[4:]):
        raise ValueError('HMI interrupt stack defaults DATA differs')
    rows.append(dict(kind='HMI interrupt stack and driver state',
                     binary='irq_stack_defaults.bin', bytes=size,
                     payload_sha256=hashlib.sha256(irq_defaults).hexdigest(),
                     raw_offset=hex(raw), ds_offset=hex(ds), le_targets=1))
    raw, ds = 0xb20b4, 0x16ab4
    descriptor_defaults = (binaries/'dos_descriptor_defaults.bin').read_bytes()
    address = 0x80000 + ds
    size, pointer_offset, table_offset = 88, 84, 4
    targets = {address + pointer_offset: address + table_offset}
    if (len(descriptor_defaults) != size or descriptor_defaults != exe[raw:raw + size]
            or {site: target for site, target in pointers.items()
                if address <= site < address + size} != targets
            or struct.unpack_from('<I', descriptor_defaults, pointer_offset)[0] != ds + table_offset):
        raise ValueError('DOS descriptor defaults DATA differs')
    relocated = bytearray(descriptor_defaults)
    struct.pack_into('<I', relocated, pointer_offset, address + table_offset)
    if relocated != loaded[address:address + size]:
        raise ValueError('Loaded DOS descriptor defaults DATA differs')
    rows.append(dict(kind='runtime DOS descriptor defaults',
                     binary='dos_descriptor_defaults.bin', bytes=size,
                     payload_sha256=hashlib.sha256(descriptor_defaults).hexdigest(),
                     raw_offset=hex(raw), ds_offset=hex(ds), le_targets=len(targets)))
    raw, ds = 0xaf7ac, 0x141ac
    hooks = (binaries/'exit_hooks.bin').read_bytes()
    address = 0x80000 + ds
    targets = {address + offset: 0x60352 for offset in (0, 4, 8)}
    if (len(hooks) != 12 or hooks != exe[raw:raw + 12]
            or {site: target for site, target in pointers.items()
                if address <= site < address + 12} != targets
            or any(value + 0x10000 != target
                   for value, target in zip(struct.unpack('<3I', hooks), targets.values()))
            or loaded[address:address + 12] != struct.pack('<3I', *targets.values())):
        raise ValueError('Runtime exit hook DATA differs')
    rows.append(dict(kind='runtime exit hooks', binary='exit_hooks.bin', bytes=12,
                     payload_sha256=hashlib.sha256(hooks).hexdigest(),
                     raw_offset=hex(raw), ds_offset=hex(ds), le_targets=3))
    raw, ds = 0xb29d0, 0x173d0
    callbacks = (binaries/'float_callbacks.bin').read_bytes()
    address = 0x80000 + ds
    target = 0x6747f
    targets = {address: target, address + 4: target}
    if (len(callbacks) != 8 or callbacks != exe[raw:raw + 8]
            or {site: value for site, value in pointers.items()
                if address <= site < address + 8} != targets
            or struct.unpack('<2I', callbacks) != (target - 0x10000,) * 2
            or loaded[address:address + 8] != struct.pack('<2I', target, target)):
        raise ValueError('Runtime floating-point callback DATA differs')
    rows.append(dict(kind='runtime floating-point callback defaults',
                     binary='float_callbacks.bin', bytes=8,
                     payload_sha256=hashlib.sha256(callbacks).hexdigest(),
                     raw_offset=hex(raw), ds_offset=hex(ds), le_targets=2))
    raw, ds = 0xb2a08, 0x17408
    hooks = (binaries/'spawn_defaults.bin').read_bytes()
    address = 0x80000 + ds
    target = 0x6792b
    targets = {address: target, address + 4: target}
    if (len(hooks) != 8 or hooks != exe[raw:raw + 8]
            or {site: value for site, value in pointers.items()
                if address <= site < address + 8} != targets
            or struct.unpack('<2I', hooks) != (target - 0x10000,) * 2
            or loaded[address:address + 8] != struct.pack('<2I', target, target)):
        raise ValueError('Runtime spawn callback DATA differs')
    rows.append(dict(kind='runtime spawn callback defaults',
                     binary='spawn_defaults.bin', bytes=8,
                     payload_sha256=hashlib.sha256(hooks).hexdigest(),
                     raw_offset=hex(raw), ds_offset=hex(ds), le_targets=2))
    raw, ds = 0xb4fb4, 0x199b4
    tables = (binaries/'crt_tables.bin').read_bytes()
    targets = (0x63415, 0x60322, 0x6463b, 0x6adc6, 0x67010, 0x6e6b9, 0x60327, 0x6ae3e)
    size = 6 * len(targets)
    header = struct.unpack_from('<I', exe, 0x3c)[0]
    pages, = struct.unpack_from('<I', exe, header + 0x14)
    page_size, final_page_size = struct.unpack_from('<II', exe, header + 0x28)
    page_data, = struct.unpack_from('<I', exe, header + 0x80)
    stored_end = page_data + (pages - 1) * page_size + final_page_size
    stored_size = size - 1
    address = 0x80000 + ds
    expected = {address + 6 * i + 2: target for i, target in enumerate(targets)}
    if (len(tables) != size or stored_end != len(exe) or stored_end != raw + stored_size
            or tables[:stored_size] != exe[raw:stored_end] or tables[stored_size:] != b'\0'
            or {site: target for site, target in pointers.items()
                if address <= site < address + size} != expected):
        raise ValueError('CRT table DATA differs')
    relocated = bytearray(tables)
    for site, target in expected.items():
        offset = site - address
        if struct.unpack_from('<I', tables, offset)[0] + 0x10000 != target:
            raise ValueError('CRT table CODE operand differs')
        struct.pack_into('<I', relocated, offset, target)
    if relocated != loaded[address:address + size]:
        raise ValueError('Loaded CRT table DATA differs')
    rows.append(dict(kind='CRT initializer and finalizer records',
                     binary='crt_tables.bin', bytes=stored_size, loaded_bytes=size,
                     payload_sha256=hashlib.sha256(tables).hexdigest(),
                     raw_offset=hex(raw), ds_offset=hex(ds), le_targets=len(expected)))
    residual = (binaries/'remaining_initialized_data.bin').read_bytes()
    offset = 0
    for ds, size, sites in (
        (0x0, 4, ()),
        (0x56, 2, ()),
        (0x108, 132, ()),
        (0x1b0, 36, ()),
        (0x1f6, 2, ()),
        (0x219, 43, ()),
        (0x266, 2, ()),
        (0x285, 3, ()),
        (0x2cf, 1, ()),
        (0x2d5, 3, ()),
        (0x376, 2, ()),
        (0x3df, 1, ()),
        (0x40b, 1, ()),
        (0x40e, 2, ()),
        (0x483, 1, ()),
        (0x4c9, 3, ()),
        (0x501, 29, ()),
        (0x536, 166, ()),
        (0x61b, 1, ()),
        (0x960, 97, ()),
        (0x9cb, 134, ()),
        (0xbba, 2, ()),
        (0xcef, 42, ()),
        (0x1346, 2, ()),
        (0x1359, 259, ()),
        (0x1690, 128, ()),
        (0x1747, 1, ()),
        (0x18cb, 1, ()),
        (0x191d, 39, ()),
        (0x1bd5, 10, ()),
        (0x1e8b, 1, ()),
        (0x1ec0, 48, ()),
        (0x1efb, 1, ()),
        (0x1f17, 1, ()),
        (0x1f1d, 263, ()),
        (0x12d91, 135, ()),
        (0x13bb0, 16, ()),
        (0x13cd9, 3, ()),
        (0x141a8, 4, ()),
        (0x141b8, 12, ()),
        (0x16a98, 4, ()),
        (0x16ab0, 4, ()),
        (0x16c64, 32, ()),
        (0x16c97, 62, (26,)),
        (0x16cf7, 37, (30,)),
        (0x173d8, 48, ()),
        (0x17ec2, 2, ()),
        (0x199a4, 8, ()),
    ):
        payload = residual[offset:offset + size]
        raw = 0x9b600 + ds
        address = 0x80000 + ds
        expected = {address + site: struct.unpack_from('<I', payload, site)[0] + 0x80000
                    for site in sites}
        relocated = bytearray(payload)
        for site, target in expected.items():
            struct.pack_into('<I', relocated, site - address, target)
        if (len(payload) != size or payload != exe[raw:raw + size]
                or {site: target for site, target in pointers.items()
                    if address <= site < address + size} != expected
                or relocated != loaded[address:address + size]):
            raise ValueError(f'Remaining initialized DATA differs at DS:{ds:#x}')
        rows.append(dict(kind='initialized fields, strings or padding',
                         binary='remaining_initialized_data.bin', binary_offset=offset, bytes=size,
                         payload_sha256=hashlib.sha256(payload).hexdigest(),
                         raw_offset=hex(raw), ds_offset=hex(ds), le_targets=len(sites)))
        offset += size
    if len(residual) != offset:
        raise ValueError('Remaining initialized DATA size differs')
    require_disjoint([(int(row['raw_offset'], 16), int(row['raw_offset'], 16)+row['bytes'])
                      for row in rows])
    return dict(target_sha256=TARGET_SHA256, initialized_data_bytes=sum(row['bytes'] for row in rows),
                bss_initialized_coverage=0, final_linked_placement_verified=False,
                complete_original_modules=0, spans=rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('objects', type=Path)
    parser.add_argument('binaries', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.executable.read_bytes(), args.objects, args.binaries)
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: {result['initialized_data_bytes']} initialized DATA bytes, no overlapping ranges or BSS coverage")
