; Restore sprites for the current board from the saved actor positions and templates.
BITS 32
ORG 0x26749

actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_x equ 0x2040a0
sector_floor_z equ 0x27c3a8
tile_height equ 0x1f4020
actor_z_offset equ 0x79214
update_sector equ 0x542c4
actor_mode equ 0x7f67f
actor_tiles equ 0x7abc0
insert_sprite equ 0x508b8
format_string equ 0x601f3
report_error equ 0x26a03
sprite_position_backup equ 0x20a2c
sprite_interpolation_flags equ 0x1ecfa0
error_buffer equ 0x67e3c
actor_active equ 0x7ecb6
actor_level equ 0x7eac1
saved_actor_x equ 0x772c4
saved_actor_y equ 0x772c8
saved_actor_z equ 0x772cc
saved_actor_lotag equ 0x7d6ce
current_board equ 0x7f87e
invalid_actor_sector_message equ 0x3e0
inactive_actor_tiles equ 0x68080
sprite_actor_index equ 0x709dc
template_cstat equ 0x2a9d
template_shade equ 0x2a9f
template_palette equ 0x2aa0
template_clip_distance equ 0x2aa1
template_xrepeat equ 0x2aa2
template_yrepeat equ 0x2aa3
template_xoffset equ 0x2aa4
template_yoffset equ 0x2aa5
template_angle equ 0x2aa8
template_xvelocity equ 0x2aaa
template_yvelocity equ 0x2aac
template_zvelocity equ 0x2aae
template_owner equ 0x2ab0
template_status equ 0x2ab2
template_hitag equ 0x2ab6

restore_board_actor_sprites:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x18
    xor edx, edx
    mov [esp + 0xc], edx
    jmp near .check_slot_limit

.check_actor_slot:
    mov al, [esi + actor_active]
    mov [esp + 0x14], al
    movsx eax, al
    cmp eax, -1
    jz near .advance_actor_slot
    xor edx, edx
    movsx eax, byte [current_board]
    mov dl, [esi + actor_level]
    cmp edx, eax
    jnz near .advance_actor_slot
    mov ecx, esi
    shl ecx, byte 0x2
    sub ecx, esi
    shl ecx, byte 0x2
    lea ebx, [esp + 0x4]
    mov edx, [ecx + saved_actor_y]
    mov eax, [ecx + saved_actor_x]
    call update_sector
    cmp word [esp + 0x4], 0x0
    jnl short .choose_actor_tile
    mov edx, [ecx + saved_actor_y]
    push edx
    mov ebx, [ecx + saved_actor_x]
    push ebx
    push esi
    push strict dword invalid_actor_sector_message
    push strict dword error_buffer
    call format_string
    xor eax, eax
    mov al, [esi + actor_kind]
    add esp, 0x14
    cmp eax, 0x3
    jz near .advance_actor_slot
    mov eax, error_buffer
    call report_error

.choose_actor_tile:
    movsx ecx, word [esp + 0xc]
    xor eax, eax
    mov al, [ecx + actor_kind]
    cmp eax, 0x3
    jnz short .prepare_active_actor
    movsx eax, word [nosplit ecx*2 + saved_actor_lotag]
    sar eax, byte 0x8
    movsx edx, ax
    mov ebx, edx
    shl ebx, byte 0x4
    xor ecx, ecx
    sub ebx, edx
    mov [esp + 0x8], ecx
    mov di, [nosplit ebx*8 + inactive_actor_tiles]
    jmp short .insert_actor_sprite

