; Initialize control limits menu.
BITS 32
ORG 0x3b034

frame_state_13b60 equ 0x13b60
frame_state_174604 equ 0x174604

initialize_control_limits_menu:
    push ebx
    push edx
    xor edx, edx

.branch_3b038:
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x2
    mov ebx, frame_state_13b60
    add eax, edx
    inc edx
    add ebx, eax
    mov [nosplit edx*4 + frame_state_174604], ebx
    cmp edx, 0x3
    jl short .branch_3b038
    pop edx
    pop ebx
    ret
