; Find configuration key.
BITS 32
ORG 0x35907


find_configuration_key:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov esi, [esp + 0x14]
    mov edi, [esp + 0x18]
    mov eax, [esi + 0x90]
    mov edx, [esi + 0x94]
    xor ebp, ebp

.branch_35923:
    mov bl, [eax]
    cmp bl, [edi]
    jnz near .branch_35994
    mov [esp], eax
    lea ebx, [edi + 0x1]
    inc edx
    inc eax

.branch_35935:
    mov cl, [eax]
    cmp cl, [ebx]
    jnz short .branch_35948
    cmp edx, [esi + 0x88]
    jnc short .branch_35948
    inc eax
    inc ebx
    inc edx
    jmp short .branch_35935

.branch_35948:
    cmp byte [ebx], 0x0
    jnz short .branch_35994

.branch_3594d:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0x3d
    jz short .branch_3595f
    cmp ebx, 0xd
    jz short .branch_3595f
    inc eax
    inc edx
    jmp short .branch_3594d

.branch_3595f:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0x3d
    jnz short .branch_35972
    inc eax
    inc edx
    mov [esi + 0xa0], eax
    jmp short .branch_3597c

.branch_35972:
    mov dword [esi + 0xa0], 0x0

.branch_3597c:
    mov ebx, [esp]
    mov dword [esi + 0xa4], 0x0
    mov ebp, 0x1
    mov [esi + 0x9c], ebx

.branch_35994:
    inc eax
    inc edx
    test ebp, ebp
    jnz short .branch_359af
    cmp edx, [esi + 0x88]
    jnc short .branch_359af
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0x5b
    jnz near .branch_35923

.branch_359af:
    mov eax, ebp
    add esp, 0x4
    pop ebp
    pop edi
    pop esi
    ret
