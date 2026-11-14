; Select directional frames for temporary sprites before rendering.
BITS 32
ORG 0x2a1ef

view_state_3ccb equ 0x3ccb
projectile_positions equ 0x20a2c
get_angle equ 0x4c94c
view_state_770bc equ 0x770bc
view_state_770d4 equ 0x770d4
tile_animation_flags equ 0x1ed3a0
temporary_sprites equ 0x2710a0
view_state_27c3ac equ 0x27c3ac
view_state_27c3b4 equ 0x27c3b4
view_state_27c3bc equ 0x27c3bc
view_state_287e84 equ 0x287e84

directional_sprite_tiles:
    dw 2767, 2762, 2757, 2752, 2747, 2742, 2737, 2732
    dw 2727, 2707, 2677, 2672, 2657, 2652, 2647, 2642
    dw 2637, 2632, 2627, 2622, 2617, 2597, 2567, 2562
    dw 2533, 2528, 2523, 2518, 2513, 2493, 2488, 2441
    dw 2411, 2406, 2391, 2386, 2381, 2376, 2371, 2366
    dw 2361, 2356, 2351, 2331, 2301, 2296, 843, 838
    dw 833, 785, 766, 165

sprite_view_dispatch:
    dd update_sprite_view.check_sprite_sector - 0x10000
    times 52 dd update_sprite_view.apply_directional_frame - 0x10000

update_sprite_view:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    push eax
    push edx
    xor edx, edx
    mov esi, temporary_sprites
    mov [esp + 0x8], edx
    jmp near .check_sprite_count

.classify_sprite_tile:
    mov ecx, 0x35
    mov edi, directional_sprite_tiles - 0x10000
    mov ax, [esi + 0xe]
    db 0xf2, 0x66, 0xaf ; repne scasw with the original prefix order
    jmp dword [cs:nosplit ecx*4 + sprite_view_dispatch - 0x10000]

.apply_directional_frame:
    mov edi, [esp]
    movsx eax, word [esi + 0xe]
    mov ebx, [esp + 0x4]
    mov eax, [nosplit eax*4 + tile_animation_flags]
    mov edx, [esi + 0x4]
    mov cl, al
    mov eax, [esi]
    sub edx, edi
    sub eax, ebx
    call get_angle
    mov edx, eax
    movsx eax, word [esi + 0x1c]
    add eax, strict dword 0xc80
    sub eax, edx
    and eax, strict dword 0x7ff
    sar eax, byte 0x8
    and cl, 0x3f
    and eax, 0x7
    inc cl
    cmp eax, 0x4
    jg short .apply_mirrored_frame
    xor edx, edx
    mov dl, cl
    imul eax, edx
    mov bx, [esi + 0xe]
    mov dl, [esi + 0xc]
    add ebx, eax
    and dl, 0xfb
    mov [esi + 0xe], bx
    mov [esi + 0xc], dl
    jmp short .check_sprite_sector

.apply_mirrored_frame:
    mov edx, 0x8
    sub edx, eax
    xor eax, eax
    mov al, cl
    imul eax, edx
    mov dx, [esi + 0xe]
    add edx, eax
    mov ah, [esi + 0xc]
    mov [esi + 0xe], dx
    or ah, 0x4
    mov [esi + 0xc], ah

.check_sprite_sector:
    movsx eax, word [esi + 0x1a]
    movsx eax, byte [eax + view_state_3ccb]
    test eax, eax
    jl near .check_nearby_sprite
    movsx edx, word [esi + 0x1e]
    mov ecx, edx
    shl ecx, byte 0x2
    mov ebx, [view_state_770d4]
    sub ecx, edx
    sub ebx, edx
    shl ecx, byte 0x2
    mov edx, ebx
    add ecx, projectile_positions
    cmp eax, 0x3
    jc short .branch_2a429
    jna short .branch_2a44b
    cmp eax, 0x7
    jc near .branch_2a47d
    jna short .branch_2a45c
    cmp eax, 0xf
    jz short .branch_2a46d
    jmp short .branch_2a47d

