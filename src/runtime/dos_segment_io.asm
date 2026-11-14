; DOS descriptor I/O using the caller's buffer selector.
BITS 32
ORG 0x6e666

dos_status equ 0x6e78e
write_console_and_exit equ 0x60199

read_driver_image:
    push strict dword 0x3f00

transfer:
    push ds
    mov ds, cx
    mov ecx, edx
    mov edx, ebx
    mov ebx, eax
    mov eax, [esp + 4]
    int 0x21
    pop ds
    push ds
    jc short translate_status
    mov ebx, [esp + 0xc]
    mov [ebx], eax

translate_status:
    call dos_status
    pop ds
    add esp, 4
    ret 4

write_segment_buffer:
    push strict dword 0x4000
    jmp short transfer

console_exit_thunk:
    jmp near write_console_and_exit
