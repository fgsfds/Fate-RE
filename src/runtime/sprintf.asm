; Adapt stack arguments to the register-call formatting engine.
BITS 32
ORG 0x601f3

format_engine equ 0x635bb
sprintf_putc_offset equ 0x601e0 - 0x10000

sprintf_:
    push ebx
    push ecx
    push edx
    sub esp, 4
    lea eax, [esp + 0x1c]
    mov edx, [esp + 0x18]
    mov ebx, esp
    mov ecx, sprintf_putc_offset
    mov [esp], eax
    mov eax, [esp + 0x14]
    call format_engine
    mov edx, [esp + 0x14]
    mov byte [edx + eax], 0
    add esp, 4
    pop edx
    pop ecx
    pop ebx
    ret
