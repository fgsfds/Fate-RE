; Validate key binding.
BITS 32
ORG 0x3a3b0

frame_state_13154 equ 0x13154
frame_state_1741f4 equ 0x1741f4

validate_key_binding:
    push ebx
    push ecx
    mov ebx, eax
    mov ecx, edx
    cmp eax, 0x1
    jnz short .branch_3a3c5

.branch_3a3bb:
    mov ebx, 0xffffffff
    mov eax, ebx
    pop ecx
    pop ebx
    ret

.branch_3a3c5:
    mov eax, [nosplit eax*4 + frame_state_13154]
    cmp byte [eax], 0x0
    jz short .branch_3a3bb
    xor eax, eax

.branch_3a3d3:
    mov edx, [nosplit eax*4 + frame_state_1741f4]
    cmp ebx, [edx + 0x7]
    jnz short .branch_3a3ed
    cmp eax, ecx
    jz short .branch_3a3ed
    mov ebx, 0xfffffffe
    mov eax, ebx
    pop ecx
    pop ebx
    ret

.branch_3a3ed:
    inc eax
    cmp eax, 0x19
    jl short .branch_3a3d3
    mov eax, 0x1
    cmp ebx, 0x2
    jl short .branch_3a407
    cmp ebx, 0xb
    jg short .branch_3a407
    mov eax, 0xfffffffc

.branch_3a407:
    cmp ebx, 0x3b
    jl short .branch_3a416
    cmp ebx, 0x44
    jg short .branch_3a416
    mov eax, 0xfffffffc

.branch_3a416:
    cmp ebx, 0x57
    jz short .branch_3a420
    cmp ebx, 0x58
    jnz short .branch_3a425

.branch_3a420:
    mov eax, 0xfffffffc

.branch_3a425:
    mov ebx, eax
    mov eax, ebx
    pop ecx
    pop ebx
    ret
