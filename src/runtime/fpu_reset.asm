; Reset the emulator's control, status, tags and continuation.
BITS 32
ORG 0x69043

decode_next equ 0x67e50

reset_emulator:
    mov word ds:[byte ebp], 0x033f
    mov word ds:[ebp + 4], 0
    mov word ds:[ebp + 8], 0xffff
    lea edx, [decode_next - 0x10000]
    mov dword ds:[ebp + 0x76], edx
    db 0x2b, 0xff ; SUB EDI, EDI uses the register-destination opcode.
    jmp near decode_next
