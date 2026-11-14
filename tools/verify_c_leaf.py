"""Check a compiled OMF leaf against FATE after explicit external binding.

This verifies isolated code and its fixups, not final executable linkage.
Absolute data operands use DS offsets; absolute CODE operands use code-object
offsets and explicit metadata. Relative externals require loaded code addresses.
Relative operands are checked by exact bytes, not LE pointer records.
"""
import argparse
import hashlib
from pathlib import Path
from compare_exe import TARGET_SHA256
from match_objects import read_object
from omf_fixups import Reader, read_externals, read_fixups
from le_fixups import read_le_fixups

LEAVES = {'clipinsideboxline_': (0x717b2, 225), 'inside_': (0x71e8f, 189),
          'animateoffs_': (0x75d58, 139), 'krand_': (0x7b8e5, 20),
          'getmousevalues_': (0x79a24, 68),
          'clipinsidebox_': (0x716c7, 235), 'lastwall_': (0x77ecf, 80),
          'spritewallfront_': (0x6ab27, 79),
          'updatesector_': (0x798c4, 184),
          'alignceilslope_': (0x837a7, 212), 'alignflorslope_': (0x8387b, 213),
          'allocatepermanenttile_': (0x7128e, 184), 'agecache_': (0x6652d, 113),
          'allocache_': (0x66273, 698), 'initcache_': (0x66249, 42),
          'klseek_': (0x66a51, 122), 'kfilelength_': (0x66acb, 56),
          'kclose_': (0x66b03, 39), 'plotpixel_': (0x82847, 94),
          'getpixel_': (0x828a5, 79), 'clear2dscreen_': (0x7a522, 98),
          'drawline256_': (0x79a6b, 1123),
          'uninitgroupfile_': (0x6684c, 53), 'kopen4load_': (0x66881, 252),
          'kread_': (0x6697d, 212), 'initgroupfile_': (0x6665b, 497),
          'reportandexit_': (0x6659e, 189), 'drawline16_': (0x79ece, 1225),
          'qsetmode640350_': (0x7a397, 143), 'qsetmode640480_': (0x7a426, 252),
          'draw2dgrid_': (0x7a584, 675), 'clippoly4_': (0x7e735, 639), 'remove_listed_sprite_': (0x3659f, 84),
          'stereoinit_': (0x7ef4a, 123), 'stereoblit_': (0x7f158, 150),
          'initcrc_': (0x6851a, 89), 'getcrc_': (0x68573, 72),
          'lookup_record_value_': (0x365f3, 66),
          'transmaskvline_': (0x70028, 413), 'comsend_': (0x675ce, 129),
          'netinitconnection_': (0x67919, 374), 'lookup_type_index_': (0x36635, 62), 'getpalookup_': (0x854d7, 46), 'spawn_template_sprite_': (0x36673, 302), 'insertsprite_': (0x75eb8, 21), 'add_listed_sprite_': (0x38ac2, 88),
          'convalloc32_': (0x685bb, 65), 'uninstallbicomhandlers_': (0x68843, 126),
          'raytrace_': (0x792d5, 520), 'netuninitconnection_': (0x67a8f, 93),
          'advance_sequences_': (0x379d6, 203), 'addclipline_': (0x791ed, 65),
          'installbicomhandlers_': (0x686cc, 375)}
