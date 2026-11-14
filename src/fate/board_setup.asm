; Load the selected map and prepare actor, sector and wall state.
BITS 32
ORG 0x27a8c

board_not_found_message equ 0x4cc
board_door_limit_message equ 0x4dd
pan_sector_count equ 0x2bea
event_write_index equ 0x3cdc
board_state_3ce0 equ 0x3ce0
event_read_index equ 0x3ce4
last_tick equ 0x3cea
saved_clock equ 0x3cee
board_state_3cf2 equ 0x3cf2
board_state_3cf6 equ 0x3cf6
board_state_3d02 equ 0x3d02
input_mode equ 0x3d03
restore_count equ 0x3e04
process_sector_tag equ 0x11f94
fini_table_end equ 0x199e4
board_state_1ba44 equ 0x1ba44
board_state_1ba64 equ 0x1ba64
board_state_1ba94 equ 0x1ba94
board_state_1baa4 equ 0x1baa4
board_state_1bab4 equ 0x1bab4
board_state_1c1fc equ 0x1c1fc
board_state_1c2fc equ 0x1c2fc
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
board_state_209fc equ 0x209fc
projectile_positions equ 0x20a2c
restore_board_actor_sprites equ 0x26749
report_error equ 0x26a03
board_state_2ca2c equ 0x2ca2c
board_state_2ca6c equ 0x2ca6c
board_state_2caac equ 0x2caac
board_state_2caec equ 0x2caec
board_state_2cb2c equ 0x2cb2c
initialize_board_sprite_state equ 0x2e52b
shutdown_subsystem_d equ 0x2f258
finalize_board_state equ 0x34211
register_board_coordinate equ 0x344e4
shutdown_subsystem_c equ 0x34860
shutdown_subsystem_b equ 0x34bf6
initialize_board_subsystem_a equ 0x3fe1b
initialize_board_subsystem_b equ 0x40268
print_message equ 0x40bb4
shutdown_subsystem_e equ 0x4124c
shutdown_subsystem_a equ 0x4164f
load_map equ 0x49f89
shutdown_engine equ 0x4b390
previous_input equ 0x55b6c
board_state_55b6d equ 0x55b6d
board_state_55b6e equ 0x55b6e
board_state_55b6f equ 0x55b6f
current_input equ 0x5ac3c
board_state_5ac3d equ 0x5ac3d
board_state_5ac3e equ 0x5ac3e
board_state_5ac3f equ 0x5ac3f
board_state_5ac8c equ 0x5ac8c
board_state_5ac8d equ 0x5ac8d
board_state_5ac8e equ 0x5ac8e
player_input_word equ 0x5ac8f
board_state_5acdc equ 0x5acdc
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
board_state_5ae1c equ 0x5ae1c
format_string equ 0x601f3
runtime_exit equ 0x60353
board_state_62edc equ 0x62edc
player_mode equ 0x62f1c
player_sprite equ 0x62f2c
player_horizon equ 0x62f8c
board_state_6304c equ 0x6304c
player_angle equ 0x6308c
board_state_630bc equ 0x630bc
board_state_6317c equ 0x6317c
status_right_tenths equ 0x6319c
error_buffer equ 0x67e3c
sprite_actor_index equ 0x709dc
board_state_7494c equ 0x7494c
activation_counter equ 0x7496c
activation_sprite_index equ 0x7497c
level_sector_x equ 0x7499c
level_sector_y equ 0x749a0
level_sector_ids equ 0x7639c
actor_clock equ 0x770b8
second_player_selection equ 0x770c0
frame_index equ 0x770c4
selection equ 0x770c8
board_state_770cc equ 0x770cc
level_sector_count equ 0x7aa3c
actor_sprite_index equ 0x7dab8
board_state_7debc equ 0x7debc
board_state_7debe equ 0x7debe
encounter_actor_field equ 0x7dec0
board_state_7dec2 equ 0x7dec2
board_state_7dec4 equ 0x7dec4
board_state_7dec6 equ 0x7dec6
board_state_7deca equ 0x7deca
board_state_7decc equ 0x7decc
board_state_7dece equ 0x7dece
board_state_7ded8 equ 0x7ded8
activation_sprite_count equ 0x7def0
previous_local_input equ 0x7def4
board_state_7def5 equ 0x7def5
board_state_7def6 equ 0x7def6
board_state_7def7 equ 0x7def7
board_state_7f874 equ 0x7f874
current_level equ 0x7f87e
first_player equ 0x19028a
tile_height equ 0x1f4020
sprite_x equ 0x2040a0
sprite_z equ 0x2040a8
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_yrepeat equ 0x2040b5
sprite_lotag equ 0x2040c6
sprite_hitag equ 0x2040c8
sprite_extra equ 0x2040ca
wall_x equ 0x2310a0
wall_y equ 0x2310a4
wall_next_index equ 0x2310aa
engine_2310ac equ 0x2310ac
board_state_2310ba equ 0x2310ba
sector_wall_start equ 0x27c3a0
sector_wall_count equ 0x27c3a2
sector_floor_z equ 0x27c3a8
sector_lotag equ 0x27c3c2
board_state_287e78 equ 0x287e78
presentation_width equ 0x287e90
wall_count equ 0x289152
sector_count equ 0x289154

