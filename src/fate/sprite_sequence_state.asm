; Update a sprite from its tile sequence and track its activation state.
BITS 32
ORG 0x10433

move_actor equ 0x196b2
set_sprite_position equ 0x506f6
update_sector equ 0x542c4
absolute_long equ 0x602c3

advance_state_clock equ 0x229b
player_y equ 0x5ad5c
player_x equ 0x5ad9c
actor_z_offset equ 0x79214
actor_x equ 0x799e8
actor_y equ 0x7a1bc
actor_sector equ 0x7d2e4
actor_sprite_index equ 0x7dab8
actor_state equ 0x7e2ed
actor_sequence_initial equ 0x7e4e2
actor_frame equ 0x7e6d7
actor_kind equ 0x7f0a0
actor_flag equ 0x7f67f
tile_height equ 0x1f4020
sprite_tile equ 0x2040ae
sprite_yrepeat equ 0x2040b5
sector_floor_z equ 0x27c3a8

update_sprite_sequence_state:
    push esi
    push edi
    push ebp
    sub esp, 8
    mov esi, eax
    mov eax, edx
    mov edx, ebx
    movsx esi, si
    lea ebx, [esi+esi]
    movzx edi, byte [esi+actor_kind]
    mov [esp+4], ebx
    mov bx, [ebx+actor_sprite_index]
    cmp edi, 3
    je near .return
    cmp edi, 4
    je short .fixed_tile
    cmp edi, 5
    jne short .check_initial_state
.fixed_tile:
    movsx eax, bx
    imul eax, eax, 44
    mov edx, [esp+28]
    mov dx, [edx+4]
    mov [eax+sprite_tile], dx
    jmp near .return
.check_initial_state:
    mov edi, esi
    shl edi, 2
    cmp byte [esi+actor_state], 0
    jne short .check_active_state
    xor ch, ch
    mov ebx, actor_sector
    mov [esi+actor_flag], ch
    mov ecx, [esp+4]
    mov [edi+actor_x], eax
    add ebx, ecx
    mov [edi+actor_y], edx
    call update_sector
    mov eax, [esp+28]
    mov al, [eax]
    mov [esi+actor_sequence_initial], al
    mov byte [esi+actor_state], 1
    jmp near .return
.check_active_state:
    xor eax, eax
    mov al, [esi+actor_state]
    cmp eax, 1
    jne near .check_animation_state
    movsx eax, bx
    mov [esp], eax
    imul ebp, eax, 44
    mov eax, [esp+28]
    mov ax, [eax+2]
    mov [ebp+sprite_tile], ax
    mov eax, [esp+24]
    push eax
    mov edx, [edi+actor_x]
    push ecx
    mov ecx, [esp+12]
    mov ebx, [edi+actor_y]
    mov eax, esi
    movsx ecx, word [ecx+actor_sector]
    call move_actor
    cmp byte [esi+actor_kind], 0
    jne near .return
    movsx eax, word [ebp+sprite_tile]
    movsx edx, word [nosplit eax*2+tile_height]
    xor eax, eax
    mov al, [ebp+sprite_yrepeat]
    mov ecx, eax
    imul ecx, edx
    mov edx, [esp+4]
    movsx edx, word [edx+actor_sector]
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov eax, [eax*8+sector_floor_z]
    mov edx, [edi+actor_z_offset]
    add ecx, ecx
    add eax, edx
    mov ebx, [edi+actor_y]
    sub eax, ecx
    mov edx, [edi+actor_x]
    mov ecx, eax
    mov eax, [esp]
    call set_sprite_position
    cmp word [advance_state_clock], 0
    je near .return
    mov bh, 3
    mov eax, [esp+28]
    mov [esi+actor_frame], bh
    mov ax, [eax+6]
    mov cl, 2
    mov [ebp+sprite_tile], ax
    mov [esi+actor_state], cl
    jmp short .return
.check_animation_state:
    cmp eax, 2
    jne short .check_reset_state
    cmp word [advance_state_clock], 0
    je short .return
    mov dl, [esi+actor_frame]
    xor eax, eax
    inc dl
    mov al, dl
    mov [esi+actor_frame], dl
    mov edx, [esp+28]
    add eax, eax
    add eax, edx
    movsx edx, word [eax]
    cmp edx, -1
    jne short .show_frame
    mov byte [esi+actor_state], 3
    jmp short .return
.show_frame:
    movsx edx, bx
    imul edx, edx, 44
    mov ax, [eax]
    mov [edx+sprite_tile], ax
    jmp short .return
.check_reset_state:
    cmp eax, 3
    jne short .return
    xor ah, ah
    mov [esi+actor_state], ah
.return:
    add esp, 8
    pop ebp
    pop edi
    pop esi
    ret 8

%macro check_player_distance 2
%1:
    push ebx
    mov ebx, [player_x]
    sub ebx, eax
    mov eax, ebx
    call absolute_long
    cmp eax, %2
    jge short %%outside
    mov eax, [player_y]
    sub eax, edx
    call absolute_long
    cmp eax, %2
    jge short %%outside
    mov eax, 1
    pop ebx
    ret
%%outside:
    xor eax, eax
    pop ebx
    ret
%endmacro

check_player_distance player_within_512_xy, 512
check_player_distance player_within_4096_xy, 4096
