; CODE-base trap and BIOS print-screen helper.
BITS 32

code_base_trap:
    int3
    .halt:
    jmp short code_base_trap
    times 13 nop

bios_print_screen:
    int 0x5
    ret
