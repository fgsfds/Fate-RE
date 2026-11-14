; Initialize the timer service and register the game clock callback.
BITS 32
ORG 0x34811

timer_init_error equ 0x61c
timer_callback_error equ 0x647
timer_callback_offset equ 0x347f7 - 0x10000
report_error equ 0x26a03
timer_initialize equ 0x60b40
timer_register_callback equ 0x60c51
timer_callback_handle equ 0x1714dc
timer_error equ 0x171600

initialize_game_timer:
    push ebx
    push edx
    mov eax, 0xff00
    xor edx, edx
    call timer_initialize
    mov [timer_error], ax
    test ax, ax
    jz short .branch_34834
    mov eax, timer_init_error
    call report_error

.branch_34834:
    mov ebx, timer_callback_handle
    mov edx, timer_callback_offset
    mov eax, 0x78
    call timer_register_callback
    mov [timer_error], ax
    test ax, ax
    jz short .branch_3485d
    mov eax, timer_callback_error
    call report_error

.branch_3485d:
    pop edx
    pop ebx
    ret