DATA_OFFSETS = {'_conventional_memory_error': 0x191d, '_inbufplc': 0x18fdbc, '_inbufend': 0x18fdf0, '_outbufplc': 0x18fdd8, '_comport': 0x18fde8, '_comtype': 0x18fdf8, '_comerror': 0x18fe1c, '_comresend': 0x18fdf4, '_incnt': 0x18fe00, '_inbuf': 0x18fe24, '_rmbuffer': 0x13ce4, '_sequence_sprites': 0x2040a0, '_object_sequences': 0x6807c, '_active_sequence_count': 0x7dee0, '_active_sequence_sprites': 0x67a3c, '_clipobjectval': 0x196750, '_sector': 0x27c3a0, '_wall': 0x2310a0, '_numsectors': 0x289154,
                '_picanm': 0x1ed3a0, '_totalclocklock': 0x2863c0, '_randomseed': 0x287e78, '_moustat': 0x14002,
                '_sqrtable': 0x1dfa60, '_picsiz': 0x1e5fe0, '_pow2long': 0x14031,
                '_tilesizx': 0x1f2020, '_tilesizy': 0x1f4020,
                '_walock': 0x1f8ca0, '_waloff': 0x1ffca0,
                '_agecount': 0x13bd1, '_cacnum': 0x13bcd, '_lockptr': 0x17eca4,
                '_cachecount': 0x13bc0, '_cachestart': 0x13bc5, '_cachesize': 0x13bc9,
                '_zerochar': 0x13bc4, '_handptr': 0x17aca4, '_cacleng': 0x182ca4,
                '_cache_size_format': 0x1748, '_cache_request_format': 0x1758,
                '_cache_too_big': 0x1787, '_cache_zero_lock': 0x17a8, '_cache_all_locked': 0x17ca,
                '_filehandle': 0x13bd9, '_filepos': 0x17aba4,
                '_groupfil': 0x13bd5, '_fileoffs': 0x186cb0,
                '_chainplace': 0x286b4c, '_chainstat': 0x14003, '_frameplace': 0x286b74,
                '_ylookup': 0x286bb0, '_pageoffset': 0x286a74,
                '_qsetmode': 0x140ba, '_ydim16': 0x286a5c,
                '_palookup': 0x203ca0, '_pow2char': 0x14029,
                '_startdmost': 0x1f8020, '_startumost': 0x1f13a0,
                '_wx1': 0x286b10, '_wx2': 0x286b0c, '_wy1': 0x286b1c, '_wy2': 0x286b18,
                '_filelist': 0x186ca4, '_numfiles': 0x186ca8, '_groupfilpos': 0x186cac,
                '_group_too_many_files': 0x189e,
                '_group_list_allocation_error': 0x1846, '_group_offsets_allocation_error': 0x1872,
                '_cache_report_size': 0x17e6, '_cache_report_count': 0x17f7,
                '_cache_report_index': 0x1805, '_cache_report_handle': 0x180b,
                '_cache_report_length': 0x1817, '_cache_report_lock': 0x1823,
                '_cache_report_total': 0x182e, '_stereofps': 0x14014,
                '_rx1': 0x1cd160, '_ry1': 0x1d1160, '_rx2': 0x1cb160, '_ry2': 0x1cf160,
                '_listed_sprite_count': 0x2be8, '_listed_sprites': 0x6fcbc, '_page': 0x286b50, '_stereopixelwidth': 0x286b44,
                '_crctable': 0x18f778, '_lookup_records': 0x2c07, '_lookup_error_text': 0x12c,
                '_outbufend': 0x18fdd0, '_outbuf': 0x18fe34,
                '_dwall': 0x1a63e0, '_globalhoriz': 0x286ae4, '_globalpal': 0x286adc,
                '_globalpicnum': 0x289144, '_globalshade': 0x286a88, '_globalxpanning': 0x286abc,
                '_globalyscale': 0x286ab4, '_globalzd': 0x286a8c, '_globvis': 0x286ab8,
                '_lwall': 0x199150, '_swall': 0x1a18e0, '_transarea': 0x14008,
                '_uwall': 0x19aa60, '_viewoffset': 0x286ae8, '_windowx1': 0x286b9c,
                '_windowy1': 0x286b94, '_xdimen': 0x140b5,
                '_compaddr': 0x186d88, '_connecthead': 0x19028a, '_connectnum': 0x186d48,
                '_connectpoint2': 0x18fd78, '_myconnectindex': 0x13ce2,
                '_myconnectnum': 0x18fe30, '_numplayers': 0x13ce0, '_socket': 0x13e64,
                '_type_records': 0x2c07, '_type_lookup_error_text': 0x15c, '_numpalookups': 0x289156,
                '_record_lookup_entries': 0x2c07, '_record_icon_error': 0x12c, '_record_type_error': 0x15c,
                '_sprite_templates': 0x2bfe, '_game_sprites': 0x2040a0,
                '_sprite_old_positions': 0x20a2c, '_sprite_visibility': 0x1ecfa0,
                '_listed_sprite_records': 0x2040a0, '_listed_sprite_overflow_text': 0x21c,
                '_listed_sprite_error_buffer': 0x67e3c,
                '_comvect': 0x18fe04, '_orig_pm_off': 0x18fe20, '_orig_pm_sel': 0x190288,
                '_orig_rm_seg': 0x190284, '_orig_rm_off': 0x190286, '_clipnum': 0x289136,
                '_clipx1': 0x190b60, '_clipy1': 0x197350, '_clipx2': 0x190360, '_clipy2': 0x196b50}

