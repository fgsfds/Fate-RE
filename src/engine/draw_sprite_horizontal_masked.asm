; Draw sprite horizontal masked.
BITS 32
ORG 0x75250

frame_state_65299 equ 0x65299

draw_sprite_horizontal_masked:
    push ebp
    cmp eax, 0x0
    jng short .branch_752a2
    lea ebp, [edi-0x1]
    db 0x2b, 0xe8  ; sub ebp, eax, register-destination encoding
    mov [frame_state_65299], ebp
    db 0x8b, 0xf8  ; mov edi, eax, register-destination encoding
    jmp short .branch_75270
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    nop

.branch_75270:
    mov cl, [ebx]
    sub edx, strict dword 0x88888888
    db 0x1b, 0xed  ; sbb ebp, ebp, register-destination encoding
    sub esi, strict dword 0x88888888
    sbb ebx, strict dword 0x88888888
    and ebp, strict dword 0x88888888
    cmp cl, 0xff
    jz short .branch_7529d
    mov al, [ecx-0x77777778]
    mov [edi-0x77777778], al

.branch_7529d:
    db 0x2b, 0xdd  ; sub ebx, ebp, register-destination encoding
    dec edi
    jnz short .branch_75270

.branch_752a2:
    pop ebp
    ret
