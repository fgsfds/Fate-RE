; Scale fade palette.
BITS 32
ORG 0x365b6

saved_palette equ 0x172e14
frame_state_27c09f equ 0x27c09f

scale_fade_palette:
    push ebx
    push edx
    mov ebx, eax
    xor eax, eax

.branch_365bc:
    xor edx, edx
    mov dl, [eax + saved_palette]
    imul edx, ebx
    inc eax
    sar edx, byte 0x8
    mov [eax + frame_state_27c09f], dl
    cmp eax, strict dword 0x300
    jl short .branch_365bc
    pop edx
    pop ebx
    ret
