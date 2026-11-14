; Reset palette fade.
BITS 32
ORG 0x366c6

frame_state_173d14 equ 0x173d14
frame_state_173d18 equ 0x173d18
frame_state_173d24 equ 0x173d24

reset_palette_fade:
    push edx
    xor edx, edx
    mov [frame_state_173d18], edx
    mov [frame_state_173d14], edx
    mov [frame_state_173d24], edx
    pop edx
    ret
