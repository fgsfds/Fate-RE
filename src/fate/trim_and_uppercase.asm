; Trim and uppercase.
BITS 32
ORG 0x383a0

strlen equ 0x60381
strupr equ 0x62efc

trim_and_uppercase:
    push ebx
    push ecx
    push edx
    mov ecx, eax
    call strlen
    test eax, eax
    jng short .branch_383ce
    lea edx, [eax-0x1]

.branch_383b1:
    lea eax, [ecx + edx]
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0x20
    jnz short .branch_383c7
    test edx, edx
    jng short .branch_383c7
    dec edx
    mov byte [eax], 0x0
    jmp short .branch_383b1

.branch_383c7:
    mov eax, ecx
    call strupr

.branch_383ce:
    pop edx
    pop ecx
    pop ebx
    ret
