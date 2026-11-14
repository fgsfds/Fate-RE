; Load a board, restore its actors and initialize tagged sector and sprite state.
BITS 32
ORG 0x26a2a

map_extension equ 0x410
modified_map_extension equ 0x415
numbered_board_extension equ 0x41a
custom_start_missing_board equ 0x421
default_start_missing_board equ 0x440
door_limit_message equ 0x45f
level_names equ 0x2041
pan_sector_count equ 0x2bea
map_x equ 0x2bf0
map_scale_or_y equ 0x2bf2
button_latch_disabled equ 0x2bf6
held_sprite equ 0x2bf8
map_mode equ 0x2bfa
trigger_count equ 0x3be6
event_write_index equ 0x3cdc
board_state_3ce0 equ 0x3ce0
event_read_index equ 0x3ce4
board_state_3cf2 equ 0x3cf2
board_state_3d02 equ 0x3d02
input_mode equ 0x3d03
restore_count equ 0x3e04
find_sprite_type equ 0x11035
spawn_sprite_at_position equ 0x11073
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
board_filename equ 0x1e5ac
board_state_209fa equ 0x209fa
restore_board_actor_sprites equ 0x26749
report_error equ 0x26a03
board_state_2ca28 equ 0x2ca28
board_state_2ca68 equ 0x2ca68
board_state_2caa8 equ 0x2caa8
board_state_2cae8 equ 0x2cae8
board_state_2cb28 equ 0x2cb28
initialize_board_entry equ 0x2e14f
set_sprite_motion equ 0x339b9
register_board_coordinate equ 0x344e4
initialize_board_subsystem_a equ 0x3fe1b
initialize_board_subsystem_b equ 0x40268
load_map equ 0x49f89
update_sector equ 0x542c4
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
board_state_5acda equ 0x5acda
board_state_5acfa equ 0x5acfa
player_sector equ 0x5acfc
board_state_5ad18 equ 0x5ad18
player_z equ 0x5ad1c
board_state_5ad58 equ 0x5ad58
player_y equ 0x5ad5c
board_state_5ad98 equ 0x5ad98
player_x equ 0x5ad9c
board_state_5ae1c equ 0x5ae1c
format_string equ 0x601f3
append_string equ 0x60223
copy_string equ 0x60333
board_state_62ed8 equ 0x62ed8
board_state_62f2a equ 0x62f2a
player_horizon equ 0x62f8c
board_state_6308a equ 0x6308a
player_angle equ 0x6308c
error_buffer equ 0x67e3c
board_state_709da equ 0x709da
board_state_7494c equ 0x7494c
activation_counter equ 0x7496c
activation_sprite_index equ 0x7497c
level_sector_x equ 0x7499c
level_sector_y equ 0x749a0
level_sector_ids equ 0x7639c
level_sector_active equ 0x7639e
frame_index equ 0x770c4
board_state_770cc equ 0x770cc
level_sector_count equ 0x7aa3c
board_state_7dab6 equ 0x7dab6
board_state_7debc equ 0x7debc
board_state_7debe equ 0x7debe
encounter_actor_field equ 0x7dec0
board_state_7dec2 equ 0x7dec2
board_state_7dec4 equ 0x7dec4
board_state_7dec6 equ 0x7dec6
board_state_7deca equ 0x7deca
board_state_7decc equ 0x7decc
board_state_7dece equ 0x7dece
activation_sprite_count equ 0x7def0
previous_local_input equ 0x7def4
board_state_7def5 equ 0x7def5
board_state_7def6 equ 0x7def6
board_state_7def7 equ 0x7def7
board_state_7f874 equ 0x7f874
current_level equ 0x7f87e
next_player equ 0x18fd78
first_player equ 0x19028a
tile_height equ 0x1f4020
sprite_z equ 0x2040a8
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_yrepeat equ 0x2040b5
sprite_lotag equ 0x2040c6
sprite_hitag equ 0x2040c8
sprite_extra equ 0x2040ca
sine_table equ 0x2300a0
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
wall_count equ 0x289152
sector_count equ 0x289154

