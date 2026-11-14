; Find configuration section.
BITS 32
ORG 0x35882


find_configuration_section:
    push esi
    push edi
    push ebp
    mov esi, [esp + 0x10]
    mov eax, [esi + 0x84]
    xor edi, edi
    xor ebx, ebx

.branch_35893:
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0x5b
    jnz short .branch_358f3
    mov edx, [esp + 0x14]
    mov ebp, eax
    inc eax

.branch_358a3:
    mov cl, [eax]
    cmp cl, [edx]
    jnz short .branch_358b6
    cmp ebx, [esi + 0x88]
    jnc short .branch_358b6
    inc edx
    inc eax
    inc ebx
    jmp short .branch_358a3

.branch_358b6:
    xor ecx, ecx
    mov cl, [eax]
    cmp ecx, 0x5d
    jnz short .branch_358f3
    cmp byte [edx], 0x0
    jnz short .branch_358f3
    mov edi, 0x1

.branch_358c9:
    xor ecx, ecx
    mov cl, [eax]
    lea edx, [eax + 0x1]
    cmp ecx, 0xa
    jz short .branch_358d9
    mov eax, edx
    jmp short .branch_358c9

.branch_358d9:
    mov [esi + 0xa8], edx
    mov [esi + 0x90], edx
    mov [esi + 0x94], ebx
    mov eax, edx
    mov [esi + 0x98], ebp

.branch_358f3:
    inc eax
    inc ebx
    test edi, edi
    jnz short .branch_35901
    cmp ebx, [esi + 0x88]
    jc short .branch_35893

.branch_35901:
    mov eax, edi
    pop ebp
    pop edi
    pop esi
    ret
