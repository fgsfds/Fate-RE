; Initialize audio menu.
BITS 32
ORG 0x3af04

frame_state_13ae4 equ 0x13ae4
frame_state_1745e4 equ 0x1745e4

initialize_audio_menu:
    push ebx
    push edx
    xor edx, edx

.branch_3af08:
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x2
    mov ebx, frame_state_13ae4
    add eax, edx
    inc edx
    add ebx, eax
    mov [nosplit edx*4 + frame_state_1745e4], ebx
    cmp edx, 0x5
    jl short .branch_3af08
    pop edx
    pop ebx
    ret
