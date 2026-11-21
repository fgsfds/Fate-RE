; Original retained gap: Client low-button loads and CL clearing; supplies exact ECX/SI values for the following merge.
BITS 32
ORG 0x32671

board_state_5ac3f equ 0x5ac3f
packet equ 0x1d92c

receive_button_low:
    mov cx, [ebx + board_state_5ac3f]
    movzx si, byte [eax + packet]
    xor cl, cl