initialize_destination:
    push esi
    push edi
    push ebp
    sub esp, 0x38
    mov edi, eax
    mov esi, edx
    mov ebp, ebx
    mov [esp + 0x2c], ecx
    mov edx, 0x11
    xor ah, ah
    xor ebx, ebx
    xor ecx, ecx
    mov [board_state_7f874], ah
    mov [board_state_3d02], ah
    mov [board_state_287e78], edx
    xor dh, dh
    mov [restore_count], ebx
    mov [input_mode], dh
    jmp short .check_sprite_clear_index

.clear_sprite_tags:
    imul eax, ecx, 0x2c
    xor edx, edx
    mov [eax + sprite_hitag], dx
    mov [eax + sprite_lotag], dx
    inc ecx
    mov [eax + sprite_extra], dx

.check_sprite_clear_index:
    cmp ecx, strict dword 0x1000
    jl short .clear_sprite_tags
    xor edx, edx
    mov [trigger_count], dx
    movsx edx, byte [current_level]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, level_names
    shl eax, byte 0x2
    add edx, eax
    mov eax, board_filename
    call copy_string
    cmp edi, -1
    jnz short .format_numbered_extension
    cmp byte [esp + 0x48], 0x0
    jnz short .use_modified_extension
    mov edx, map_extension
    jmp short .append_board_extension

.use_modified_extension:
    mov edx, modified_map_extension
    jmp short .append_board_extension

.format_numbered_extension:
    push edi
    push strict dword numbered_board_extension
    lea eax, [esp + 0x14]
    push eax
    call format_string
    add esp, 0xc
    lea edx, [esp + 0xc]

.append_board_extension:
    mov eax, board_filename
    call append_string
    mov bh, [esp + 0x48]
    test bh, bh
    jnz short .choose_start_position
    movsx eax, byte [current_level]
    xor bl, bl
    mov [nosplit eax*2 + level_sector_count], bx

.choose_start_position:
    test esi, esi
    jz short .load_default_start
    test ebp, ebp
    jz short .load_default_start
    lea eax, [esp + 0x14]
    push eax
    lea ecx, [esp + 0x18]
    lea ebx, [esp + 0x18]
    push eax
    lea edx, [esp + 0x1c]
    mov eax, board_filename
    call load_map
    cmp eax, -1
    jnz short .apply_custom_start
    mov eax, custom_start_missing_board
    call report_error

.apply_custom_start:
    mov eax, [esp + 0x2c]
    mov [player_x], esi
    mov [player_y], ebp
    mov [player_angle], ax
    jmp short .check_default_board

.load_default_start:
    push strict dword player_sector
    mov ecx, player_z
    mov ebx, player_y
    push strict dword player_angle
    mov edx, player_x
    mov eax, board_filename
    call load_map
    cmp eax, -1
    jnz short .check_default_board
    mov eax, default_start_missing_board
    call report_error

.check_default_board:
    cmp edi, -1
    jnz short .resolve_player_sector
    xor ecx, ecx
    jmp short .check_default_sprite_index

.clear_default_sprite_extra:
    imul eax, ecx, 0x2c
    xor ebx, ebx
    inc ecx
    mov [eax + sprite_extra], bx

.check_default_sprite_index:
    cmp ecx, strict dword 0x1000
    jl short .clear_default_sprite_extra

.resolve_player_sector:
    mov ebx, player_sector
    mov edx, [player_y]
    mov eax, [player_x]
    call update_sector
    movsx edx, word [player_sector]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + sector_floor_z]
    mov esi, 0xffffffff
    sub eax, strict dword 0x2000
    xor ecx, ecx
    mov [player_z], eax
    jmp short .check_actor_sprite_index

