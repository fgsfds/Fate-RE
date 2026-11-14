; Copy configuration value.
BITS 32
ORG 0x35a66


copy_configuration_value:
    push esi
    push edi
    push ebp
    mov ebp, [esp + 0x10]
    mov edi, [esp + 0x14]
    mov ecx, [esp + 0x18]
    mov edx, [ebp + 0xa4]
    test edx, edx
    jz short .branch_35a83
    mov eax, edx
    jmp short .branch_35a89

.branch_35a83:
    mov eax, [ebp + 0xa0]

.branch_35a89:
    test eax, eax
    jnz short .branch_35a94
    xor ebx, ebx
    jmp near .branch_35af3

.branch_35a94:
    xor edx, edx

.branch_35a96:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0x20
    jnz short .branch_35aa2
    inc eax
    jmp short .branch_35a96

.branch_35aa2:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0xd
    jz short .branch_35ac4
    cmp ebx, 0x2c
    jz short .branch_35ac4
    lea ebx, [ecx-0x1]
    cmp edx, ebx
    jnc short .branch_35ac4
    mov ebx, eax
    mov esi, edx
    inc eax
    mov bl, [ebx]
    inc edx
    mov [edi + esi], bl
    jmp short .branch_35aa2

.branch_35ac4:
    dec ecx
    mov byte [edx + edi], 0x0
    cmp edx, ecx
    jnz short .branch_35ade

.branch_35acd:
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0xd
    jz short .branch_35ade
    cmp edx, 0x2c
    jz short .branch_35ade
    inc eax
    jmp short .branch_35acd

.branch_35ade:
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0x2c
    jnz short .branch_35ae8
    inc eax

.branch_35ae8:
    mov [ebp + 0xa4], eax
    mov ebx, 0x1

.branch_35af3:
    mov eax, ebx
    pop ebp
    pop edi
    pop esi
    ret
