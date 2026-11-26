"""Verify every reconstructed C span and emit an auditable coverage inventory."""
import argparse
import hashlib
import json
from pathlib import Path
from verify_c_leaf import SAVE_FIELD_LAYOUT, SAVE_BYTE_LAYOUT, SAVE_IO_ROUTINES, SAVE_DYNAMIC_LAYOUT, COMPILER_CONTEXT_OBJECTS, COMPILER_CONTEXT_PHASES
from functools import lru_cache
from verification_diagnostics import code_mismatch
from restoration_registry import switch_groups
from compare_exe import TARGET_SHA256
from le_fixups import read_le_fixups
from match_objects import read_object
from verify_c_leaf import (LEAVES, EMPTY_GAME_HOOKS, DISABLED_MENU_HOOKS, DATA_OFFSETS,
                           CODE_OFFSETS, FUNCTION_ADDRESSES,
                           SPRITE_PATH_BOARDS,
                           bind_leaf_details, verify_leaf_relocations)

OBJECT_NAMES = {'processreservedmessage_': 'netinitc', 'getpacket_head_': 'netinitc', 'getpacket_tail_': 'netinitc', 'sendpacket_': 'sendpack', 'netsend_': 'netsend', 'update_gameplay_head_': 'gamup', 'update_gameplay_tail_': 'gamup', 'draw_status_panel_': 'statpan', 'checksum_gameplay_state_': 'gamesum', 'process_gameplay_frame_': 'procfram', 'update_menu_selection_': 'menusel', 'dispatch_actor_update_': 'actdisp', 'update_actor_common_': 'actcomm', 'activate_crush_sector_': 'crushact', 'deletesprite_': 'sprlists', 'loadtables_': 'loadtabl', 'changespritesect_': 'sprchang', 'changespritestat_': 'sprchang', 'animation_prestep_': 'prestep', 'audio_volume_': 'avol', 'move_listed_sprite_': 'movelist', 'netuninitconnection_': 'netuninc', 'convalloc32_': 'convallo', 'uninstallbicomhandlers_': 'uninstbc', 'add_listed_sprite_': 'add', 'insertsprite_': 'insert', 'spawn_template_sprite_': 'spawn', 'getpalookup_': 'pallook', 'netinitconnection_': 'netinitc', 'lookup_type_index_': 'reclook', 'transmaskvline_': 'transcol', 'lookup_record_value_': 'reclook', 'stereoinit_': 'stereo', 'stereoblit_': 'stereo', 'remove_listed_sprite_': 'remove', 'clippoly4_': 'clippoly', 'clipinsideboxline_': 'clipline', 'clipinsidebox_': 'clbox',
                'animateoffs_': 'animate', 'getmousevalues_': 'mouse', 'initialize_mouse_': 'mouse',
                'spritewallfront_': 'sprfront', 'updatesector_': 'updsect',
                'alignceilslope_': 'slopes', 'alignflorslope_': 'slopes',
                'allocatepermanenttile_': 'alloctil', 'allocache_': 'allocach',
                'initcache_': 'initcach', 'kfilelength_': 'kfilelen',
                'plotpixel_': 'pixels', 'getpixel_': 'pixels', 'clear2dscreen_': 'editor16',
                'drawline256_': 'editor16', 'drawline16_': 'editor16',
                'qsetmode640350_': 'editor16', 'qsetmode640480_': 'editor16',
                'draw2dgrid_': 'editor16', 'uninitgroupfile_': 'uninitgr',
                'kopen4load_': 'kopen4', 'initgroupfile_': 'initgr', 'reportandexit_': 'report'}
# The cache/archive spans are checked from their jointly compiled prefix.
OBJECT_NAMES.update({'ceilspritescan_': 'ceilspr',
 'ceilspritehline_': 'ceilspr',
 'advance_sequences_': 'advance',
 'addclipline_': 'clipadd',
 'installbicomhandlers_': 'instbico',
 'append_sprite_event_': 'event',
 'comhandler_': 'comhandl',
 'simulateint_': 'simint',
 'activate_initial_crushers_': 'crdisp',
 'find_crush_sector_': 'crdisp',
 'loop_finish_': 'presgrp',
 'getanimationgoal_': 'anim',
 'setanimation_': 'anim',
 'dispatch_ticks_': 'presgrp',
 'dispatch_period_': 'presgrp',
 'dispatch_menu_': 'dispatch',
 'main_step_d_': 'dispatch',
 'game_loop_': 'frameprf',
 'is_crush_sector_': 'crushchk',
 'clear_crush_bank_': 'crushclr',
 'init_object_sequences_': 'initseq',
 'main_load_selection_': 'frameprf',
 'main_run_': 'frameprf',
 'main_': 'startgrp',
 'main_prepare_callback_': 'startgrp',
 'dispatch_prepare_': 'presgrp',
 'dispatch_poll_': 'presgrp',
 'setinterpolation_': 'interp',
 'stopinterpolation_': 'interp',
 'updateinterpolations_': 'interp',
 'dointerpolations_': 'intdraw',
 'restoreinterpolations_': 'intrest',
 'doanimations_': 'animstep',
 'presentation_reset_': 'presinp',
 'presentation_input_': 'presinp'})
from verify_cache_prefix import PUBLICS as CACHE_PUBLICS
from verify_cache_unit import verify as verify_cache_unit
from verify_network_defaults import verify as verify_network_defaults
OBJECT_NAMES.update({symbol: 'cacheunt' for symbol, _ in CACHE_PUBLICS})

AUDIO_LEVELS = ('get_audio_level_a_', 'set_audio_level_a_',
                'get_audio_level_b_', 'set_audio_level_b_')
PALETTE_ADJUST = ('adjust_palette_red_', 'adjust_palette_blue_', 'adjust_palette_green_',
                  'reset_palette_color_scales_')
PALETTE_FADE = ('capture_fade_palette_', 'scale_fade_palette_', 'palette_is_dimmed_',
                'reset_palette_fade_')
PALETTE_FADE_START = ('start_fade_out_', 'start_fade_in_')
FRAME_TIMING = ('reset_frame_timing_', 'print_frame_rate_')
HELP_PAGES = ('run_help_page_menu_', 'run_first_help_pages_', 'run_second_help_pages_',
              'run_help_submenu_')
RASTER_SETUP = (
    'setuptvlineasm_',
    'setupvlineasm_',
    'setupmvlineasm_',
    'fixtransluscence_',
    'setpalookupaddress_',
    'setvlinebpl_',
    'setuptvlineasm2_',
    'setup_sprite_horizontal_masked_',
    'msethlineshift_',
    'tsethlineshift_',
    'setup_sprite_horizontal_unrolled_',
)
SOUND_STOP = ('stop_sound_', 'stop_sprite_sound_')
COMMAND_LINE_HELP = ('print_command_line_help_', 'print_video_settings_help_')
VIDEO_TEXT = ('print_video_text_', 'print_video_text_at_', 'initialize_video_console_')
PLAYER_DISTANCE = ('player_within_512_xy_', 'player_within_4096_xy_')
TEXT_ARCHIVE = ('select_item_', 'open_text_archive_')
CONFIG_REMOVERS = ('remove_configuration_key_', 'remove_configuration_section_')
DOS_MEMORY = ('allocate_dos_memory_', 'free_video_dos_memory_')
RUNTIME_HELPERS = ('graphics_stack_limit_', 'labs_', 'min_', 'tell_')
RANDOM_NUMBER = ('initrandnext_', 'rand_', 'srand_')
ERROR_SETTERS = ('set_permission_denied_', 'set_errno_', 'set_bad_address_',
                 'set_runtime_error_', 'bad_file_descriptor_')
GRAPHICS_DEVICE = ('initialize_graphics_device_', 'shutdown_graphics_device_',
                   'begin_graphics_device_', 'end_graphics_device_')
GRAPHICS_STATE = (
    'set_absolute_graphics_pair_',
    'set_nonzero_graphics_pair_',
    'set_graphics_word_a5_',
    'set_graphics_word_ab_',
    'set_graphics_pair_ad_',
    'get_drawing_color_',
    'set_drawing_color_',
    'replace_drawing_color_',
    'get_background_color_',
)
MENU_STATE = ('get_audio_flag_a_', 'get_audio_flag_b_', 'reset_menu_animation_clock_',
              'video_mode_name_')
CRUSHER_SAVE = ('write_crusher_state_', 'read_crusher_state_', 'is_first_player_sprite_')
MENU_ENTRIES = ('initialize_demo_menu_', 'initialize_difficulty_menu_', 'initialize_audio_menu_',
                'initialize_control_limits_menu_', 'initialize_help_menus_',
                'initialize_mouse_menus_', 'initialize_key_menu_', 'reset_key_bindings_')
