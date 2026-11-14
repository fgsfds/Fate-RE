; Reset the graphics error status and report whether graphics is active.
BITS 32
ORG 0x6ffe6

graphics_active equ 0x16c65
graphics_error equ 0x16c66

graphics_available:
    mov word [graphics_error], 0
    cmp byte [graphics_active], 0
    jne short .return_active
    mov word [graphics_error], -3
.return_active:
    movzx ax, byte [graphics_active]
    ret
