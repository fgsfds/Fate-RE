; Parse hex digits.
BITS 32
ORG 0x36211

frame_state_12cf0 equ 0x12cf0
toupper equ 0x62dce

parse_hex_digits:
    push ebx
    push ecx
    push edx
    mov cl, al
    xor edx, edx
    jmp short .branch_36238

.branch_3621a:
    mov eax, [frame_state_12cf0]
    xor ebx, ebx
    mov bl, [edx + eax]
    xor eax, eax
    mov al, cl
    call toupper
    cmp ebx, eax
    jnz short .branch_36237
    mov eax, edx
    pop edx
    pop ecx
    pop ebx
    ret

.branch_36237:
    inc edx

.branch_36238:
    cmp edx, 0x10
    jc short .branch_3621a
    mov eax, 0xffffffff
    pop edx
    pop ecx
    pop ebx
    ret