.clear_actor_sprite:
    inc ecx
    mov [nosplit ecx*2 + board_state_7dab6], si

.check_actor_sprite_index:
    cmp ecx, strict dword 0x1f4
    jng short .clear_actor_sprite
    mov ebx, 0xffffffff
    xor ecx, ecx
    jmp short .check_sprite_actor_index

.clear_sprite_actor:
    inc ecx
    mov [nosplit ecx*2 + board_state_709da], bx

.check_sprite_actor_index:
    cmp ecx, strict dword 0x1000
    jl short .clear_sprite_actor
    call restore_board_actor_sprites
    cmp word [map_mode], 0x0
    jz near .prepare_sprite_scan
    movsx eax, word [button_latch_disabled]
    call find_sprite_type
    mov edx, eax
    mov eax, [player_x]
    mov [esp], eax
    mov eax, [player_y]
    mov [esp + 0x4], eax
    mov eax, [player_z]
    movsx ebx, word [player_sector]
    mov [esp + 0x8], eax
    movsx eax, dx
    mov edx, esp
    call spawn_sprite_at_position
    movsx edx, word [player_angle]
    add edx, strict dword 0x200
    and edx, strict dword 0x7ff
    movsx edx, word [nosplit edx*2 + sine_table]
    shl edx, byte 0x9
    xor ecx, ecx
    mov [esp], edx
    mov dx, [player_angle]
    push strict byte 0x0
    and dh, 0x7
    mov [held_sprite], ax
    movsx edx, dx
    push strict dword 0x400
    movsx edx, word [nosplit edx*2 + sine_table]
    cwde
    shl edx, byte 0x9
    push strict dword 0x400
    mov [esp + 0x10], edx
    mov ebx, edx
    mov edx, [esp + 0xc]
    call set_sprite_motion
    xor eax, eax
    mov [map_x], ax
    mov [map_scale_or_y], ax

.prepare_sprite_scan:
    mov esi, 0xffffffff
    xor ecx, ecx
    jmp near .check_sprite_scan_index

.scan_sprite:
    inc ecx
    mov edx, [player_x]
    mov bx, [player_angle]
    mov [nosplit ecx*2 + board_state_62f2a], si
    mov [nosplit ecx*4 + board_state_5ad98], edx
    mov [nosplit ecx*2 + board_state_6308a], bx
    mov edx, [player_y]
    mov bx, [player_sector]
    mov ax, [player_angle]
    mov [nosplit ecx*2 + board_state_5acfa], bx
    mov [nosplit ecx*2 + board_state_5acda], bx
    xor ebx, ebx
    mov [nosplit ecx*4 + board_state_5ad58], edx
    mov [nosplit ecx*4 + board_state_62ed8], ebx
    mov ebx, [player_x]
    mov [nosplit ecx*2 + board_state_209fa], ax
    mov [nosplit ecx*4 + board_state_2caa8], ebx
    mov ebx, [player_y]
    mov edx, [player_z]
    mov [nosplit ecx*4 + board_state_2cae8], ebx
    mov ebx, [player_horizon]
    mov [nosplit ecx*4 + board_state_5ad18], edx
    mov [nosplit ecx*4 + board_state_2ca28], ebx
    mov ebx, [board_state_5ae1c]
    mov [nosplit ecx*4 + board_state_2ca68], edx
    mov [nosplit ecx*4 + board_state_2cb28], ebx

.check_sprite_scan_index:
    cmp ecx, 0x10
    jl near .scan_sprite
    xor ecx, ecx
    mov [board_state_770cc], ecx
    mov [frame_index], ecx
    mov [event_write_index], ecx
    mov [board_state_3ce0], ecx
    mov [event_read_index], ecx
    mov [board_state_3cf2], ecx
    xor ecx, ecx
    mov [board_state_7def7], cx
    xor cl, cl
    mov [board_state_7def6], cl
    mov [board_state_7def5], cl
    mov [previous_local_input], cl
    xor ecx, ecx
    jmp short .check_sector_clear_index

