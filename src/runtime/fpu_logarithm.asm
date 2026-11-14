; Compute log2 with a rational approximation and multiply the x87 operands.
BITS 32
ORG 0x6a392

add_extended_stack equ 0x6959e
multiply_extended equ 0x699a8
multiply_significands equ 0x699d2
add_significands equ 0x695ce
divide_significands equ 0x697fd
evaluate_polynomial equ 0x6abd0
convert_signed_integer equ 0x69b92

log_denominator:
    dd 0xb5e946e9, 0xca20ad9a
    dw 0xbffe
    dd 0xb57f6509, 0x83125100
    dw 0x4003
    dd 0x9dacd228, 0x803ff895
    dw 0xc005

log_numerator:
    dd 0x00000000, 0x80000000
    dw 0x3fff
    dd 0x3e7076bb, 0x8eac025b
    dw 0xc004
    dd 0xa933ef60, 0x9c041fd0
    dw 0x4007
    dd 0x6c83bb96, 0xc05ff4e0
    dw 0xc008

log2_one_plus:
    push ebx
    push edx
    push eax
    push strict dword 0x3fff
    push strict dword 0x80000000
    push 0
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    call add_extended_stack
    pop eax
    pop edx
    pop ebx

log2_multiply:
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax
    call log2_extended
    pop eax
    db 0x8b, 0xda ; MOV EBX, EDX, register-destination encoding.
    push edx
    call multiply_extended
    pop edi
    mov si, word [edi + 8]
    mov ecx, dword [edi + 4]
    mov ebx, dword [edi]
    shl esi, 0x10
    mov si, 0x3fff
    mov edx, 0xb8aa3b29
    mov eax, 0x5c17f0bd
    call multiply_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    ret

log2_extended:
    push edi
    push esi
    push edx
    push ecx
    push ebx
    db 0x2b, 0xc9 ; SUB ECX, ECX, register-destination encoding.
    mov cx, word [eax + 8]
    db 0x66, 0x0b, 0xc9 ; OR CX, CX, register-destination encoding.
    js short .normalize
    jmp short .normalize

.normalize:
    db 0x8b, 0xf8 ; MOV EDI, EAX, register-destination encoding.
    mov edx, 0x3ffe
    sub ecx, 0x3ffe
    push ecx
    mov word [edi + 8], dx
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov esi, 0xbffe3ffe
    mov ecx, 0x80000000
    db 0x2b, 0xdb ; SUB EBX, EBX, register-destination encoding.
    call add_significands
    cmp word [edi + 8], 0x3ffe
    jne short .choose_reduction
    cmp dword [edi + 4], 0xb504f333
    jne short .choose_reduction
    cmp dword [edi], 0xf9de6484

.choose_reduction:
    jbe short .reduce_lower
    and esi, 0xffff
    or esi, 0xbffe0000
    mov ecx, 0x80000000
    db 0x2b, 0xdb ; SUB EBX, EBX, register-destination encoding.
    call add_significands
    jmp short .form_ratio

.reduce_lower:
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    dec dword [esp]

.form_ratio:
    push eax
    push edx
    push esi
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    dec si
    and esi, 0xffff
    or esi, 0x3ffe0000
    mov ecx, 0x80000000
    db 0x2b, 0xdb ; SUB EBX, EBX, register-destination encoding.
    call add_significands
    shl esi, 0x10
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    pop eax
    db 0x66, 0x8b, 0xf0 ; MOV SI, AX, register-destination encoding.
    pop edx
    pop eax
    call divide_significands
    push eax
    push edx
    push esi
    db 0x8b, 0xce ; MOV ECX, ESI, register-destination encoding.
    shl esi, 0x10
    db 0x66, 0x8b, 0xf1 ; MOV SI, CX, register-destination encoding.
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    call multiply_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    mov ebx, 3
    lea ecx, [log_numerator - 0x10000]
    call evaluate_polynomial
    push eax
    push edx
    push esi
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    lea ecx, [log_denominator - 0x10000]
    mov ebx, 2
    call evaluate_polynomial
    pop ecx
    rol esi, 0x10
    db 0x66, 0x8b, 0xf1 ; MOV SI, CX, register-destination encoding.
    rol esi, 0x10
    pop ecx
    pop ebx
    call divide_significands
    mov ebx, dword [edi]
    mov ecx, dword [edi + 4]
    rol esi, 0x10
    mov si, word [edi + 8]
    rol esi, 0x10
    call multiply_significands
    rol esi, 0x10
    mov si, word [esp]
    rol esi, 0x10
    mov ecx, dword [esp + 4]
    mov ebx, dword [esp + 8]
    call multiply_significands
    rol esi, 0x10
    pop ecx
    db 0x66, 0x8b, 0xf1 ; MOV SI, CX, register-destination encoding.
    rol esi, 0x10
    pop ecx
    pop ebx
    call add_significands
    pop ecx
    db 0x0b, 0xc9 ; OR ECX, ECX, register-destination encoding.
    je short .store
    push eax
    push edx
    push esi
    db 0x8b, 0xd7 ; MOV EDX, EDI, register-destination encoding.
    db 0x8b, 0xc1 ; MOV EAX, ECX, register-destination encoding.
    call convert_signed_integer
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    and esi, 0xffff
    or esi, 0xbff20000
    mov ecx, 0xde8082e3
    mov ebx, 0x865435c
    call multiply_significands
    pop ecx
    rol esi, 0x10
    db 0x66, 0x8b, 0xf1 ; MOV SI, CX, register-destination encoding.
    rol esi, 0x10
    pop ecx
    pop ebx
    call add_significands
    push eax
    push edx
    push esi
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    and esi, 0xffff
    or esi, 0x3ffe0000
    mov ecx, 0xb1800000
    db 0x2b, 0xdb ; SUB EBX, EBX, register-destination encoding.
    call multiply_significands
    pop ecx
    rol esi, 0x10
    db 0x66, 0x8b, 0xf1 ; MOV SI, CX, register-destination encoding.
    rol esi, 0x10
    pop ecx
    pop ebx
    call add_significands

.store:
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    ret