# Absolute CODE pointers are object-relative, unlike loaded relative-call targets.
CODE_OFFSETS = {'comhandler_': 0x3215b}
LEAVES['ceilspritescan_'] = (0x75871, 220)
LEAVES['startcom_'] = (0x6764f, 268)
LEAVES['comhandler_'] = (0x6775b, 446)
LEAVES['simulateint_'] = (0x685fc, 208)
DATA_OFFSETS.update({
    '_RMI': 0x19028c,
    '_rmoffset32': 0x18fdc0,
    '_rmsegment16': 0x18fdec,
})
DATA_OFFSETS.update({
    '_comtemp': 0x18fe3c,
    '_comi': 0x18fe18,
})
LEAVES['append_sprite_event_'] = (0x3654e, 81)
DATA_OFFSETS.update({'_sprite_event_count': 0x3be6, '_sprite_events': 0x77124,
                     '_sprite_event_overflow_text': 0x108,
                     '_sprite_event_error_buffer': 0x67e3c})
DATA_OFFSETS['_lastx'] = 0x197d50

# Error/printing dependencies remain identified bindings, not reconstructed code.
FUNCTION_ADDRESSES = {'convalloc32_': 0x42fbb, 'sequence_remove_sprite_': 0x10f9f, 'int386_': 0x630b3, 'int386x_': 0x6309a, 'format_listed_sprite_error_': 0x601f3, 'report_listed_sprite_error_': 0x26a03, 'insertspritesect_': 0x508cd, 'insertspritestat_': 0x5096b, 'insert_template_sprite_': 0x508b8, 'record_lookup_error_': 0x26a03, 'memcpy_': 0x63245, 'type_lookup_error_': 0x26a03, 'getpalookup_': 0x5fed7, 'tvlineasm1_': 0x744d0, 'lookup_error_': 0x26a03, 'setverts_': 0x599c5, 'remove_engine_sprite_': 0x50a09, 'inside_': 0x4c88f, 'allocache_': 0x40c73,
                      'printf_': 0x40bb4, 'reportandexit_': 0x40f9e,
                      'lseek_': 0x615b6, 'filelength_': 0x63208, 'close_': 0x6219a, 'outpw_': 0x63320,
                      'kfree_': 0x44791, 'read_': 0x615f7, 'min_': 0x63201,
                      'open_': 0x61368, 'exit_': 0x60353, 'kmalloc_': 0x4478c, 'uninitgroupfile_': 0x4124c, 'drawline16_': 0x548ce}


FUNCTION_ADDRESSES.update({
    'ceilspritehline_': 0x5034d,
    'faketimerhandler_': 0x31ec4,
})
FUNCTION_ADDRESSES.update({'format_sprite_event_error_': 0x601f3,
                           'report_sprite_event_error_': 0x26a03})
FUNCTION_ADDRESSES['__GETDS'] = 0x601d4
FUNCTION_ADDRESSES['memset_'] = 0x61350


