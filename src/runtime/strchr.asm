; Search a NUL-terminated string, including its terminator.
BITS 32
ORG 0x6e8f8


strchr_:
    push ebx
    push ecx
    mov ebx, edx

scan_character:
    xor edx, edx
    mov dl, byte [eax]
    cmp edx, ebx
    je short return_character
    mov edx, eax
    mov cl, byte [edx]
    inc eax
    test cl, cl
    jne short scan_character
    xor eax, eax

return_character:
    pop ecx
    pop ebx
    ret
