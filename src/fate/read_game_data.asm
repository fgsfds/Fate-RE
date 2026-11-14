; Restore serialized game state from GAMEDATA.
BITS 32
ORG 0x2f46b

load_slot_format equ 0x5dc
load_basename equ 0x5e3
load_mode equ 0x5ec
loaded_message equ 0x5ef
save_state_202c equ 0x202c
last_sequence_clock equ 0x2030
last_frame_tick equ 0x2034
left_icon equ 0x2038
middle_icon equ 0x203a
right_icon equ 0x203c
toggled_word equ 0x203e
destination_level equ 0x2040
level_names equ 0x2041
effect_count equ 0x225d
effect_speed equ 0x225f
status_flag equ 0x2261
interaction_state_2263 equ 0x2263
toggled_mode equ 0x2265
item_enabled equ 0x2267
item_stock equ 0x2277
item_alternate_stock equ 0x2287
player_action equ 0x2297
save_state_2299 equ 0x2299
advance_clock equ 0x229b
waypoint_x equ 0x229d
template_cstat equ 0x2a9d
weapon_action equ 0x2bdc
weapon_animation_state equ 0x2bde
selected_weapon equ 0x2be0
selected_weapon_2be2 equ 0x2be2
weapon_tile equ 0x2be4
close_hit_tile equ 0x2be6
moving_sprite_count equ 0x2be8
pan_sector_count equ 0x2bea
float_sprite_count equ 0x2bec
projectile_count equ 0x2bee
map_x equ 0x2bf0
map_scale_or_y equ 0x2bf2
map_offset_y equ 0x2bf4
button_latch_disabled equ 0x2bf6
held_sprite equ 0x2bf8
map_mode equ 0x2bfa
mouse_motion_disabled equ 0x2bfc
inventory_grid equ 0x3b9d
cursor_mode equ 0x3be5
trigger_count equ 0x3be6
last_tick equ 0x3cea
listener_index equ 0x3cfa
saved_mouse_buttons equ 0x3cfc
brightness equ 0x3cfe
restore_count equ 0x3e04
player_count equ 0x13ce0
local_player equ 0x13ce2
fini_table_end equ 0x199e4
save_state_19a04 equ 0x19a04
board_state_1a204 equ 0x1a204
board_state_1a214 equ 0x1a214
board_state_1a224 equ 0x1a224
restore_addresses equ 0x1a234
save_state_1a238 equ 0x1a238
activation_state_1aa34 equ 0x1aa34
restore_values equ 0x1b234
board_state_1ba34 equ 0x1ba34
board_state_1ba44 equ 0x1ba44
board_state_1ba64 equ 0x1ba64
board_state_1ba84 equ 0x1ba84
board_state_1ba94 equ 0x1ba94
board_state_1baa4 equ 0x1baa4
board_state_1bab4 equ 0x1bab4
board_state_1babc equ 0x1babc
board_state_1bafc equ 0x1bafc
board_state_1bb3c equ 0x1bb3c
board_state_1bc7c equ 0x1bc7c
board_state_1bcbc equ 0x1bcbc
board_state_1bcfc equ 0x1bcfc
board_state_1bd0c equ 0x1bd0c
board_state_1bd1c equ 0x1bd1c
board_state_1c11c equ 0x1c11c
board_state_1c12c equ 0x1c12c
board_state_1c16c equ 0x1c16c
board_state_1c17c equ 0x1c17c
board_state_1c1fc equ 0x1c1fc
board_state_1c2fc equ 0x1c2fc
board_state_1c3fc equ 0x1c3fc
board_state_1c43c equ 0x1c43c
board_state_1c83c equ 0x1c83c
board_state_1cc3c equ 0x1cc3c
board_state_1cc44 equ 0x1cc44
board_state_1cc4c equ 0x1cc4c
board_state_1cc6c equ 0x1cc6c
board_state_1cc8c equ 0x1cc8c
board_state_1ccac equ 0x1ccac
board_state_1cd2c equ 0x1cd2c
board_state_1cdec equ 0x1cdec
board_state_1ce2c equ 0x1ce2c
board_state_1ce6c equ 0x1ce6c
board_state_1ceac equ 0x1ceac
board_state_1ceec equ 0x1ceec
board_state_1cf6c equ 0x1cf6c
board_state_1d08c equ 0x1d08c
board_state_1d10c equ 0x1d10c
board_filename equ 0x1e5ac
initialize_board_entry equ 0x2e14f
sub_40354 equ 0x40354
previous_input equ 0x55b6c
save_state_5abbc equ 0x5abbc
save_state_5abfc equ 0x5abfc
board_state_5ac8c equ 0x5ac8c
previous_player_sector equ 0x5acdc
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
save_state_5addc equ 0x5addc
save_state_5adfc equ 0x5adfc
board_state_5ae1c equ 0x5ae1c
format_string equ 0x601f3
append_string equ 0x60223
strlen equ 0x60381
fopen equ 0x605a2
fread equ 0x60638
fclose equ 0x60802
player_mode equ 0x62f1c
board_state_62f2c equ 0x62f2c
motion_state_62f4c equ 0x62f4c
player_horizon equ 0x62f8c
board_state_6304c equ 0x6304c
motion_state_6306c equ 0x6306c
player_angle equ 0x6308c
motion_state_630ac equ 0x630ac
board_state_630bc equ 0x630bc
board_state_6317c equ 0x6317c
status_right_tenths equ 0x6319c
list equ 0x67a3c
force_attack_frame equ 0x6f87c
player_hit_timer equ 0x6f89c
float_sprite_list equ 0x6f8bc
moving_sprites equ 0x6fcbc
pan_sectors equ 0x704bc
projectile_list equ 0x7053c
player_hit_y equ 0x7093c
player_hit_x equ 0x7097c
defer_mode_change equ 0x709bc
sprite_actor_index equ 0x709dc
interaction_state_729dc equ 0x729dc
actor_destination_x equ 0x729fc
board_state_7494c equ 0x7494c
activation_counter equ 0x7496c
activation_sprite_index equ 0x7497c
level_sector_x equ 0x7499c
level_sector_ids equ 0x7639c
status_expiration equ 0x7709c
near_tag_distance equ 0x770a0
save_state_770ac equ 0x770ac
actor_clock equ 0x770b8
second_player_selection equ 0x770c0
selection equ 0x770c8
keyboard_strafe equ 0x770e4
keyboard_forward equ 0x770e8
keyboard_turn equ 0x770ec
trigger_sprite equ 0x77124
saved_actor_x equ 0x772c4
actor_first_waypoint equ 0x78a40
actor_z_offset equ 0x79214
actor_x equ 0x799e8
actor_y equ 0x7a1bc
last_step_clock equ 0x7a990
ticks_per_step equ 0x7a994
destination_x equ 0x7a998
destination_y equ 0x7a99c
level_left_icon equ 0x7a9a0
level_sector_count equ 0x7aa3c
status_text equ 0x7aa70
actor_tiles equ 0x7abc0
actor_health equ 0x7cefa
actor_sector equ 0x7d2e4
saved_actor_lotag equ 0x7d6ce
actor_sprite_index equ 0x7dab8
modified_levels equ 0x7dea2
board_state_7debc equ 0x7debc
board_state_7debe equ 0x7debe
board_state_7dec0 equ 0x7dec0
board_state_7dec2 equ 0x7dec2
board_state_7dec4 equ 0x7dec4
board_state_7dec6 equ 0x7dec6
board_state_7deca equ 0x7deca
board_state_7decc equ 0x7decc
board_state_7dece equ 0x7dece
near_sector equ 0x7ded2
near_wall equ 0x7ded4
near_sprite equ 0x7ded6
mouse_dx equ 0x7deda
mouse_dy equ 0x7dedc
actor_target equ 0x7dede
active equ 0x7dee0
mouse_buttons equ 0x7dee2
special_sector equ 0x7dee4
alternate_fire_requested equ 0x7dee6
weapon_x_offset equ 0x7dee8
weapon_y_offset equ 0x7deea
difficulty_divisor equ 0x7deec
destination_entry equ 0x7deee
activation_sprite_count equ 0x7def0
smoothed_mouse_dx equ 0x7def2
previous_local_input equ 0x7def4
board_state_7def5 equ 0x7def5
board_state_7def6 equ 0x7def6
board_state_7def7 equ 0x7def7
input_forward equ 0x7def9
input_strafe equ 0x7defa
input_turn equ 0x7defb
input_actions equ 0x7defc
second_player_input equ 0x7defe
actor_delay_byte equ 0x7df03
actor_state_byte equ 0x7e0f8
actor_state equ 0x7e2ed
actor_sequence_initial equ 0x7e4e2
actor_frame equ 0x7e6d7
actor_profile equ 0x7e8cc
actor_board equ 0x7eac1
actor_enabled equ 0x7ecb6
actor_projectile_type equ 0x7eeab
actor_kind equ 0x7f0a0
actor_recovery_counter equ 0x7f295
actor_visibility_timer equ 0x7f48a
actor_mode equ 0x7f67f
board_state_7f874 equ 0x7f874
loaded_level equ 0x7f87d
current_board equ 0x7f87e
next_player equ 0x18fd78
first_player equ 0x19028a
engine_1ed1a0 equ 0x1ed1a0
save_state_1f6020 equ 0x1f6020
engine_1f9ca0 equ 0x1f9ca0
next_sprite_stat equ 0x1fbca0
save_state_1fdca0 equ 0x1fdca0
sprite equ 0x2040a0
walls equ 0x2310a0
sectors equ 0x27c3a0
engine_286b88 equ 0x286b88
engine_286ba0 equ 0x286ba0
engine_286ba8 equ 0x286ba8
save_state_287e74 equ 0x287e74
board_state_287e78 equ 0x287e78
totalclock equ 0x287e88
hit_sprite_list_head equ 0x28811c
engine_28891e equ 0x28891e
engine_289150 equ 0x289150
numwalls equ 0x289152
numsectors equ 0x289154
numpalookups equ 0x289156
engine_2891da equ 0x2891da

