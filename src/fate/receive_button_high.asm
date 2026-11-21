; Original retained gap: Client high-button OR/store uses EAX destination; compiler uses EBX destination, so original bytes remain.
BITS 32
ORG 0x326b5

board_state_5ac3f equ 0x5ac3f

receive_button_high:
    or eax, ebx
    mov [edx + board_state_5ac3f], ax
