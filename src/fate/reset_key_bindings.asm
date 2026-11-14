; Reset key bindings.
BITS 32
ORG 0x3a42c

frame_state_13623 equ 0x13623
frame_state_1363c equ 0x1363c

reset_key_bindings:
    push edx
    xor eax, eax

.branch_3a42f:
    inc eax
    mov dl, [eax + frame_state_13623]
    mov [eax + frame_state_1363c], dl
    cmp eax, 0x19
    jl short .branch_3a42f
    pop edx
    ret