.clear_sector_state:
    mov eax, ecx
    mov edx, ecx
    shl eax, byte 0x2
    xor bl, bl
    add eax, ecx
    xor dl, cl
    xor edi, edi
    mov [eax + previous_input], dl
    mov [eax + board_state_5ac8c], dl
    mov [eax + current_input], dl
    mov [eax + board_state_55b6e], bl
    mov [eax + board_state_5ac8e], bl
    mov [eax + board_state_5ac3e], bl
    mov [eax + board_state_55b6f], di
    mov [eax + player_input_word], di
    mov [eax + board_state_5ac3f], di
    xor dh, ch
    inc ecx
    mov [eax + board_state_55b6d], dh
    mov [eax + board_state_5ac8d], dh
    mov [eax + board_state_5ac3d], dh

.check_sector_clear_index:
    cmp ecx, 0x10
    jl short .clear_sector_state
    mov esi, 0xffffffff
    xor ecx, ecx
    jmp short .check_wall_clear_index

.clear_wall_state:
    inc ecx
    xor edi, edi
    mov [eax + fini_table_end], si
    mov [eax + board_state_1ba44], di

.check_wall_clear_index:
    lea eax, [ecx + ecx]
    cmp ecx, 0x10
    jl short .clear_wall_state
    xor edx, edx
    xor ecx, ecx
    mov [board_state_7dece], dx
    mov [board_state_7dec4], dx
    mov [board_state_7dec2], dx
    mov [board_state_7dec6], dx
    mov [board_state_7debe], dx
    mov [encounter_actor_field], dx
    mov [board_state_7debc], dx
    mov [pan_sector_count], dx
    mov [eax + board_state_1ba64], dx
    jmp near .check_sector_index

.inspect_sector_tag:
    mov edx, ecx
    shl edx, byte 0x2
    add edx, ecx
    shl edx, byte 0x3
    mov di, [edx + sector_lotag]
    cmp di, 0xe
    jc short .classify_lower_sector_tags
    jna near .measure_sector_center
    cmp di, 0x47
    jc short .classify_lower_door_tags
    cmp di, 0x49
    jna near .register_door_sector
    cmp di, 0x51
    jc near .check_sector_tag_callback
    cmp di, 0x53
    jna near .register_door_sector
    cmp di, 0xa1
    jc near .check_sector_tag_callback
    cmp di, 0xa3

.check_upper_door_tag:
    jna short .register_door_sector
    jmp near .check_sector_tag_callback

.classify_lower_door_tags:
    cmp di, 0x10
    jc near .check_sector_tag_callback
    jna short .register_door_sector
    cmp di, 0x3d
    jc near .check_sector_tag_callback
    cmp di, 0x3f
    jmp short .check_upper_door_tag

.classify_lower_sector_tags:
    cmp di, 0xa
    jc short .classify_lowest_sector_tags
    jna near .store_sector_group_b
    cmp di, 0xb
    jna near .store_sector_group_c
    cmp di, 0xc
    jz near .measure_sector_bounds
    jmp near .check_sector_tag_callback

.classify_lowest_sector_tags:
    cmp di, 0x4
    jc near .check_sector_tag_callback
    jna near .store_sector_group_a
    cmp di, 0x6
    jc near .check_sector_tag_callback
    cmp di, 0x8
    ja near .check_sector_tag_callback

.register_door_sector:
    cmp byte [esp + 0x48], 0x0
    jnz near .check_sector_tag_callback
    movsx edx, byte [current_level]
    mov bx, [nosplit edx*2 + level_sector_count]
    inc ebx
    movsx eax, bx
    mov [nosplit edx*2 + level_sector_count], bx
    cmp eax, 0x1f
    jng short .store_door_sector
    push edx
    push strict dword door_limit_message
    push strict dword error_buffer
    call format_string
    add esp, 0xc
    mov eax, error_buffer
    call report_error

