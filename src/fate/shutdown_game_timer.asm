; Remove the game clock callback and shut down the timer service.
BITS 32
ORG 0x34860

remove_timer_error equ 0x674
shutdown_timer_error equ 0x6a1
report_error equ 0x26a03
timer_init_return equ 0x3485f
timer_shutdown equ 0x60c17
timer_remove_callback equ 0x60fa7
timer_callback_handle equ 0x1714dc

shutdown_game_timer:
    mov eax, [timer_callback_handle]
    call timer_remove_callback
    test eax, eax
    jz short .branch_34878
    mov eax, remove_timer_error
    call report_error

.branch_34878:
    xor eax, eax
    call timer_shutdown
    test eax, eax
    jz short timer_init_return
    mov eax, shutdown_timer_error
    jmp near report_error
