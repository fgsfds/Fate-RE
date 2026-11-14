; Start four scripted actors when the player enters the trigger sectors.
BITS 32
ORG 0x1e41d

play_sound equ 0x34f79
actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_tile equ 0x2040ae
player_x equ 0x5ad9c
player_y equ 0x5ad5c
advance_clock equ 0x229b
player_sector equ 0x5acfc
actor_sector equ 0x7d2e4
update_sector equ 0x542c4
move_actor equ 0x196b2
actor_mode equ 0x7f67f
activate_tagged_sprite equ 0x11fdd
sprite_lotag equ 0x2040c6
actor_tag_flags equ 0x7d6ce
board_five_actors equ 0x12818
board_five_target_x equ 0x12820
board_five_target_y equ 0x12824
actor_script_step equ 0x851b0
second_actor_script_step equ 0x851b2
third_actor_script_step equ 0x851b4
fourth_actor_script_step equ 0x851b6
script_sprite_indices equ 0x7494e

update_board_5_script:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    cmp word [actor_script_step], 0x0
    jnz short .begin_actor_loop
    movsx eax, word [player_sector]
    cmp eax, strict dword 0xec
    jz short .start_actor_sequence
    cmp eax, strict dword 0xed
    jz short .start_actor_sequence
    cmp eax, strict dword 0xee
    jnz short .begin_actor_loop

.start_actor_sequence:
    mov ebx, 0x1
    mov eax, 0x8e
    xor ecx, ecx
    xor edx, edx
    mov [actor_script_step], bx
    mov [second_actor_script_step], bx
    mov [third_actor_script_step], bx
    mov [fourth_actor_script_step], bx
    xor ebx, ebx
    call play_sound

.begin_actor_loop:
    xor eax, eax
    mov [esp], eax
    jmp near .check_actor_index

.update_script_actor:
    add edx, edx
    mov bx, [edx + board_five_actors]
    movsx eax, bx
    mov al, [eax + actor_kind]
    and eax, strict dword 0xff
    cmp eax, 0x3
    jz near .advance_actor_index
    movsx eax, word [edx + actor_script_step]
    cmp eax, 0x1
    jnz short .check_delay
    mov ax, [edx + script_sprite_indices]
    cwde
    imul ebx, eax, 0x2c
    mov ecx, 0x4400
    mov esi, 0x2
    mov [ebx + sprite_lotag], cx
    call activate_tagged_sprite
    mov [edx + actor_script_step], si
    jmp near .advance_actor_index

.check_delay:
    cmp eax, 0x2
    jl short .check_move_step
    cmp eax, 0x7
    jg short .check_move_step
    cmp word [advance_clock], 0x0
    jz near .advance_actor_index
    inc word [edx + actor_script_step]
    jmp near .advance_actor_index

.check_move_step:
    movsx esi, word [esp]
    lea ebp, [esi + esi]
    movsx eax, word [ebp + actor_script_step]
    cmp eax, 0x8
    jnz near .advance_actor_index
    movsx edi, bx
    lea ecx, [edi + edi]
    movsx edx, word [ecx + actor_sprite_index]
    imul edx, edx, 0x2c
    mov ebx, 0x91b
    mov ah, [edx + sprite_lotag]
    mov [edx + sprite_tile], bx
    or ah, 0x65
    mov ebx, actor_sector
    mov [edx + sprite_lotag], ah
    mov dl, [ecx + actor_tag_flags]
    add ebx, ecx
    or dl, 0x65
    mov eax, [nosplit esi*8 + board_five_target_x]
    mov [ecx + actor_tag_flags], dl
    mov edx, [nosplit esi*8 + board_five_target_y]
    call update_sector
    mov edx, [player_y]
    mov ebx, [player_x]
    mov eax, edi
    push edx
    movsx ecx, word [ecx + actor_sector]
    push ebx
    mov edx, [nosplit esi*8 + board_five_target_x]
    mov ebx, [nosplit esi*8 + board_five_target_y]
    call move_actor
    cmp byte [edi + actor_kind], 0x0
    jnz short .advance_actor_index
    mov bl, 0x2
    mov ecx, 0x9
    mov [edi + actor_mode], bl
    mov [ebp + actor_script_step], cx

.advance_actor_index:
    inc dword [esp]

.check_actor_index:
    movsx edx, word [esp]
    cmp edx, 0x3
    jng near .update_script_actor
    add esp, 0x4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
