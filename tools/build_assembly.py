"""Build every registered assembly source once; strict verification remains separate."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from verify_assembly_suite import ROUTINES, NON_ROUTINE_UNITS


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(nasm, destination):
    root = Path(__file__).resolve().parents[1]
    nasm = nasm.resolve(strict=True)
    destination.mkdir(parents=True, exist_ok=True)
    units = {}
    for _, source, binary, *_ in ROUTINES+NON_ROUTINE_UNITS:
        if binary in units and units[binary] != source:
            raise ValueError('Conflicting assembly output: '+binary)
        units[binary] = source
    # Executable instructions stored in original DATA, excluded from CODE totals.
    units['level_modification_strings.bin'] = 'fate/level_modification_strings.asm'
    units['save_game_strings.bin'] = 'fate/save_game_strings.asm'
    units['save_slot_menu_strings.bin'] = 'fate/save_slot_menu_strings.asm'
    units['game_timer_messages.bin'] = 'fate/game_timer_messages.asm'
    units['game_audio_strings.bin'] = 'fate/game_audio_strings.asm'
    units['configuration_strings.bin'] = 'fate/configuration_strings.asm'
    units['video_settings_filename.bin'] = 'fate/video_settings_filename.asm'
    units['video_menu_strings.bin'] = 'fate/video_menu_strings.asm'
    units['cd_audio_messages.bin'] = 'fate/cd_audio_messages.asm'
    units['text_archive_strings.bin'] = 'fate/text_archive_strings.asm'
    units['game_configuration_filename.bin'] = 'fate/game_configuration_filename.asm'
    units['game_subsystem_strings.bin'] = 'fate/game_subsystem_strings.asm'
    units['crusher_runtime_strings.bin'] = 'fate/crusher_runtime_strings.asm'
    units['crushed_sprite_strings.bin'] = 'fate/crushed_sprite_strings.asm'
    units['network_startup_messages.bin'] = 'fate/network_startup_messages.asm'
    units['vesa_mode_messages.bin'] = 'fate/vesa_mode_messages.asm'
    units['frame_rate_format.bin'] = 'engine/frame_rate_format.asm'
    units['irq_stack_defaults.bin'] = 'runtime/irq_stack_defaults.asm'
    units['audio_timer_defaults.bin'] = 'runtime/audio_timer_defaults.asm'
    units['audio_detector_state.bin'] = 'runtime/audio_detector_state.asm'
    units['audio_mixer_state.bin'] = 'runtime/audio_mixer_state.asm'
    units['static_stream_defaults.bin'] = 'runtime/static_stream_defaults.asm'
    units['ipx_receive_callback.bin'] = 'network/ipx_receive_callback.asm'
    units['video_state_defaults.bin'] = 'engine/video_state_defaults.asm'
    units['key_binding_defaults.bin'] = 'fate/key_binding_defaults.asm'
    units['audio_pan_defaults.bin'] = 'fate/audio_pan_defaults.asm'
    units['video_configuration_defaults.bin'] = 'fate/video_configuration_defaults.asm'
    units['remaining_initialized_data.bin'] = 'runtime/remaining_initialized_data.asm'
    units['crt_startup_defaults.bin'] = 'runtime/crt_startup_defaults.asm'
    units['difficulty_audio_control_menus.bin'] = 'fate/difficulty_audio_control_menus.asm'
    units['graphics_hercules_device_table.bin'] = 'runtime/graphics_hercules_device_table.asm'
    units['runtime_heap_defaults.bin'] = 'runtime/runtime_heap_defaults.asm'
    units['fpu_emulator_defaults.bin'] = 'runtime/fpu_emulator_defaults.asm'
    units['graphics_font_descriptors.bin'] = 'runtime/graphics_font_descriptors.asm'
    units['graphics_font_descriptor_defaults.bin'] = 'runtime/graphics_font_descriptor_defaults.asm'
    units['hmi_status_messages.bin'] = 'runtime/hmi_status_messages.asm'
    units['hmi_status_pointers.bin'] = 'runtime/hmi_status_pointers.asm'
    units['hmi_driver_tables.bin'] = 'runtime/hmi_driver_tables.asm'
    units['hmi_driver_close_dispatch.bin'] = 'runtime/hmi_driver_close_dispatch.asm'
    units['level_name_defaults.bin'] = 'fate/level_name_defaults.asm'
    units['actor_initial_state.bin'] = 'fate/actor_initial_state.asm'
    units['interaction_configuration.bin'] = 'fate/interaction_configuration.asm'
    units['interaction_sprite_templates.bin'] = 'fate/interaction_sprite_templates.asm'
    units['terminal_and_inventory_defaults.bin'] = 'fate/terminal_and_inventory_defaults.asm'
    units['key_binding_captions.bin'] = 'fate/key_binding_captions.asm'
    units['key_scan_name_pointers.bin'] = 'fate/key_scan_name_pointers.asm'
    units['key_binding_action_table.bin'] = 'fate/key_binding_action_table.asm'
    units['key_binding_menu_records.bin'] = 'fate/key_binding_menu_records.asm'
    units['main_menu_records.bin'] = 'fate/main_menu_records.asm'
    units['options_menu_records.bin'] = 'fate/options_menu_records.asm'
    units['main_menu_captions.bin'] = 'fate/main_menu_captions.asm'
    units['configuration_menu_captions.bin'] = 'fate/configuration_menu_captions.asm'
    units['keyboard_ascii_tables.bin'] = 'fate/keyboard_ascii_tables.asm'
    units['video_mode_strings.bin'] = 'engine/video_mode_strings.asm'
    units['video_allocation_messages.bin'] = 'engine/video_allocation_messages.asm'
    units['dpmi_video_messages.bin'] = 'fate/dpmi_video_messages.asm'
    units['configuration_hex_pointer.bin'] = 'fate/configuration_hex_pointer.asm'
    units['gameplay_mod_extension.bin'] = 'fate/gameplay_mod_extension.asm'
    units['level_board_transition_messages.bin'] = 'fate/level_board_transition_messages.asm'
    units['teleport_terminal_message.bin'] = 'fate/teleport_terminal_message.asm'
    units['float_sprites_message.bin'] = 'fate/float_sprites_message.asm'
    units['actor_projectile_message.bin'] = 'fate/actor_projectile_message.asm'
    units['player_projectile_message.bin'] = 'fate/player_projectile_message.asm'
    units['sector_panning_message.bin'] = 'fate/sector_panning_message.asm'
    units['fate_error_newline.bin'] = 'fate/fate_error_newline.asm'
    units['fate_game_over_message.bin'] = 'fate/fate_game_over_message.asm'
    units['fate_shutdown_flags.bin'] = 'fate/fate_shutdown_flags.asm'
    units['numbered_board_messages.bin'] = 'fate/numbered_board_messages.asm'
    units['board_setup_messages.bin'] = 'fate/board_setup_messages.asm'
    units['player_health_messages.bin'] = 'fate/player_health_messages.asm'
    units['board_loader_messages.bin'] = 'fate/board_loader_messages.asm'
    units['restore_actor_message.bin'] = 'fate/restore_actor_message.asm'
    units['weapon_animation_tables.bin'] = 'fate/weapon_animation_tables.asm'
    units['level_script_defaults.bin'] = 'fate/level_script_defaults.asm'
    units['navigation_puzzle_defaults.bin'] = 'fate/navigation_puzzle_defaults.asm'
    units['sprite_navigation_data.bin'] = 'fate/sprite_navigation_data.asm'
    units['sprite_navigation_messages.bin'] = 'fate/sprite_navigation_messages.asm'
    units['sprite_path_messages.bin'] = 'fate/sprite_path_messages.asm'
    units['realcom.bin'] = 'network/realcom.asm'
    units['crt_tables.bin'] = 'runtime/crt_tables.asm'
    units['dos_errno_table.bin'] = 'runtime/dos_errno_table.asm'
    units['spawn_defaults.bin'] = 'runtime/spawn_defaults.asm'
    units['stack_defaults.bin'] = 'runtime/stack_defaults.asm'
    units['fpu_default.bin'] = 'runtime/fpu_default.asm'
    units['fpu_vendor.bin'] = 'runtime/fpu_vendor.asm'
    units['spawn_path_variable.bin'] = 'runtime/spawn_path_variable.asm'
    units['float_callbacks.bin'] = 'runtime/float_callbacks.asm'
    units['float_message.bin'] = 'runtime/float_message.asm'
    units['audio_detector_filename.bin'] = 'runtime/audio_detector_filename.asm'
    units['audio_driver_filename.bin'] = 'runtime/audio_driver_filename.asm'
    units['delimiter_bit_masks.bin'] = 'runtime/delimiter_bit_masks.asm'
    units['stdio_mode.bin'] = 'runtime/stdio_mode.asm'
    units['dos_descriptor_defaults.bin'] = 'runtime/dos_descriptor_defaults.asm'
    units['exit_hooks.bin'] = 'runtime/exit_hooks.asm'
    units['rand_seed.bin'] = 'runtime/rand_seed.asm'
    units['system_strings.bin'] = 'runtime/system_strings.asm'
    units['graphics_coordinate_defaults.bin'] = 'runtime/graphics_coordinate_defaults.asm'
    units['graphics_bitmap_defaults.bin'] = 'runtime/graphics_bitmap_defaults.asm'
    units['graphics_mode_masks.bin'] = 'runtime/graphics_mode_masks.asm'
    units['graphics_rom_signatures.bin'] = 'runtime/graphics_rom_signatures.asm'
    units['graphics_ega_palette.bin'] = 'runtime/graphics_ega_palette.asm'
    units['graphics_fill_defaults.bin'] = 'runtime/graphics_fill_defaults.asm'
    units['graphics_adapter_classes.bin'] = 'runtime/graphics_adapter_classes.asm'
    units['graphics_hercules_crtc.bin'] = 'runtime/graphics_hercules_crtc.asm'
    units['graphics_planar_actions.bin'] = 'runtime/graphics_planar_actions.asm'
    units['graphics_two_plane_colors.bin'] = 'runtime/graphics_two_plane_colors.asm'
    units['graphics_vendor_modes.bin'] = 'runtime/graphics_vendor_modes.asm'
    units['graphics_cga_device_tables.bin'] = 'runtime/graphics_cga_device_tables.asm'
    units['graphics_planar_device_tables.bin'] = 'runtime/graphics_planar_device_tables.asm'
    units['graphics_banked_device_tables.bin'] = 'runtime/graphics_banked_device_tables.asm'
    units['graphics_mode_device_map.bin'] = 'runtime/graphics_mode_device_map.asm'
    units['graphics_bank_selectors.bin'] = 'runtime/graphics_bank_selectors.asm'
    version = subprocess.run([str(nasm), '-v'], check=True, capture_output=True,
                             text=True).stdout.strip()
    rows = []
    for binary, source in sorted(units.items()):
        path = root/'src'/source
        output = destination/binary
        subprocess.run([str(nasm), '-f', 'bin', str(path), '-o', str(output)],
                       cwd=root, check=True)
        rows.append(dict(source='src/'+source, source_sha256=digest(path),
                         binary=binary, binary_sha256=digest(output),
                         bytes=output.stat().st_size))
    result = dict(assembler_version=version, assembler_sha256=digest(nasm),
                  format='bin', units=rows, exact_original_match_checked=False)
    (destination/'assembly-build.json').write_text(json.dumps(result, indent=2)+'\n',
                                                 encoding='utf-8', newline='\n')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('nasm', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    result = build(args.nasm, args.destination)
    print(f"Built {len(result['units'])} NASM source units")