OBJECT_NAMES.update({symbol: 'audlevel' for symbol in AUDIO_LEVELS})
OBJECT_NAMES.update({symbol: 'paladj' for symbol in PALETTE_ADJUST})
OBJECT_NAMES.update({symbol: 'palfade' for symbol in PALETTE_FADE})
OBJECT_NAMES.update({symbol: 'palstart' for symbol in PALETTE_FADE_START})
OBJECT_NAMES['tolower_'] = 'asciilow'
OBJECT_NAMES.update({'float_positive_zero_': 'fltedge', 'float_largest_finite_': 'fltedge'})
OBJECT_NAMES['palette_fade_in_entry_'] = 'fadeinen'
OBJECT_NAMES.update({symbol: 'frmtime' for symbol in FRAME_TIMING})
OBJECT_NAMES.update({symbol: 'helppage' for symbol in HELP_PAGES})
OBJECT_NAMES.update({symbol: 'lvlstub' for symbol in EMPTY_GAME_HOOKS})
OBJECT_NAMES.update({symbol: 'menuhook' for symbol in DISABLED_MENU_HOOKS})
OBJECT_NAMES.update({symbol: 'raspatch' for symbol in RASTER_SETUP})
OBJECT_NAMES.update({'deletespritesect_': 'sprlists', 'deletespritestat_': 'sprlists'})
OBJECT_NAMES['initspritelists_'] = 'initspr'
OBJECT_NAMES['wait_vertical_retrace_'] = 'waitret'
OBJECT_NAMES.update({'nsqrt_': 'nsqrt', 'uninitmultiplayers_': 'netstop'})
SPRITE_INSERTION = ('insertsprite_', 'insertspritesect_', 'insertspritestat_')
OBJECT_NAMES.update({symbol: 'insert' for symbol in SPRITE_INSERTION})
SPRITE_COLUMN_SETUP = ('setupspritevline_', 'msetupspritevline_', 'tsetupspritevline_')
OBJECT_NAMES.update({symbol: 'sprsetup' for symbol in SPRITE_COLUMN_SETUP})
OBJECT_NAMES['setup_sprite_horizontal_reverse_'] = 'revspan'
OBJECT_NAMES['fputc_'] = 'rtfputc'
OBJECT_NAMES['sectorofwall_'] = 'sectwall'
OBJECT_NAMES['rebuild_view_angle_table_'] = 'viewang'
OBJECT_NAMES['setview_'] = 'setview'
OBJECT_NAMES['setaspect_'] = 'setview'
OBJECT_NAMES['initksqrt_'] = 'sqrtinit'
OBJECT_NAMES['pushmove_'] = 'pushmove'
OBJECT_NAMES['copytilepiece_'] = 'tilecopy'
OBJECT_NAMES['preparemirror_'] = 'prepmir'
OBJECT_NAMES['load_art_files_'] = 'loadart'
OBJECT_NAMES['run_key_binding_menu_'] = 'keybind'
ENV_COPY_ENTRIES = (
    'env_scan_strings_',
    'env_allocate_and_copy_',
    'env_finish_vector_',
    'env_free_strings_',
    'env_restore_registers_',
)
OBJECT_NAMES.update(dict.fromkeys(ENV_COPY_ENTRIES, 'envcopy'))
OBJECT_NAMES['wallmost_'] = 'wallmost'
OBJECT_NAMES['wallmost_flat_height_'] = 'wallmost'
OBJECT_NAMES['wallmost_floor_height_'] = 'wallmost'
OBJECT_NAMES['wallmost_slope_geometry_'] = 'wallmost'
OBJECT_NAMES['wallmost_slope_length_'] = 'wallmost'
OBJECT_NAMES['wallmost_left_ray_'] = 'wallmost'
OBJECT_NAMES['wallmost_slope_coefficient_'] = 'wallmost'
OBJECT_NAMES['wallmost_left_height_'] = 'wallset'
OBJECT_NAMES['wallmost_right_ray_'] = 'wallset'
OBJECT_NAMES['wallmost_right_height_'] = 'wallset'
OBJECT_NAMES['wallmost_clip_flags_'] = 'wallset'
OBJECT_NAMES['wallmost_fill_clipped_'] = 'wallclip'
OBJECT_NAMES['wallmost_check_bottom_'] = 'wallclip'
OBJECT_NAMES['wallmost_clip_top_'] = 'wallclip'
OBJECT_NAMES['wallmost_fill_top_'] = 'wallclip'
OBJECT_NAMES['wallmost_clip_bottom_'] = 'wallclip'
OBJECT_NAMES['wallmost_fill_bottom_'] = 'wallclip'
OBJECT_NAMES['wallmost_interpolate_'] = 'wallclip'
OBJECT_NAMES['wallmost_read_flags_'] = 'wallclip'
OBJECT_NAMES['wallmost_restore_'] = 'wallclip'
OBJECT_NAMES['owallmost_'] = 'owallmst'
OBJECT_NAMES['owallmost_fill_clipped_'] = 'owallmst'
OBJECT_NAMES['owallmost_check_bottom_'] = 'owallmst'
OBJECT_NAMES['owallmost_clip_top_'] = 'owallmst'
OBJECT_NAMES['owallmost_fill_top_'] = 'owallmst'
OBJECT_NAMES['owallmost_clip_bottom_'] = 'owallmst'
OBJECT_NAMES['owallmost_fill_bottom_'] = 'owallmst'
OBJECT_NAMES['owallmost_interpolate_'] = 'owallmst'
OBJECT_NAMES['owallmost_return_'] = 'owallmst'
OBJECT_NAMES['ceilscan_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_check_height_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_animate_tile_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_require_tile_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_touch_tile_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_flat_axes_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_wall_axes_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_wall_length_'] = 'ceilentr'
OBJECT_NAMES['ceilscan_project_axes_'] = 'ceilentr'
OBJECT_NAMES['grouscan_wall_vector_'] = 'grougeom'
OBJECT_NAMES['grouscan_wall_length_'] = 'grougeom'
OBJECT_NAMES['grouscan_inverse_length_'] = 'grougeom'
OBJECT_NAMES['grouscan_scale_wall_vector_'] = 'grougeom'
OBJECT_NAMES['grouscan_'] = 'grouentr'
OBJECT_NAMES['grouscan_select_floor_'] = 'grouentr'
OBJECT_NAMES['grouscan_select_tile_'] = 'grouentr'
OBJECT_NAMES['grouscan_require_tile_'] = 'grouentr'
OBJECT_NAMES['grouscan_touch_tile_'] = 'grouentr'
OBJECT_NAMES['florscan_'] = 'florentr'
OBJECT_NAMES['florscan_check_height_'] = 'florentr'
OBJECT_NAMES['florscan_touch_tile_'] = 'florentr'
OBJECT_NAMES['florscan_load_tile_'] = 'florentr'
OBJECT_NAMES['florscan_set_visibility_'] = 'florentr'
OBJECT_NAMES['florscan_flat_axes_'] = 'florentr'
OBJECT_NAMES['florscan_wall_axes_'] = 'florentr'
OBJECT_NAMES['florscan_wall_length_'] = 'florentr'
OBJECT_NAMES['florscan_project_axes_'] = 'florentr'
OBJECT_NAMES['florscan_texture_'] = 'flortail'
OBJECT_NAMES['florscan_flip_x_'] = 'flortail'
OBJECT_NAMES['florscan_flip_y_'] = 'flortail'
OBJECT_NAMES['florscan_begin_spans_'] = 'flortail'
OBJECT_NAMES['florscan_scan_column_'] = 'flortail'
OBJECT_NAMES['florscan_empty_column_'] = 'flortail'
OBJECT_NAMES['florscan_test_column_'] = 'flortail'
OBJECT_NAMES['florscan_finish_spans_'] = 'flortail'
OBJECT_NAMES['ceilscan_texture_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_flip_x_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_flip_y_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_begin_spans_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_scan_column_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_empty_column_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_test_column_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_finish_spans_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_run_timer_'] = 'ceiltail'
OBJECT_NAMES['ceilscan_restore_stack_'] = 'ceiltail'
OBJECT_NAMES['hline_'] = 'hline'
OBJECT_NAMES['hline_planar_'] = 'hline'
OBJECT_NAMES['hline_next_plane_'] = 'hline'
OBJECT_NAMES['clearview_'] = 'clrview'
OBJECT_NAMES['clearview_stereo_row_'] = 'clrview'
OBJECT_NAMES['clearview_check_stereo_row_'] = 'clrview'
OBJECT_NAMES['clearview_check_planar_'] = 'clrview'
OBJECT_NAMES['clearview_linear_'] = 'clrview'
OBJECT_NAMES['clearview_service_timer_'] = 'clrview'
OBJECT_NAMES['clearallviews_'] = 'clrviews'
OBJECT_NAMES['initialize_board_routes_'] = 'routedsp'
OBJECT_NAMES['route_actor_toward_target_'] = 'routedsp'
PAN_ENTRIES = (
    'update_sector_panning_',
    'pan_prepare_sector_',
    'pan_floor_cases_',
    'pan_ceiling_cases_',
    'pan_advance_',
    'pan_ceiling_y_normal_',
)
OBJECT_NAMES.update(dict.fromkeys(PAN_ENTRIES, 'sectpan'))
ROUTE_SECTOR_ENTRIES = (
    'resolve_route_sectors_',
    'route_start_zone_scan_',
    'resolve_route_waypoint_',
    'route_report_bad_waypoint_',
    'store_route_waypoint_sector_',
    'route_check_waypoint_index_',
    'advance_route_zone_',
    'route_check_zone_index_',
)
ROUTE_BOUNDS_ENTRIES = (
    'route_find_actor_sprite_',
    'route_read_bounds_',
    'route_check_bounds_index_',
)
ROUTE_CROSSING_ENTRIES = ('route_read_zone_route_', 'route_cross_zone_')
ROUTE_PATH_ENTRIES = (
    'route_move_to_zone_exit_',
    'route_choose_actor_target_',
    'route_select_target_tail_',
)
OBJECT_NAMES.update(dict.fromkeys(ROUTE_SECTOR_ENTRIES + ROUTE_BOUNDS_ENTRIES + ROUTE_CROSSING_ENTRIES + ROUTE_PATH_ENTRIES, 'routesec'))
OBJECT_NAMES['clearallviews_fill_dwords_'] = 'clrviews'
OBJECT_NAMES['clearallviews_dispatch_backend_'] = 'clrviews'
OBJECT_NAMES['clearallviews_vga_planes_'] = 'clrviews'
OBJECT_NAMES['clearallviews_paged_display_'] = 'clrviews'
OBJECT_NAMES['clearallviews_linear_frame_'] = 'clrviews'
OBJECT_NAMES['clearallviews_port_3cd_banks_'] = 'clrviews'
OBJECT_NAMES['clearallviews_graphics_controller_banks_'] = 'clrviews'
OBJECT_NAMES['clearallviews_crtc_banks_'] = 'clrviews'
OBJECT_NAMES['clearallviews_service_timer_'] = 'clrviews'
OBJECT_NAMES['prepwall_'] = 'prepwall'
OBJECT_NAMES['prepwall_more_columns_'] = 'prepwall'
OBJECT_NAMES['prepwall_last_pair_'] = 'prepwall'
OBJECT_NAMES['prepwall_last_column_'] = 'prepwall'
OBJECT_NAMES['transmaskwallscan_'] = 'transwal'
OBJECT_NAMES['run_palette_fade_'] = 'fadeloop'
OBJECT_NAMES['palette_fade_out_entry_'] = 'fadeloop'
OBJECT_NAMES['completemirror_'] = 'cmpmir'
OBJECT_NAMES['allocate_stream_'] = 'alstream'
OBJECT_NAMES['init_fpu_callbacks_'] = 'spnfpu'
OBJECT_NAMES['check_fpu_callbacks_'] = 'spnfpu'
OBJECT_NAMES['wallfront_geometry_'] = 'walfrnt'
OBJECT_NAMES['wallfront_'] = 'walfrnt'
OBJECT_NAMES['cansee_'] = 'vizporta'
OBJECT_NAMES['draw_ega_text_'] = 'egatext'
OBJECT_NAMES['draw_screen_text_'] = 'scrntxt'
OBJECT_NAMES['rotatesprite_'] = 'rotspr'
OBJECT_NAMES['makepalookup_'] = 'palookmk'
OBJECT_NAMES['getclosestcol_'] = 'closestc'
OBJECT_NAMES['initialize_color_lookup_'] = 'palinit'
OBJECT_NAMES['set_vga_vertical_timing_'] = 'vgavtime'
OBJECT_NAMES['loadtile_'] = 'loadtile'
OBJECT_NAMES['setviewtotile_'] = 'viewtile'
OBJECT_NAMES['setviewback_'] = 'viewback'
OBJECT_NAMES['crt_argument_noop_'] = 'crtnop'
OBJECT_NAMES['timer_vector_noop_'] = 'tvnoop'
OBJECT_NAMES['audio_helper_region_end_'] = 'tvnoop'
OBJECT_NAMES['DISCARD_STACK_CHECK_ARGUMENT'] = 'discstk'
OBJECT_NAMES.update({symbol: 'gfxstep' for symbol in (
    'step_up_80_', 'step_down_80_', 'step_up_40_', 'step_down_40_',
)})
OBJECT_NAMES.update({symbol: 'gfxbyte' for symbol in (
    'step_byte_up_320_', 'step_byte_down_320_', 'step_byte_left_',
    'step_byte_right_', 'step_byte_up_100_', 'step_byte_down_100_',
)})
OBJECT_NAMES['getzsofslope_'] = 'slopepr'
OBJECT_NAMES['setbrightness_'] = 'setbrigh'
OBJECT_NAMES['rintersect_'] = 'rinterc'
OBJECT_NAMES['apply_projectile_hit_'] = 'prjhit'
OBJECT_NAMES['move_actor_'] = 'actmove'
OBJECT_NAMES['update_proximity_sprites_'] = 'proxupd'
OBJECT_NAMES['update_sprite_sequence_state_'] = 'sprseq'
OBJECT_NAMES['spawn_counted_player_effect_'] = 'peffspn'
OBJECT_NAMES['check_teleport_terminals_'] = 'telterm'
OBJECT_NAMES['update_board_7_script_'] = 'board7'
OBJECT_NAMES['update_board_5_script_'] = 'board5'
OBJECT_NAMES['save_build_map_'] = 'savemap'
OBJECT_NAMES['load_build_map_'] = 'loadmap'
OBJECT_NAMES['edit_save_slot_name_'] = 'savename'
OBJECT_NAMES['run_menu_loop_'] = 'menuloop'
OBJECT_NAMES['run_save_game_menu_'] = 'savmenu'
OBJECT_NAMES['run_load_game_menu_'] = 'loadmenu'
OBJECT_NAMES['getceilzofslope_'] = 'slphgt'
OBJECT_NAMES['getflorzofslope_'] = 'slphgt'
OBJECT_NAMES['parse_startup_arguments_'] = 'launch'
OBJECT_NAMES['lintersect_'] = 'linterc'
OBJECT_NAMES['shutdown_video_engine_'] = 'vidshut'
OBJECT_NAMES['readpixel16_'] = 'readpix'
OBJECT_NAMES['squarerotatetile_'] = 'tilerot'
OBJECT_NAMES['rotatepoint_'] = 'rotpoint'
OBJECT_NAMES['nextsectorneighborz_'] = 'neighz'
OBJECT_NAMES['keepaway_'] = 'keepaway'
OBJECT_NAMES['bunchfront_'] = 'bfront'
OBJECT_NAMES['dragpoint_'] = 'dragpt'
OBJECT_NAMES['load_audio_driver_image_'] = 'hmiimage'
OBJECT_NAMES['audio_driver_shutdown_'] = 'hmibuf'
OBJECT_NAMES['allocate_audio_buffer_'] = 'hmibuf'
OBJECT_NAMES['allocate_dpmi_audio_buffer_'] = 'hmidpmi'
OBJECT_NAMES['release_dpmi_audio_buffer_'] = 'hmidpmi'
OBJECT_NAMES['draw_menu_frame_'] = 'mnuframe'
OBJECT_NAMES['draw_menu_text_'] = 'menutext'
OBJECT_NAMES['audio_driver_init_'] = 'drvinit'
OBJECT_NAMES['initialize_audio_backend_'] = 'hmilock'
OBJECT_NAMES['shutdown_audio_backend_'] = 'hmilock'
HMI_SCAN_ROUTINES = (
    'load_detector_command_table_',
    'find_working_audio_driver_',
    'find_next_working_audio_driver_',
    'detect_audio_driver_',
)
OBJECT_NAMES.update(dict.fromkeys(HMI_SCAN_ROUTINES, 'hmiscan'))
OBJECT_NAMES['unload_audio_driver_image_'] = 'hmiimage'
OBJECT_NAMES['draw_menu_selection_marker_'] = 'mkrdraw'
HMINDET_ROUTINES = (
    'audio_detection_noop_',
    'open_audio_detector_',
    'close_audio_detector_',
    'query_detected_audio_parameters_',
    'apply_detected_audio_parameters_',
    'audio_detection_end_',
    'audio_detection_lookup_start_',
    'lookup_audio_detector_value_',
    'audio_detection_lookup_end_',
)
OBJECT_NAMES.update(dict.fromkeys(HMINDET_ROUTINES, 'hmindet'))
HMIWORK_ROUTINES = (
    'allocate_driver_workspace_',
    'release_driver_workspace_',
    'set_workspace_allocate_hook_',
    'set_workspace_release_hook_',
)
OBJECT_NAMES.update(dict.fromkeys(HMIWORK_ROUTINES, 'hmiwork'))
HMICTRL_ROUTINES = (
    'audio_init_noop_',
    'audio_system_init_',
    'audio_system_shutdown_',
    'audio_noop_61816_',
    'audio_noop_6182b_',
    'audio_empty_range_stub_657ed_',
    'audio_empty_range_stub_65ee6_',
    'audio_empty_range_stub_65efb_',
    'audio_empty_range_stub_661b8_',
    'audio_empty_range_stub_661cd_',
    'audio_empty_range_stub_662cc_',
    'audio_empty_range_stub_662e1_',
    'query_driver_interface_',
    'audio_dispatch_noop_',
)
OBJECT_NAMES.update(dict.fromkeys(HMICTRL_ROUTINES, 'hmictrl'))
HMIMARK_ROUTINES = (
    'audio_empty_range_stub_64cfc_',
    'audio_backend_region_start_',
    'audio_empty_range_stub_66b74_',
    'audio_empty_range_stub_67005_',
    'audio_input_region_start_',
    'audio_input_region_end_',
    'audio_output_region_start_',
    'audio_output_region_end_',
)
OBJECT_NAMES.update(dict.fromkeys(HMIMARK_ROUTINES, 'hmimark'))
AUDIO_SAMPLE_ROUTINES = tuple(
    symbol for symbol, (offset, _) in sorted(LEAVES.items(), key=lambda item: item[1][0])
    if 0x876d6 <= offset < 0x88097 and symbol != "close_"
)
OBJECT_NAMES.update(dict.fromkeys(AUDIO_SAMPLE_ROUTINES, 'audctrl'))
OBJECT_NAMES['int386x_'] = OBJECT_NAMES['int386_'] = 'dosint'
PCM_INPUT = tuple(symbol for symbol, (offset, _) in sorted(LEAVES.items(), key=lambda item: item[1][0])
                  if 0x917b9 <= offset < 0x932f9)
