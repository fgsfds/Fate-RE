; Tile the screen region outside the active viewport.
BITS 32
ORG 0x346f2

rotatesprite equ 0x57181
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020

draw_view_border:
    push esi
    push edi
    push ebp
    sub esp, 0x14
    push ebx
    mov [esp + 0x14], cl
    mov eax, [esp + 0x28]
    movsx esi, bx
    mov edx, eax
    movsx ebp, word [nosplit esi*2 + tilesizx]
    sar edx, byte 0x1f
    idiv ebp
    mov edi, eax
    mov eax, [esp + 0x30]
    mov edx, eax
    sar edx, byte 0x1f
    idiv ebp
    mov [esp + 0x8], eax
    movsx eax, word [nosplit esi*2 + tilesizy]
    mov [esp + 0x10], eax
    mov eax, [esp + 0x2c]
    mov edx, eax
    mov ebx, [esp + 0x10]
    sar edx, byte 0x1f
    idiv ebx
    mov [esp + 0x4], eax
    mov eax, [esp + 0x34]
    mov edx, eax
    sar edx, byte 0x1f
    idiv ebx
    mov [esp + 0xc], eax
    jmp short .branch_347ac

.branch_34754:
    mov esi, [esp + 0x4]
    jmp short .branch_347a5

.branch_3475a:
    mov edx, [esp + 0x34]
    push edx
    mov edx, [esp + 0x14]
    imul edx, esi
    mov ebx, [esp + 0x34]
    push ebx
    mov ecx, [esp + 0x34]
    push ecx
    mov eax, [esp + 0x34]
    push eax
    xor eax, eax
    push strict dword 0xd8
    mov al, [esp + 0x4c]
    push eax
    movsx eax, byte [esp + 0x2c]
    push eax
    movsx eax, word [esp + 0x1c]
    push eax
    mov eax, edi
    imul eax, ebp
    mov ebx, 0x10000
    xor ecx, ecx
    shl edx, byte 0x10
    shl eax, byte 0x10
    inc esi
    call rotatesprite

.branch_347a5:
    cmp esi, [esp + 0xc]
    jng short .branch_3475a
    inc edi

.branch_347ac:
    cmp edi, [esp + 0x8]
    jng short .branch_34754
    add esp, 0x18
    pop ebp
    pop edi
    pop esi
    ret word 0x14