prepare_loaded_board:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x1c
    mov esi, eax
    mov edx, 0x11
    xor ah, ah
    xor ebx, ebx
    mov [board_state_7f874], ah
    mov [board_state_3d02], ah
    mov [board_state_287e78], edx
    mov [restore_count], ebx
    mov [selection], ebx
    mov [second_player_selection], ebx
    xor dh, dh
    mov [esp + 0x4], ebx
    mov [input_mode], dh
    jmp short .check_board_slot_reset

.reset_board_slot:
    imul eax, eax, 0x2c
    xor edx, edx
    mov ecx, [esp + 0x4]
    mov [eax + sprite_hitag], dx
    inc ecx
    mov [eax + sprite_lotag], dx
    mov [esp + 0x4], ecx
    mov [eax + sprite_extra], dx

.check_board_slot_reset:
    mov eax, [esp + 0x4]
    cmp eax, strict dword 0x1000
    jl short .reset_board_slot
    push strict dword player_sector
    mov ecx, player_z
    mov ebx, player_y
    push strict dword player_angle
    mov edx, player_x
    mov eax, esi
    call load_map
    cmp eax, -1
    jnz short .begin_sprite_scan_reset
    call shutdown_subsystem_a
    call shutdown_subsystem_b
    call shutdown_subsystem_c
    call shutdown_subsystem_d
    call shutdown_engine
    call shutdown_subsystem_e
    mov eax, 0x3
    int byte 0x10
    push strict dword board_not_found_message
    call print_message
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.begin_sprite_scan_reset:
    xor edx, edx
    mov [esp + 0x4], edx
    jmp short .check_sprite_clear_index

.clear_sprite_state:
    mov ebp, esi
    imul eax, esi, 0x2c
    xor esi, esi
    mov [eax + sprite_extra], si
    mov eax, ebp
    inc eax
    mov [esp + 0x4], eax

.check_sprite_clear_index:
    mov esi, [esp + 0x4]
    cmp esi, strict dword 0x1000
    jl short .clear_sprite_state
    xor edi, edi
    mov [esp + 0x4], edi
    mov edi, 0xffffffff
    jmp short .check_actor_sprite_index

.clear_actor_sprite:
    lea ecx, [edx + 0x1]
    mov [nosplit edx*2 + actor_sprite_index], di
    mov [esp + 0x4], ecx

.check_actor_sprite_index:
    mov edx, [esp + 0x4]
    cmp edx, strict dword 0x1f4
    jng short .clear_actor_sprite
    xor ebx, ebx
    mov edx, 0xffffffff
    mov [esp + 0x4], ebx
    jmp short .check_sprite_actor_index

.clear_sprite_actor:
    lea ebp, [esi + 0x1]
    mov [nosplit esi*2 + sprite_actor_index], dx
    mov [esp + 0x4], ebp

.check_sprite_actor_index:
    mov esi, [esp + 0x4]
    cmp esi, strict dword 0x1000
    jl short .clear_sprite_actor
    call restore_board_actor_sprites
    xor edi, edi
    mov esi, 0x3e8
    mov [esp + 0x4], edi
    jmp near .check_sprite_scan_index

