; Initialize difficulty menu.
BITS 32
ORG 0x3ae44

frame_state_13a90 equ 0x13a90
frame_state_1745cc equ 0x1745cc

initialize_difficulty_menu:
    push ebx
    push edx
    xor edx, edx

.branch_3ae48:
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x2
    mov ebx, frame_state_13a90
    add eax, edx
    inc edx
    add ebx, eax
    mov [nosplit edx*4 + frame_state_1745cc], ebx
    cmp edx, 0x4
    jl short .branch_3ae48
    pop edx
    pop ebx
    ret
