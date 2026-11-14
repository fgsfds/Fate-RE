; Parse configuration integer.
BITS 32
ORG 0x359b8

parse_hexadecimal equ 0x361da
atoi equ 0x62c68

parse_configuration_integer:
    sub esp, 0x20
    mov ecx, [esp + 0x24]
    mov edx, [ecx + 0xa4]
    test edx, edx
    jz short .branch_359cd
    mov eax, edx
    jmp short .branch_359d3

.branch_359cd:
    mov eax, [ecx + 0xa0]

.branch_359d3:
    test eax, eax
    jnz short .branch_359de

.branch_359d7:
    xor ebx, ebx
    jmp near .branch_35a60

.branch_359de:
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0x20
    jnz short .branch_359ea
    inc eax
    jmp short .branch_359de

.branch_359ea:
    cmp edx, 0xd
    jz short .branch_359d7
    xor edx, edx

.branch_359f1:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0xd
    jz short .branch_35a0c
    cmp ebx, 0x2c
    jz short .branch_35a0c
    cmp ebx, 0x20
    jz short .branch_35a0c
    inc edx
    inc eax
    mov [esp + edx-0x1], bl
    jmp short .branch_359f1

.branch_35a0c:
    xor bl, bl
    mov [esp + edx], bl
    test edx, edx
    jz short .branch_359d7

.branch_35a15:
    xor ebx, ebx
    mov bl, [eax]
    lea edx, [eax + 0x1]
    cmp ebx, 0x20
    jnz short .branch_35a25
    mov eax, edx
    jmp short .branch_35a15

.branch_35a25:
    cmp ebx, 0x2c
    jnz short .branch_35a32
    mov [ecx + 0xa4], edx
    jmp short .branch_35a38

.branch_35a32:
    mov [ecx + 0xa4], eax

.branch_35a38:
    xor eax, eax
    mov al, [esp + 0x1]
    cmp eax, 0x78
    jnz short .branch_35a4e
    lea eax, [esp + 0x2]
    call parse_hexadecimal
    jmp short .branch_35a55

.branch_35a4e:
    mov eax, esp
    call atoi

.branch_35a55:
    mov edx, [esp + 0x28]
    mov ebx, 0x1
    mov [edx], eax

.branch_35a60:
    mov eax, ebx
    add esp, 0x20
    ret