.scan_sprite:
    mov edi, 0x300
    mov edx, [player_x]
    mov bx, [player_angle]
    xor ecx, ecx
    xor ebp, ebp
    mov [nosplit eax*4 + status_right_tenths], esi
    mov [nosplit eax*4 + player_x], edx
    mov [nosplit eax*2 + player_angle], bx
    mov [nosplit eax*4 + board_state_630bc], ecx
    mov [nosplit eax*4 + board_state_5ae1c], edi
    mov [nosplit eax*4 + board_state_62edc], ebp
    mov ch, 0x3
    mov edi, 0xffffffff
    mov edx, [player_y]
    mov bx, [player_sector]
    mov [nosplit eax*4 + player_y], edx
    mov [nosplit eax*2 + player_sector], bx
    mov [nosplit eax*2 + board_state_5acdc], bx
    mov ebx, 0x64
    mov [eax + player_mode], ch
    mov [nosplit eax*4 + player_horizon], ebx
    mov bx, [presentation_width]
    mov [nosplit eax*2 + player_sprite], di
    inc ebx
    mov edx, [player_z]
    mov [board_state_7ded8], bx
    mov ebx, [player_x]
    xor ecx, ecx
    mov [nosplit eax*4 + board_state_2caac], ebx
    mov ebx, [player_y]
    mov [nosplit eax*4 + player_z], edx
    mov [nosplit eax*4 + board_state_2caec], ebx
    mov ebx, [player_z]
    mov [nosplit eax*2 + board_state_6304c], cx
    mov [nosplit eax*4 + board_state_2ca6c], ebx
    mov ebx, [player_horizon]
    mov [nosplit eax*2 + board_state_6317c], cx
    mov [nosplit eax*4 + board_state_2ca2c], ebx
    mov ebx, [board_state_5ae1c]
    mov edx, eax
    mov [nosplit eax*4 + board_state_2cb2c], ebx
    mov ax, [player_angle]
    mov [nosplit edx*2 + board_state_209fc], ax
    mov eax, edx
    inc eax
    mov [esp + 0x4], eax

.check_sprite_scan_index:
    mov eax, [esp + 0x4]
    cmp eax, 0x10
    jl near .scan_sprite
    xor edx, edx
    xor ebx, ebx
    xor ecx, ecx
    mov [board_state_770cc], edx
    mov [frame_index], edx
    mov [event_write_index], edx
    mov [board_state_3ce0], edx
    mov [event_read_index], edx
    mov [board_state_3cf2], edx
    call initialize_board_sprite_state
    xor ebx, edx
    mov [esp + 0x4], edx
    mov [board_state_7def7], bx
    xor bl, bl
    xor cl, dl
    mov [board_state_7def6], bl
    xor bh, bh
    mov [previous_local_input], cl
    mov [board_state_7def5], bh
    jmp short .check_sector_clear_index

.clear_sector_state:
    mov eax, edx
    shl eax, byte 0x2
    mov ecx, [esp + 0x4]
    add eax, edx
    xor dl, dl
    inc ecx
    mov [eax + previous_input], dl
    mov [eax + board_state_5ac8c], dl
    mov [eax + current_input], dl
    xor dh, dh
    mov [esp + 0x4], ecx
    mov [eax + board_state_55b6d], dl
    mov [eax + board_state_5ac8d], dl
    mov [eax + board_state_5ac3d], dl
    mov [eax + board_state_55b6e], dl
    mov [eax + board_state_5ac8e], dl
    mov [eax + board_state_5ac3e], dl
    mov [eax + board_state_55b6f], dx
    mov [eax + player_input_word], dx
    mov [eax + board_state_5ac3f], dx

.check_sector_clear_index:
    mov edx, [esp + 0x4]
    cmp edx, 0x10
    jl short .clear_sector_state
    xor ebx, ebx
    mov edi, 0xffffffff
    mov [esp + 0x4], ebx
    jmp short .check_wall_clear_index

