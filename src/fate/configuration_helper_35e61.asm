; Configuration buffer helper.
BITS 32
ORG 0x35e61

find_configuration_key equ 0x35907
memmove equ 0x62d49

configuration_helper_35e61:
    push esi
    push edi
    push ebp
    mov edi, [esp + 0x10]
    mov edx, [esp + 0x14]
    push edx
    push edi
    xor esi, esi
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short .branch_35eb9
    mov ecx, [edi + 0x9c]

.branch_35e82:
    mov al, [ecx + esi]
    and eax, strict dword 0xff
    inc esi
    cmp eax, 0xa
    jnz short .branch_35e82
    mov ebx, [edi + 0x84]
    mov ebp, [edi + 0x88]
    lea edx, [ecx + esi]
    add ebx, ebp
    mov eax, ecx
    sub ebx, edx
    call memmove
    sub [edi + 0x88], esi
    or byte [edi + 0x1], 0x80
    mov eax, 0x1

.branch_35eb9:
    pop ebp
    pop edi
    pop esi
    ret
