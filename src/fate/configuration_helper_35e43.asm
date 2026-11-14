; Configuration buffer helper.
BITS 32
ORG 0x35e43

frame_state_95d equ 0x95d
write_configuration_value equ 0x35c88

configuration_helper_35e43:
    push strict dword frame_state_95d
    mov esi, [esp + 0x10]
    push esi
    call write_configuration_value
    add esp, 0x8
    test eax, eax
    jz short .branch_35e5e
    mov eax, 0x1

.branch_35e5e:
    pop edi
    pop esi
    ret
