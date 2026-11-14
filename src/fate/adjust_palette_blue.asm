; Adjust palette blue.
BITS 32
ORG 0x366e4

frame_state_173d28 equ 0x173d28

adjust_palette_blue:
    add [frame_state_173d28], eax
    ret