OBJECT_NAMES.update(dict.fromkeys(PCM_INPUT, 'pcminput'))
OBJECT_NAMES['output_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_stereo_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_stereo_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_stereo_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_stereo_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_mono_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_mono_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_mono_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_mono_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_stereo_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_stereo_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_stereo_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_swapped_stereo_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_mono_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_mono_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_mono_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_mono_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_stereo_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_stereo_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_stereo_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_stereo_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_mono_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_mono_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_mono_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_mono_unsigned_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_stereo_signed_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_stereo_signed_16_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_stereo_unsigned_8_'] = 'pcmaudio'
OBJECT_NAMES['output_clipped_swapped_stereo_unsigned_16_'] = 'pcmaudio'
TRANSLUCENCY_MODES = ('settransnormal_', 'settransreverse_')
OBJECT_NAMES.update({symbol: 'transmod' for symbol in TRANSLUCENCY_MODES})
OBJECT_NAMES.update({symbol: 'sndstop' for symbol in SOUND_STOP})
OBJECT_NAMES.update({'trigger_crusher_on_entry_': 'crdisp', 'register_pan_sector_': 'panreg'})
OBJECT_NAMES.update({'menu_glyph_tile_': 'menugly',
                     'refresh_inventory_': 'invref', 'load_palette_tables_': 'loadpal',
                     'set_vesa_dac_width_': 'dacwidth',
                     'snapshot_input_': 'inpsnap', 'output_queue_depth_': 'outqueue',
                     'copy_configuration_value_': 'cfgcopy', 'broadcast_network_ready_': 'netready',
                     'write_configuration_boolean_': 'cfgbool'})
OBJECT_NAMES.update({symbol: 'vidtext' for symbol in VIDEO_TEXT})
OBJECT_NAMES['prompt_video_settings_'] = 'prvset'
OBJECT_NAMES.update({symbol: 'itemsel' for symbol in TEXT_ARCHIVE})
OBJECT_NAMES.update({symbol: 'cfgrem' for symbol in CONFIG_REMOVERS})
OBJECT_NAMES.update({symbol: 'plyrdist' for symbol in PLAYER_DISTANCE})
CD_REQUESTS = ('prepare_cd_request_buffers_', 'send_cd_driver_request_', 'request_cd_device_status_',
               'request_cd_device_control_', 'request_cd_disk_info_', 'read_cd_track_start_')
CD_PLAYBACK = ('stop_cd_driver_playback_', 'resume_cd_driver_playback_')
CD_TRACK_NAVIGATION = ('next_cd_track_', 'previous_cd_track_')
OBJECT_NAMES.update({symbol: 'cdcmds' for symbol in CD_REQUESTS})
OBJECT_NAMES.update({symbol: 'cdplay' for symbol in CD_PLAYBACK})
OBJECT_NAMES.update({symbol: 'cdskip' for symbol in CD_TRACK_NAVIGATION})
OBJECT_NAMES['read_cd_track_info_'] = 'cdinfo'
OBJECT_NAMES.update({'simulate_real_mode_interrupt_': 'rmsim', 'initialize_cd_audio_': 'cdinit'})
OBJECT_NAMES['dpmi_real_mode_interrupt_'] = 'dpmirm'
OBJECT_NAMES['dpmi_real_mode_far_call_'] = 'dpmifar'
OBJECT_NAMES.update({'detect_cd_drives_': 'cddetect', 'run_exit_callbacks_': 'exitcb',
                     'spawn_float_sprite_': 'floatnew', 'shutdown_game_audio_': 'audshut',
                     'sound_sample_done_': 'audshut'})
OBJECT_NAMES['move_sprite_'] = 'mvspr'
OBJECT_NAMES['update_float_sprites_'] = 'floupd'
OBJECT_NAMES.update({symbol: 'dosmem' for symbol in DOS_MEMORY})
OBJECT_NAMES.update({symbol: 'rtleaf' for symbol in RUNTIME_HELPERS})
OBJECT_NAMES.update({symbol: 'randcrt' for symbol in RANDOM_NUMBER})
OBJECT_NAMES.update({symbol: 'errno' for symbol in ERROR_SETTERS})
OBJECT_NAMES.update({symbol: 'gfxstate' for symbol in GRAPHICS_STATE})
OBJECT_NAMES.update({symbol: 'gfxdev' for symbol in GRAPHICS_DEVICE})
OBJECT_NAMES.update({'print_runtime_message_': 'rtprint', 'flatten_sprite_': 'flatsp',
                     'crush_sprite_': 'flatsp',
                     'open_configuration_': 'cfgopen'})
OBJECT_NAMES.update({symbol: 'cmdhelp' for symbol in COMMAND_LINE_HELP})
OBJECT_NAMES.update({'setsprite_': 'sprpos',
                     'report_game_error_': 'gamerr',
                     'check_crushed_player_': 'crushply',
                     'audio_source_attenuation_': 'audatten',
                     'audio_pan_': 'audiopan', 'audio_sprite_pan_': 'audiopan'})
OBJECT_NAMES['initialize_sound_slots_'] = 'sndinit'
OBJECT_NAMES['register_exit_callback_'] = 'exitreg'
OBJECT_NAMES['initialize_game_audio_'] = 'audinit'
OBJECT_NAMES.update({symbol: 'state' for symbol in MENU_STATE})
OBJECT_NAMES.update({symbol: 'crushio' for symbol in CRUSHER_SAVE})
OBJECT_NAMES.update({symbol: 'menuinit' for symbol in MENU_ENTRIES})
OBJECT_NAMES['initialize_board_sprite_state_'] = 'boardvp'
OBJECT_NAMES['append_configuration_integer_'] = 'cfgins'
OBJECT_NAMES['load_sound_archive_'] = 'sndindex'
OBJECT_NAMES['initialize_game_subsystems_'] = 'gameinit'
OBJECT_NAMES['initialize_ripple_tables_'] = 'ripinit'
OBJECT_NAMES['adjust_status_value_'] = 'statadj'
OBJECT_NAMES['adjust_player_status_'] = 'adjpstat'
OBJECT_NAMES['parse_configuration_integer_'] = 'cfgparse'
OBJECT_NAMES['replace_configuration_value_'] = 'cfgnumb'
OBJECT_NAMES['load_video_settings_'] = 'vidload'
OBJECT_NAMES['write_configuration_value_'] = 'cfgvalue'
OBJECT_NAMES['append_configuration_section_'] = 'cfgapnd'
OBJECT_NAMES['run_mouse_sensitivity_menu_'] = 'mousesen'
OBJECT_NAMES['run_mouse_button_menu_'] = 'mousebtn'
OBJECT_NAMES['run_control_limits_menu_'] = 'ctlmenu'
OBJECT_NAMES['dispatch_hit_event_'] = 'hitdisp'
OBJECT_NAMES['check_crushed_sprites_'] = 'crushspr'
OBJECT_NAMES['play_crusher_sound_'] = 'crushsnd'
OBJECT_NAMES['trigger_tagged_crushers_'] = 'crushtag'
OBJECT_NAMES['advance_menu_animation_'] = 'menuanim'
OBJECT_NAMES['select_vesa_draw_page_'] = 'vesapage'
OBJECT_NAMES['update_level_effects_'] = 'crushupd'
OBJECT_NAMES['cache_menu_tiles_'] = 'ctile'
OBJECT_NAMES['draw_weapon_overlay_'] = 'weapover'
OBJECT_NAMES['teleport_sprite_'] = 'telepspr'
OBJECT_NAMES['restore_board_actor_sprites_'] = 'boardact'
OBJECT_NAMES['update_projectiles_'] = 'projup'
OBJECT_NAMES['apply_sprite_blast_'] = 'blast'
OBJECT_NAMES['build_palette_fade_tables_'] = 'fadetab'
OBJECT_NAMES['update_palette_fade_'] = 'fadeupd'
OBJECT_NAMES['run_recorded_session_'] = 'playrec'
OBJECT_NAMES['synchronize_network_players_'] = 'netrsync'
OBJECT_NAMES['rotate_network_lead_player_'] = 'netlead'
OBJECT_NAMES['finalize_board_state_'] = 'boardfin'
OBJECT_NAMES['update_sprite_view_'] = 'sprview'
OBJECT_NAMES['initialize_board_entry_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_1_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_2_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_3_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_4_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_5_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_6_'] = 'boardent'
OBJECT_NAMES['board_entry_palette_7_'] = 'boardent'
OBJECT_NAMES['board_entry_default_palette_'] = 'boardent'
OBJECT_NAMES['find_spawn_position_'] = 'spawnpos'
OBJECT_NAMES['resolve_teleport_destination_'] = 'telepdst'
OBJECT_NAMES['sectors_share_portal_'] = 'sectport'
OBJECT_NAMES['draw_status_banner_'] = 'statusbn'
OBJECT_NAMES['draw_small_tile_text_'] = 'drawsml'
OBJECT_NAMES['preload_game_tiles_'] = 'pretiles'
OBJECT_NAMES['confirm_menu_action_'] = 'cfmact'
OBJECT_NAMES['confirm_reset_key_bindings_'] = 'cfmreset'
OBJECT_NAMES['run_mouse_settings_'] = 'mouseset'
OBJECT_NAMES['run_keyboard_settings_'] = 'keyset'
OBJECT_NAMES['validate_key_binding_'] = 'keyvalid'
OBJECT_NAMES['initialize_game_menus_'] = 'gamemenu'
CONFIG_READERS = ('read_configuration_boolean_', 'read_configuration_integer_',
                  'read_configuration_string_')
OBJECT_NAMES.update({symbol: 'cfgread' for symbol in CONFIG_READERS})
OBJECT_NAMES.update({'read_audio_configuration_': 'audiocfg',
                     'parse_hex_digits_': 'hexdigit', 'parse_hexadecimal_': 'hexparse'})
TEXT_VIDEO = ('trim_and_uppercase_', 'restore_text_video_mode_', 'reset_vesa_state_')
OBJECT_NAMES.update({symbol: 'textvid' for symbol in TEXT_VIDEO})
OBJECT_NAMES.update({'find_configuration_key_': 'cfgkey', 'read_configuration_line_': 'cfgkey',
                     'append_configuration_value_': 'cfgkey',
                     'close_configuration_': 'cfgclose'})
GAME_CONFIG = ('load_game_configuration_', 'save_game_configuration_')
SAVE_PREVIEW = ('draw_save_slot_preview_', 'write_save_slot_preview_')
OBJECT_NAMES.update({symbol: 'gamecfg' for symbol in GAME_CONFIG})
OBJECT_NAMES.update({symbol: 'preview' for symbol in SAVE_PREVIEW})
OBJECT_NAMES['read_save_slot_preview_'] = 'readprev'
OBJECT_NAMES['save_video_settings_'] = 'vidset'
DEVICE_STATE = ('stop_cd_music_', 'shutdown_cd_audio_', 'reset_cd_disc_state_',
                'close_text_archive_', 'advance_timer_clock_')
OBJECT_NAMES.update({symbol: 'devices' for symbol in DEVICE_STATE})
GAME_TIMER = ('initialize_game_timer_', 'shutdown_game_timer_')
ENGINE_HEAP = ('engine_malloc_', 'engine_free_')
CRUSH_VIEW = ('schedule_crush_view_kick_', 'apply_crush_view_kick_')
OBJECT_NAMES.update({symbol: 'gametime' for symbol in GAME_TIMER})
OBJECT_NAMES.update({symbol: 'engheap' for symbol in ENGINE_HEAP})
OBJECT_NAMES.update({symbol: 'crushvw' for symbol in CRUSH_VIEW})
OBJECT_NAMES['request_menu_redraw_'] = 'menudraw'

GRAPHICS_AVAILABILITY = ('graphics_available_', 'check_graphics_and_hide_cursor_')
OBJECT_NAMES.update(dict.fromkeys(GRAPHICS_AVAILABILITY, 'gfxavail'))
OBJECT_NAMES['viewport_bitmap_size_'] = 'vpbits'

OBJECT_NAMES.update({'get_errno_address_': 'erraddr', 'get_dos_error_address_': 'erraddr'})

OBJECT_NAMES['scale_mouse_'] = 'mouscale'

OBJECT_NAMES.update(dict.fromkeys(('bitmap_row_bytes_', 'bitmap_rectangle_size_'), 'bitrow'))
GRAPHICS_TEXT_WINDOW = (
    'get_text_window_', 'set_text_window_', 'output_counted_text_', 'get_text_cursor_shape_',
    'get_text_position_', 'get_text_color_', 'set_text_color_', 'set_text_position_', 'clear_screen_',
    'scroll_text_by_rows_', 'set_text_cursor_shape_', 'clear_graphics_display_',
)
OBJECT_NAMES.update(dict.fromkeys(GRAPHICS_TEXT_WINDOW, 'gettxtw'))
OBJECT_NAMES['output_text_string_'] = 'txtstr'
GRAPHICS_FILL_PATTERN = ('get_fill_pattern_', 'set_fill_pattern_')
OBJECT_NAMES.update(dict.fromkeys(GRAPHICS_FILL_PATTERN, 'gfxfill'))
OBJECT_NAMES['get_video_configuration_'] = 'gfxconf'
VIDEO_MODES = (
    'set_video_mode_', 'resolve_video_mode_', 'detect_color_adapter_', 'probe_crtc_cursor_register_',
    'configure_vga_text_font_',
    'set_video_mode_and_text_rows_', 'set_cga_graphics_mode_', 'set_vga_graphics_mode_', 'set_hercules_mode_',
    'set_planar_graphics_mode_', 'bios_mode_supported_', 'reset_video_state_', 'reset_text_display_',
)
OBJECT_NAMES.update(dict.fromkeys(VIDEO_MODES, 'vidmode'))
OBJECT_NAMES['copy_world_bounds_'] = 'wrldbn'
STANDARD_TEXT_ROWS = (
    'set_standard_text_rows_', 'configure_ega_text_font_', 'set_text_rows_', 'initialize_text_pages_',
    'read_graphics_mode_state_', 'initialize_graphics_once_', 'set_bios_cursor_visible_', 'hide_graphics_cursor_',
    'apply_graphics_mode_state_', 'set_and_query_bios_mode_', 'detect_display_adapters_',
    'detect_legacy_display_adapters_', 'program_hercules_graphics_', 'clear_text_region_',
)
OBJECT_NAMES.update(dict.fromkeys(STANDARD_TEXT_ROWS, 'stdrows'))
OBJECT_NAMES['unmap_coordinate_pair_'] = 'coordun'
PALETTE_REPLACEMENT = (
    'replace_palette_entry_', 'replace_palette_', 'set_background_color_', 'upload_palette_entries_',
    'read_palette_entry_', 'write_palette_entry_',
)
OBJECT_NAMES.update(dict.fromkeys(PALETTE_REPLACEMENT, 'palrepl'))