.branch_2a429:
    test eax, eax
    jna short .branch_2a434
    cmp eax, 0x1
    jz short .branch_2a43c
    jmp short .branch_2a47d

.branch_2a434:
    mov ebp, [view_state_770bc]
    jmp short .branch_2a47d

.branch_2a43c:
    and edx, eax
    mov ebp, [view_state_770bc]
    shl edx, byte 0xf
    sar ebp, 1
    jmp short .branch_2a47b

.branch_2a44b:
    and edx, 0x3
    mov ebp, [view_state_770bc]
    shl edx, byte 0xe
    sar ebp, byte 0x2
    jmp short .branch_2a47b

.branch_2a45c:
    and edx, 0x7
    mov ebp, [view_state_770bc]
    shl edx, byte 0xd
    sar ebp, byte 0x3
    jmp short .branch_2a47b

.branch_2a46d:
    and edx, eax
    mov ebp, [view_state_770bc]
    shl edx, byte 0xc
    sar ebp, byte 0x4

.branch_2a47b:
    add ebp, edx

.branch_2a47d:
    mov edi, [ecx]
    mov eax, [esi]
    mov [esi], edi
    sub eax, edi
    jz short .branch_2a491
    mov ebx, ebp
    imul ebx
    shrd eax, edx, byte 0x10
    add [esi], eax

.branch_2a491:
    mov ebx, [ecx + 0x4]
    mov eax, [esi + 0x4]
    mov [esi + 0x4], ebx
    sub eax, ebx
    jz short .branch_2a4a9
    mov ebx, ebp
    imul ebx
    shrd eax, edx, byte 0x10
    add [esi + 0x4], eax

.branch_2a4a9:
    mov edx, [ecx + 0x8]
    mov eax, [esi + 0x8]
    mov [esi + 0x8], edx
    sub eax, edx
    jz short .check_nearby_sprite
    mov ebx, ebp
    imul ebx
    shrd eax, edx, byte 0x10
    add [esi + 0x8], eax

.check_nearby_sprite:
    movsx eax, word [esi + 0x1a]
    cmp eax, 0x3
    jz short .branch_2a4d9
    cmp eax, 0x4
    jz short .branch_2a4d9
    cmp eax, 0x5
    jz short .branch_2a4d9
    cmp eax, 0x7
    jnz short .branch_2a503

.branch_2a4d9:
    mov eax, [esp + 0x4]
    sub eax, [esi]
    test eax, eax
    jns short .branch_2a4e5
    neg eax

.branch_2a4e5:
    cmp eax, strict dword 0x100
    jnl short .branch_2a503
    mov eax, [esp]
    sub eax, [esi + 0x4]
    test eax, eax
    jns short .branch_2a4f8
    neg eax

.branch_2a4f8:
    cmp eax, strict dword 0x100
    jnl short .branch_2a503
    and byte [esi + 0xc], 0xfd

.branch_2a503:
    movsx edx, word [esi + 0x18]
    mov eax, edx
    shl eax, byte 0x2
    mov bl, [esi + 0x10]
    add eax, edx
    add bl, 0x6
    shl eax, byte 0x3
    mov [esi + 0x10], bl
    mov dx, [eax + view_state_27c3ac]
    xor dh, dh
    and dl, 0x1
    movsx edx, dx
    test edx, edx
    jz short .branch_2a53c
    mov cl, bl
    mov al, [eax + view_state_27c3b4]
    add cl, al
    mov [esi + 0x10], cl
    jmp short .branch_2a549

.branch_2a53c:
    mov bh, bl
    mov al, [eax + view_state_27c3bc]
    add bh, al
    mov [esi + 0x10], bh

.branch_2a549:
    mov eax, [esp + 0x8]
    inc eax
    add esi, 0x2c
    mov [esp + 0x8], eax

.check_sprite_count:
    mov eax, [esp + 0x8]
    cmp eax, [view_state_287e84]
    jl near .classify_sprite_tile
    add esp, 0xc
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
