; Port input, far copy, bounded strings and signed division.
BITS 32
ORG 0x6326a

inp_:
    push edx
    mov edx, eax
    sub eax, eax
    in al, dx
    pop edx
    ret

_fmemcpy_:
    push esi
    push edi
    mov edi, eax
    mov esi, ebx
    mov eax, dword [esp + 0xc]
    push ds
    push es
    push edi
    xchg eax, ecx
    mov ds, eax
    mov es, edx
    mov eax, ecx
    shr ecx, 2
    db 0xf2 ; Preserve the original repeat prefix.
    movsd
    db 0x8a, 0xc8 ; MOV CL, AL uses the register-destination opcode.
    and cl, 3
    repne movsb
    pop eax
    pop es
    pop ds
    pop edi
    pop esi
    ret 4

strncpy_:
    push ecx
    push esi
    mov esi, eax
    jmp short .check_copy_count

.copy_byte:
    mov cl, byte [edx]
    test cl, cl
    je short .pad_destination
    inc edx
    dec ebx
    mov byte [eax], cl
    inc eax

.check_copy_count:
    test ebx, ebx
    jne short .copy_byte

.pad_destination:
    test ebx, ebx
    je short .return_destination
    dec ebx
    mov byte [eax], 0
    inc eax
    jmp short .pad_destination

.return_destination:
    mov eax, esi
    pop esi
    pop ecx
    ret

strncmp_:
    push ecx

.check_count:
    test ebx, ebx
    jne short .compare_bytes

.return_equal:
    xor eax, eax
    pop ecx
    ret

.compare_bytes:
    mov cl, byte [eax]
    mov ch, byte [edx]
    cmp cl, ch
    je short .check_terminator
    xor ebx, ebx
    xor eax, eax
    mov bl, cl
    mov al, ch
    sub ebx, eax
    mov eax, ebx
    pop ecx
    ret

.check_terminator:
    cmp byte [eax], 0
    je short .return_equal
    inc eax
    inc edx
    dec ebx
    jmp short .check_count

div_:
    push ebx
    push ecx
    push edi
    push es
    sub esp, 8
    mov ecx, esi
    mov ebx, eax
    mov esi, edx
    mov edx, eax
    sar edx, 0x1f
    idiv esi
    mov dword [esp], eax
    mov edx, ebx
    mov eax, ebx
    sar edx, 0x1f
    idiv esi
    mov edi, ecx
    mov eax, ds
    mov esi, esp
    mov es, eax
    mov dword [esp + 4], edx
    movsd
    movsd
    mov eax, ecx
    add esp, 8
    pop es
    pop edi
    pop ecx
    pop ebx
    ret