OBJECT_NAMES['show_intro_'] = 'showintr'
OBJECT_NAMES['draw_intro_screen_'] = 'drawintr'
OBJECT_NAMES['draw_animated_intro_'] = 'animint'
OBJECT_NAMES['fatal_runtime_error_'] = 'rootfatl'
OBJECT_NAMES['notify_debugger_'] = 'rtdbg'
OBJECT_NAMES['allocate_stream_buffer_'] = 'strmbuf'
OBJECT_NAMES['fill_buffer_'] = 'rtfillb'
OBJECT_NAMES['fgetc_'] = 'rtfgetc'
OBJECT_NAMES['initialize_standard_streams_'] = 'rtinitst'
OBJECT_NAMES['flush_stream_'] = 'rtflush'
OBJECT_NAMES['write_stream_descriptor_'] = 'dwrite'
OBJECT_NAMES['u32_to_float_'] = 'u32float'
OBJECT_NAMES['i32_to_float_'] = 'i32float'
OBJECT_NAMES['truncate_float_'] = 'flttrunc'
OBJECT_NAMES['truncate_float_zero_'] = 'flttrunc'
OBJECT_NAMES['bios_print_screen_'] = 'codehelp'
OBJECT_NAMES['save_fpu_state_'] = 'spawnfpu'
OBJECT_NAMES['restore_fpu_state_'] = 'spawnfpu'
OBJECT_NAMES['or_masked_byte_'] = 'gfxbits'
OBJECT_NAMES['xor_masked_byte_'] = 'gfxbits'
OBJECT_NAMES['step_planar_left_'] = 'gfxplane'
OBJECT_NAMES['step_planar_right_'] = 'gfxplane'
OBJECT_NAMES['step_interleaved_up_'] = 'gfxplane'
OBJECT_NAMES['step_interleaved_down_'] = 'gfxplane'
OBJECT_NAMES['scan_two_planes_left_'] = 'planar2'
OBJECT_NAMES['scan_two_planes_right_'] = 'planar2'
OBJECT_NAMES['get_audio_data_selector_'] = 'audcmds'
OBJECT_NAMES['get_audio_code_selector_'] = 'audcmds'
OBJECT_NAMES['truncate_magnitude_'] = 'flttrunc'
OBJECT_NAMES['truncate_shift_left_'] = 'flttrunc'
OBJECT_NAMES['truncate_limit_'] = 'flttrunc'
OBJECT_NAMES['float_to_double_'] = 'fltwiden'
CLOSE_STREAMS = ('close_nonstandard_streams_', 'close_streams_from_index_')
OBJECT_NAMES.update(dict.fromkeys(CLOSE_STREAMS, 'rtclidx'))
OBJECT_NAMES['fseek_'] = 'rtfseek'
OBJECT_NAMES['__doopen_'] = 'rtdoopen'
OBJECT_NAMES['copy_path_part_'] = 'pathpart'
OBJECT_NAMES['bounded_far_strlen_'] = 'farstrln'
OBJECT_NAMES['format_padded_hex_'] = 'numfmt'
OBJECT_NAMES['format_fixed_point_'] = 'numfmt'
OBJECT_NAMES['bounded_far_wcslen_'] = 'farstrln'
OBJECT_NAMES['div_'] = 'rtdiv'
OBJECT_NAMES['getenv_'] = 'rtgetenv'
OBJECT_NAMES['system_'] = 'rtsystem'
OBJECT_NAMES['spawnlp_'] = 'rtspawnl'
OBJECT_NAMES['lseek_'] = 'rtlseek'
OBJECT_NAMES['call_float_formatter_'] = 'rtfmtfp'
OBJECT_NAMES['probe_executable_'] = 'rtexepr'
OBJECT_NAMES['prepare_spawn_'] = 'rtprep'
OBJECT_NAMES['build_command_tail_'] = 'rtdostl'
OBJECT_NAMES['build_child_environment_'] = 'spenv'
OBJECT_NAMES['spawnve_'] = 'spawnve'
OBJECT_NAMES['stackavail_'] = 'rtstack'
OBJECT_NAMES['__CMain'] = 'rtcmain'
OBJECT_NAMES.update(dict.fromkeys(('spawn_with_arguments_', 'spawn_with_path_search_'), 'rtspawn'))

OBJECT_NAMES['draw_view_border_'] = 'viewbdf'
OBJECT_NAMES['draw_status_message_'] = 'sttext'

COORDINATE_TRANSFORMS = (
    'map_first_coordinate_', 'map_second_coordinate_', 'map_first_extent_', 'map_second_extent_',
    'recalculate_coordinate_scales_',
)
OBJECT_NAMES.update(dict.fromkeys(COORDINATE_TRANSFORMS, 'coordmap'))
OBJECT_NAMES['query_vesa_mode_'] = 'vesaq'

COORDINATE_PAIRS = ('map_coordinate_pair_', 'map_pair_stack_', 'map_pair_from_pointer_')
OBJECT_NAMES.update(dict.fromkeys(COORDINATE_PAIRS, 'coordpr'))

OBJECT_NAMES['reset_graphics_aspect_settings_'] = 'gfxasp'

GRAPHICS_CLIP_HELPERS = (
    'set_cursor_enabled_', 'draw_clipped_graphics_span_', 'graphics_point_outcode_', 'clamp_point_edge_',
    'fill_graphics_rectangle_', 'draw_clipped_solid_line_', 'show_graphics_cursor_', 'clear_graphics_region_',
    'set_drawing_action_', 'set_graphics_clipping_', 'toggle_graphics_cursor_line_',
    'clip_axis_aligned_line_', 'intersect_clip_edge_',
)
OBJECT_NAMES.update(dict.fromkeys(GRAPHICS_CLIP_HELPERS, 'gfxclip'))

OBJECT_NAMES['disabled_positioned_sound_'] = 'sndstub'

AUDIO_FLAGS = ('set_audio_flag_a_', 'set_audio_flag_b_')
OBJECT_NAMES.update(dict.fromkeys(AUDIO_FLAGS, 'audflags'))

OBJECT_NAMES['restore_keyboard_interrupt_'] = 'kbdrest'
OBJECT_NAMES['install_keyboard_interrupt_'] = 'kbdinst'

DOS_RUNTIME_STATE = ('exchange_runtime_hook_', 'get_psp_selector_')
OBJECT_NAMES.update(dict.fromkeys(DOS_RUNTIME_STATE, 'dosstate'))

OBJECT_NAMES.update({'abs_': 'intabs', '__null_int23_exit_': 'rtirq', '_disable_': 'rtirq', '_enable_': 'rtirq'})

UPPERCASE_STRINGS = ('uppercase_output_', 'strupr_')
OBJECT_NAMES.update(dict.fromkeys(UPPERCASE_STRINGS, 'rtstr'))

OBJECT_NAMES['find_configuration_section_'] = 'cfgsect'

OBJECT_NAMES['toggle_cd_pause_'] = 'togglect'
OBJECT_NAMES['shutdown_serial_network_'] = 'serstop'
OBJECT_NAMES['send_network_join_request_'] = 'joinnet'
OBJECT_NAMES['set_network_socket_'] = 'ipxsock'
OBJECT_NAMES['discard_level_and_load_board_'] = 'disboard'
OBJECT_NAMES['save_level_and_load_board_'] = 'savboard'
OBJECT_NAMES.update({'restore_level_modifications_': 'levrest', 'save_level_modifications_': 'levsave'})
OBJECT_NAMES['play_cd_track_'] = 'cdlaunch'

STRING_FORMAT_HELPERS = ('strncpy_', 'format_integer_', 'strncmp_')
OBJECT_NAMES.update(dict.fromkeys(STRING_FORMAT_HELPERS, 'strmore'))

FORMATTED_OUTPUT = ('ltoa_', 'vsprintf_', 'vsprintf_putc_', 'stream_format_putc_')
OBJECT_NAMES.update(dict.fromkeys(FORMATTED_OUTPUT, 'printfmt'))
OBJECT_NAMES['sprintf_putc_'] = 'printput'
OBJECT_NAMES['sprintf_'] = 'fmtsp'
OBJECT_NAMES['parse_format_flags_'] = 'fmtflags'
OBJECT_NAMES['parse_format_specifier_'] = 'fmtspc'
OBJECT_NAMES['format_engine_'] = 'prtf'
OBJECT_NAMES['convert_format_value_'] = 'fmtconv'
OBJECT_NAMES['search_and_spawn_'] = 'spsearch'
OBJECT_NAMES['write_stream_format_'] = 'streamfm'
OBJECT_NAMES.update(dict.fromkeys(('split_path_', 'path_noop_', 'make_path_'), 'pathutil'))
OBJECT_NAMES['format_unsigned_'] = 'radix'
OBJECT_NAMES['ultoa_'] = 'radix'
ASCII_CASE_COMPARISONS = ('stricmp_', 'strnicmp_')
OBJECT_NAMES.update(dict.fromkeys(ASCII_CASE_COMPARISONS, 'rtstric'))
OBJECT_NAMES['memmove_'] = 'rtmemmv'
OBJECT_NAMES['memset_'] = 'rtmemst'
OBJECT_NAMES['open_'] = 'rtopen'
OBJECT_NAMES['close_file_'] = 'rtclose'
OBJECT_NAMES['__doclose_'] = 'rtdocls'
OBJECT_NAMES['__MkTmpFile_'] = 'rttmp'
DOS_INTERRUPT_VECTORS = ('_dos_getvect_', '_dos_setvect_')
OBJECT_NAMES.update(dict.fromkeys(DOS_INTERRUPT_VECTORS, 'rtgetvec'))
OBJECT_NAMES['__open_flags_'] = 'openflag'
NEAR_HEAP_BOOKKEEPING = ('unlink_near_heap_', 'free_space_at_break_', 'link_and_initialize_heap_')
OBJECT_NAMES.update(dict.fromkeys(NEAR_HEAP_BOOKKEEPING, 'heapul'))
OBJECT_NAMES['release_empty_heaps_'] = 'heapfree'
NEAR_HEAP_RESIZE = (
    'resize_dpmi_heap_', 'resize_heap_target_', 'resize_heap_result_',
    'resize_use_whole_block_', 'resize_return_block_', 'resize_next_heap_',
    'resize_check_heap_', 'resize_return_zero_', 'resize_restore_',
)
OBJECT_NAMES.update(dict.fromkeys(NEAR_HEAP_RESIZE, 'heaprsz'))
NEAR_HEAP_ALLOCATE = (
    'allocate_dpmi_heap_', 'allocate_dpmi_result_', 'allocate_dos_fallback_',
    'allocate_dos_heap_', 'allocate_heap_failure_', 'discard_heap_request_',
    'heap_release_restore_',
)
OBJECT_NAMES.update(dict.fromkeys(NEAR_HEAP_ALLOCATE, 'heapall'))
NEAR_HEAP_GROWTH = (
    'expand_separate_heap_', 'expand_return_zero_', 'expand_check_limit_',
    'expand_allocate_dos_', 'expand_check_block_',
)
OBJECT_NAMES.update(dict.fromkeys(NEAR_HEAP_GROWTH, 'heapgrow'))
DOS_BINARY_MODE = (
    '__set_binary_', 'set_binary_device_get_', 'set_binary_dos_error_',
    'set_binary_device_set_', 'set_binary_success_', 'set_binary_restore_',
)
OBJECT_NAMES.update(dict.fromkeys(DOS_BINARY_MODE, 'dosbin'))
DOS_ACCESS = ('access_', 'access_translate_')
OBJECT_NAMES.update(dict.fromkeys(DOS_ACCESS, 'dosacc'))
TIMER_IRQ_MASK = ('mask_timer_irq_', 'unmask_timer_irq_', 'program_pit_')
AUDIO_COMMAND_WRAPPERS = ('driver_command_5_', 'driver_command_0_', 'read_driver_parameters_', 'driver_command_3_', 'driver_secondary_command_1_', 'driver_configure_secondary_', 'driver_secondary_command_4_', 'driver_secondary_command_2_', 'driver_secondary_command_3_')
WINDOWS_DRIVER_INTERRUPT = ('windows_driver_interrupt_', 'windows_driver_interrupt_stop_')
GET_DRIVER_TABLES = ('get_driver_tables_',)
QUERY_DRIVER_INFO = ('query_dpmi_memory_', 'query_windows_version_')
SET_DRIVER_CALLBACK = ('set_driver_callback_',)
RELEASE_DOS_SELECTOR = ('release_dos_selector_',)
CONFIGURE_FPU = ('configure_fpu_',)
OBJECT_NAMES.update(dict.fromkeys(CONFIGURE_FPU, 'fpu'))
OBJECT_NAMES.update(dict.fromkeys(RELEASE_DOS_SELECTOR, 'rds'))
OBJECT_NAMES.update(dict.fromkeys(SET_DRIVER_CALLBACK, 'sdc'))
OBJECT_NAMES.update(dict.fromkeys(QUERY_DRIVER_INFO, 'qwin'))
OBJECT_NAMES.update(dict.fromkeys(GET_DRIVER_TABLES, 'gdt'))
OBJECT_NAMES.update(dict.fromkeys(WINDOWS_DRIVER_INTERRUPT, 'windi'))
OBJECT_NAMES.update(dict.fromkeys(AUDIO_COMMAND_WRAPPERS, 'audiocmd'))
OBJECT_NAMES.update(dict.fromkeys(TIMER_IRQ_MASK, 'timerirq'))
HEAP_REQUEST_ROUTINES = ('round_heap_request_', 'request_more_heap_')
OBJECT_NAMES.update(dict.fromkeys(HEAP_REQUEST_ROUTINES, 'heaprnd'))
OBJECT_NAMES['select_shell_switch_'] = 'rtshell'
FLOAT_FALLBACK = ('__CommonInit_', 'float_support_missing_')
OBJECT_NAMES.update(dict.fromkeys(FLOAT_FALLBACK, 'fltfback'))

