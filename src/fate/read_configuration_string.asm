; Read configuration string.
BITS 32
ORG 0x35dd0

find_configuration_key equ 0x35907
copy_configuration_value equ 0x35a66

read_configuration_string:
    push esi
    push edi
    mov edx, [esp + 0x10]
    push edx
    mov ebx, [esp + 0x10]
    push ebx
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short .branch_35e08
    mov ecx, [esp + 0x18]
    push ecx
    mov esi, [esp + 0x18]
    push esi
    mov edi, [esp + 0x14]
    push edi
    call copy_configuration_value
    add esp, 0xc
    test eax, eax
    jz short .branch_35e08
    mov eax, 0x1

.branch_35e08:
    pop edi
    pop esi
    ret
