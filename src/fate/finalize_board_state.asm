; Apply per-board render state and visibility settings.
BITS 32
ORG 0x34211

frame_state_1d12a equ 0x1d12a
frame_state_1d12c equ 0x1d12c
loadtile equ 0x4bb0d
player_sprite equ 0x62f2c
sector_visibility_before_first equ 0x1ec69f
engine_1ec6a0 equ 0x1ec6a0
wall_visibility_before_first equ 0x1ec91f
engine_1ec920 equ 0x1ec920
sprite_visibility_before_first equ 0x1ecf9f
sprite_visibility equ 0x1ecfa0
waloff equ 0x1ffca0
walls equ 0x2310a0
motion_state_2310b0 equ 0x2310b0
motion_state_2310b2 equ 0x2310b2
board_state_2310ba equ 0x2310ba
sectors equ 0x27c3a0
sector_wall_count equ 0x27c3a2
frame_state_27c3b0 equ 0x27c3b0
sector_floor_tile equ 0x27c3b8
sector_lotag equ 0x27c3c2
numsectors equ 0x289154
engine_2891d8 equ 0x2891d8

finalize_board_state:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x10
    mov ebx, eax
    test ax, ax
    jl near .branch_344da
    cmp ax, [numsectors]
    jnl near .branch_344da
    xor edx, edx
    jmp short .branch_3423f

.branch_34236:
    inc edx
    xor ah, ah
    mov [edx + sector_visibility_before_first], ah

.branch_3423f:
    cmp edx, strict dword 0x80
    jl short .branch_34236
    xor edx, edx
    jmp short .branch_34254

.branch_3424b:
    inc edx
    xor cl, cl
    mov [edx + wall_visibility_before_first], cl

.branch_34254:
    cmp edx, strict dword 0x400
    jl short .branch_3424b
    xor edx, edx
    jmp short .branch_34269

.branch_34260:
    inc edx
    xor cl, cl
    mov [edx + sprite_visibility_before_first], cl

.branch_34269:
    cmp edx, strict dword 0x200
    jl short .branch_34260
    xor ch, ch
    movsx edx, bx
    mov [engine_2891d8], ch
    mov cl, bl
    mov eax, edx
    and cl, 0x7
    mov esi, edx
    mov ch, 0x1
    sar eax, byte 0x3
    shl ch, cl
    shl edx, byte 0x2
    mov cl, ch
    add edx, esi
    mov ch, [eax + engine_1ec6a0]
    mov [frame_state_1d12c], bx
    or ch, cl
    movsx edx, word [nosplit edx*8 + sector_lotag]
    mov [eax + engine_1ec6a0], ch
    cmp edx, 0x63
    jnz short .branch_342c3
    mov dl, cl
    not dl
    mov dh, ch
    and dh, dl
    mov [eax + engine_1ec6a0], dh

.branch_342c3:
    movsx edx, bx
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov ax, [nosplit eax*8 + frame_state_27c3b0]
    cwde
    cmp dword [nosplit eax*4 + waloff], 0x0
    jnz short .branch_342e5
    call loadtile

.branch_342e5:
    movsx edx, bx
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov ax, [nosplit eax*8 + sector_floor_tile]
    cwde
    cmp dword [nosplit eax*4 + waloff], 0x0
    jnz short .branch_34307
    call loadtile

.branch_34307:
    xor edi, edi
    mov [esp + 0x4], edi
    mov edi, 0x1
    jmp near .branch_344ce

.branch_34317:
    movsx eax, word [nosplit ebp*2 + frame_state_1d12c]
    mov [esp + 0xc], eax
    mov edx, eax
    shl eax, byte 0x2
    add eax, edx
    movsx ebx, word [nosplit eax*8 + sectors]
    movsx eax, word [nosplit eax*8 + sector_wall_count]
    lea edx, [ebx + eax]
    mov esi, walls
    mov [esp + 0x8], edx
    mov edx, ebx
    shl ebx, byte 0x5
    add esi, ebx
    jmp near .branch_34498

.branch_34352:
    mov eax, edx
    sar eax, byte 0x3
    or [eax + engine_1ec920], bl
    mov ebx, [esp + 0xc]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0x63
    jz short .branch_34386
    mov eax, edx
    shl eax, byte 0x5
    movsx eax, word [eax + board_state_2310ba]
    cmp eax, 0x63
    jnz short .branch_3439c

.branch_34386:
    mov cl, dl
    mov bl, 0x1
    and cl, 0x7
    mov eax, edx
    shl bl, cl
    sar eax, byte 0x3
    not bl
    and [eax + engine_1ec920], bl

.branch_3439c:
    mov eax, edx
    shl eax, byte 0x5
    mov ax, [eax + motion_state_2310b0]
    cwde
    cmp dword [nosplit eax*4 + waloff], 0x0
    jnz short .branch_343b8
    call loadtile

.branch_343b8:
    mov eax, edx
    shl eax, byte 0x5
    mov ax, [eax + motion_state_2310b2]
    movsx ebx, ax
    test ebx, 0xfffff000
    jnz short .branch_343df
    cwde
    cmp dword [nosplit eax*4 + waloff], 0x0
    jnz short .branch_343df
    call loadtile

.branch_343df:
    movsx ebx, word [esi + 0xc]
    test ebx, ebx
    jl near .branch_34466
    mov eax, ebx
    sar eax, byte 0x3
    xor ecx, ecx
    mov cl, [eax + engine_1ec6a0]
    mov [esp], ecx
    mov ecx, ebx
    mov ebp, 0x1
    and ecx, 0x7
    shl ebp, cl
    mov ecx, ebp
    test [esp], ecx
    jnz short .branch_34466
    mov cl, bl
    and cl, 0x7
    mov ch, 0x1
    shl ch, cl
    mov cl, ch
    or [eax + engine_1ec6a0], cl
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ax, [nosplit eax*8 + frame_state_27c3b0]
    cwde
    cmp dword [nosplit eax*4 + waloff], 0x0
    jnz short .branch_3443e
    call loadtile

.branch_3443e:
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ax, [nosplit eax*8 + sector_floor_tile]
    cwde
    cmp dword [nosplit eax*4 + waloff], 0x0
    jnz short .branch_3445d
    call loadtile

.branch_3445d:
    inc edi
    mov [nosplit edi*2 + frame_state_1d12a], bx

.branch_34466:
    mov ecx, [esp + 0xc]
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0x63
    jnz short .branch_34494
    mov eax, ebx
    mov cl, bl
    mov bl, 0x1
    and cl, 0x7
    shl bl, cl
    sar eax, byte 0x3
    not bl
    and [eax + engine_1ec6a0], bl

.branch_34494:
    inc edx
    add esi, 0x20

.branch_34498:
    mov cl, dl
    mov bl, 0x1
    and cl, 0x7
    mov eax, [esp + 0x8]
    shl bl, cl
    cmp edx, eax
    jl near .branch_34352
    movsx eax, word [player_sprite]
    sar eax, byte 0x3
    mov edx, [esp + 0x4]
    mov ch, [eax + sprite_visibility]
    inc edx
    or ch, bl
    mov [esp + 0x4], edx
    mov [eax + sprite_visibility], ch

.branch_344ce:
    mov ebp, [esp + 0x4]
    cmp edi, ebp
    jg near .branch_34317

.branch_344da:
    add esp, 0x10
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