DOS_EXIT_WRAPPERS = ('exit_', '_exit_')
OBJECT_NAMES.update(dict.fromkeys(DOS_EXIT_WRAPPERS, 'exitwrap'))

DOS_RUNTIME_TRANSFERS = (
    'runtime_init_thunk_', 'runtime_fini_thunk_', 'console_exit_thunk_', 'shutdown_all_streams_',
)
OBJECT_NAMES.update(dict.fromkeys(DOS_RUNTIME_TRANSFERS, 'rtthunk'))

SPRITE_PATH_OBJECTS = {name: f'path{index + 1:02}' for index, name in enumerate(SPRITE_PATH_BOARDS)}
OBJECT_NAMES.update(SPRITE_PATH_OBJECTS)

DOS_DESCRIPTOR_MODES = (
    'get_io_mode_', 'set_io_mode_', 'close_descriptor_', 'remove_', 'remove_file_dos_',
    'isatty_', 'read_descriptor_raw_', 'read_console_character_', 'getch_', 'filelength_',
)
OBJECT_NAMES.update(dict.fromkeys(DOS_DESCRIPTOR_MODES, 'iomode'))

STDIO_HELPERS = (
    'toupper_', 'hex_digit_', 'fopen_', 'close_', 'flushall_', 'flush_matching_streams_', '_fsopen_', 'freopen_',
    '__shutdown_stream_', 'fclose_', 'free_recycled_streams_', 'recycle_stream_', 'call_stream_hook_',
    'refill_and_get_character_', 'ftell_', 'detect_terminal_',
)
OBJECT_NAMES.update(dict.fromkeys(STDIO_HELPERS, 'stdwrap'))
OBJECT_NAMES['seek_within_buffer_'] = 'bufseek'
OBJECT_NAMES.update({'atoi_': 'rtatoi', 'strlen_': 'rtstrlen', 'memcpy_': 'rtmemcpy',
                     '_fmemcpy_': 'rtfmemcp'})
DOS_PATH_HELPERS = ('copy_c_string_', 'normalize_separator_', 'dos_find_close_',
                    'dos_find_next_', 'dos_find_first_')
OBJECT_NAMES.update(dict.fromkeys(DOS_PATH_HELPERS, 'dospath'))
OBJECT_NAMES['dos_search_status_'] = 'dossstat'
OBJECT_NAMES['copy_dta_to_caller_'] = 'dosdta'
OBJECT_NAMES['copy_caller_to_dta_'] = 'dosdta'
OBJECT_NAMES['parse_command_line_'] = 'crtparse'
OBJECT_NAMES['apply_mouse_button_binding_'] = 'mouseact'
OBJECT_NAMES.update(dict.fromkeys(('dosret0_', 'translate_exec_result_'), 'doserrno'))
FLOAT_INTEGER_CONVERSIONS = (
    'float_to_i32_', 'float_to_u32_', 'float_to_i16_',
    'float_to_u16_', 'float_to_i8_', 'float_to_u8_',
)
OBJECT_NAMES.update(dict.fromkeys(FLOAT_INTEGER_CONVERSIONS, 'fltint'))
OBJECT_NAMES.update({'set_dos_errno_': 'doserrno', 'restore_cursor_if_enabled_': 'restcur',
                     'find_legacy_palette_index_': 'oldpal', 'build_delimiter_map_': 'delimmap',
                     'strtok_': 'rttok', 'strchr_': 'rtstrchr', 'strstr_': 'strfind',
                     'set_text_video_mode_': 'txtvmode', 'detect_mono_adapter_': 'monodet'})
PLANAR_DRAWING = (
    'begin_planar_drawing_', 'begin_interleaved_planar_drawing_',
    'end_planar_drawing_', 'end_interleaved_planar_drawing_',
)
OBJECT_NAMES.update(dict.fromkeys(PLANAR_DRAWING, 'plndraw'))
VGA_PIXEL_ADDRESS = (
    'address_vga_byte_pixel_', 'finish_banked_planar_drawing_', 'select_graphics_bank_', 'address_banked_byte_pixel_640_',
    'address_banked_byte_pixel_800_', 'address_banked_byte_pixel_1024_', 'address_planar_pixel_800_',
    'address_banked_planar_pixel_1024_', 'address_vga_mono_pixel_', 'address_cga_mono_pixel_',
    'address_hercules_pixel_',
)
OBJECT_NAMES.update(dict.fromkeys(VGA_PIXEL_ADDRESS, 'vgapix'))
PLANAR_PIXEL_ADDRESSES = ('address_planar_pixel_320_', 'address_planar_pixel_640_', 'address_two_plane_pixel_')
OBJECT_NAMES.update(dict.fromkeys(PLANAR_PIXEL_ADDRESSES, 'plan320'))
GRAPHICS_DOS_BUFFER = (
    'free_graphics_dos_buffer_', 'allocate_graphics_dos_buffer_', 'initialize_graphics_memory_windows_',
)
OBJECT_NAMES.update(dict.fromkeys(GRAPHICS_DOS_BUFFER, 'gfxdos'))
BIOS_PALETTE_UPLOAD = ('upload_bios_palette_', 'call_graphics_real_mode_interrupt_')
OBJECT_NAMES.update(dict.fromkeys(BIOS_PALETTE_UPLOAD, 'upal'))
PORT_IO = ('inp_', 'outpw_', 'outp_')
OBJECT_NAMES.update(dict.fromkeys(PORT_IO, 'portio'))

LEAVES.update({
    'timer_module_noop_': (0x8612b, 21),
    'timer_initialize_': (0x86140, 215),
    'timer_shutdown_': (0x86217, 58),
    'timer_register_callback_': (0x86251, 494),
    'timer_set_frequency_': (0x8643f, 360),
    'timer_remove_callback_': (0x865a7, 408),
    'timer_get_frequency_': (0x8673f, 42),
    'timer_set_divisor_': (0x86769, 53),
    'timer_dispatch_callbacks_': (0x8679e, 160),
    'default_timer_callback_': (0x8683e, 26),
    'timer_tail_noop_': (0x86858, 21),
})

TIMER_CALLBACK_ROUTINES = (
    'timer_module_noop_',
    'timer_initialize_',
    'timer_shutdown_',
    'timer_register_callback_',
    'timer_set_frequency_',
    'timer_remove_callback_',
    'timer_get_frequency_',
    'timer_set_divisor_',
    'timer_dispatch_callbacks_',
    'default_timer_callback_',
    'timer_tail_noop_',
)

OBJECT_NAMES.update(dict.fromkeys(TIMER_CALLBACK_ROUTINES, 'timercb'))


OBJECT_NAMES.update({
    'receive_packets_entry_': 'recvpkt',
    'receive_packets_crc_store_': 'recvpkt',
    'receive_packets_delta_': 'recvpkt',
    'receive_packets_buttons_': 'recvpkt',
    'receive_packets_text_': 'recvpkt',
    'receive_packets_ready_': 'recvpkt',
    'receive_packets_ready_test_': 'recvpkt',
    'receive_packets_poll_': 'recvpkt',
    'receive_packets_finish_': 'recvpkt',
})

OBJECT_NAMES.update({'main_menu_resume_guard_': 'mainmenu',
                     'main_menu_save_': 'mainmenu',
                     'main_menu_tick_': 'mainmenu',
                     'main_menu_zero_': 'mainmenu',
                     'main_menu_initialize_': 'mainmenu',
                     'main_menu_caption_': 'menuprep',
                     'main_menu_selection_': 'menuprep',
                     'main_menu_loop_': 'mainmenu',
                     'main_menu_actions_': 'mainmenu',
                     'main_menu_exit_': 'mainmenu',
                     'getpacket_length_order_': 'recvlen',
                     'receive_packets_button_low_': 'recvfrag',
                     'receive_packets_crc_order_': 'recvfrag',
                     'receive_packets_message_delta_': 'recvfrag',
                     'receive_packets_message_clock_': 'recvfrag',
                     'receive_packets_button_high_': 'recvhigh',
                     'receive_packets_ready_head_': 'recvhead',
                     'receive_packets_ready_send_': 'recvsend',
                     'receive_packets_checksums_': 'recvcrc',
                     'receive_packets_parity_': 'recvpar'})

OBJECT_NAMES.update({'puzzle_tile_solution_': 'sectpuz',
                     'puzzle_activate_walls_': 'puzact',
                     'puzzle_key_effect_exit_': 'sectpuz'})

OBJECT_NAMES.update({'capture_header_mode_': 'pcxhdr', 'capture_header_planar_': 'pcxhdr'})
OBJECT_NAMES.update({'capture_open_body_': 'capopen', 'capture_close_success_': 'capclose'})
OBJECT_NAMES.update(dict.fromkeys(('capture_palette_compare_', 'capture_palette_color_',
                                  'capture_palette_zero_'), 'pcxstep'))
OBJECT_NAMES.update(dict.fromkeys(('setgamemode_init_save_', 'setgamemode_init_body_'), 'setinit'))
OBJECT_NAMES.update(dict.fromkeys(('setgamemode_save_tail_', 'setgamemode_backend_guard_',
                                  'setgamemode_stereo_join_'), 'setdisp'))
OBJECT_NAMES['setgamemode_padded_width_'] = 'setdisp'
OBJECT_NAMES['setgamemode_finish_return_'] = 'setdisp'
OBJECT_NAMES['setgamemode_allocate_planar_'] = 'setdisp'
OBJECT_NAMES['setgamemode_allocate_padded_'] = 'setdisp'
OBJECT_NAMES['setgamemode_allocate_linear_'] = 'setdisp'
OBJECT_NAMES['setgamemode_direct_frame_'] = 'setdisp'
OBJECT_NAMES['setgamemode_allocate_stereo_'] = 'setdisp'
OBJECT_NAMES['setgamemode_allocate_stereo_double_'] = 'setdisp'
OBJECT_NAMES['setgamemode_backend_geometry_'] = 'setdisp'
from bind_setgamemode_stereo import PHASES as STEREO_PHASES
OBJECT_NAMES.update(dict.fromkeys(STEREO_PHASES, 'ststate'))
OBJECT_NAMES.update(dict.fromkeys(('setgamemode_backend_dispatch_setup_',
                                  'setgamemode_backend_dispatch_jump_'), 'vmoddsp'))
OBJECT_NAMES['palette_lookup_'] = 'plook'
OBJECT_NAMES['setgamemode_display_reset_'] = 'setdisp'
OBJECT_NAMES['drawmasks_projection_'] = 'drawproj'
OBJECT_NAMES['level_encounter_exit_'] = 'encexit'
OBJECT_NAMES.update(dict.fromkeys(('encounter_entry_save_', 'encounter_initialize_',
                                  'encounter_release_frame_', 'encounter_restore_return_'), 'encexit'))
OBJECT_NAMES.update(dict.fromkeys(('encounter_latch_', 'encounter_latch_index_',
                                  'encounter_latch_zero_', 'encounter_latch_tag_',
                                  'encounter_update_second_actor_'), 'enclatch'))

