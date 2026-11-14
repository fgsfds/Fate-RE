; Write crusher state.
BITS 32
ORG 0x4032e

fwrite equ 0x60944
crusher_state equ 0x174640

write_crusher_state:
    push ebx
    push ecx
    push edx
    test eax, eax
    jz short .branch_40350
    mov ebx, 0x1
    mov edx, 0x64c8
    mov ecx, eax
    mov eax, crusher_state
    call fwrite
    mov eax, 0x1

.branch_40350:
    pop edx
    pop ecx
    pop ebx
    ret
