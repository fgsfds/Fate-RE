; Write configuration value.
BITS 32
ORG 0x35c88

strlen equ 0x60381
memmove equ 0x62d49

write_configuration_value:
    push esi
    push edi
    push ebp
    mov edi, [esp + 0x10]
    mov ecx, [esp + 0x14]
    mov eax, [edi + 0xa0]
    test eax, eax
    jz near .branch_35d48
    xor edx, edx

.branch_35ca3:
    movzx esi, byte [eax]
    cmp esi, 0x20
    jnz short .branch_35cae
    inc eax
    jmp short .branch_35ca3

.branch_35cae:
    mov esi, eax

.branch_35cb0:
    xor ebx, ebx
    mov bl, [eax]
    inc eax
    cmp ebx, 0xd
    jz short .branch_35cbd
    inc edx
    jmp short .branch_35cb0

.branch_35cbd:
    mov eax, ecx
    call strlen
    cmp eax, edx
    jnc short .branch_35cee
    mov ebx, [edi + 0x84]
    add ebx, [edi + 0x88]
    mov ebp, edx
    sub ebp, eax
    sub ebx, esi
    lea edx, [esi + ebp]
    sub ebx, ebp
    mov eax, esi
    call memmove
    sub [edi + 0x88], ebp
    jmp short .branch_35d2e

.branch_35cee:
    jna short .branch_35d2e
    mov ebp, eax
    mov eax, [edi + 0x88]
    sub ebp, edx
    mov edx, [edi + 0x8c]
    add eax, ebp
    cmp eax, edx
    jna short .branch_35d0c
    xor eax, eax
    pop ebp
    pop edi
    pop esi
    ret

.branch_35d0c:
    mov eax, [edi + 0x84]
    mov ebx, [edi + 0x88]
    add ebx, eax
    sub ebx, esi
    lea eax, [esi + ebp]
    add ebx, ebp
    mov edx, esi
    call memmove
    add [edi + 0x88], ebp

.branch_35d2e:
    mov ah, [ecx]
    test ah, ah
    jz short .branch_35d3a
    inc ecx
    mov [esi], ah
    inc esi
    jmp short .branch_35d2e

.branch_35d3a:
    mov dl, [edi + 0x1]
    or dl, 0x80
    mov eax, 0x1
    mov [edi + 0x1], dl

.branch_35d48:
    pop ebp
    pop edi
    pop esi
    ret
