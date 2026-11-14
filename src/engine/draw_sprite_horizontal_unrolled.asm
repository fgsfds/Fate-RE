; Draw sprite horizontal unrolled.
BITS 32
ORG 0x75120

frame_state_65174 equ 0x65174
frame_state_65220 equ 0x65220

draw_sprite_horizontal_unrolled:
    push ebp
    cmp eax, 0x0
    jng near .branch_7522d
    lea ebp, [edi-0x4]
    db 0x2b, 0xe8  ; sub ebp, eax, register-destination encoding
    mov [frame_state_65220], ebp
    add ebp, 0x3
    mov [frame_state_65174], ebp
    db 0x8b, 0xf8  ; mov edi, eax, register-destination encoding
    test edi, 0x3
    jz short .branch_7518b
    jmp short .branch_75150
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx

.branch_75150:
    mov cl, [ebx]
    sub edx, strict dword 0x88888888
    db 0x1b, 0xed  ; sbb ebp, ebp, register-destination encoding
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    mov al, [ecx-0x77777778]
    and ebp, strict dword 0x88888888
    mov [edi-0x77777778], al
    db 0x2b, 0xdd  ; sub ebx, ebp, register-destination encoding
    dec edi
    test edi, 0x3
    jnz short .branch_75150
    test edi, edi
    jz near .branch_7522d

.branch_7518b:
    mov cl, [ebx]
    sub edx, strict dword 0x88888888
    db 0x1b, 0xed  ; sbb ebp, ebp, register-destination encoding
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    and ebp, strict dword 0x88888888
    db 0x2b, 0xdd  ; sub ebx, ebp, register-destination encoding
    sub edx, strict dword 0x88888888
    db 0x1b, 0xed  ; sbb ebp, ebp, register-destination encoding
    mov ah, [ecx-0x77777778]
    mov cl, [ebx]
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    and ebp, strict dword 0x88888888
    mov al, [ecx-0x77777778]
    db 0x2b, 0xdd  ; sub ebx, ebp, register-destination encoding
    shl eax, byte 0x10
    mov cl, [ebx]
    sub edx, strict dword 0x88888888
    db 0x1b, 0xed  ; sbb ebp, ebp, register-destination encoding
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    and ebp, strict dword 0x88888888
    db 0x2b, 0xdd  ; sub ebx, ebp, register-destination encoding
    sub edx, strict dword 0x88888888
    db 0x1b, 0xed  ; sbb ebp, ebp, register-destination encoding
    mov ah, [ecx-0x77777778]
    mov cl, [ebx]
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    and ebp, strict dword 0x88888888
    mov al, [ecx-0x77777778]
    db 0x2b, 0xdd  ; sub ebx, ebp, register-destination encoding
    mov [edi-0x77777778], eax
    sub edi, 0x4
    jnz near .branch_7518b

.branch_7522d:
    pop ebp
    ret