GROUPS = {
    'stdwrap': (462, STDIO_HELPERS),
    'bufseek': (66, ('seek_within_buffer_',)),
    'rtatoi': (87, ('atoi_',)),
    'rtstrlen': (25, ('strlen_',)),
    'rtmemcpy': (37, ('memcpy_',)),
    'rtfmemcp': (40, ('_fmemcpy_',)),
    'dospath': (93, DOS_PATH_HELPERS),
    'doserrno': (114, ('dosret0_', 'translate_exec_result_', 'set_dos_errno_')),
    'fltint': (60, FLOAT_INTEGER_CONVERSIONS),
    'crtparse': (233, ('parse_command_line_',)),
    'mouseact': (255, ('apply_mouse_button_binding_',)),
    'restcur': (15, ('restore_cursor_if_enabled_',)),
    'oldpal': (37, ('find_legacy_palette_index_',)),
    'delimmap': (62, ('build_delimiter_map_',)),
    'strfind': (194, ('strstr_',)),
    'rttok': (149, ('strtok_',)),
    'rtstrchr': (26, ('strchr_',)),
    'txtvmode': (30, ('set_text_video_mode_',)),
    'monodet': (129, ('detect_mono_adapter_',)),
    'plndraw': (99, PLANAR_DRAWING),
    'vgapix': (712, VGA_PIXEL_ADDRESS),
    'plan320': (190, PLANAR_PIXEL_ADDRESSES),
    'gfxdos': (340, GRAPHICS_DOS_BUFFER),
    'upal': (344, BIOS_PALETTE_UPLOAD),
    'portio': (33, PORT_IO),
    'iomode': (372, DOS_DESCRIPTOR_MODES),
    **{obj: (LEAVES[name][1], (name,)) for name, obj in SPRITE_PATH_OBJECTS.items()},
    'rtthunk': (27, DOS_RUNTIME_TRANSFERS),
    'exitwrap': (46, DOS_EXIT_WRAPPERS),
    'printfmt': (84, FORMATTED_OUTPUT),
    'fltfback': (29, FLOAT_FALLBACK),
    'printput': (19, ('sprintf_putc_',)),
    'fmtsp': (48, ('sprintf_',)),
    'fmtflags': (91, ('parse_format_flags_',)),
    'fmtspc': (307, ('parse_format_specifier_',)),
    'prtf': (641, ('format_engine_',)),
    'fmtconv': (1097, ('convert_format_value_',)),
    'spsearch': (305, ('search_and_spawn_',)),
    'streamfm': (133, ('write_stream_format_',)),
    'pathutil': (341, ('split_path_', 'path_noop_', 'make_path_')),
    'radix': (147, ('format_unsigned_', 'ultoa_')),
    'rtstric': (144, ASCII_CASE_COMPARISONS),
    'rtmemmv': (76, ('memmove_',)),
    'rtmemst': (24, ('memset_',)),
    'rtopen': (36, ('open_',)),
    'rtclose': (104, ('close_file_',)),
    'rtdocls': (137, ('__doclose_',)),
    'rttmp': (105, ('__MkTmpFile_',)),
    'rtgetvec': (95, DOS_INTERRUPT_VECTORS),
    'openflag': (180, ('__open_flags_',)),
    'heapul': (257, NEAR_HEAP_BOOKKEEPING),
    'heaprsz': (259, NEAR_HEAP_RESIZE),
    'heapall': (211, NEAR_HEAP_ALLOCATE),
    'heapgrow': (175, NEAR_HEAP_GROWTH),
    'dosbin': (101, DOS_BINARY_MODE),
    'dosacc': (59, DOS_ACCESS),
    'timerirq': (158, TIMER_IRQ_MASK),
    'audiocmd': (392, AUDIO_COMMAND_WRAPPERS),
    'windi': (106, WINDOWS_DRIVER_INTERRUPT),
    'gdt': (63, GET_DRIVER_TABLES),
    'qwin': (72, QUERY_DRIVER_INFO),
    'sdc': (54, SET_DRIVER_CALLBACK),
    'rds': (46, RELEASE_DOS_SELECTOR),
    'fpu': (39, CONFIGURE_FPU),
    'heaprnd': (122, HEAP_REQUEST_ROUTINES),
    'rtshell': (38, ('select_shell_switch_',)),
    'strmore': (105, STRING_FORMAT_HELPERS),
    'togglect': (140, ('toggle_cd_pause_',)),
    'serstop': (123, ('shutdown_serial_network_',)),
    'joinnet': (236, ('send_network_join_request_',)),
    'ipxsock': (214, ('set_network_socket_',)),
    'disboard': (233, ('discard_level_and_load_board_',)),
    'savboard': (349, ('save_level_and_load_board_',)),
    'levrest': (220, ('restore_level_modifications_',)),
    'levsave': (206, ('save_level_modifications_',)),
    'cdlaunch': (435, ('play_cd_track_',)),
    'cfgsect': (133, ('find_configuration_section_',)),
    'rtstr': (55, UPPERCASE_STRINGS),
    'intabs': (7, ('abs_',)),
    'rtirq': (5, ('__null_int23_exit_', '_disable_', '_enable_')),
    'dosstate': (22, DOS_RUNTIME_STATE),
    'kbdrest': (38, ('restore_keyboard_interrupt_',)),
    'kbdinst': (90, ('install_keyboard_interrupt_',)),
    'audflags': (58, AUDIO_FLAGS),
    'sndstub': (8, ('disabled_positioned_sound_',)),
    'gfxclip': (1080, GRAPHICS_CLIP_HELPERS),
    'gfxasp': (96, ('reset_graphics_aspect_settings_',)),
    'coordpr': (126, COORDINATE_PAIRS),
    'coordmap': (370, COORDINATE_TRANSFORMS),
    'vesaq': (73, ('query_vesa_mode_',)),
    'viewbdf': (201, ('draw_view_border_',)),
    'sttext': (197, ('draw_status_message_',)),
    'showintr': (140, ('show_intro_',)),
    'drawintr': (207, ('draw_intro_screen_',)),
    'animint': (319, ('draw_animated_intro_',)),
    'rootfatl': (29, ('fatal_runtime_error_',)),
    'rtdbg': (38, ('notify_debugger_',)),
    'strmbuf': (119, ('allocate_stream_buffer_',)),
    'rtfillb': (171, ('fill_buffer_',)),
    'rtfgetc': (137, ('fgetc_',)),
    'rtinitst': (120, ('initialize_standard_streams_',)),
    'rtflush': (191, ('flush_stream_',)),
    'rtclidx': (87, CLOSE_STREAMS),
    'rtfseek': (252, ('fseek_',)),
    'rtdoopen': (200, ('__doopen_',)),
    'pathpart': (68, ('copy_path_part_',)),
    'farstrln': (71, ('bounded_far_strlen_', 'bounded_far_wcslen_')),
    'numfmt': (316, ('format_padded_hex_', 'format_fixed_point_')),
    'rtdiv': (56, ('div_',)),
    'rtgetenv': (90, ('getenv_',)),
    'rtsystem': (105, ('system_',)),
    'rtspawnl': (22, ('spawnlp_',)),
    'rtlseek': (65, ('lseek_',)),
    'rtfmtfp': (7, ('call_float_formatter_',)),
    'rtexepr': (31, ('probe_executable_',)),
    'rtprep': (51, ('prepare_spawn_',)),
    'rtdostl': (85, ('build_command_tail_',)),
    'spenv': (312, ('build_child_environment_',)),
    'spawnve': (766, ('spawnve_',)),
    'rtstack': (9, ('stackavail_',)),
    'rtcmain': (79, ('__CMain',)),
    'rtspawn': (44, ('spawn_with_arguments_', 'spawn_with_path_search_')),
    'bitrow': (123, ('bitmap_row_bytes_', 'bitmap_rectangle_size_')),
    'gettxtw': (1055, GRAPHICS_TEXT_WINDOW),
    'txtstr': (61, ('output_text_string_',)),
    'gfxfill': (158, GRAPHICS_FILL_PATTERN),
    'gfxconf': (34, ('get_video_configuration_',)),
    'vidmode': (2274, VIDEO_MODES),
    'wrldbn': (35, ('copy_world_bounds_',)),
    'stdrows': (2182, STANDARD_TEXT_ROWS),
    'coordun': (327, ('unmap_coordinate_pair_',)),
    'palrepl': (608, PALETTE_REPLACEMENT),
    'mouscale': (61, ('scale_mouse_',)),
    'erraddr': (12, ('get_errno_address_', 'get_dos_error_address_')),
    'gfxavail': (72, GRAPHICS_AVAILABILITY),
    'vpbits': (64, ('viewport_bitmap_size_',)),
    'audlevel': (92, AUDIO_LEVELS),
    'paladj': (47, PALETTE_ADJUST),
    'palfade': (119, PALETTE_FADE),
    'palstart': (107, PALETTE_FADE_START),
    'asciilow': (14, ('tolower_',)),
    'fltedge': (14, ('float_positive_zero_', 'float_largest_finite_')),
    'fadeinen': (38, ('palette_fade_in_entry_',)),
    'frmtime': (145, FRAME_TIMING),
    'helppage': (344, HELP_PAGES),
    'raspatch': (504, RASTER_SETUP),
    'initspr': (213, ('initspritelists_',)),
    'nsqrt': (60, ('nsqrt_',)),
    'netstop': (69, ('uninitmultiplayers_',)),
    'insert': (337, SPRITE_INSERTION),
    'sprsetup': (138, SPRITE_COLUMN_SETUP),
    'revspan': (87, ('setup_sprite_horizontal_reverse_',)),
    'rtfputc': (164, ('fputc_',)),
    'sectwall': (170, ('sectorofwall_',)),
    'viewang': (123, ('rebuild_view_angle_table_',)),
    'setview': (631, ('setview_', 'setaspect_')),
    'sqrtinit': (144, ('initksqrt_',)),
    'pushmove': (999, ('pushmove_',)),
    'tilecopy': (336, ('copytilepiece_',)),
    'prepmir': (712, ('preparemirror_',)),
    'loadart': (752, ('load_art_files_',)),
    'routesec': (961, ROUTE_SECTOR_ENTRIES + ROUTE_BOUNDS_ENTRIES + ROUTE_CROSSING_ENTRIES + ROUTE_PATH_ENTRIES),
    'wallmost': (646, (
        'wallmost_',
        'wallmost_flat_height_',
        'wallmost_floor_height_',
        'wallmost_slope_geometry_',
        'wallmost_slope_length_',
        'wallmost_left_ray_',
        'wallmost_slope_coefficient_',
    )),
    'wallset': (817, (
        'wallmost_left_height_',
        'wallmost_right_ray_',
        'wallmost_right_height_',
        'wallmost_clip_flags_',
    )),
    'wallclip': (1053, (
        'wallmost_fill_clipped_',
        'wallmost_check_bottom_',
        'wallmost_clip_top_',
        'wallmost_fill_top_',
        'wallmost_clip_bottom_',
        'wallmost_fill_bottom_',
        'wallmost_interpolate_',
        'wallmost_read_flags_',
        'wallmost_restore_',
    )),
    'owallmst': (1236, (
        'owallmost_',
        'owallmost_fill_clipped_',
        'owallmost_check_bottom_',
        'owallmost_clip_top_',
        'owallmost_fill_top_',
        'owallmost_clip_bottom_',
        'owallmost_fill_bottom_',
        'owallmost_interpolate_',
        'owallmost_return_',
    )),
    'sectpan': (262, PAN_ENTRIES),
    'ceilentr': (871, (
        'ceilscan_',
        'ceilscan_check_height_',
        'ceilscan_animate_tile_',
        'ceilscan_require_tile_',
        'ceilscan_touch_tile_',
        'ceilscan_flat_axes_',
        'ceilscan_wall_axes_',
        'ceilscan_wall_length_',
        'ceilscan_project_axes_',
    )),
    'grougeom': (279, (
        'grouscan_wall_vector_',
        'grouscan_wall_length_',
        'grouscan_inverse_length_',
        'grouscan_scale_wall_vector_',
    )),
    'grouentr': (345, (
        'grouscan_',
        'grouscan_select_floor_',
        'grouscan_select_tile_',
        'grouscan_require_tile_',
        'grouscan_touch_tile_',
    )),
    'florentr': (870, (
        'florscan_',
        'florscan_check_height_',
        'florscan_touch_tile_',
        'florscan_load_tile_',
        'florscan_set_visibility_',
        'florscan_flat_axes_',
        'florscan_wall_axes_',
        'florscan_wall_length_',
        'florscan_project_axes_',
    )),
    'flortail': (788, (
        'florscan_texture_',
        'florscan_flip_x_',
        'florscan_flip_y_',
        'florscan_begin_spans_',
        'florscan_scan_column_',
        'florscan_empty_column_',
        'florscan_test_column_',
        'florscan_finish_spans_',
    )),
    'ceiltail': (752, (
        'ceilscan_texture_',
        'ceilscan_flip_x_',
        'ceilscan_flip_y_',
        'ceilscan_begin_spans_',
        'ceilscan_scan_column_',
        'ceilscan_empty_column_',
        'ceilscan_test_column_',
        'ceilscan_finish_spans_',
        'ceilscan_run_timer_',
        'ceilscan_restore_stack_',
    )),
    'envcopy': (185, ENV_COPY_ENTRIES),
    'hline': (565, ('hline_', 'hline_planar_', 'hline_next_plane_')),
    'clrview': (751, (
        'clearview_',
        'clearview_stereo_row_',
        'clearview_check_stereo_row_',
        'clearview_check_planar_',
        'clearview_linear_',
        'clearview_service_timer_',
    )),
    'clrviews': (413, (
        'clearallviews_',
        'clearallviews_fill_dwords_',
        'clearallviews_dispatch_backend_',
        'clearallviews_vga_planes_',
        'clearallviews_paged_display_',
        'clearallviews_linear_frame_',
        'clearallviews_port_3cd_banks_',
        'clearallviews_graphics_controller_banks_',
        'clearallviews_crtc_banks_',
        'clearallviews_service_timer_',
    )),
    'prepwall': (919, ('prepwall_', 'prepwall_more_columns_', 'prepwall_last_pair_', 'prepwall_last_column_')),
    'transwal': (440, ('transmaskwallscan_',)),
    'fadeloop': (71, ('run_palette_fade_', 'palette_fade_out_entry_')),
    'cmpmir': (1192, ('completemirror_',)),
    'spnfpu': (59, ('init_fpu_callbacks_', 'check_fpu_callbacks_')),
    'walfrnt': (532, ('wallfront_', 'wallfront_geometry_')),
    'vizporta': (482, ('cansee_',)),
    'egatext': (690, ('draw_ega_text_',)),
    'scrntxt': (519, ('draw_screen_text_',)),
    'rotspr': (555, ('rotatesprite_',)),
    'palookmk': (462, ('makepalookup_',)),
    'closestc': (478, ('getclosestcol_',)),
    'palinit': (490, ('initialize_color_lookup_',)),
    'vgavtime': (403, ('set_vga_vertical_timing_',)),
    'loadtile': (385, ('loadtile_',)),
    'viewtile': (377, ('setviewtotile_',)),
    'viewback': (309, ('setviewback_',)),
    'slopepr': (301, ('getzsofslope_',)),
    'setbrigh': (318, ('setbrightness_',)),
    'rinterc': (246, ('rintersect_',)),
    'prjhit': (290, ('apply_projectile_hit_',)),
    'actmove': (326, ('move_actor_',)),
    'proxupd': (361, ('update_proximity_sprites_',)),
    'sprseq': (477, ('update_sprite_sequence_state_',)),
    'peffspn': (374, ('spawn_counted_player_effect_',)),
    'telterm': (334, ('check_teleport_terminals_',)),
    'board7': (361, ('update_board_7_script_',)),
    'board5': (435, ('update_board_5_script_',)),
    'savemap': (378, ('save_build_map_',)),
    'loadmap': (401, ('load_build_map_',)),
    'savename': (370, ('edit_save_slot_name_',)),
    'savmenu': (394, ('run_save_game_menu_',)),
    'loadmenu': (431, ('run_load_game_menu_',)),
    'slphgt': (522, ('getceilzofslope_', 'getflorzofslope_')),
    'launch': (197, ('parse_startup_arguments_',)),
    'linterc': (271, ('lintersect_',)),
    'vidshut': (236, ('shutdown_video_engine_',)),
    'readpix': (213, ('readpixel16_',)),
    'tilerot': (180, ('squarerotatetile_',)),
    'rotpoint': (146, ('rotatepoint_',)),
    'neighz': (208, ('nextsectorneighborz_',)),
    'keepaway': (167, ('keepaway_',)),
    'bfront': (154, ('bunchfront_',)),
    'dragpt': (173, ('dragpoint_',)),
    'mkrdraw': (242, ('draw_menu_selection_marker_',)),
    'audctrl': (2492, AUDIO_SAMPLE_ROUTINES),
    'hmindet': (1166, HMINDET_ROUTINES),
    'hmiimage': (680, ('load_audio_driver_image_', 'unload_audio_driver_image_')),
    'hmibuf': (678, ('audio_driver_shutdown_', 'allocate_audio_buffer_')),
    'hmidpmi': (397, ('allocate_dpmi_audio_buffer_', 'release_dpmi_audio_buffer_')),
    'mnuframe': (298, ('draw_menu_frame_',)),
    'menutext': (301, ('draw_menu_text_',)),
    'drvinit': (1123, ('audio_driver_init_',)),
    'timercb': (1858, TIMER_CALLBACK_ROUTINES),
    'hmilock': (1764, ('initialize_audio_backend_', 'shutdown_audio_backend_')),
    'hmiscan': (2111, HMI_SCAN_ROUTINES),
    'hmiwork': (234, HMIWORK_ROUTINES),
    'hmictrl': (517, HMICTRL_ROUTINES),
    'pcminput': (6976, PCM_INPUT),
    'dosint': (52, ('int386x_', 'int386_')),
    'pcmaudio': (1384, (
        'output_signed_8_', 'output_signed_16_',
        'output_unsigned_8_', 'output_unsigned_16_',
        'output_stereo_signed_8_', 'output_stereo_signed_16_',
        'output_stereo_unsigned_8_', 'output_stereo_unsigned_16_',
        'output_swapped_mono_signed_8_', 'output_swapped_mono_signed_16_',
        'output_swapped_mono_unsigned_8_', 'output_swapped_mono_unsigned_16_',
        'output_swapped_stereo_signed_8_', 'output_swapped_stereo_signed_16_',
        'output_swapped_stereo_unsigned_8_', 'output_swapped_stereo_unsigned_16_',
        'output_clipped_mono_signed_8_', 'output_clipped_mono_signed_16_',
        'output_clipped_mono_unsigned_8_', 'output_clipped_mono_unsigned_16_',
        'output_clipped_stereo_signed_8_', 'output_clipped_stereo_signed_16_',
        'output_clipped_stereo_unsigned_8_', 'output_clipped_stereo_unsigned_16_',
        'output_clipped_swapped_mono_signed_8_', 'output_clipped_swapped_mono_signed_16_',
        'output_clipped_swapped_mono_unsigned_8_', 'output_clipped_swapped_mono_unsigned_16_',
        'output_clipped_swapped_stereo_signed_8_', 'output_clipped_swapped_stereo_signed_16_',
        'output_clipped_swapped_stereo_unsigned_8_', 'output_clipped_swapped_stereo_unsigned_16_',
    )),
    'transmod': (254, TRANSLUCENCY_MODES),
    'sndstop': (308, SOUND_STOP),
    'panreg': (73, ('register_pan_sector_',)),
    'invref': (81, ('refresh_inventory_',)),
    'cmdhelp': (217, COMMAND_LINE_HELP),
    'loadpal': (281, ('load_palette_tables_',)),
    'mouse': (90, ('getmousevalues_', 'initialize_mouse_')),
    'vidtext': (277, VIDEO_TEXT),
    'prvset': (268, ('prompt_video_settings_',)),
    'inpsnap': (129, ('snapshot_input_',)),
    'outqueue': (58, ('output_queue_depth_',)),
    'cfgcopy': (147, ('copy_configuration_value_',)),
    'netready': (126, ('broadcast_network_ready_',)),
    'itemsel': (298, TEXT_ARCHIVE),
    'cfgbool': (86, ('write_configuration_boolean_',)),
    'cfgrem': (203, CONFIG_REMOVERS),
    'cddetect': (95, ('detect_cd_drives_',)),
    'cdcmds': (459, CD_REQUESTS),
    'cdplay': (298, CD_PLAYBACK),
    'cdinfo': (107, ('read_cd_track_info_',)),
    'rmsim': (112, ('simulate_real_mode_interrupt_',)),
    'dpmirm': (239, ('dpmi_real_mode_interrupt_',)),
    'dpmifar': (292, ('dpmi_real_mode_far_call_',)),
    'cdinit': (280, ('initialize_cd_audio_',)),
    'cdskip': (106, CD_TRACK_NAVIGATION),
    'dosmem': (149, DOS_MEMORY),
    'floatnew': (270, ('spawn_float_sprite_',)),
    'mvspr': (311, ('move_sprite_',)),
    'floupd': (163, ('update_float_sprites_',)),
    'audshut': (140, ('shutdown_game_audio_', 'sound_sample_done_')),
    'rtleaf': (37, RUNTIME_HELPERS),
    'randcrt': (58, RANDOM_NUMBER),
    'errno': (52, ERROR_SETTERS),
    'gfxstate': (166, GRAPHICS_STATE),
    'gfxdev': (39, GRAPHICS_DEVICE),
    'flatsp': (387, ('flatten_sprite_', 'crush_sprite_')),
    'cfgopen': (242, ('open_configuration_',)),
    'rtprint': (34, ('print_runtime_message_',)),
    'exitcb': (55, ('run_exit_callbacks_',)),
    'exitreg': (60, ('register_exit_callback_',)),
    'plyrdist': (106, PLAYER_DISTANCE),
    'dacwidth': (64, ('set_vesa_dac_width_',)),
    'menugly': (117, ('menu_glyph_tile_',)),
    'sprpos': (98, ('setsprite_',)),
    'gamerr': (39, ('report_game_error_',)),
    'crushply': (170, ('check_crushed_player_',)),
    'audatten': (101, ('audio_source_attenuation_',)),
    'audiopan': (250, ('audio_pan_', 'audio_sprite_pan_')),
    'sndinit': (227, ('initialize_sound_slots_',)),
    'audinit': (185, ('initialize_game_audio_',)),
    'state': (44, MENU_STATE),
    'crushio': (92, CRUSHER_SAVE),
    'menuinit': (466, MENU_ENTRIES),
    'boardvp': (209, ('initialize_board_sprite_state_',)),
    'cfgins': (277, ('append_configuration_integer_',)),
    'sndindex': (260, ('load_sound_archive_',)),
    'gameinit': (219, ('initialize_game_subsystems_',)),
    'ripinit': (181, ('initialize_ripple_tables_',)),
    'statadj': (203, ('adjust_status_value_',)),
    'adjpstat': (308, ('adjust_player_status_',)),
    'cfgparse': (174, ('parse_configuration_integer_',)),
    'cfgnumb': (253, ('replace_configuration_value_',)),
    'vidload': (196, ('load_video_settings_',)),
    'cfgvalue': (196, ('write_configuration_value_',)),
    'cfgapnd': (164, ('append_configuration_section_',)),
    'mousesen': (275, ('run_mouse_sensitivity_menu_',)),
    'mousebtn': (550, ('run_mouse_button_menu_',)),
    'ctlmenu': (240, ('run_control_limits_menu_',)),
    'hitdisp': (132, ('dispatch_hit_event_',)),
    'crushspr': (162, ('check_crushed_sprites_',)),
    'crushsnd': (89, ('play_crusher_sound_',)),
    'crushupd': (487, ('update_level_effects_',)),
    'crushtag': (170, ('trigger_tagged_crushers_',)),
    'menuanim': (124, ('advance_menu_animation_',)),
    'vesapage': (164, ('select_vesa_draw_page_',)),
    'ctile': (137, ('cache_menu_tiles_',)),
    'weapover': (169, ('draw_weapon_overlay_',)),
    'telepspr': (182, ('teleport_sprite_',)),
    'boardact': (698, ('restore_board_actor_sprites_',)),
    'projup': (651, ('update_projectiles_',)),
    'blast': (532, ('apply_sprite_blast_',)),
    'fadeupd': (574, ('update_palette_fade_',)),
    'playrec': (475, ('run_recorded_session_',)),
    'netrsync': (335, ('synchronize_network_players_',)),
    'netlead': (457, ('rotate_network_lead_player_',)),
    'boardfin': (723, ('finalize_board_state_',)),
    'sprview': (579, ('update_sprite_view_',)),
    'boardent': (513, (
        'initialize_board_entry_',
        'board_entry_palette_1_',
        'board_entry_palette_2_',
        'board_entry_palette_3_',
        'board_entry_palette_4_',
        'board_entry_palette_5_',
        'board_entry_palette_6_',
        'board_entry_palette_7_',
        'board_entry_default_palette_',
    )),
    'spawnpos': (507, ('find_spawn_position_',)),
    'telepdst': (501, ('resolve_teleport_destination_',)),
    'sectport': (157, ('sectors_share_portal_',)),
    'statusbn': (230, ('draw_status_banner_',)),
    'drawsml': (223, ('draw_small_tile_text_',)),
    'pretiles': (295, ('preload_game_tiles_',)),
    'cfmact': (89, ('confirm_menu_action_',)),
    'cfmreset': (79, ('confirm_reset_key_bindings_',)),
    'mouseset': (98, ('run_mouse_settings_',)),
    'keyset': (98, ('run_keyboard_settings_',)),
    'keyvalid': (124, ('validate_key_binding_',)),
    'gamemenu': (199, ('initialize_game_menus_',)),
    'cfgread': (191, CONFIG_READERS),
    'audiocfg': (201, ('read_audio_configuration_',)),
    'hexdigit': (53, ('parse_hex_digits_',)),
    'hexparse': (55, ('parse_hexadecimal_',)),
    'cfgkey': (568, ('find_configuration_key_', 'read_configuration_line_',
                     'append_configuration_value_')),
    'cfgclose': (94, ('close_configuration_',)),
    'textvid': (111, TEXT_VIDEO),
    'gamecfg': (532, GAME_CONFIG),
    'preview': (181, SAVE_PREVIEW),
    'readprev': (155, ('read_save_slot_preview_',)),
    'vidset': (172, ('save_video_settings_',)),
    'devices': (227, DEVICE_STATE),
    'gametime': (124, GAME_TIMER),
    'engheap': (10, ENGINE_HEAP),
    'crushvw': (109, CRUSH_VIEW),
    'menudraw': (8, ('request_menu_redraw_',)),
    'sprchang': (160, ('changespritesect_', 'changespritestat_')),
    'presinp': (191, ('presentation_reset_', 'presentation_input_')),
    'presgrp': (920, ('loop_finish_', 'dispatch_ticks_', 'dispatch_period_', 'dispatch_prepare_', 'dispatch_poll_')),
    'interp': (200, ('setinterpolation_', 'stopinterpolation_', 'updateinterpolations_')),
    'anim': (148, ('getanimationgoal_', 'setanimation_')),
    'distime': (97, ('dispatch_ticks_', 'dispatch_period_')),
    'crdisp': (335, ('activate_initial_crushers_', 'find_crush_sector_', 'trigger_crusher_on_entry_')),
    'dispatch': (127, ('dispatch_menu_', 'main_step_d_')),
    'frameprf': (700, ('main_run_', 'main_load_selection_', 'game_loop_')),
    'startgrp': (272, ('main_prepare_callback_', 'main_')),
    'ceilspr': (1157, ('ceilspritescan_', 'ceilspritehline_')),
    'reclook': (128, ('lookup_record_value_', 'lookup_type_index_')),
    'slopes': (425, ('alignceilslope_', 'alignflorslope_')),
    'editor16': (3516, ('drawline256_', 'drawline16_', 'qsetmode640350_',
                       'qsetmode640480_', 'clear2dscreen_', 'draw2dgrid_')),
}


