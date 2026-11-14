; Draw sprite horizontal reverse.
BITS 32
ORG 0x75310


draw_sprite_horizontal_reverse:
    push ebp
    cmp eax, 0x0
    jng near .branch_753ad
    db 0x8b, 0xe8  ; mov ebp, eax, register-destination encoding
    test ebp, 0x3
    jz short .branch_75354
    jmp short .branch_75330
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx

.branch_75330:
    mov cl, [ebx]
    dec edi
    sub esi, strict dword 0x88888888
    dec ebp
    sbb ebx, strict dword 0x88888888
    mov al, [ecx-0x77777778]
    mov [edi], al
    test ebp, 0x3
    jnz short .branch_75330
    test ebp, ebp
    jz short .branch_753ad

.branch_75354:
    mov cl, [ebx]
    jmp short .branch_75360
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx

.branch_75360:
    mov dl, [ebx-0x77777778]
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    mov ah, [ecx-0x77777778]
    mov al, [edx-0x77777778]
    sub edi, 0x4
    shl eax, byte 0x10
    mov cl, [ebx]
    mov dl, [ebx-0x77777778]
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    mov ah, [ecx-0x77777778]
    mov al, [edx-0x77777778]
    mov cl, [ebx]
    mov [edi], eax
    sub ebp, 0x4
    jnz short .branch_75360

.branch_753ad:
    pop ebp
    ret
