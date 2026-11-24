"""Check a compiled OMF leaf against FATE after explicit external binding.

This verifies isolated code and its fixups, not final executable linkage.
Absolute data operands use DS offsets; absolute CODE operands use code-object
offsets and explicit metadata. Relative externals require loaded code addresses.
Relative operands are checked by exact bytes, not LE pointer records.
"""
import argparse
import hashlib
import json
from functools import lru_cache
from pathlib import Path
from types import MappingProxyType
from compare_exe import TARGET_SHA256
from match_objects import read_object
from omf_fixups import Reader, read_externals, read_fixups
from le_fixups import read_le_fixups, pointer_range
from verification_diagnostics import code_mismatch, relocation_mismatch

LEAVES = {'processreservedmessage_': (0x688c1, 719), 'sendpacket_': (0x67aec, 1177), 'netsend_': (0x67359, 629), 'checksum_gameplay_state_': (0x5923f, 1490), 'process_gameplay_frame_': (0x5283e, 732), 'update_menu_selection_': (0x5e835, 595), 'dispatch_actor_update_': (0x39c10, 647), 'update_actor_common_': (0x39e97, 697), 'clipinsideboxline_': (0x717b2, 225), 'inside_': (0x71e8f, 189),
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
DATA_OFFSETS = {'_actor_recovery_counter': 0x7f295, '_alternate_fire_requested': 0x7dee6, '_conventional_memory_error': 0x191d, '_inbufplc': 0x18fdbc, '_inbufend': 0x18fdf0, '_outbufplc': 0x18fdd8, '_comport': 0x18fde8, '_comtype': 0x18fdf8, '_comerror': 0x18fe1c, '_comresend': 0x18fdf4, '_incnt': 0x18fe00, '_inbuf': 0x18fe24, '_rmbuffer': 0x13ce4, '_sequence_sprites': 0x2040a0, '_object_sequences': 0x6807c, '_active_sequence_count': 0x7dee0, '_active_sequence_sprites': 0x67a3c, '_clipobjectval': 0x196750, '_sector': 0x27c3a0, '_wall': 0x2310a0, '_numsectors': 0x289154, '_numwalls': 0x289152,
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
                '_sector_wall_counts': 0x27c3a2, '_sector_wall_starts': 0x27c3a0,
                '_sprite_sector_numbers': 0x2040b8, '_show_2d_sectors': 0x1ec6a0,
                '_listed_sprite_records': 0x2040a0, '_listed_sprite_overflow_text': 0x21c,
                '_listed_sprite_error_buffer': 0x67e3c,
                '_comvect': 0x18fe04, '_orig_pm_off': 0x18fe20, '_orig_pm_sel': 0x190288,
                '_orig_rm_seg': 0x190284, '_orig_rm_off': 0x190286, '_clipnum': 0x289136,
                '_clipx1': 0x190b60, '_clipy1': 0x197350, '_clipx2': 0x190360, '_clipy2': 0x196b50}

DATA_OFFSETS.update({
    '_prevspritesect': 0x1f6020,
    '_headspritestat': 0x28811c,
    '_prevspritestat': 0x1fdca0,
    '_nextspritestat': 0x1fbca0,
})

DATA_OFFSETS.update({
    '_pit_programming_enabled': 0x16528,
    '_use_dpmi_vector': 0x1652c,
    '_timer_flags': 0x166c4,
    '_pit_divisor': 0x166c8,
    '_timer_callbacks': 0x166cc,
    '_timer_frequencies': 0x1670c,
    '_timer_increments': 0x1674c,
    '_timer_accumulators': 0x1678c,
    '_timer_contexts': 0x167cc,
    '_current_timer_context': 0x1680c,
    '_spawn_path_variable': 0x1f18,
    '_fpu_present': 0x141a9,
    '_fpu_control_word': 0x17490,
    '_save_spawn_state': 0x17408,
    '_restore_spawn_state': 0x1740c,
    '_current_directory_prefix': 0x1c24,
    '_batch_extension': 0x1c27,
    '_com_extension': 0x1c2c,
    '_exe_extension': 0x1c31,
    '_comspec_name': 0x1c36,
    '_spawn_cmd_name': 0x1c3e,
    '_spawn_command_name': 0x1c42,
    '_default_timer_slot': 0x16708,
    '_default_timer_frequency': 0x16748,
    '_default_timer_increment': 0x16788,
})

DATA_OFFSETS.update({
    '_argument_count': 0x1419c,
    '_argument_vector': 0x141a0,
    '_map_extension': 0xb79,
    '_extension_separator': 0xb7e,
    '_command_line_options': 0x12d18,
    '_force_video_setup': 0x173d48,
    '_sector_wallptr': 0x27c3a0,
    '_wall_x': 0x2310a0,
    '_wall_y': 0x2310a4,
    '_wall_point2': 0x2310a8,
    '_ceiling_flags': 0x27c3ac,
    '_ceiling_heinum': 0x27c3b2,
    '_ceiling_z': 0x27c3a4,
    '_floor_flags': 0x27c3ae,
    '_floor_heinum': 0x27c3ba,
    '_floor_z': 0x27c3a8,
})

# Absolute CODE pointers are object-relative, unlike loaded relative-call targets.
CODE_OFFSETS = {'comhandler_': 0x3215b, '_format_digits': 0x57491, '_integer_digits': 0x52cbf}
CODE_OFFSETS.update({
    'stream_format_putc_': 0x5316b,
    'timer_module_noop_': 0x50b2b,
    'timer_tail_noop_': 0x51258,
    'timer_dispatch_callbacks_': 0x5119e,
    'default_timer_callback_': 0x5123e,
    'audio_init_noop_': 0x51768,
    'audio_noop_61816_': 0x51816,
    'audio_noop_6182b_': 0x5182b,
    'audio_noop_62185_': 0x52185,
    'audio_noop_6219f_': 0x5219f,
    'audio_noop_62414_': 0x52414,
    'audio_noop_62429_': 0x52429,
    'audio_noop_62a82_': 0x52a82,
    'audio_empty_range_stub_64cfc_': 0x54cfc,
    'timer_vector_noop_': 0x54f9d,
    'audio_empty_range_stub_657ed_': 0x557ed,
    'audio_empty_range_stub_65ee6_': 0x55ee6,
    'audio_empty_range_stub_65efb_': 0x55efb,
    'audio_empty_range_stub_661b8_': 0x561b8,
    'audio_empty_range_stub_661cd_': 0x561cd,
    'audio_empty_range_stub_662cc_': 0x562cc,
    'audio_empty_range_stub_662e1_': 0x562e1,
    'audio_dispatch_noop_': 0x5637b,
    'audio_backend_region_start_': 0x56390,
    'audio_helper_region_end_': 0x56b73,
    'audio_empty_range_stub_66b74_': 0x56b74,
    'audio_empty_range_stub_67005_': 0x57005,
    'audio_detection_noop_': 0x5b0ea,
    'audio_detection_end_': 0x5bd4e,
    'audio_detection_lookup_start_': 0x5bd63,
    'audio_detection_lookup_end_': 0x5bda2,
    'audio_input_region_start_': 0x5bdb8,
    'audio_input_region_end_': 0x5dcf9,
    'audio_output_region_start_': 0x5dcfc,
    'audio_output_region_end_': 0x5e665,
})
LEAVES['ceilspritescan_'] = (0x75871, 220)
LEAVES['startcom_'] = (0x6764f, 268)
LEAVES['comhandler_'] = (0x6775b, 446)
LEAVES['simulateint_'] = (0x685fc, 208)
DATA_OFFSETS.update({'_ecbput': 0x18fde0, '_ipxout': 0x18fdac, '_messout': 0x18fd98})
# Guard-prefixed arrays describe the original broadcast peer-minus-one reads.
DATA_OFFSETS.update({'_multioption': 0x13cde, '_comrateoption': 0x13cdf,
    '_outbufindex': 0x18fb78, '_outcnt': 0x18fe14, '_netoutcnt_backing': 0x186e47,
    '_omessnum_backing': 0x18f6d6, '_omessout_backing': 0x1865d0,
    '_omessleng_backing': 0x18f6f0, '_omessconnectindex_backing': 0x186cb0})
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
DATA_OFFSETS.update({
    '_detector_data_selector': 0x169e4,
    '_detector_code_selector': 0x169ec,
    '_detector_data_offset': 0x169e0,
    '_detector_code_offset': 0x169e8,
    '_detector_values': 0x16a04,
    '_detector_flags': 0x16810,
    '_detector_file': 0x169f0,
    '_detector_active_offset': 0x169f4,
    '_detector_linear_base': 0x16a00,
    '_detector_memory_handle': 0x169fc,
    '_detector_parameter_ax': 0x16bf0,
    '_detector_parameter_cl': 0x16bf4,
    '_detector_parameter_ch': 0x16bf8,
    '_detector_parameter_dx': 0x16bfc,
    '_driver_records': 0x16b60,
    '_driver_records_selector': 0x16b64,
    '_driver_callbacks': 0x16b68,
    '_driver_callbacks_selector': 0x16b6c,
    '_dpmi_memory_info': 0x16b70,
    '_detector_path': 0x16894,
    '_detector_filename': 0x1ef0,
    '_detector_header': 0x16914,
    '_detector_data_pointer': 0x169e0,
    '_detector_code_pointer': 0x169e8,
    '_workspace_allocate_hook': 0x166bc,
    '_workspace_release_hook': 0x166c0,
    '_audio_system_flags': 0x16538,
    '_audio_driver_path': 0x1653c,
})
DATA_OFFSETS.update({
    '_pcm_mix_end': 0x16c10,
    '_audio_driver_slots': 0x1663c,
    '_dma_count_ports': 0x16a64,
    '_audio_driver_services': 0x16a84,
    '_dpmi_audio_exchange': 0x16650,
    '_timer_state_start': 0x144f8,
    '_timer_state_end': 0x16530,
    '_driver_state_start': 0x16534,
    '_driver_state_end': 0x16a98,
    '_dpmi_state_start': 0x16b0c,
    '_dpmi_state_end': 0x16c02,
    '_mixer_state_start': 0x16c08,
    '_mixer_state_end': 0x16c4c,
    '_menu_font_zoom': 0x12de8,
    '_dpmi_buffer_address': 0x1665c,
    '_dpmi_buffer_low_address': 0x1665c,
    '_redraw_menu_frame': 0x772b8,
    '_detector_entry_index': 0x169f8,
    '_detector_entry_count': 0x16934,
    '_detector_entry_header': 0x16940,
    '_detector_entry_size': 0x16964,
    '_detector_entry_id': 0x16968,
    '_detector_entry_flags': 0x1696d,
    '_detector_active_commands': 0x169dc,
    '_detector_commands': 0x16970,
    '_detector_command_flags': 0x169ad,
    '_save_slot_menu_rows': 0x173fc0,
    '_save_slot_name_format': 0xd13,
    '_save_menu_title': 0xc23,
    '_load_menu_title': 0xc19,
    '_save_slot_preview_enabled': 0x1314d,
    '_save_names_filename': 0xd2b,
    '_save_names_open_error': 0xd37,
    '_save_names': 0x1303a,
    '_save_menu_records': 0x174104,
    '_save_name_key_ascii': 0x3d04,
    '_editing_save_slot': 0x1740c8,
    '_editing_save_slot_name': 0x1314e,
    '_driver_file_path': 0x165bc,
    '_driver_filename': 0x1e80,
    '_driver_file_header': 0x16660,
    '_driver_entry_count': 0x16680,
    '_driver_entry_header': 0x1668c,
    '_driver_entry_id': 0x166b4,
    '_driver_entry_flags': 0x166b9,
    '_driver_entry_size': 0x166b0,
    '_pcm_sample_end': 0x16c20,
    '_pcm_fractional_step': 0x16c24,
    '_pcm_source_step': 0x16c28,
    '_pcm_left_gain': 0x16c3c,
    '_pcm_right_gain': 0x16c40,
})

# Error/printing dependencies remain identified bindings, not reconstructed code.
FUNCTION_ADDRESSES = {'netuninitconnection_': 0x4248f, 'getpacket_': 0x42985, 'processreservedmessage_': 0x432c1, 'netinitconnection_': 0x42319, 'sendpacket_': 0x424ec, 'comsend_': 0x41fce, 'getcrc_': 0x42f73, 'netsend_': 0x41d59, 'simulate_network_interrupt_': 0x42ffc, 'convalloc32_': 0x42fbb, 'sequence_remove_sprite_': 0x10f9f, 'int386_': 0x630b3, 'int386x_': 0x6309a, 'format_listed_sprite_error_': 0x601f3, 'report_listed_sprite_error_': 0x26a03, 'insertspritesect_': 0x508cd, 'insertspritestat_': 0x5096b, 'insert_template_sprite_': 0x508b8, 'record_lookup_error_': 0x26a03, 'memcpy_': 0x63245, 'type_lookup_error_': 0x26a03, 'getpalookup_': 0x5fed7, 'tvlineasm1_': 0x744d0, 'lookup_error_': 0x26a03, 'setverts_': 0x599c5, 'remove_engine_sprite_': 0x50a09, 'inside_': 0x4c88f, 'allocache_': 0x40c73,
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
FUNCTION_ADDRESSES['update_actor_common_'] = 0x14897

# Menu input accumulators and signed word mouse deltas.
DATA_OFFSETS.update({
    '_menu_mouse_x': 0x1741d6,
    '_menu_mouse_y': 0x1741da,
    '_mouse_dx': 0x7deda,
    '_mouse_dy': 0x7dedc,
})
FUNCTION_ADDRESSES['update_menu_selection_'] = 0x39235


# Synchronization checksum reads these fields through its own typed view.
DATA_OFFSETS.update({
    '_checksum_checksum_table': 0x18f778,
    '_checksum_first_player': 0x19028a,
    '_checksum_hit_sprite_list_head': 0x28811c,
    '_checksum_next_player': 0x18fd78,
    '_checksum_next_sprite_stat': 0x1fbca0,
    '_checksum_player_angle': 0x6308c,
    '_checksum_player_horizon': 0x62f8c,
    '_checksum_player_sector': 0x5acfc,
    '_checksum_player_x': 0x5ad9c,
    '_checksum_player_y': 0x5ad5c,
    '_checksum_player_z': 0x5ad1c,
    '_checksum_random_seed': 0x287e78,
    '_checksum_sprite': 0x2040a0,
    '_checksum_status_right_tenths': 0x6319c,
})

# Gameplay input frames, interpolation snapshots, and recording state.
DATA_OFFSETS.update({
    '_actor_clock': 0x770b8,
    '_connecthead': 0x19028a,
    '_connectpoint2': 0x18fd78,
    '_frame_current_input': 0x5ac8c,
    '_event_queue': 0x1f7fc,
    '_event_write_index': 0x3cdc,
    '_frame_network_enabled': 0x3c98,
    '_frame_old_angle': 0x209fc,
    '_frame_old_height': 0x2cb2c,
    '_frame_old_horizon': 0x2ca2c,
    '_frame_old_x': 0x2caac,
    '_frame_old_y': 0x2caec,
    '_frame_old_z': 0x2ca6c,
    '_frame_player_angle': 0x6308c,
    '_frame_player_height': 0x5ae1c,
    '_frame_player_horizon': 0x62f8c,
    '_frame_player_sector': 0x5acfc,
    '_frame_player_x': 0x5ad9c,
    '_frame_player_y': 0x5ad5c,
    '_frame_player_z': 0x5ad1c,
    '_frame_previous_sector': 0x5acdc,
    '_frame_recorded_input': 0x2db6c,
    '_frame_recording_mode': 0x3cd6,
    '_frame_sprite': 0x2040a0,
    '_frame_sprite_positions': 0x20a2c,
    '_frame_status_mask': 0x3ccb,
    '_headspritestat': 0x28811c,
    '_input_history': 0x55bbc,
    '_input_read_index': 0x770cc,
    '_nextspritestat': 0x1fbca0,
    '_player_count': 0x13ce0,
    '_processed_frame_count': 0x770d4,
    '_recorded_frame_count': 0x770d0,
})
FUNCTION_ADDRESSES.update({
    'checksum_gameplay_state_': 0x33c3f,
    'do_animations_': 0x2eeae,
    'process_gameplay_frame_': 0x2d23e,
    'rotate_network_lead_player_': 0x2f035,
    'update_board_environment_': 0x2a56e,
    'update_interpolations_': 0x34589,
    'update_player_motion_': 0x2b3ed,
})

FUNCTION_ADDRESSES['dispatch_actor_update_'] = 0x14610

# Actor mode-transition dispatcher and original field/callee aliases.
DATA_OFFSETS.update({
    '_actor_mode': 0x7f67f,
    '_previous_mode': 0x7f964,
    '_defer_mode_change': 0x709bc,
    '_actor_sprite_index': 0x7dab8,
    '_actor_state_byte': 0x7e0f8,
    '_actor_delay_byte': 0x7df03,
    '_sprite_x': 0x2040a0,
    '_sprite_y': 0x2040a4,
    '_sprite_sector': 0x2040b8,
    '_sprite_tile': 0x2040ae,
    '_actor_x': 0x799e8,
    '_actor_y': 0x7a1bc,
    '_actor_sector': 0x7d2e4,
    '_actor_tiles': 0x7abc0,
    '_mode_one_tile': 0x7abc2,
    '_mode_two_tile': 0x7abc4,
    '_mode_three_tile': 0x7abc6,
    '_mode_four_tile': 0x7abc8,
    '_mode_five_tile': 0x7abca,
    '_mode_six_tile': 0x7abcc,
    '_actor_profile': 0x7e8cc,
    '_actor_sequence_initial': 0x7e4e2,
})
FUNCTION_ADDRESSES.update({
    'profile_one_mode_one_': 0x15411,
    'profile_one_mode_two_': 0x163f2,
    'profile_one_mode_three_': 0x18a37,
    'profile_one_mode_four_': 0x183ce,
    'profile_one_mode_five_': 0x17da9,
    'profile_one_mode_six_': 0x190aa,
    'profile_two_mode_one_': 0x14b50,
    'profile_two_mode_two_': 0x15e07,
    'profile_two_mode_three_': 0x16aa8,
    'profile_two_mode_four_': 0x1711b,
    'profile_two_mode_five_': 0x17784,
})

FUNCTION_ADDRESSES['__GETDS'] = 0x601d4
FUNCTION_ADDRESSES['memset_'] = 0x61350
FUNCTION_ADDRESSES['fill_byte_pattern_'] = 0x62de0
FUNCTION_ADDRESSES['sopen_'] = 0x6138c


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
    '_horizon_reciprocals': 0x286ac4,
    '_horizon_aspect': 0x286aec,
    '_viewingrange': 0x287e7c,
    '_viewingrange_reciprocal': 0x286bac,
    '_viewingrange_scaled': 0x286b00,
    '_viewingrange_reciprocal_scaled': 0x286b14,
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
FUNCTION_ADDRESSES['dispatch_period_'] = 0x35422
LEAVES['dispatch_menu_'] = (0x5ac04, 48)
LEAVES['main_step_d_'] = (0x5ac34, 79)
DATA_OFFSETS.update({
    '_dispatch_mode': 0x772bc,
    '_dispatch_active': 0x77118,
    '_dispatch_play': 0x772b8,
})
FUNCTION_ADDRESSES.update({
    'start_fade_out_': 0x3662e,
    'start_fade_in_': 0x36669,
    'run_palette_fade_': 0x365ee,
    'check_fade_out_': 0x366aa,
    'check_palette_fade_input_': 0x36601,
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
    '_network_enabled': 0x3c98,
    '_network_settings': 0x3c99,
    '_engine_1ed1a0': 0x1ed1a0,
    '_engine_1ed1a2': 0x1ed1a2,
    '_engine_289150': 0x289150,
    '_art_archive_filename': 0x131c,
    '_slime_allocation_error': 0x1329,
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
    'network_init_return_': 0x4164e,
    'shutdown_serial_network_': 0x41cde,
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
    '_status_minimum_width': 0x7ded8,
    '_status_depletion_sound': 0x514,
    '_active_status_format': 0x51e,
    '_depleted_status_message': 0x52a,
    '_status_message_buffer': 0x1df6c,
    '_viewed_player': 0x3cfa,
    '_player_status_sprite': 0x62f2c,
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
    'wallmost_': 0x5e824,
    'wallmost_flat_height_': 0x5e864,
    'wallmost_floor_height_': 0x5e86e,
    'wallmost_slope_geometry_': 0x5e893,
    'wallmost_slope_length_': 0x5e971,
    'wallmost_left_ray_': 0x5e9c6,
    'wallmost_slope_coefficient_': 0x5ea56,
    'wallmost_left_height_': 0x5eaaa,
    'wallmost_right_ray_': 0x5eb98,
    'wallmost_right_height_': 0x5ec3f,
    'wallmost_clip_flags_': 0x5ecc4,
    'wallmost_fill_clipped_': 0x5eddb,
    'wallmost_check_bottom_': 0x5ee1d,
    'wallmost_clip_top_': 0x5ee3d,
    'wallmost_fill_top_': 0x5ef3e,
    'wallmost_clip_bottom_': 0x5ef7d,
    'wallmost_fill_bottom_': 0x5f0a6,
    'wallmost_interpolate_': 0x5f0e7,
    'wallmost_read_flags_': 0x5f1ed,
    'wallmost_restore_': 0x5f1f1,
    'owallmost_': 0x5e350,
    'owallmost_fill_clipped_': 0x5e460,
    'owallmost_check_bottom_': 0x5e4a2,
    'owallmost_clip_top_': 0x5e4c2,
    'owallmost_fill_top_': 0x5e597,
    'owallmost_clip_bottom_': 0x5e5d6,
    'owallmost_fill_bottom_': 0x5e6da,
    'owallmost_interpolate_': 0x5e717,
    'owallmost_return_': 0x5e818,
    'ceilscan_': 0x478b5,
    'ceilscan_check_height_': 0x478f7,
    'ceilscan_animate_tile_': 0x4792a,
    'ceilscan_require_tile_': 0x4794a,
    'ceilscan_touch_tile_': 0x4797f,
    'ceilscan_flat_axes_': 0x479f7,
    'ceilscan_wall_axes_': 0x47a50,
    'ceilscan_wall_length_': 0x47ad4,
    'ceilscan_project_axes_': 0x47af0,
    'grouscan_': 0x5f1f8,
    'grouscan_select_floor_': 0x5f273,
    'grouscan_select_tile_': 0x5f2c3,
    'grouscan_require_tile_': 0x5f2e7,
    'grouscan_touch_tile_': 0x5f31e,
    'grouscan_restore_stack_': 0x5fed0,
    'florscan_': 0x47f0c,
    'florscan_check_height_': 0x47f50,
    'florscan_touch_tile_': 0x47f7e,
    'florscan_load_tile_': 0x47ff2,
    'florscan_set_visibility_': 0x48008,
    'florscan_flat_axes_': 0x4804d,
    'florscan_wall_axes_': 0x480a6,
    'florscan_wall_length_': 0x4812a,
    'florscan_project_axes_': 0x48146,
    'florscan_texture_': 0x48272,
    'florscan_flip_x_': 0x48321,
    'florscan_flip_y_': 0x48357,
    'florscan_begin_spans_': 0x4838b,
    'florscan_scan_column_': 0x4849d,
    'florscan_empty_column_': 0x4852a,
    'florscan_test_column_': 0x48565,
    'florscan_finish_spans_': 0x4856e,
    'ceilscan_texture_': 0x47c1c,
    'ceilscan_flip_x_': 0x47cc7,
    'ceilscan_flip_y_': 0x47cfd,
    'ceilscan_begin_spans_': 0x47d31,
    'ceilscan_scan_column_': 0x47e30,
    'ceilscan_empty_column_': 0x47ebe,
    'ceilscan_test_column_': 0x47ee2,
    'ceilscan_finish_spans_': 0x47eeb,
    'ceilscan_run_timer_': 0x47eff,
    'ceilscan_restore_stack_': 0x47f04,
    'hline_': 0x4a7f3,
    'sethlinesizes_': 0x73ff0,
    'hline_planar_': 0x4a904,
    'hline_next_plane_': 0x4a9b6,
    'hlineasm4_': 0x74150,
    'setuphlineasm4_': 0x74110,
    'clearview_': 0x5cd99,
    'clearview_restore_': 0x4bb05,
    'clearview_stereo_row_': 0x5ce0c,
    'clearview_check_stereo_row_': 0x5cea1,
    'clearview_check_planar_': 0x5ceb2,
    'clearview_linear_': 0x5d00c,
    'clearview_service_timer_': 0x5d07e,
    'rotatesprite_': 0x57181,
    'animateoffs_': 0x50758,
    'draw_rotated_sprite_': 0x573ac,
    'end_rotated_sprite_': 0x573a3,
    'next_rotated_sprite_': 0x57377,
    'advance_permanent_tail_': 0x5738a,
    'nextpage_': 0x4b496,
})
CODE_OFFSETS.update({
    '_presentation_durations': 0x247bb,
    '_presentation_pictures': 0x247d9,
})


LEAVES['presentation_reset_'] = (0x5b846, 22)
LEAVES['float_to_i32_'] = (0x994c4, 10)
LEAVES['float_to_u32_'] = (0x994ce, 10)
LEAVES['float_to_i16_'] = (0x994d8, 10)
LEAVES['float_to_u16_'] = (0x994e2, 10)
LEAVES['float_to_i8_'] = (0x994ec, 10)
LEAVES['float_to_u8_'] = (0x994f6, 10)
LEAVES['presentation_input_'] = (0x5b85c, 169)
LEAVES['ksqrt_'] = (0x72038, 54)
LEAVES['initksqrt_'] = (0x720aa, 144)
LEAVES['pushmove_'] = (0x794dd, 999)
LEAVES['copytilepiece_'] = (0x7213a, 336)
LEAVES['preparemirror_'] = (0x82c56, 712)
LEAVES['load_art_files_'] = (0x71346, 752)
LEAVES['wallmost_'] = (0x83e24, 64)
LEAVES['wallmost_flat_height_'] = (0x83e64, 10)
LEAVES['wallmost_floor_height_'] = (0x83e6e, 37)
LEAVES['wallmost_slope_geometry_'] = (0x83e93, 222)
LEAVES['wallmost_slope_length_'] = (0x83f71, 85)
LEAVES['wallmost_left_ray_'] = (0x83fc6, 144)
LEAVES['wallmost_slope_coefficient_'] = (0x84056, 84)
LEAVES['wallmost_left_height_'] = (0x840aa, 238)
LEAVES['wallmost_right_ray_'] = (0x84198, 167)
LEAVES['wallmost_right_height_'] = (0x8423f, 133)
LEAVES['wallmost_clip_flags_'] = (0x842c4, 279)
LEAVES['wallmost_fill_clipped_'] = (0x843db, 66)
LEAVES['wallmost_check_bottom_'] = (0x8441d, 32)
LEAVES['wallmost_clip_top_'] = (0x8443d, 257)
LEAVES['wallmost_fill_top_'] = (0x8453e, 63)
LEAVES['wallmost_clip_bottom_'] = (0x8457d, 297)
LEAVES['wallmost_fill_bottom_'] = (0x846a6, 65)
LEAVES['wallmost_interpolate_'] = (0x846e7, 262)
LEAVES['wallmost_read_flags_'] = (0x847ed, 4)
LEAVES['wallmost_restore_'] = (0x847f1, 7)
LEAVES['owallmost_'] = (0x83950, 272)
LEAVES['owallmost_fill_clipped_'] = (0x83a60, 66)
LEAVES['owallmost_check_bottom_'] = (0x83aa2, 32)
LEAVES['owallmost_clip_top_'] = (0x83ac2, 213)
LEAVES['owallmost_fill_top_'] = (0x83b97, 63)
LEAVES['owallmost_clip_bottom_'] = (0x83bd6, 260)
LEAVES['owallmost_fill_bottom_'] = (0x83cda, 61)
LEAVES['owallmost_interpolate_'] = (0x83d17, 257)
LEAVES['owallmost_return_'] = (0x83e18, 12)
LEAVES['ceilscan_'] = (0x6ceb5, 66)
LEAVES['ceilscan_check_height_'] = (0x6cef7, 51)
LEAVES['ceilscan_animate_tile_'] = (0x6cf2a, 32)
LEAVES['ceilscan_require_tile_'] = (0x6cf4a, 53)
LEAVES['ceilscan_touch_tile_'] = (0x6cf7f, 120)
LEAVES['ceilscan_flat_axes_'] = (0x6cff7, 89)
LEAVES['ceilscan_wall_axes_'] = (0x6d050, 132)
LEAVES['ceilscan_wall_length_'] = (0x6d0d4, 28)
LEAVES['ceilscan_project_axes_'] = (0x6d0f0, 300)
DATA_OFFSETS.update({
    '_slope_view_axis_x': 0x286a78,
    '_slope_view_axis_y': 0x286a7c,
})
LEAVES['grouscan_wall_vector_'] = (0x84951, 71)
LEAVES['grouscan_wall_length_'] = (0x84998, 61)
LEAVES['grouscan_inverse_length_'] = (0x849d5, 61)
LEAVES['grouscan_scale_wall_vector_'] = (0x84a12, 86)
LEAVES['grouscan_'] = (0x847f8, 123)
LEAVES['grouscan_select_floor_'] = (0x84873, 80)
LEAVES['grouscan_select_tile_'] = (0x848c3, 36)
LEAVES['grouscan_require_tile_'] = (0x848e7, 55)
LEAVES['grouscan_touch_tile_'] = (0x8491e, 51)
LEAVES['florscan_'] = (0x6d50c, 68)
LEAVES['florscan_check_height_'] = (0x6d550, 46)
LEAVES['florscan_touch_tile_'] = (0x6d57e, 116)
LEAVES['florscan_load_tile_'] = (0x6d5f2, 22)
LEAVES['florscan_set_visibility_'] = (0x6d608, 69)
LEAVES['florscan_flat_axes_'] = (0x6d64d, 89)
LEAVES['florscan_wall_axes_'] = (0x6d6a6, 132)
LEAVES['florscan_wall_length_'] = (0x6d72a, 28)
LEAVES['florscan_project_axes_'] = (0x6d746, 300)
LEAVES['florscan_texture_'] = (0x6d872, 175)
LEAVES['florscan_flip_x_'] = (0x6d921, 54)
LEAVES['florscan_flip_y_'] = (0x6d957, 52)
LEAVES['florscan_begin_spans_'] = (0x6d98b, 274)
LEAVES['florscan_scan_column_'] = (0x6da9d, 141)
LEAVES['florscan_empty_column_'] = (0x6db2a, 59)
LEAVES['florscan_test_column_'] = (0x6db65, 9)
LEAVES['florscan_finish_spans_'] = (0x6db6e, 24)
LEAVES['ceilscan_texture_'] = (0x6d21c, 171)
LEAVES['ceilscan_flip_x_'] = (0x6d2c7, 54)
LEAVES['ceilscan_flip_y_'] = (0x6d2fd, 52)
LEAVES['ceilscan_begin_spans_'] = (0x6d331, 255)
LEAVES['ceilscan_scan_column_'] = (0x6d430, 142)
LEAVES['ceilscan_empty_column_'] = (0x6d4be, 36)
LEAVES['ceilscan_test_column_'] = (0x6d4e2, 9)
LEAVES['ceilscan_finish_spans_'] = (0x6d4eb, 20)
LEAVES['ceilscan_run_timer_'] = (0x6d4ff, 5)
LEAVES['ceilscan_restore_stack_'] = (0x6d504, 8)
LEAVES['hline_'] = (0x6fdf3, 273)
LEAVES['hline_planar_'] = (0x6ff04, 178)
LEAVES['hline_next_plane_'] = (0x6ffb6, 114)
LEAVES['clearview_'] = (0x82399, 115)
LEAVES['clearview_stereo_row_'] = (0x8240c, 149)
LEAVES['clearview_check_stereo_row_'] = (0x824a1, 17)
LEAVES['clearview_check_planar_'] = (0x824b2, 346)
LEAVES['clearview_linear_'] = (0x8260c, 114)
LEAVES['clearview_service_timer_'] = (0x8267e, 10)
LEAVES['clearallviews_'] = (0x826aa, 106)
LEAVES['clearallviews_fill_dwords_'] = (0x82714, 7)
LEAVES['clearallviews_dispatch_backend_'] = (0x8271b, 26)
LEAVES['clearallviews_vga_planes_'] = (0x82735, 26)
LEAVES['clearallviews_paged_display_'] = (0x8274f, 95)
LEAVES['clearallviews_linear_frame_'] = (0x827ae, 29)
LEAVES['clearallviews_port_3cd_banks_'] = (0x827cb, 34)
LEAVES['clearallviews_graphics_controller_banks_'] = (0x827ed, 41)
LEAVES['clearallviews_crtc_banks_'] = (0x82816, 39)
LEAVES['clearallviews_service_timer_'] = (0x8283d, 10)
LEAVES['prepwall_'] = (0x6cb1e, 300)
LEAVES['prepwall_more_columns_'] = (0x6cc4a, 233)
LEAVES['prepwall_last_pair_'] = (0x6cd33, 141)
LEAVES['prepwall_last_column_'] = (0x6cdc0, 245)
LEAVES['transmaskwallscan_'] = (0x6f3d1, 440)
LEAVES['completemirror_'] = (0x82f1e, 1192)
LEAVES.update({'init_fpu_callbacks_': (0x89c00, 49), 'check_fpu_callbacks_': (0x89c31, 10)})
LEAVES['run_menu_loop_'] = (0x5ec4c, 266)
LEAVES['wallfront_'] = (0x6a913, 5)
LEAVES['wallfront_geometry_'] = (0x6a918, 527)
LEAVES['cansee_'] = (0x76333, 482)
LEAVES['draw_ega_text_'] = (0x7b42c, 690)
LEAVES['draw_screen_text_'] = (0x7b6de, 519)
LEAVES['rotatesprite_'] = (0x7c781, 555)
LEAVES['makepalookup_'] = (0x7e9b4, 462)
LEAVES['getclosestcol_'] = (0x7ed6c, 478)
LEAVES['initialize_color_lookup_'] = (0x7eb82, 490)
LEAVES['set_vga_vertical_timing_'] = (0x7efc5, 403)
LEAVES['loadtile_'] = (0x7110d, 385)
LEAVES['setviewtotile_'] = (0x828f4, 377)
LEAVES['setviewback_'] = (0x82a6d, 309)
LEAVES['getzsofslope_'] = (0x8367a, 301)
LEAVES['setbrightness_'] = (0x7f1ee, 318)
LEAVES['rintersect_'] = (0x77d2c, 246)
LEAVES['apply_projectile_hit_'] = (0x38715, 290)
LEAVES['update_projectiles_'] = (0x38837, 651)
DATA_OFFSETS.update({
    '_projectile_list': 0x7053c,
    '_projectile_player_sprite': 0x62f2c,
    '_projectile_sector': 0x2040b8,
    '_projectile_owner': 0x2040be,
    '_projectile_lotag': 0x2040c6,
    '_projectile_hitag': 0x2040c8,
    '_projectile_xvel': 0x2040c0,
    '_projectile_yvel': 0x2040c2,
    '_projectile_zvel': 0x2040c4,
    '_projectile_x': 0x2040a0,
    '_projectile_y': 0x2040a4,
    '_projectile_z': 0x2040a8,
    '_projectile_ticks': 0x7a994,
    '_projectile_player_x': 0x5ad9c,
    '_projectile_player_y': 0x5ad5c,
    '_projectile_player_z': 0x5ad1c,
    '_projectile_player_hit_x': 0x7097c,
    '_projectile_player_hit_y': 0x7093c,
    '_projectile_player_hit_timer': 0x6f89c,
    '_projectile_selected_weapon': 0x2be2,
    '_projectile_close_hit_tile': 0x2be6,
    '_projectile_player_mode': 0x62f1c,
    '_projectile_extra_high': 0x2040cb,
})
LEAVES['move_actor_'] = (0x3ecb2, 326)
LEAVES['update_proximity_sprites_'] = (0x358ca, 361)
LEAVES['update_sprite_sequence_state_'] = (0x35a33, 477)
LEAVES['spawn_counted_player_effect_'] = (0x35ff9, 374)
LEAVES['check_teleport_terminals_'] = (0x3939f, 334)
LEAVES['update_board_7_script_'] = (0x43bd1, 361)
LEAVES['update_board_5_script_'] = (0x43a1d, 435)
LEAVES['save_build_map_'] = (0x6f71a, 378)
LEAVES['load_build_map_'] = (0x6f589, 401)
LEAVES['getceilzofslope_'] = (0x83470, 261)
LEAVES['getflorzofslope_'] = (0x83575, 261)
LEAVES['lintersect_'] = (0x77c1d, 271)
LEAVES['shutdown_video_engine_'] = (0x70990, 236)
LEAVES['readpixel16_'] = (0x71893, 213)
LEAVES['squarerotatetile_'] = (0x82ba2, 180)
LEAVES['rotatepoint_'] = (0x7997c, 146)
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
LEAVES['validate_key_binding_'] = (0x5f9b0, 124)
LEAVES['run_key_binding_menu_'] = (0x5fa92, 458)
LEAVES.update({
    'env_scan_strings_': (0x93cd4, 40),
    'env_allocate_and_copy_': (0x93cfc, 92),
    'env_finish_vector_': (0x93d58, 37),
    'env_free_strings_': (0x93d7d, 7),
    'env_restore_registers_': (0x93d84, 9),
})
LEAVES['advance_menu_animation_'] = (0x5e6c7, 124)
LEAVES['select_vesa_draw_page_'] = (0x6977c, 164)
LEAVES['cache_menu_tiles_'] = (0x5ea88, 137)
LEAVES['draw_weapon_overlay_'] = (0x5d595, 169)
LEAVES['teleport_sprite_'] = (0x53fec, 182)
LEAVES['restore_board_actor_sprites_'] = (0x4bd49, 698)
DATA_OFFSETS.update({
    '_restored_sprite': 0x2040a0,
    '_saved_actor_board': 0x7eac1,
    '_saved_actor_mode': 0x7f67f,
    '_saved_actor_active': 0x7ecb6,
    '_restored_current_board': 0x7f87e,
    '_restored_actor_sprite': 0x7dab8,
    '_restored_sprite_actor': 0x709dc,
    '_restored_tile_height': 0x1f4020,
    '_restored_actor_tiles': 0x7abc0,
    '_inactive_actor_tiles': 0x68080,
    '_saved_actor_x': 0x772c4,
    '_saved_actor_y': 0x772c8,
    '_saved_actor_z': 0x772cc,
    '_restored_actor_z_offset': 0x79214,
    '_restored_sector_floor': 0x27c3a8,
    '_restored_sprite_position': 0x20a2c,
    '_restored_sprite_interpolated': 0x1ecfa0,
    '_restore_actor_error_buffer': 0x67e3c,
    '_restore_actor_sector_error': 0x3e0,
    '_restore_template_cstat': 0x2a9d,
    '_restore_template_angle': 0x2aa8,
    '_restore_template_status': 0x2ab2,
    '_restore_template_hitag': 0x2ab6,
    '_restore_template_xvel': 0x2aaa,
    '_restore_template_yvel': 0x2aac,
    '_restore_template_zvel': 0x2aae,
    '_restore_template_owner': 0x2ab0,
    '_restore_template_shade': 0x2a9f,
    '_restore_template_palette': 0x2aa0,
    '_restore_template_clip_distance': 0x2aa1,
    '_restore_template_xrepeat': 0x2aa2,
    '_restore_template_yrepeat': 0x2aa3,
    '_restore_template_xoffset': 0x2aa4,
    '_restore_template_yoffset': 0x2aa5,
})
LEAVES['apply_sprite_blast_'] = (0x3633a, 532)
DATA_OFFSETS.update({
    '_blast_horizontal_scale': 0xf8,
    '_blast_vertical_scale': 0xfc,
    '_blast_vertical_limit': 0x100,
    '_blast_vertical_velocity': 0x104,
    '_blast_player_x': 0x5ad9c,
    '_blast_player_y': 0x5ad5c,
    '_blast_sprite_actor': 0x709dc,
    '_blast_next_sprite_status': 0x1fbca0,
    '_blast_sprite_x': 0x2040a0,
    '_blast_sprite_y': 0x2040a4,
    '_blast_sprite_cstat': 0x2040ac,
    '_blast_sprite_tile': 0x2040ae,
    '_blast_sprite_xrepeat': 0x2040b2,
    '_blast_sprite_xvel': 0x2040c0,
    '_blast_sprite_yvel': 0x2040c2,
    '_blast_sprite_zvel': 0x2040c4,
    '_blast_sprite_lotag': 0x2040c6,
    '_blast_head_sprite_status': 0x28811c,
})
LEAVES['update_palette_fade_'] = (0x5bcf2, 574)
DATA_OFFSETS.update({
    '_palette_fade_up': 0x173d14,
    '_palette_fade_down': 0x173d18,
    '_palette_tint_a_ticks': 0x173d1c,
    '_palette_tint_b_ticks': 0x173d28,
    '_palette_tint_c_ticks': 0x173d20,
    '_palette_fade_step': 0x173d24,
    '_palette_fade_last_tick': 0x173d2c,
    '_palette_tint_a': 0x171614,
    '_palette_tint_b': 0x172214,
    '_palette_tint_c': 0x173114,
})
LEAVES['run_recorded_session_'] = (0x53950, 475)
LEAVES['synchronize_network_players_'] = (0x590f0, 335)
LEAVES['rotate_network_lead_player_'] = (0x54635, 457)
DATA_OFFSETS.update({
    '_rotate_network_enabled': 0x3c98,
    '_rotate_first_player': 0x19028a,
    '_rotate_next_player': 0x18fd78,
    '_rotate_local_player': 0x13ce2,
    '_rotate_player_input_word': 0x5ac8f,
    '_rotate_current_a': 0x5ac3c,
    '_rotate_current_b': 0x5ac3d,
    '_rotate_current_c': 0x5ac3e,
    '_rotate_current_word': 0x5ac3f,
    '_rotate_previous_a': 0x55b6c,
    '_rotate_previous_b': 0x55b6d,
    '_rotate_previous_c': 0x55b6e,
    '_rotate_previous_word': 0x55b6f,
    '_rotate_local_a': 0x7def9,
    '_rotate_local_b': 0x7defa,
    '_rotate_local_c': 0x7defb,
    '_rotate_local_word': 0x7defc,
    '_rotate_saved_local_a': 0x7def4,
    '_rotate_saved_local_b': 0x7def5,
    '_rotate_saved_local_c': 0x7def6,
    '_rotate_saved_local_word': 0x7def7,
    '_rotate_actor_clock': 0x770b8,
    '_rotate_event_read': 0x3ce4,
    '_rotate_event_state': 0x3ce0,
    '_rotate_event_write': 0x3cdc,
    '_rotate_saved_clock': 0x3cee,
    '_rotate_last_tick': 0x3cea,
    '_rotate_lead_text': 0x7aa70,
    '_rotate_remote_lead_format': 0x5c6,
    '_rotate_lead_message': 0x7aa70,
    '_rotate_local_lead_message': 0x5b4,
    '_rotate_lead_text_length': 0x7f874,
    '_rotate_text_deadline': 0x7709c,
})
DATA_OFFSETS.update({
    '_sync_player_count': 0x13ce0,
    '_sync_local_player': 0x13ce2,
    '_sync_packet': 0x1d92c,
    '_sync_packet_ready_stage': 0x1d92d,
    '_sync_peer_ready_stage': 0x20a1c,
    '_sync_next_player': 0x18fd78,
    '_sync_first_player': 0x19028a,
})
LEAVES['finalize_board_state_'] = (0x59811, 723)
DATA_OFFSETS.update({
    '_final_player_sprite': 0x62f2c,
    '_final_sector_seed': 0x1d12c,
    '_final_sector_queue': 0x1d12a,
    '_final_wall_first': 0x27c3a0,
    '_final_wall_count': 0x27c3a2,
    '_final_sector_lotag': 0x27c3c2,
    '_final_ceiling_tile': 0x27c3b0,
    '_final_floor_tile': 0x27c3b8,
    '_final_wall_tile': 0x2310b0,
    '_final_wall_overlay': 0x2310b2,
    '_final_wall_lotag': 0x2310ba,
    '_final_tile_cache': 0x1ffca0,
    '_final_sectors_before': 0x1ec69f,
    '_final_walls_before': 0x1ec91f,
    '_final_sprites_before': 0x1ecf9f,
    '_final_sectors_visible': 0x1ec6a0,
    '_final_walls_visible': 0x1ec920,
    '_final_sprites_visible': 0x1ecfa0,
    '_final_visibility_dirty': 0x2891d8,
    '_final_walls': 0x2310a0,
})
LEAVES['update_sprite_view_'] = (0x4f92b, 579)
DATA_OFFSETS.update({
    '_temporary_view_sprites': 0x2710a0,
    '_view_tile_animation_flags': 0x1ed3a0,
    '_view_interpolation_modes': 0x3ccb,
    '_view_previous_positions': 0x20a2c,
    '_view_interpolation_fraction': 0x770bc,
    '_view_interpolation_clock': 0x770d4,
    '_view_sprite_count': 0x287e84,
    '_view_sector_ceiling_flags': 0x27c3ac,
    '_view_sector_ceiling_shade': 0x27c3b4,
    '_view_sector_floor_shade': 0x27c3bc,
})
LEAVES['initialize_board_entry_'] = (0x5374f, 293)
LEAVES['board_entry_palette_1_'] = (0x53874, 26)
LEAVES['board_entry_palette_2_'] = (0x5388e, 26)
LEAVES['board_entry_palette_3_'] = (0x538a8, 26)
LEAVES['board_entry_palette_4_'] = (0x538c2, 23)
LEAVES['board_entry_palette_5_'] = (0x538d9, 23)
LEAVES['board_entry_palette_6_'] = (0x538f0, 23)
LEAVES['board_entry_palette_7_'] = (0x53907, 23)
LEAVES['board_entry_default_palette_'] = (0x5391e, 50)
DATA_OFFSETS.update({
    '_board_player_sprites': 0x2040a0,
    '_board_player_sprite': 0x62f2c,
    '_board_player_sector': 0x5acfc,
    '_board_player_angle': 0x6308c,
    '_board_player_x': 0x5ad9c,
    '_board_player_y': 0x5ad5c,
    '_board_player_z': 0x5ad1c,
    '_board_player_positions': 0x20a2c,
    '_board_sprite_visibility': 0x1ecfa0,
    '_board_player_palette': 0x1df6c,
    '_board_player_ramp': 0x1e02b,
})
DATA_OFFSETS.update({
    '_playback_view_key': 0x3cab,
    '_playback_mode_key': 0x3caa,
    '_playback_timer_enabled': 0x3ce9,
    '_playback_pending_time': 0x3cd6,
    '_playback_last_tick': 0x3cea,
    '_playback_saved_clock': 0x3cee,
    '_playback_listener': 0x3cfa,
    '_playback_first_player': 0x19028a,
    '_playback_next_player': 0x18fd78,
    '_playback_actor_clock': 0x770b8,
    '_playback_frame_count': 0x770d0,
    '_playback_keys': 0x6793c,
    '_playback_player_mode': 0x62f1c,
    '_playback_board_name': 0x1e5ac,
    '_recorded_input_a': 0x2db6c,
    '_recorded_input_b': 0x2db6d,
    '_recorded_input_c': 0x2db6e,
    '_recorded_input_word': 0x2db6f,
    '_playback_input_a': 0x5ac3c,
    '_playback_input_b': 0x5ac3d,
    '_playback_input_c': 0x5ac3e,
    '_playback_input_word': 0x5ac3f,
    '_playback_quit': 0x6793d,
})
LEAVES['find_spawn_position_'] = (0x53bfc, 507)
DATA_OFFSETS.update({
    '_spawn_hitag': 0x27c3c4,
    '_spawn_lotag': 0x27c3c2,
    '_spawn_floor_flags': 0x27c3ae,
    '_spawn_first_wall': 0x27c3a0,
    '_spawn_wall_count': 0x27c3a2,
    '_spawn_ceiling': 0x27c3a4,
    '_spawn_floor': 0x27c3a8,
    '_spawn_wall_x': 0x2310a0,
    '_spawn_wall_y': 0x2310a4,
})
LEAVES['resolve_teleport_destination_'] = (0x53df7, 501)
DATA_OFFSETS.update({
    '_teleport_sound_name': 0x5a8,
    '_teleport_sectors': 0x1ccac,
    '_teleport_count': 0x7dece,
    '_teleport_wall_x': 0x2310a0,
    '_teleport_wall_y': 0x2310a4,
    '_teleport_wall_next': 0x2310a8,
    '_teleport_wall_link': 0x2310ac,
    '_teleport_sector_wall_starts': 0x27c3a0,
    '_teleport_sector_wall_counts': 0x27c3a2,
    '_teleport_sector_floors': 0x27c3a8,
    '_teleport_sector_tags': 0x27c3c4,
})
LEAVES['sectors_share_portal_'] = (0x549ce, 157)
LEAVES['preload_game_tiles_'] = (0x6074b, 295)
LEAVES['confirm_menu_action_'] = (0x5f6ce, 89)
LEAVES['confirm_reset_key_bindings_'] = (0x5fa43, 79)
LEAVES['run_mouse_settings_'] = (0x603e2, 98)
LEAVES['run_keyboard_settings_'] = (0x5fc5c, 98)
LEAVES['trigger_tagged_crushers_'] = (0x65bb8, 170)
LEAVES['check_crushed_sprites_'] = (0x65a34, 162)
LEAVES['play_crusher_sound_'] = (0x65ad6, 89)
LEAVES['update_level_effects_'] = (0x65c62, 487)
DATA_OFFSETS.update({
    '_crusher_update_bad_bank': 0x1634,
    '_crusher_update_disabled': 0x1651,
    '_crusher_update_bad_sector': 0x1675,
    '_update_crusher_banks': 0x174640,
    '_crusher_update_sectors': 0x27c3a0,
    '_crusher_update_sector_ceiling': 0x27c3a4,
    '_crusher_update_floor_shade': 0x27c3bc,
})
LEAVES['dispatch_hit_event_'] = (0x50969, 132)
LEAVES['run_control_limits_menu_'] = (0x6065b, 240)
LEAVES['run_mouse_sensitivity_menu_'] = (0x600a9, 275)
LEAVES['run_mouse_button_menu_'] = (0x601bc, 550)
DATA_OFFSETS.update({
    '_mouse_row_format': 0x122c, '_mouse_blank': 0x1232,
    '_mouse_empty_format': 0x1233, '_mouse_menu_title': 0x123b,
    '_mouse_menu_prompt': 0x1248, '_mouse_action_labels': 0x13558,
    '_mouse_bindings': 0x139f4, '_mouse_button_names': 0x139f7,
    '_mouse_menu_entries': 0x1741f4, '_mouse_menu_rows': 0x174268,
    '_mouse_menu_selection': 0x1745ac, '_mouse_buttons': 0x7dee2,
})
LEAVES['append_configuration_section_'] = (0x5b52c, 164)
LEAVES['write_configuration_value_'] = (0x5b288, 196)
LEAVES['load_video_settings_'] = (0x5bf52, 196)
LEAVES['replace_configuration_value_'] = (0x5b18b, 253)
LEAVES['parse_configuration_integer_'] = (0x5afb8, 174)
LEAVES['initialize_game_subsystems_'] = (0x60872, 219)
LEAVES['initialize_ripple_tables_'] = (0x540a2, 181)
LEAVES['load_sound_archive_'] = (0x59f56, 260)
LEAVES['append_configuration_integer_'] = (0x5b6c5, 277)
LEAVES['initialize_board_sprite_state_'] = (0x53b2b, 209)
LEAVES['adjust_status_value_'] = (0x35f2e, 203)
LEAVES['adjust_player_status_'] = (0x4e917, 308)
LEAVES['audio_pan_'] = (0x5a477, 161)
LEAVES['audio_sprite_pan_'] = (0x5a518, 89)
FUNCTION_ADDRESSES['getangle_'] = 0x4c94c
DATA_OFFSETS.update({'_radarang': 0x287e94, '_column_angles': 0x1dcde0,
                     '_view_width_reciprocal': 0x286b04,
                     '_xdim': 0x287e90, '_ydim': 0x287e8c, '_bytesperline': 0x286b64,
                     '_view_left_scaled': 0x286b10, '_view_right_scaled': 0x286b0c,
                     '_view_top_scaled': 0x286b1c, '_view_bottom_scaled': 0x286b18,
                     '_half_view_width': 0x286b08, '_view_height': 0x286af4})


LEAVES['move_listed_sprite_'] = (0x38b1a, 405)
LEAVES['move_sprite_'] = (0x58fb9, 311)
DATA_OFFSETS.update({'_move_sprites': 0x2040a0, '_move_tile_heights': 0x1f4020})
DATA_OFFSETS.update({'_move_ceiling_z': 0x770a4, '_move_ceiling_hit': 0x770a8,
                     '_move_floor_z': 0x770b4, '_move_floor_hit': 0x770b0})
FUNCTION_ADDRESSES.update({'move_clip_': 0x5291f, 'move_change_sector_': 0x50bc3,
                           'move_zrange_': 0x562f9, 'move_add_listed_': 0x134c2})


LEAVES['audio_volume_'] = (0x5a41b, 92)
DATA_OFFSETS.update({'_audio_listener_index': 0x3cfa, '_audio_listener_angles': 0x6308c,
                     '_audio_pan_table': 0x12c40})
FUNCTION_ADDRESSES['ksqrt_'] = 0x4ca38
FUNCTION_ADDRESSES['wallfront_'] = 0x45313
DATA_OFFSETS.update({
    '_bunchfirst': 0x1d7560,
    '_bunchlast': 0x1d9560,
    '_p2': 0x1d8560,
    '_xb1': 0x1c5160,
    '_xb2': 0x1c3160,
})


LEAVES['animation_prestep_'] = (0x5d4e0, 181)
DATA_OFFSETS.update({'_prestep_value': 0x12d84, '_prestep_direction': 0x12d88,
                     '_prestep_speed': 0x12d8c, '_prestep_hold': 0x12d90})


LEAVES.update({'changespritesect_': (0x761c3, 80), 'changespritestat_': (0x76213, 80)})
FUNCTION_ADDRESSES.update({'deletespritesect_': 0x50a1d, 'insertspritesect_': 0x508cd,
                           'deletespritestat_': 0x50af0, 'insertspritestat_': 0x5096b})


LEAVES.update({'activate_crush_sector_': (0x65e49, 328),
               'deletesprite_': (0x76009, 20), 'loadtables_': (0x6f894, 211)})
DATA_OFFSETS.update({'_activate_crush_banks': 1525312, '_activate_crush_sectors': 2605984, '_activate_crush_numsectors': 2658644, '_activate_crush_goals': 111156, '_activate_crush_velocity': 109108, '_activate_crush_silent': 80816, '_activate_bad_bank': 5776, '_activate_disabled': 5805, '_activate_bad_sector': 5837, '_activate_bad_slot': 5868, '_tablesloaded': 82105, '_tables_filename': 6716, '_reciptable': 1913184, '_sintable': 2293920, '_radarang': 2653844, '_textfont': 1841504, '_smalltextfont': 1921376, '_britable': 1842528})
FUNCTION_ADDRESSES.update({
    'windows_driver_interrupt_': 0x6684c,
    'windows_driver_interrupt_stop_': 0x66881,
    'copy_far_driver_interface_': 0x665e5,
    'driver_command_3_': 0x66724,
    'read_driver_parameters_': 0x66687,
    'unlock_memory_region_': 0x663ce,
    'release_driver_memory_': 0x664b7,
    'lock_memory_region_': 0x66391,
    'allocate_driver_memory_': 0x6640b,
    'read_driver_image_': 0x6e666,
    'query_extender_': 0x669a0,
    'allocate_dpmi_audio_buffer_': 0x61f49,
    'allocate_dos_buffer_': 0x6654a,
    'driver_command_5_': 0x66641,
    'driver_secondary_command_1_': 0x66754,
    'release_dpmi_audio_buffer_': 0x62065,
    'read_driver_command_table_': 0x666cb,
    'get_driver_tables_': 0x668b6,
    'copy_driver_record_': 0x668f5,
    'set_driver_callback_': 0x6693f,
    'driver_command_0_': 0x66664,
    'allocate_exchange_block_': 0x669bd,
    'release_exchange_block_': 0x669fe,
    'query_dpmi_buffer_': 0x66a2c,
    'map_dpmi_buffer_': 0x66ae5,
    'free_dpmi_buffer_': 0x66a98,
    '_fmemcpy_': 0x63272,
    'draw_menu_entries_': 0x38ac0,
    'draw_screen_text_': 0x560de,
    'menu_glyph_tile_': 0x38499,
    'small_text_return_': 0x386cd,
    'advance_menu_animation_': 0x390c7,
    'draw_menu_selection_marker_': 0x39143,
    'draw_save_slot_preview_': 0x39c45,
    'menu_frame_return_': 0x386cd,
    'release_dos_buffer_': 0x66580,
    'unload_audio_driver_image_': 0x660f2,
    'release_driver_workspace_': 0x66246,
    'get_driver_alias_': 0x664ed,
    'initialize_audio_backend_': 0x65802,
    'shutdown_audio_backend_': 0x65b74,
})
FUNCTION_ADDRESSES.update({'activate_crush_error_': 158211, 'activate_crush_lookup_': 262871, 'activate_find_animation_': 192417, 'activate_set_animation_': 192448, 'activate_crush_sound_': 263382, 'initksqrt_': 314026, 'kopen4load_': 266881, 'kread_': 267133, 'klseek_': 267345, 'kclose_': 267523})

SPRITE_PATH_BOARDS = tuple(f'initialize_sprite_path_board_{board + 1:02}_' for board in range(25))
SPRITE_PATH_INITIALIZER_SIZE = 443
SPRITE_PATH_VARIANTS = (
    (0x40fb4, 797),
    (0x412d1, 443),
    (0x4148c, 1328),
    (0x419bc, 797),
    (0x41cd9, 443),
    (0x41e94, 856),
    (0x421ec, 561),
    (0x4241d, 443),
    (0x425d8, 443),
    (0x42793, 503),
)
LEAVES.update({
    name: (0x3f5bf + index * SPRITE_PATH_INITIALIZER_SIZE, SPRITE_PATH_INITIALIZER_SIZE)
    for index, name in enumerate(SPRITE_PATH_BOARDS[:15])
})
LEAVES.update(zip(SPRITE_PATH_BOARDS[15:], SPRITE_PATH_VARIANTS))
LEAVES['initialize_board_routes_'] = (0x42a4a, 733)
LEAVES['route_actor_toward_target_'] = (0x429ee, 92)
FUNCTION_ADDRESSES.update({name: LEAVES[name][0] - 0x25600 for name in SPRITE_PATH_BOARDS})
FUNCTION_ADDRESSES['resolve_route_sectors_'] = 0x1d727
FUNCTION_ADDRESSES['route_find_actor_sprite_'] = 0x1d7f6
LEAVES.update({
    'resolve_route_sectors_': (0x42d27, 11),
    'route_start_zone_scan_': (0x42d32, 7),
    'resolve_route_waypoint_': (0x42d39, 60),
    'route_report_bad_waypoint_': (0x42d75, 36),
    'store_route_waypoint_sector_': (0x42d99, 26),
    'route_check_waypoint_index_': (0x42db3, 46),
    'advance_route_zone_': (0x42de1, 4),
    'route_check_zone_index_': (0x42de5, 17),
    'route_find_actor_sprite_': (0x42df6, 77),
    'route_read_bounds_': (0x42e43, 126),
    'route_check_bounds_index_': (0x42ec1, 16),
    'route_read_zone_route_': (0x42f3d, 118),
    'route_cross_zone_': (0x42fb3, 201),
    'route_move_to_zone_exit_': (0x4307c, 96),
    'route_choose_actor_target_': (0x42ed1, 108),
    'route_select_target_tail_': (0x430dc, 12),
})
FUNCTION_ADDRESSES.update({
    'route_start_zone_scan_': 0x1d732,
    'resolve_route_waypoint_': 0x1d739,
    'route_report_bad_waypoint_': 0x1d775,
    'store_route_waypoint_sector_': 0x1d799,
    'route_check_waypoint_index_': 0x1d7b3,
    'advance_route_zone_': 0x1d7e1,
    'route_check_zone_index_': 0x1d7e5,
    'route_read_bounds_': 0x1d843,
    'route_check_bounds_index_': 0x1d8c1,
    'finish_actor_route_': 0x1dae1,
    'route_move_to_zone_exit_': 0x1da7c,
    'route_select_target_tail_': 0x1dadc,
    'select_sprite_path_target_': 0x19c7d,
    'format_route_error_': 0x601f3,
    'report_route_error_': 0x26a03,
})
DATA_OFFSETS.update({
    '_route_last_zone': 0x841dc,
    '_route_zone_routes': 0x841d8,
    '_route_zone_bounds': 0x841d4,
    '_route_records': 0x83d88,
    '_route_sector_lists': 0x83d8c,
    '_route_actor_sprite': 0x7dab8,
    '_route_sprite_hitag': 0x2040ca,
    '_route_actor_sequence': 0x7e4e2,
    '_route_sprite_x': 0x2040a0,
    '_route_sprite_sector': 0x2040b8,
    '_route_sprite_z': 0x2040a8,
    '_route_sector_floor_z': 0x27c3a8,
    '_route_floor_offsets': 0x83d9a,
    '_route_ceiling_offsets': 0x83d96,
    '_route_widths': 0x83d94,
    '_route_next_hops': 0x83d90,
    '_route_sprite_y': 0x2040a4,
    '_route_error_buffer': 0x67e3c,
    '_route_bad_waypoint': 0x378,
    '_route_missing_terminator': 0x3aa,
    '_route_current_board': 0x7f87e,
    '_route_loaded_board': 0x127e4,
    '_actor_route_cache': 0x841de,
})

LEAVES.update({
    'crt_argument_noop_': (0x88a14, 1),
    'audio_helper_region_end_': (0x8c173, 1),
    'timer_vector_noop_': (0x8a59d, 1),
    'DISCARD_STACK_CHECK_ARGUMENT': (0x8c628, 3),
    'step_up_80_': (0x97820, 4),
    'step_down_80_': (0x97825, 4),
    'step_up_40_': (0x9782a, 4),
    'step_down_40_': (0x9782f, 4),
    'step_byte_up_320_': (0x97d6f, 7),
    'step_byte_down_320_': (0x97d77, 7),
    'step_byte_left_': (0x97d7f, 2),
    'step_byte_right_': (0x97d82, 2),
    'step_byte_up_100_': (0x98081, 4),
    'step_byte_down_100_': (0x98086, 4),
    'get_audio_level_a_': (0x5acd6, 6),
    'set_audio_level_a_': (0x5acdc, 40),
    'get_audio_level_b_': (0x5ad04, 6),
    'set_audio_level_b_': (0x5ad0a, 40),
    'adjust_palette_red_': (0x5bcdd, 7),
    'adjust_palette_blue_': (0x5bce4, 7),
    'adjust_palette_green_': (0x5bceb, 7),
    'request_menu_redraw_': (0x5de00, 8),
    'capture_fade_palette_': (0x5bb8e, 40),
    'scale_fade_palette_': (0x5bbb6, 37),
    'palette_is_dimmed_': (0x5bbdb, 19),
    'reset_palette_fade_': (0x5bcc6, 23),
    'reset_palette_color_scales_': (0x5bf30, 26),
    'run_palette_fade_': (0x5bbee, 64),
    'palette_fade_out_entry_': (0x5bc62, 7),
    'start_fade_out_': (0x5bc2e, 52),
    'start_fade_in_': (0x5bc69, 55),
    'palette_fade_in_entry_': (0x5bca0, 38),
    'print_frame_rate_': (0x71636, 122),
    'reset_frame_timing_': (0x716b0, 23),
    'setsprite_': (0x75cf6, 98),
    'report_game_error_': (0x4c003, 39),
    'audio_source_attenuation_': (0x5a3b6, 101),
    'run_help_page_menu_': (0x5fd53, 95),
    'run_first_help_pages_': (0x5fdb2, 78),
    'run_second_help_pages_': (0x5fe00, 113),
    'menu_glyph_tile_': (0x5da99, 117),
    'run_help_submenu_': (0x5fe71, 58),
    'trigger_crusher_on_entry_': (0x65b2f, 137),
    'stop_sound_': (0x5a282, 140),
    'initialize_sound_slots_': (0x5a113, 227),
    'initialize_game_audio_': (0x5a05a, 185),
    'stop_sprite_sound_': (0x5a30e, 168),
    'register_pan_sector_': (0x37594, 73),
    'build_palette_fade_tables_': (0x5b905, 649),
    'update_sector_panning_': (0x3748e, 18),
    'pan_prepare_sector_': (0x374a0, 86),
    'pan_floor_cases_': (0x374f6, 50),
    'pan_ceiling_cases_': (0x37528, 77),
    'pan_advance_': (0x37575, 23),
    'pan_ceiling_y_normal_': (0x3758c, 8),
    'setuptvlineasm_': (0x99910, 6),
    'setupvlineasm_': (0x998d0, 31),
    'setupmvlineasm_': (0x998f0, 26),
    'fixtransluscence_': (0x999a0, 46),
    'setpalookupaddress_': (0x996e0, 36),
    'setvlinebpl_': (0x99690, 76),
    'setuptvlineasm2_': (0x9a320, 35),
    'setup_sprite_horizontal_masked_': (0x9a830, 30),
    'msethlineshift_': (0x9a050, 36),
    'tsethlineshift_': (0x9a1c0, 36),
    'setup_sprite_horizontal_unrolled_': (0x9a680, 146),
    'refresh_inventory_': (0x4ea4b, 81),
    'print_command_line_help_': (0x5cab8, 108),
    'parse_startup_arguments_': (0x5cb24, 197),
    'load_palette_tables_': (0x6f967, 281),
    'initialize_mouse_': (0x79a0e, 22),
    'print_video_settings_help_': (0x5c67f, 109),
    'set_vesa_dac_width_': (0x6973c, 64),
    'print_video_text_at_': (0x5c10e, 92),
    'initialize_video_console_': (0x5c16a, 138),
    'prompt_video_settings_': (0x5c573, 268),
    'snapshot_input_': (0x527bd, 129),
    'output_queue_depth_': (0x68cfa, 58),
    'copy_configuration_value_': (0x5b066, 147),
    'broadcast_network_ready_': (0x68c7c, 126),
    'select_item_': (0x5d6d8, 180),
    'detect_cd_drives_': (0x5ccbb, 95),
    'simulate_real_mode_interrupt_': (0x5cbe9, 112),
    'dpmi_real_mode_interrupt_': (0x68e0a, 239),
    'dpmi_real_mode_far_call_': (0x68ef9, 292),
    'initialize_cd_audio_': (0x5cf50, 280),
    'prepare_cd_request_buffers_': (0x5cd1a, 141),
    'send_cd_driver_request_': (0x5cda7, 94),
    'request_cd_device_status_': (0x5ce05, 44),
    'request_cd_device_control_': (0x5ce31, 30),
    'request_cd_disk_info_': (0x5ce4f, 30),
    'next_cd_track_': (0x5d406, 72),
    'previous_cd_track_': (0x5d44e, 34),
    'read_cd_track_start_': (0x5ced8, 120),
    'stop_cd_driver_playback_': (0x5d085, 157),
    'resume_cd_driver_playback_': (0x5d2d5, 141),
    'toggle_cd_pause_': (0x5d362, 140),
    'shutdown_serial_network_': (0x672de, 123),
    'set_network_socket_': (0x68d34, 214),
    'send_network_join_request_': (0x68b90, 236),
    'discard_level_and_load_board_': (0x3964a, 233),
    'save_level_and_load_board_': (0x394ed, 349),
    'restore_level_modifications_': (0x35720, 220),
    'save_level_modifications_': (0x357fc, 206),
    'play_cd_track_': (0x5d122, 435),
    'read_cd_track_info_': (0x5ce6d, 107),
    'allocate_dos_memory_': (0x5cc59, 98),
    'free_video_dos_memory_': (0x6901d, 51),
    'spawn_float_sprite_': (0x38d52, 270),
    'update_float_sprites_': (0x38caf, 163),
    'shutdown_game_audio_': (0x5a1f6, 64),
    'sound_sample_done_': (0x5a236, 76),
    'graphics_stack_limit_': (0x97186, 6),
    'labs_': (0x858c3, 7),
    'min_': (0x88801, 7),
    'tell_': (0x903b5, 17),
    'initrandnext_': (0x858ca, 6),
    'rand_': (0x858d0, 36),
    'srand_': (0x858f4, 16),
    'fputc_': (0x8a257, 164),
    'set_permission_denied_': (0x89c89, 5),
    'set_errno_': (0x89c8e, 12),
    'set_bad_address_': (0x89c9a, 7),
    'set_runtime_error_': (0x89cb1, 12),
    'bad_file_descriptor_': (0x89ca1, 16),
    'print_runtime_message_': (0x661b4, 34),
    'set_absolute_graphics_pair_': (0x96c2c, 31),
    'set_nonzero_graphics_pair_': (0x96c4b, 34),
    'set_graphics_word_a5_': (0x96c6d, 7),
    'set_graphics_word_ab_': (0x96c74, 7),
    'set_graphics_pair_ad_': (0x96c7b, 14),
    'get_drawing_color_': (0x9703f, 7),
    'set_drawing_color_': (0x97046, 30),
    'replace_drawing_color_': (0x97064, 30),
    'set_drawing_action_': (0x96f50, 81),
    'set_graphics_clipping_': (0x96c89, 115),
    'get_fill_pattern_': (0x96fa1, 42),
    'set_fill_pattern_': (0x96fcb, 116),
    'get_video_configuration_': (0x951d8, 34),
    'set_video_mode_': (0x9428a, 234),
    'set_video_mode_and_text_rows_': (0x96987, 23),
    'set_cga_graphics_mode_': (0x95664, 124),
    'set_vga_graphics_mode_': (0x95bf7, 171),
    'address_vga_byte_pixel_': (0x95d08, 60),
    'finish_banked_planar_drawing_': (0x9630f, 7),
    'select_graphics_bank_': (0x96316, 21),
    'address_banked_byte_pixel_640_': (0x963dd, 70),
    'address_banked_byte_pixel_800_': (0x96423, 11),
    'address_banked_byte_pixel_1024_': (0x9642e, 9),
    'address_banked_planar_pixel_1024_': (0x9637d, 96),
    'address_vga_mono_pixel_': (0x95ca2, 102),
    'address_cga_mono_pixel_': (0x956e0, 126),
    'address_hercules_pixel_': (0x958fc, 128),
    'address_planar_pixel_800_': (0x9632b, 82),
    'address_planar_pixel_320_': (0x95b39, 85),
    'address_planar_pixel_640_': (0x95b8e, 12),
    'address_two_plane_pixel_': (0x95b9a, 93),
    'set_hercules_mode_': (0x95893, 105),
    'set_planar_graphics_mode_': (0x9597c, 346),
    'bios_mode_supported_': (0x97736, 74),
    'set_and_query_bios_mode_': (0x97780, 119),
    'resolve_video_mode_': (0x94374, 309),
    'detect_color_adapter_': (0x96bd8, 21),
    'detect_display_adapters_': (0x9699e, 211),
    'detect_legacy_display_adapters_': (0x96a71, 230),
    'program_hercules_graphics_': (0x957e9, 170),
    'detect_mono_adapter_': (0x96b57, 129),
    'probe_crtc_cursor_register_': (0x96bed, 63),
    'configure_vga_text_font_': (0x967aa, 116),
    'set_standard_text_rows_': (0x9674f, 91),
    'set_text_rows_': (0x96437, 230),
    'initialize_text_pages_': (0x951fa, 115),
    'read_graphics_mode_state_': (0x9526d, 296),
    'initialize_graphics_once_': (0x95395, 137),
    'set_bios_cursor_visible_': (0x95526, 37),
    'hide_graphics_cursor_': (0x954bd, 105),
    'apply_graphics_mode_state_': (0x9541e, 113),
    'configure_ega_text_font_': (0x9681e, 149),
    'get_background_color_': (0x947b9, 6),
    'set_background_color_': (0x947bf, 109),
    'flatten_sprite_': (0x65f91, 183),
    'bitmap_row_bytes_': (0x9714a, 60),
    'bitmap_rectangle_size_': (0x9710b, 63),
    'set_text_window_': (0x948e7, 124),
    'get_text_window_': (0x948b2, 53),
    'draw_view_border_': (0x59cf2, 201),
    'draw_status_message_': (0x59c2d, 197),
    'map_first_coordinate_': (0x9886a, 43),
    'map_second_coordinate_': (0x98895, 64),
    'map_first_extent_': (0x988d5, 53),
    'map_second_extent_': (0x9890a, 42),
    'recalculate_coordinate_scales_': (0x98b1c, 168),
    'map_coordinate_pair_': (0x98a7b, 67),
    'map_pair_stack_': (0x98abe, 30),
    'map_pair_from_pointer_': (0x98adc, 29),
    'copy_world_bounds_': (0x98af9, 35),
    'unmap_coordinate_pair_': (0x98934, 327),
    'set_audio_flag_a_': (0x5ac9c, 29),
    'set_audio_flag_b_': (0x5acb9, 29),
    'abs_': (0x8592c, 7),
    'get_io_mode_': (0x8ad83, 85),
    '__set_binary_': (0x86b51, 32),
    'set_binary_device_get_': (0x86b71, 19),
    'set_binary_dos_error_': (0x86b84, 13),
    'set_binary_device_set_': (0x86b91, 27),
    'set_binary_success_': (0x86bac, 2),
    'set_binary_restore_': (0x86bae, 8),
    'set_io_mode_': (0x8add8, 21),
    'close_descriptor_': (0x8a220, 50),
    'isatty_': (0x8acf3, 30),
    'read_descriptor_raw_': (0x89fa9, 31),
    'read_console_character_': (0x904a1, 29),
    'getch_': (0x884df, 29),
    'filelength_': (0x88808, 61),
    'remove_': (0x8a252, 5),
    'remove_file_dos_': (0x9053a, 31),
    'toupper_': (0x883ce, 14),
    'hex_digit_': (0x85e46, 12),
    '_fsopen_': (0x85b87, 27),
    'fopen_': (0x85ba2, 10),
    'freopen_': (0x85c14, 36),
    'close_': (0x8779a, 5),
    'flushall_': (0x88483, 5),
    'flush_matching_streams_': (0x88488, 47),
    '__shutdown_stream_': (0x85e31, 21),
    'fclose_': (0x85e02, 47),
    'fgetc_': (0x89fc8, 137),
    'flush_stream_': (0x8a131, 191),
    'write_stream_descriptor_': (0x904be, 124),
    'u32_to_float_': (0x99548, 43),
    'i32_to_float_': (0x99573, 17),
    'truncate_float_': (0x99500, 12),
    'truncate_float_zero_': (0x99545, 3),
    'truncate_magnitude_': (0x9950c, 37),
    'truncate_shift_left_': (0x99531, 7),
    'truncate_limit_': (0x99538, 13),
    'float_to_double_': (0x99584, 86),
    'initialize_standard_streams_': (0x903c6, 120),
    'close_nonstandard_streams_': (0x9044a, 5),
    'close_streams_from_index_': (0x9044f, 82),
    'refill_and_get_character_': (0x8a051, 47),
    'ftell_': (0x8a1f0, 48),
    'detect_terminal_': (0x89f01, 49),
    'allocate_stream_': (0x89cc4, 168),
    'allocate_stream_buffer_': (0x89f32, 119),
    'fill_buffer_': (0x8a080, 171),
    'atoi_': (0x88268, 87),
    'strlen_': (0x85981, 25),
    'memcpy_': (0x88845, 37),
    '_fmemcpy_': (0x88872, 40),
    'copy_c_string_': (0x8cbf4, 15),
    'dos_find_close_': (0x8cbab, 3),
    'dos_search_status_': (0x93d8e, 19),
    'copy_dta_to_caller_': (0x8cbae, 35),
    'copy_caller_to_dta_': (0x8cbd1, 35),
    'dosret0_': (0x8ad11, 7),
    'access_': (0x88730, 29),
    'access_translate_': (0x8874d, 30),
    'mask_timer_irq_': (0x8a470, 44),
    'unmask_timer_irq_': (0x8a49c, 44),
    'program_pit_': (0x8a36f, 70),
    'driver_command_5_': (0x8bc41, 35),
    'driver_command_0_': (0x8bc64, 35),
    'read_driver_parameters_': (0x8bc87, 68),
    'windows_driver_interrupt_': (0x8be4c, 53),
    'windows_driver_interrupt_stop_': (0x8be81, 53),
    'get_driver_tables_': (0x8beb6, 63),
    'set_driver_callback_': (0x8bf3f, 54),
    'query_dpmi_memory_': (0x8bf75, 43),
    'query_windows_version_': (0x8bfa0, 29),
    'release_dos_selector_': (0x8bffe, 46),
    'configure_fpu_': (0x9038e, 39),
    'driver_command_3_': (0x8bd24, 48),
    'driver_secondary_command_1_': (0x8bd54, 35),
    'driver_configure_secondary_': (0x8bd77, 53),
    'driver_secondary_command_4_': (0x8bdac, 41),
    'driver_secondary_command_2_': (0x8bdd5, 38),
    'driver_secondary_command_3_': (0x8bdfb, 39),
    'translate_exec_result_': (0x8ad18, 5),
    'set_dos_errno_': (0x8ad1d, 102),
    'parse_command_line_': (0x88ad2, 233),
    'apply_mouse_button_binding_': (0x5ffaa, 255),
    'dos_find_next_': (0x8cb8f, 28),
    'dos_find_first_': (0x8cb72, 29),
    'inp_': (0x8886a, 8),
    'outpw_': (0x88920, 11),
    'outp_': (0x8599a, 14),
    'normalize_separator_': (0x8cf2c, 18),
    'split_path_': (0x8cea2, 137),
    'path_noop_': (0x8cf2b, 1),
    'make_path_': (0x8cf3e, 203),
    'seek_within_buffer_': (0x89dc3, 66),
    'fseek_': (0x89e05, 252),
    'copy_path_part_': (0x8ce5e, 68),
    'bounded_far_strlen_': (0x88fca, 36),
    'format_padded_hex_': (0x89011, 97),
    'format_fixed_point_': (0x89072, 219),
    'bounded_far_wcslen_': (0x88fee, 35),
    'div_': (0x888e8, 56),
    'getenv_': (0x895b5, 90),
    'call_float_formatter_': (0x8914d, 7),
    'probe_executable_': (0x89635, 31),
    'prepare_spawn_': (0x89654, 51),
    'build_command_tail_': (0x8cd3b, 85),
    'build_child_environment_': (0x8cc03, 312),
    'spawnve_': (0x89687, 766),
    'stackavail_': (0x8c606, 9),
    '__CMain': (0x8892b, 79),
    'system_': (0x8585a, 105),
    'spawnlp_': (0x89985, 22),
    'lseek_': (0x86bb6, 65),
    'spawn_with_arguments_': (0x8d015, 30),
    'spawn_with_path_search_': (0x8d033, 14),
    'free_recycled_streams_': (0x89da5, 30),
    'recycle_stream_': (0x89d6c, 57),
    'call_stream_hook_': (0x89cbd, 7),
    'find_configuration_section_': (0x5ae82, 133),
    'uppercase_output_': (0x8959d, 24),
    'strupr_': (0x884fc, 31),
    'strncpy_': (0x8889a, 37),
    'strncmp_': (0x888bf, 41),
    'format_integer_': (0x8caff, 27),
    'ltoa_': (0x8832e, 27),
    '__CommonInit_': (0x8ca74, 11),
    'float_support_missing_': (0x8ca7f, 18),
    'stream_format_putc_': (0x8876b, 17),
    'write_stream_format_': (0x8877c, 133),
    'vsprintf_putc_': (0x884b7, 19),
    'sprintf_putc_': (0x857e0, 19),
    'sprintf_': (0x857f3, 48),
    'parse_format_flags_': (0x88f6f, 91),
    'parse_format_specifier_': (0x88e3c, 307),
    'format_engine_': (0x88bbb, 641),
    'convert_format_value_': (0x89154, 1097),
    'format_unsigned_': (0x8cab6, 73),
    'ultoa_': (0x882e4, 74),
    'stricmp_': (0x88395, 57),
    'memmove_': (0x88349, 76),
    'memset_': (0x86950, 24),
    'open_': (0x86968, 36),
    'close_file_': (0x85bac, 104),
    '__doclose_': (0x85ebb, 137),
    '__MkTmpFile_': (0x85e52, 105),
    '_dos_getvect_': (0x859a8, 52),
    '_dos_setvect_': (0x859de, 43),
    '__open_flags_': (0x85a0b, 180),
    '__doopen_': (0x85abf, 200),
    'strnicmp_': (0x8cb1a, 87),
    'unlink_near_heap_': (0x8a751, 63),
    'release_empty_heaps_': (0x8a790, 94),
    'resize_dpmi_heap_': (0x8a7ee, 25),
    'resize_heap_target_': (0x8a807, 117),
    'resize_heap_result_': (0x8a87c, 87),
    'resize_use_whole_block_': (0x8a8d3, 7),
    'resize_return_block_': (0x8a8da, 4),
    'resize_next_heap_': (0x8a8de, 3),
    'resize_check_heap_': (0x8a8e1, 8),
    'resize_return_zero_': (0x8a8e9, 2),
    'resize_restore_': (0x8a8eb, 6),
    'allocate_dpmi_heap_': (0x8a9b3, 49),
    'allocate_dpmi_result_': (0x8a9e4, 29),
    'allocate_dos_fallback_': (0x8aa01, 21),
    'allocate_dos_heap_': (0x8aa16, 101),
    'allocate_heap_failure_': (0x8aa7b, 2),
    'discard_heap_request_': (0x8aa7d, 3),
    'heap_release_restore_': (0x8aa80, 6),
    'free_space_at_break_': (0x8a965, 78),
    'link_and_initialize_heap_': (0x8a8f1, 116),
    'round_heap_request_': (0x8ac79, 119),
    'expand_separate_heap_': (0x8aa86, 15),
    'expand_return_zero_': (0x8aa95, 4),
    'expand_check_limit_': (0x8aa99, 52),
    'expand_allocate_dos_': (0x8aacd, 27),
    'expand_check_block_': (0x8aae8, 77),
    'select_shell_switch_': (0x8960f, 38),
    'request_more_heap_': (0x8acf0, 3),
    'vsprintf_': (0x884ca, 21),
    '__null_int23_exit_': (0x85952, 1),
    'runtime_init_thunk_': (0x85922, 5),
    'runtime_fini_thunk_': (0x85927, 5),
    'console_exit_thunk_': (0x93c97, 5),
    'shutdown_all_streams_': (0x9043e, 12),
    'exit_': (0x85953, 24),
    '_exit_': (0x8596b, 22),
    '_disable_': (0x859dc, 2),
    '_enable_': (0x85a09, 2),
    'restore_keyboard_interrupt_': (0x54858, 38),
    'install_keyboard_interrupt_': (0x547fe, 90),
    'exchange_runtime_hook_': (0x90559, 16),
    'get_psp_selector_': (0x8a12b, 6),
    'disabled_positioned_sound_': (0x5a571, 8),
    'set_cursor_enabled_': (0x94bbd, 18),
    'fill_graphics_rectangle_': (0x97082, 73),
    'output_counted_text_': (0x940eb, 32),
    'get_text_cursor_shape_': (0x9416f, 12),
    'set_text_cursor_shape_': (0x9417b, 69),
    'scroll_text_by_rows_': (0x9410b, 100),
    'get_text_position_': (0x941c0, 50),
    'set_text_position_': (0x941f2, 152),
    'clear_screen_': (0x94a2c, 128),
    'get_text_color_': (0x9482c, 49),
    'set_text_color_': (0x9485d, 85),
    'output_text_string_': (0x940ae, 61),
    'replace_palette_entry_': (0x96cfc, 82),
    'read_palette_entry_': (0x96eac, 67),
    'replace_palette_': (0x96d85, 82),
    'upload_palette_entries_': (0x96d4e, 55),
    'show_graphics_cursor_': (0x9548f, 46),
    'restore_cursor_if_enabled_': (0x9562e, 15),
    'find_legacy_palette_index_': (0x96eef, 37),
    'write_palette_entry_': (0x96dd7, 213),
    'build_delimiter_map_': (0x8c658, 62),
    'strstr_': (0x8851b, 194),
    'strtok_': (0x885dd, 149),
    'strchr_': (0x93ef8, 26),
    'search_and_spawn_': (0x93da1, 305),
    'set_text_video_mode_': (0x957cb, 30),
    'begin_planar_drawing_': (0x95ad6, 37),
    'end_planar_drawing_': (0x95b08, 36),
    'begin_interleaved_planar_drawing_': (0x95afb, 13),
    'end_interleaved_planar_drawing_': (0x95b2c, 13),
    'upload_bios_palette_': (0x982bd, 166),
    'call_graphics_real_mode_interrupt_': (0x98420, 178),
    'free_graphics_dos_buffer_': (0x983f4, 44),
    'allocate_graphics_dos_buffer_': (0x98363, 145),
    'initialize_graphics_memory_windows_': (0x9718c, 151),
    'clear_graphics_region_': (0x94aac, 94),
    'clear_text_region_': (0x94b0a, 179),
    'clear_graphics_display_': (0x94963, 201),
    'draw_clipped_solid_line_': (0x97223, 65),
    'toggle_graphics_cursor_line_': (0x9554b, 155),
    'draw_clipped_graphics_span_': (0x98c7a, 69),
    'graphics_point_outcode_': (0x98cbf, 68),
    'clamp_point_edge_': (0x98ec8, 62),
    'clip_axis_aligned_line_': (0x98f06, 130),
    'intersect_clip_edge_': (0x98d03, 104),
    'reset_graphics_aspect_settings_': (0x944a9, 96),
    'reset_video_state_': (0x94509, 434),
    'reset_text_display_': (0x946bb, 254),
    'query_vesa_mode_': (0x69128, 73),
    'show_intro_': (0x5e016, 140),
    'draw_status_banner_': (0x5db0e, 230),
    'draw_small_tile_text_': (0x5dbf4, 223),
    'draw_intro_screen_': (0x5de08, 207),
    'draw_animated_intro_': (0x5ded7, 319),
    'fatal_runtime_error_': (0x93c9c, 29),
    'notify_debugger_': (0x93ed2, 38),
    'scale_mouse_': (0x5ff6d, 61),
    'get_errno_address_': (0x8d009, 6),
    'get_dos_error_address_': (0x8d00f, 6),
    'graphics_available_': (0x955e6, 36),
    'check_graphics_and_hide_cursor_': (0x9560a, 36),
    'viewport_bitmap_size_': (0x970cb, 64),
    'crush_sprite_': (0x66048, 204),
    'open_configuration_': (0x5ad32, 242),
    'initialize_graphics_device_': (0x9563d, 12),
    'shutdown_graphics_device_': (0x95649, 9),
    'begin_graphics_device_': (0x95652, 9),
    'end_graphics_device_': (0x9565b, 9),
    'run_exit_callbacks_': (0x661d6, 55),
    'register_exit_callback_': (0x6620d, 60),
    'open_text_archive_': (0x5d63e, 118),
    'write_configuration_boolean_': (0x5b40b, 86),
    'remove_configuration_key_': (0x5b461, 92),
    'remove_configuration_section_': (0x5b4bd, 111),
    'player_within_512_xy_': (0x35c10, 53),
    'player_within_4096_xy_': (0x35c45, 53),
    'print_video_text_': (0x5c0df, 47),
    'get_audio_flag_a_': (0x5ac83, 16),
    'get_audio_flag_b_': (0x5ac93, 9),
    'video_mode_name_': (0x5c1f4, 8),
    'reset_menu_animation_clock_': (0x5e6bc, 11),
    'write_crusher_state_': (0x6592e, 38),
    'read_crusher_state_': (0x65954, 38),
    'is_first_player_sprite_': (0x6597a, 16),
    'initialize_demo_menu_': (0x5fcbe, 39),
    'initialize_difficulty_menu_': (0x60444, 39),
    'initialize_audio_menu_': (0x60504, 39),
    'initialize_control_limits_menu_': (0x60634, 39),
    'initialize_help_menus_': (0x5fce8, 107),
    'initialize_mouse_menus_': (0x5ff24, 73),
    'initialize_key_menu_': (0x5f945, 107),
    'reset_key_bindings_': (0x5fa2c, 23),
    'initialize_game_menus_': (0x5d9d2, 199),
    'read_configuration_boolean_': (0x5b34c, 80),
    'read_configuration_integer_': (0x5b39c, 52),
    'read_configuration_string_': (0x5b3d0, 59),
    'read_audio_configuration_': (0x59e8d, 201),
    'parse_hex_digits_': (0x5b811, 53),
    'parse_hexadecimal_': (0x5b7da, 55),
    'find_configuration_key_': (0x5af07, 177),
    'read_configuration_line_': (0x5b0f9, 146),
    'append_configuration_value_': (0x5b5d0, 245),
    'close_configuration_': (0x5ae24, 94),
    'trim_and_uppercase_': (0x5d9a0, 50),
    'restore_text_video_mode_': (0x5c0c2, 29),
    'reset_vesa_state_': (0x69d6c, 32),
    'save_video_settings_': (0x5c016, 172),
    'draw_save_slot_preview_': (0x5f245, 70),
    'write_save_slot_preview_': (0x5f28b, 111),
    'read_save_slot_preview_': (0x5f2fa, 155),
    'load_game_configuration_': (0x5d78c, 261),
    'save_game_configuration_': (0x5d891, 271),
    'stop_cd_music_': (0x5d3ee, 24),
    'shutdown_cd_audio_': (0x5d068, 29),
    'reset_cd_disc_state_': (0x5d470, 112),
    'close_text_archive_': (0x5d6b4, 36),
    'advance_timer_clock_': (0x59df7, 26),
    'initialize_game_timer_': (0x59e11, 79),
    'shutdown_game_timer_': (0x59e60, 45),
    'engine_malloc_': (0x69d8c, 5),
    'engine_free_': (0x69d91, 5),
    'schedule_crush_view_kick_': (0x66114, 53),
    'apply_crush_view_kick_': (0x66149, 56),
    'check_crushed_player_': (0x6598a, 170),
})
EMPTY_LEVEL_SCRIPTS = {
    f'empty_level_script_{board + index:02}_': (raw + index, 1)
    for board, raw, count in ((1, 0x430e8, 2), (6, 0x43bd0, 1), (8, 0x43d3a, 18))
    for index in range(count)
}
EMPTY_GAME_HOOKS = {**EMPTY_LEVEL_SCRIPTS, 'empty_menu_hook_': (0x5ff20, 1)}
DISABLED_MENU_HOOKS = {'disabled_menu_hook_': (0x5ff21, 3), 'new_game_disabled_': (0x5fce5, 3)}
LEAVES.update(EMPTY_GAME_HOOKS)
LEAVES.update(DISABLED_MENU_HOOKS)

DATA_OFFSETS.update({
    '_audio_level_a': 0x12cdc,
    '_audio_level_b': 0x12ce0,
    '_palette_red_scale': 0x173d1c,
    '_palette_blue_scale': 0x173d28,
    '_palette_green_scale': 0x173d20,
    '_menu_redraw_pending': 0x1314f,
    '_saved_palette': 0x172e14,
    '_brightness_palette': 0x27c0a0,
    '_fade_level': 0x12d14,
    '_fade_in_active': 0x173d14,
    '_fade_out_active': 0x173d18,
    '_fade_speed': 0x173d24,
    '_fade_last_tick': 0x173d2c,
    '_frame_count': 0x287e74,
    '_frame_rate_format': 0x1bdf,
    '_error_newline': 0x40c,
    '_audio_flag_a': 0x12cd4,
    '_audio_flag_b': 0x12cd8,
    '_video_mode_names': 0x12d30,
    '_radial_sample_count': 0x5ae5c,
    '_radial_x_offsets': 0x5aedc,
    '_radial_y_offsets': 0x5eedc,
    '_ripple_speed': 0x630fc,
    '_ripple_wave': 0x6783c,
    '_ripple_count': 0x770e0,
    '_ripple_frame': 0x770f4,
    '_video_settings_border': 0xa1f,
    '_video_settings_mode_format': 0xa32,
    '_video_settings_separator': 0xa3e,
    '_menu_animation_clock': 0x13150,
    '_menu_tile_frame': 0x12de0,
    '_menu_marker_scale': 0x12de8,
    '_menu_color_frame': 0x12de4,
    '_crusher_state': 0x174640,
    '_tagged_crush_banks': 0x174640,
    '_hit_sectors': 0x27c3a0,
    '_hit_sprites': 0x2040a0,
    '_hit_sprite_list_head': 0x28811c,
    '_next_sprite_stat': 0x1fbca0,
    '_current_board': 0x7f87e,
    '_trigger_bad_bank': 0x159e,
    '_trigger_inactive_bank': 0x15bc,
    '_trigger_bad_sector': 0x15e8,
    '_trigger_bad_entry': 0x1608,
    '_first_player_sprite': 0x62f2c,
    '_demo_records': 0x138cc,
    '_demo_entries': 0x17455c,
    '_menu_selection_storage': 0x1740f4,
    '_menu_selection': 0x1740f0,
    '_menu_entry_count': 0x1740f8,
    '_enabled_menu_entries': 0x1740fc,
    '_active_menu_entries': 0x174048,
    '_menu_loop_state': 0x12dd4,
    '_difficulty_records': 0x13a90,
    '_difficulty_entries': 0x1745d0,
    '_audio_records': 0x13ae4,
    '_audio_entries': 0x1745e8,
    '_limits_records': 0x13b60,
    '_limits_entries': 0x174608,
    '_control_limits_selection': 0x174604,
    '_control_limits_title': 0x130c,
    '_strafe_limit': 0x13b9f,
    '_strafe_step': 0x13ba3,
    '_help_records': 0x1390c,
    '_help_entries': 0x17456c,
    '_help_extra_records': 0x1399f,
    '_help_extra_entries': 0x174580,
    '_help_back_records': 0x13960,
    '_help_back_entries': 0x174590,
    '_help_page_selection': 0x174594,
    '_help_page_title': 0x1147,
    '_back_selection': 0x17457c,
    '_help_back_title': 0x111b,
    '_crusher_index_error': 0x1506,
    '_crusher_inactive_error': 0x1525,
    '_crusher_sector_error': 0x1551,
    '_crusher_lookup_error': 0x1572,
    '_sound_slots': 0x854dc,
    '_sample_callback_overflow': 0x84c,
    '_sound_slot_storage': 0x8531c,
    '_sound_cache': 0x8551c,
    '_sound_playback': 0x16fdac,
    '_sound_cache_error': 0x831,
    '_sound_slot_overflow': 0x870,
    '_null_sample_handle': 0x892,
    '_stop_sample_error': 0x8b4,
    '_sprite_sound_slot_overflow': 0x8d7,
    '_stop_sprite_sample_error': 0x901,
    '_stopped_sprite_message': 0x924,
    '_error_buffer': 0x67e3c,
    '_restore_extension': 0x58,
    '_restore_copy_prefix': 0x5f,
    '_restore_space': 0x65,
    '_restore_mod_extension': 0x67,
    '_restore_copy_options': 0x6c,
    '_restore_copy_error': 0x79,
    '_save_extension': 0xa0,
    '_save_copy_prefix': 0xa7,
    '_save_mod_extension_and_space': 0xad,
    '_save_copy_options': 0xb3,
    '_save_copy_error': 0xc0,
    '_level_names': 0x2041,
    '_modified_levels': 0x7dea2,
    '_current_level': 0x7f87e,
    '_pan_sector_count': 0x2bea,
    '_palette_red_fade': 0x171614,
    '_palette_green_fade': 0x172214,
    '_palette_blue_fade': 0x173114,
    '_saved_palette': 0x172e14,
    '_pan_sectors': 0x704bc,
    '_pan_clock': 0x770b8,
    '_pan_clock_byte': 0x770b8,
    '_pan_sector_tag': 0x27c3c2,
    '_pan_ceiling_x': 0x27c3b6,
    '_pan_ceiling_y': 0x27c3b7,
    '_pan_floor_x': 0x27c3be,
    '_pan_floor_y': 0x27c3bf,
    '_pan_overflow': 0x18c,
    '_inventory_available': 0x2267,
    '_inventory_primary_count': 0x2277,
    '_inventory_secondary_count': 0x2287,
    '_selected_inventory_slot': 0x770c8,
    '_video_newline': 0xa51,
    '_command_line_title': 0xb4d,
    '_command_line_format': 0xb69,
    '_command_line_switches': 0x12d18,
    '_command_line_descriptions': 0x12d24,
    '_palette_filename': 0x1a47,
    '_palette_lock': 0x1401c,
    '_translucency_table': 0x140be,
    '_palette_loaded': 0x140c2,
    '_palette': 0x27c0a0,
    '_current_palookup': 0x286af0,
    '_video_mode_format': 0xa53,
    '_video_size_format': 0xa66,
    '_video_settings_instructions': 0xa7e,
    '_vesa_capabilities': 0x1ec2aa,
    '_demo_version': 0x9cb,
    '_demo_name': 0x9d1,
    '_demo_title_format': 0x9db,
    '_input_clock': 0x3cee,
    '_input_frame': 0x770c4,
    '_current_input': 0x5ac3c,
    '_input_history': 0x55bbc,
    '_transport': 0x13cde,
    '_network_id_byte': 0x18fe0c,
    '_ipx_local_address': 0x18fdc4,
    '_ipx_send_event': 0x18fde4,
    '_current_socket_low': 0x18fdce,
    '_current_socket_high': 0x18fdcf,
    '_ready_player_count': 0x13ce0,
    '_frame_state_12cd4': 0x12cd4,
    '_frame_state_12cd8': 0x12cd8,
    '_runtime_hook': 0x17494,
    '_descriptor_count': 0x16ab4,
    '_descriptor_modes': 0x16b08,
    '_open_streams': 0x2891e0,
    '_environment_vector': 0x173d8,
    '_environment_flags': 0x173dc,
    '_dos_environment_offset': 0x1449d,
    '_stack_bottom': 0x1447c,
    '_argument_workspace_size': 0x14484,
    '_argument_workspace_end': 0x14488,
    '_argc_value': 0x28924c,
    '_argv_pointer': 0x289250,
    '_float_formatter': 0x173d0,
    '_comspec': 0x1bfc,
    '_default_shell': 0x1c0c,
    '_cmd_name': 0x1c18,
    '_command_name': 0x1c1c,
    '_stderr_buffer_flags': 0x14295,
    '_static_streams': 0x14254,
    '_static_streams_end': 0x1445c,
    '_standard_streams_end': 0x142d6,
    '_allocation_error_message': 0x1ec0,
    '_default_file_mode': 0x1445d,
    '_recycled_streams': 0x2891dc,
    '_stream_hook': 0x144a5,
    '_psp_selector': 0x14478,
    '_previous_keyboard_vector': 0x7abb4,
    '_software_framebuffer': 0x13ff0,
    '_video_backend': 0x2891db,
    '_red_color_distance': 0x28643c,
    '_blue_color_distance': 0x286640,
    '_green_color_distance': 0x286844,
    '_occupied_palette_buckets': 0x289158,
    '_palette_bucket_head': 0x191360,
    '_palette_bucket_next': 0x196350,
    '_lookup_palette_end': 0x27c39d,
    '_palette_neighbor_offsets': 0x2863cc,
    '_visibility_queue': 0x195f50,
    '_art_size': 0x14021,
    '_art_file_count': 0x2863bc,
    '_art_header_version': 0x286b30,
    '_art_header_total_tiles': 0x286ba4,
    '_art_cache_bytes': 0x14025,
    '_art_tile_locks': 0x1ecda0,
    '_gotpic': 0x1ecda0,
    '_camera_z': 0x286ad8,
    '_view_ray_x': 0x286ac8,
    '_view_ray_y': 0x286af8,
    '_wallmost_sqrt_scratch': 0x286b20,
    '_wall_clip_top': 0x286acc,
    '_wall_clip_bottom': 0x286afc,
    '_yb1': 0x1c7160,
    '_yb2': 0x1c9160,
    '_view_x1': 0x1cf160,
    '_view_x2': 0x1d1160,
    '_xb1': 0x1c5160,
    '_xb2': 0x1c3160,
    '_translucent_tile_shift': 0x289146,
    '_mirror_row': 0x2863a0,
    '_mirror_scanline': 0x1dda60,
    '_mirror_z': 0x2863a4,
    '_mirror_sector': 0x289120,
    '_scan_wall_index': 0x1c2160,
    '_camera_x': 0x286ad0,
    '_camera_y': 0x286ad4,
    '_clipsectorlist': 0x195f50,
    '_clipsectnum': 0x28912e,
    '_windowx2': 0x286b98,
    '_windowy2': 0x286b90,
    '_base_plane_visibility': 0x286a94,
    '_ceiling_sqrt_scratch': 0x286b20,
    '_floor_sqrt_scratch': 0x286b20,
    '_tile_x_shift': 0x2891d5,
    '_tile_y_shift': 0x2891d6,
    '_lower_plane_edge': 0x19f360,
    '_upper_plane_edge': 0x19e6e0,
    '_upper_clip_edge': 0x1a3e60,
    '_lower_clip_edge': 0x1a7ce0,
    '_clear_stereo_buffer': 0x13ff0,
    '_display_page_bytes': 0x286b70,
    '_display_page_count': 0x287e80,
    '_permanent_sprite_tail': 0x140cb,
    '_permanent_sprite_head': 0x140cf,
    '_permanent_sprite_queue': 0x191750,
    '_permanent_sprite_phase': 0x14010,
    '_draw_single_page_sprite': 0x13ffd,
    '_color_neighbor_order': 0x140c3,
    '_view_stack_depth': 0x14190,
    '_saved_window_bottom': 0x190350,
    '_saved_window_right': 0x1902e0,
    '_saved_window_top': 0x1902c0,
    '_saved_window_left': 0x1902f0,
    '_saved_startumost': 0x1a31e0,
    '_saved_startdmost': 0x1a7060,
    '_saved_stereo_mode': 0x1902d0,
    '_restored_stereo_mode': 0x14004,
    '_saved_chainstat': 0x190340,
    '_saved_video_backend': 0x190320,
    '_saved_frameplace': 0x190330,
    '_saved_tile_width': 0x190300,
    '_saved_tile_height': 0x190310,
    '_current_brightness': 0x14018,
    '_brightness_video_mode': 0x286b24,
    '_brightness_table': 0x1c1d60,
    '_shutdown_art_handle': 0x1418b,
    '_art_tile_file': 0x1e3d20,
    '_loaded_art_number': 0x2863c4,
    '_art_file_position': 0x2863c8,
    '_art_tile_offsets': 0x1e6fe0,
    '_art_filename': 0x2863a8,
    '_debug_tile_loads': 0x1418f,
    '_tile_load_message': 0x1bd5,
    '_art_tile_cache': 0x1401d,
    '_vesa_pm_set_window': 0x13ff5,
    '_linear_page_addresses': 0x1ec5a0,
    '_skip_bank_switch': 0x286b54,
    '_bank_shift': 0x286b5c,
    '_linear_framebuffer_enabled': 0x286b60,
    '_draw_page_address': 0x286b74,
    '_use_software_framebuffer': 0x286b84,
    '_key_fifo_read': 0x7f87b,
    '_key_fifo_write': 0x7f878,
    '_key_state': 0x6793c,
    '_cd_registers': 0x173f56,
    '_cd_request_segment': 0x173f9e,
    '_cd_driver_offset': 0x173f94,
    '_cd_probe_result': 0x173fa6,
    '_cd_buffers_segment': 0x173fa8,
    '_cd_buffer_offset': 0x173f9c,
    '_cd_request_address': 0x173f88,
    '_cd_track_start': 0x173ee8,
    '_cd_lead_out': 0x173fb5,
    '_cd_header_segment': 0x173fa4,
    '_cd_header_offset': 0x173f98,
    '_cd_header_address': 0x173f50,
    '_cd_driver_name': 0x173fac,
    '_dos_segment': 0x173fa0,
    '_dos_buffer_offset': 0x173f90,
    '_float_sprite_list': 0x6f8bc,
    '_float_sprite_count': 0x2bec,
    '_float_sprite_overflow': 0x244,
    '_audio_timer_handle': 0x1714e8,
    '_audio_sample_rate': 0x1714f0,
    '_audio_driver_buffer_size': 0x171530,
    '_audio_driver_configuration': 0x1714ec,
    '_audio_timer_callback': 0x1715f4,
    '_audio_system_init_error': 0x789,
    '_audio_driver_init_error': 0x7b6,
    '_audio_callback_error': 0x7e3,
    '_audio_configuration_error': 0x814,
    '_sound_index_buffer': 0x171603,
    '_sound_index_storage': 0x16fe2c,
    '_sound_index_entries': 0x16fb1c,
    '_sound_index_memory_error': 0x72a,
    '_sound_archive_filename': 0x75a,
    '_sound_archive_open_error': 0x761,
    '_sound_archive_handle': 0x1714e0,
    '_graphics_stack_floor': 0x1447c,
    '_random_seed': 0x141a4,
    '_stdout_stream': 0x1426e,
    '_graphics_word_a7': 0x16ca7,
    '_graphics_word_a9': 0x16ca9,
    '_graphics_word_a1': 0x16ca1,
    '_graphics_word_a3': 0x16ca3,
    '_cursor_enabled': 0x16c74,
    '_cursor_visible': 0x16c76,
    '_bios_data_offset': 0x16d01,
    '_bios_data_selector': 0x16cf7,
    '_preserve_display': 0x199a4,
    '_hercules_crtc_registers': 0x16e64,
    '_mono_video_offset': 0x16d05,
    '_mono_video_selector': 0x16cf9,
    '_text_page_offset': 0x16c7a,
    '_text_page_count': 0x289208,
    '_video_memory_kib': 0x289210,
    '_active_text_page': 0x16c78,
    '_clipping_enabled': 0x16c70,
    '_saved_clip_left': 0x28921e,
    '_saved_clip_right': 0x289220,
    '_saved_clip_top': 0x289222,
    '_saved_clip_bottom': 0x289224,
    '_screen_width': 0x2891fc,
    '_screen_height': 0x2891fe,
    '_clip_left': 0x289216,
    '_clip_right': 0x289218,
    '_clip_top': 0x28921a,
    '_clip_bottom': 0x28921c,
    '_graphics_error': 0x16c66,
    '_graphics_word_a5': 0x16ca5,
    '_graphics_word_ab': 0x16cab,
    '_graphics_word_ad': 0x16cad,
    '_graphics_word_af': 0x16caf,
    '_drawing_color': 0x16c80,
    '_drawing_action': 0x16c9f,
    '_planar_action_bits': 0x16ec0,
    '_dos_extender_type': 0x1449a,
    '_extender_flags': 0x1449c,
    '_extender_subtype': 0x1449b,
    '_minimum_heap_growth': 0x17498,
    '_low_memory_selector': 0x1419a,
    '_saved_data_selector': 0x289238,
    '_mono_text_selector': 0x16cf9,
    '_color_text_selector': 0x16cfb,
    '_graphics_selector': 0x16cfd,
    '_video_rom_selector': 0x16cff,
    '_mono_text_offset': 0x16d05,
    '_color_text_offset': 0x16d09,
    '_graphics_offset': 0x16d0d,
    '_video_rom_offset': 0x16d11,
    '_cursor_restore_enabled': 0x16c74,
    '_legacy_rgb_palette': 0x17390,
    '_ega_component_bits': 0x1738c,
    '_bit_masks': 0x2024,
    '_token_resume': 0x14250,
    '_pending_console_char': 0x1448c,
    '_dos_major_version': 0x144a3,
    '_dos_error_table_window': 0x16a99,
    '_character_types': 0x1f20,
    '_small_text_character_widths': 0x12df4,
    '_status_character_width': 0x12df4,
    '_near_heap_head': 0x141b8,
    '_near_heap_rover': 0x141bc,
    '_memory_limit': 0x1446c,
    '_dos_reserve_bytes': 0x2892dc,
    '_dos_reserve_high_word': 0x2892de,
    '_debugger_present': 0x199a8,
    '_window_bottom': 0x286b90,
    '_window_top': 0x286b94,
    '_window_right': 0x286b98,
    '_window_left': 0x286b9c,
    '_weapon_bob_angle': 0x12d84,
    '_weapon_bob_scale': 0x12d88,
    '_weapon_bob_limit': 0x12d8c,
    '_weapon_idle': 0x12d90,
    '_common_init_value': 0x17498,
    '_float_support_message': 0x1e8c,
    '_fill_pattern': 0x16c84,
    '_default_fill_pattern': 0x16c8c,
    '_fill_pattern_enabled': 0x16c94,
    '_background_color': 0x16c7c,
    '_viewport_offset_x': 0x16c68,
    '_viewport_offset_y': 0x16c6a,
    '_text_wrap_enabled': 0x16c72,
    '_pattern_transparent': 0x16c95,
    '_pattern_origin_x': 0x16c97,
    '_pattern_origin_y': 0x16c99,
    '_line_pattern': 0x16c9b,
    '_line_pattern_phase': 0x16c9d,
    '_screen_stride': 0x289226,
    '_screen_offset': 0x289228,
    '_cursor_shape': 0x28923c,
    '_palette_size': 0x289204,
    '_video_mode': 0x28920a,
    '_video_device_table': 0x141c4,
    '_graphics_init_pending': 0x16c64,
    '_initial_text_rows': 0x28923a,
    '_initial_video_mode': 0x289246,
    '_adapter_class': 0x28920c,
    '_monitor_class': 0x28920e,
    '_adapter_class_table': 0x16d1c,
    '_monitor_class_table': 0x16d40,
    '_video_memory_table': 0x16d64,
    '_mouse_x_scale': 0x13a81,
    '_mouse_y_scale': 0x13a85,
    '_bitmap_layout_flags': 0x289234,
    '_mode_buffer_offset': 0x28922e,
    '_mode_buffer_selector': 0x289232,
    '_mode_buffer_stride': 0x28922c,
    '_current_buffer_stride': 0x289226,
    '_current_buffer_offset': 0x289228,
    '_pixel_address': 0x2891ec,
    '_bank_selector_callback': 0x2891e8,
    '_pixel_selector': 0x2891f0,
    '_pixel_color': 0x2891f2,
    '_pixel_bit_offset': 0x2891f6,
    '_pixel_mask': 0x2891f4,
    '_two_plane_color_map': 0x16ec4,
    '_current_buffer_selector': 0x289226,
    '_bitmap_bits_per_pixel': 0x289206,
    '_pixel_height': 0x2891fe,
    '_pixel_width': 0x2891fc,
    '_text_rows': 0x289202,
    '_text_columns': 0x289200,
    '_text_window_top': 0x289244,
    '_text_cursor_row': 0x2891f8,
    '_text_cursor_column': 0x2891fa,
    '_text_window_bottom': 0x289240,
    '_text_window_left': 0x289242,
    '_text_window_right': 0x28923e,
    '_difficulty_divisor': 0x7deec,
    '_status_left_tenths': 0x2263,
    '_invalid_difficulty_message': 0xe8,
    '_status_right_tenths': 0x6319c,
    '_world_bounds': 0x16cd5,
    '_world_first_min': 0x16ce7,
    '_world_first_max': 0x16cef,
    '_world_second_min': 0x16ceb,
    '_first_pixel_scale': 0x2892e4,
    '_pixel_first_min': 0x289216,
    '_pixel_first_max': 0x289218,
    '_first_extent': 0x2891fc,
    '_first_extent_scale': 0x2892ec,
    '_reverse_second_axis': 0x16ce5,
    '_world_second_max': 0x16cf3,
    '_second_pixel_scale': 0x2892e0,
    '_pixel_second_min': 0x28921a,
    '_pixel_second_max': 0x28921c,
    '_second_extent': 0x2891fe,
    '_second_extent_scale': 0x2892e8,
    '_errno_value': 0x289258,
    '_dos_error_value': 0x289254,
    '_graphics_active': 0x16c65,
    '_text_attribute': 0x16c71,
    '_viewport_origin_x': 0x16c6c,
    '_viewport_origin_y': 0x16c6e,
    '_graphics_device': 0x289212,
    '_two_plane_device': 0x17008,
    '_adapter_mode_masks': 0x1995c,
    '_invalid_flatten_sector': 0x1710,
    '_invalid_crush_sprite': 0x1732,
    '_sprite_actor_index': 0x709dc,
    '_actor_health': 0x7cefa,
    '_actor_kind': 0x7f0a0,
    '_movement_actor_sprite': 0x7dab8,
    '_movement_sprite_x': 0x2040a0,
    '_movement_sprite_y': 0x2040a4,
    '_movement_sprite_angle': 0x2040bc,
    '_advance_clock': 0x229b,
    '_activation_sprite_index': 0x7497c,
    '_activation_sprite_count': 0x7def0,
    '_activation_counter': 0x7496c,
    '_effect_count': 0x225d,
    '_terminal_x': 0x3e74,
    '_terminal_y': 0x3e78,
    '_terminal_destination_x': 0x3e7c,
    '_terminal_destination_y': 0x3e80,
    '_terminal_destination_level': 0x3e84,
    '_terminal_destination_entry': 0x3e88,
    '_destination_level': 0x2040,
    '_destination_entry': 0x7deee,
    '_terminal_special_case': 0x6793d,
    '_terminal_projectiles': 0x7053c,
    '_projectile_count': 0x2bee,
    '_moving_sprite_count': 0x2be8,
    '_destination_x': 0x7a998,
    '_destination_y': 0x7a99c,
    '_terminal_special_counter': 0x77118,
    '_terminal_table_error': 0x268,
    '_board7_reset': 0x12844,
    '_board5_actor_steps': 0x851b0,
    '_board5_actors': 0x12818,
    '_board5_script_sprites': 0x7494e,
    '_board5_target_x': 0x12820,
    '_board5_target_y': 0x12824,
    '_map_version': 0x286b28,
    '_show_2d_walls': 0x1ec920,
    '_board7_present': 0x12846,
    '_board7_previous_present': 0x12848,
    '_board7_trigger_sectors': 0x1284a,
    '_board7_sector_head': 0x288a4a,
    '_board7_sector_lotag': 0x27c3c2,
    '_board7_key_wall_tile': 0x236fd0,
    '_board7_sprite_tile': 0x2040ae,
    '_board7_key_consumed': 0x12840,
    '_board7_level_flags': 0x203c,
    '_effect_speed': 0x225f,
    '_effect_sprite_xvel': 0x2040c0,
    '_effect_sprite_yvel': 0x2040c2,
    '_effect_sprite_zvel': 0x2040c4,
    '_sequence_actor_sprite': 0x7dab8,
    '_sequence_actor_sector': 0x7d2e4,
    '_sequence_tile_height': 0x1f4020,
    '_sequence_actor_x': 0x799e8,
    '_sequence_actor_y': 0x7a1bc,
    '_sequence_actor_z_offset': 0x79214,
    '_sequence_actor_state': 0x7e2ed,
    '_sequence_actor_flag': 0x7f67f,
    '_sequence_actor_first': 0x7e4e2,
    '_sequence_actor_frame': 0x7e6d7,
    '_sequence_sprite_tile': 0x2040ae,
    '_sequence_sprite_yrepeat': 0x2040b5,
    '_proximity_player_x': 0x5ad9c,
    '_proximity_player_y': 0x5ad5c,
    '_proximity_player_z': 0x5ad1c,
    '_proximity_player_sector': 0x5acfc,
    '_proximity_sprite_x': 0x2040a0,
    '_proximity_sprite_y': 0x2040a4,
    '_proximity_sprite_z': 0x2040a8,
    '_proximity_sprite_tile': 0x2040ae,
    '_proximity_sprite_sector': 0x2040b8,
    '_hit_sprite_lotag': 0x2040c6,
    '_hit_actor_index': 0x709dc,
    '_hit_actor_health': 0x7cefa,
    '_hit_sprite_sector': 0x2040b8,
    '_hit_sprite_cstat': 0x2040ac,
    '_hit_sprite_owner': 0x2040be,
    '_player_sprite': 0x62f2c,
    '_held_item': 0x2bf6,
    '_hit_sprite_tile': 0x2040ae,
    '_hit_sprite_z': 0x2040a8,
    '_sector_floor_z': 0x27c3a8,
    '_hit_sprite_xrepeat': 0x2040b2,
    '_held_sprite_type': 0x2bf6,
    '_holding_sprite': 0x2bfa,
    '_board_path_data': 0x4d1c,
    '_board_path_sectors': 0x82c90,
    '_atexit_hook': 0x141ac,
    '_int23_exit_hook': 0x141b0,
    '_fpe_exit_hook': 0x141b4,
    '_exit_callback_count': 0x17aba0,
    '_exit_callbacks': 0x17ab20,
    '_cd_drive_letter': 0x173fa2,
    '_player_x': 0x5ad9c,
    '_player_y': 0x5ad5c,
    '_null_crusher_sound': 0x14e9,
    '_text_seek_error': 0xbc5,
    '_text_read_error': 0xbe6,
    '_text_archive_index': 0x12d9c,
    '_text_archive_records': 0x12da0,
    '_text_archive_record': 0x12da4,
    '_text_archive_message': 0x12da8,
    '_active_text_message': 0x7711c,
    '_text_message_timeout': 0x77108,
    '_mouse_records': 0x13a42,
    '_mouse_entries': 0x1745bc,
    '_mouse_button_records': 0x13a03,
    '_mouse_button_entries': 0x1745b0,
    '_mouse_sensitivity_selection': 0x1745c8,
    '_mouse_sensitivity_title': 0x120e,
    '_mouse_sensitivity_multiplier': 0x1220,
    '_mouse_sensitivity_divisor': 0x1224,
    '_key_records': 0x13656,
    '_key_entries': 0x1741f4,
    '_key_scan_names': 0x13154,
    '_key_blank_name': 0xd84,
    '_key_menu_row_format': 0x1098,
    '_key_menu_title': 0x10a0,
    '_key_menu_prompt': 0x10b0,
    '_key_menu_rejected': 0x10bc,
    '_key_action_labels': 0x13558,
    '_key_bindings_one_based': 0x1363c,
    '_key_forward': 0x1363d,
    '_key_entries_one_based': 0x1741f0,
    '_key_menu_selection': 0x17425c,
    '_key_menu_rows': 0x174268,
    '_key_action_records': 0x1388d,
    '_key_action_entries': 0x1741e8,
    '_key_confirm_records': 0x13863,
    '_key_confirm_entries': 0x1741e0,
    '_main_menu_records': 0x12e18,
    '_main_entries': 0x173ff0,
    '_pause_records': 0x12ec0,
    '_pause_entries': 0x174028,
    '_options_records': 0x12f68,
    '_options_entries': 0x174010,
    '_confirm_records': 0x13010,
    '_confirm_entries': 0x173fe8,
    '_confirm_selection': 0x1740e4,
    '_confirm_menu_title': 0xd65,
    '_key_confirm_selection': 0x174258,
    '_key_confirm_title': 0x1086,
    '_mouse_settings_selection': 0x1745ac,
    '_mouse_settings_title': 0x125b,
    '_key_settings_selection': 0x174260,
    '_key_settings_title': 0x10c7,
    '_controller_records': 0x130e4,
    '_controller_entries': 0x1740d0,
    '_default_key_bindings': 0x13624,
    '_active_key_bindings': 0x1363d,
    '_configuration_true': 0x955,
    '_configuration_true_output': 0x959,
    '_configuration_false_output': 0x95d,
    '_text_archive_filename': 0xbbc,
    '_audio_config_filename': 0x6d4,
    '_audio_config_open_error': 0x6df,
    '_digital_section': 0x6fa,
    '_device_id_key': 0x702,
    '_device_port_key': 0x70b,
    '_device_dma_key': 0x716,
    '_device_irq_key': 0x720,
    '_audio_device_id': 0x1715f0,
    '_audio_device_port': 0x171548,
    '_audio_device_dma': 0x171550,
    '_audio_device_irq': 0x17154c,
    '_hex_digit_set': 0x12cf0,
    '_hex_place_values': 0x12cf4,
    '_saved_text_mode': 0x12d70,
    '_saved_text_width': 0x12d74,
    '_saved_text_height': 0x12d78,
    '_video_dos_buffer_size': 0x13fe8,
    '_video_dos_allocation': 0x13fec,
    '_vesa_probe_attempted': 0x13ff4,
    '_video_settings_filename': 0x9c1,
    '_text_mode': 0x12d70,
    '_text_width': 0x12d74,
    '_text_height': 0x12d78,
    '_video_settings_record': 0x173d38,
    '_video_setup_pending': 0x173d48,
    '_save_preview_pixels': 0x203c98,
    '_save_preview_lock': 0x1f9c9e,
    '_save_preview_filename': 0xd19,
    '_save_preview_format': 0xd21,
    '_game_configuration_filename': 0xce4,
    '_mouse_button_bindings': 0x139f4,
    '_pending_mouse_action': 0x13a89,
    '_mouse_action_keys': 0x1363d,
    '_mouse_key_state': 0x6793c,
    '_previous_mouse_action': 0x13a8d,
    '_mouse_input_actions': 0x7defc,
    '_stored_audio_settings': 0x13b4d,
    '_mouse_scales': 0x13a81,
    '_movement_limits': 0x13b9f,
    '_cd_device_handle': 0x173f96,
    '_first_cd_track': 0x173f8e,
    '_last_cd_track': 0x173f9a,
    '_selected_cd_track': 0x12d7c,
    '_active_cd_track': 0x12d80,
    '_cd_playback_pending': 0x173faa,
    '_cd_paused_message': 0xb80,
    '_serial_uses_uart': 0x13cdd,
    '_cd_resumed_message': 0xb8a,
    '_cd_status_buffer': 0x67e3c,
    '_cd_stopped_message': 0xb9b,
    '_cd_reset_message': 0xbac,
    '_text_archive_handle': 0x12d98,
    '_text_archive_open': 0x12d94,
    '_timer_callback_handle': 0x1714dc,
    '_timer_error': 0x171600,
    '_timer_init_error': 0x61c,
    '_timer_callback_error': 0x647,
    '_remove_timer_error': 0x674,
    '_shutdown_timer_error': 0x6a1,
    '_crush_view_kick': 0x13bb4,
    '_player_horizon': 0x62f8c,
    '_intro_visibility': 0x286ba8,
    '_player_sector': 0x5acfc,
    '_player_z': 0x5ad1c,
    '_player_angle': 0x6308c,
    '_actor_active': 0x7ecb6,
    '_actor_level': 0x7eac1,
    '_actor_sprite': 0x7dab8,
    '_held_sprite': 0x2bf8,
    '_discard_error': 0x2ac,
    '_save_error': 0x288,
    '_saved_actor_positions': 0x772c4,
    '_saved_actor_lotag': 0x7d6ce,
    '_restore_count': 0x3e04,
    '_restore_addresses': 0x1a234,
    '_restore_values': 0x1b234,
    '_crusher_bad_sector': 0x145c,
    '_headspritesect': 0x28891e,
    '_nextspritesect': 0x1f9ca0,
    '_crusher_floor': 0x27c3a8,
    '_crusher_ceiling': 0x27c3a4,
    '_crusher_sprite_tile': 0x2040ae,
    '_crusher_sprite_repeat': 0x2040b5,
    '_crushed_sprite_bad_sector': 0x14a3,
    '_crushed_sprite_null_record': 0x14c8,
    '_crusher_null_record': 0x1481,
    '_crush_view_before': 0x17ab14,
    '_crush_view_after': 0x17ab18,
})
FUNCTION_ADDRESSES.update({
    'memmove_': 0x62d49,
    'build_palette_fade_tables_': 0x36305,
    'update_palette_fade_': 0x366f2,
    'scale_fade_palette_': 0x365b6,
    'palette_fade_shared_return_': 0x36587,
    'palette_fade_changed_address_': 0x367ab,
    'wait_vertical_retrace_': 0x40b82,
    'write_vga_palette_': 0x40b99,
    'updatesector_': 0x542c4,
    'restore_board_actor_sprites_': 0x26749,
    'changespritesect_': 0x50bc3,
    'resolve_teleport_destination_': 0x2e7f7,
    'run_recorded_session_': 0x2e350,
    'prepare_loaded_board_': 0x27a8c,
    'initialize_board_entry_': 0x2e14f,
    'board_entry_finish_': 0x2e347,
    'board_entry_default_palette_': 0x2e31e,
    'board_player_palette_finish_': 0x2e330,
    'makepalookup_': 0x593b4,
    'reset_playback_timer_': 0x4c0b0,
    'snapshot_playback_input_': 0x2d1bd,
    'process_playback_frame_': 0x2d23e,
    'render_playback_frame_': 0x2c48d,
    'shutdown_engine_': 0x4b390,
    'find_spawn_position_': 0x2e5fc,
    'spawn_try_sector_': 0x2e613,
    'spawn_test_retry_budget_': 0x2e7e4,
    'pushmove_': 0x53edd,
    'shutdown_game_': 0x3b34d,
    'run_menu_loop_': 0x3963b,
    'truncate_magnitude_': 0x73f0c,
    'truncate_for_i32_': 0x73f00,
    'truncate_for_u32_': 0x73f00,
    'truncate_for_i16_': 0x73f00,
    'truncate_for_u16_': 0x73f00,
    'truncate_for_i8_': 0x73f00,
    'truncate_for_u8_': 0x73f00,
    'update_menu_selection_': 0x39235,
    'read_save_slot_preview_': 0x39cfa,
    'setviewtotile_': 0x5d2f4,
    'setviewback_': 0x5d46d,
    'access_': 0x63130,
    'edit_save_slot_name_': 0x39890,
    'render_save_slot_preview_': 0x39a02,
    'write_save_slot_preview_': 0x39c8b,
    'finish_save_game_menu_': 0x39482,
    'reset_key_bindings_': 0x3a42c,
    'confirm_reset_key_bindings_': 0x3a443,
    'run_mouse_sensitivity_menu_': 0x3aaa9,
    'run_mouse_button_menu_': 0x3abbc,
    'run_key_binding_menu_': 0x3a492,
    'memset_': 0x61350,
    'env_restore_registers_': 0x6e784,
    'format_string_': 0x601f3,
    'validate_key_binding_': 0x3a3b0,
    'run_help_page_menu_': 0x3a753,
    'report_game_error_': 0x26a03,
    'load_sound_archive_': 0x34956,
    'initialize_sound_slots_': 0x34b13,
    'reset_mouse_driver_': 0x5440e,
    'initialize_video_console_': 0x36b6a,
    'load_video_settings_': 0x36952,
    'save_video_settings_': 0x36a16,
    'print_video_settings_help_': 0x3707f,
    'restore_text_video_mode_': 0x36ac2,
    'install_keyboard_interrupt_': 0x2f1fe,
    'initialize_game_timer_': 0x34811,
    'initialize_network_': 0x41542,
    'initialize_game_audio_': 0x34a5a,
    'load_art_files_': 0x4bd46,
    'initcache_': 0x40c49,
    'allocate_permanent_tile_': 0x4bc8e,
    'open_text_archive_': 0x3803e,
    'initialize_ripple_tables_': 0x2eaa2,
    'play_sound_': 0x34f79,
    'apply_sprite_blast_': 0x10d3a,
    'adjust_blast_player_status_': 0x1092e,
    'blast_random_': 0x602d0,
    'blast_distance_root_': 0x4ca38,
    'truncate_st0_': 0x60304,
    'start_blast_sequence_': 0x11fdd,
    'move_sprite_': 0x339b9,
    'deletesprite_': 0x50a09,
    'save_build_map_': 0x4a11a,
    'find_crush_sector_': 0x402d7,
    'classify_sector_hit_': 0x3fccb,
    'activate_sector_': 0x28710,
    'trigger_tagged_crushers_': 0x405b8,
    'is_first_player_sprite_': 0x4037a,
    'crush_sprite_': 0x40a48,
    'activate_crush_sector_': 0x40849,
    'update_level_effects_': 0x40662,
    'get_animation_goal_': 0x2efa1,
    'restore_crusher_registers_': 0x40261,
    'check_crushed_player_': 0x4038a,
    'check_crushed_sprites_': 0x40434,
    'play_crusher_sound_': 0x404d6,
    'request_sample_stop_': 0x62334,
    'print_video_text_': 0x36adf,
    'initialize_color_lookup_': 0x59582,
    'setpalookupaddress_': 0x740e0,
    'fixtransluscence_': 0x743a0,
    'draw_graphics_span_': 0x735c4,
    'clip_graphics_line_': 0x7376b,
    'dispatch_device_line_': 0x71d0f,
    'begin_graphics_device_': 0x70052,
    'end_graphics_device_': 0x7005b,
    'set_cursor_enabled_': 0x6f5bd,
    'dpmi_real_mode_interrupt_': 0x4380a,
    'video_vformat_': 0x62eca,
    'output_video_string_': 0x6eaae,
    'print_video_text_at_': 0x36b0e,
    'prompt_video_mode_': 0x36d0a,
    'prompt_video_settings_': 0x36f73,
    'set_text_position_': 0x6ebf2,
    'get_text_position_': 0x6ebc0,
    'set_video_mode_': 0x6ec8a,
    'return_after_font_setup_': 0x712b2,  # configure_ega_text_font's shared ret
    'resolve_video_mode_': 0x6ed74,
    'detect_display_adapters_': 0x7139e,
    'detect_legacy_display_adapters_': 0x71471,
    'detect_mono_adapter_': 0x71557,
    'detect_color_adapter_': 0x715d8,
    'probe_video_adapter_': 0x72ed2,
    'probe_crtc_cursor_register_': 0x715ed,
    'initialize_graphics_device_': 0x7003d,
    'shutdown_graphics_device_': 0x70049,
    'set_text_rows_': 0x70e37,
    'configure_text_rows_in_graphics_mode_': 0x71061,
    'configure_text_rows_in_text_mode_': 0x70f1d,
    'initialize_text_pages_': 0x6fbfa,
    'reset_video_state_': 0x6ef09,
    'finish_text_display_reset_': 0x6ed6e,  # shared register restore in set_video_mode
    'reset_text_display_': 0x6f0bb,
    'reset_graphics_aspect_settings_': 0x6eea9,
    'set_graphics_clipping_': 0x71689,
    'read_palette_entry_': 0x718ac,
    'write_palette_entry_': 0x717d7,
    'upload_palette_entries_': 0x7174e,
    'upload_bios_palette_': 0x72cbd,
    'allocate_graphics_dos_buffer_': 0x72d63,
    'free_graphics_dos_buffer_': 0x72df4,
    'call_graphics_real_mode_interrupt_': 0x72e20,
    'set_background_color_': 0x6f1bf,
    'find_legacy_palette_index_': 0x718ef,
    'replace_palette_entry_': 0x716fc,
    'set_text_color_': 0x6f25d,
    'set_text_window_': 0x6f2e7,
    'clear_screen_': 0x6f42c,
    'clear_graphics_display_': 0x6f363,
    'clear_graphics_region_': 0x6f4ac,
    'clear_text_region_': 0x6f50a,
    'startcom_': 0x4204f,
    'disable_interrupts_': 0x603dc,
    'enable_interrupts_': 0x60409,
    'uninstallbicomhandlers_': 0x43243,
    'send_ready_packet_': 0x424ec,
    'send_packet_': 0x424ec,
    'receive_packets_': 0x32407,
    'simulate_real_mode_interrupt_': 0x375e9,
    'segread_': 0x63072,
    'dispatch_interrupt_registers_': 0x67096,
    'service_driver_': 0x66b75,
    'lastwall_': 0x528cf,
    'finish_neighbor_height_': 0x4c1ab,  # shared 12-byte search frame cleanup
    'far_memmove_': 0x630ce,
    'detect_cd_drives_': 0x376bb,
    'prepare_cd_request_buffers_': 0x3771a,
    'allocate_dos_memory_': 0x37659,
    'send_cd_driver_request_': 0x377a7,
    'random_value_': 0x602d0,
    'spawn_sprite_at_position_': 0x11073,
    'set_sprite_motion_': 0x339b9,
    'add_listed_sprite_': 0x134c2,
    'apply_terminal_special_case_': 0x38800,
    'audio_driver_shutdown_': 0x61ca3,
    'audio_system_shutdown_': 0x617d9,
    'audio_system_init_': 0x6177d,
    'audio_driver_init_': 0x61840,
    'load_audio_driver_image_': 0x65f10,
    'allocate_driver_workspace_': 0x661e2,
    'query_driver_interface_': 0x662f6,
    'allocate_audio_buffer_': 0x61e80,
    'driver_command_11_': 0x66b45,
    'driver_configure_secondary_': 0x66777,
    'driver_secondary_command_3_': 0x667fb,
    'driver_secondary_command_2_': 0x667d5,
    'driver_secondary_command_4_': 0x667ac,
    'read_audio_configuration_': 0x3488d,
    'initrandnext_': 0x602ca,
    'draw_intro_screen_': 0x38808,
    'menu_restore_without_ebp_': 0x39482,
    'drawrooms_': 0x44796,
    'drawmasks_': 0x4cc8a,
    'restore_saved_registers_': 0x39481,
    'dpmi_real_mode_interrupt_': 0x4380a,
    'shared_graphics_epilogue_': 0x4abbf,
    'finish_palette_lookup_': 0x4bd3e,
    'finish_color_search_': 0x47f04,
    'finish_vertical_timing_': 0x4918a,
    'finish_save_map_': 0x4918a,
    'kopen4load_': 0x41281,
    'kread_': 0x4137d,
    'kclose_': 0x41503,
    'initspritelists_': 0x507e3,
    'insertsprite_': 0x508b8,
    'finish_load_map_': 0x4918a,
    'finish_screen_text_': 0x4918a,
    'finish_ega_text_': 0x4918a,
    'split_ega_row_start_': 0x55f7e,
    'split_ega_row_check_': 0x560a3,
    'finish_palookup_': 0x4918a,
    'done_palookup_': 0x5957a,
    'engine_malloc_': 0x4478c,
    'getclosestcol_': 0x5976c,
    'finish_restored_view_': 0x4abbe,
    'finish_tile_view_': 0x54374,
    'setvlinebpl_': 0x74090,
    'finish_combined_height_': 0x548c8,
    'finish_ega_brightness_': 0x50344,
    'finish_rgb_brightness_': 0x50344,
    'finish_rintersect_': 0x51fbb,
    'finish_slope_height_': 0x4c944,
    'finish_startup_arguments_': 0x374b1,
    'print_command_line_help_': 0x374b8,
    'strtok_': 0x62fdd,
    'strstr_': 0x62f1b,
    'finish_lintersect_': 0x51fbb,
    'finish_video_shutdown_': 0x4abbe,
    'shutdown_video_backend_': 0x4476c,
    'shutdown_close_art_': 0x41503,
    'finish_tile_load_': 0x4abbe,
    'open_tile_art_': 0x41281,
    'seek_tile_art_': 0x41451,
    'read_tile_art_': 0x4137d,
    'finish_planar_pixel_': 0x4abbf,
    'restore_square_tile_rotation_': 0x4d6c2,
    'finish_rotation_': 0x4c28a,
    'finish_keepaway_': 0x47f04,  # shared cleanup for the clip-line stack frame
    'loadtile_': 0x4bb0d,
    'menu_return_': 0x39234,
    'draw_animated_intro_': 0x388d7,
    'status_banner_cleanup_': 0x385ec,
    'initialize_graphics_once_': 0x6fd95,
    'initialize_graphics_memory_windows_': 0x71b8c,
    'read_graphics_mode_state_': 0x6fc6d,
    'set_and_query_bios_mode_': 0x72180,
    'bios_mode_supported_': 0x72136,
    'end_planar_drawing_': 0x70508,
    'select_graphics_bank_': 0x70d16,
    'apply_graphics_mode_state_': 0x6fe1e,
    'program_hercules_graphics_': 0x701e9,
    'hide_graphics_cursor_': 0x6febd,
    'set_bios_cursor_visible_': 0x6ff26,
    'toggle_graphics_cursor_line_': 0x6ff4b,
    'draw_clipped_solid_line_': 0x71c23,
    'graphics_point_outcode_': 0x736bf,
    'clamp_point_edge_': 0x738c8,
    'return_axis_clip_result_': 0x738c2,  # shared outcode intersection and register restore
    'restore_cursor_if_enabled_': 0x7002e,
    'show_graphics_cursor_': 0x6fe8f,
    'set_drawing_action_': 0x71950,
    'recalculate_coordinate_scales_': 0x7351c,
    'get_drawing_action_': 0x71924,
    'get_fill_pattern_': 0x719a1,
    'set_fill_pattern_': 0x719cb,
    'get_drawing_color_': 0x71a3f,
    'set_drawing_color_': 0x71a46,
    'fill_graphics_rectangle_': 0x71a82,
    'write_text_window_': 0x6e912,
    'scroll_text_window_': 0x6f5cf,
    'get_text_color_': 0x6f22c,
    'map_first_coordinate_': 0x7326a,
    'map_second_coordinate_': 0x73295,
    'map_coordinate_pair_': 0x7347b,
    '__FDFS': 0x73cca,
    '__FSS': 0x73d16,
    '__FSA': 0x73d20,
    '__FSFD': 0x73f84,
    '__FSM': 0x73dcd,
    '__FSD': 0x73e44,
    '__FSI4': 0x73ec4,
    '__I4FS': 0x73f73,
    'u32_to_float_': 0x73f48,
    'get_vesa_mode_info_': 0x43a50,
    'set_absolute_graphics_pair_': 0x7162c,
    'set_nonzero_graphics_pair_': 0x7164b,
    'set_graphics_word_a5_': 0x7166d,
    'set_graphics_word_ab_': 0x71674,
    'set_graphics_pair_ad_': 0x7167b,
    '__CHP': 0x60304,
    'get_errno_address_': 0x67a09,
    'get_dos_error_address_': 0x67a0f,
    'set_errno_': 0x6468e,
    'write_stream_format_': 0x6317c,
    'normalize_separator_': 0x6792c,
    'copy_path_part_': 0x6785e,
    'graphics_available_': 0x6ffe6,
    'replace_drawing_color_': 0x71a64,
    'bitmap_rectangle_size_': 0x71b0b,
    'bitmap_row_bytes_': 0x71b4a,
    'adjust_status_value_': 0x1092e,
    'absolute_long_': 0x602c3,
    'absolute_int_': 0x6032c,
    'route_actor_toward_target_': 0x1d3ee,
    'move_actor_return_': 0x197f0,
    'move_actor_': 0x196b2,
    'setsprite_': 0x506f6,
    'activate_sprite_at_player_': 0x129fc,
    'cansee_': 0x50d33,
    'lintersect_': 0x5261d,
    'getzsofslope_': 0x5e07a,
    'visibility_wall_start_': 0x50da9,
    'visibility_wall_test_': 0x50ed1,
    'visibility_blocked_': 0x50f0b,
    'visibility_cleanup_': 0x50f0d,
    'finish_visibility_': 0x4cc84,
    'finish_wall_push_': 0x4cc84,
    'preparemirror_finish_': 0x5d916,
    'configure_fpu_': 0x6ad8e,
    'completemirror_restore_': 0x4abbb,
    'check_planar_bounds_': 0x5da3a,
    'check_linear_bounds_': 0x5dcc3,
    'check_linear_row_': 0x5ddb6,
    'reverse_linear_row_': 0x5dd30,
    'preparemirror_restore_': 0x52c82,
    'ceiling_sprite_restore_registers_': 0x50347,
    'set_translucent_column_shift_': 0x74310,
    'select_display_page_': 0x4417c,
    'clearallviews_fill_dwords_': 0x5d114,
    'clearallviews_service_timer_': 0x5d23d,
    'prepwall_more_columns_': 0x4764a,
    'prepwall_last_pair_': 0x47733,
    'prepwall_last_column_': 0x477c0,
    'wallfront_return_': 0x4551f,
    'transmaskvline_': 0x4aa28,
    'transmaskvline_pair_': 0x4abc5,
    'translucent_wall_cleanup_': 0x49f26,
    'tile_copy_done_': 0x4cc81,
    'tile_copy_column_test_': 0x4cc74,
    'tile_copy_row_test_': 0x4cc53,
    'tile_copy_first_column_': 0x4cbe0,
    'pushmove_closest_wall_': 0x53f8d,
    'pushmove_test_wall_': 0x5427c,
    'clipinsidebox_': 0x4c0c7,
    'getceilzofslope_': 0x5de70,
    'getflorzofslope_': 0x5df75,
    'krand_': 0x562e5,
    'play_positioned_sound_': 0x34f76,
    'draw_status_message_': 0x3462d,
    'start_negative_delta_effect_': 0x40b14,
    'start_sequence_': 0x11fdd,
    'update_projectiles_': 0x13237,
    'dispatch_hit_event_': 0x2b369,
    'apply_projectile_hit_': 0x13115,
    'flatten_sprite_': 0x40991,
    'fread_': 0x60638,
    'fwrite_': 0x60944,
    'initialize_demo_menu_': 0x3a6be,
    'initialize_difficulty_menu_': 0x3ae44,
    'initialize_audio_menu_': 0x3af04,
    'initialize_control_limits_menu_': 0x3b034,
    'initialize_help_menus_': 0x3a6e8,
    'initialize_mouse_menus_': 0x3a924,
    'initialize_key_menu_': 0x3a345,
    'load_game_configuration_': 0x3818c,
    'find_configuration_key_': 0x35907,
    'replace_configuration_value_': 0x35b8b,
    'copy_configuration_value_': 0x35a66,
    'parse_configuration_integer_': 0x359b8,
    'open_configuration_': 0x35732,
    'find_configuration_section_': 0x35882,
    'write_configuration_value_': 0x35c88,
    'close_configuration_': 0x35824,
    'read_configuration_integer_': 0x35d9c,
    'report_audio_config_error_': 0x26a03,
    'toupper_': 0x62dce,
    'parse_format_flags_': 0x6396f,
    'format_unsigned_': 0x674b6,
    'ultoa_': 0x62ce4,
    'ltoa_': 0x62d2e,
    'format_engine_': 0x635bb,
    'parse_format_specifier_': 0x6383c,
    'convert_format_value_': 0x63b54,
    'call_float_formatter_': 0x63b4d,
    'uppercase_output_': 0x63f9d,
    'format_integer_': 0x674ff,
    'format_signed_integer_': 0x674ff,
    'format_padded_hex_': 0x63a11,
    'format_fixed_point_': 0x63a72,
    'bounded_far_strlen_': 0x639ca,
    'bounded_far_wcslen_': 0x639ee,
    'fatal_runtime_error_': 0x6e69c,
    'unlink_near_heap_': 0x65151,
    'heap_release_restore_': 0x65480,
    'release_empty_heaps_': 0x65190,
    'link_and_initialize_heap_': 0x652f1,
    'resize_dpmi_heap_': 0x651ee,
    'resize_heap_target_': 0x65207,
    'resize_heap_result_': 0x6527c,
    'resize_use_whole_block_': 0x652d3,
    'resize_return_block_': 0x652da,
    'resize_next_heap_': 0x652de,
    'resize_check_heap_': 0x652e1,
    'resize_return_zero_': 0x652e9,
    'resize_restore_': 0x652eb,
    'allocate_dpmi_heap_': 0x653b3,
    'allocate_dpmi_result_': 0x653e4,
    'allocate_dos_fallback_': 0x65401,
    'allocate_dos_heap_': 0x65416,
    'allocate_heap_failure_': 0x6547b,
    'discard_heap_request_': 0x6547d,
    'expand_separate_heap_': 0x65486,
    'expand_return_zero_': 0x65495,
    'expand_check_limit_': 0x65499,
    'expand_allocate_dos_': 0x654cd,
    'expand_check_block_': 0x654e8,
    'heap_release_restore_': 0x65480,
    'free_space_at_break_': 0x65365,
    'notify_debugger_': 0x6e8d2,
    'detect_terminal_': 0x64901,
    'fputc_': 0x64c57,
    'fill_buffer_': 0x64a80,
    'refill_and_get_character_': 0x64a51,
    'allocate_stream_buffer_': 0x64932,
    'read_descriptor_raw_': 0x649a9,
    'read_console_character_': 0x6aea1,
    'flush_matching_streams_': 0x62e88,
    'build_delimiter_map_': 0x67058,
    'copy_dta_to_caller_': 0x675ae,
    'copy_caller_to_dta_': 0x675d1,
    'dos_search_status_': 0x6e78e,
    'tell_': 0x6adb5,
    '_exit_': 0x6036b,
    'startup_exit_': 0x60197,
    'isatty_': 0x656f3,
    '__doclose_': 0x608bb,
    'close_stream_descriptor_': 0x64c20,
    'ftell_': 0x64bf0,
    '__MkTmpFile_': 0x60852,
    'getpid_': 0x64b2b,
    'hex_digit_': 0x60846,
    'remove_': 0x64c52,
    '__shutdown_stream_': 0x60831,
    'free_stream_': 0x6476c,
    '_fsopen_': 0x60587,
    'allocate_stream_': 0x646c4,
    '__doopen_': 0x604bf,
    '__open_flags_': 0x6040b,
    'fseek_': 0x64805,
    'close_file_': 0x605ac,
    'tolower_': 0x6467b,
    'close_stream_': 0x608bb,
    'close_descriptor_': 0x64c20,
    'set_io_mode_': 0x657d8,
    'remove_file_dos_': 0x6af3a,
    'set_dos_errno_': 0x6571d,
    'set_runtime_error_': 0x646b1,
    'flush_stream_': 0x64b31,
    'seek_within_buffer_': 0x647c3,
    'write_stream_descriptor_': 0x6aebe,
    'get_io_mode_': 0x65783,
    'access_': 0x63130,
    'access_translate_': 0x6314d,
    'dosret0_': 0x65711,
    '__set_binary_': 0x61551,
    'set_binary_device_get_': 0x61571,
    'set_binary_dos_error_': 0x61584,
    'set_binary_device_set_': 0x61591,
    'set_binary_success_': 0x615ac,
    'set_binary_restore_': 0x615ae,
    'runtime_init_': 0x6439c,
    'runtime_fini_': 0x64521,
    'write_console_and_exit_': 0x60199,
    'close_streams_from_index_': 0x6ae4f,
    'free_recycled_streams_': 0x647a5,
    'strlen_': 0x60381,
    'apply_video_mode_': 0x37136,
    'parse_hex_digits_': 0x36211,
    'parse_hexadecimal_': 0x361da,
    'atoi_': 0x62c68,
    'free_': 0x6170a,
    'round_heap_request_': 0x65679,
    'write_': 0x62a97,
    'strupr_': 0x62efc,
    'restore_engine_video_mode_': 0x4b04e,
    'flushall_': 0x62e83,
    'sprintf_': 0x601f3,
    'trim_and_uppercase_': 0x383a0,
    'draw_menu_frame_': 0x39511,
    'system_': 0x6025a,
    'getenv_': 0x63fb5,
    'dos_find_first_': 0x67572,
    'select_shell_switch_': 0x6400f,
    'spawnlp_': 0x64385,
    'spawn_with_path_search_': 0x67a33,
    'build_command_tail_': 0x6773b,
    'dos_exec_': 0x67790,
    'stackavail_': 0x67006,
    'common_init_': 0x67474,
    'game_main_': 0x1002c,
    'runtime_exit_': 0x60353,
    'copy_c_string_': 0x675f4,
    'spawnve_': 0x64087,
    'split_path_': 0x678a2,
    'make_path_': 0x6793e,
    'build_child_environment_': 0x67603,
    'probe_executable_': 0x64035,
    'prepare_spawn_': 0x64054,
    'spawn_with_arguments_': 0x67a15,
    'strnicmp_': 0x6751a,
    'search_and_spawn_': 0x6e7a1,
    'check_stack_': 0x67018,
    'strchr_': 0x6e8f8,
    'read_game_data_': 0x2f46b,
    'write_game_data_': 0x309a3,
    'get_audio_flag_a_': 0x35683,
    'get_audio_flag_b_': 0x35693,
    'get_audio_level_a_': 0x356d6,
    'get_audio_level_b_': 0x35704,
    'set_audio_flag_a_': 0x3569c,
    'set_audio_flag_b_': 0x356b9,
    'set_audio_level_a_': 0x356dc,
    'set_audio_level_b_': 0x3570a,
    'stop_cd_driver_playback_': 0x37a85,
    'play_cd_track_': 0x37b22,
    'resume_cd_driver_playback_': 0x37cd5,
    'request_cd_disk_info_': 0x3784f,
    '_dos_setvect_': 0x603de,
    '_dos_getvect_': 0x603a8,
    'read_cd_track_info_': 0x3786d,
    'read_cd_track_start_': 0x378d8,
    'outp_': 0x6039a,
    'initialize_video_mode_': 0x4a480,
    'rebuild_view_angle_table_': 0x56e8f,
    'setview_': 0x56f0a,
    'setaspect_': 0x5708a,
    'draw_view_border_': 0x346f2,
    'report_timer_error_': 0x26a03,
    'timer_initialize_': 0x60b40,
    'timer_register_callback_': 0x60c51,
    'timer_remove_callback_': 0x60fa7,
    'timer_shutdown_': 0x60c17,
    'timer_set_divisor_': 0x61169,
    'program_pit_': 0x64d6f,
    'install_timer_vector_': 0x64db5,
    'mask_timer_irq_': 0x64e70,
    'unmask_timer_irq_': 0x64e9c,
    'restore_timer_vector_': 0x64ec8,
    'chain_original_timer_': 0x64f44,
    'malloc_': 0x6126d,
})
CODE_OFFSETS.update({'save_fpu_state_': 0x545f7, 'restore_fpu_state_': 0x545fc})
CODE_OFFSETS['run_exit_callbacks_'] = 0x30bd6
CODE_OFFSETS['keyboard_interrupt_'] = 0x1f27e
CODE_OFFSETS['advance_timer_clock_'] = 0x247f7
CODE_OFFSETS['vsprintf_putc_'] = 0x52eb7
CODE_OFFSETS['sprintf_putc_'] = 0x501e0

# Instruction operands written by the original self-modifying renderer.
CODE_OFFSETS.update({
    '_translucent_column_shift': 0x644e4,
    '_previous_column_shift': 0x6432c,
    '_opaque_column_shift': 0x6434e,
    '_opaque_group_shift_3': 0x64605,
    '_opaque_group_shift_2': 0x645fa,
    '_opaque_group_shift_1': 0x645d7,
    '_opaque_group_shift_0': 0x645d2,
    '_masked_column_shift': 0x64377,
    '_masked_group_shift_3': 0x64781,
    '_masked_group_shift_2': 0x64763,
    '_masked_group_shift_1': 0x64731,
    '_masked_group_shift_0': 0x6472e,
    '_column_blend_table': 0x644f7,
    '_span_blend_table_0': 0x64c7a,
    '_span_blend_table_1': 0x64ce7,
    '_span_blend_table_2': 0x64cfe,
    '_sprite_blend_table': 0x64a1c,
    '_paired_column_blend_table_0': 0x64e2b,
    '_paired_column_blend_table_1': 0x64e31,
    '_paired_column_blend_table_2': 0x64dc4,
    '_paired_column_blend_table_3': 0x64e54,
    '_opaque_span_palette_0': 0x64169,
    '_opaque_span_palette_1': 0x64191,
    '_opaque_span_palette_2': 0x641b2,
    '_opaque_span_palette_3': 0x64265,
    '_opaque_span_palette_4': 0x64276,
    '_opaque_span_palette_5': 0x642ac,
    '_opaque_span_palette_6': 0x642ba,
    '_previous_column_pitch': 0x64346,
    '_opaque_column_pitch': 0x64351,
    '_masked_column_pitch': 0x6438a,
    '_translucent_column_pitch': 0x64501,
    '_opaque_sprite_pitch': 0x64928,
    '_masked_sprite_pitch': 0x6499c,
    '_translucent_sprite_pitch': 0x64a24,
    '_opaque_group_pitch': 0x6463b,
    '_masked_group_pitch_0': 0x64711,
    '_masked_group_pitch_1': 0x6479f,
    '_paired_column_pitch_0': 0x64d87,
    '_paired_column_pitch_1': 0x64ddc,
    '_paired_column_pitch_2': 0x64e25,
    '_paired_column_pitch_3': 0x64dbe,
    '_paired_column_pitch_4': 0x64e4e,
    '_paired_column_shift_0': 0x64de6,
    '_paired_column_shift_1': 0x64deb,
    '_paired_column_left_palette_0': 0x64e19,
    '_paired_column_right_palette_0': 0x64e1f,
    '_paired_column_left_palette_1': 0x64db8,
    '_paired_column_right_palette_1': 0x64e48,
    '_masked_span_u_step': 0x65274,
    '_masked_span_texture_step': 0x6527c,
    '_masked_span_palette': 0x65282,
    '_masked_span_u_carry_step': 0x65293,
    '_masked_span_v_step': 0x65288,
    '_masked_span_x_shift_0': 0x64adf,
    '_masked_span_y_shift_0': 0x64ae3,
    '_masked_span_x_shift_1': 0x64b3d,
    '_masked_span_y_shift_1': 0x64b41,
    '_masked_span_x_shift_2': 0x64b56,
    '_masked_span_y_shift_2': 0x64b5a,
    '_translucent_span_x_shift_0': 0x64c51,
    '_translucent_span_y_shift_0': 0x64c55,
    '_translucent_span_x_shift_1': 0x64ca3,
    '_translucent_span_y_shift_1': 0x64ca7,
    '_translucent_span_x_shift_2': 0x64cbc,
    '_translucent_span_y_shift_2': 0x64cc0,
    '_unrolled_span_u_step_0': 0x6518f,
    '_unrolled_span_u_step_1': 0x651ab,
    '_unrolled_span_u_step_2': 0x651da,
    '_unrolled_span_u_step_3': 0x651f6,
    '_unrolled_span_u_step_4': 0x65154,
    '_unrolled_span_texture_step_0': 0x65197,
    '_unrolled_span_texture_step_1': 0x651bb,
    '_unrolled_span_texture_step_2': 0x651e2,
    '_unrolled_span_texture_step_3': 0x65206,
    '_unrolled_span_texture_step_4': 0x6515c,
    '_unrolled_span_palette_0': 0x6519d,
    '_unrolled_span_palette_1': 0x651c1,
    '_unrolled_span_palette_2': 0x651e8,
    '_unrolled_span_palette_3': 0x6520c,
    '_unrolled_span_palette_4': 0x65162,
    '_unrolled_span_u_carry_step_0': 0x651b3,
    '_unrolled_span_u_carry_step_1': 0x651cd,
    '_unrolled_span_u_carry_step_2': 0x651fe,
    '_unrolled_span_u_carry_step_3': 0x65218,
    '_unrolled_span_u_carry_step_4': 0x65168,
    '_unrolled_span_v_step_0': 0x651a3,
    '_unrolled_span_v_step_1': 0x651c7,
    '_unrolled_span_v_step_2': 0x651ee,
    '_unrolled_span_v_step_3': 0x65212,
    '_unrolled_span_v_step_4': 0x6516e,
})


# These small-model operands address the original DATA object through DS.
# Each entry identifies the exact routine, operand, external, and opcode.
SMALL_MODEL_DATA_REFERENCES = {
    'clear_text_region_': {
        22: ('_video_mode', b'\x66\x83\x3d'),
        31: ('_mono_text_selector', b'\x8e\x25'),
        36: ('_mono_text_offset', b'\xa1'),
        44: ('_color_text_selector', b'\x8e\x25'),
        49: ('_color_text_offset', b'\xa1'),
        56: ('_text_columns', b'\x0f\xbf\x1d'),
        68: ('_bios_data_offset', b'\x8b\x15'),
        74: ('_bios_data_selector', b'\x8e\x05'),
        94: ('_active_text_page', b'\x0f\xbf\x1d'),
        114: ('_text_attribute', b'\x66\x0f\xb6\x0d'),
        158: ('_text_columns', b'\x0f\xbf\x15'),
    },
    'call_graphics_real_mode_interrupt_': {
        16: ('_dos_extender_type', b'\x80\x3d'),
    },
    'getenv_': {10: ('_environment_vector', b'\x8b\x35')},
    'program_hercules_graphics_': {
        7: ('_bios_data_offset', b'\xa1'),
        13: ('_bios_data_selector', b'\x8e\x05'),
        48: ('_hercules_crtc_registers', b'\x0f\xb6\x90'),
        78: ('_mono_video_offset', b'\x8b\x3d'),
        85: ('_mono_video_selector', b'\x66\x8b\x15'),
        117: ('_bios_data_offset', b'\xa1'),
        123: ('_bios_data_selector', b'\x8e\x05'),
    },
    'detect_legacy_display_adapters_': {
        96: ('_bios_data_offset', b'\xa1'),
        102: ('_bios_data_selector', b'\x8e\x05'),
    },
    'detect_display_adapters_': {
        104: ('_bios_data_offset', b'\xa1'),
        110: ('_bios_data_selector', b'\x8e\x05'),
    },
    'set_and_query_bios_mode_': {
        20: ('_bios_data_offset', b'\xa1'),
        26: ('_bios_data_selector', b'\x8e\x05'),
        67: ('_preserve_display', b'\x66\x83\x3d'),
    },
    'apply_graphics_mode_state_': {
        8: ('_graphics_active', b'\xc6\x05'),
        24: ('_pixel_width', b'\x66\x89\x35'),
        31: ('_pixel_height', b'\x66\x89\x15'),
        38: ('_palette_size', b'\x66\x89\x1d'),
        45: ('_bitmap_bits_per_pixel', b'\x66\x89\x0d'),
        53: ('_mode_buffer_offset', b'\xa3'),
        63: ('_text_page_count', b'\x66\x89\x15'),
        72: ('_mode_buffer_selector', b'\x66\xa3'),
        82: ('_mode_buffer_stride', b'\x66\x89\x15'),
        89: ('_bitmap_layout_flags', b'\x66\x09\x05'),
        99: ('_current_buffer_stride', b'\x66\x89\x15'),
        104: ('_current_buffer_offset', b'\xa3'),
    },
    'hide_graphics_cursor_': {
        6: ('_cursor_visible', b'\x66\x83\x3d'),
        15: ('_graphics_active', b'\x80\x3d'),
        34: ('_active_text_page', b'\x0f\xbf\x05'),
        40: ('_bios_data_offset', b'\x8b\x15'),
        50: ('_bios_data_selector', b'\x8e\x05'),
        64: ('_text_cursor_row', b'\x0f\xbf\x05'),
        71: ('_text_cursor_column', b'\x0f\xbf\x15'),
        95: ('_cursor_visible', b'\x66\xc7\x05'),
    },
    'set_bios_cursor_visible_': {6: ('_cursor_shape', b'\x66\x8b\x0d')},
    'set_text_rows_': {
        9: ('_graphics_error', b'\x66\xc7\x05'),
        22: ('_graphics_active', b'\x80\x3d'),
        50: ('_graphics_error', b'\x66\x83\x3d'),
        65: ('_bios_data_offset', b'\xa1'),
        71: ('_bios_data_selector', b'\x8e\x05'),
        99: ('_text_rows', b'\x66\xa3'),
        105: ('_graphics_active', b'\x80\x3d'),
        125: ('_text_window_top', b'\x66\xc7\x05'),
        134: ('_text_window_left', b'\x66\xc7\x05'),
        143: ('_text_cursor_row', b'\x66\xc7\x05'),
        152: ('_text_cursor_column', b'\x66\xc7\x05'),
        160: ('_text_rows', b'\x66\xa1'),
        167: ('_text_page_offset', b'\x66\xc7\x05'),
        178: ('_text_window_bottom', b'\x66\xa3'),
        184: ('_text_columns', b'\x66\xa1'),
        195: ('_text_window_right', b'\x66\xa3'),
        207: ('_active_text_page', b'\x66\xc7\x05'),
        221: ('_text_rows', b'\x66\xa1'),
    },
    'initialize_graphics_once_': {
        5: ('_graphics_init_pending', b'\x80\x3d'),
        14: ('_graphics_init_pending', b'\xc6\x05'),
        31: ('_video_mode', b'\x66\xa1'),
        38: ('_text_rows', b'\x66\x8b\x1d'),
        44: ('_initial_video_mode', b'\x66\xa3'),
        51: ('_initial_text_rows', b'\x66\x89\x1d'),
        56: ('_bios_data_offset', b'\xa1'),
        62: ('_bios_data_selector', b'\x8e\x05'),
        77: ('_text_window_top', b'\x66\xc7\x05'),
        89: ('_text_window_left', b'\x66\xc7\x05'),
        101: ('_text_window_bottom', b'\x66\x89\x1d'),
        107: ('_text_cursor_row', b'\x66\xa3'),
        113: ('_text_columns', b'\x66\xa1'),
        123: ('_text_cursor_column', b'\x66\x89\x15'),
        129: ('_text_window_right', b'\x66\xa3'),
    },
    'read_graphics_mode_state_': {
        7: ('_pixel_width', b'\x66\xc7\x05'),
        16: ('_pixel_height', b'\x66\xc7\x05'),
        25: ('_bitmap_bits_per_pixel', b'\x66\xc7\x05'),
        34: ('_bitmap_layout_flags', b'\x66\xc7\x05'),
        41: ('_bios_data_offset', b'\xa1'),
        47: ('_bios_data_selector', b'\x8e\x05'),
        75: ('_text_rows', b'\x66\xa3'),
        80: ('_bios_data_offset', b'\xa1'),
        86: ('_bios_data_selector', b'\x8e\x05'),
        105: ('_text_columns', b'\x66\xa3'),
        117: ('_palette_size', b'\x66\xc7\x05'),
        135: ('_video_mode', b'\x66\xa3'),
        151: ('_adapter_class_table', b'\x66\x8b\x14\x45'),
        159: ('_monitor_class_table', b'\x66\x8b\x04\x45'),
        165: ('_monitor_class', b'\x66\xa3'),
        176: ('_video_memory_table', b'\x66\x8b\x04\x45'),
        182: ('_video_memory_kib', b'\x66\xa3'),
        190: ('_adapter_class', b'\x66\x89\x15'),
        228: ('_video_memory_kib', b'\x66\x89\x1d'),
        234: ('_graphics_active', b'\x80\x3d'),
        244: ('_adapter_class', b'\x66\x83\x3d'),
        254: ('_text_page_count', b'\x66\xc7\x05'),
        268: ('_bios_data_offset', b'\xa1'),
        274: ('_bios_data_selector', b'\x8e\x05'),
        287: ('_cursor_shape', b'\x66\xa3'),
    },
    'initialize_text_pages_': {
        6: ('_text_rows', b'\x66\xa1'),
        14: ('_text_columns', b'\x66\x0f\xaf\x05'),
        35: ('_bios_data_offset', b'\xa1'),
        43: ('_bios_data_selector', b'\x8e\x05'),
        59: ('_video_memory_kib', b'\x66\x83\x3d'),
        106: ('_text_page_count', b'\x66\x89\x15'),
    },
    'configure_ega_text_font_': {
        84: ('_bios_data_offset', b'\xa1'),
        90: ('_bios_data_selector', b'\x8e\x05'),
        137: ('_cursor_visible', b'\x66\xc7\x05'),
    },
    'set_standard_text_rows_': {
        43: ('_bios_data_offset', b'\xa1'),
        49: ('_bios_data_selector', b'\x8e\x05'),
        80: ('_cursor_visible', b'\x66\xc7\x05'),
    },
    'unmap_coordinate_pair_': {
        31: ('_viewport_origin_x', b'\x0f\xbf\x05'),
        41: ('_pixel_first_min', b'\x0f\xbf\x35'),
        56: ('_world_first_min', b'\x8b\x15'),
        63: ('_world_first_max', b'\xa1'),
        84: ('_pixel_first_max', b'\x0f\xbf\x05'),
        107: ('_world_first_min', b'\xa1'),
        130: ('_viewport_origin_y', b'\x0f\xbf\x05'),
        140: ('_pixel_second_min', b'\x0f\xbf\x0d'),
        158: ('_pixel_second_max', b'\x0f\xbf\x05'),
        185: ('_reverse_second_axis', b'\x66\x83\x3d'),
        193: ('_world_second_max', b'\xa1'),
        199: ('_world_second_min', b'\x8b\x15'),
        220: ('_world_second_max', b'\xa1'),
        243: ('_world_second_min', b'\xa1'),
        249: ('_world_second_max', b'\x8b\x15'),
        269: ('_world_second_max', b'\x8b\x15'),
    },
    'copy_world_bounds_': {14: ('_world_bounds', b'\xbe')},
    'get_video_configuration_': {16: ('_pixel_width', b'\xbe')},
    'get_fill_pattern_': {
        8: ('_fill_pattern', b'\xbe'),
        29: ('_fill_pattern_enabled', b'\x80\x3d'),
    },
    'set_fill_pattern_': {
        8: ('_fill_pattern', b'\xbf'),
        13: ('_default_fill_pattern', b'\xbe'),
        24: ('_fill_pattern_enabled', b'\xc6\x05'),
        42: ('_fill_pattern', b'\xbf'),
        69: ('_default_fill_pattern', b'\xbf'),
        96: ('_fill_pattern_enabled', b'\xc6\x05'),
        107: ('_fill_pattern_enabled', b'\xc6\x05'),
    },
}


def flat_frame_groups(blob):
    """Identify the explicit empty FLAT groups used by the verified Watcom objects.

    Absolute references need frame placement metadata. Other absolute frames
    are only supported for the known small-model DATA operands above.
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


# Watcom resolves these direct jumps in the object without an OMF fixup.
# The public entries retain their original, nonadjacent executable spans.
INTERNAL_LEAF_JUMPS = {
    'processreservedmessage_': {
        **dict.fromkeys((32, 171, 515, 534, 603, 714), ('netinitconnection_', 365)),
        39: ('netinitconnection_', 365, 0x85),
        176: ('netinitconnection_', 365, 0x8c),
        226: ('netinitconnection_', 365, 0x84),
        270: ('netinitconnection_', 365, 0x85),
        293: ('netinitconnection_', 365, 0x85),
        608: ('netinitconnection_', 365, 0x8c),
        624: ('netinitconnection_', 365, 0x8d),
        698: ('netinitconnection_', 365, 0x8c),
    },
    'getpacket_': {1424: ('netinitconnection_', 368)},
    'deletespritesect_': {0x1f: ('insertspritesect_', 0x96), 0xce: ('insertspritesect_', 0x96)},
    'deletespritestat_': {0x1f: ('insertspritesect_', 0x96), 0xce: ('insertspritesect_', 0x96)},
    'read_configuration_line_': {141: ('find_configuration_key_', 0xaa)},
    'append_configuration_value_': {
        55: ('find_configuration_key_', 0xaa),
        111: ('find_configuration_key_', 0xaa),
        240: ('find_configuration_key_', 0xaa),
    },
}


# This local tail is compiled into the unlinked insertion candidate.
# The exact image supplies the same pop/pop/pop/pop/pop/ret sequence in transmaskvline.
INTERNAL_EPILOGUE_ALIASES = {
    ('insertspritesect_', 0x96): ('shared_graphics_epilogue_', bytes.fromhex('5f5e5a595bc3')),
}


# Watcom emits both shutdown early exits to a local RET. In FATE those
# conditional jumps use the equivalent RET owned by network initialization.
INTERNAL_SHORT_RETURNS = {
    'uninitmultiplayers_': (
        'network_init_return_', 0x44, ((0x08, 0x7e), (0x2a, 0x7c)),
    ),
}


def bind_short_returns(code, symbol, address, functions, fixup_fields):
    if symbol not in INTERNAL_SHORT_RETURNS:
        return
    target_symbol, local_ret, branches = INTERNAL_SHORT_RETURNS[symbol]
    if address is None or target_symbol not in (functions or {}):
        raise ValueError('Short return requires loaded source and target addresses')
    if local_ret >= len(code) or code[local_ret] != 0xc3:
        raise ValueError('Expected compiler-local near return')
    for site, opcode in branches:
        if (site + 2 > len(code) or code[site] != opcode
                or fixup_fields.intersection(range(site, site + 2))):
            raise ValueError('Invalid short return branch')
        original = int.from_bytes(code[site + 1:site + 2], 'little', signed=True)
        if site + 2 + original != local_ret:
            raise ValueError('Unexpected local short return target')
        displacement = functions[target_symbol] - (address + site + 2)
        if not -128 <= displacement <= 127:
            raise ValueError('Shared return is outside short branch range')
        code[site + 1] = displacement & 0xff



# Status-panel body; its 84-byte entry remains separately verified assembly.
LEAVES['draw_status_panel_'] = (0x35cce, 608)
FUNCTION_ADDRESSES.update({'draw_status_panel_': 0x1067a,
                           'draw_tile_': 0x57181, 'draw_number_text_': 0x385f4})
DATA_OFFSETS.update({
    '_number_format': 0xe4, '_show_left_icon': 0x2038,
    '_show_middle_icon': 0x203a, '_show_right_icon': 0x203c,
    '_status_left_value': 0x225d, '_status_left_tenths': 0x2263,
    '_status_right_values': 0x2277, '_status_right_index': 0x2be2,
    '_status_right_tenths': 0x6319c, '_panel_top': 0x7f898,
    '_window_bottom': 0x286b90, '_window_top': 0x286b94,
    '_window_right': 0x286b98, '_window_left': 0x286b9c,
})


# Gameplay-controller compiler sections; calls enter the original public address.
LEAVES.update({'getpacket_head_': (0x67f85, 914), 'getpacket_tail_': (0x6831b, 511),
               'getpacket_length_order_': (0x68317, 4)})
DATA_OFFSETS.update({'_syncstate': 81116, '_netincnt': 1600824, '_comescape': 1637884, '_comreset': 1637932, '_syncbufleng': 1637944, '_syncbuf_backing': 1638496, '_getmess': 1637952, '_myconnectnum': 1637936, '_otherconnectnum': 1637896, '_inbuf': 1637924, '_inbufplc': 1637820, '_inbufend': 1637872, '_outbufplc': 1637848, '_comresend': 1637876, '_comerror': 1637916, '_incnt': 1637888, '_netinbuf': 1637812, '_netinbufplc': 1637816, '_netinbufend': 1637800})
LEAVES.update({'update_gameplay_head_': (0x39733, 550),
               'update_gameplay_tail_': (0x3996b, 677)})
FUNCTION_ADDRESSES.update({'select_item_': 229592, 'refresh_inventory_': 169035, 'check_teleport_terminals_': 81311, 'absolute_long_': 393923, 'activate_sector_': 165648, 'update_sector_events_': 171220, 'update_periodic_sequences_': 74710, 'update_proximity_sprites_': 66250, 'update_float_sprites_': 79535, 'update_moving_sprite_physics_': 79968, 'update_projectiles_': 78391, 'update_sector_panning_': 73358, 'update_fall_triggers_': 68495, 'update_level_effects_': 263778, 'save_level_and_load_board_': 81645, 'initialize_destination_': 158250, 'update_actor_states_': 124848, 'update_gameplay_': 82227})
DATA_OFFSETS.update({'_inventory_override_request': 424318, '_inventory_override': 19732, '_previous_override': 19734, '_status_right_tenths': 405916, '_saved_status_right': 19736, '_item_enabled': 8807, '_item_stock': 8823, '_item_alternate_stock': 8839, '_saved_item_enabled': 522574, '_saved_item_stock': 522558, '_saved_item_alternate_stock': 522542, '_left_icon': 8248, '_middle_icon': 8250, '_right_icon': 8252, '_effect_count': 8797, '_status_flag': 8801, '_saved_left_icon': 522540, '_saved_middle_icon': 522538, '_saved_right_icon': 522536, '_saved_effect_count': 522534, '_saved_status_flag': 522532, '_game_clock': 2653832, '_last_step_clock': 502160, '_advance_clock': 8859, '_level_sector_ids': 484252, '_level_sector_active': 484254, '_sector_hitag': 2606020, '_level_sector_x': 477596, '_level_sector_y': 477600, '_player_x': 372124, '_player_y': 372060, '_actor_active': 519350, '_actor_level': 518849, '_actor_sprite': 514744, '_sprite_x': 2113696, '_sprite_y': 2113700, '_current_level': 522366, '_level_sector_count': 502332, '_player_sector': 371964, '_special_sector': 515812, '_last_sequence_clock': 8240, '_destination_level': 8256, '_loaded_level': 522365, '_level_left_icon': 502176, '_level_middle_icon': 502178, '_level_right_icon': 502180, '_modified_levels': 515746, '_mod_extension': 720, '_destination_entry': 515822, '_destination_x': 502168, '_destination_y': 502172})

# The exact image retains this entry sequence from assembly and takes the
# remaining bytes from the compiler public of the same name.
LEAF_ENTRY_PREFIXES = {'run_menu_loop_': 17, 'draw_status_panel_': 84}
# Only these compiler-prefix references may be discarded. The independently
# verified assembly prefix owns its actual operands in the production image.
LEAF_ENTRY_PREFIX_FIXUPS = {
    'draw_status_panel_': {
        16: ('_window_bottom', False), 23: ('_window_right', False),
        30: ('_window_top', False), 37: ('_window_left', False),
        58: ('_panel_top', False), 80: ('draw_tile_', True),
    },
}


# Unchanged compiler sections surrounding a separately verified assembly island.
# Each row names the real OMF public, kept bounds, and required full public size.
LEAF_CONTEXT_SUFFIXES = {
    'main_caption_setup_': b'\xe8\x00\x00\x00\x00\xc3',
    'main_menu_select_': b'\xa1\x00\x00\x00\x00\xc3',
    'getpacket_length_copy_': b'\xc3',
    'receive_button_low_': b'\xc3',
    'receive_checksum_order_': b'\xc3',
    'receive_message_delta_': b'\xc3',
    'receive_message_clock_': b'\xc3',
    'compare_received_checksums_': b'\xc3',
    'receiver_parity_tick_': b'\xc3',
    'receive_button_high_': b'\xc3',
    'receive_ready_context_': b'\xc3',
    'receive_ready_send_': b'\xe9\x00\x00\x00\x00',
}

# Exact literal prefixes belong to unlinked compiler context, not C coverage.
# public -> (prefix bytes, SHA-256, operand offsets -> literal-prefix offsets,
#            optional placed CODE-object offset for selected literal pointers).
LEAF_CONTEXT_LITERALS = {}

# Complete private contexts, including unlinked stack wrappers and shared tails.
LEAF_CONTEXT_BYTES = {}
# Digest guards keep larger complete contexts compact.
LEAF_CONTEXT_SHA256 = {}

LEAF_CONTEXT_FIXUPS = {
    'main_caption_setup_': {2: ('_loading_caption_columns', False),
                            12: ('_loading_caption', False), 41: ('draw_menu_text_', True)},
    'main_menu_select_': {2: ('_game_in_progress', False),
                          11: ('_main_menu_selection', False),
                          19: ('_main_menu_selection', False),
                          24: ('_menu_dispatch_active', False)},
}

LEAF_CODE_SLICES = {
    'main_menu_resume_guard_': ('dispatch_main_menu_', 0x1d1, 0x1de, 497),
    'main_menu_save_': ('dispatch_main_menu_', 0, 17, 497),
    'main_menu_tick_': ('dispatch_main_menu_', 19, 25, 497),
    'main_menu_zero_': ('dispatch_main_menu_', 17, 19, 497),
    'main_menu_initialize_': ('dispatch_main_menu_', 25, 41, 497),
    'main_menu_caption_': ('main_caption_setup_', 0, 40, 46),
    'main_menu_selection_': ('main_menu_select_', 0, 23, 29),
    'main_menu_loop_': ('dispatch_main_menu_', 0x43, 0x117, 497),
    'main_menu_actions_': ('dispatch_main_menu_', 0x13f, 0x1ae, 497),
    'main_menu_exit_': ('dispatch_main_menu_', 0x1ae, 0x1f1, 497),
    'getpacket_length_order_': ('getpacket_length_copy_', 0, 4, 54),
    'receive_packets_button_low_': ('receive_button_low_', 0, 17, 28),
    'receive_packets_crc_order_': ('receive_checksum_order_', 0, 3, 24),
    'receive_packets_message_delta_': ('receive_message_delta_', 0, 10, 11),
    'receive_packets_message_clock_': ('receive_message_clock_', 0, 20, 21),
    'receive_packets_button_high_': ('receive_button_high_', 0, 9, 10),
    'receive_packets_ready_head_': ('receive_ready_context_', 0, 18, 37),
    'receive_packets_ready_send_': ('receive_ready_send_', 0, 13, 18),
    'receive_packets_checksums_': ('compare_received_checksums_', 0, 105, 106),
    'receive_packets_parity_': ('receiver_parity_tick_', 0, 7, 32),
    'receive_packets_entry_': ('receive_packets_', 0, 342, 910),
    'receive_packets_crc_store_': ('receive_packets_', 345, 370, 910),
    'receive_packets_delta_': ('receive_packets_', 472, 615, 910),
    'receive_packets_buttons_': ('receive_packets_', 636, 687, 910),
    'receive_packets_text_': ('receive_packets_', 696, 739, 910),
    'receive_packets_ready_': ('receive_packets_', 767, 783, 910),
    'receive_packets_ready_test_': ('receive_packets_', 801, 820, 910),
    'receive_packets_poll_': ('receive_packets_', 833, 874, 910),
    'receive_packets_finish_': ('receive_packets_', 876, 910, 910),

    'getpacket_head_': ('getpacket_', 0, 914, 1429),
    'getpacket_tail_': ('getpacket_', 918, 1429, 1429),
    'update_gameplay_head_': ('update_gameplay_', 0, 550, 1245),
    'update_gameplay_tail_': ('update_gameplay_', 568, 1245, 1245),
}



LEAVES.update({
    'receive_packets_entry_': (0x57a07, 342),
    'receive_packets_crc_store_': (0x57b60, 25),
    'receive_packets_delta_': (0x57be2, 143),
    'receive_packets_buttons_': (0x57c82, 51),
    'receive_packets_text_': (0x57cbe, 43),
    'receive_packets_ready_': (0x57d07, 16),
    'receive_packets_ready_test_': (0x57d29, 19),
    'receive_packets_poll_': (0x57d49, 41),
    'receive_packets_finish_': (0x57d79, 34),
})
DATA_OFFSETS.update({
    '_sync_error': 0x3cda,
    '_received_write_index': 0x3ce0,
    '_event_read_index': 0x3ce4,
    '_last_tick': 0x3cea,
    '_local_player': 0x13ce2,
    '_packet': 0x1d92c,
    '_received_checksum': 0x1e5fc,
    '_generated_checksum': 0x1f7fc,
    '_peer_ready_stage': 0x20a1c,
    '_quit_requested': 0x6793d,
    '_message_deadline': 0x7709c,
    '_message_text': 0x7aa70,
    '_message_length': 0x7f874,
})
FUNCTION_ADDRESSES.update({
    'snapshot_input_': 0x2d1bd,
    'receive_ready_send_': 0x3273c,
})

LEAVES.update({
    'receive_packets_checksums_': (0x57b79, 105),
    'receive_packets_button_low_': (0x57c71, 17),
    'receive_packets_crc_order_': (0x57b5d, 3),
    'receive_packets_message_delta_': (0x57ce9, 10),
    'receive_packets_message_clock_': (0x57cf3, 20),
    'receive_packets_button_high_': (0x57cb5, 9),
    'receive_packets_ready_head_': (0x57d17, 18),
    'receive_packets_ready_send_': (0x57d3c, 13),
    'receive_packets_parity_': (0x57d72, 7),
})
DATA_OFFSETS.update({
    '_receiver_button_bytes': 0x5ac3c,
    '_receiver_crc_words': 0x1e5fc,
    '_receiver_crc_cursor': 0x3ce0,
    '_checksum_write_cursor': 0x3cdc,
    '_checksum_received_cursor': 0x3ce0,
    '_checksum_read_cursor': 0x3ce4,
})

# Selected sections of one compiler public may straddle retained assembly.
# Entries record immutable opcodes, compiler target offsets, and original target
# offsets. Only displacement operands in the selected section are rebound.
LEAF_SECTION_BRANCHES = {
    'main_menu_select_': (29, 29, {7: (b'\x74', 17, 17), 15: (b'\xeb', 23, 23)}),
    'receive_packets_': (910, 916, {
        15: (b'\x0f\x84', 901, 907),
        49: (b'\x0f\x8e', 855, 856),
        62: (b'r', 90, 90),
        64: (b'\x0f\x86', 701, 700),
        72: (b'r', 27, 27),
        74: (b'\x0f\x86', 772, 773),
        82: (b'\x0f\x84', 843, 844),
        88: (b'\xeb', 27, 27),
        92: (b'\x0f\x87', 491, 494),
        121: (b'\xe9', 284, 284),
        152: (b't', 175, 175),
        179: (b't', 202, 202),
        206: (b't', 229, 229),
        233: (b't', 273, 273),
        286: (b'\x0f\x8d', 126, 126),
        299: (b't', 370, 370),
        368: (b'\xeb', 292, 292),
        486: (b'\xe9', 27, 27),
        507: (b't', 538, 541),
        541: (b't', 568, 571),
        571: (b't', 598, 601),
        601: (b't', 646, 645),
        649: (b'\x0f\x84', 27, 27),
        696: (b'\xe9', 27, 27),
        720: (b'\xeb', 735, 734),
        737: (b'}', 722, 721),
        767: (b'\xe9', 27, 27),
        801: (b'\x0f\x85', 27, 27),
        814: (b'\x0f\x85', 27, 27),
        838: (b'\xe9', 27, 27),
        850: (b'\xe9', 27, 27),
        868: (b't', 901, 907),
        876: (b'u', 901, 907),
        885: (b't', 895, 901),
        893: (b'\xeb', 901, 907),
    }),
}


def bind_section_branches(code, public, address, functions, fields, kept_start, kept_end, *, metadata=None):
    if metadata is None:
        if public not in LEAF_SECTION_BRANCHES:
            return
        metadata = LEAF_SECTION_BRANCHES[public]
    compiler_size, placed_size, branches = metadata
    if len(code) != compiler_size or address is None or public not in (functions or {}):
        raise ValueError('Section branch public extent/address differs')
    for site, (opcode, compiled_target, placed_target) in branches.items():
        if len(opcode) == 1 and (opcode == b'\xeb' or 0x70 <= opcode[0] <= 0x7f):
            width = 1
        elif opcode == b'\xe9' or (len(opcode) == 2 and opcode[0] == 0x0f and 0x80 <= opcode[1] <= 0x8f):
            width = 4
        else:
            raise ValueError('Unsupported section branch opcode')
        operand, end = site + len(opcode), site + len(opcode) + width
        if (site < 0 or end > len(code) or code[site:operand] != opcode
                or fields.intersection(range(site, end))):
            raise ValueError('Section branch opcode/fixup differs')
        if not 0 <= compiled_target < compiler_size or not 0 <= placed_target < placed_size:
            raise ValueError('Section branch target outside public')
        if end + int.from_bytes(code[operand:end], 'little', signed=True) != compiled_target:
            raise ValueError('Section branch compiler target differs')
        fields.update(range(site, end))
        if any(site < boundary < end for boundary in (kept_start, kept_end)):
            raise ValueError('Section boundary splits a branch')
        if kept_start <= site < kept_end:
            displacement = functions[public] + placed_target - (address + end)
            try:
                code[operand:end] = displacement.to_bytes(width, 'little', signed=True)
            except OverflowError as error:
                raise ValueError('Placed section branch exceeds original width') from error


def leaf_public_name(symbol):
    return LEAF_CODE_SLICES.get(symbol, (symbol,))[0]


def leaf_code_bounds(symbol, public_size):
    if symbol in LEAF_CODE_SLICES:
        if symbol in LEAF_ENTRY_PREFIXES or symbol in LEAF_ENTRY_PREFIX_FIXUPS:
            raise ValueError('A sliced leaf cannot also retain an entry prefix')
        _, start, end, expected_size = LEAF_CODE_SLICES[symbol]
        if public_size != expected_size or not 0 <= start < end <= public_size:
            raise ValueError('Compiler public extent differs from registered leaf slice')
        return start, end
    prefix = LEAF_ENTRY_PREFIXES.get(symbol, 0)
    if not 0 <= prefix < public_size:
        raise ValueError('Retained assembly prefix exceeds the compiler public')
    return prefix, public_size


@lru_cache(maxsize=512)
def parsed_leaf_object(blob):
    """Cache only immutable parser results, never placed code or binding outputs."""
    segments, publics = read_object(blob)
    immutable = tuple(None if segment is None else MappingProxyType(
        {**segment, 'data': bytes(segment['data'])}) for segment in segments)
    return (immutable, tuple(publics), tuple(read_externals(blob)),
            frozenset(flat_frame_groups(blob)), tuple(read_fixups(blob)))


def bind_leaf_details(blob, symbol, values, *, address=None, functions=None,
                      absolute_code=None, code_bindings=None):
    """Return unchanged (code, all_absolute_bindings), plus optional CODE metadata.

    address and returned fixup offsets refer to the placed span after any
    retained assembly entry prefix or registered compiler section.

    code_bindings must be an empty output dict when a CODE pointer is used. It
    receives leaf-relative site -> final object-relative operand, including
    addends. Pass it to verify_leaf_relocations; it is not a relative-call map.
    """
    if code_bindings is not None and (not isinstance(code_bindings, dict) or code_bindings):
        raise ValueError('CODE binding output must be an empty dict; stale metadata rejected')
    segments, publics, externals, flat_groups, fixups = parsed_leaf_object(bytes(blob))
    public_name = leaf_public_name(symbol)
    from bind_setgamemode_display import ALLOCATION_PHASES, bind_allocation_phase
    if symbol in ALLOCATION_PHASES:
        return bind_allocation_phase(blob, symbol, address)
    if symbol == 'setgamemode_backend_geometry_':
        from bind_setgamemode_display import bind_backend_geometry
        return bind_backend_geometry(blob, address)
    if symbol == 'setgamemode_display_reset_':
        from bind_setgamemode_display import bind_display_reset
        return bind_display_reset(blob, address)
    if public_name == 'dispatch_main_menu_' and symbol in LEAF_CODE_SLICES:
        from bind_main_menu_sections import bind_section, DATA as menu_data, FUNCTIONS as menu_functions
        # This shared-frame binder supports the fixed production placement.
        # Loaded/alternate execution uses the explicit full-group fixture.
        if (any(name in values and values[name] != target for name, target in menu_data.items())
                or any(name in (functions or {}) and functions[name] != target
                       for name, target in menu_functions.items())
                or set(menu_data).intersection(absolute_code or {})):
            raise ValueError('Main-menu sections require fixed bindings; use the full-group fixture')
        return bind_section(blob, symbol, address=address, code_bindings=code_bindings)
    found = [(seg, off) for seg, off, name in publics if name == public_name]
    if len(found) != 1:
        raise ValueError('Expected exactly one leaf public symbol')
    seg, start = found[0]
    if segments[seg]['cls'] != 'CODE':
        raise ValueError('Leaf is not code')
    end = min([a for s, a, _ in publics if s == seg and a > start]
              or [len(segments[seg]['data'])])
    code = bytearray(segments[seg]['data'][start:end])
    expected_context = LEAF_CONTEXT_BYTES.get(public_name)
    if expected_context is not None and bytes(code) != expected_context:
        raise ValueError('Compiler private context bytes differ')
    expected_digest = LEAF_CONTEXT_SHA256.get(public_name)
    if expected_digest is not None and hashlib.sha256(code).hexdigest() != expected_digest:
        raise ValueError('Compiler private context digest differs')
    suffix = LEAF_CONTEXT_SUFFIXES.get(public_name, b'')
    if suffix and not code.endswith(suffix):
        raise ValueError('Unlinked compiler context suffix differs')
    # DX is already 0..15 and MOVSX EBX,DX already extended the index.
    # The second, idempotent extension remains unlinked and must stay guarded.
    if (public_name == 'encounter_spawn_loop_context_'
            and code[0x161:0x164] != bytes.fromhex('0fbfdb')):
        raise ValueError('Unlinked spawn index extension differs')
    # The selected border loop already receives the original pixel pointer
    # in EDX. Its excluded MOV EDX,ESI only repeats the private entry copy.
    if (public_name == 'ripple_border_columns_'
            and (code[:3] != bytes.fromhex('5689d6')
                 or code[5:7] != bytes.fromhex('89f2'))):
        raise ValueError('Unlinked ripple pixel copy differs')
    context_fixups = LEAF_CONTEXT_FIXUPS.get(public_name)
    if context_fixups is not None:
        observed = [f for f in fixups if f.segment == seg and start <= f.offset < end]
        if len(observed) != len(context_fixups) or {f.offset-start for f in observed} != context_fixups.keys():
            raise ValueError('Compiler context fixup inventory differs')
        for f in observed:
            expected = context_fixups[f.offset-start]
            if len(expected) not in (2, 3):
                raise ValueError('Invalid compiler context fixup metadata')
            name, relative = expected[:2]
            addend = expected[2] if len(expected) == 3 else 0
            if (type(addend) is not int or not 0 <= addend <= 0xffffffff
                    or f.location != 9 or f.width != 4 or f.target[0] != 2
                    or not 0 < f.target[1] < len(externals)
                    or f.frame[0] != 1 or f.frame[1] not in flat_groups
                    or f.displacement
                    or int.from_bytes(code[f.offset-start:f.offset-start+4], 'little') != addend
                    or (externals[f.target[1]], f.relative) != (name, relative)):
                raise ValueError('Compiler context fixup target/form/addend differs')
    literal = LEAF_CONTEXT_LITERALS.get(public_name)
    literal_sites = {} if literal is None else literal[2]
    literal_base = literal[3] if literal is not None and len(literal) == 4 else None
    if literal is not None:
        if len(literal) not in (3, 4):
            raise ValueError('Invalid compiler literal metadata')
        size, digest = literal[:2]
        if len(literal) == 4 and (type(literal_base) is not int
                                        or not 0 <= literal_base <= 0xffffffff-size):
            raise ValueError('Invalid placed literal CODE offset')
        if (start != size or hashlib.sha256(segments[seg]['data'][:start]).hexdigest() != digest
                or [(s, a, n) for s, a, n in publics if s == seg] != [(seg, start, public_name)]):
            raise ValueError('Compiler literal prefix/layout differs')
        if any(f.segment == seg and (f.offset < start or f.offset+f.width > end-len(suffix))
               for f in fixups):
            raise ValueError('Fixup intersects compiler literal prefix or context suffix')
        observed = [f.offset-start for f in fixups if f.segment == seg and start <= f.offset < end
                    and (f.target[0] == 0 or f.offset-start in literal_sites)]
        if len(observed) != len(literal_sites) or set(observed) != set(literal_sites):
            raise ValueError('Compiler literal fixup inventory differs')
    kept_start, kept_end = leaf_code_bounds(symbol, len(code))
    prefix = LEAF_ENTRY_PREFIXES.get(symbol, 0)
    if address is not None:
        address -= kept_start
    prefix_fixups = LEAF_ENTRY_PREFIX_FIXUPS.get(symbol, {})
    seen_prefix_fixups = set()
    fields = set()
    literal_instructions = {byte for site in literal_sites for byte in range(site-1, site+4)}
    bindings = {}
    generated_code_bindings = {}
    for fix in fixups:
        if fix.segment != seg or not start <= fix.offset < end:
            continue
        offset = fix.offset - start
        if offset < prefix:
            if offset not in prefix_fixups:
                raise ValueError('Relocation in retained assembly prefix')
            if offset + 4 > prefix:
                raise ValueError('Relocation crosses retained assembly prefix boundary')
        if symbol in LEAF_CODE_SLICES and any(
                0 < boundary < len(code) and offset < boundary < offset + 4
                for boundary in (kept_start, kept_end)):
            raise ValueError('Relocation crosses selected leaf boundary')
        if offset not in literal_sites and literal_instructions.intersection(range(offset, offset+4)):
            raise ValueError('Fixup overlaps a compiler literal instruction')
        if offset in literal_sites:
            sites = set(range(offset, offset+4))
            if (fix.location != 9 or fix.width != 4 or fix.relative
                    or fix.target != (0, seg) or fix.displacement
                    or fix.frame[0] != 1 or fix.frame[1] not in flat_groups
                    or not 0 < offset <= len(code)-4 or fields & sites
                    or code[offset-1] != 0xbe
                    or int.from_bytes(code[offset:offset+4], 'little') != literal_sites[offset]
                    or not 0 <= literal_sites[offset] < start):
                raise ValueError('Compiler literal fixup form/addend differs')
            if kept_start <= offset < kept_end:
                if literal_base is None:
                    raise ValueError('Compiler literal operands must remain unlinked')
                if symbol not in LEAF_CODE_SLICES:
                    raise ValueError('Placed literal context requires a registered slice')
                if code_bindings is None:
                    raise ValueError('Selected literal pointer requires CODE binding metadata')
            if address is None:
                raise ValueError('Compiler literal binding requires a loaded address')
            # A separately placed, digest-checked literal prefix may supply the
            # initializer's CODE pointers. Otherwise only private fields bind
            # virtually; cropping excludes their bytes and metadata.
            base = address-start-0x10000 if literal_base is None else literal_base
            value = (base+literal_sites[offset]) & 0xffffffff
            code[offset:offset+4] = value.to_bytes(4, 'little')
            fields.update(sites)
            bindings[offset] = value
            generated_code_bindings[offset] = value
            continue
        if fix.location != 9 or fix.target[0] != 2:
            raise ValueError('Unsupported leaf relocation')
        # Small-model Watcom emits frame-by-target near calls. Both addresses
        # are in the same CODE object, so their displacement needs no frame base.
        small_model_call = (fix.frame == (5, None) and fix.relative
                            and not fix.displacement and offset > 0
                            and code[offset-1:offset+4] == b'\xe8\x00\x00\x00\x00')
        if not 0 < fix.target[1] < len(externals):
            raise ValueError('External index outside table')
        name = externals[fix.target[1]]
        if offset < prefix:
            if prefix_fixups[offset] != (name, fix.relative):
                raise ValueError('Unexpected retained assembly prefix relocation')
            seen_prefix_fixups.add(offset)
        is_code_pointer = not fix.relative and name in (absolute_code or {})
        data_name, opcode = SMALL_MODEL_DATA_REFERENCES.get(public_name, {}).get(offset, (None, b''))
        small_model_data = (fix.frame == (5, None) and not fix.relative
                            and not is_code_pointer and not fix.displacement
                            and data_name == name and offset >= len(opcode)
                            and code[offset-len(opcode):offset+4] == opcode + bytes(4))
        flat_frame = fix.frame[0] == 1 and fix.frame[1] in flat_groups
        if not (flat_frame or small_model_call or small_model_data):
            raise ValueError('Unsupported leaf frame')
        if is_code_pointer and name in values:
            raise ValueError(f'Ambiguous absolute DATA/CODE symbol: {name}')
        if is_code_pointer and code_bindings is None:
            raise ValueError('Absolute CODE binding requires code_bindings output metadata')
        targets = (functions or {}) if fix.relative else (absolute_code if is_code_pointer else values)
        if fix.relative and address is None:
            raise ValueError('Relative binding requires loaded code address')
        if name not in targets:
            raise ValueError(f'Unbound leaf symbol: {name}')
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
    for site, spec in INTERNAL_LEAF_JUMPS.get(public_name, {}).items():
        # A third element records the immutable near-Jcc condition byte.
        # Only the displacement is rebound when compiler publics move apart.
        if len(spec) not in (2, 3) or (len(spec) == 3 and not 0x80 <= spec[2] <= 0x8f):
            raise ValueError('Unsupported internal leaf jump form')
        target_symbol, target_offset = spec[:2]
        opcode = b'\xe9' if len(spec) == 2 else bytes((0x0f, spec[2]))
        operand = site + len(opcode)
        instruction_end = operand + 4
        target = [off for s, off, name in publics if s == seg and name == target_symbol]
        alias = INTERNAL_EPILOGUE_ALIASES.get((target_symbol, target_offset))
        placed_symbol, placed_offset = (alias[0], 0) if alias else (target_symbol, target_offset)
        if address is None or placed_symbol not in (functions or {}):
            raise ValueError('Internal leaf jump requires loaded source and target addresses')
        if (len(target) != 1 or site < 0 or instruction_end > len(code)
                or code[site:operand] != opcode
                or fields.intersection(range(site, instruction_end))):
            raise ValueError('Invalid internal leaf jump')
        displacement = int.from_bytes(code[operand:instruction_end], 'little', signed=True)
        if start + instruction_end + displacement != target[0] + target_offset:
            raise ValueError('Unexpected internal leaf jump target')
        if alias:
            epilogue = target[0] + target_offset
            if segments[seg]['data'][epilogue:epilogue + len(alias[1])] != alias[1]:
                raise ValueError('Compiler-local epilogue does not match the shared epilogue')
        displacement = functions[placed_symbol] + placed_offset - (address + instruction_end)
        code[operand:instruction_end] = displacement.to_bytes(4, 'little', signed=True)
    if symbol in LEAF_CODE_SLICES:
        bind_section_branches(code, public_name, address, functions, fields, kept_start, kept_end)
    if seen_prefix_fixups != set(prefix_fixups):
        raise ValueError('Missing retained assembly prefix relocation')
    bind_short_returns(code, public_name, address, functions, fields)
    if code_bindings is not None:
        code_bindings.update((site - kept_start, ref) for site, ref in generated_code_bindings.items()
                             if kept_start <= site < kept_end)
    return bytes(code[kept_start:kept_end]), {site - kept_start: ref for site, ref in bindings.items()
                                               if kept_start <= site < kept_end}


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
    actual = pointer_range(pointers, address, len(code))
    expected = {offset: value+(0x10000 if offset in code_bindings else 0x80000)
                for offset, value in bindings.items()}
    if actual != expected:
        raise ValueError('Original LE relocation sites or targets differ from bound leaf: '
                         + relocation_mismatch(actual, expected))


CODE_OFFSETS['_clearallviews_dispatch_table'] = 0x4d08a
CODE_OFFSETS['_route_navigation_dispatch'] = 0xd38a
CODE_OFFSETS['_pan_dispatch'] = 0x1e5e
CODE_OFFSETS['_directional_sprite_tiles'] = 0x1a1ef
CODE_OFFSETS['_sprite_view_dispatch'] = 0x1a257
CODE_OFFSETS['_board_player_palette_dispatch'] = 0x1e133
FUNCTION_ADDRESSES.update({
    'pan_check_count_': 0x11f76,
    'pan_advance_': 0x11f75,
    'pan_prepare_sector_': 0x11ea0,
})

CODE_OFFSETS.update({
    # Sprite renderer instruction operands, relative to the CODE object.
    '_opaque_sprite_palette': 0x64920,
    '_opaque_sprite_x_fraction_0': 0x64912,
    '_opaque_sprite_x_fraction_1': 0x64939,
    '_opaque_sprite_texture_step_0': 0x6491a,
    '_opaque_sprite_texture_step_1': 0x64941,
    '_opaque_sprite_y_step': 0x6492e,
    '_masked_sprite_palette': 0x64994,
    '_masked_sprite_x_fraction_0': 0x64982,
    '_masked_sprite_x_fraction_1': 0x649ad,
    '_masked_sprite_texture_step_0': 0x6498a,
    '_masked_sprite_texture_step_1': 0x649b5,
    '_masked_sprite_y_step': 0x649a2,
    '_translucent_sprite_palette': 0x64a16,
    '_translucent_sprite_x_fraction_0': 0x64a02,
    '_translucent_sprite_x_fraction_1': 0x64a35,
    '_translucent_sprite_texture_step_0': 0x64a0a,
    '_translucent_sprite_texture_step_1': 0x64a3d,
    '_translucent_sprite_y_step': 0x64a2a,
    # Reverse span renderer operands.
    '_reverse_fraction_step': 0x65335,
    '_reverse_texel_step': 0x6533c,
    '_reverse_second_sample_0': 0x65362,
    '_reverse_second_sample_1': 0x65388,
    '_reverse_pair_fraction_0': 0x65368,
    '_reverse_pair_fraction_1': 0x6538e,
    '_reverse_pair_texel_0': 0x6536e,
    '_reverse_pair_texel_1': 0x65394,
    '_reverse_palette_0': 0x65374,
    '_reverse_palette_1': 0x6537a,
    '_reverse_palette_2': 0x6539a,
    '_reverse_palette_3': 0x653a0,
    '_reverse_palette_single': 0x65342,
    # Operand bytes written by the translucency mode setters.
    '_column_framebuffer_operand': 0x644ee,
    '_column_palette_operand': 0x644f4,
    '_sprite_framebuffer_operand': 0x64a13,
    '_sprite_palette_operand': 0x64a15,
    '_span_first_palette_operand': 0x64c71,
    '_span_first_blend_operand': 0x64c77,
    '_span_left_palette_operand': 0x64cde,
    '_span_left_blend_operand': 0x64ce4,
    '_span_right_palette_operand': 0x64cf5,
    '_span_right_blend_operand': 0x64cfb,
    '_pair_tail_framebuffer_operand': 0x64db1,
    '_pair_tail_palette_operand': 0x64db7,
    '_pair_framebuffer_operand': 0x64e10,
    '_pair_pixel_registers': 0x64e16,
    '_pair_left_palette_operand': 0x64e18,
    '_pair_right_palette_operand': 0x64e1e,
    '_pair_second_framebuffer_operand': 0x64e41,
    '_pair_second_palette_operand': 0x64e47,
})

DATA_OFFSETS.update({'_sqrt_float_bits': 0x286b20, '_sqrt_lookup': 0x1d3160})

LEAVES.update({
    'setup_sprite_horizontal_reverse_': (0x9a8b0, 87),
    'setupspritevline_': (0x99ee0, 46),
    'msetupspritevline_': (0x99f50, 46),
    'tsetupspritevline_': (0x99fc0, 46),
    'initspritelists_': (0x75de3, 213),
    'sectorofwall_': (0x833c6, 170),
    'nextsectorneighborz_': (0x76263, 208),
    'rebuild_view_angle_table_': (0x7c48f, 123),
    'setview_': (0x7c50a, 384),
    'setaspect_': (0x7c68a, 247),
    'keepaway_': (0x7922e, 167),
    'bunchfront_': (0x6ab76, 154),
    'output_signed_8_': (0x936fd, 14),
    'output_signed_16_': (0x9370b, 15),
    'output_unsigned_8_': (0x9371a, 19),
    'output_unsigned_16_': (0x9372d, 20),
    'output_stereo_signed_8_': (0x93741, 20),
    'output_stereo_signed_16_': (0x93755, 22),
    'output_stereo_unsigned_8_': (0x9376b, 31),
    'output_stereo_unsigned_16_': (0x9378a, 33),
    'output_swapped_mono_signed_8_': (0x937ab, 14),
    'output_swapped_mono_signed_16_': (0x937b9, 15),
    'output_swapped_mono_unsigned_8_': (0x937c8, 19),
    'output_swapped_mono_unsigned_16_': (0x937db, 20),
    'output_swapped_stereo_signed_8_': (0x937ef, 20),
    'output_swapped_stereo_signed_16_': (0x93803, 22),
    'output_swapped_stereo_unsigned_8_': (0x93819, 31),
    'output_swapped_stereo_unsigned_16_': (0x93838, 33),
    'output_clipped_mono_signed_8_': (0x93859, 42),
    'output_clipped_mono_signed_16_': (0x93883, 43),
    'output_clipped_mono_unsigned_8_': (0x938ae, 47),
    'output_clipped_mono_unsigned_16_': (0x938dd, 48),
    'output_clipped_stereo_signed_8_': (0x9390d, 78),
    'output_clipped_stereo_signed_16_': (0x9395b, 80),
    'output_clipped_stereo_unsigned_8_': (0x939ab, 89),
    'output_clipped_stereo_unsigned_16_': (0x93a04, 91),
    'output_clipped_swapped_mono_signed_8_': (0x93a5f, 42),
    'output_clipped_swapped_mono_signed_16_': (0x93a89, 43),
    'output_clipped_swapped_mono_unsigned_8_': (0x93ab4, 47),
    'output_clipped_swapped_mono_unsigned_16_': (0x93ae3, 48),
    'output_clipped_swapped_stereo_signed_8_': (0x93b13, 78),
    'output_clipped_swapped_stereo_signed_16_': (0x93b61, 80),
    'output_clipped_swapped_stereo_unsigned_8_': (0x93bb1, 89),
    'output_clipped_swapped_stereo_unsigned_16_': (0x93c0a, 91),
    'segread_': (0x88672, 40),
    'initialize_audio_backend_': (0x8ae02, 882),
    'shutdown_audio_backend_': (0x8b174, 882),
    'draw_menu_text_': (0x5dcd3, 301),
    'load_detector_command_table_': (0x90b4b, 378),
    'find_working_audio_driver_': (0x90cc5, 573),
    'find_next_working_audio_driver_': (0x90f02, 529),
    'detect_audio_driver_': (0x908d4, 631),
    'audio_driver_init_': (0x86e40, 1123),
    'audio_driver_shutdown_': (0x872a3, 477),
    'allocate_audio_buffer_': (0x87480, 201),
    'allocate_dpmi_audio_buffer_': (0x87549, 284),
    'release_dpmi_audio_buffer_': (0x87665, 113),
    'draw_menu_frame_': (0x5eb11, 298),
    'edit_save_slot_name_': (0x5ee90, 370),
    'run_save_game_menu_': (0x5f395, 394),
    'run_load_game_menu_': (0x5f51f, 431),
    'load_audio_driver_image_': (0x8b510, 482),
    'unload_audio_driver_image_': (0x8b6f2, 198),
    'audio_detection_noop_': (0x906ea, 21),
    'open_audio_detector_': (0x906ff, 333),
    'close_audio_detector_': (0x9084c, 136),
    'query_detected_audio_parameters_': (0x91113, 384),
    'apply_detected_audio_parameters_': (0x91293, 187),
    'audio_detection_end_': (0x9134e, 21),
    'audio_detection_lookup_start_': (0x91363, 21),
    'lookup_audio_detector_value_': (0x91378, 42),
    'audio_detection_lookup_end_': (0x913a2, 21),
    'allocate_driver_workspace_': (0x8b7e2, 100),
    'release_driver_workspace_': (0x8b846, 70),
    'set_workspace_allocate_hook_': (0x8b88c, 32),
    'set_workspace_release_hook_': (0x8b8ac, 32),
    'audio_init_noop_': (0x86d68, 21),
    'audio_system_init_': (0x86d7d, 92),
    'audio_system_shutdown_': (0x86dd9, 61),
    'audio_noop_61816_': (0x86e16, 21),
    'audio_noop_6182b_': (0x86e2b, 21),
    'audio_empty_range_stub_657ed_': (0x8aded, 21),
    'audio_empty_range_stub_65ee6_': (0x8b4e6, 21),
    'audio_empty_range_stub_65efb_': (0x8b4fb, 21),
    'audio_empty_range_stub_661b8_': (0x8b7b8, 21),
    'audio_empty_range_stub_661cd_': (0x8b7cd, 21),
    'audio_empty_range_stub_662cc_': (0x8b8cc, 21),
    'audio_empty_range_stub_662e1_': (0x8b8e1, 21),
    'query_driver_interface_': (0x8b8f6, 133),
    'audio_dispatch_noop_': (0x8b97b, 21),
    'audio_empty_range_stub_64cfc_': (0x8a2fc, 1),
    'audio_backend_region_start_': (0x8b990, 1),
    'audio_empty_range_stub_66b74_': (0x8c174, 1),
    'audio_empty_range_stub_67005_': (0x8c605, 1),
    'audio_input_region_start_': (0x913b8, 1),
    'audio_input_region_end_': (0x932f9, 1),
    'audio_output_region_start_': (0x932fc, 1),
    'audio_output_region_end_': (0x93c65, 1),
    'int386x_': (0x8869a, 25),
    'int386_': (0x886b3, 27),
    'dragpoint_': (0x77e22, 173),
    'draw_menu_selection_marker_': (0x5e743, 242),
    'service_audio_driver_0_': (0x876d6, 35),
    'service_audio_driver_1_': (0x876f9, 35),
    'service_audio_driver_2_': (0x8771c, 35),
    'service_audio_driver_3_': (0x8773f, 35),
    'service_audio_driver_4_': (0x87762, 35),
    'audio_noop_62185_': (0x87785, 21),
    'audio_noop_6219f_': (0x8779f, 21),
    'queue_audio_sample_': (0x877b4, 384),
    'request_sample_stop_': (0x87934, 114),
    'request_all_samples_stop_': (0x879a6, 110),
    'audio_noop_62414_': (0x87a14, 21),
    'audio_noop_62429_': (0x87a29, 21),
    'read_driver_field_1c_': (0x87a3e, 66),
    'set_sample_field_2c_': (0x87a80, 136),
    'get_sample_field_2c_': (0x87b08, 118),
    'get_sample_field_58_': (0x87b7e, 118),
    'get_sample_field_30_': (0x87bf4, 118),
    'set_sample_field_44_': (0x87c6a, 134),
    'get_sample_field_44_': (0x87cf0, 118),
    'set_sample_field_34_': (0x87d66, 134),
    'get_sample_field_34_': (0x87dec, 118),
    'get_sample_field_48_': (0x87e62, 118),
    'get_sample_identifier_': (0x87ed8, 100),
    'find_sample_by_identifier_': (0x87f3c, 138),
    'read_driver_field_54_': (0x87fc6, 66),
    'sample_is_inactive_': (0x88008, 122),
    'audio_noop_62a82_': (0x88082, 21),
    'mix_mono_to_mono_signed_8_': (0x917b9, 30),
    'mix_mono_to_mono_unsigned_8_': (0x917d7, 35),
    'mix_mono_to_mono_signed_16_': (0x917fa, 31),
    'mix_mono_to_mono_unsigned_16_': (0x91819, 36),
    'mix_mono_to_stereo_signed_8_': (0x9183d, 33),
    'mix_mono_to_stereo_unsigned_8_': (0x9185e, 38),
    'mix_mono_to_stereo_signed_16_': (0x91884, 34),
    'mix_mono_to_stereo_unsigned_16_': (0x918a6, 39),
    'mix_stereo_to_mono_signed_8_': (0x918cd, 33),
    'mix_stereo_to_mono_unsigned_8_': (0x918ee, 44),
    'mix_stereo_to_mono_signed_16_': (0x9191a, 35),
    'mix_stereo_to_mono_unsigned_16_': (0x9193d, 46),
    'mix_stereo_to_stereo_signed_8_': (0x9196b, 39),
    'mix_stereo_to_stereo_unsigned_8_': (0x91992, 50),
    'mix_stereo_to_stereo_signed_16_': (0x919c4, 41),
    'mix_stereo_to_stereo_unsigned_16_': (0x919ed, 52),
    'resample_mono_to_mono_signed_8_': (0x91a21, 39),
    'resample_mono_to_mono_unsigned_8_': (0x91a48, 44),
    'resample_mono_to_mono_signed_16_': (0x91a74, 45),
    'resample_mono_to_mono_unsigned_16_': (0x91aa1, 50),
    'resample_mono_to_stereo_signed_8_': (0x91ad3, 42),
    'resample_mono_to_stereo_unsigned_8_': (0x91afd, 47),
    'resample_mono_to_stereo_signed_16_': (0x91b2c, 48),
    'resample_mono_to_stereo_unsigned_16_': (0x91b5c, 53),
    'resample_stereo_to_mono_signed_8_': (0x91b91, 47),
    'resample_stereo_to_mono_unsigned_8_': (0x91bc0, 58),
    'resample_stereo_to_mono_signed_16_': (0x91bfa, 49),
    'resample_stereo_to_mono_unsigned_16_': (0x91c2b, 60),
    'resample_stereo_to_stereo_signed_8_': (0x91c67, 53),
    'resample_stereo_to_stereo_unsigned_8_': (0x91c9c, 64),
    'resample_stereo_to_stereo_signed_16_': (0x91cdc, 55),
    'resample_stereo_to_stereo_unsigned_16_': (0x91d13, 66),
    'mix_scaled_mono_to_mono_signed_8_': (0x91d55, 42),
    'mix_scaled_mono_to_mono_unsigned_8_': (0x91d7f, 47),
    'mix_scaled_mono_to_mono_signed_16_': (0x91dae, 43),
    'mix_scaled_mono_to_mono_unsigned_16_': (0x91dd9, 48),
    'mix_scaled_mono_to_stereo_signed_8_': (0x91e09, 62),
    'mix_scaled_mono_to_stereo_unsigned_8_': (0x91e47, 67),
    'mix_scaled_mono_to_stereo_signed_16_': (0x91e8a, 63),
    'mix_scaled_mono_to_stereo_unsigned_16_': (0x91ec9, 68),
    'mix_scaled_stereo_to_mono_signed_8_': (0x91f0d, 45),
    'mix_scaled_stereo_to_mono_unsigned_8_': (0x91f3a, 56),
    'mix_scaled_stereo_to_mono_signed_16_': (0x91f72, 47),
    'mix_scaled_stereo_to_mono_unsigned_16_': (0x91fa1, 58),
    'mix_scaled_stereo_to_stereo_signed_8_': (0x91fdb, 63),
    'mix_scaled_stereo_to_stereo_unsigned_8_': (0x9201a, 74),
    'mix_scaled_stereo_to_stereo_signed_16_': (0x92064, 65),
    'mix_scaled_stereo_to_stereo_unsigned_16_': (0x920a5, 76),
    'resample_scaled_mono_to_mono_signed_8_': (0x920f1, 51),
    'resample_scaled_mono_to_mono_unsigned_8_': (0x92124, 56),
    'resample_scaled_mono_to_mono_signed_16_': (0x9215c, 57),
    'resample_scaled_mono_to_mono_unsigned_16_': (0x92195, 62),
    'resample_scaled_mono_to_stereo_signed_8_': (0x921d3, 71),
    'resample_scaled_mono_to_stereo_unsigned_8_': (0x9221a, 76),
    'resample_scaled_mono_to_stereo_signed_16_': (0x92266, 77),
    'resample_scaled_mono_to_stereo_unsigned_16_': (0x922b3, 82),
    'resample_scaled_stereo_to_mono_signed_8_': (0x92305, 59),
    'resample_scaled_stereo_to_mono_unsigned_8_': (0x92340, 70),
    'resample_scaled_stereo_to_mono_signed_16_': (0x92386, 61),
    'resample_scaled_stereo_to_mono_unsigned_16_': (0x923c3, 72),
    'resample_scaled_stereo_to_stereo_signed_8_': (0x9240b, 77),
    'resample_scaled_stereo_to_stereo_unsigned_8_': (0x92458, 88),
    'resample_scaled_stereo_to_stereo_signed_16_': (0x924b0, 79),
    'resample_scaled_stereo_to_stereo_unsigned_16_': (0x924ff, 90),
    'mix_swapped_mono_to_mono_signed_8_': (0x92559, 30),
    'mix_swapped_mono_to_mono_unsigned_8_': (0x92577, 35),
    'mix_swapped_mono_to_mono_signed_16_': (0x9259a, 31),
    'mix_swapped_mono_to_mono_unsigned_16_': (0x925b9, 36),
    'mix_swapped_mono_to_stereo_signed_8_': (0x925dd, 33),
    'mix_swapped_mono_to_stereo_unsigned_8_': (0x925fe, 38),
    'mix_swapped_mono_to_stereo_signed_16_': (0x92624, 34),
    'mix_swapped_mono_to_stereo_unsigned_16_': (0x92646, 39),
    'mix_swapped_stereo_to_mono_signed_8_': (0x9266d, 33),
    'mix_swapped_stereo_to_mono_unsigned_8_': (0x9268e, 44),
    'mix_swapped_stereo_to_mono_signed_16_': (0x926ba, 35),
    'mix_swapped_stereo_to_mono_unsigned_16_': (0x926dd, 46),
    'mix_swapped_stereo_to_stereo_signed_8_': (0x9270b, 39),
    'mix_swapped_stereo_to_stereo_unsigned_8_': (0x92732, 50),
    'mix_swapped_stereo_to_stereo_signed_16_': (0x92764, 41),
    'mix_swapped_stereo_to_stereo_unsigned_16_': (0x9278d, 52),
    'resample_swapped_mono_to_mono_signed_8_': (0x927c1, 39),
    'resample_swapped_mono_to_mono_unsigned_8_': (0x927e8, 44),
    'resample_swapped_mono_to_mono_signed_16_': (0x92814, 45),
    'resample_swapped_mono_to_mono_unsigned_16_': (0x92841, 50),
    'resample_swapped_mono_to_stereo_signed_8_': (0x92873, 42),
    'resample_swapped_mono_to_stereo_unsigned_8_': (0x9289d, 47),
    'resample_swapped_mono_to_stereo_signed_16_': (0x928cc, 48),
    'resample_swapped_mono_to_stereo_unsigned_16_': (0x928fc, 53),
    'resample_swapped_stereo_to_mono_signed_8_': (0x92931, 47),
    'resample_swapped_stereo_to_mono_unsigned_8_': (0x92960, 58),
    'resample_swapped_stereo_to_mono_signed_16_': (0x9299a, 49),
    'resample_swapped_stereo_to_mono_unsigned_16_': (0x929cb, 60),
    'resample_swapped_stereo_to_stereo_signed_8_': (0x92a07, 53),
    'resample_swapped_stereo_to_stereo_unsigned_8_': (0x92a3c, 64),
    'resample_swapped_stereo_to_stereo_signed_16_': (0x92a7c, 55),
    'resample_swapped_stereo_to_stereo_unsigned_16_': (0x92ab3, 66),
    'mix_scaled_swapped_mono_to_mono_signed_8_': (0x92af5, 42),
    'mix_scaled_swapped_mono_to_mono_unsigned_8_': (0x92b1f, 47),
    'mix_scaled_swapped_mono_to_mono_signed_16_': (0x92b4e, 43),
    'mix_scaled_swapped_mono_to_mono_unsigned_16_': (0x92b79, 48),
    'mix_scaled_swapped_mono_to_stereo_signed_8_': (0x92ba9, 62),
    'mix_scaled_swapped_mono_to_stereo_unsigned_8_': (0x92be7, 67),
    'mix_scaled_swapped_mono_to_stereo_signed_16_': (0x92c2a, 63),
    'mix_scaled_swapped_mono_to_stereo_unsigned_16_': (0x92c69, 68),
    'mix_scaled_swapped_stereo_to_mono_signed_8_': (0x92cad, 45),
    'mix_scaled_swapped_stereo_to_mono_unsigned_8_': (0x92cda, 56),
    'mix_scaled_swapped_stereo_to_mono_signed_16_': (0x92d12, 47),
    'mix_scaled_swapped_stereo_to_mono_unsigned_16_': (0x92d41, 58),
    'mix_scaled_swapped_stereo_to_stereo_signed_8_': (0x92d7b, 63),
    'mix_scaled_swapped_stereo_to_stereo_unsigned_8_': (0x92dba, 74),
    'mix_scaled_swapped_stereo_to_stereo_signed_16_': (0x92e04, 65),
    'mix_scaled_swapped_stereo_to_stereo_unsigned_16_': (0x92e45, 76),
    'resample_scaled_swapped_mono_to_mono_signed_8_': (0x92e91, 51),
    'resample_scaled_swapped_mono_to_mono_unsigned_8_': (0x92ec4, 56),
    'resample_scaled_swapped_mono_to_mono_signed_16_': (0x92efc, 57),
    'resample_scaled_swapped_mono_to_mono_unsigned_16_': (0x92f35, 62),
    'resample_scaled_swapped_mono_to_stereo_signed_8_': (0x92f73, 71),
    'resample_scaled_swapped_mono_to_stereo_unsigned_8_': (0x92fba, 76),
    'resample_scaled_swapped_mono_to_stereo_signed_16_': (0x93006, 77),
    'resample_scaled_swapped_mono_to_stereo_unsigned_16_': (0x93053, 82),
    'resample_scaled_swapped_stereo_to_mono_signed_8_': (0x930a5, 59),
    'resample_scaled_swapped_stereo_to_mono_unsigned_8_': (0x930e0, 70),
    'resample_scaled_swapped_stereo_to_mono_signed_16_': (0x93126, 61),
    'resample_scaled_swapped_stereo_to_mono_unsigned_16_': (0x93163, 72),
    'resample_scaled_swapped_stereo_to_stereo_signed_8_': (0x931ab, 77),
    'resample_scaled_swapped_stereo_to_stereo_unsigned_8_': (0x931f8, 88),
    'resample_scaled_swapped_stereo_to_stereo_signed_16_': (0x93250, 79),
    'resample_scaled_swapped_stereo_to_stereo_unsigned_16_': (0x9329f, 90),
    'settransnormal_': (0x999d0, 127),
    'settransreverse_': (0x99a50, 127),
    'nsqrt_': (0x7206e, 60),
    'uninitmultiplayers_': (0x66c4f, 69),
    'deletespritesect_': (0x7601d, 211),
    'deletespritestat_': (0x760f0, 211),
    'insertspritesect_': (0x75ecd, 158),
    'insertspritestat_': (0x75f6b, 158),
    'tolower_': (0x89c7b, 14),
    'float_positive_zero_': (0x995da, 3),
    'float_largest_finite_': (0x995dd, 11),
})

LEAVES['wait_vertical_retrace_'] = (0x66182, 23)
LEAVES['bios_print_screen_'] = (0x79a68, 3)
LEAVES['save_fpu_state_'] = (0x89bf7, 5)
LEAVES['restore_fpu_state_'] = (0x89bfc, 4)
LEAVES['or_masked_byte_'] = (0x991a5, 6)
LEAVES['xor_masked_byte_'] = (0x991bb, 6)
LEAVES['step_planar_left_'] = (0x9783a, 7)
LEAVES['step_planar_right_'] = (0x97833, 7)
LEAVES['step_interleaved_up_'] = (0x977f7, 18)
LEAVES['step_interleaved_down_'] = (0x97809, 18)
LEAVES['scan_two_planes_left_'] = (0x97c42, 4)
LEAVES['scan_two_planes_right_'] = (0x97cf5, 4)
LEAVES['get_audio_data_selector_'] = (0x8c16b, 4)
LEAVES['get_audio_code_selector_'] = (0x8c16f, 4)

LEAVES.update({'main_menu_resume_guard_': (0x5f8f3, 13),
               'main_menu_save_': (0x5f748, 17), 'main_menu_tick_': (0x5f759, 6),
               'main_menu_zero_': (0x5f75f, 2), 'main_menu_initialize_': (0x5f761, 16),
               'main_menu_loop_': (0x5f788, 212),
               'main_menu_actions_': (0x5f884, 111),
               'main_menu_exit_': (0x5f902, 67)})

LEAVES.update({'main_menu_caption_': (0x5f85c, 40), 'main_menu_selection_': (0x5f771, 23)})
DATA_OFFSETS.update({'_loading_caption_columns': 0x12df8, '_loading_caption': 0xd7c,
                     '_game_in_progress': 0x772b8, '_main_menu_selection': 0x1740ec,
                     '_menu_dispatch_active': 0x77118})
FUNCTION_ADDRESSES.update({'draw_menu_text_': 0x386d3, 'main_menu_select_': 0x3a171})

# Consecutive phases of the board-three puzzle; no private context bytes linked.
LEAVES.update({'puzzle_tile_solution_': (0x430ea, 410),
               'puzzle_activate_walls_': (0x43284, 64),
               'puzzle_key_effect_exit_': (0x432c4, 458)})
LEAF_CODE_SLICES.update({
    'puzzle_tile_solution_': ('update_level_sector_puzzle_', 0, 0x19a, 933),
    'puzzle_activate_walls_': ('puzzle_activation_context_', 0x19a, 0x1da, 929),
    'puzzle_key_effect_exit_': ('update_level_sector_puzzle_', 0x1db, 0x3a5, 933),
})
LEAF_SECTION_BRANCHES['update_level_sector_puzzle_'] = (933, 932, {
    0x00d: (bytes.fromhex('0f85'), 0x1db, 0x1da),
    0x12b: (bytes.fromhex('0f8e'), 0x1db, 0x1da),
    0x17c: (bytes.fromhex('75'), 0x1db, 0x1da),
    0x18a: (bytes.fromhex('75'), 0x1db, 0x1da),
    0x198: (bytes.fromhex('75'), 0x1db, 0x1da),
})
DATA_OFFSETS.update({'_sprite_tile': 2113710,
 '_player_x': 372124,
 '_player_y': 372060,
 '_last_tile_step': 75752,
 '_puzzle_solved': 75756,
 '_key_sprite_consumed': 75760,
 '_game_clock': 2653832,
 '_previous_effect_active': 545172,
 '_effect_active': 545176,
 '_effect_x': 545180,
 '_effect_y': 545184,
 '_sector_14_lotag': 2606578,
 '_sector_15_lotag': 2606618,
 '_sector_30_lotag': 2607218,
 '_sector_30_wall_start': 2607184,
 '_sector_30_wall_count': 2607186,
 '_sector_floor_tile': 2606008,
 '_sector_107_floor_tile': 2610288,
 '_sector_108_floor_tile': 2610328,
 '_sector_109_floor_tile': 2610368,
 '_trigger_count': 15334,
 '_trigger_sprite': 487716,
 '_trigger_target': 487718,
 '_wall_tile': 2329584,
 '_transition_marker': 515822,
 '_destination_level': 8256,
 '_destination_x': 502168,
 '_destination_y': 502172})
FUNCTION_ADDRESSES.update({'absolute_long_': 393923,
 'activate_sector_': 165648,
 'remove_sprite_': 69535,
 'spawn_level_effect_': 79698,
 'update_level_sector_puzzle_': 121578,
 'puzzle_activation_context_': 121578})

LEAVES['level_encounter_exit_'] = (0x4390b, 261)
LEAF_CODE_SLICES['level_encounter_exit_'] = ('encounter_exit_context_', 0x3b8, 0x4bd, 1225)
LEAF_CONTEXT_SUFFIXES['encounter_exit_context_'] = bytes.fromhex('81c4b80000005f5e5a595bc3')
LEAF_CONTEXT_LITERALS['encounter_exit_context_'] = (160, '4e2264519143a5033cec5947e5fd0649fd21c0189d3ad8c6ad08a90360a51142', {19: 0, 38: 128}, 0xde8e)
DATA_OFFSETS.update({'_board4_sector_events': 484764, '_ticks_per_step': 502164, '_first_trigger_state': 75764, '_second_trigger_state': 75766, '_encounter_sequence': 75768, '_exit_scan_initialized': 75782, '_exit_sequence': 75784, '_encounter_clock': 75796, '_rotating_sector_count': 515776, '_encounter_position': 469472, '_first_trigger_sprite': 477518, '_second_trigger_sprite': 477520, '_encounter_sprite_index': 514870, '_first_actor_state': 516907, '_second_actor_state': 516908, '_first_actor_kind': 520414, '_second_actor_kind': 520415, '_first_actor_mode': 521917, '_second_actor_mode': 521918, '_exit_scan_index': 545192})
FUNCTION_ADDRESSES.update({'near_encounter_position_': 67088, 'update_sprite_sequence_state_': 66611})

LEAVES.update({'encounter_latch_': (0x437b0, 119),
               'encounter_latch_index_': (0x43827, 10),
               'encounter_latch_zero_': (0x43831, 2),
               'encounter_latch_tag_': (0x43833, 7),
               'encounter_update_second_actor_': (0x43899, 114)})
LEAF_CODE_SLICES.update({
    'encounter_latch_': ('encounter_latch_context_', 0x26e, 0x2e5, 1249),
    'encounter_latch_index_': ('encounter_latch_context_', 0x2e7, 0x2f1, 1249),
    'encounter_latch_zero_': ('encounter_latch_context_', 0x2e5, 0x2e7, 1249),
    'encounter_latch_tag_': ('encounter_latch_context_', 0x2f1, 0x2f8, 1249),
    'encounter_update_second_actor_': ('encounter_latch_context_', 0x35e, 0x3d0, 1249),
})
LEAF_CONTEXT_LITERALS['encounter_latch_context_'] = LEAF_CONTEXT_LITERALS['encounter_exit_context_'][:3]
LEAF_CONTEXT_SUFFIXES['encounter_latch_context_'] = LEAF_CONTEXT_SUFFIXES['encounter_exit_context_']

LEAVES['encounter_spawn_checks_'] = (0x4355b, 149)
LEAF_CODE_SLICES['encounter_spawn_checks_'] = ('encounter_spawn_context_', 0x2c, 0xc1, 1260)
LEAVES['encounter_spawn_sound_'] = (0x435f0, 16)
LEAF_CODE_SLICES['encounter_spawn_sound_'] = ('encounter_spawn_context_', 0xc3, 0xd3, 1260)
LEAVES['encounter_spawn_zero_di_'] = (0x43600, 2)
LEAF_CODE_SLICES['encounter_spawn_zero_di_'] = ('encounter_spawn_context_', 0xc1, 0xc3, 1260)
LEAVES['encounter_spawn_sectors_clock_'] = (0x43602, 110)
LEAF_CODE_SLICES['encounter_spawn_sectors_clock_'] = ('encounter_spawn_context_', 0xd3, 0x141, 1260)
LEAF_CONTEXT_LITERALS['encounter_spawn_context_'] = LEAF_CONTEXT_LITERALS['encounter_latch_context_']
LEAF_CONTEXT_SUFFIXES['encounter_spawn_context_'] = LEAF_CONTEXT_SUFFIXES['encounter_latch_context_']
FUNCTION_ADDRESSES['encounter_spawn_context_'] = 0x1df2e
LEAF_SECTION_BRANCHES['encounter_spawn_context_'] = (1260, 1263, {
    0x36: (bytes.fromhex('0f84'), 0x277, 0x282),
    0x127: (bytes.fromhex('0f8e'), 0x277, 0x282),
})

LEAVES['encounter_loop_one_'] = (0x43670, 5)
LEAF_CODE_SLICES['encounter_loop_one_'] = ('encounter_spawn_loop_context_', 0x141, 0x146, 1266)
LEAVES['encounter_loop_start_'] = (0x4367a, 12)
LEAF_CODE_SLICES['encounter_loop_start_'] = ('encounter_spawn_loop_context_', 0x146, 0x152, 1266)
LEAVES['encounter_loop_position_'] = (0x43686, 15)
LEAF_CODE_SLICES['encounter_loop_position_'] = ('encounter_spawn_loop_context_', 0x152, 0x161, 1266)
LEAVES['encounter_loop_coordinates_'] = (0x43695, 21)
LEAF_CODE_SLICES['encounter_loop_coordinates_'] = ('encounter_spawn_loop_context_', 0x164, 0x179, 1266)
LEAVES['encounter_loop_store_y_'] = (0x436aa, 7)
LEAF_CODE_SLICES['encounter_loop_store_y_'] = ('encounter_spawn_loop_context_', 0x17b, 0x182, 1266)
LEAVES['encounter_loop_y_argument_'] = (0x436b1, 2)
LEAF_CODE_SLICES['encounter_loop_y_argument_'] = ('encounter_spawn_loop_context_', 0x179, 0x17b, 1266)
LEAVES['encounter_loop_spawn_'] = (0x436b3, 52)
LEAF_CODE_SLICES['encounter_loop_spawn_'] = ('encounter_spawn_loop_context_', 0x182, 0x1b6, 1266)
LEAVES['encounter_loop_guard_'] = (0x43799, 23)
LEAF_CODE_SLICES['encounter_loop_guard_'] = ('encounter_spawn_loop_context_', 0x266, 0x27d, 1266)
LEAF_CONTEXT_LITERALS['encounter_spawn_loop_context_'] = LEAF_CONTEXT_LITERALS['encounter_latch_context_']
LEAF_CONTEXT_SUFFIXES['encounter_spawn_loop_context_'] = LEAF_CONTEXT_SUFFIXES['encounter_latch_context_']
FUNCTION_ADDRESSES['encounter_spawn_loop_context_'] = 0x1df2e
LEAF_SECTION_BRANCHES['encounter_spawn_loop_context_'] = (1266, 1263, {
    0x14d: (bytes.fromhex('e9'), 0x266, 0x26b),
    0x277: (bytes.fromhex('0f8e'), 0x152, 0x158),
})

LEAVES['encounter_reset_state_'] = (0x43883, 22)
FUNCTION_ADDRESSES['encounter_exit_scan_'] = 0x1e30b

LEAVES['encounter_actor_state_'] = (0x4383a, 73)
LEAF_CODE_SLICES['encounter_actor_state_'] = ('encounter_actor_context_', 0x2f8, 0x341, 1249)
LEAF_CONTEXT_LITERALS['encounter_actor_context_'] = LEAF_CONTEXT_LITERALS['encounter_latch_context_']
LEAF_CONTEXT_SUFFIXES['encounter_actor_context_'] = LEAF_CONTEXT_SUFFIXES['encounter_latch_context_']
FUNCTION_ADDRESSES['encounter_actor_context_'] = 0x1df2e
LEAF_SECTION_BRANCHES['encounter_actor_context_'] = (1249, 1263, {
    0x302: (bytes.fromhex('75'), 0x35a, 0x36b),
    0x33b: (bytes.fromhex('0f85'), 0x3d0, 0x3dd),
})

LEAVES.update({'encounter_entry_save_': (0x4352e, 5),
               'encounter_initialize_': (0x43534, 39),
               'encounter_release_frame_': (0x43a10, 6),
               'encounter_restore_return_': (0x43a17, 6)})
LEAF_CODE_SLICES.update({
    'encounter_entry_save_': ('encounter_exit_context_', 0, 5, 1225),
    'encounter_initialize_': ('encounter_exit_context_', 5, 44, 1225),
    'encounter_release_frame_': ('encounter_exit_context_', 1213, 1219, 1225),
    'encounter_restore_return_': ('encounter_exit_context_', 1219, 1225, 1225),
})

LEAVES['drawmasks_projection_'] = (0x7228a, 0x167)
LEAF_CODE_SLICES['drawmasks_projection_'] = ('drawmasks_', 0, 0x167, 1259)
DATA_OFFSETS.update({
    '_vidoption': 0x14004, '_spritesortcnt': 0x287e84, '_globalposx': 0x286ad0,
    '_globalposy': 0x286ad4, '_globalposz': 0x286ad8, '_cosviewingrangeglobalang': 0x286ac8,
    '_sinviewingrangeglobalang': 0x286af8, '_cosglobalang': 0x286ac8, '_singlobalang': 0x286af8,
    '_xdimen': 0x140b5, '_spritesx': 0x19c6e0, '_spritesy': 0x19d6e0,
    '_tsprite': 0x2710a0, '_tempsprite': 0x27c048, '_maskwall': 0x19b6e0,
    '_maskwallcnt': 0x28914c, '_thewall': 0x1c2160, '_xb1': 0x1c5160,
    '_xb2': 0x1c3160,
})
FUNCTION_ADDRESSES.update({'spritewallfront_': 0x45527, 'drawsprite_': 0x4d6ca, 'drawmaskwall_': 0x4d193})

LEAVES.update({'capture_header_mode_': (0x71a0f, 154),
               'capture_header_planar_': (0x71aab, 100)})
LEAF_CODE_SLICES.update({
    'capture_header_mode_': ('capture_header_', 1, 0x9b, 259),
    'capture_header_planar_': ('capture_header_', 0x9d, 0x101, 259),
})
DATA_OFFSETS['_pcx_header'] = 0x140d5

LEAVES.update({'capture_open_body_': (0x71976, 140),
               'capture_close_success_': (0x71e71, 22)})
LEAF_CODE_SLICES.update({
    'capture_open_body_': ('capture_open_', 5, 0x91, 149),
    'capture_close_success_': ('capture_close_', 1, 0x17, 25),
})
LEAVES.update({'capture_palette_compare_': (0x71dfd, 6),
               'capture_palette_color_': (0x71e05, 15),
               'capture_palette_zero_': (0x71e16, 8)})
LEAF_CODE_SLICES.update({
    'capture_palette_compare_': ('capture_planar_palette_', 2, 8, 39),
    'capture_palette_color_': ('capture_planar_palette_', 0xa, 0x19, 39),
    'capture_palette_zero_': ('capture_planar_palette_', 0x1c, 0x24, 39),
})
DATA_OFFSETS.update({'_capture_buffer': 0x1dda60, '_capture_palette16': 0x14155})
DATA_OFFSETS['_capture_sequence'] = 0x140d3
FUNCTION_ADDRESSES['_open'] = 0x61368

LEAVES.update({'setgamemode_init_save_': (0x7064e, 2),
               'setgamemode_init_body_': (0x70652, 235)})
LEAF_CODE_SLICES.update({
    'setgamemode_init_save_': ('setgamemode_init_context_', 0, 2, 240),
    'setgamemode_init_body_': ('setgamemode_init_context_', 2, 237, 240),
})
DATA_OFFSETS.update({
    '_setmode_vidoption': 0x2891db,
    '_out_of_memory_message': 0x1af9,
    '_horizlookup2': 0x286aec,
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
})
FUNCTION_ADDRESSES.update({
    'initialize_video_backend_': 0x4a294,
    '_print_diagnostic': 0x40bb4,
})

LEAVES['setgamemode_padded_width_'] = (0x70875, 5)
LEAF_CODE_SLICES['setgamemode_padded_width_'] = ('setgamemode_display_context_', 0x226, 0x22b, 851)
LEAVES['setgamemode_finish_return_'] = (0x70986, 10)
LEAF_CODE_SLICES['setgamemode_finish_return_'] = ('setgamemode_display_context_', 0x349, 0x353, 851)

LEAVES['setgamemode_allocate_planar_'] = (0x70832, 67)
LEAF_CODE_SLICES['setgamemode_allocate_planar_'] = ('setgamemode_display_context_', 0x1e3, 0x226, 851)
LEAVES['setgamemode_allocate_padded_'] = (0x7087a, 27)
LEAF_CODE_SLICES['setgamemode_allocate_padded_'] = ('setgamemode_display_context_', 0x231, 0x24c, 851)
LEAVES['setgamemode_allocate_linear_'] = (0x70895, 21)
LEAF_CODE_SLICES['setgamemode_allocate_linear_'] = ('setgamemode_display_context_', 0x258, 0x26d, 851)
LEAVES['setgamemode_direct_frame_'] = (0x708aa, 15)
LEAF_CODE_SLICES['setgamemode_direct_frame_'] = ('setgamemode_display_context_', 0x26d, 0x27c, 851)
LEAVES['setgamemode_allocate_stereo_'] = (0x708b9, 39)
LEAF_CODE_SLICES['setgamemode_allocate_stereo_'] = ('setgamemode_display_context_', 0x27c, 0x2a3, 851)
LEAVES['setgamemode_allocate_stereo_double_'] = (0x70920, 39)
LEAF_CODE_SLICES['setgamemode_allocate_stereo_double_'] = ('setgamemode_display_context_', 0x2e4, 0x30b, 851)

LEAVES['setgamemode_backend_geometry_'] = (0x707f3, 63)
LEAF_CODE_SLICES['setgamemode_backend_geometry_'] = ('setgamemode_display_context_', 0x1a4, 0x1e3, 851)

LEAVES['palette_lookup_'] = (0x7073d, 19)
LEAF_CODE_SLICES['palette_lookup_'] = ('palette_lookup_', 0, 19, 20)

LEAVES['setgamemode_display_reset_'] = (0x70750, 129)
LEAF_CODE_SLICES['setgamemode_display_reset_'] = ('setgamemode_display_context_', 0x102, 0x183, 851)

# One compiler body implements the four original stencil sums in place.
for _name, _raw in (
        ('ripple_sum_first_', 0x543b0), ('ripple_sum_second_', 0x543db),
        ('ripple_sum_third_', 0x54417), ('ripple_sum_fourth_', 0x5444a)):
    LEAVES[_name] = (_raw, 38)
    LEAF_CODE_SLICES[_name] = ('ripple_neighbor_sum_', 0, 38, 39)
LEAF_CONTEXT_SUFFIXES['ripple_neighbor_sum_'] = b'\xc3'
FUNCTION_ADDRESSES['ripple_neighbor_sum_'] = 0x2edb0

LEAVES['ripple_spawn_limit_phase_'] = (0x54162, 22)
LEAF_CODE_SLICES['ripple_spawn_limit_phase_'] = ('ripple_spawn_limit_', 0, 22, 23)
LEAVES['ripple_mask_row_phase_'] = (0x542c8, 32)
LEAF_CODE_SLICES['ripple_mask_row_phase_'] = ('ripple_mask_row_', 0, 32, 33)
LEAF_CONTEXT_SUFFIXES['ripple_spawn_limit_'] = b'\xc3'
LEAF_CONTEXT_SUFFIXES['ripple_mask_row_'] = b'\xc3'
FUNCTION_ADDRESSES.update({'ripple_spawn_limit_': 0x2eb62, 'ripple_mask_row_': 0x2ecc8})
LEAF_SECTION_BRANCHES['ripple_spawn_limit_'] = (23, 23, {15: (b'\x7c', 22, 22)})
LEAF_SECTION_BRANCHES['ripple_mask_row_'] = (33, 33, {
    5: (b'\xeb', 23, 23), 28: (b'\x7f', 7, 7)})

LEAVES['ripple_border_initialize_'] = (0x542f1, 2)
LEAF_CODE_SLICES['ripple_border_initialize_'] = ('ripple_border_columns_', 3, 5, 47)
LEAVES['ripple_border_loop_'] = (0x542f3, 38)
LEAF_CODE_SLICES['ripple_border_loop_'] = ('ripple_border_columns_', 7, 45, 47)
LEAF_CONTEXT_SUFFIXES['ripple_border_columns_'] = bytes.fromhex('5ec3')
# The loop is placed two bytes earlier after omitting the identity copy.
FUNCTION_ADDRESSES['ripple_border_columns_'] = 0x2ecec
DATA_OFFSETS['_ripple_buffer'] = 0x6331c
LEAF_SECTION_BRANCHES['ripple_border_columns_'] = (47, 47, {
    7: (b'\xeb', 37, 37), 43: (b'\x7c', 9, 9)})

for _alias, _raw, _length, _public in (
        ('ripple_store_y_phase_', 0x541a4, 33, 'ripple_store_y_slot_'),
        ('ripple_floor_phase_', 0x54250, 14, 'ripple_floor_pixel_'),
        ('ripple_advance_radius_phase_', 0x54266, 73, 'ripple_advance_radius_')):
    LEAVES[_alias] = (_raw, _length)
    LEAF_CODE_SLICES[_alias] = (_public, 0, _length, _length + 1)
    LEAF_CONTEXT_SUFFIXES[_public] = b'\xc3'
    FUNCTION_ADDRESSES[_public] = _raw - 0x25600
DATA_OFFSETS.update({'_ripple_origin_y': 0x6773c, '_ripple_origin_x': 0x677bc,
                     '_ripple_radius': 0x62fcc})
LEAF_SECTION_BRANCHES['ripple_floor_pixel_'] = (15, 15, {9: (b'\x7d', 14, 14)})
LEAF_SECTION_BRANCHES['ripple_advance_radius_'] = (74, 74, {19: (b'\x7e', 73, 73)})

for _alias, _raw, _begin, _end in (
        ('ripple_x_draw_', 0x54187, 0, 2),
        ('ripple_x_index_', 0x5418b, 2, 10),
        ('ripple_x_store_', 0x54195, 10, 17)):
    LEAVES[_alias] = (_raw, _end - _begin)
    LEAF_CODE_SLICES[_alias] = ('ripple_store_x_slot_', _begin, _end, 18)
LEAF_CONTEXT_SUFFIXES['ripple_store_x_slot_'] = b'\xc3'
FUNCTION_ADDRESSES['ripple_store_x_slot_'] = 0x2eb87
for _alias, _raw, _begin, _end in (
        ('ripple_corners_load_', 0x54354, 0, 38),
        ('ripple_corners_mask_', 0x5437c, 38, 40),
        ('ripple_corners_store_', 0x54380, 40, 45)):
    LEAVES[_alias] = (_raw, _end - _begin)
    LEAF_CODE_SLICES[_alias] = ('ripple_border_corners_', _begin, _end, 46)
LEAF_CONTEXT_SUFFIXES['ripple_border_corners_'] = b'\xc3'
FUNCTION_ADDRESSES['ripple_border_corners_'] = 0x2ed54

LEAVES['ripple_radial_setup_phase_'] = (0x541dc, 55)
LEAF_CODE_SLICES['ripple_radial_setup_phase_'] = ('ripple_radial_setup_', 0, 55, 56)
LEAF_CONTEXT_SUFFIXES['ripple_radial_setup_'] = b'\xc3'
LEAVES['ripple_radial_sample_phase_'] = (0x5421c, 52)
LEAF_CODE_SLICES['ripple_radial_sample_phase_'] = ('ripple_radial_sample_', 0, 52, 53)
LEAF_CONTEXT_SUFFIXES['ripple_radial_sample_'] = b'\xc3'
LEAVES['ripple_pack_two_bits_'] = (0x54401, 17)
LEAF_CODE_SLICES['ripple_pack_two_bits_'] = ('ripple_pack_two_', 0, 17, 20)
LEAF_CONTEXT_SUFFIXES['ripple_pack_two_'] = b'\xc3'
LEAVES['ripple_pack_two_add_'] = (0x54415, 2)
LEAF_CODE_SLICES['ripple_pack_two_add_'] = ('ripple_pack_two_', 17, 19, 20)
LEAF_CONTEXT_SUFFIXES['ripple_pack_two_'] = b'\xc3'
LEAVES['ripple_pack_third_bits_'] = (0x5443d, 8)
LEAF_CODE_SLICES['ripple_pack_third_bits_'] = ('ripple_pack_third_', 0, 8, 11)
LEAF_CONTEXT_SUFFIXES['ripple_pack_third_'] = b'\xc3'
LEAVES['ripple_pack_third_add_'] = (0x54448, 2)
LEAF_CODE_SLICES['ripple_pack_third_add_'] = ('ripple_pack_third_', 8, 10, 11)
LEAF_CONTEXT_SUFFIXES['ripple_pack_third_'] = b'\xc3'
LEAVES['ripple_pack_fourth_phase_'] = (0x54470, 15)
LEAF_CODE_SLICES['ripple_pack_fourth_phase_'] = ('ripple_pack_fourth_', 0, 15, 16)
LEAF_CONTEXT_SUFFIXES['ripple_pack_fourth_'] = b'\xc3'
DATA_OFFSETS['_ripple_speed'] = 0x630fc

LEAVES['ripple_vertical_head_phase_'] = (0x5431d, 11)
LEAF_CODE_SLICES['ripple_vertical_head_phase_'] = ('ripple_vertical_head_', 0, 11, 12)
LEAF_CONTEXT_SUFFIXES['ripple_vertical_head_'] = b'\xc3'
LEAVES['ripple_vertical_tail_phase_'] = (0x54329, 35)
LEAF_CODE_SLICES['ripple_vertical_tail_phase_'] = ('ripple_vertical_tail_', 0, 35, 36)
LEAF_CONTEXT_SUFFIXES['ripple_vertical_tail_'] = b'\xc3'
LEAVES['ripple_output_row_phase_'] = (0x5438a, 31)
LEAF_CODE_SLICES['ripple_output_row_phase_'] = ('ripple_output_row_', 0, 31, 32)
LEAF_CONTEXT_SUFFIXES['ripple_output_row_'] = b'\xc3'
LEAVES['ripple_store_output_phase_'] = (0x5447f, 8)
LEAF_CODE_SLICES['ripple_store_output_phase_'] = ('ripple_store_output_', 0, 8, 9)
LEAF_CONTEXT_SUFFIXES['ripple_store_output_'] = b'\xc3'

FUNCTION_ADDRESSES['ripple_output_more_words_'] = 0x2edae
FUNCTION_ADDRESSES['ripple_output_more_rows_'] = 0x2ed8a
LEAVES['ripple_mask_begin_phase_'] = (0x542bd, 7)
LEAF_CODE_SLICES['ripple_mask_begin_phase_'] = ('ripple_mask_begin_', 0, 7, 8)
LEAF_CONTEXT_SUFFIXES['ripple_mask_begin_'] = b'\xc3'
LEAVES['ripple_output_word_guard_phase_'] = (0x54487, 10)
LEAF_CODE_SLICES['ripple_output_word_guard_phase_'] = ('ripple_output_word_guard_', 0, 10, 11)
LEAF_CONTEXT_SUFFIXES['ripple_output_word_guard_'] = b'\xc3'
LEAVES['ripple_output_row_increment_phase_'] = (0x54491, 1)
LEAF_CODE_SLICES['ripple_output_row_increment_phase_'] = ('ripple_output_row_increment_', 0, 1, 2)
LEAF_CONTEXT_SUFFIXES['ripple_output_row_increment_'] = b'\xc3'
LEAVES['ripple_mask_row_increment_phase_'] = (0x542e8, 1)
LEAF_CODE_SLICES['ripple_mask_row_increment_phase_'] = ('ripple_output_row_increment_', 0, 1, 2)
LEAVES['ripple_vertical_row_increment_phase_'] = (0x54328, 1)
LEAF_CODE_SLICES['ripple_vertical_row_increment_phase_'] = ('ripple_output_row_increment_', 0, 1, 2)
LEAVES['ripple_output_row_guard_phase_'] = (0x54492, 18)
LEAF_CODE_SLICES['ripple_output_row_guard_phase_'] = ('ripple_output_row_guard_', 0, 18, 19)
LEAF_CONTEXT_SUFFIXES['ripple_output_row_guard_'] = b'\xc3'

LEAVES['ripple_spawn_count_copy_phase_'] = (0x54189, 2)
LEAF_CODE_SLICES['ripple_spawn_count_copy_phase_'] = ('ripple_spawn_countdown_', 0, 2, 5)
LEAF_CONTEXT_SUFFIXES['ripple_spawn_countdown_'] = b'\xc3'
LEAVES['ripple_spawn_count_step_phase_'] = (0x54193, 2)
LEAF_CODE_SLICES['ripple_spawn_count_step_phase_'] = ('ripple_spawn_countdown_', 2, 4, 5)
LEAF_CONTEXT_SUFFIXES['ripple_spawn_countdown_'] = b'\xc3'
LEAVES['ripple_radial_set_slot_phase_'] = (0x541da, 2)
LEAF_CODE_SLICES['ripple_radial_set_slot_phase_'] = ('ripple_radial_set_slot_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_radial_set_slot_'] = b'\xc3'
LEAVES['ripple_radial_load_y_phase_'] = (0x54213, 7)
LEAF_CODE_SLICES['ripple_radial_load_y_phase_'] = ('ripple_radial_load_y_', 0, 7, 8)
LEAF_CONTEXT_SUFFIXES['ripple_radial_load_y_'] = b'\xc3'
LEAVES['ripple_mask_row_reset_phase_'] = (0x542c4, 2)
LEAF_CODE_SLICES['ripple_mask_row_reset_phase_'] = ('ripple_row_reset_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_row_reset_'] = b'\xc3'
LEAVES['ripple_vertical_row_reset_phase_'] = (0x54319, 2)
LEAF_CODE_SLICES['ripple_vertical_row_reset_phase_'] = ('ripple_row_reset_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_row_reset_'] = b'\xc3'
LEAVES['ripple_output_row_reset_phase_'] = (0x5437e, 2)
LEAF_CODE_SLICES['ripple_output_row_reset_phase_'] = ('ripple_row_reset_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_row_reset_'] = b'\xc3'
LEAVES['ripple_tile_register_phase_'] = (0x54160, 2)
LEAF_CODE_SLICES['ripple_tile_register_phase_'] = ('ripple_tile_register_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_tile_register_'] = b'\xc3'
LEAVES['ripple_spawn_step_phase_'] = (0x54178, 5)
LEAF_CODE_SLICES['ripple_spawn_step_phase_'] = ('ripple_spawn_step_', 0, 5, 6)
LEAF_CONTEXT_SUFFIXES['ripple_spawn_step_'] = b'\xc3'
LEAVES['ripple_output_tile_phase_'] = (0x5437a, 2)
LEAF_CODE_SLICES['ripple_output_tile_phase_'] = ('ripple_output_tile_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_output_tile_'] = b'\xc3'
LEAVES['ripple_stencil_center_phase_'] = (0x543ae, 2)
LEAF_CODE_SLICES['ripple_stencil_center_phase_'] = ('ripple_stencil_center_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_stencil_center_'] = b'\xc3'
LEAVES['ripple_stencil_next1_phase_'] = (0x543d6, 3)
LEAF_CODE_SLICES['ripple_stencil_next1_phase_'] = ('ripple_stencil_next1_', 0, 3, 4)
LEAF_CONTEXT_SUFFIXES['ripple_stencil_next1_'] = b'\xc3'
LEAVES['ripple_first_lane_phase_'] = (0x543d9, 2)
LEAF_CODE_SLICES['ripple_first_lane_phase_'] = ('ripple_first_lane_', 0, 2, 3)
LEAF_CONTEXT_SUFFIXES['ripple_first_lane_'] = b'\xc3'
LEAVES['ripple_stencil_next2_phase_'] = (0x54412, 3)
LEAF_CODE_SLICES['ripple_stencil_next2_phase_'] = ('ripple_stencil_next2_', 0, 3, 4)
LEAF_CONTEXT_SUFFIXES['ripple_stencil_next2_'] = b'\xc3'
LEAVES['ripple_stencil_next3_phase_'] = (0x54445, 3)
LEAF_CODE_SLICES['ripple_stencil_next3_phase_'] = ('ripple_stencil_next3_', 0, 3, 4)
LEAF_CONTEXT_SUFFIXES['ripple_stencil_next3_'] = b'\xc3'

FUNCTION_ADDRESSES.update({'ripple_particle_continue_': 0x2ebda, 'ripple_sample_continue_': 0x2ec1c, 'ripple_spawn_continue_': 0x2eb82})
LEAVES['ripple_frame_allocate_phase_'] = (0x5415d, 3)
LEAF_CODE_SLICES['ripple_frame_allocate_phase_'] = ('ripple_seed_and_read_ecx_', 0, 3, 13)
LEAVES['ripple_index_seed_phase_'] = (0x5417d, 3)
LEAF_CODE_SLICES['ripple_index_seed_phase_'] = ('ripple_seed_and_read_ecx_', 3, 6, 13)
LEAVES['ripple_index_commit_phase_'] = (0x541a1, 3)
LEAF_CODE_SLICES['ripple_index_commit_phase_'] = ('ripple_commit_and_read_eax_', 3, 6, 13)
LEAVES['ripple_index_spawn_read_phase_'] = (0x541c5, 3)
LEAF_CODE_SLICES['ripple_index_spawn_read_phase_'] = ('ripple_seed_and_read_ecx_', 6, 9, 13)
LEAVES['ripple_index_radial_seed_phase_'] = (0x541d2, 3)
LEAF_CODE_SLICES['ripple_index_radial_seed_phase_'] = ('ripple_seed_and_read_ecx_', 3, 6, 13)
LEAVES['ripple_index_floor_read_phase_'] = (0x54263, 3)
LEAF_CODE_SLICES['ripple_index_floor_read_phase_'] = ('ripple_commit_and_read_eax_', 6, 9, 13)
LEAVES['ripple_index_step_phase_'] = (0x542af, 3)
LEAF_CODE_SLICES['ripple_index_step_phase_'] = ('ripple_step_and_read_eax_', 6, 9, 11)
LEAVES['ripple_index_radial_read_phase_'] = (0x542b2, 3)
LEAF_CODE_SLICES['ripple_index_radial_read_phase_'] = ('ripple_commit_and_read_eax_', 6, 9, 13)
LEAVES['ripple_frame_release_phase_'] = (0x544a4, 3)
LEAF_CODE_SLICES['ripple_frame_release_phase_'] = ('ripple_seed_and_read_ecx_', 9, 12, 13)
LEAVES['ripple_frame_return_phase_'] = (0x544ad, 1)
LEAF_CODE_SLICES['ripple_frame_return_phase_'] = ('ripple_seed_and_read_ecx_', 12, 13, 13)
LEAVES['ripple_particle_guard_phase_'] = (0x542b5, 8)
LEAF_CODE_SLICES['ripple_particle_guard_phase_'] = ('ripple_particle_guard_', 0, 8, 9)
LEAVES['ripple_sample_step_phase_'] = (0x5425e, 1)
LEAF_CODE_SLICES['ripple_sample_step_phase_'] = ('ripple_sample_step_', 0, 1, 2)
LEAVES['ripple_sample_test_phase_'] = (0x5425f, 2)
LEAF_CODE_SLICES['ripple_sample_test_phase_'] = ('ripple_sample_guard_', 0, 2, 9)
LEAVES['ripple_spawn_test_phase_'] = (0x541c8, 2)
LEAF_CODE_SLICES['ripple_spawn_test_phase_'] = ('ripple_spawn_guard_', 0, 2, 9)
LEAVES['ripple_last_slot_phase_'] = (0x541cc, 6)
LEAF_CODE_SLICES['ripple_last_slot_phase_'] = ('ripple_last_slot_', 0, 6, 7)
LEAVES['ripple_random_x_call_phase_'] = (0x54182, 5)
LEAF_CODE_SLICES['ripple_random_x_call_phase_'] = ('ripple_random_draw_', 0, 5, 8)
LEAVES['ripple_random_y_call_phase_'] = (0x5419c, 5)
LEAF_CODE_SLICES['ripple_random_y_call_phase_'] = ('ripple_random_draw_', 0, 5, 8)
LEAVES['ripple_mask_guard_compare_phase_'] = (0x542e9, 6)
LEAF_CODE_SLICES['ripple_mask_guard_compare_phase_'] = ('ripple_output_row_guard_', 0, 6, 19)
LEAVES['ripple_vertical_guard_compare_phase_'] = (0x5434c, 6)
LEAF_CODE_SLICES['ripple_vertical_guard_compare_phase_'] = ('ripple_output_row_guard_', 0, 6, 19)
LEAF_CONTEXT_BYTES['ripple_seed_and_read_ecx_'] = bytes.fromhex('83ec148904248b0c2483c414c3')
LEAF_CONTEXT_FIXUPS['ripple_seed_and_read_ecx_'] = {}
LEAF_CONTEXT_BYTES['ripple_commit_and_read_eax_'] = bytes.fromhex('83ec14892c248b042483c414c3')
LEAF_CONTEXT_FIXUPS['ripple_commit_and_read_eax_'] = {}
LEAF_CONTEXT_BYTES['ripple_step_and_read_eax_'] = bytes.fromhex('83ec14890424ff0c24ebee')
LEAF_CONTEXT_FIXUPS['ripple_step_and_read_eax_'] = {}
LEAF_CONTEXT_SUFFIXES['ripple_particle_guard_'] = bytes.fromhex('c3')
LEAF_CONTEXT_SUFFIXES['ripple_sample_step_'] = bytes.fromhex('c3')
LEAF_CONTEXT_SUFFIXES['ripple_sample_guard_'] = bytes.fromhex('7cfbe900000000')
LEAF_CONTEXT_SUFFIXES['ripple_spawn_guard_'] = bytes.fromhex('7cf2e900000000')
LEAF_CONTEXT_SUFFIXES['ripple_last_slot_'] = bytes.fromhex('c3')
LEAF_CONTEXT_SUFFIXES['ripple_random_draw_'] = bytes.fromhex('89c3c3')
LEAF_CONTEXT_FIXUPS['ripple_particle_guard_'] = {4: ('ripple_particle_continue_', True)}
LEAF_CONTEXT_FIXUPS['ripple_sample_guard_'] = {5: ('ripple_sample_continue_', True)}
LEAF_CONTEXT_FIXUPS['ripple_spawn_guard_'] = {5: ('ripple_spawn_continue_', True)}
LEAF_CONTEXT_FIXUPS['ripple_last_slot_'] = {1: ('_ripple_count', False)}
LEAF_CONTEXT_FIXUPS['ripple_random_draw_'] = {1: ('random_value_', True)}

FUNCTION_ADDRESSES['ripple_flow_context_'] = 0x2eb57
LEAVES['ripple_control_saved_registers_phase_'] = (0x54157, 6)
LEAF_CODE_SLICES['ripple_control_saved_registers_phase_'] = ('ripple_flow_context_', 0, 6, 865)
LEAVES['ripple_control_branch_2eb80_phase_'] = (0x54180, 2)
LEAF_CODE_SLICES['ripple_control_branch_2eb80_phase_'] = ('ripple_flow_context_', 47, 49, 865)
LEAVES['ripple_control_branch_2ebca_phase_'] = (0x541ca, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ebca_phase_'] = ('ripple_flow_context_', 117, 119, 865)
LEAVES['ripple_control_branch_2ebd5_phase_'] = (0x541d5, 5)
LEAF_CODE_SLICES['ripple_control_branch_2ebd5_phase_'] = ('ripple_flow_context_', 128, 133, 865)
LEAVES['ripple_control_branch_2ec1a_phase_'] = (0x5421a, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ec1a_phase_'] = ('ripple_flow_context_', 195, 197, 865)
LEAVES['ripple_control_branch_2ec61_phase_'] = (0x54261, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ec61_phase_'] = ('ripple_flow_context_', 260, 262, 865)
LEAVES['ripple_control_branch_2ecc6_phase_'] = (0x542c6, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ecc6_phase_'] = ('ripple_flow_context_', 365, 367, 865)
LEAVES['ripple_control_branch_2ecef_phase_'] = (0x542ef, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ecef_phase_'] = ('ripple_flow_context_', 406, 408, 865)
LEAVES['ripple_control_branch_2ed1b_phase_'] = (0x5431b, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ed1b_phase_'] = ('ripple_flow_context_', 450, 452, 865)
LEAVES['ripple_control_branch_2ed52_phase_'] = (0x54352, 2)
LEAF_CODE_SLICES['ripple_control_branch_2ed52_phase_'] = ('ripple_flow_context_', 506, 508, 865)
LEAVES['ripple_control_branch_2ed85_phase_'] = (0x54385, 5)
LEAF_CODE_SLICES['ripple_control_branch_2ed85_phase_'] = ('ripple_flow_context_', 560, 565, 865)
LEAVES['ripple_control_branch_2eda9_phase_'] = (0x543a9, 5)
LEAF_CODE_SLICES['ripple_control_branch_2eda9_phase_'] = ('ripple_flow_context_', 595, 600, 865)
LEAVES['ripple_control_restored_registers_phase_'] = (0x544a7, 6)
LEAF_CODE_SLICES['ripple_control_restored_registers_phase_'] = ('ripple_flow_context_', 858, 864, 865)
LEAF_CONTEXT_SHA256['ripple_flow_context_'] = 'c0078b4844f0f1b673fface7613e70ce1b16493b64bdf03b0d8473702665305b'
LEAF_CONTEXT_SUFFIXES['ripple_flow_context_'] = b'\xc3'
LEAF_CONTEXT_FIXUPS['ripple_flow_context_'] = {20: ('_ripple_count', False, 0), 50: ('random_value_', True, 0), 57: ('_ripple_count', False, 0), 69: ('_ripple_origin_x', False, 0), 74: ('random_value_', True, 0), 84: ('_ripple_count', False, 0), 94: ('_ripple_origin_y', False, 0), 101: ('_ripple_radius', False, 0), 108: ('_ripple_count', False, 0), 120: ('_ripple_count', False, 0), 136: ('_ripple_radius', False, 0), 148: ('_ripple_speed', False, 0), 159: ('_ripple_radius', False, 0), 166: ('_radial_sample_count', False, 0), 180: ('_ripple_origin_x', False, 0), 191: ('_ripple_origin_y', False, 0), 215: ('_radial_x_offsets', False, 0), 223: ('_radial_y_offsets', False, 0), 270: ('_ripple_radius', False, 0), 277: ('_ripple_radius', False, 0), 288: ('_ripple_count', False, 0), 296: ('_ripple_origin_x', False, 0), 303: ('_ripple_radius', False, 0), 310: ('_ripple_origin_y', False, 0), 316: ('_ripple_count', False, 0), 322: ('_ripple_origin_x', False, 0), 328: ('_ripple_radius', False, 0), 334: ('_ripple_origin_y', False, 0), 355: ('_ripple_buffer', False, 133), 424: ('_ripple_buffer', False, 1), 436: ('_ripple_buffer', False, 17028), 485: ('_ripple_buffer', False, 0), 496: ('_ripple_buffer', False, 129), 517: ('_ripple_buffer', False, 0), 530: ('_ripple_buffer', False, 129), 540: ('_ripple_buffer', False, 17028), 556: ('_ripple_buffer', False, 17159), 579: ('_ripple_buffer', False, 0), 851: ('_ripple_frame', False, 0)}
LEAF_SECTION_BRANCHES['ripple_flow_context_'] = (865, 855, {47: (b'\xeb', 112, 110), 117: (b'}', 49, 43), 128: (b'\xe9', 341, 347), 195: (b'\xeb', 258, 264), 260: (b'}', 197, 197), 365: (b'\xeb', 400, 402), 406: (b'|', 367, 369), 450: (b'\xeb', 500, 501), 506: (b'|', 452, 454), 560: (b'\xe9', 837, 827), 595: (b'\xe9', 826, 816)})

# Fixed-size game-state I/O fields, audited against the pinned save format.
SAVE_FIELD_LAYOUT = json.loads((Path(__file__).parent/'data/save-field-layout.json').read_text(encoding='utf-8'))
SAVE_BYTE_LAYOUT = json.loads((Path(__file__).parent/'data/save-byte-layout.json').read_text(encoding='utf-8'))
SAVE_IO_ROUTINES = SAVE_FIELD_LAYOUT['routines'] + SAVE_BYTE_LAYOUT['routines']
DATA_OFFSETS['_save_data_image'] = 0
for _routine in SAVE_IO_ROUTINES:
    _target = 'fread_' if _routine['symbol'] == 'read_game_data' else 'fwrite_'
    for _run in _routine['runs']:
        _public, _phase = _run['public'], _run['phase']
        _start, _size = _run['body_start'], _run['body_size']
        LEAVES[_phase] = (_run['start_file_offset'], _size)
        LEAF_CODE_SLICES[_phase] = (_public, _start, _start+_size, _run['public_size'])
        LEAF_CONTEXT_SHA256[_public] = _run['context_sha256']
        LEAF_CONTEXT_SUFFIXES[_public] = bytes.fromhex(_run['private_suffix'])
        _refs = {int(site): tuple(spec) for site, spec in _run['private_fixups'].items()}
        _stride = _run.get('record_bytes', 22)
        _buffer_site, _call_site = (6, 15) if _stride == 19 else (11, 18)
        for _index, _field in enumerate(_run['records']):
            _refs[_start+_stride*_index+_buffer_site] = ('_save_data_image', False, _field['data_offset'])
            _refs[_start+_stride*_index+_call_site] = (_target, True)
        LEAF_CONTEXT_FIXUPS[_public] = _refs

# Dynamic records and unsigned pointer restoration in the same save format.
SAVE_DYNAMIC_LAYOUT = json.loads((Path(__file__).parent/'data/save-dynamic-layout.json').read_text(encoding='utf-8'))
FUNCTION_ADDRESSES.update({'sprintf_': 0x601f3, 'strcat_': 0x60223,
                           'fopen_': 0x605a2, 'fclose_': 0x60802,
                           'read_crusher_state_': 0x40354, 'write_crusher_state_': 0x4032e})
DATA_OFFSETS.update({'_save_restore_words': 0x1a234, '_save_status_length': 0x7f874,
                     '_save_status_clock': 0x287e88, '_save_status_expiration': 0x7709c,
                     '_save_loaded_status': 0x7aa70, '_save_saved_status': 0x7aa70,
                     '_save_loaded_message': 0x5ef, '_save_saved_message': 0x60f,
                     '_load_slot_format': 0x5dc, '_save_slot_format': 0x5fc,
                     '_load_basename': 0x5e3, '_save_basename': 0x603,
                     '_load_mode': 0x5ec, '_save_mode': 0x60c,
                     '_player_count': 0x13ce0, '_local_player': 0x13ce2,
                     '_first_player': 0x19028a, '_next_player': 0x18fd78,
                     '_player_x': 0x5ad9c, '_player_y': 0x5ad5c})
for _object in SAVE_DYNAMIC_LAYOUT['objects']:
    for _context in _object['contexts']:
        LEAF_CONTEXT_SHA256[_context['public']] = _context['sha256']
        LEAF_CONTEXT_FIXUPS[_context['public']] = {int(site): tuple(spec) for site, spec in _context['fixups'].items()}
        if 'branches' in _context:
            _branch = _context['branches']
            FUNCTION_ADDRESSES[_context['public']] = _branch['public_address']
            LEAF_SECTION_BRANCHES[_context['public']] = (_branch['compiler_size'], _branch['placed_size'],
                {int(site): (bytes.fromhex(spec[0]), spec[1], spec[2]) for site, spec in _branch['sites'].items()})
for _phase in SAVE_DYNAMIC_LAYOUT['phases']:
    _context = next(row for obj in SAVE_DYNAMIC_LAYOUT['objects'] for row in obj['contexts'] if row['public'] == _phase['public'])
    LEAVES[_phase['phase']] = (_phase['address']+0x25600, _phase['end']-_phase['begin'])
    LEAF_CODE_SLICES[_phase['phase']] = (_phase['public'], _phase['begin'], _phase['end'], _context['size'])

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
        raise SystemExit(code_mismatch(args.symbol, code, expected, offset-0x25600))
    verify_leaf_relocations(code, bindings, read_le_fixups(exe)['pointers'], offset-0x25600,
                            code_bindings=code_bindings)
    print(f'PASS: {args.symbol} all {size} bytes and {len(bindings)} LE pointer targets match')
