; Graphics runtime entry points.
BITS 32
ORG 0x7000a

graphics_error equ 0x16c66
graphics_active equ 0x16c65
return_graphics_active equ 0x70001
hide_graphics_cursor equ 0x6febd
cursor_restore_enabled equ 0x16c74
show_graphics_cursor equ 0x6fe8f

check_graphics_and_hide_cursor:
    mov word [graphics_error], 0
    cmp byte [graphics_active], 0
    jne short .hide
    mov word [graphics_error], 0xfffd
    jmp short return_graphics_active
.hide:
    call hide_graphics_cursor
    jmp short return_graphics_active

restore_cursor_if_enabled:
    cmp word [cursor_restore_enabled], 1
    je near show_graphics_cursor
    ret
