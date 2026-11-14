; Activate tagged sectors on a sprite-presence change and handle the key trigger.
BITS 32
ORG 0x1e5d1

play_sound equ 0x34f79
sprite_tile equ 0x2040ae
activate_sector equ 0x28710
remove_sprite equ 0x10f9f
trigger_count equ 0x3be6
trigger_sprite equ 0x77124
trigger_target equ 0x77126
sector_lotag equ 0x27c3c2
key_sprite_consumed equ 0x12840
sector_reset_flag equ 0x12844
sprite_present equ 0x12846
previous_sprite_present equ 0x12848
trigger_sectors equ 0x1284a
sector_sprite_head equ 0x288a4a
next_sprite_in_sector equ 0x1f9ca0
level_flags equ 0x203c
key_wall_tile equ 0x236fd0

; Original ModR/M form of sub eax, 0x4000.
%macro sub_trigger_tag 0
    db 0x81, 0xe8
    dd 0x4000
%endmacro

update_board_7_script:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov dx, [sector_reset_flag]
    test dx, dx
    jnz short .check_sector_sprite_list
    jmp short .check_clear_index

.clear_sector_tag:
    movsx ebx, word [nosplit eax*2 + trigger_sectors]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    xor ebx, ebx
    inc edx
    mov [nosplit eax*8 + sector_lotag], bx

.check_clear_index:
    movsx eax, dx
    cmp eax, 0xf
    jng short .clear_sector_tag

.check_sector_sprite_list:
    mov edi, 0x1
    xor ecx, ecx
    mov dx, [sector_sprite_head]
    mov [sprite_present], cx
    jmp short .check_sprite_index

.advance_sector_sprite:
    movsx eax, dx
    mov [sprite_present], di
    mov dx, [nosplit eax*2 + next_sprite_in_sector]

.check_sprite_index:
    test dx, dx
    jnl short .advance_sector_sprite
    mov ax, [previous_sprite_present]
    mov si, [sprite_present]
    cmp ax, si
    jz short .check_key_consumed
    mov eax, 0x9c
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov [previous_sprite_present], si
    call play_sound
    mov esi, 0x6
    xor edx, edx
    jmp short .check_activation_index

.activate_trigger_sector:
    movsx ecx, word [nosplit ebx*2 + trigger_sectors]
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    mov [nosplit eax*8 + sector_lotag], si
    mov eax, ecx
    call activate_sector
    movsx ebx, word [nosplit ebx*2 + trigger_sectors]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    xor edi, edi
    inc edx
    mov [nosplit eax*8 + sector_lotag], di

.check_activation_index:
    movsx ebx, dx
    cmp ebx, 0xf
    jng short .activate_trigger_sector

.check_key_consumed:
    cmp dword [key_sprite_consumed], 0x0
    jnz near .return
    mov edx, 0x1
    jmp short .check_trigger_index

.scan_key_trigger:
    movsx eax, dx
    xor ebx, ebx
    mov cx, [nosplit eax*4 + trigger_sprite]
    mov ax, [nosplit eax*4 + trigger_target]
    mov bx, ax
    cmp ebx, strict dword 0x8000
    jnl short .advance_trigger
    sub_trigger_tag
    and eax, strict dword 0xffff
    cmp eax, 0x5d
    jnz short .advance_trigger
    movsx eax, cx
    imul ebx, eax, 0x2c
    movsx ebx, word [ebx + sprite_tile]
    cmp ebx, strict dword 0x20f
    jnz short .advance_trigger
    call remove_sprite
    mov ebx, 0x1
    mov ah, [level_flags]
    mov [key_sprite_consumed], ebx
    or ah, 0x1
    mov ebx, 0x689
    mov [level_flags], ah
    mov [key_wall_tile], bx

.advance_trigger:
    inc edx

.check_trigger_index:
    cmp dx, [trigger_count]
    jng short .scan_key_trigger

.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
