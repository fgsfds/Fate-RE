; Close configuration.
BITS 32
ORG 0x35824

open equ 0x61368
free equ 0x6170a
close equ 0x6219a
write equ 0x62a97

close_configuration:
    push esi
    mov ecx, [esp + 0x8]
    test byte [ecx + 0x1], 0x80
    jz short .branch_35870
    push strict byte 0x0
    push strict dword 0x262
    lea eax, [ecx + 0x4]
    push eax
    call open
    mov esi, eax
    add esp, 0xc
    cmp eax, -1
    jnz short .branch_35858
    mov eax, [ecx + 0x84]
    call free
    xor eax, eax
    pop esi
    ret

.branch_35858:
    mov ebx, [ecx + 0x88]
    mov edx, [ecx + 0x84]
    call write
    mov eax, esi
    call close

.branch_35870:
    mov eax, [ecx + 0x84]
    call free
    mov eax, 0x1
    pop esi
    ret