.store_door_sector:
    movsx eax, byte [current_level]
    movsx edx, word [nosplit eax*2 + level_sector_count]
    shl eax, byte 0x7
    xor esi, esi
    mov [eax + edx*4 + level_sector_ids], cx
    mov [eax + edx*4 + level_sector_active], si
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    xor ebx, ebx
    mov dx, [nosplit eax*8 + sector_wall_start]
    mov di, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x30], edx
    mov esi, edx
    movsx edx, dx
    add esi, edi
    xor edi, edi
    jmp short .check_door_wall_index

.initialize_door_wall:
    mov eax, edx
    shl eax, byte 0x5
    add ebx, [eax + wall_x]
    mov ebp, [eax + wall_y]
    inc edx
    add edi, ebp

.check_door_wall_index:
    movsx eax, si
    cmp edx, eax
    jl short .initialize_door_wall
    movsx ebp, word [esp + 0x30]
    mov edx, ebx
    sub eax, ebp
    sar edx, byte 0x1f
    mov ebp, eax
    mov eax, ebx
    idiv ebp
    mov ebx, eax
    mov edx, edi
    mov eax, edi
    sar edx, byte 0x1f
    idiv ebp
    movsx edx, byte [current_level]
    mov edi, eax
    mov eax, edx
    movsx ebp, word [nosplit edx*2 + level_sector_count]
    shl eax, byte 0x8
    mov [eax + ebp*8 + level_sector_x], ebx
    mov [eax + ebp*8 + level_sector_y], edi
    jmp near .check_sector_tag_callback

.store_sector_group_a:
    mov dx, [board_state_7dec2]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1d08c], cx
    mov [board_state_7dec2], dx
    jmp near .check_sector_tag_callback

.store_sector_group_b:
    mov dx, [board_state_7dece]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1ccac], cx
    mov [board_state_7dece], dx
    jmp near .check_sector_tag_callback

.store_sector_group_c:
    mov dx, [board_state_7dec4]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1cc8c], cx
    mov [board_state_7dec4], dx
    jmp near .check_sector_tag_callback

.measure_sector_bounds:
    mov edi, 0x7fffffff
    mov ebx, 0x80000000
    mov ax, [edx + sector_wall_start]
    mov [esp + 0x28], edi
    mov [esp + 0x20], ebx
    mov [esp + 0x24], ebx
    mov [esp + 0x30], eax
    mov esi, eax
    mov ax, [edx + sector_wall_count]
    movsx edx, word [esp + 0x30]
    add esi, eax
    jmp near .check_boundary_wall_index

.inspect_boundary_wall:
    mov eax, edx
    shl eax, byte 0x5
    mov ebx, [eax + wall_x]
    cmp edi, ebx
    jng short .check_minimum_x
    mov edi, ebx

.check_minimum_x:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [esp + 0x28]
    mov ebx, [eax + wall_y]
    cmp ebx, ebp
    jnl short .check_maximum_x
    mov [esp + 0x28], ebx

.check_maximum_x:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [esp + 0x20]
    mov ebx, [eax + wall_x]
    cmp ebx, ebp
    jng short .check_minimum_y
    mov [esp + 0x20], ebx

.check_minimum_y:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [esp + 0x24]
    mov ebx, [eax + wall_y]
    cmp ebx, ebp
    jng short .check_maximum_y
    mov [esp + 0x24], ebx

.check_maximum_y:
    mov eax, edx
    shl eax, byte 0x5
    movsx eax, word [eax + board_state_2310ba]
    cmp eax, 0x3
    jnz short .advance_boundary_wall
    mov [esp + 0x18], edx

.advance_boundary_wall:
    inc edx

.check_boundary_wall_index:
    movsx eax, si
    cmp edx, eax
    jl short .inspect_boundary_wall
    mov eax, [esp + 0x18]
    shl eax, byte 0x5
    cmp edi, [eax + wall_x]
    jnz short .check_bound_b
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc4c], 0xfff0

