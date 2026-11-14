; Configuration buffer helper.
BITS 32
ORG 0x360c5

find_configuration_key equ 0x35907
replace_configuration_value equ 0x35b8b
strlen equ 0x60381
ltoa equ 0x62d2e
memmove equ 0x62d49

configuration_helper_360c5:
    push esi
    push edi
    push ebp
    sub esp, 0x24
    mov ebp, [esp + 0x34]
    mov esi, [esp + 0x38]
    mov edi, [esp + 0x40]
    push esi
    push ebp
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short .branch_360fd
    mov ecx, [esp + 0x3c]
    push ecx
    push ebp
    call replace_configuration_value
    mov eax, 0x1
    add esp, 0x8
    jmp near .branch_361d3

.branch_360fd:
    cmp dword [esp + 0x44], 0x10
    jnz short .branch_3611a
    mov ah, 0x30
    mov dl, 0x78
    mov ebx, 0x10
    mov [esp], ah
    mov [esp + 0x1], dl
    lea edx, [esp + 0x2]
    jmp short .branch_36121

.branch_3611a:
    mov ebx, 0xa
    mov edx, esp

.branch_36121:
    mov eax, [esp + 0x3c]
    call ltoa
    mov eax, esp
    lea edx, [edi + 0x4]
    mov ecx, [ebp + 0x90]
    call strlen
    add edx, eax
    mov eax, [ebp + 0x88]
    mov [esp + 0x20], edx
    add eax, edx
    cmp eax, [ebp + 0x8c]
    jna short .branch_36157
    xor eax, eax
    jmp near .branch_361d3

.branch_36157:
    mov eax, [ebp + 0x84]
    mov ebx, [ebp + 0x88]
    mov edx, ecx
    add ebx, eax
    mov eax, [esp + 0x20]
    sub ebx, ecx
    add eax, ecx
    call memmove

.branch_36174:
    mov dh, [esi]
    test dh, dh
    jz short .branch_36181
    inc esi
    dec edi
    mov [ecx], dh
    inc ecx
    jmp short .branch_36174

.branch_36181:
    dec edi
    lea esi, [ecx + 0x1]
    cmp edi, -1
    jz short .branch_36191
    mov byte [ecx], 0x20
    mov ecx, esi
    jmp short .branch_36181

.branch_36191:
    mov byte [ecx], 0x3d
    xor eax, eax
    lea ecx, [esi + 0x1]
    mov byte [esi], 0x20

.branch_3619c:
    mov bl, [esp + eax]
    lea esi, [ecx + 0x1]
    test bl, bl
    jz short .branch_361ad
    inc eax
    mov [ecx], bl
    mov ecx, esi
    jmp short .branch_3619c

.branch_361ad:
    mov byte [ecx], 0xd
    mov byte [esi], 0xa
    mov eax, [esp + 0x20]
    mov esi, [ebp + 0x88]
    mov bh, [ebp + 0x1]
    add esi, eax
    or bh, 0x80
    mov [ebp + 0x88], esi
    mov eax, 0x1
    mov [ebp + 0x1], bh

.branch_361d3:
    add esp, 0x24
    pop ebp
    pop edi
    pop esi
    ret
