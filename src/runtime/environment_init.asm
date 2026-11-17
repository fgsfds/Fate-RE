; Initialize the Watcom environment vector from the DOS environment segment.
BITS 32
ORG 0x6e6b9

restore_environment_registers equ 0x6e784
environment_vector equ 0x173d8
environment_selector equ 0x144a1

initialize_environment:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es
    push fs
    cmp dword [environment_vector], 0
    jne near restore_environment_registers
    mov fs, word [environment_selector]