.check_bound_b:
    mov eax, [esp + 0x18]
    shl eax, byte 0x5
    mov ebx, [esp + 0x28]
    cmp ebx, [eax + wall_y]
    jnz short .check_bound_c
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc6c], 0xfff0

.check_bound_c:
    mov eax, [esp + 0x18]
    shl eax, byte 0x5
    mov esi, [esp + 0x20]
    cmp esi, [eax + wall_x]
    jnz short .check_bound_d
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc4c], 0x10

.check_bound_d:
    mov eax, [esp + 0x18]
    shl eax, byte 0x5
    mov ebp, [esp + 0x24]
    cmp ebp, [eax + wall_y]
    jnz short .store_sector_bounds
    movsx eax, word [board_state_7dec6]
    mov word [nosplit eax*2 + board_state_1cc6c], 0x10

.store_sector_bounds:
    movsx eax, word [esp + 0x30]
    shl eax, byte 0x5
    mov ax, [eax + engine_2310ac]
    mov edx, 0x7fffffff
    mov [esp + 0x34], eax
    movsx eax, word [board_state_7dec6]
    mov esi, 0x80000000
    mov [nosplit eax*4 + board_state_1ce2c], edx
    mov [nosplit eax*4 + board_state_1ceac], edx
    mov [nosplit eax*4 + board_state_1cdec], esi
    movsx edx, word [esp + 0x34]
    mov [nosplit eax*4 + board_state_1ce6c], esi
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov dx, [nosplit eax*8 + sector_wall_start]
    mov bx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x30], edx
    mov esi, edx
    movsx edx, dx
    add esi, ebx
    jmp near .check_boundary_init_index

.initialize_boundary_wall:
    mov ebx, edx
    shl ebx, byte 0x5
    movsx eax, word [board_state_7dec6]
    mov ebp, [ebx + wall_x]
    shl eax, byte 0x2
    cmp ebp, [eax + board_state_1ce2c]
    jnl short .check_boundary_coordinate_b
    mov [eax + board_state_1ce2c], ebp

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
    mov ebx, edx
    shl ebx, byte 0x5
    movsx eax, word [board_state_7dec6]
    mov ebp, [ebx + wall_x]
    shl eax, byte 0x2
    cmp ebp, [eax + board_state_1cdec]
    jng short .check_boundary_coordinate_d
    mov [eax + board_state_1cdec], ebp

.check_boundary_coordinate_d:
    mov ebx, edx
    shl ebx, byte 0x5
    movsx eax, word [board_state_7dec6]
    mov ebp, [ebx + wall_y]
    shl eax, byte 0x2
    cmp ebp, [eax + board_state_1ce6c]
    jng short .register_boundary_coordinates
    mov [eax + board_state_1ce6c], ebp

.register_boundary_coordinates:
    movsx ebx, word [esp + 0x34]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ebp, wall_x
    shl eax, byte 0x3
    mov ebx, edx
    add eax, sector_wall_start
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
    movsx eax, si
    cmp edx, eax
    jl near .initialize_boundary_wall
    mov edx, ecx
    shl edx, byte 0x2
    lea ebx, [ecx + edx]
    shl ebx, byte 0x3
    movsx edx, word [ebx + sector_wall_start]
    shl edx, byte 0x5
    mov esi, [edx + wall_x]
    sub esi, edi
    movsx eax, word [board_state_7dec6]
    mov edi, esi
    mov esi, [nosplit eax*4 + board_state_1ce2c]
    mov ebp, [esp + 0x28]
    add esi, edi
    mov edi, [edx + wall_y]
    mov [nosplit eax*4 + board_state_1ce2c], esi
    mov esi, [nosplit eax*4 + board_state_1ceac]
    sub edi, ebp
    mov ebp, [edx + wall_x]
    add esi, edi
    mov edi, [esp + 0x20]
    mov [nosplit eax*4 + board_state_1ceac], esi
    mov esi, [nosplit eax*4 + board_state_1cdec]
    sub edi, ebp
    sub esi, edi
    mov [nosplit eax*4 + board_state_1cdec], esi
    mov esi, [esp + 0x24]
    mov edi, [edx + wall_y]
    mov edx, esi
    mov ebp, [nosplit eax*4 + board_state_1ce6c]
    sub edx, edi
    sub ebp, edx
    mov edx, [ebx + sector_floor_z]
    mov [nosplit eax*4 + board_state_1cd2c], edx
    mov dx, [board_state_7dec6]
    mov [nosplit eax*4 + board_state_1ce6c], ebp
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1d10c], cx
    mov [board_state_7dec6], dx
    jmp near .check_sector_tag_callback

