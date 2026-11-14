; Convert a 32-bit integer to a NUL-terminated string in the requested radix.
BITS 32
ORG 0x67491

format_digits:
    db "0123456789abcdefghijklmnopqrstuvwxyz", 0

format_unsigned:
    push ecx
    push esi
    push ebp
    sub esp, 0x28
    push edx
    mov ebp, ebx
    mov esi, edx
    xor dl, dl
    lea ecx, [esp + 5]
    mov byte [esp + 4], dl
.divide:
    lea ebx, [esp + 0x28]
    mov dword [esp + 0x28], ebp
    xor edx, edx
    div dword [ebx]
    mov [ebx], edx
    mov edx, [esp + 0x28]
    mov dl, cs:[edx + format_digits - 0x10000]
    mov [ecx], dl
    inc ecx
    test eax, eax
    jne short .divide
.reverse_digits:
    dec ecx
    mov al, [ecx]
    mov [esi], al
    inc esi
    test al, al
    jne short .reverse_digits
    mov eax, [esp]
    add esp, 0x2c
    pop ebp
    pop esi
    pop ecx
    ret

format_integer:
    push ecx
    mov ecx, edx
    cmp ebx, 10
    jne short .write_magnitude
    test eax, eax
    jge short .write_magnitude
    neg eax
    mov byte [edx], '-'
    inc edx
.write_magnitude:
    call format_unsigned
    mov eax, ecx
    pop ecx
    ret