LEAVES['ceilspritehline_'] = (0x7594d, 937)
DATA_OFFSETS.update({
    '_asm1': 0x286aa4,
    '_asm2': 0x286aa8,
    '_asm3': 0x286aac,
    '_globalbufplc': 0x286a90,
    '_globalorientation': 0x286a84,
    '_globalx1': 0x286a80,
    '_globalx2': 0x286a4c,
    '_globaly1': 0x286a50,
    '_globaly2': 0x286a58,
    '_globalypanning': 0x286ac0,
    '_horizlookup': 0x286ac4,
    '_horizycent': 0x286ae0,
})
FUNCTION_ADDRESSES.update({
    'mhline_': 0x74a80,
    'mhlineskipmodify_': 0x74ad0,
    'thline_': 0x74bf0,
    'thlineskipmodify_': 0x74c40,
})


LEAVES['activate_initial_crushers_'] = (0x65868, 111)
LEAVES['find_crush_sector_'] = (0x658d7, 87)
DATA_OFFSETS.update({
    '_dispatch_crush_banks': 0x174640,
    '_dispatch_crush_silent': 0x13bb0,
    '_dispatch_invalid_bank': 0x13e6,
    '_dispatch_disabled_bank': 0x1406,
    '_lookup_invalid_bank': 0x1429,
    '_lookup_disabled_bank': 0x1441,
})
FUNCTION_ADDRESSES.update({
    'dispatch_crush_error_': 0x26a03,
    'dispatch_crush_activate_': 0x40849,
})
LEAVES['loop_finish_'] = (0x5a86c, 425)
LEAVES['getanimationgoal_'] = (0x545a1, 31)
LEAVES['setanimation_'] = (0x545c0, 117)
DATA_OFFSETS.update({
    '_audio_enabled': 0x171602,
    '_audio_tick': 0x770b8,
    '_audio_last_tick': 0x1714e4,
    '_audio_listener_x': 0x5ad9c,
    '_audio_listener_y': 0x5ad5c,
    '_audio_driver': 0x12cd0,
    '_audio_sources': 0x854dc,
    '_sprite': 0x2040a0,
    '_audio_channels': 0x170608,
    '_animatecnt': 0x3e04,
    '_animateptr': 0x1a234,
    '_animategoal': 0x1b234,
    '_animatevel': 0x1aa34,
    '_animateacc': 0x19a04,
})
FUNCTION_ADDRESSES.update({
    'audio_volume_': 0x34e1b,
    'audio_pan_': 0x34e77,
    'audio_sprite_pan_': 0x34f18,
    'labs_': 0x602c3,
    'audio_set_volume_': 0x62480,
    'audio_set_pan_': 0x6266a,
    'setinterpolation_': 0x344e4,
})
LEAVES['dispatch_ticks_'] = (0x5aa15, 13)
LEAVES['dispatch_period_'] = (0x5aa22, 84)
LEAVES['dispatch_menu_'] = (0x5ac04, 48)
LEAVES['main_step_d_'] = (0x5ac34, 79)
DATA_OFFSETS.update({
    '_dispatch_mode': 0x772bc,
    '_dispatch_active': 0x77118,
    '_dispatch_play': 0x772b8,
})
FUNCTION_ADDRESSES.update({
    'dispatch_set_': 0x3662e,
    'dispatch_prepare_': 0x35476,
    'dispatch_poll_': 0x35545,
    'dispatch_command_': 0x3a148,
    'game_loop_': 0x3b496,
    'dispatch_menu_': 0x35604,
})
LEAVES['game_loop_'] = (0x60a96, 371)
DATA_OFFSETS.update({
    '_loop_running': 0x3ce9,
    '_loop_exit': 0x6793d,
    '_loop_candidate': 0x7dee4,
    '_loop_request_a': 0x3be6,
    '_loop_request_b': 0x2bdc,
    '_loop_candidate_b': 0x7dee6,
    '_loop_toggle_a': 0x2297,
    '_loop_toggle_b': 0x2299,
    '_loop_skip_neighbors': 0x2bfa,
    '_loop_sector': 0x5acfc,
    '_loop_scale': 0x3cfa,
    '_loop_last_tick': 0x202c,
    '_loop_queue_read': 0x770cc,
    '_loop_queue_write': 0x770c4,
    '_loop_updates': 0x7a994,
    '_main_state_b': 0x3cee,
    '_totalclock': 0x287e88,
    '_sector': 0x27c3a0,
    '_wall': 0x2310a0,
})
FUNCTION_ADDRESSES.update({
    'loop_poll_': 0x111a1,
    'loop_process_': 0x2d23e,
    'loop_special_': 0x109f9,
    'loop_mark_': 0x2949c,
    'loop_render_': 0x14133,
    'loop_timing_': 0x2c48d,
    'loop_finish_': 0x3526c,
})
LEAVES['is_crush_sector_'] = (0x652cb, 70)
LEAVES['clear_crush_bank_'] = (0x65311, 206)
DATA_OFFSETS.update({
    '_crush_num_sectors': 0x289154,
    '_crush_sectors': 0x27c3a0,
    '_crush_invalid_sector_text': 0x1368,
    '_crush_banks': 0x174640,
    '_crush_invalid_bank_text': 0x1387,
})
FUNCTION_ADDRESSES.update({
    'crush_report_error_': 0x26a03,
})
LEAVES['init_object_sequences_'] = (0x60c09, 18114)
DATA_OFFSETS['_object_sequence_definitions'] = 0x6807c
LEAVES['main_load_selection_'] = (0x60a04, 146)
DATA_OFFSETS.update({
    '_main_resource': 0x1e5ac,
    '_selection_names': 0x2041,
    '_selection_terminator': 0x135c,
    '_selection_extension': 0x1361,
    '_selection_scan': 0x7f87e,
    '_selection_current': 0x7f87d,
})
FUNCTION_ADDRESSES.update({
    'strcpy_': 0x60333,
    'stricmp_': 0x62d95,
    'strcat_': 0x60223,
})
LEAVES['main_run_'] = (0x6094d, 183)
DATA_OFFSETS.update({
    '_shutdown_network': 0x13ba8,
    '_shutdown_b': 0x13ba9,
    '_shutdown_c': 0x13baa,
    '_shutdown_d': 0x13bab,
    '_shutdown_e': 0x13bac,
    '_shutdown_video': 0x13bad,
    '_shutdown_group': 0x13bae,
    '_shutdown_h': 0x13baf,
    '_shutdown_message': 0x1348,
})
FUNCTION_ADDRESSES.update({
    'uninitmultiplayers_': 0x4164f,
    'shutdown_step_b_': 0x34bf6,
    'shutdown_step_c_': 0x37a68,
    'shutdown_step_d_': 0x34860,
    'shutdown_step_e_': 0x2f258,
    'uninitengine_': 0x4b390,
    'uninitgroupfile_': 0x4124c,
    'shutdown_step_h_': 0x380b4,
    'printf_': 0x40bb4,
})
LEAVES['main_prepare_callback_'] = (0x35610, 28)
DATA_OFFSETS['_main_cleanup_message'] = 4
LEAVES['main_'] = (0x3562c, 244)
DATA_OFFSETS.update({
    '_main_group_name': 0x30,
    '_main_load_error': 0x3a,
    '_main_default_selection': 0x50,
    '_main_resource': 0x1e5ac,
    '_main_indices': 0x7d2e2,
    '_main_records': 0x78a3c,
    '_main_before_players': 0x770d0,
    '_main_state_a': 0x3cea,
    '_main_state_b': 0x3cee,
    '_main_state_c': 0x770d4,
    '_main_finished': 0x3e08,
})
FUNCTION_ADDRESSES.update({
    'main_prepare_': 0x40c0d,
    'main_init_sequences_': 0x3b609,
    'initgroupfile_': 0x4105b,
    'main_get_selection_': 0x37524,
    'main_load_selection_': 0x3b404,
    'main_report_': 0x26a03,
    'main_step_a_': 0x3b272,
    'main_step_b_': 0x1e91a,
    'main_install_resource_': 0x27a8c,
    'main_step_c_': 0x383d2,
    'main_initialize_player_': 0x2e14f,
    'main_reset_timer_': 0x4c0b0,
    'main_step_d_': 0x35634,
    'main_step_e_': 0x4367c,
    'main_step_f_': 0x38a16,
    'main_run_': 0x3b34d,
})
CODE_OFFSETS.update({
    'main_prepare_callback_': 0x10,
})


