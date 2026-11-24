; Serialize game state to GAMEDATA.
BITS 32
ORG 0x309a3

save_slot_format equ 0x5fc
save_basename equ 0x603
save_mode equ 0x60c
saved_message equ 0x60f
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
sub_4032e equ 0x4032e
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
fclose equ 0x60802
fwrite equ 0x60944
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
; Fixed-size field transfers are supplied by the matching C contexts.
section .text align=1
write_game_data:
.write_player_count equ 0x309f3
.branch_313c5 equ 0x313c5
.branch_313de equ 0x313de
.branch_313ff equ 0x313ff
.branch_31418 equ 0x31418
.return equ 0x31ebb
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x14
    push eax
    push strict dword save_slot_format
    lea eax, [esp + 0x14]
    lea edi, [esp + 0x8]
    push eax
    lea edx, [esp + 0x18]
    mov esi, save_basename
    call format_string
    add esp, 0xc
    mov eax, esp
    movsd
    movsd
    movsb
    call append_string
    mov edx, save_mode
    mov eax, esp
    call fopen
    mov edi, eax
    mov esi, eax
    test eax, eax
    jnz short .write_player_count
    mov eax, 0xffffffff
    jmp near .return
    mov ebx, 0x1
    mov edx, 0x2
    mov ecx, eax
    mov eax, player_count
    call fwrite

; C field run 0 ends here.
section .retained_1 align=1 vstart=0x31e73 follows=.text
    mov eax, esi

; C field run 1 ends here.
section .retained_2 align=1 vstart=0x31e7a follows=.retained_1
    call sub_4032e
    mov eax, esi

; C field run 2 ends here.
section .retained_3 align=1 vstart=0x31e86 follows=.retained_2
    call fclose

; C field run 3 ends here.
section .retained_4 align=1 vstart=0x31ebb follows=.retained_3
    add esp, 0x14
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
