; Evaluate a polynomial in Horner form and multiply the odd polynomial by its argument.
BITS 32
ORG 0x6abd0

add_significands equ 0x695ce
multiply_significands equ 0x699d2

evaluate_polynomial:
    push ebp
    push edi
    push ecx
    push ebx
    push esi
    push edx
    push eax
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    db 0x8b, 0xf9 ; MOV EDI, ECX, register-destination encoding.
    mov eax, dword [cs:edi]
    mov edx, dword [cs:edi + 4]
    mov si, word [cs:edi + 8]

.horner_step:
    rol esi, 0x10
    mov si, word [ebp + 8]
    rol esi, 0x10
    mov ebx, [byte ebp]
    mov ecx, dword [ebp + 4]
    call multiply_significands
    lea edi, [edi + 0xa]
    mov ebx, dword [cs:edi]
    mov ecx, dword [cs:edi + 4]
    rol esi, 0x10
    mov si, word [cs:edi + 8]
    rol esi, 0x10
    call add_significands
    dec dword [ebp + 0xc]
    jne short .horner_step
    add esp, 0x10
    pop ecx
    pop edi
    pop ebp
    ret

evaluate_odd_polynomial:
    push edi
    push esi
    push ecx
    push ebx
    push edx
    db 0x8b, 0xf8 ; MOV EDI, EAX, register-destination encoding.
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    shl esi, 0x10
    mov si, word [edi + 8]
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    call multiply_significands
    pop ecx
    pop ebx
    call evaluate_polynomial
    rol esi, 0x10
    mov ebx, dword [edi]
    mov ecx, dword [edi + 4]
    mov si, word [edi + 8]
    rol esi, 0x10
    call multiply_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    pop ecx
    pop esi
    pop edi
    ret
