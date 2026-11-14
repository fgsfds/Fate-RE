; Adjust palette green.
BITS 32
ORG 0x366eb

frame_state_173d20 equ 0x173d20

adjust_palette_green:
    add [frame_state_173d20], eax
    ret
