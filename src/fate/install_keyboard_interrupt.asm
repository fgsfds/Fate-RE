; Clear keyboard state and install the game keyboard interrupt.
BITS 32
ORG 0x2f1fe

keyboard_interrupt_offset equ 0x2f27e - 0x10000
dos_getvect equ 0x603a8
disable_interrupts equ 0x603dc
dos_setvect equ 0x603de
enable_interrupts equ 0x60409
key_state_before_first equ 0x6793b
previous_keyboard_vector_offset equ 0x7abb4
previous_keyboard_vector_selector equ 0x7abb8
key_fifo_write equ 0x7f878
key_fifo_read equ 0x7f87b

install_keyboard_interrupt:
    push ebx
    push ecx
    push edx
    xor ah, ah
    mov [key_fifo_read], ah
    mov [key_fifo_write], ah
    xor eax, eax
    jmp short .branch_2f21c

.branch_2f213:
    inc eax
    xor dh, dh
    mov [eax + key_state_before_first], dh

.branch_2f21c:
    cmp eax, strict dword 0x100
    jl short .branch_2f213
    mov eax, 0x9
    mov ebx, keyboard_interrupt_offset
    call dos_getvect
    mov ecx, cs
    mov [previous_keyboard_vector_selector], dx
    mov [previous_keyboard_vector_offset], eax
    call disable_interrupts
    mov eax, 0x9
    call dos_setvect
    call enable_interrupts
    pop edx
    pop ecx
    pop ebx
    ret
