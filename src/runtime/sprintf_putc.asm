; Append one output character to the formatting engine's buffer state.
BITS 32
ORG 0x601e0

buffer_cursor equ 0
character_count equ 0x10

sprintf_putc:
    push ebx
    push ecx
    mov bl, dl
    mov edx, [eax + buffer_cursor]
    lea ecx, [edx + 1]
    mov [eax + buffer_cursor], ecx
    mov [edx], bl
    inc dword [eax + character_count]
    pop ecx
    pop ebx
    ret