def verify_group_layout(blob, size, layout):
    """Require one complete CODE group and exact public offsets, including tails."""
    segments, publics = read_object(blob)
    code_segments = [i for i, segment in enumerate(segments[1:], 1) if segment['cls'] == 'CODE']
    if len(code_segments) != 1:
        raise ValueError('Expected exactly one group CODE segment')
    segment = code_segments[0]
    if len(segments[segment]['data']) != size:
        raise ValueError('Unexpected group CODE size')
    expected = sorted((segment, offset, symbol) for symbol, offset in layout)
    if sorted(publics) != expected:
        raise ValueError('Group public names/offsets differ from original layout')
    if any(item['data'] for i, item in enumerate(segments[1:], 1) if i != segment):
        raise ValueError('Group must keep non-code data external')


def verify_compiler_groups(exe, directory, names=None):
    selected = lambda name: names is None or name in names
    for name, (size, symbols) in GROUPS.items():
        if not selected(name):
            continue
        # The compiler packs these functions into one segment. The executable
        # can place the same functions apart, with other routines between them.
        layout = []
        offset = 0
        for symbol in symbols:
            layout.append((symbol, offset))
            offset += LEAVES[symbol][1]
        if offset != size:
            raise ValueError(f'Unexpected span sizes for {name}')
        verify_group_layout((directory/(name+'.obj')).read_bytes(), size, layout)
    # The local insertion candidates are only present to preserve Watcom's shared tail.
    for name, size, public in (('recvhigh', 10, 'receive_button_high_'),
                               ('recvhead', 37, 'receive_ready_context_'),
                               ('recvsend', 18, 'receive_ready_send_')):
        if selected(name):
            verify_group_layout((directory/(name+'.obj')).read_bytes(), size, [(public, 0)])
    for name, size, public in (('sectpuz', 933, 'update_level_sector_puzzle_'),
                               ('puzact', 929, 'puzzle_activation_context_')):
        if selected(name):
            verify_group_layout((directory/(name+'.obj')).read_bytes(), size, [(public, 0)])
    if selected('ripout'):
        verify_group_layout((directory/'ripout.obj').read_bytes(), 49,
                            [('ripple_output_row_', 0), ('ripple_store_output_', 32),
                             ('ripple_mask_begin_', 41)])
    for _routine in SAVE_FIELD_LAYOUT['routines']:
        if selected(_routine['object']):
            _runs = _routine['runs']
            verify_group_layout((directory/(_routine['object']+'.obj')).read_bytes(),
                                sum(row['public_size'] for row in _runs),
                                [(row['public'], row['public_start']) for row in _runs])
    if selected('svbytes'):
        verify_group_layout((directory/'svbytes.obj').read_bytes(),
                            SAVE_BYTE_LAYOUT['object_size'], SAVE_BYTE_LAYOUT['public_layout'])
    for _object in COMPILER_CONTEXT_OBJECTS:
        if selected(_object['object']):
            verify_group_layout((directory/(_object['object']+'.obj')).read_bytes(),
                                _object['size'], [(row['public'],row['start']) for row in _object['contexts']])
    if selected('ripflow'):
        verify_group_layout((directory/'ripflow.obj').read_bytes(), 865, [('ripple_flow_context_', 0)])
    if selected('ripidx'):
        verify_group_layout((directory/'ripidx.obj').read_bytes(), 37,
                            [('ripple_seed_and_read_ecx_', 0), ('ripple_commit_and_read_eax_', 13),
                             ('ripple_step_and_read_eax_', 26)])
    if selected('riptest'):
        verify_group_layout((directory/'riptest.obj').read_bytes(), 44,
                            [('ripple_particle_guard_', 0), ('ripple_sample_step_', 9),
                             ('ripple_sample_guard_', 11), ('ripple_spawn_guard_', 20),
                             ('ripple_last_slot_', 29), ('ripple_random_draw_', 36)])
    if selected('ripbook'):
        verify_group_layout((directory/'ripbook.obj').read_bytes(), 49,
                            [('ripple_spawn_countdown_', 0), ('ripple_radial_set_slot_', 5), ('ripple_radial_load_y_', 8), ('ripple_row_reset_', 16), ('ripple_tile_register_', 19), ('ripple_spawn_step_', 22), ('ripple_output_tile_', 28), ('ripple_stencil_center_', 31), ('ripple_stencil_next1_', 34), ('ripple_first_lane_', 38), ('ripple_stencil_next2_', 41), ('ripple_stencil_next3_', 45)])
    if selected('riploop'):
        verify_group_layout((directory/'riploop.obj').read_bytes(), 32,
                            [('ripple_output_word_guard_', 0),
                             ('ripple_output_row_increment_', 11), ('ripple_output_row_guard_', 13)])
    if selected('riprad'):
        verify_group_layout((directory/'riprad.obj').read_bytes(), 109,
                            [('ripple_radial_sample_', 0), ('ripple_radial_setup_', 53)])
    if selected('rippack'):
        verify_group_layout((directory/'rippack.obj').read_bytes(), 47,
                            [('ripple_pack_two_', 0), ('ripple_pack_third_', 20),
                             ('ripple_pack_fourth_', 31)])
    if selected('rippart'):
        verify_group_layout((directory/'rippart.obj').read_bytes(), 141,
                            [('ripple_store_y_slot_', 0), ('ripple_floor_pixel_', 34),
                             ('ripple_advance_radius_', 49), ('ripple_store_x_slot_', 123)])
    if selected('ripbord'):
        verify_group_layout((directory/'ripbord.obj').read_bytes(), 141,
                            [('ripple_border_columns_', 0), ('ripple_border_corners_', 47),
                             ('ripple_vertical_head_', 93), ('ripple_vertical_tail_', 105)])
    if selected('ripctl'):
        verify_group_layout((directory/'ripctl.obj').read_bytes(), 56,
                            [('ripple_spawn_limit_', 0), ('ripple_mask_row_', 23)])
    if selected('enclatch'):
        verify_group_layout((directory/'enclatch.obj').read_bytes(), 1409, [('encounter_latch_context_', 160)])
    if selected('encexit'):
        verify_group_layout((directory/'encexit.obj').read_bytes(), 1385, [('encounter_exit_context_', 160)])
    if selected('menuprep'):
        verify_group_layout((directory/'menuprep.obj').read_bytes(), 75,
                            [('main_caption_setup_', 0), ('main_menu_select_', 46)])
    if selected('mainmenu'):
        verify_group_layout((directory/'mainmenu.obj').read_bytes(), 529, [('dispatch_main_menu_', 32)])
    if selected('recvlen'):
        verify_group_layout((directory/'recvlen.obj').read_bytes(), 54, [('getpacket_length_copy_', 0)])
    if selected('recvfrag'):
        verify_group_layout((directory/'recvfrag.obj').read_bytes(), 84, [
            ('receive_button_low_', 0), ('receive_checksum_order_', 28),
            ('receive_message_delta_', 52), ('receive_message_clock_', 63)])
    if selected('recvcrc'):
        verify_group_layout((directory/'recvcrc.obj').read_bytes(), 106,
                            [('compare_received_checksums_', 0)])
    if selected('recvpar'):
        verify_group_layout((directory/'recvpar.obj').read_bytes(), 32,
                            [('receiver_parity_tick_', 0)])
    if selected('recvpkt'):
        verify_group_layout((directory/'recvpkt.obj').read_bytes(), 910, [('receive_packets_', 0)])
    if selected('sprlists'):
        verify_group_layout((directory/'sprlists.obj').read_bytes(), 774, [
            ('insertsprite_', 0), ('insertspritesect_', 21), ('insertspritestat_', 177),
            ('deletesprite_', 332), ('deletespritesect_', 352), ('deletespritestat_', 563),
        ])
    # Watcom merges identical empty functions. The linker places each at its
    # original dispatch address, which has its own entry in the inventory.
    if selected('lvlstub'):
        verify_group_layout((directory/'lvlstub.obj').read_bytes(), 1,
                            [(symbol, 0) for symbol in EMPTY_GAME_HOOKS])
    if selected('menuhook'):
        verify_group_layout((directory/'menuhook.obj').read_bytes(), 3,
                            [(symbol, 0) for symbol in DISABLED_MENU_HOOKS])
    if selected('hmimark'):
        verify_group_layout((directory/'hmimark.obj').read_bytes(), 1,
                            [(symbol, 0) for symbol in HMIMARK_ROUTINES])
    if selected('cacheunt'):
        verify_cache_unit(exe, (directory/'cacheunt.obj').read_bytes())
    if selected('netdefs'):
        verify_network_defaults(exe, (directory/'netdefs.obj').read_bytes())


