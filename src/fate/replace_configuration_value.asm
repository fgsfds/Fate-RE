; Replace configuration value.
BITS 32
ORG 0x35b8b

strlen equ 0x60381
ltoa equ 0x62d2e
memmove equ 0x62d49

replace_configuration_value:
    push esi
    push edi
    push ebp
    sub esp, 0x20
    mov edi, [esp + 0x30]
    mov ebp, [esp + 0x34]
    mov edx, [edi + 0xa0]
    test edx, edx
    jnz short .branch_35baa

.branch_35ba3:
    xor eax, eax
    jmp near .branch_35c81

.branch_35baa:
    mov eax, edx

.branch_35bac:
    xor ecx, ecx
    mov cl, [eax]
    cmp ecx, 0x20
    jnz short .branch_35bb8
    inc eax
    jmp short .branch_35bac

.branch_35bb8:
    mov ecx, eax
    xor esi, esi

.branch_35bbc:
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0xd
    jz short .branch_35bcd
    inc esi
    inc eax
    mov [esp + esi-0x1], dl
    jmp short .branch_35bbc

.branch_35bcd:
    xor ah, ah
    mov [esp + esi], ah
    xor eax, eax
    mov al, [esp + 0x1]
    cmp eax, 0x78
    jnz short .branch_35be8
    mov ebx, 0x10
    lea edx, [esp + 0x2]
    jmp short .branch_35bef

.branch_35be8:
    mov ebx, 0xa
    mov edx, esp

.branch_35bef:
    mov eax, ebp
    call ltoa
    mov eax, esp
    call strlen
    cmp eax, esi
    jnc short .branch_35c27
    mov edx, [edi + 0x84]
    mov ebx, [edi + 0x88]
    add ebx, edx
    sub esi, eax
    sub ebx, ecx
    lea edx, [ecx + esi]
    sub ebx, esi
    mov eax, ecx
    call memmove
    sub [edi + 0x88], esi
    jmp short .branch_35c64

.branch_35c27:
    jna short .branch_35c64
    sub eax, esi
    mov esi, eax
    mov eax, [edi + 0x88]
    mov ebx, [edi + 0x8c]
    add eax, esi
    cmp eax, ebx
    ja near .branch_35ba3
    mov eax, [edi + 0x84]
    add eax, [edi + 0x88]
    sub eax, ecx
    lea ebx, [eax + esi]
    lea eax, [ecx + esi]
    mov edx, ecx
    call memmove
    add [edi + 0x88], esi

.branch_35c64:
    xor eax, eax

.branch_35c66:
    mov dl, [esp + eax]
    test dl, dl
    jz short .branch_35c73
    inc eax
    mov [ecx], dl
    inc ecx
    jmp short .branch_35c66

.branch_35c73:
    mov dh, [edi + 0x1]
    or dh, 0x80
    mov eax, 0x1
    mov [edi + 0x1], dh

.branch_35c81:
    add esp, 0x20
    pop ebp
    pop edi
    pop esi
    ret
