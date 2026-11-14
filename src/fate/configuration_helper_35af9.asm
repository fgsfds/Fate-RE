; Configuration buffer helper.
BITS 32
ORG 0x35af9

configuration_key_return equ 0x359b1

configuration_helper_35af9:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov ebp, [esp + 0x14]
    mov edi, [esp + 0x18]
    mov eax, [ebp + 0xa8]
    test eax, eax
    jz short .branch_35b1f
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0x5b
    jz short .branch_35b1f
    cmp edx, 0xd
    jnz short .branch_35b23

.branch_35b1f:
    xor ebx, ebx
    jmp short .branch_35b84

.branch_35b23:
    mov edx, [ebp + 0x84]
    mov ebx, [ebp + 0x88]
    add ebx, edx
    mov [esp], ebx
    xor edx, edx

.branch_35b36:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0x20
    jnz short .branch_35b42
    inc eax
    jmp short .branch_35b36

.branch_35b42:
    xor ebx, ebx
    mov bl, [eax]
    cmp ebx, 0xd
    jz short .branch_35b61
    mov ebx, [esp + 0x1c]
    dec ebx
    cmp edx, ebx
    jnc short .branch_35b61
    mov esi, eax
    mov ebx, edx
    inc eax
    mov cl, [esi]
    inc edx
    mov [edi + ebx], cl
    jmp short .branch_35b42

.branch_35b61:
    add eax, 0x2
    mov byte [edx + edi], 0x0
    cmp eax, [esp]
    jc short .branch_35b79
    mov dword [ebp + 0xa8], 0x0
    jmp short .branch_35b7f

.branch_35b79:
    mov [ebp + 0xa8], eax

.branch_35b7f:
    mov ebx, 0x1

.branch_35b84:
    mov eax, ebx
    jmp near configuration_key_return
