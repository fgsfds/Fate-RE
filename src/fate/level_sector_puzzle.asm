; Update the level-specific sector tile puzzle and its sprite triggers.
BITS 32
ORG 0x1daea

absolute_long equ 0x602c3
sprite_tile equ 0x2040ae
player_x equ 0x5ad9c
player_y equ 0x5ad5c
last_tile_step equ 0x127e8
puzzle_solved equ 0x127ec
key_sprite_consumed equ 0x127f0
game_clock equ 0x287e88
activate_sector equ 0x28710
remove_sprite equ 0x10f9f
spawn_level_effect equ 0x13752
previous_effect_active equ 0x85194
effect_active equ 0x85198
effect_x equ 0x8519c
effect_y equ 0x851a0
sector_14_lotag equ 0x27c5f2
sector_15_lotag equ 0x27c61a
sector_30_lotag equ 0x27c872
sector_30_wall_start equ 0x27c850
sector_30_wall_count equ 0x27c852
sector_floor_tile equ 0x27c3b8
sector_107_floor_tile equ 0x27d470
sector_108_floor_tile equ 0x27d498
sector_109_floor_tile equ 0x27d4c0
trigger_count equ 0x3be6
trigger_sprite equ 0x77124
trigger_target equ 0x77126
wall_tile equ 0x238bf0
transition_marker equ 0x7deee
destination_level equ 0x2040
destination_x equ 0x7a998
destination_y equ 0x7a99c

; Use the original ModR/M form of sub eax, 0x4000.
%macro sub_trigger_tag 0
    db 0x81, 0xe8
    dd 0x4000
%endmacro

update_level_sector_puzzle:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    cmp dword [puzzle_solved], 0x0
    jnz near .check_key_trigger
    xor ebx, ebx
    mov eax, [player_x]
    mov [sector_14_lotag], bx
    mov [sector_30_lotag], bx
    sub eax, strict dword 0x7e6e
    mov [sector_15_lotag], bx
    call absolute_long
    cmp eax, strict dword 0x400
    jnl short .check_second_position
    mov eax, [player_y]
    sub eax, strict dword 0x6408
    call absolute_long
    cmp eax, strict dword 0x400
    jnl short .check_second_position
    mov ebx, 0x6b
    mov edx, 0x7e6e
    mov ecx, 0x6408
    mov [effect_x], edx
    mov [effect_y], ecx
    mov edx, 0x68e
    jmp near .check_step_clock

.check_second_position:
    mov eax, [player_x]
    sub eax, strict dword 0x93f6
    call absolute_long
    cmp eax, strict dword 0x400
    jnl short .check_third_position
    mov eax, [player_y]
    sub eax, strict dword 0x79f7
    call absolute_long
    cmp eax, strict dword 0x400
    jnl short .check_third_position
    mov ebx, 0x6d
    mov ebp, 0x93f6
    mov eax, 0x79f7
    mov edx, 0x691
    mov [effect_x], ebp
    mov [effect_y], eax
    jmp short .check_step_clock

.check_third_position:
    mov eax, [player_x]
    sub eax, strict dword 0x69f8
    call absolute_long
    cmp eax, strict dword 0x400
    jnl short .mark_no_selected_sector
    mov eax, [player_y]
    sub eax, strict dword 0x79ea
    call absolute_long
    cmp eax, strict dword 0x400
    jnl short .mark_no_selected_sector
    mov ebx, 0x6c
    mov esi, 0x69f8
    mov edi, 0x79ea
    mov edx, 0x694
    mov [effect_x], esi
    mov [effect_y], edi
    jmp short .check_step_clock

.mark_no_selected_sector:
    mov ebx, 0xffffffff

.check_step_clock:
    mov eax, [game_clock]
    sub eax, [last_tile_step]
    cmp eax, strict dword 0xb4
    jng near .check_key_trigger
    mov eax, [game_clock]
    mov [last_tile_step], eax
    movsx eax, bx
    cmp eax, -1
    jng short .check_solution
    mov ecx, eax
    shl eax, byte 0x2
    add eax, ecx
    shl eax, byte 0x3
    mov di, [eax + sector_floor_tile]
    movsx ecx, dx
    inc edi
    add ecx, 0x2
    movsx esi, di
    mov [eax + sector_floor_tile], di
    cmp esi, ecx
    jng short .check_solution
    mov [eax + sector_floor_tile], dx

