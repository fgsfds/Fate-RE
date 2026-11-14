; Return zero on success or pass the DOS error to the shared translator.
BITS 32
ORG 0x65711

translate_exec_result equ 0x65718

dosret0:
    test edx, edx
    jne short translate_exec_result
    xor eax, eax
    ret
