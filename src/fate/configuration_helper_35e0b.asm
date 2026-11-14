; Configuration buffer helper.
BITS 32
ORG 0x35e0b

frame_state_959 equ 0x959
find_configuration_key equ 0x35907
write_configuration_value equ 0x35c88
configuration_helper_35e43 equ 0x35e43
branch_35e59 equ 0x35e59
branch_35e5e equ 0x35e5e

configuration_helper_35e0b:
    push esi
    push edi
    mov edx, [esp + 0x10]
    push edx
    mov ebx, [esp + 0x10]
    push ebx
    call find_configuration_key
    add esp, 0x8
    test eax, eax
    jz short branch_35e5e
    cmp dword [esp + 0x14], 0x0
    jz short configuration_helper_35e43
    push strict dword frame_state_959
    mov edi, [esp + 0x10]
    push edi
    call write_configuration_value
    add esp, 0x8
    test eax, eax
    jnz short branch_35e59
    pop edi
    pop esi
    ret