.measure_sector_center:
    mov ax, [edx + sector_wall_start]
    mov bx, [edx + sector_wall_count]
    xor edi, edi
    mov [esp + 0x30], eax
    mov esi, eax
    mov [esp + 0x28], edi
    movsx edx, ax
    add esi, ebx
    jmp short .check_center_wall_index

.sum_wall_coordinates:
    mov eax, edx
    shl eax, byte 0x5
    mov ebp, [esp + 0x28]
    mov ebx, [eax + wall_x]
    mov eax, [eax + wall_y]
    inc edx
    add ebp, eax
    add edi, ebx
    mov [esp + 0x28], ebp

.check_center_wall_index:
    movsx eax, si
    cmp edx, eax
    jl short .sum_wall_coordinates
    movsx ebp, word [esp + 0x30]
    sub eax, ebp
    mov edx, edi
    mov [esp + 0x1c], eax
    sar edx, byte 0x1f
    mov ebx, [esp + 0x1c]
    mov eax, edi
    idiv ebx
    movsx ebx, word [encounter_actor_field]
    mov [nosplit ebx*4 + board_state_1baa4], eax
    mov eax, [esp + 0x28]
    mov edx, eax
    mov edi, [esp + 0x1c]
    sar edx, byte 0x1f
    idiv edi
    mov [nosplit ebx*4 + board_state_1ba94], eax
    xor eax, eax
    mov edx, ebp
    jmp short .check_center_wall_registration_index

.register_center_wall:
    mov edi, [esp + 0x18]
    movsx eax, word [encounter_actor_field]
    mov ebx, edx
    shl eax, byte 0x6
    shl edi, byte 0x2
    shl ebx, byte 0x5
    add eax, edi
    mov edi, [ebx + wall_x]
    mov [eax + board_state_1c2fc], edi
    mov edi, [ebx + wall_y]
    mov [eax + board_state_1c1fc], edi
    mov edi, wall_x
    add edi, ebx
    mov eax, edi
    call register_board_coordinate
    lea eax, [edi + 0x4]
    call register_board_coordinate
    movsx eax, word [ebx + wall_next_index]
    shl eax, byte 0x5
    add eax, wall_x
    call register_board_coordinate
    movsx eax, word [ebx + wall_next_index]
    shl eax, byte 0x5
    add eax, wall_x
    add eax, 0x4
    call register_board_coordinate
    mov eax, [esp + 0x18]
    inc eax
    inc edx

.check_center_wall_registration_index:
    mov [esp + 0x18], eax
    movsx eax, si
    cmp edx, eax
    jl near .register_center_wall
    movsx eax, word [encounter_actor_field]
    xor edi, edi
    mov [nosplit eax*2 + board_state_1bab4], cx
    mov [nosplit eax*2 + board_state_1cc44], di
    inc word [encounter_actor_field]

.check_sector_tag_callback:
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0x12
    jl short .advance_sector_index
    cmp eax, 0x1d
    jg short .advance_sector_index
    mov eax, ecx
    call process_sector_tag

.advance_sector_index:
    inc ecx

