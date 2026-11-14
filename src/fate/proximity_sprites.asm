; Update the proximity-triggered sprite list and its activation counters.
BITS 32
ORG 0x102ca

activate_sprite_at_player equ 0x129fc
absolute_long equ 0x602c3
random_value equ 0x602d0
cansee equ 0x50d33

advance_activation_counters equ 0x229b
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
activation_counter equ 0x7496c
activation_sprite_index equ 0x7497c
activation_sprite_count equ 0x7def0
sprite equ 0x2040a0
sprite_size equ 44
sprite_x equ 0
sprite_y equ 4
sprite_z equ 8
sprite_tile equ 14
sprite_sector equ 24

update_proximity_sprites:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov edi, 1
    jmp near .check_count
.next_sprite:
    movsx esi, di
    mov ax, [nosplit esi*2+activation_sprite_index]
    cwde
    imul edx, eax, sprite_size
    movsx ebx, word [sprite+edx+sprite_tile]
    cmp ebx, 0x3a6
    jl near .advance
    cmp ebx, 0x3a9
    jg near .advance
    cmp byte [activation_counter+esi], 0
    jbe near .check_proximity
    mov ecx, [player_z]
    add ecx, 2000
    cmp ebx, 0x3a8
    jge short .activate_upper_tiles
    push 5
    push 512
    mov ebx, [player_y]
    mov edx, [player_x]
    call activate_sprite_at_player
    xor al, al
    mov [activation_counter+esi], al
    jmp short .check_counter_clock
.activate_upper_tiles:
    push 4
    push 512
    mov ebx, [player_y]
    mov edx, [player_x]
    call activate_sprite_at_player
.check_counter_clock:
    cmp word [advance_activation_counters], 0
    je near .advance
    movsx edx, di
    inc byte [activation_counter+edx]
    xor eax, eax
    mov al, [activation_counter+edx]
    cmp eax, 3
    jle near .advance
    xor bl, bl
    mov [activation_counter+edx], bl
    jmp near .advance
.check_proximity:
    mov eax, [player_x]
    sub eax, [sprite+edx+sprite_x]
    call absolute_long
    cmp eax, 8192
    jge short .advance
    mov eax, [player_y]
    sub eax, [sprite+edx+sprite_y]
    call absolute_long
    cmp eax, 8192
    jge short .advance
    movsx eax, word [player_sector]
    push eax
    mov ebp, [player_z]
    push ebp
    mov eax, [player_y]
    mov ebx, [player_x]
    push eax
    movsx ecx, word [sprite+edx+sprite_sector]
    mov ebp, [sprite+edx+sprite_x]
    push ebx
    mov eax, [sprite+edx+sprite_y]
    mov ebx, [sprite+edx+sprite_z]
    mov edx, eax
    mov eax, ebp
    call cansee
    cwde
    cmp eax, 1
    jne short .advance
    call random_value
    xor ah, ah
    cwde
    cmp eax, 10
    jge short .advance
    mov byte [activation_counter+esi], 1
.advance:
    inc edi
.check_count:
    cmp di, [activation_sprite_count]
    jle near .next_sprite
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
