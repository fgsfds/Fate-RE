; Configuration buffer helper.
BITS 32
ORG 0x35f2c

find_configuration_section equ 0x35882
strlen equ 0x60381

configuration_helper_35f2c:
    push esi
    push edi
    push ebp
    mov edi, [esp + 0x10]
    mov esi, [esp + 0x14]
    push esi
    push edi
    call find_configuration_section
    add esp, 0x8
    test eax, eax
    jz short .branch_35f4b

.branch_35f45:
    xor eax, eax
    pop ebp
    pop edi
    pop esi
    ret

.branch_35f4b:
    mov eax, esi
    mov edx, [edi + 0x84]
    mov ebx, [edi + 0x88]
    call strlen
    lea ecx, [eax + 0x6]
    mov eax, [edi + 0x88]
    mov ebp, [edi + 0x8c]
    add eax, ecx
    add edx, ebx
    cmp eax, ebp
    ja short .branch_35f45
    mov byte [edx], 0xd
    inc edx
    mov byte [edx], 0xa
    inc edx
    mov [edi + 0x98], edx
    mov byte [edx], 0x5b
    inc edx

.branch_35f87:
    mov bl, [esi]
    lea eax, [edx + 0x1]
    test bl, bl
    jz short .branch_35f97
    inc esi
    mov [edx], bl
    mov edx, eax
    jmp short .branch_35f87

.branch_35f97:
    mov byte [edx], 0x5d
    lea edx, [eax + 0x1]
    mov byte [eax], 0xd
    mov byte [edx], 0xa
    inc edx
    mov eax, [edi + 0x88]
    mov bh, [edi + 0x1]
    mov [edi + 0xa8], edx
    add eax, ecx
    mov [edi + 0x90], edx
    or bh, 0x80
    mov [edi + 0x88], eax
    mov [edi + 0x1], bh
    mov eax, 0x1
    pop ebp
    pop edi
    pop esi
    ret
