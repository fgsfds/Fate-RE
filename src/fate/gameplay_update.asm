; Run the gameplay update and apply pending level transitions.
BITS 32
ORG 0x14133

select_item equ 0x380d8
refresh_inventory equ 0x2944b
check_teleport_terminals equ 0x13d9f
absolute_long equ 0x602c3
activate_sector equ 0x28710
update_sector_events equ 0x29cd4
update_periodic_sequences equ 0x123d6
update_proximity_sprites equ 0x102ca
update_float_sprites equ 0x136af
update_moving_sprite_physics equ 0x13860
update_projectiles equ 0x13237
update_sector_panning equ 0x11e8e
update_fall_triggers equ 0x10b8f
update_level_effects equ 0x40662
save_level_and_load_board equ 0x13eed
initialize_destination equ 0x26a2a
update_actor_states equ 0x1e7b0
inventory_override_request equ 0x6797e
inventory_override equ 0x4d14
previous_override equ 0x4d16
status_right_tenths equ 0x6319c
saved_status_right equ 0x4d18
item_enabled equ 0x2267
item_stock equ 0x2277
item_alternate_stock equ 0x2287
saved_item_enabled equ 0x7f94e
saved_item_stock equ 0x7f93e
saved_item_alternate_stock equ 0x7f92e
left_icon equ 0x2038
middle_icon equ 0x203a
right_icon equ 0x203c
effect_count equ 0x225d
status_flag equ 0x2261
saved_left_icon equ 0x7f92c
saved_middle_icon equ 0x7f92a
saved_right_icon equ 0x7f928
saved_effect_count equ 0x7f926
saved_status_flag equ 0x7f924
game_clock equ 0x287e88
last_step_clock equ 0x7a990
advance_clock equ 0x229b
level_sector_ids equ 0x7639c
level_sector_active equ 0x7639e
sector_hitag equ 0x27c3c4
level_sector_x equ 0x7499c
level_sector_y equ 0x749a0
player_x equ 0x5ad9c
player_y equ 0x5ad5c
actor_active equ 0x7ecb6
actor_level equ 0x7eac1
actor_sprite equ 0x7dab8
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
current_level equ 0x7f87e
level_sector_count equ 0x7aa3c
player_sector equ 0x5acfc
special_sector equ 0x7dee4
last_sequence_clock equ 0x2030
destination_level equ 0x2040
loaded_level equ 0x7f87d
level_left_icon equ 0x7a9a0
level_middle_icon equ 0x7a9a2
level_right_icon equ 0x7a9a4
modified_levels equ 0x7dea2
mod_extension equ 0x2d0
destination_entry equ 0x7deee
destination_x equ 0x7a998
destination_y equ 0x7a99c

update_gameplay:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 8
    cmp byte [inventory_override_request], 0
    jbe short .check_override_change
    xor dl, dl
    mov byte [inventory_override_request], dl
    mov dx, word [inventory_override]
    not edx
    mov word [inventory_override], dx
    test dx, dx
    jne short .show_override_on
    mov eax, 0x13
    jmp short .show_override_message

.show_override_on:
    mov eax, 0x12

.show_override_message:
    call select_item

    ; Preserve the inventory and status fields across override transitions.

.check_override_change:
    mov ax, word [inventory_override]
    cmp ax, word [previous_override]
    je near .check_override
    mov word [previous_override], ax
    test ax, ax
    je near .restore_override
    mov eax, dword [status_right_tenths]
    mov esi, 1
    mov dword [saved_status_right], eax
    jmp short .check_save_item

.save_item:
    mov dx, word [nosplit eax*2 + item_enabled]
    mov word [nosplit eax*2 + saved_item_enabled], dx
    mov dx, word [nosplit eax*2 + item_stock]
    mov word [nosplit eax*2 + saved_item_stock], dx
    mov dx, word [nosplit eax*2 + item_alternate_stock]
    inc esi
    mov word [nosplit eax*2 + saved_item_alternate_stock], dx

