; Save and restore the x87 state around a DOS child launch.
BITS 32
ORG 0x645f7

configure_fpu equ 0x6ad8e
fpu_present equ 0x141a9
save_spawn_state equ 0x17408
restore_spawn_state equ 0x1740c
fpu_control_word equ 0x17490

save_fpu_state:
    wait
    fnsave [eax]
    wait
    ret

restore_fpu_state:
    frstor [eax]
    wait
    ret

init_fpu_callbacks:
    push ebx
    push edx
    cmp byte [fpu_present], 0
    je short apply_control_word
    mov edx, save_fpu_state - 0x10000
    mov ebx, restore_fpu_state - 0x10000
    mov dword [save_spawn_state], edx
    mov dword [restore_spawn_state], ebx

apply_control_word:
    xor eax, eax
    mov ax, word [fpu_control_word]
    call configure_fpu
    pop edx
    pop ebx
    ret

check_fpu_callbacks:
    cmp byte [fpu_present], 0
    jne short init_fpu_callbacks
    ret
