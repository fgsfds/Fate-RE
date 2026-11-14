; Load a numbered board and restore its player and actor state.
BITS 32
ORG 0x276e5

numbered_extension equ 0x484
custom_start_missing_numbered_board equ 0x48b
default_start_missing_numbered_board equ 0x4aa
level_names equ 0x2041
map_x equ 0x2bf0
map_scale_or_y equ 0x2bf2
button_latch_disabled equ 0x2bf6
held_sprite equ 0x2bf8
map_mode equ 0x2bfa
trigger_count equ 0x3be6
find_sprite_type equ 0x11035
spawn_sprite_at_position equ 0x11073
board_state_1cf6c equ 0x1cf6c
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
load_map equ 0x49f89
update_sector equ 0x542c4
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
board_state_709da equ 0x709da
board_state_7494c equ 0x7494c
activation_counter equ 0x7496c
activation_sprite_index equ 0x7497c
board_state_7dab6 equ 0x7dab6
board_state_7deca equ 0x7deca
activation_sprite_count equ 0x7def0
current_level equ 0x7f87e
next_player equ 0x18fd78
first_player equ 0x19028a
sprite_tile equ 0x2040ae
sprite_lotag equ 0x2040c6
sprite_hitag equ 0x2040c8
sprite_extra equ 0x2040ca
sine_table equ 0x2300a0
sector_floor_z equ 0x27c3a8

load_numbered_board:
    push esi
    push edi
    push ebp
    sub esp, 0x1c
    mov ebp, eax
    mov edi, edx
    mov esi, ebx
    mov [esp + 0x18], ecx
    xor ecx, ecx
    jmp short .check_sprite_clear_index

.clear_sprite_tags:
    imul eax, ecx, 0x2c
    xor ebx, ebx
    mov [eax + sprite_hitag], bx
    mov [eax + sprite_lotag], bx
    inc ecx
    mov [eax + sprite_extra], bx

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
    push ebp
    push strict dword numbered_extension
    lea eax, [esp + 0x14]
    push eax
    call format_string
    add esp, 0xc
    lea edx, [esp + 0xc]
    mov eax, board_filename
    call append_string
    test edi, edi
    jz short .load_default_start
    test esi, esi
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
    mov eax, custom_start_missing_numbered_board
    call report_error

.apply_custom_start:
    mov eax, [esp + 0x18]
    mov [player_x], edi
    mov [player_y], esi
    mov [player_angle], ax
    jmp short .resolve_player_sector

.load_default_start:
    push strict dword player_sector
    mov ecx, player_z
    mov ebx, player_y
    push strict dword player_angle
    mov edx, player_x
    mov eax, board_filename
    call load_map
    cmp eax, -1
    jnz short .resolve_player_sector
    mov eax, default_start_missing_numbered_board
    call report_error

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
    mov edi, 0xffffffff
    xor ecx, ecx
    jmp near .check_sprite_scan_index

.scan_sprite:
    inc ecx
    mov edx, [player_x]
    mov bx, [player_angle]
    mov [nosplit ecx*2 + board_state_62f2a], di
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
    mov [activation_sprite_count], cx
    mov [board_state_7deca], cx
    xor ecx, ecx
    jmp near .check_final_sprite_index

.inspect_final_sprite:
    imul eax, ecx, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x3a6
    jl short .check_sprite_hitag
    cmp eax, strict dword 0x3a9
    jg short .check_sprite_hitag
    mov ax, [activation_sprite_count]
    inc eax
    mov [activation_sprite_count], ax
    cwde
    mov edx, eax
    xor dl, al
    mov [nosplit eax*2 + activation_sprite_index], cx
    mov [eax + activation_counter], dl

.check_sprite_hitag:
    imul eax, ecx, 0x2c
    mov ax, [eax + sprite_hitag]
    xor ah, ah
    cwde
    cmp eax, 0x1
    jl short .check_sprite_lotag
    cmp eax, 0xf
    jg short .check_sprite_lotag
    mov [nosplit eax*2 + board_state_7494c], cx

.check_sprite_lotag:
    imul eax, ecx, 0x2c
    mov ax, [eax + sprite_lotag]
    xor ah, ah
    cwde
    cmp eax, 0x3
    jnz short .advance_final_sprite
    mov ax, [board_state_7deca]
    movsx edx, ax
    inc eax
    mov [nosplit edx*2 + board_state_1cf6c], cx
    mov [board_state_7deca], ax

.advance_final_sprite:
    inc ecx

.check_final_sprite_index:
    cmp ecx, strict dword 0x1000
    jl near .inspect_final_sprite
    movsx ecx, word [first_player]
    jmp short .check_board_slot

.initialize_board_slot:
    movsx eax, cx
    call initialize_board_entry
    movsx ecx, word [nosplit ecx*2 + next_player]

.check_board_slot:
    test ecx, ecx
    jnl short .initialize_board_slot
    add esp, 0x1c
    pop ebp
    pop edi
    pop esi
    ret word 0x4