; One record per call. Field order and size are part of the save format.
%macro fread_field 2
    mov ebx, 1
    mov edx, %2
    mov eax, %1
    mov ecx, esi
    call fread
%endmacro

read_game_data:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x14
    push eax
    push strict dword load_slot_format
    lea eax, [esp + 0x14]
    lea edi, [esp + 0x8]
    push eax
    lea edx, [esp + 0x18]
    mov esi, load_basename
    call format_string
    add esp, 0xc
    mov eax, esp
    movsd
    movsd
    movsb
    call append_string
    mov edx, load_mode
    mov eax, esp
    call fopen
    mov edi, eax
    mov esi, eax
    test eax, eax
    jnz short .read_player_count
    mov eax, 0xffffffff
    jmp near .return

.read_player_count:
    mov ebx, 0x1
    mov edx, 0x2
    mov ecx, eax
    mov eax, player_count
    call fread
    mov ebx, 0x1
    mov edx, 0x2
    mov eax, local_player
    mov ecx, edi
    call fread
    mov ebx, 0x1
    mov edx, 0x2
    mov eax, first_player
    mov ecx, edi
    call fread
    mov ebx, 0x1
    mov edx, 0x20
    mov eax, next_player
    mov ecx, edi
    call fread
    movsx edi, word [first_player]
    jmp short .branch_2f52c