.check_save_item:
    movsx eax, si
    cmp eax, 8
    jle short .save_item
    mov ax, word [left_icon]
    mov word [saved_left_icon], ax
    mov ax, word [middle_icon]
    mov word [saved_middle_icon], ax
    mov ax, word [right_icon]
    mov word [saved_right_icon], ax
    mov ax, word [effect_count]
    mov word [saved_effect_count], ax
    mov ax, word [status_flag]
    mov word [saved_status_flag], ax
    jmp near .check_override

.restore_override:
    mov eax, dword [saved_status_right]
    mov esi, 1
    mov dword [status_right_tenths], eax
    jmp short .check_restore_item

.restore_item:
    mov dx, word [nosplit eax*2 + saved_item_enabled]
    mov word [nosplit eax*2 + item_enabled], dx
    mov dx, word [nosplit eax*2 + saved_item_stock]
    mov word [nosplit eax*2 + item_stock], dx
    mov dx, word [nosplit eax*2 + saved_item_alternate_stock]
    inc esi
    mov word [nosplit eax*2 + item_alternate_stock], dx

.check_restore_item:
    movsx eax, si
    cmp eax, 8
    jle short .restore_item
    call refresh_inventory
    mov ax, word [saved_left_icon]
    mov word [left_icon], ax
    mov ax, word [saved_middle_icon]
    mov word [middle_icon], ax
    mov ax, word [saved_right_icon]
    mov word [right_icon], ax
    mov ax, word [saved_effect_count]
    mov word [effect_count], ax
    mov ax, word [saved_status_flag]
    mov word [status_flag], ax

.check_override:
    cmp word [inventory_override], 0
    je short .update_clock
    mov edx, 0x3e8
    mov esi, 1
    mov edi, 1
    mov dword [status_right_tenths], edx
    mov edx, 0xfa
    jmp short .check_grant_item

.grant_item:
    add esi, edi
    mov word [nosplit eax*2 + item_enabled], di
    mov word [nosplit eax*2 + item_stock], dx
    mov word [nosplit eax*2 + item_alternate_stock], dx

.check_grant_item:
    movsx eax, si
    cmp eax, 3
    jle short .grant_item
    mov eax, 1
    mov ecx, 0x32
    mov word [left_icon], ax
    mov word [middle_icon], ax
    mov word [right_icon], ax
    mov word [effect_count], cx
    mov word [status_flag], ax

.update_clock:
    mov eax, dword [game_clock]
    sub eax, dword [last_step_clock]
    cmp eax, 0xf
    jl short .clear_clock_flag
    mov word [advance_clock], 1
    mov eax, dword [game_clock]
    mov dword [last_step_clock], eax
    jmp short .check_teleport

.clear_clock_flag:
    xor ecx, ecx
    mov word [advance_clock], cx

.check_teleport:
    call check_teleport_terminals
    mov esi, 1
    jmp near .check_sector_count

    ; Test player and actor proximity to each tagged sector.

.check_sector_trigger:
    mov ebp, edx
    movsx ecx, si
    shl ebp, 7
    mov eax, ecx
    mov ax, word [ebp + eax*4 + level_sector_ids]
    movsx ebp, ax
    mov dword [esp + 4], eax
    mov eax, ebp
    shl eax, 2
    add eax, ebp
    mov ax, word [nosplit eax*8 + sector_hitag]
    xor ah, ah
    cwde
    cmp eax, 1
    jne near .advance_sector
    shl edx, 8
    mov eax, dword [edx + ecx*8 + level_sector_x]
    mov ebp, dword [edx + ecx*8 + level_sector_y]
    mov edx, dword [player_x]
    mov dword [esp], eax
    sub eax, edx
    xor edi, edi
    call absolute_long
    cmp eax, strict dword 0x5dc
    jge short .start_actor_scan
    mov ebx, dword [player_y]
    mov eax, ebp
    sub eax, ebx
    call absolute_long
    cmp eax, strict dword 0x5dc
    jge short .start_actor_scan
    mov edi, 1

.start_actor_scan:
    xor ebx, ebx
    jmp short .check_actor_count

