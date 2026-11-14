; Read configuration boolean.
BITS 32
ORG 0x35d4c

frame_state_955 equ 0x955
find_configuration_key equ 0x35907
copy_configuration_value equ 0x35a66
stricmp equ 0x62d95

read_configuration_boolean:
    sub esp, 0x20
    mov edx, [esp + 0x28]
    push edx
    mov ebx, [esp + 0x28]
    push ebx
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short .branch_35d98
    push strict byte 0x20
    lea eax, [esp + 0x4]
    push eax
    mov ecx, [esp + 0x2c]
    push ecx
    call copy_configuration_value
    add esp, 0xc
    test eax, eax
    jz short .branch_35d98
    mov edx, frame_state_955
    mov eax, esp
    call stricmp
    test eax, eax
    jnz short .branch_35d96
    mov eax, 0x1
    add esp, 0x20
    ret

.branch_35d96:
    xor eax, eax

.branch_35d98:
    add esp, 0x20
    ret