LEAVES['dispatch_prepare_'] = (0x5aa76, 207)
LEAVES['dispatch_poll_'] = (0x5ab45, 191)
LEAVES['setinterpolation_'] = (0x59ae4, 70)
LEAVES['stopinterpolation_'] = (0x59b2a, 95)
LEAVES['updateinterpolations_'] = (0x59b89, 35)
LEAVES['dointerpolations_'] = (0x59bac, 94)
LEAVES['restoreinterpolations_'] = (0x59c0a, 35)
DATA_OFFSETS.update({
    '_audio_enabled': 0x171602,
    '_audio_tick': 0x770b8,
    '_audio_last_tick': 0x1714e4,
    '_audio_listener_x': 0x5ad9c,
    '_audio_listener_y': 0x5ad5c,
    '_audio_driver': 0x12cd0,
    '_audio_sources': 0x854dc,
    '_sprite': 0x2040a0,
    '_audio_channels': 0x170608,
    '_totalclock': 0x287e88,
    '_presentation_width': 0x287e90,
    '_presentation_height': 0x287e8c,
    '_numinterpolations': 0x3cf2,
    '_startofdynamicinterpolations': 0x3cf6,
    '_smoothratio': 0x770bc,
    '_curipos': 0x2cb6c,
    '_oldipos': 0x1f9fc,
    '_bakipos': 0x1e7fc,
})
FUNCTION_ADDRESSES.update({
    'audio_volume_': 0x34e1b,
    'audio_pan_': 0x34e77,
    'audio_sprite_pan_': 0x34f18,
    'labs_': 0x602c3,
    'audio_set_volume_': 0x62480,
    'audio_set_pan_': 0x6266a,
    'dispatch_ticks_': 0x35415,
    'presentation_reset_': 0x36246,
    'presentation_input_': 0x3625c,
    'presentation_sound_': 0x34f79,
    'presentation_stop_sound_': 0x34c82,
    'clearview_': 0x5cd99,
    'rotatesprite_': 0x57181,
    'nextpage_': 0x4b496,
})
CODE_OFFSETS.update({
    '_presentation_durations': 0x247bb,
    '_presentation_pictures': 0x247d9,
})


