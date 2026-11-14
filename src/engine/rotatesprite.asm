; Validate, draw and optionally queue a rotated sprite.
BITS 32
ORG 0x57181

engine_13ffd equ 0x13ffd
engine_14010 equ 0x14010
permanent_sprite_tail equ 0x140cb
frame_state_140cf equ 0x140cf
animateoffs equ 0x50758
draw_rotated_sprite equ 0x573ac
permanent_sprite_queue equ 0x191750
picanm equ 0x1ed3a0
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
display_page_count equ 0x287e80

rotatesprite:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov ebp, eax
    mov edi, edx
    mov esi, ebx
    mov [esp], ecx
    mov eax, [esp + 0x24]
    cmp eax, [esp + 0x2c]
    jg near .branch_573a3
    mov eax, [esp + 0x28]
    cmp eax, [esp + 0x30]
    jg near .branch_573a3
    cmp esi, 0x10
    jng near .branch_573a3
    movsx eax, word [esp + 0x14]
    test byte [nosplit eax*4 + picanm], 0xc0
    jz short .branch_571d2
    mov edx, 0xffffc000
    call animateoffs
    add [esp + 0x14], eax

.branch_571d2:
    movsx edx, word [esp + 0x14]
    lea eax, [edx + edx]
    cmp word [eax + tilesizx], 0x0
    jng near .branch_573a3
    cmp word [eax + tilesizy], 0x0
    jng near .branch_573a3
    mov ecx, [esp + 0x30]
    push ecx
    mov eax, [esp + 0x30]
    push eax
    mov ebx, [esp + 0x30]
    push ebx
    mov ecx, [esp + 0x30]
    xor eax, eax
    push ecx
    mov al, [esp + 0x30]
    push eax
    xor eax, eax
    mov al, [esp + 0x30]
    push eax
    movsx eax, byte [esp + 0x30]
    mov ebx, esi
    push eax
    movsx ecx, word [esp + 0x1c]
    push edx
    mov eax, ebp
    mov edx, edi
    call draw_rotated_sprite
    mov al, [esp + 0x20]
    and al, 0x80
    and eax, strict dword 0xff
    jz near .branch_573a3
    cmp dword [display_page_count], 0x2
    jl near .branch_5739c
    mov edx, [permanent_sprite_tail]
    mov eax, edx
    shl eax, byte 0x3
    add eax, edx
    mov edx, permanent_sprite_queue
    shl eax, byte 0x2
    add edx, eax
    mov [edx], ebp
    mov [edx + 0x4], edi
    mov eax, [esp]
    mov [edx + 0x8], esi
    mov [edx + 0xc], ax
    mov eax, [esp + 0x14]
    mov [edx + 0xe], ax
    mov al, [esp + 0x18]
    mov [edx + 0x10], al
    mov al, [esp + 0x1c]
    mov [edx + 0x11], al
    mov al, [esp + 0x20]
    mov [edx + 0x12], al
    mov ah, [engine_14010]
    and ah, 0x1
    shl ah, byte 0x7
    mov al, [display_page_count]
    add al, ah
    mov [edx + 0x13], al
    mov eax, [esp + 0x24]
    mov [edx + 0x14], eax
    mov eax, [esp + 0x28]
    mov [edx + 0x18], eax
    mov eax, [esp + 0x2c]
    mov [edx + 0x1c], eax
    mov eax, [esp + 0x30]
    mov [edx + 0x20], eax
    mov al, [esp + 0x20]
    and al, 0x40
    and eax, strict dword 0xff
    jz near .branch_5738a
    mov esi, [frame_state_140cf]
    jmp near .branch_5737e

.branch_572de:
    mov eax, esi
    shl eax, byte 0x3
    add eax, esi
    shl eax, byte 0x2
    add eax, permanent_sprite_queue
    mov bl, [eax + 0x13]
    and bl, 0x7f
    and ebx, strict dword 0xff
    jz near .branch_57377
    mov ebx, [eax]
    cmp ebx, [edx]
    jnz near .branch_57377
    mov ebx, [eax + 0x4]
    cmp ebx, [edx + 0x4]
    jnz near .branch_57377
    mov ebx, [eax + 0x8]
    cmp ebx, [edx + 0x8]
    jnz short .branch_57377
    mov bx, [eax + 0xc]
    cmp bx, [edx + 0xc]
    jnz short .branch_57377
    movsx ecx, word [eax + 0xe]
    add ecx, ecx
    movsx ebx, word [edx + 0xe]
    mov di, [ecx + tilesizx]
    add ebx, ebx
    cmp di, [ebx + tilesizx]
    jg short .branch_57377
    mov cx, [ecx + tilesizy]
    cmp cx, [ebx + tilesizy]
    jg short .branch_57377
    mov ebx, [eax + 0x14]
    cmp ebx, [edx + 0x14]
    jl short .branch_57377
    mov ebx, [eax + 0x18]
    cmp ebx, [edx + 0x18]
    jl short .branch_57377
    mov ebx, [eax + 0x1c]
    cmp ebx, [edx + 0x1c]
    jg short .branch_57377
    mov ebx, [eax + 0x20]
    cmp ebx, [edx + 0x20]
    jg short .branch_57377
    mov byte [eax + 0x13], 0x0

.branch_57377:
    inc esi
    and esi, strict dword 0x1ff

.branch_5737e:
    cmp esi, [permanent_sprite_tail]
    jnz near .branch_572de

.branch_5738a:
    mov eax, [permanent_sprite_tail]
    inc eax
    and eax, strict dword 0x1ff
    mov [permanent_sprite_tail], eax
    jmp short .branch_573a3

.branch_5739c:
    mov byte [engine_13ffd], 0x1

.branch_573a3:
    add esp, 0x4
    pop ebp
    pop edi
    pop esi
    ret word 0x20
