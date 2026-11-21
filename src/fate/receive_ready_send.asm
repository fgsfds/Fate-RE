; Original retained gap: Original send argument setup order and registers, including EAX from CX.
BITS 32
ORG 0x3273c

packet equ 0x1d92c

receive_ready_send:
    mov ebx, 0x2
    mov edx, packet
    movsx eax, cx
