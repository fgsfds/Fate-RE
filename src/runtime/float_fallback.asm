; CRT common initialization and fallback for absent floating-point support.
BITS 32
ORG 0x67474

common_init_value equ 0x17498
float_support_message equ 0x1e8c
fatal_runtime_error equ 0x6e69c

common_init:
    mov dword [common_init_value], 0x8000
    ret

float_support_missing:
    push edx
    mov eax, float_support_message
    mov edx, 1
    call fatal_runtime_error
    pop edx
    ret