LEAVES['presentation_reset_'] = (0x5b846, 22)
LEAVES['presentation_input_'] = (0x5b85c, 169)
LEAVES['ksqrt_'] = (0x72038, 54)
LEAVES['doanimations_'] = (0x544ae, 243)
DATA_OFFSETS.update({
    '_presentation_keys': 0x6793c,
    '_presentation_mouse_x': 0x7deda,
    '_presentation_mouse_y': 0x7dedc,
    '_presentation_buttons': 0x7dee2,
    '_presentation_previous_buttons': 0x173d34,
    '_sqrtable': 0x1dfa60,
    '_animatecnt': 0x3e04,
    '_animateptr': 0x1a234,
    '_animategoal': 0x1b234,
    '_animatevel': 0x1aa34,
    '_animateacc': 0x19a04,
})
FUNCTION_ADDRESSES.update({
    '__STOSB': 0x62de0,
    'presentation_reset_': 0x36246,
    'readmousexy_': 0x54424,
    'animation_prestep_': 0x37ee0,
    'stopinterpolation_': 0x3452a,
})


LEAVES['getangle_'] = (0x71f4c, 236)
DATA_OFFSETS['_radarang'] = 0x287e94


LEAVES['move_listed_sprite_'] = (0x38b1a, 405)
DATA_OFFSETS.update({'_move_sprites': 0x2040a0, '_move_tile_heights': 0x1f4020})
FUNCTION_ADDRESSES.update({'move_clip_': 0x5291f, 'move_change_sector_': 0x50bc3,
                           'move_zrange_': 0x562f9, 'move_add_listed_': 0x134c2})


LEAVES['audio_volume_'] = (0x5a41b, 92)
DATA_OFFSETS['_audio_listener_index'] = 0x3cfa
FUNCTION_ADDRESSES['ksqrt_'] = 0x4ca38


