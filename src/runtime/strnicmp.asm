; Compare at most EBX bytes, folding ASCII uppercase in each string.
BITS 32
ORG 0x6751a

strnicmp_:
    push ecx
    sub esp, 4
.check_length:
    test ebx, ebx
    jne short .load_characters
.equal:
    xor eax, eax
    add esp, 4
    pop ecx
    ret
.load_characters:
    mov ch, [edx]
    mov cl, [eax]
    mov [esp], ch
    cmp cl, 'A'
    jb short .fold_second
    cmp cl, 'Z'
    ja short .fold_second
    add cl, 0x20
.fold_second:
    mov ch, [esp]
    cmp ch, 'A'
    jb short .compare
    cmp ch, 'Z'
    ja short .compare
    add ch, 0x20
    mov [esp], ch
.compare:
    mov ch, [esp]
    cmp cl, ch
    je short .check_terminator
    xor edx, edx
    xor eax, eax
    mov dl, cl
    mov al, ch
    sub edx, eax
    mov eax, edx
    add esp, 4
    pop ecx
    ret
.check_terminator:
    test ch, ch
    je short .equal
    inc eax
    inc edx
    dec ebx
    jmp short .check_length
