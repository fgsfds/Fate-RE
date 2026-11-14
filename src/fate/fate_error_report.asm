; Shut down the game, print the supplied error and exit.
BITS 32
ORG 0x26a03
shutdown_game equ 0x3b34d
print_message equ 0x40bb4
runtime_exit equ 0x60353
newline_message equ 0x40c

report_error:
    push edx
    mov edx, eax
    call shutdown_game
    push edx
    call print_message
    add esp, 4
    push strict dword newline_message
    call print_message
    add esp, 4
    xor eax, eax
    call runtime_exit
    pop edx
    ret