LEAVES['animation_prestep_'] = (0x5d4e0, 181)
DATA_OFFSETS.update({'_prestep_value': 0x12d84, '_prestep_direction': 0x12d88,
                     '_prestep_speed': 0x12d8c, '_prestep_hold': 0x12d90})


LEAVES.update({'changespritesect_': (0x761c3, 80), 'changespritestat_': (0x76213, 80)})
FUNCTION_ADDRESSES.update({'deletespritesect_': 0x50a1d, 'insertspritesect_': 0x508cd,
                           'deletespritestat_': 0x50af0, 'insertspritestat_': 0x5096b})


LEAVES.update({'activate_crush_sector_': (0x65e49, 328),
               'deletesprite_': (0x76009, 20), 'loadtables_': (0x6f894, 211)})
DATA_OFFSETS.update({'_activate_crush_banks': 1525312, '_activate_crush_sectors': 2605984, '_activate_crush_numsectors': 2658644, '_activate_crush_goals': 111156, '_activate_crush_velocity': 109108, '_activate_crush_silent': 80816, '_activate_bad_bank': 5776, '_activate_disabled': 5805, '_activate_bad_sector': 5837, '_activate_bad_slot': 5868, '_tablesloaded': 82105, '_tables_filename': 6716, '_reciptable': 1913184, '_sintable': 2293920, '_radarang': 2653844, '_textfont': 1841504, '_smalltextfont': 1921376, '_britable': 1842528})
FUNCTION_ADDRESSES.update({'activate_crush_error_': 158211, 'activate_crush_lookup_': 262871, 'activate_find_animation_': 192417, 'activate_set_animation_': 192448, 'activate_crush_sound_': 263382, 'initksqrt_': 314026, 'kopen4load_': 266881, 'kread_': 267133, 'klseek_': 267345, 'kclose_': 267523})


def flat_frame_groups(blob):
    """Identify the explicit empty FLAT groups used by the verified Watcom objects.

    Other valid OMF frames (including frame-by-target) need segment/frame placement
    metadata that this isolated binder does not possess. Do not guess their base.
    """
    names, groups, offset = [''], [], 0
    while offset < len(blob):
        header = Reader(blob[offset:offset+3])
        kind, size = header.number(), header.number(2)
        end = offset+3+size
        if size < 1 or end > len(blob):
            raise ValueError('Truncated OMF record')
        reader = Reader(blob[offset+3:end-1])
        if kind == 0x96:
            while reader.pos < len(reader.data):
                names.append(reader.name())
        elif kind == 0x9a:
            name = reader.index()
            if not 0 < name < len(names):
                raise ValueError('Group name outside LNAMES')
            groups.append(names[name] == 'FLAT' and reader.pos == len(reader.data))
        offset = end
    return {index for index, flat in enumerate(groups, 1) if flat}