.clear_wall_state:
    lea ebp, [esi + 0x1]
    xor edx, edx
    mov [eax + fini_table_end], di
    mov [esp + 0x4], ebp
    mov [eax + board_state_1ba44], dx

.check_wall_clear_index:
    mov eax, [esp + 0x4]
    mov esi, [esp + 0x4]
    add eax, eax
    cmp esi, 0x10
    jl short .clear_wall_state
    xor ebx, ebx
    xor edi, edi
    mov [board_state_7dece], bx
    mov [board_state_7dec4], bx
    mov [board_state_7dec2], bx
    mov [board_state_7dec6], bx
    mov [board_state_7debe], bx
    mov [encounter_actor_field], bx
    mov [board_state_7debc], bx
    mov [pan_sector_count], bx
    mov [esp + 0x4], edi
    mov [eax + board_state_1ba64], bx
    jmp near .check_sector_index

.inspect_sector_tag:
    mov eax, edx
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x3
    mov si, [edx + sector_lotag]
    cmp si, 0xe
    jc short .classify_lower_sector_tags
    jna near .measure_sector_center
    cmp si, 0x47
    jc short .classify_lower_door_tags
    cmp si, 0x49
    jna near .register_door_sector
    cmp si, 0x51
    jc near .check_sector_tag_callback
    cmp si, 0x53
    jna near .register_door_sector
    cmp si, 0xa1
    jc near .check_sector_tag_callback
    cmp si, 0xa3

.check_upper_door_tag:
    jna short .register_door_sector
    jmp near .check_sector_tag_callback

.classify_lower_door_tags:
    cmp si, 0x10
    jc near .check_sector_tag_callback
    jna short .register_door_sector
    cmp si, 0x3d
    jc near .check_sector_tag_callback
    cmp si, 0x3f
    jmp short .check_upper_door_tag

.classify_lower_sector_tags:
    cmp si, 0xa
    jc short .classify_lowest_sector_tags
    jna near .store_sector_group_b
    cmp si, 0xb
    jna near .store_sector_group_c
    cmp si, 0xc
    jz near .measure_sector_bounds
    jmp near .check_sector_tag_callback

.classify_lowest_sector_tags:
    cmp si, 0x4
    jc near .check_sector_tag_callback
    jna near .store_sector_group_a
    cmp si, 0x6
    jc near .check_sector_tag_callback
    cmp si, 0x8
    ja near .check_sector_tag_callback

.register_door_sector:
    movsx edx, byte [current_level]
    mov bx, [nosplit edx*2 + level_sector_count]
    inc ebx
    movsx eax, bx
    mov [nosplit edx*2 + level_sector_count], bx
    cmp eax, 0x1f
    jng short .store_door_sector
    push edx
    push strict dword board_door_limit_message
    push strict dword error_buffer
    call format_string
    add esp, 0xc
    mov eax, error_buffer
    call report_error

.store_door_sector:
    movsx eax, byte [current_level]
    movsx edx, word [nosplit eax*2 + level_sector_count]
    shl edx, byte 0x2
    shl eax, byte 0x7
    add eax, edx
    mov edx, [esp + 0x4]
    mov [eax + level_sector_ids], dx
    mov edx, [esp + 0x4]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    xor ebx, ebx
    mov dx, [nosplit eax*8 + sector_wall_start]
    mov si, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x18], edx
    mov ecx, edx
    movsx edx, dx
    add ecx, esi
    xor esi, esi
    jmp short .check_door_wall_index

.initialize_door_wall:
    mov eax, edx
    shl eax, byte 0x5
    inc edx
    mov edi, [eax + wall_x]
    mov ebp, [eax + wall_y]
    add esi, edi
    add ebx, ebp

.check_door_wall_index:
    movsx eax, cx
    cmp edx, eax
    jl short .initialize_door_wall
    movsx edi, word [esp + 0x18]
    mov edx, esi
    sub eax, edi
    sar edx, byte 0x1f
    mov edi, eax
    mov eax, esi
    idiv edi
    mov esi, eax
    mov edx, ebx
    mov eax, ebx
    sar edx, byte 0x1f
    idiv edi
    movsx edx, byte [current_level]
    mov ebx, eax
    movsx eax, word [nosplit edx*2 + level_sector_count]
    shl edx, byte 0x8
    mov [edx + eax*8 + level_sector_x], esi
    mov [edx + eax*8 + level_sector_y], ebx
    jmp near .check_sector_tag_callback

