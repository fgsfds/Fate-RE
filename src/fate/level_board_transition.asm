; Unload level sprites, optionally preserve actor state, and load the named board.
BITS 32
ORG 0x13eed

delete_sprite equ 0x50a09
report_error equ 0x26a03
copy_string equ 0x60333
append_string equ 0x60223
load_board equ 0x4a11a
player_sprite equ 0x62f2c
holding_sprite equ 0x2bfa
held_sprite equ 0x2bf8
actor_active equ 0x7ecb6
actor_level equ 0x7eac1
actor_sprite equ 0x7dab8
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_lotag equ 0x2040c6
saved_actor_x equ 0x772c4
saved_actor_y equ 0x772c8
saved_actor_z equ 0x772cc
saved_actor_lotag equ 0x7d6ce
save_error equ 0x288
discard_error equ 0x2ac
restore_count equ 0x3e04
restore_addresses equ 0x1a234
restore_values equ 0x1b234
level_names equ 0x2041
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_angle equ 0x6308c
player_x equ 0x5ad9c

save_level_and_load_board:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x50
    push eax
    mov ebp, edx
    movsx eax, word [player_sprite]
    call delete_sprite
    cmp word [holding_sprite], 0
    je short .check_level
    movsx eax, word [held_sprite]
    call delete_sprite

.check_level:
    cmp word [esp], 0
    je near .restore_board_changes
    mov ecx, dword [esp]
    xor edx, edx
    jmp near .check_actor_count

.save_actor:
    movsx eax, byte [edx + actor_active]
    cmp eax, -1
    je short .advance_actor
    xor eax, eax
    mov al, byte [edx + actor_level]
    cmp ax, cx
    jne short .advance_actor
    mov ax, word [nosplit edx*2 + actor_sprite]
    movsx esi, ax
    imul eax, esi, 0x2c
    mov ebx, edx
    shl ebx, 2
    sub ebx, edx
    mov edi, dword [eax + sprite_x]
    mov dword [nosplit ebx*4 + saved_actor_x], edi
    mov edi, dword [eax + sprite_y]
    mov dword [nosplit ebx*4 + saved_actor_y], edi
    mov edi, dword [eax + sprite_z]
    mov ax, word [eax + sprite_lotag]
    mov dword [nosplit ebx*4 + saved_actor_z], edi
    mov word [nosplit edx*2 + saved_actor_lotag], ax
    mov eax, esi
    mov esi, 0xffffffff
    call delete_sprite
    mov word [nosplit edx*2 + actor_sprite], si

.advance_actor:
    inc edx

.check_actor_count:
    cmp edx, 0x1f4
    jle near .save_actor
    xor edx, edx
    jmp short .check_slot_count

.check_actor_slot:
    movsx eax, word [nosplit edx*2 + actor_sprite]
    cmp eax, -1
    je short .advance_slot
    mov eax, save_error
    call report_error

.advance_slot:
    inc edx

.check_slot_count:
    cmp edx, 0x1f4
    jle short .check_actor_slot

.restore_board_changes:
    mov edx, dword [restore_count]
    dec edx
    jmp short .check_restore_index

.restore_value:
    mov ebx, dword [nosplit edx*4 + restore_addresses]
    mov eax, dword [nosplit edx*4 + restore_values]
    dec edx
    mov dword [ebx], eax

.check_restore_index:
    test edx, edx
    jge short .restore_value
    movsx edx, word [esp]
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov edx, level_names
    shl eax, 2
    add edx, eax
    lea eax, [esp + 4]
    call copy_string
    lea eax, [esp + 4]
    mov edx, ebp
    call append_string
    push player_sector
    mov ecx, player_z
    mov ebx, player_y
    push player_angle
    mov edx, player_x
    lea eax, [esp + 0xc]
    call load_board
    add esp, 0x54
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

discard_level_and_load_board:
    push ebx
    push ecx
    push esi
    push edi
    sub esp, 0x50
    mov ecx, eax
    mov esi, edx
    movsx eax, word [player_sprite]
    call delete_sprite
    cmp word [holding_sprite], 0
    je short .check_level
    movsx eax, word [held_sprite]
    call delete_sprite

.check_level:
    test cx, cx
    je near .load_level_board
    mov edi, 0xffffffff
    xor edx, edx
    jmp short .check_actor_count

.discard_actor:
    movsx eax, byte [edx + actor_active]
    cmp eax, -1
    je short .advance_actor
    xor eax, eax
    mov al, byte [edx + actor_level]
    cmp ax, cx
    jne short .advance_actor
    mov ax, word [nosplit edx*2 + actor_sprite]
    cwde
    call delete_sprite
    mov word [nosplit edx*2 + actor_sprite], di

.advance_actor:
    inc edx

.check_actor_count:
    cmp edx, 0x1f4
    jle short .discard_actor
    xor edx, edx
    jmp short .check_slot_count

.check_actor_slot:
    movsx eax, word [nosplit edx*2 + actor_sprite]
    cmp eax, -1
    je short .advance_slot
    mov eax, discard_error
    call report_error

.advance_slot:
    inc edx

.check_slot_count:
    cmp edx, 0x1f4
    jle short .check_actor_slot

.load_level_board:
    movsx edx, cx
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov edx, level_names
    shl eax, 2
    add edx, eax
    mov eax, esp
    call copy_string
    mov eax, esp
    mov edx, esi
    call append_string
    push player_sector
    mov ebx, player_y
    mov ecx, player_z
    push player_angle
    mov edx, player_x
    lea eax, [esp + 8]
    call load_board
    add esp, 0x50
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