def bind_leaf_details(blob, symbol, values, *, address=None, functions=None,
                      absolute_code=None, code_bindings=None):
    """Return unchanged (code, all_absolute_bindings), plus optional CODE metadata.

    code_bindings must be an empty output dict when a CODE pointer is used. It
    receives leaf-relative site -> final object-relative operand, including
    addends. Pass it to verify_leaf_relocations; it is not a relative-call map.
    """
    if code_bindings is not None and (not isinstance(code_bindings, dict) or code_bindings):
        raise ValueError('CODE binding output must be an empty dict; stale metadata rejected')
    segments, publics = read_object(blob)
    found = [(seg, off) for seg, off, name in publics if name == symbol]
    if len(found) != 1:
        raise ValueError('Expected exactly one leaf public symbol')
    seg, start = found[0]
    if segments[seg]['cls'] != 'CODE':
        raise ValueError('Leaf is not code')
    end = min([a for s, a, _ in publics if s == seg and a > start]
              or [len(segments[seg]['data'])])
    code = bytearray(segments[seg]['data'][start:end])
    externals = read_externals(blob)
    flat_groups = flat_frame_groups(blob)
    fields = set()
    bindings = {}
    generated_code_bindings = {}
    for fix in read_fixups(blob):
        if fix.segment != seg or not start <= fix.offset < end:
            continue
        if fix.location != 9 or fix.target[0] != 2:
            raise ValueError('Unsupported leaf relocation')
        if fix.frame[0] != 1 or fix.frame[1] not in flat_groups:
            raise ValueError('Unsupported leaf frame: expected explicit empty FLAT group')
        if not 0 < fix.target[1] < len(externals):
            raise ValueError('External index outside table')
        name = externals[fix.target[1]]
        is_code_pointer = not fix.relative and name in (absolute_code or {})
        if is_code_pointer and name in values:
            raise ValueError(f'Ambiguous absolute DATA/CODE symbol: {name}')
        if is_code_pointer and code_bindings is None:
            raise ValueError('Absolute CODE binding requires code_bindings output metadata')
        targets = (functions or {}) if fix.relative else (absolute_code if is_code_pointer else values)
        if fix.relative and address is None:
            raise ValueError('Relative binding requires loaded code address')
        if name not in targets:
            raise ValueError(f'Unbound leaf symbol: {name}')
        offset = fix.offset-start
        sites = set(range(offset, offset+4))
        if offset+4 > len(code) or fields & sites:
            raise ValueError('Invalid or overlapping leaf fixups')
        fields.update(sites)
        value = int.from_bytes(code[offset:offset+4], 'little')
        value = value+fix.displacement+targets[name]
        if fix.relative:
            value -= address+offset+4
        value &= 0xffffffff
        code[offset:offset+4] = value.to_bytes(4, 'little')
        if not fix.relative:
            bindings[offset] = value
            if is_code_pointer:
                generated_code_bindings[offset] = value
    if code_bindings is not None:
        code_bindings.update(generated_code_bindings)
    return bytes(code), bindings


def bind_leaf(blob, symbol, values, **kwargs):
    code, bindings = bind_leaf_details(blob, symbol, values, **kwargs)
    return code, len(bindings)


def verify_leaf_relocations(code, bindings, pointers, address, *, code_bindings=None):
    """Check all original LE pointers with explicit DATA versus CODE object bases."""
    code_bindings = {} if code_bindings is None else code_bindings
    if not isinstance(code_bindings, dict):
        raise ValueError('CODE metadata must be a dict')
    for offset, value in code_bindings.items():
        if (offset not in bindings or bindings[offset] != value
                or not isinstance(offset, int) or offset < 0 or offset + 4 > len(code)
                or int.from_bytes(code[offset:offset + 4], 'little') != value):
            raise ValueError('Stale or inconsistent CODE binding metadata')
    actual = {site-address: target for site, target in pointers.items()
              if address <= site < address+len(code)}
    expected = {offset: value+(0x10000 if offset in code_bindings else 0x80000)
                for offset, value in bindings.items()}
    if actual != expected:
        raise ValueError('Original LE relocation sites or targets differ from bound leaf')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('object', type=Path)
    parser.add_argument('symbol', choices=LEAVES)
    args = parser.parse_args()
    exe = args.executable.read_bytes()
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    offset, size = LEAVES[args.symbol]
    code_bindings = {}
    code, bindings = bind_leaf_details(args.object.read_bytes(), args.symbol, DATA_OFFSETS,
                                       address=offset-0x25600, functions=FUNCTION_ADDRESSES,
                                       absolute_code=CODE_OFFSETS, code_bindings=code_bindings)
    expected = exe[offset:offset+size]
    if code != expected:
        differences = [i for i, (a, b) in enumerate(zip(code, expected)) if a != b]
        raise SystemExit(f'FAIL: {len(code)} generated versus {size} expected bytes; '
                         f'first differing offsets {differences[:12]}')
    verify_leaf_relocations(code, bindings, read_le_fixups(exe)['pointers'], offset-0x25600,
                            code_bindings=code_bindings)
    print(f'PASS: {args.symbol} all {size} bytes and {len(bindings)} LE pointer targets match')