.check_actor_distance:
    movsx edx, byte [eax + actor_active]
    cmp edx, -1
    je short .advance_actor
    xor ecx, ecx
    movsx edx, byte [current_level]
    mov cl, byte [eax + actor_level]
    cmp ecx, edx
    jne short .advance_actor
    mov ax, word [nosplit eax*2 + actor_sprite]
    movsx edx, ax
    imul edx, edx, 0x2c
    mov eax, dword [esp]
    sub eax, dword [edx + sprite_x]
    call absolute_long
    cmp eax, strict dword 0x5dc
    jge short .advance_actor
    mov eax, ebp
    sub eax, dword [edx + sprite_y]
    call absolute_long
    cmp eax, strict dword 0x5dc
    jge short .advance_actor
    mov edi, 1

.advance_actor:
    inc ebx

.check_actor_count:
    movsx eax, bx
    cmp eax, strict dword 0x1f4
    jle short .check_actor_distance
    movsx eax, di
    cmp eax, 1
    jne short .check_sector_vacated
    movsx edx, byte [current_level]
    movsx eax, si
    shl edx, 7
    cmp word [edx + eax*4 + level_sector_active], 0
    jne short .advance_sector
    jmp short .activate_sector_trigger

.check_sector_vacated:
    movsx edx, byte [current_level]
    movsx eax, si
    shl edx, 7
    movsx eax, word [edx + eax*4 + level_sector_active]
    cmp eax, 1
    jne short .advance_sector

.activate_sector_trigger:
    movsx eax, word [esp + 4]
    call activate_sector

.advance_sector:
    inc esi

.check_sector_count:
    movsx edx, byte [current_level]
    cmp si, word [nosplit edx*2 + level_sector_count]
    jle near .check_sector_trigger
    call update_sector_events
    movsx edx, word [player_sector]
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov ax, word [nosplit eax*8 + sector_hitag]
    xor al, al
    and ah, 4
    cwde
    test eax, eax
    je short .check_sequence_clock
    mov ax, word [player_sector]
    mov word [special_sector], ax

.check_sequence_clock:
    mov eax, dword [game_clock]
    sub eax, dword [last_sequence_clock]
    cmp eax, 0xc
    jl short .update_gameplay_lists
    call update_periodic_sequences
    mov eax, dword [game_clock]
    mov dword [last_sequence_clock], eax

.update_gameplay_lists:
    call update_proximity_sprites
    call update_float_sprites
    call update_moving_sprite_physics
    call update_projectiles
    call update_sector_panning
    call update_fall_triggers
    movsx eax, byte [current_level]
    call update_level_effects

    ; Save the old board and restore per-level indicators when a teleport changes levels.
    movsx eax, byte [destination_level]
    cmp eax, -1
    je near .finish_update
    mov dh, 0xff
    mov al, byte [destination_level]
    mov bl, byte [loaded_level]
    mov byte [current_level], al
    mov byte [destination_level], dh
    cmp al, bl
    je near .finish_update
    movsx ecx, bl
    mov eax, ecx
    shl eax, 2
    sub eax, ecx
    mov dx, word [left_icon]
    mov word [nosplit eax*2 + level_left_icon], dx
    mov dx, word [middle_icon]
    mov word [nosplit eax*2 + level_middle_icon], dx
    mov dx, word [right_icon]
    mov bh, 1
    mov word [nosplit eax*2 + level_right_icon], dx
    mov edx, mod_extension
    mov eax, ecx
    mov byte [ecx + modified_levels], bh
    call save_level_and_load_board
    movsx eax, byte [current_level]
    mov al, byte [eax + modified_levels]
    movsx ecx, word [destination_entry]
    and eax, 0xff
    mov ebx, dword [destination_y]
    push eax
    mov edx, dword [destination_x]
    mov eax, 0xffffffff
    call initialize_destination
    movsx edx, byte [current_level]
    mov eax, edx
    shl eax, 2
    sub eax, edx
    mov dx, word [nosplit eax*2 + level_left_icon]
    mov word [left_icon], dx
    mov dx, word [nosplit eax*2 + level_middle_icon]
    mov ax, word [nosplit eax*2 + level_right_icon]
    mov word [right_icon], ax
    mov al, byte [current_level]
    mov word [middle_icon], dx
    mov byte [loaded_level], al

.finish_update:
    call update_actor_states
    add esp, 8
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
