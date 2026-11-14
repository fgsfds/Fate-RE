; Print runtime message.
BITS 32
ORG 0x40bb4

frame_state_1426e equ 0x1426e
stream_format equ 0x6317c

print_runtime_message:
    push ebx
    push edx
    sub esp, 0x4
    lea ebx, [esp + 0x14]
    mov eax, frame_state_1426e
    mov edx, [esp + 0x10]
    mov [esp], ebx
    mov ebx, esp
    call stream_format
    add esp, 0x4
    pop edx
    pop ebx
    ret
