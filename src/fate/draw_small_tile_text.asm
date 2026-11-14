; Draw small tile text.
BITS 32
ORG 0x385f4

character_types equ 0x1f20
frame_state_12df4 equ 0x12df4
rotatesprite equ 0x57181
strlen equ 0x60381
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c

draw_small_tile_text:
    push esi
    push edi
    push ebp
    sub esp, 0x10
    mov esi, eax
    mov [esp], edx
    mov [esp + 0x8], ebx
    mov [esp + 0xc], ecx
    mov eax, ecx
    call strlen
    xor edi, edi
    mov [esp + 0x4], eax
    jmp near .branch_386c0

.branch_38619:
    mov eax, [esp + 0xc]
    add eax, edi
    mov dl, [eax]
    xor ebx, ebx
    inc dl
    and edx, strict dword 0xff
    mov cl, [edx + character_types]
    and cl, 0xc0
    and ecx, strict dword 0xff
    jz short .branch_38646
    mov bl, [eax]
    add ebx, strict dword 0x7c4
    jmp short .branch_3866c

.branch_38646:
    mov dl, [edx + character_types]
    and dl, 0x20
    and edx, strict dword 0xff
    jz short .branch_38661
    mov bl, [eax]
    add ebx, strict dword 0x7c9
    jmp short .branch_3866c

.branch_38661:
    mov eax, [esp + 0x20]
    add esi, [nosplit eax*4 + frame_state_12df4]

.branch_3866c:
    test ebx, ebx
    jz short .branch_386bf
    mov ebp, [window_bottom]
    push ebp
    mov eax, [window_right]
    push eax
    mov edx, [window_top]
    push edx
    mov ecx, [window_left]
    push ecx
    push strict dword 0x92
    movsx eax, byte [esp + 0x1c]
    mov edx, [esp + 0x14]
    push strict byte 0x0
    shl edx, byte 0x10
    push eax
    movsx eax, bx
    xor ecx, ecx
    push eax
    mov eax, esi
    mov ebx, 0x10000
    shl eax, byte 0x10
    call rotatesprite
    mov eax, [esp + 0x20]
    add esi, [nosplit eax*4 + frame_state_12df4]

.branch_386bf:
    inc edi

.branch_386c0:
    cmp edi, [esp + 0x4]
    jl near .branch_38619
    add esp, 0x10
    pop ebp
    pop edi
    pop esi
    ret word 0x4
