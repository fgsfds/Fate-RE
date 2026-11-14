; Read configuration integer.
BITS 32
ORG 0x35d9c

find_configuration_key equ 0x35907
parse_configuration_integer equ 0x359b8

read_configuration_integer:
    push esi
    mov edx, [esp + 0xc]
    push edx
    mov ebx, [esp + 0xc]
    push ebx
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short .branch_35dce
    mov ecx, [esp + 0x10]
    push ecx
    mov esi, [esp + 0xc]
    push esi
    call parse_configuration_integer
    add esp, 0x8
    test eax, eax
    jz short .branch_35dce
    mov eax, 0x1

.branch_35dce:
    pop esi
    ret