.store_sector_group_a:
    mov dx, [board_state_7dec2]
    mov ebx, [esp + 0x4]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1d08c], bx
    mov [board_state_7dec2], dx
    jmp near .check_sector_tag_callback

.store_sector_group_b:
    mov dx, [board_state_7dece]
    mov ebx, [esp + 0x4]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1ccac], bx
    mov [board_state_7dece], dx
    jmp near .check_sector_tag_callback

.store_sector_group_c:
    mov dx, [board_state_7dec4]
    mov ebx, [esp + 0x4]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1cc8c], bx
    mov [board_state_7dec4], dx
    jmp near .check_sector_tag_callback

.measure_sector_bounds:
    mov edi, 0x7fffffff
    mov ecx, 0x80000000
    mov ax, [edx + sector_wall_start]
    mov esi, edi
    mov [esp + 0x10], ecx
    mov [esp + 0xc], ecx
    mov [esp + 0x18], eax
    mov ecx, eax
    mov ax, [edx + sector_wall_count]
    movsx edx, word [esp + 0x18]
    add ecx, eax
    jmp short .check_boundary_wall_index

.inspect_boundary_wall:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [eax + wall_x]
    cmp edi, ebp
    jng short .check_minimum_x
    mov edi, ebp

.check_minimum_x:
    mov eax, edx
    shl eax, byte 0x5
    mov ebx, [eax + wall_y]
    cmp esi, ebx
    jng short .check_maximum_x
    mov esi, ebx

.check_maximum_x:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [esp + 0x10]
    mov ebx, [eax + wall_x]
    cmp ebx, ebp
    jng short .check_minimum_y
    mov [esp + 0x10], ebx

.check_minimum_y:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [esp + 0xc]
    mov ebx, [eax + wall_y]
    cmp ebx, ebp
    jng short .check_maximum_y
    mov [esp + 0xc], ebx

.check_maximum_y:
    mov eax, edx
    shl eax, byte 0x5
    movsx eax, word [eax + board_state_2310ba]
    cmp eax, 0x3
    jnz short .advance_boundary_wall
    mov [esp + 0x8], edx

.advance_boundary_wall:
    inc edx

.check_boundary_wall_index:
    movsx eax, cx
    cmp edx, eax
    jl short .inspect_boundary_wall
    mov eax, [esp + 0x8]
    shl eax, byte 0x5
    cmp edi, [eax + wall_x]
    jnz short .check_bound_b
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc4c], 0xfff0

.check_bound_b:
    mov eax, [esp + 0x8]
    shl eax, byte 0x5
    cmp esi, [eax + wall_y]
    jnz short .check_bound_c
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc6c], 0xfff0

.check_bound_c:
    mov eax, [esp + 0x8]
    shl eax, byte 0x5
    mov edx, [esp + 0x10]
    cmp edx, [eax + wall_x]
    jnz short .check_bound_d
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc4c], 0x10

.check_bound_d:
    mov eax, [esp + 0x8]
    shl eax, byte 0x5
    mov ebx, [esp + 0xc]
    cmp ebx, [eax + wall_y]
    jnz short .store_sector_bounds
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc6c], 0x10

.store_sector_bounds:
    movsx eax, word [esp + 0x18]
    shl eax, byte 0x5
    mov ax, [eax + engine_2310ac]
    mov ecx, 0x7fffffff
    mov [esp + 0x14], eax
    movsx eax, word [board_state_7dec6]
    mov edx, 0x80000000
    mov [nosplit eax*4 + board_state_1ce2c], ecx
    mov [nosplit eax*4 + board_state_1cdec], edx
    mov [nosplit eax*4 + board_state_1ce6c], edx
    movsx edx, word [esp + 0x14]
    mov [nosplit eax*4 + board_state_1ceac], ecx
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov dx, [nosplit eax*8 + sector_wall_start]
    mov bx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x18], edx
    mov ecx, edx
    movsx edx, dx
    add ecx, ebx
    jmp near .check_boundary_init_index

