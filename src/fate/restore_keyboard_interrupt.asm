; Restore the previous DOS keyboard vector and clear BIOS keyboard flags.
BITS 32
ORG 0x2f258

dos_setvect equ 0x603de
previous_keyboard_vector_offset equ 0x7abb4
previous_keyboard_vector_selector equ 0x7abb8

restore_keyboard_interrupt:
    push ebx
    push ecx
    mov eax, 0x9
    mov cx, [previous_keyboard_vector_selector]
    mov ebx, [previous_keyboard_vector_offset]
    call dos_setvect
    mov eax, 0x417
    and word [eax], 0xfcf0
    pop ecx
    pop ebx
    ret
