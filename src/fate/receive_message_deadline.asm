; Original retained gap: Original message deadline arithmetic/register schedule; supplies final message_deadline before poll edge.
BITS 32
ORG 0x326e9

board_state_7f874 equ 0x7f874
totalclock equ 0x287e88
weapon_state_7709c equ 0x7709c

receive_message_deadline:
    xor eax, eax
    mov al, [board_state_7f874]
    shl eax, byte 0x4
    mov edx, [totalclock]
    add edx, strict dword 0x168
    add edx, eax
    mov [weapon_state_7709c], edx