.initialize_boundary_wall:
    mov eax, edx
    shl eax, byte 0x5
    movsx ebx, word [board_state_7dec6]
    mov ebp, [eax + wall_x]
    shl ebx, byte 0x2
    cmp ebp, [ebx + board_state_1ce2c]
    jnl short .check_boundary_coordinate_b
    mov [ebx + board_state_1ce2c], ebp

.check_boundary_coordinate_b:
    mov eax, edx
    shl eax, byte 0x5
    movsx ebx, word [board_state_7dec6]
    mov ebp, [eax + wall_y]
    shl ebx, byte 0x2
    cmp ebp, [ebx + board_state_1ceac]
    jnl short .check_boundary_coordinate_c
    mov [ebx + board_state_1ceac], ebp

.check_boundary_coordinate_c:
    mov eax, edx
    shl eax, byte 0x5
    movsx ebx, word [board_state_7dec6]
    mov ebp, [eax + wall_x]
    shl ebx, byte 0x2
    cmp ebp, [ebx + board_state_1cdec]
    jng short .check_boundary_coordinate_d
    mov [ebx + board_state_1cdec], ebp

.check_boundary_coordinate_d:
    mov eax, edx
    shl eax, byte 0x5
    movsx ebx, word [board_state_7dec6]
    mov ebp, [eax + wall_y]
    shl ebx, byte 0x2
    cmp ebp, [ebx + board_state_1ce6c]
    jng short .register_boundary_coordinates
    mov [ebx + board_state_1ce6c], ebp

.register_boundary_coordinates:
    movsx eax, word [esp + 0x14]
    mov ebx, eax
    shl ebx, byte 0x2
    add ebx, eax
    mov eax, sector_wall_start
    shl ebx, byte 0x3
    add eax, ebx
    mov ebx, edx
    mov ebp, wall_x
    shl ebx, byte 0x5
    add eax, 0x8
    add ebp, ebx
    call register_board_coordinate
    mov eax, ebp
    call register_board_coordinate
    lea eax, [ebp + 0x4]
    call register_board_coordinate
    movsx eax, word [ebx + wall_next_index]
    shl eax, byte 0x5
    add eax, wall_x
    call register_board_coordinate
    movsx eax, word [ebx + wall_next_index]
    shl eax, byte 0x5
    add eax, wall_x
    add eax, 0x4
    inc edx
    call register_board_coordinate

.check_boundary_init_index:
    movsx eax, cx
    cmp edx, eax
    jl near .initialize_boundary_wall
    mov ebx, [esp + 0x4]
    mov edx, ebx
    shl edx, byte 0x2
    add ebx, edx
    shl ebx, byte 0x3
    movsx edx, word [ebx + sector_wall_start]
    shl edx, byte 0x5
    movsx eax, word [board_state_7dec6]
    mov ebp, [edx + wall_x]
    mov ecx, [nosplit eax*4 + board_state_1ce2c]
    sub ebp, edi
    mov edi, [edx + wall_y]
    add ecx, ebp
    sub edi, esi
    mov ebp, [edx + wall_x]
    mov esi, edi
    mov edi, [nosplit eax*4 + board_state_1ceac]
    mov [nosplit eax*4 + board_state_1ce2c], ecx
    add edi, esi
    mov esi, [esp + 0x10]
    mov ecx, [nosplit eax*4 + board_state_1cdec]
    sub esi, ebp
    mov [nosplit eax*4 + board_state_1ceac], edi
    sub ecx, esi
    mov esi, [esp + 0xc]
    mov edi, [edx + wall_y]
    mov edx, esi
    mov ebp, [nosplit eax*4 + board_state_1ce6c]
    sub edx, edi
    mov [nosplit eax*4 + board_state_1cdec], ecx
    sub ebp, edx
    mov edx, [ebx + sector_floor_z]
    mov [nosplit eax*4 + board_state_1ce6c], ebp
    mov [nosplit eax*4 + board_state_1cd2c], edx
    mov ax, [board_state_7dec6]
    mov ebx, [esp + 0x4]
    movsx edx, ax
    inc eax
    mov [nosplit edx*2 + board_state_1d10c], bx
    mov [board_state_7dec6], ax
    jmp near .check_sector_tag_callback

