; Adjust palette red.
BITS 32
ORG 0x366dd

frame_state_173d1c equ 0x173d1c

adjust_palette_red:
    add [frame_state_173d1c], eax
    ret
