; Initialize mouse menus.
BITS 32
ORG 0x3a924

frame_state_13a03 equ 0x13a03
frame_state_13a42 equ 0x13a42
frame_state_1745ac equ 0x1745ac
frame_state_1745b8 equ 0x1745b8

initialize_mouse_menus:
    push ebx
    push edx
    xor eax, eax

.branch_3a928:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_13a42
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_1745b8], ebx
    cmp eax, 0x3
    jl short .branch_3a928
    xor eax, eax

.branch_3a94a:
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    shl edx, byte 0x2
    mov ebx, frame_state_13a03
    add edx, eax
    inc eax
    add ebx, edx
    mov [nosplit eax*4 + frame_state_1745ac], ebx
    cmp eax, 0x3
    jl short .branch_3a94a
    pop edx
    pop ebx
    ret
