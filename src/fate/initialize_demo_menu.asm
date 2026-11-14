; Initialize demo menu.
BITS 32
ORG 0x3a6be

frame_state_138cc equ 0x138cc
frame_state_174558 equ 0x174558

initialize_demo_menu:
    push ebx
    push edx
    xor edx, edx

.branch_3a6c2:
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x2
    mov ebx, frame_state_138cc
    add eax, edx
    inc edx
    add ebx, eax
    mov [nosplit edx*4 + frame_state_174558], ebx
    cmp edx, 0x3
    jl short .branch_3a6c2
    pop edx
    pop ebx
    ret