.initialize_player_before_restore:
    movsx eax, di
    call initialize_board_entry
    movsx edi, word [nosplit edi*2 + next_player]

.branch_2f52c:
    test edi, edi
    jnl short .initialize_player_before_restore
    fread_field player_x, 0x40
    fread_field player_y, 0x40
    fread_field player_z, 0x40
    fread_field player_horizon, 0x40
    fread_field board_state_5ae1c, 0x40
    fread_field motion_state_62f4c, 0x40
    fread_field player_angle, 0x20
    fread_field player_sector, 0x20
    fread_field previous_player_sector, 0x20
    fread_field board_state_62f2c, 0x20
    fread_field board_state_6317c, 0x20
    fread_field board_state_630bc, 0x40
    fread_field status_right_tenths, 0x40
    fread_field board_state_6304c, 0x20
    fread_field motion_state_6306c, 0x20
    fread_field player_mode, 0x10
    fread_field motion_state_630ac, 0x10
    fread_field save_state_5addc, 0x20
    fread_field save_state_5adfc, 0x20
    fread_field save_state_5abbc, 0x40
    fread_field save_state_5abfc, 0x40
    fread_field numsectors, 0x2
    movsx edx, word [numsectors]
    mov eax, edx
    mov ebx, 0x1
    shl eax, byte 0x2
    mov ecx, esi
    add edx, eax
    mov eax, sectors
    shl edx, byte 0x3
    call fread
    fread_field numwalls, 0x2
    mov ebx, 0x1
    mov eax, walls
    movsx edx, word [numwalls]
    mov ecx, esi
    shl edx, byte 0x5
    call fread
    fread_field sprite, 0x2c000
    fread_field engine_28891e, 0x802
    fread_field save_state_1f6020, 0x2000
    fread_field engine_1f9ca0, 0x2000
    fread_field hit_sprite_list_head, 0x802
    fread_field save_state_1fdca0, 0x2000
    fread_field next_sprite_stat, 0x2000
    fread_field keyboard_forward, 0x4
    fread_field keyboard_strafe, 0x4
    fread_field keyboard_turn, 0x4
    fread_field selection, 0x4
    mov ebx, 0x1
    mov eax, input_forward
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, previous_local_input
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, input_strafe
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, board_state_7def5
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, input_turn
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, board_state_7def6
    mov ecx, esi
    mov edx, ebx
    call fread
    fread_field input_actions, 0x2
    fread_field board_state_7def7, 0x2
    fread_field second_player_selection, 0x4
    fread_field second_player_input, 0x5
    fread_field board_state_5ac8c, 0x50
    fread_field previous_input, 0x50
    fread_field board_filename, 0x50
    fread_field listener_index, 0x2
    fread_field saved_mouse_buttons, 0x2
    fread_field brightness, 0x2
    fread_field near_sector, 0x2
    fread_field near_sprite, 0x2
    fread_field near_wall, 0x2
    fread_field actor_clock, 0x4
    fread_field save_state_770ac, 0x4
    fread_field near_tag_distance, 0x4
    fread_field board_state_1cf6c, 0x20
    fread_field board_state_7deca, 0x2
    fread_field board_state_1ccac, 0x20
    fread_field board_state_7dece, 0x2
    fread_field board_state_1cc8c, 0x20
    fread_field board_state_7dec4, 0x2
    fread_field board_state_1ceec, 0x80
    fread_field board_state_7decc, 0x2
    fread_field board_state_1d08c, 0x80
    fread_field board_state_7dec2, 0x2
    fread_field board_state_1d10c, 0x20
    fread_field board_state_1cc4c, 0x20
    fread_field board_state_1cc6c, 0x20
    fread_field board_state_7dec6, 0x2
    fread_field board_state_1ce2c, 0x40
    fread_field board_state_1ceac, 0x40
    fread_field board_state_1cdec, 0x40
    fread_field board_state_1ce6c, 0x40
    fread_field board_state_1cd2c, 0x40
    fread_field board_state_7debe, 0x2
    fread_field board_state_1bb3c, 0x140
    fread_field board_state_1bc7c, 0x40
    fread_field board_state_1babc, 0x40
    fread_field board_state_1bcbc, 0x40
    fread_field board_state_1c3fc, 0x40
    fread_field board_state_1c12c, 0x40
    fread_field board_state_1bafc, 0x40
    fread_field board_state_1c43c, 0x400
    fread_field board_state_1c83c, 0x400
    fread_field board_state_1bab4, 0x8
    fread_field board_state_1cc44, 0x8
    fread_field board_state_7dec0, 0x2
    fread_field board_state_1c2fc, 0x100
    fread_field board_state_1c1fc, 0x100
    fread_field board_state_1baa4, 0x10
    fread_field board_state_1ba94, 0x10
    fread_field board_state_1bd1c, 0x400
    fread_field board_state_1cc3c, 0x8
    fread_field board_state_7debc, 0x2
    fread_field board_state_1c17c, 0x80
    fread_field board_state_1c16c, 0x10
    fread_field board_state_1bd0c, 0x10
    fread_field board_state_1c11c, 0x10
    fread_field board_state_1bcfc, 0x10
    fread_field board_state_1a214, 0x10
    fread_field board_state_1ba34, 0x10
    fread_field board_state_1a224, 0x10
    fread_field board_state_1a204, 0x10
    fread_field board_state_1ba84, 0x10
    fread_field fini_table_end, 0x20
    fread_field board_state_1ba44, 0x20
    fread_field board_state_1ba64, 0x20
    mov ebx, 0x1
    mov edx, 0x800
    mov eax, restore_addresses
    mov ecx, esi
    mov edi, 0x1ff
    call fread
    jmp short .branch_2fed9

