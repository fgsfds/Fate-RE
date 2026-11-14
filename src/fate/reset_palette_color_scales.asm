BITS 32
ORG 0x36930

frame_state_173d1c equ 0x173d1c
frame_state_173d20 equ 0x173d20
frame_state_173d28 equ 0x173d28

reset_palette_color_scales:
    push edx
    mov edx, 0x1
    mov [frame_state_173d1c], edx
    mov [frame_state_173d20], edx
    mov [frame_state_173d28], edx
    pop edx
    ret