.check_sector_index:
    movsx eax, word [sector_count]
    cmp ecx, eax
    jl near .inspect_sector_tag
    movsx eax, byte [current_level]
    call initialize_board_subsystem_a
    movsx eax, byte [current_level]
    call initialize_board_subsystem_b
    xor eax, eax
    xor ecx, ecx
    mov [board_state_7decc], ax
    jmp short .check_final_sprite_index

.scan_final_sprite_tags:
    mov eax, ecx
    shl eax, byte 0x5
    movsx eax, word [eax + board_state_2310ba]
    cmp eax, 0x1
    jnz short .advance_final_sprite
    mov dx, [board_state_7decc]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1ceec], cx
    mov [board_state_7decc], dx

.advance_final_sprite:
    inc ecx

.check_final_sprite_index:
    movsx eax, word [wall_count]
    cmp ecx, eax
    jl short .scan_final_sprite_tags
    cmp byte [esp + 0x48], 0x0
    jnz short .prepare_final_sector_scan
    xor ecx, ecx
    jmp short .check_special_sprite_index

.scan_board_special_sprites:
    imul eax, ecx, 0x2c
    mov dx, [eax + sprite_lotag]
    xor dh, dh
    movsx edx, dx
    cmp edx, 0x64
    jnz short .advance_special_sprite
    movsx edx, word [eax + sprite_tile]
    xor ebx, ebx
    movsx edx, word [nosplit edx*2 + tile_height]
    mov bl, [eax + sprite_yrepeat]
    imul edx, ebx
    mov edi, [eax + sprite_z]
    add edx, edx
    sub edi, edx
    mov dx, [eax + sprite_cstat]
    mov [eax + sprite_z], edi
    or edx, strict dword 0x181
    mov [eax + sprite_cstat], dx

.advance_special_sprite:
    inc ecx

.check_special_sprite_index:
    cmp ecx, strict dword 0x1000
    jl short .scan_board_special_sprites

.prepare_final_sector_scan:
    xor ebx, ebx
    xor ecx, ecx
    mov [activation_sprite_count], bx
    mov [board_state_7deca], bx
    jmp near .check_final_sector_index

.inspect_final_sector:
    imul eax, ecx, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x3a6
    jl short .check_second_sector_range
    cmp eax, strict dword 0x3a9
    jg short .check_second_sector_range
    mov si, [activation_sprite_count]
    inc esi
    movsx eax, si
    mov edx, eax
    mov [activation_sprite_count], si
    xor dl, al
    mov [nosplit eax*2 + activation_sprite_index], cx
    mov [eax + activation_counter], dl

.check_second_sector_range:
    imul eax, ecx, 0x2c
    mov ax, [eax + sprite_hitag]
    xor ah, ah
    cwde
    cmp eax, 0x1
    jl short .check_final_sector_tile
    cmp eax, 0xf
    jg short .check_final_sector_tile
    mov [nosplit eax*2 + board_state_7494c], cx

.check_final_sector_tile:
    imul eax, ecx, 0x2c
    mov ax, [eax + sprite_lotag]
    xor ah, ah
    cwde
    cmp eax, 0x3
    jnz short .advance_final_sector
    mov dx, [board_state_7deca]
    movsx eax, dx
    inc edx
    mov [nosplit eax*2 + board_state_1cf6c], cx
    mov [board_state_7deca], dx

.advance_final_sector:
    inc ecx

.check_final_sector_index:
    cmp ecx, strict dword 0x1000
    jl near .inspect_final_sector
    movsx ecx, word [first_player]
    jmp short .check_board_slot

.initialize_board_slot:
    movsx eax, cx
    call initialize_board_entry
    movsx ecx, word [nosplit ecx*2 + next_player]

.check_board_slot:
    test ecx, ecx
    jnl short .initialize_board_slot
    add esp, 0x38
    pop ebp
    pop edi
    pop esi
    ret word 0x4