.measure_sector_center:
    mov ax, [edx + sector_wall_start]
    mov si, [edx + sector_wall_count]
    xor edi, edi
    mov [esp + 0x18], eax
    mov ecx, eax
    movsx edx, ax
    add ecx, esi
    xor esi, esi
    jmp short .check_center_wall_index

.sum_wall_coordinates:
    mov ebx, edx
    shl ebx, byte 0x5
    inc edx
    mov ebp, [ebx + wall_x]
    mov eax, [ebx + wall_y]
    add edi, ebp
    add esi, eax

.check_center_wall_index:
    movsx eax, cx
    cmp edx, eax
    jl short .sum_wall_coordinates
    movsx ebp, word [esp + 0x18]
    sub eax, ebp
    mov edx, edi
    mov [esp], eax
    sar edx, byte 0x1f
    mov ebx, [esp]
    mov eax, edi
    idiv ebx
    mov edx, esi
    movsx ebx, word [encounter_actor_field]
    sar edx, byte 0x1f
    mov [nosplit ebx*4 + board_state_1baa4], eax
    mov eax, esi
    idiv dword [esp]
    xor edi, edi
    mov [esp + 0x8], edi
    mov edx, ebp
    mov [nosplit ebx*4 + board_state_1ba94], eax
    jmp short .check_center_wall_registration_index

.register_center_wall:
    mov eax, [esp + 0x8]
    movsx esi, word [encounter_actor_field]
    mov ebx, edx
    shl esi, byte 0x6
    shl eax, byte 0x2
    shl ebx, byte 0x5
    add eax, esi
    mov esi, [ebx + wall_x]
    mov [eax + board_state_1c2fc], esi
    mov esi, [ebx + wall_y]
    mov [eax + board_state_1c1fc], esi
    mov esi, wall_x
    add esi, ebx
    mov eax, esi
    call register_board_coordinate
    lea eax, [esi + 0x4]
    call register_board_coordinate
    movsx eax, word [ebx + wall_next_index]
    shl eax, byte 0x5
    add eax, wall_x
    call register_board_coordinate
    movsx eax, word [ebx + wall_next_index]
    shl eax, byte 0x5
    inc edx
    add eax, wall_x
    mov ebx, [esp + 0x8]
    add eax, 0x4
    inc ebx
    call register_board_coordinate
    mov [esp + 0x8], ebx

.check_center_wall_registration_index:
    movsx eax, cx
    cmp edx, eax
    jl near .register_center_wall
    mov edx, [esp + 0x4]
    movsx eax, word [encounter_actor_field]
    mov si, [encounter_actor_field]
    xor ecx, ecx
    inc esi
    mov [nosplit eax*2 + board_state_1bab4], dx
    mov [nosplit eax*2 + board_state_1cc44], cx
    mov [encounter_actor_field], si

.check_sector_tag_callback:
    mov edx, [esp + 0x4]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0x12
    jl short .advance_sector_index
    cmp eax, 0x1d
    jg short .advance_sector_index
    mov eax, edx
    call process_sector_tag

.advance_sector_index:
    inc dword [esp + 0x4]

.check_sector_index:
    mov edx, [esp + 0x4]
    movsx eax, word [sector_count]
    cmp eax, edx
    jg near .inspect_sector_tag
    movsx eax, byte [current_level]
    call initialize_board_subsystem_a
    movsx eax, byte [current_level]
    xor ebx, ebx
    call initialize_board_subsystem_b
    mov [board_state_7decc], bx
    xor ebx, ebx
    mov [esp + 0x4], ebx
    jmp short .check_final_sprite_index

.scan_final_sprite_tags:
    mov eax, edx
    shl eax, byte 0x5
    movsx eax, word [eax + board_state_2310ba]
    cmp eax, 0x1
    jnz short .advance_final_sprite
    mov ax, [board_state_7decc]
    mov ebx, [esp + 0x4]
    movsx edx, ax
    inc eax
    mov [nosplit edx*2 + board_state_1ceec], bx
    mov [board_state_7decc], ax