for _name in ('ripple_sum_first_', 'ripple_sum_second_',
              'ripple_sum_third_', 'ripple_sum_fourth_'):
    OBJECT_NAMES[_name] = 'ripsum'

OBJECT_NAMES['ripple_spawn_limit_phase_'] = 'ripctl'
OBJECT_NAMES['ripple_mask_row_phase_'] = 'ripctl'

OBJECT_NAMES['ripple_border_initialize_'] = 'ripbord'
OBJECT_NAMES['ripple_border_loop_'] = 'ripbord'

for _name in ('ripple_store_y_phase_', 'ripple_floor_phase_', 'ripple_advance_radius_phase_'):
    OBJECT_NAMES[_name] = 'rippart'

for _name in ('ripple_x_draw_', 'ripple_x_index_', 'ripple_x_store_'):
    OBJECT_NAMES[_name] = 'rippart'
for _name in ('ripple_corners_load_', 'ripple_corners_mask_', 'ripple_corners_store_'):
    OBJECT_NAMES[_name] = 'ripbord'

OBJECT_NAMES['ripple_radial_setup_phase_'] = 'riprad'
OBJECT_NAMES['ripple_radial_sample_phase_'] = 'riprad'
OBJECT_NAMES['ripple_pack_two_bits_'] = 'rippack'
OBJECT_NAMES['ripple_pack_two_add_'] = 'rippack'
OBJECT_NAMES['ripple_pack_third_bits_'] = 'rippack'
OBJECT_NAMES['ripple_pack_third_add_'] = 'rippack'
OBJECT_NAMES['ripple_pack_fourth_phase_'] = 'rippack'

OBJECT_NAMES['ripple_vertical_head_phase_'] = 'ripbord'
OBJECT_NAMES['ripple_vertical_tail_phase_'] = 'ripbord'
OBJECT_NAMES['ripple_output_row_phase_'] = 'ripout'
OBJECT_NAMES['ripple_store_output_phase_'] = 'ripout'
OBJECT_NAMES['ripple_mask_begin_phase_'] = 'ripout'
OBJECT_NAMES['ripple_control_saved_registers_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2eb80_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ebca_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ebd5_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ec1a_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ec61_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ecc6_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ecef_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ed1b_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ed52_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2ed85_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_branch_2eda9_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_control_restored_registers_phase_'] = 'ripflow'
OBJECT_NAMES['ripple_frame_allocate_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_seed_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_commit_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_spawn_read_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_radial_seed_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_floor_read_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_step_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_index_radial_read_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_frame_release_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_frame_return_phase_'] = 'ripidx'
OBJECT_NAMES['ripple_particle_guard_phase_'] = 'riptest'
OBJECT_NAMES['ripple_sample_step_phase_'] = 'riptest'
OBJECT_NAMES['ripple_sample_test_phase_'] = 'riptest'
OBJECT_NAMES['ripple_spawn_test_phase_'] = 'riptest'
OBJECT_NAMES['ripple_last_slot_phase_'] = 'riptest'
OBJECT_NAMES['ripple_random_x_call_phase_'] = 'riptest'
OBJECT_NAMES['ripple_random_y_call_phase_'] = 'riptest'
OBJECT_NAMES['ripple_mask_guard_compare_phase_'] = 'riploop'
OBJECT_NAMES['ripple_vertical_guard_compare_phase_'] = 'riploop'
OBJECT_NAMES['ripple_spawn_count_copy_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_spawn_count_step_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_radial_set_slot_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_radial_load_y_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_mask_row_reset_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_vertical_row_reset_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_output_row_reset_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_tile_register_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_spawn_step_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_output_tile_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_stencil_center_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_stencil_next1_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_first_lane_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_stencil_next2_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_stencil_next3_phase_'] = 'ripbook'
OBJECT_NAMES['ripple_output_word_guard_phase_'] = 'riploop'
OBJECT_NAMES['ripple_output_row_increment_phase_'] = 'riploop'
OBJECT_NAMES['ripple_mask_row_increment_phase_'] = 'riploop'
OBJECT_NAMES['ripple_vertical_row_increment_phase_'] = 'riploop'
OBJECT_NAMES['ripple_output_row_guard_phase_'] = 'riploop'

for _routine in SAVE_IO_ROUTINES:
    for _run in _routine['runs']:
        OBJECT_NAMES[_run['phase']] = _routine['object']

for _phase in COMPILER_CONTEXT_PHASES:
    OBJECT_NAMES[_phase['phase']] = _phase['object']

OBJECT_NAMES['sound_playback_options_'] = 'sndopts'

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    exe = args.executable.read_bytes()
    if hashlib.sha256(exe).hexdigest() != TARGET_SHA256:
        parser.error('Unknown FATE.EXE')
    pointers = read_le_fixups(exe)['pointers']
    verify_compiler_groups(exe, args.directory)
    rows, covered = [], set()
    read_blob = lru_cache(maxsize=None)(lambda name: (args.directory/name).read_bytes())
    for symbol, (offset, size) in sorted(LEAVES.items(), key=lambda item: item[1][0]):
        filename = OBJECT_NAMES.get(symbol, symbol[:-1])+'.obj'
        blob = read_blob(filename)
        code_bindings = {}
        code, bindings = bind_leaf_details(blob, symbol, DATA_OFFSETS,
                                            address=offset-0x25600, functions=FUNCTION_ADDRESSES,
                                            absolute_code=CODE_OFFSETS, code_bindings=code_bindings)
        if code != exe[offset:offset+size]:
            raise ValueError(code_mismatch(symbol, code, exe[offset:offset+size], offset-0x25600))
        verify_leaf_relocations(code, bindings, pointers, offset-0x25600,
                                code_bindings=code_bindings)
        sites = set(range(offset, offset+size))
        if covered & sites:
            raise ValueError('Overlapping coverage spans')
        covered.update(sites)
        rows.append(dict(symbol=symbol, object=filename,
                         object_sha256=hashlib.sha256(blob).hexdigest(),
                         sha256=hashlib.sha256(code).hexdigest(),
                         raw_offset=hex(offset), loaded_address=hex(offset-0x25600),
                         bytes=size, le_pointers=len(bindings)))
    # Generated CODE tables precede these functions but are not extra routines.
    non_routine = []
    for filename, (binder, base, size, parts, counts) in switch_groups().items():
        blob = (args.directory/filename).read_bytes()
        code, data_bindings, code_bindings, calls = binder(blob)
        offset = base+0x25600
        if len(code) != size or code != exe[offset:offset+size]:
            raise ValueError('Generated-table compiler group differs: '+filename)
        if (len(data_bindings), len(code_bindings), len(calls)) != counts:
            raise ValueError('Unexpected group binding inventory: '+filename)
        bindings = data_bindings | code_bindings
        verify_leaf_relocations(code, bindings, pointers, base, code_bindings=code_bindings)
        if parts[0][0] != 0 or parts[-1][1] != size or any(
                left[1] != right[0] for left, right in zip(parts, parts[1:])):
            raise ValueError('Compiler group spans do not cover the group: '+filename)
        sites = set(range(offset, offset+size))
        if covered & sites:
            raise ValueError('Overlapping compiler group coverage: '+filename)
        covered.update(sites)
        digest = hashlib.sha256(blob).hexdigest()
        for start, end, symbol, kind, expected_le in parts:
            le_count = sum(start <= site < end for site in bindings)
            if le_count != expected_le:
                raise ValueError(f'Compiler group relocation count differs at {filename}+{start:#x}')
            row = dict(object=filename, object_sha256=digest, raw_offset=hex(offset + start),
                       sha256=hashlib.sha256(code[start:end]).hexdigest(),
                       loaded_address=hex(base + start), bytes=end - start, le_pointers=le_count)
            if symbol is None:
                non_routine.append(dict(kind=kind, **row))
            else:
                rows.append(dict(symbol=symbol, **row))
    rows.sort(key=lambda row: int(row['raw_offset'], 16))
    result = dict(target_sha256=TARGET_SHA256, routines=len(rows), unique_code_bytes=len(covered),
                  le_pointers=sum(row['le_pointers'] for row in rows+non_routine),
                  non_routine_code_spans=non_routine,
                  complete_modules=0, complete_executable=False,
                  note='Isolated spans/compiler groups, including generated jump-table prefixes; no complete original modules.', spans=rows)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(f"PASS: {result['routines']} routines, {len(covered)} unique bytes, {result['le_pointers']} LE targets")