.check_solution:
    movsx eax, word [sector_107_floor_tile]
    cmp eax, strict dword 0x68f
    jnz short .check_key_trigger
    movsx eax, word [sector_109_floor_tile]
    cmp eax, strict dword 0x693
    jnz short .check_key_trigger
    movsx eax, word [sector_108_floor_tile]
    cmp eax, strict dword 0x694
    jnz short .check_key_trigger
    mov edi, 0x1
    mov eax, 0x6
    xor edx, edx
    mov [sector_30_lotag], ax
    mov eax, 0x1e
    mov [puzzle_solved], edi
    call activate_sector
    mov bx, [sector_30_wall_start]
    mov ax, [sector_30_wall_count]
    mov [sector_30_lotag], dx
    add eax, ebx
    jmp short .check_wall_index

.advance_wall_index:
    inc ebx

.check_wall_index:
    cmp bx, ax
    jl short .advance_wall_index

.check_key_trigger:
    cmp dword [puzzle_solved], 0x1
    jnz near .update_position_effect
    cmp dword [key_sprite_consumed], 0x0
    jnz near .update_position_effect
    mov ebx, 0x1
    mov esi, 0x689
    mov edi, 0x6
    jmp near .check_key_trigger_index

.scan_key_trigger:
    movsx eax, bx
    xor ecx, ecx
    mov dx, [nosplit eax*4 + trigger_sprite]
    mov ax, [nosplit eax*4 + trigger_target]
    mov cx, ax
    cmp ecx, strict dword 0x8000
    jnl short .advance_key_trigger
    sub_trigger_tag
    and eax, strict dword 0xffff
    cmp eax, 0x6a
    jnz short .advance_key_trigger
    movsx eax, dx
    imul edx, eax, 0x2c
    movsx edx, word [edx + sprite_tile]
    cmp edx, strict dword 0x20f
    jnz short .advance_key_trigger
    call remove_sprite
    mov edx, 0x1
    mov eax, 0xe
    mov [wall_tile], si
    mov [sector_14_lotag], di
    mov [key_sprite_consumed], edx
    call activate_sector
    xor eax, eax
    xor ecx, ecx
    mov [sector_14_lotag], ax
    mov eax, 0xf
    mov [sector_15_lotag], di
    call activate_sector
    mov [sector_15_lotag], cx

.advance_key_trigger:
    inc ebx

.check_key_trigger_index:
    cmp bx, [trigger_count]
    jng near .scan_key_trigger

.update_position_effect:
    xor ecx, ecx
    mov esi, [puzzle_solved]
    mov [effect_active], ecx
    test esi, esi
    jnz short .check_effect_transition
    movsx eax, bx
    cmp eax, -1
    jng short .check_effect_transition
    mov edi, 0x1
    push strict dword 0xfffff1f0
    mov ecx, effect_x
    mov ebx, 0x6
    mov eax, 0x1e
    mov edx, ebx
    mov [effect_active], edi
    call spawn_level_effect

.check_effect_transition:
    mov eax, [effect_active]
    cmp eax, [previous_effect_active]
    jz short .scan_exit_triggers
    cmp eax, 0x1
    jnz short .store_effect_state
    xor ebx, ebx
    jmp short .check_outer_counter

.reset_inner_counter:
    xor eax, eax
    jmp short .check_inner_counter

.advance_inner_counter:
    inc eax

.check_inner_counter:
    movsx edx, ax
    cmp edx, 0x5
    jng short .advance_inner_counter
    inc ebx

.check_outer_counter:
    movsx eax, bx
    cmp eax, 0x5
    jng short .reset_inner_counter

.store_effect_state:
    mov eax, [effect_active]
    mov [previous_effect_active], eax

.scan_exit_triggers:
    mov ebx, 0x1
    mov edi, 0x336
    mov si, [trigger_count]
    jmp short .check_exit_trigger_index

.check_exit_trigger:
    movsx eax, bx
    xor ecx, ecx
    mov dx, [nosplit eax*4 + trigger_sprite]
    mov ax, [nosplit eax*4 + trigger_target]
    mov cx, ax
    cmp ecx, strict dword 0x8000
    jnl short .advance_exit_trigger
    sub_trigger_tag
    and eax, strict dword 0xffff
    cmp eax, 0x29
    jnz short .advance_exit_trigger
    movsx eax, dx
    imul eax, eax, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x224
    jnz short .advance_exit_trigger
    mov edx, 0x2ee5
    mov ecx, 0x17ff
    mov ah, 0x4
    mov [transition_marker], di
    mov [destination_x], edx
    mov [destination_y], ecx
    mov [destination_level], ah

.advance_exit_trigger:
    inc ebx

.check_exit_trigger_index:
    cmp bx, si
    jng short .check_exit_trigger
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
