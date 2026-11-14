; Query DOS device information for a character descriptor.
BITS 32
ORG 0x656f3


isatty_:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    mov al, 0
    mov ah, 0x44
    int 0x21
    rcl edx, 1
    ror edx, 1
    test dl, 0x80
    setne al
    and eax, 0xff
    pop edx
    pop ecx
    pop ebx
    ret