.advance_final_sprite:
    inc dword [esp + 0x4]

.check_final_sprite_index:
    mov edx, [esp + 0x4]
    movsx eax, word [wall_count]
    cmp eax, edx
    jg short .scan_final_sprite_tags
    xor ebx, ebx
    mov [esp + 0x4], ebx
    jmp short .check_special_sprite_index

.scan_special_sprites:
    imul eax, esi, 0x2c
    mov dx, [eax + sprite_lotag]
    xor dh, dh
    movsx edx, dx
    cmp edx, 0x64
    jnz short .advance_special_sprite
    movsx edx, word [eax + sprite_tile]
    movsx ebx, word [nosplit edx*2 + tile_height]
    xor edx, edx
    mov dl, [eax + sprite_yrepeat]
    imul edx, ebx
    mov ebx, [eax + sprite_z]
    add edx, edx
    sub ebx, edx
    mov dx, [eax + sprite_cstat]
    mov [eax + sprite_z], ebx
    or edx, strict dword 0x181
    mov [eax + sprite_cstat], dx

.advance_special_sprite:
    inc dword [esp + 0x4]

.check_special_sprite_index:
    mov esi, [esp + 0x4]
    cmp esi, strict dword 0x1000
    jl short .scan_special_sprites
    xor edi, edi
    mov [activation_sprite_count], di
    mov [board_state_7deca], di
    xor edi, edi
    mov [esp + 0x4], edi
    jmp near .check_final_sector_index

.inspect_final_sprite:
    imul eax, esi, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x3a6
    jl short .check_sprite_hitag
    cmp eax, strict dword 0x3a9
    jg short .check_sprite_hitag
    mov bx, [activation_sprite_count]
    inc ebx
    mov [activation_sprite_count], bx
    movsx eax, bx
    mov ebx, [esp + 0x4]
    mov [nosplit eax*2 + activation_sprite_index], bx
    xor bh, bh
    mov [eax + activation_counter], bh

.check_sprite_hitag:
    imul eax, [esp + 0x4], 0x2c
    mov ax, [eax + sprite_hitag]
    xor ah, ah
    cwde
    cmp eax, 0x1
    jl short .check_sprite_lotag
    cmp eax, 0xf
    jg short .check_sprite_lotag
    mov edx, [esp + 0x4]
    mov [nosplit eax*2 + board_state_7494c], dx

.check_sprite_lotag:
    imul eax, [esp + 0x4], 0x2c
    mov ax, [eax + sprite_lotag]
    xor ah, ah
    cwde
    cmp eax, 0x3
    jnz short .advance_final_sector
    mov ax, [board_state_7deca]
    mov ebx, [esp + 0x4]
    movsx edx, ax
    inc eax
    mov [nosplit edx*2 + board_state_1cf6c], bx
    mov [board_state_7deca], ax

.advance_final_sector:
    inc dword [esp + 0x4]

.check_final_sector_index:
    mov esi, [esp + 0x4]
    cmp esi, strict dword 0x1000
    jl near .inspect_final_sprite
    mov dword [esp + 0x4], 0xfff
    jmp short .check_board_slot

.initialize_board_slot:
    mov eax, esi
    shl eax, byte 0x2
    mov edx, esi
    sub eax, esi
    imul esi, esi, 0x2c
    mov edi, projectile_positions
    shl eax, byte 0x2
    mov ecx, 0x3
    add edi, eax
    add esi, sprite_x
    rep movsd
    lea eax, [edx-0x1]
    mov [esp + 0x4], eax

.check_board_slot:
    mov esi, [esp + 0x4]
    test esi, esi
    jnl short .initialize_board_slot
    movsx eax, word [first_player]
    movsx eax, word [nosplit eax*2 + player_sector]
    xor edx, edx
    call finalize_board_state
    mov eax, [board_state_3cf2]
    mov [actor_clock], edx
    mov [last_tick], edx
    mov [saved_clock], edx
    mov [board_state_3cf6], eax
    add esp, 0x1c
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