.prepare_active_actor:
    mov ebx, ecx
    shl ebx, byte 0x3
    add ebx, ecx
    movzx edi, byte [ecx + actor_mode]
    add ebx, ebx
    movsx edx, byte [esp + 0x14]
    mov di, [ebx + edi*2 + actor_tiles]
    mov ebx, edx
    shl ebx, byte 0x3
    sub ebx, edx
    mov ax, [edx + ebx*4 + template_cstat]
    mov [esp + 0x8], eax
    xor eax, eax
    mov al, [edx + ebx*4 + template_yrepeat]
    movsx edx, di
    movsx edx, word [nosplit edx*2 + tile_height]
    imul eax, edx
    movsx edx, word [esp + 0x4]
    mov ebx, edx
    shl ebx, byte 0x2
    mov esi, [nosplit ecx*4 + actor_z_offset]
    add edx, ebx
    add eax, eax
    shl edx, byte 0x3
    mov ebx, ecx
    mov edx, [edx + sector_floor_z]
    shl ebx, byte 0x2
    add edx, esi
    sub ebx, ecx
    sub edx, eax
    mov [nosplit ebx*4 + saved_actor_z], edx

.insert_actor_sprite:
    movsx edx, byte [esp + 0x14]
    mov ebx, edx
    shl ebx, byte 0x3
    sub ebx, edx
    shl ebx, byte 0x2
    add ebx, edx
    movsx eax, word [esp + 0x4]
    movsx edx, word [ebx + template_status]
    call insert_sprite
    mov [esp], eax
    mov eax, [esp]
    movsx ebp, ax
    imul esi, ebp, 0x2c
    mov [esp + 0x10], ax
    movsx eax, word [esp + 0xc]
    mov ecx, eax
    shl ecx, byte 0x2
    sub ecx, eax
    add esi, sprite_x
    mov edx, [nosplit ecx*4 + saved_actor_x]
    mov [esi], edx
    mov edx, [nosplit ecx*4 + saved_actor_y]
    mov [esi + 0x4], edx
    mov edx, [nosplit ecx*4 + saved_actor_z]
    mov [esi + 0x8], edx
    mov edx, [esp + 0x8]
    mov [esi + 0xc], dx
    mov dl, [ebx + template_shade]
    mov [esi + 0x10], dl
    mov dl, [ebx + template_palette]
    mov [esi + 0x11], dl
    mov dl, [ebx + template_clip_distance]
    mov [esi + 0x12], dl
    mov dl, [ebx + template_xrepeat]
    mov [esi + 0x14], dl
    mov dl, [ebx + template_yrepeat]
    mov [esi + 0x15], dl
    mov dl, [ebx + template_xoffset]
    mov [esi + 0x16], dl
    mov dl, [ebx + template_yoffset]
    mov [esi + 0x17], dl
    mov [esi + 0xe], di
    mov dx, [ebx + template_angle]
    mov [esi + 0x1c], dx
    mov dx, [ebx + template_xvelocity]
    mov [esi + 0x20], dx
    mov dx, [ebx + template_yvelocity]
    mov [esi + 0x22], dx
    mov dx, [ebx + template_zvelocity]
    mov [esi + 0x24], dx
    mov dx, [ebx + template_owner]
    mov [esi + 0x1e], dx
    lea edx, [eax + eax]
    mov ax, [edx + saved_actor_lotag]
    mov [esi + 0x26], ax
    mov ax, [ebx + template_hitag]
    mov ebx, ebp
    shl ebx, byte 0x2
    mov ecx, 0x3
    sub ebx, ebp
    mov edi, sprite_position_backup
    shl ebx, byte 0x2
    mov word [esi + 0x2a], 0x0
    add edi, ebx
    mov [esi + 0x28], ax
    rep movsd
    mov cl, [esp + 0x10]
    mov al, 0x1
    and cl, 0x7
    mov ebx, ebp
    shl al, cl
    sar ebx, byte 0x3
    not al
    and [ebx + sprite_interpolation_flags], al
    mov eax, [esp + 0xc]
    mov [nosplit ebp*2 + sprite_actor_index], ax
    mov eax, [esp]
    mov [edx + actor_sprite_index], ax

.advance_actor_slot:
    inc dword [esp + 0xc]

.check_slot_limit:
    movsx esi, word [esp + 0xc]
    cmp esi, strict dword 0x1f4
    jng near .check_actor_slot
    add esp, 0x18
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
