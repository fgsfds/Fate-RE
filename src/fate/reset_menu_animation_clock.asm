; Reset menu animation clock.
BITS 32
ORG 0x390bc

frame_state_13150 equ 0x13150

reset_menu_animation_clock:
    push edx
    xor edx, edx
    mov [frame_state_13150], edx
    pop edx
    ret