.branch_2fec0:
    mov ebx, sectors
    mov edx, [nosplit edi*4 + restore_addresses]
    shl ebx, byte 0x2
    dec edi
    add edx, ebx
    mov [nosplit edi*4 + save_state_1a238], edx

.branch_2fed9:
    test edi, edi
    jnl short .branch_2fec0
    fread_field restore_values, 0x800
    fread_field activation_state_1aa34, 0x800
    fread_field save_state_19a04, 0x800
    fread_field restore_count, 0x4
    fread_field totalclock, 0x4
    fread_field last_tick, 0x4
    fread_field save_state_287e74, 0x4
    fread_field board_state_287e78, 0x4
    fread_field numpalookups, 0x2
    fread_field engine_286ba8, 0x4
    fread_field engine_286ba0, 0x4
    mov ebx, 0x1
    mov eax, engine_2891da
    mov ecx, esi
    mov edx, ebx
    call fread
    fread_field engine_286b88, 0x4
    fread_field engine_1ed1a0, 0x200
    fread_field engine_289150, 0x2
    fread_field save_state_202c, 0x4
    fread_field last_sequence_clock, 0x4
    fread_field last_frame_tick, 0x4
    fread_field level_sector_count, 0x34
    fread_field level_sector_ids, 0xd00
    fread_field level_sector_x, 0x1a00
    fread_field level_left_icon, 0x9c
    fread_field left_icon, 0x2
    fread_field middle_icon, 0x2
    fread_field right_icon, 0x2
    fread_field activation_sprite_count, 0x2
    fread_field activation_sprite_index, 0x20
    fread_field activation_counter, 0x10
    fread_field smoothed_mouse_dx, 0x2
    fread_field toggled_word, 0x2
    fread_field modified_levels, 0x1a
    mov ebx, 0x1
    mov eax, loaded_level
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, current_board
    mov ecx, esi
    mov edx, ebx
    call fread
    mov ebx, 0x1
    mov eax, destination_level
    mov ecx, esi
    mov edx, ebx
    call fread
    fread_field destination_x, 0x4
    fread_field destination_y, 0x4
    fread_field destination_entry, 0x2
    fread_field level_names, 0x21c
    fread_field difficulty_divisor, 0x2
    fread_field effect_count, 0x2
    fread_field effect_speed, 0x2
    fread_field status_flag, 0x2
    fread_field interaction_state_2263, 0x2
    fread_field toggled_mode, 0x2
    fread_field item_enabled, 0x10
    fread_field item_stock, 0x10
    fread_field item_alternate_stock, 0x10
    fread_field player_action, 0x2
    fread_field save_state_2299, 0x2
    fread_field ticks_per_step, 0x4
    fread_field last_step_clock, 0x4
    fread_field advance_clock, 0x2
    fread_field board_state_7494c, 0x20
    fread_field interaction_state_729dc, 0x20
    fread_field sprite_actor_index, 0x2000
    fread_field actor_sprite_index, 0x3ea
    fread_field actor_board, 0x1f5
    fread_field saved_actor_x, 0x177c
    fread_field actor_enabled, 0x1f5
    fread_field saved_actor_lotag, 0x3ea
    fread_field actor_sequence_initial, 0x1f5
    fread_field actor_health, 0x3ea
    fread_field actor_z_offset, 0x7d4
    fread_field actor_projectile_type, 0x1f5
    fread_field actor_recovery_counter, 0x1f5
    fread_field actor_visibility_timer, 0x1f5
    fread_field actor_state, 0x1f5
    fread_field actor_frame, 0x1f5
    fread_field actor_state_byte, 0x1f5
    fread_field actor_x, 0x7d4
    fread_field actor_y, 0x7d4
    fread_field actor_sector, 0x3ea
    fread_field actor_first_waypoint, 0x7d4
    fread_field waypoint_x, 0x800
    fread_field actor_destination_x, 0x1f50
    fread_field actor_kind, 0x1f5
    fread_field actor_mode, 0x1f5
    fread_field actor_profile, 0x1f5
    fread_field actor_tiles, 0x233a
    fread_field actor_delay_byte, 0x1f5
    fread_field template_cstat, 0x13f
    fread_field weapon_action, 0x2
    fread_field weapon_animation_state, 0x2
    fread_field selected_weapon, 0x2
    fread_field selected_weapon_2be2, 0x2
    fread_field weapon_tile, 0x2
    fread_field weapon_x_offset, 0x2
    fread_field weapon_y_offset, 0x2
    fread_field close_hit_tile, 0x2
    fread_field alternate_fire_requested, 0x2
    fread_field force_attack_frame, 0x20
    fread_field defer_mode_change, 0x20
    fread_field player_hit_timer, 0x20
    fread_field player_hit_x, 0x40
    fread_field player_hit_y, 0x40
    fread_field moving_sprite_count, 0x2
    fread_field moving_sprites, 0x800
    fread_field pan_sector_count, 0x2
    fread_field pan_sectors, 0x80
    fread_field float_sprite_count, 0x2
    fread_field float_sprite_list, 0x400
    fread_field projectile_count, 0x2
    fread_field projectile_list, 0x400
    fread_field active, 0x2
    fread_field list, 0x400
    fread_field map_x, 0x2
    fread_field map_scale_or_y, 0x2
    fread_field map_offset_y, 0x2
    fread_field mouse_buttons, 0x2
    fread_field mouse_dx, 0x2
    fread_field mouse_dy, 0x2
    fread_field button_latch_disabled, 0x2
    fread_field held_sprite, 0x2
    fread_field map_mode, 0x2
    fread_field mouse_motion_disabled, 0x2
    fread_field inventory_grid, 0x48
    mov ebx, 0x1
    mov eax, cursor_mode
    mov ecx, esi
    mov edx, ebx
    call fread
    fread_field actor_target, 0x2
    fread_field special_sector, 0x2
    fread_field trigger_count, 0x2
    fread_field trigger_sprite, 0x194
    mov eax, esi
    call sub_40354
    mov eax, esi
    call fclose
    movsx edi, word [first_player]
    jmp short .branch_3095b

.initialize_player_after_restore:
    movsx eax, di
    call initialize_board_entry
    movsx edi, word [nosplit edi*2 + next_player]

.branch_3095b:
    test edi, edi
    jnl short .initialize_player_after_restore
    mov edi, status_text
    mov esi, loaded_message
    mov eax, status_text
    movsd
    movsd
    movsd
    movsb
    call strlen
    mov [board_state_7f874], al
    and eax, strict dword 0xff
    shl eax, byte 0x4
    mov edx, [totalclock]
    add edx, strict dword 0x168
    add edx, eax
    mov [status_expiration], edx
    xor eax, eax

.return:
    add esp, 0x14
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
