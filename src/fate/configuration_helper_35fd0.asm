; Configuration buffer helper.
BITS 32
ORG 0x35fd0

find_configuration_key equ 0x35907
configuration_key_return equ 0x359b1
write_configuration_value equ 0x35c88
strlen equ 0x60381
memmove equ 0x62d49

configuration_helper_35fd0:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov edi, [esp + 0x18]
    mov esi, [esp + 0x1c]
    mov ebp, [esp + 0x20]
    push edi
    mov edx, [esp + 0x18]
    push edx
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short .branch_3600c
    push esi
    mov ebx, [esp + 0x18]
    push ebx
    call write_configuration_value
    mov eax, 0x1
    add esp, 0x8
    jmp near configuration_key_return

.branch_3600c:
    mov ecx, [esp + 0x14]
    mov eax, esi
    lea ebx, [ebp + 0x4]
    mov ecx, [ecx + 0x90]
    call strlen
    add ebx, eax
    mov eax, [esp + 0x14]
    mov eax, [eax + 0x88]
    mov [esp], ebx
    add eax, ebx
    mov ebx, [esp + 0x14]
    cmp eax, [ebx + 0x8c]
    jna short .branch_36044
    xor eax, eax
    jmp near configuration_key_return

.branch_36044:
    mov eax, [ebx + 0x84]
    mov edx, [ebx + 0x88]
    lea ebx, [eax + edx]
    mov eax, [esp]
    mov edx, ecx
    sub ebx, ecx
    add eax, ecx
    call memmove

.branch_36061:
    mov ah, [edi]
    test ah, ah
    jz short .branch_3606e
    inc edi
    dec ebp
    mov [ecx], ah
    inc ecx
    jmp short .branch_36061

.branch_3606e:
    dec ebp
    lea edi, [ecx + 0x1]
    cmp ebp, -1
    jz short .branch_3607e
    mov byte [ecx], 0x20
    mov ecx, edi
    jmp short .branch_3606e

.branch_3607e:
    mov byte [ecx], 0x3d
    lea ecx, [edi + 0x1]
    mov byte [edi], 0x20

.branch_36087:
    mov dl, [esi]
    lea edi, [ecx + 0x1]
    test dl, dl
    jz short .branch_36097
    inc esi
    mov [ecx], dl
    mov ecx, edi
    jmp short .branch_36087

.branch_36097:
    mov byte [ecx], 0xd
    mov ebx, [esp + 0x14]
    mov byte [edi], 0xa
    mov eax, [esp]
    mov ecx, [ebx + 0x88]
    mov dh, [ebx + 0x1]
    add ecx, eax
    or dh, 0x80
    mov [ebx + 0x88], ecx
    mov eax, 0x1
    mov [ebx + 0x1], dh
    jmp near configuration_key_return
