; Configuration buffer helper.
BITS 32
ORG 0x35ebd

find_configuration_section equ 0x35882
memmove equ 0x62d49

configuration_helper_35ebd:
    push esi
    push edi
    mov edi, [esp + 0xc]
    mov edx, [esp + 0x10]
    push edx
    push edi
    call find_configuration_section
    add esp, 0x8
    test eax, eax
    jz short .branch_35f29
    mov ebx, [edi + 0x84]
    mov ecx, [edi + 0x88]
    mov esi, [edi + 0x98]
    add ebx, ecx
    mov ecx, 0x1

.branch_35eee:
    lea eax, [esi + ecx]
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0x5b
    jz short .branch_35f01
    cmp eax, ebx
    jnc short .branch_35f01
    inc ecx
    jmp short .branch_35eee

.branch_35f01:
    lea edx, [esi + ecx]
    mov eax, esi
    sub ebx, edx
    call memmove
    mov esi, [edi + 0x88]
    mov ah, [edi + 0x1]
    sub esi, ecx
    or ah, 0x80
    mov [edi + 0x88], esi
    mov [edi + 0x1], ah
    mov eax, 0x1

.branch_35f29:
    pop edi
    pop esi
    ret
