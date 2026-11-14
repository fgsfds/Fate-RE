; Evaluate two to an extended-precision power, minus one.
BITS 32
ORG 0x6a8e8

add_extended_stack equ 0x6959e
multiply_significands equ 0x699d2
add_significands equ 0x695ce
divide_significands equ 0x697fd

exp2_factors:
    dd 0xcc487b15, 0x85aac367
    dw 0x3fff
    dd 0xea8bd6e7, 0x8b95c1e3
    dw 0x3fff
    dd 0x8db8a96f, 0x9837f051
    dw 0x3fff
    dd 0xf9de6484, 0xb504f333
    dw 0x3fff

exp2_minus_one:
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    db 0x8b, 0xf8 ; MOV EDI, EAX, register-destination encoding.
    db 0x2b, 0xf6 ; SUB ESI, ESI, register-destination encoding.
    mov cx, word [edi + 8]
    and byte [edi + 9], 0x7f
    cmp word [edi + 8], 0
    jne short .check_zero
    cmp dword [edi + 4], 0
    jne short .check_zero
    cmp dword [edi], 0

.check_zero:
    je short .zero_index
    db 0x66, 0x0b, 0xc9 ; OR CX, CX, register-destination encoding.
    jns short .split_argument
    dec esi
    push strict dword 0xbfff
    push strict dword 0x80000000
    push 0
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    db 0x8b, 0xdf ; MOV EBX, EDI, register-destination encoding.
    call add_extended_stack
    xor byte [ebx + 9], 0x80

.split_argument:
    mov bx, word [edi + 8]
    add bx, 4
    db 0x2b, 0xc9 ; SUB ECX, ECX, register-destination encoding.
    mov edx, dword [edi + 4]
    mov eax, dword [edi]

.shift_fraction:
    cmp bx, 0x3fff
    jb short .check_high_word
    db 0x03, 0xc0 ; ADD EAX, EAX, register-destination encoding.
    db 0x13, 0xd2 ; ADC EDX, EDX, register-destination encoding.
    db 0x13, 0xc9 ; ADC ECX, ECX, register-destination encoding.
    dec bx
    jmp short .shift_fraction

.check_high_word:
    db 0x0b, 0xd2 ; OR EDX, EDX, register-destination encoding.
    jne short .check_fraction
    db 0x0b, 0xc0 ; OR EAX, EAX, register-destination encoding.

.check_fraction:
    jne short .normalize_fraction
    db 0x2b, 0xdb ; SUB EBX, EBX, register-destination encoding.
    jmp short .store_fraction

.normalize_fraction:
    db 0x0b, 0xd2 ; OR EDX, EDX, register-destination encoding.
    js short .restore_fraction_exponent
    db 0x03, 0xc0 ; ADD EAX, EAX, register-destination encoding.
    db 0x13, 0xd2 ; ADC EDX, EDX, register-destination encoding.
    dec bx
    jmp short .normalize_fraction

.restore_fraction_exponent:
    sub bx, 4

.store_fraction:
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], bx
    jmp short .evaluate_fraction

.zero_index:
    db 0x2b, 0xc9 ; SUB ECX, ECX, register-destination encoding.

.evaluate_fraction:
    push esi
    push ecx
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    shl esi, 0x10
    mov si, word [edi + 8]
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    call multiply_significands
    push eax
    push edx
    push esi
    mov ecx, 0xa6829a79
    mov ebx, 0x1bf21f8c
    and esi, 0xffff
    or esi, 0x40030000
    call add_significands
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    xchg dword [ebp + 8], eax
    xchg dword [ebp + 4], edx
    xchg dword [ebp], esi
    mov ecx, 0xec96f0d6
    mov ebx, 0x9d7bfdb
    and esi, 0xffff
    or esi, 0x3ffa0000
    call multiply_significands
    mov ecx, 0xe6d5051a
    mov ebx, 0xe536e187
    and esi, 0xffff
    or esi, 0x40010000
    call add_significands
    mov ebx, dword [edi]
    mov ecx, dword [edi + 4]
    rol esi, 0x10
    mov si, word [edi + 8]
    rol esi, 0x10
    call multiply_significands
    push eax
    push edx
    push esi
    xor esi, 0x8000
    rol esi, 0x10
    mov si, word [ebp]
    rol esi, 0x10
    mov ebx, dword [ebp + 8]
    mov ecx, dword [ebp + 4]
    call add_significands
    xchg dword [ebp - 4], eax
    xchg dword [ebp - 8], edx
    xchg dword [ebp - 0xc], esi
    rol esi, 0x10
    mov si, word [ebp]
    rol esi, 0x10
    mov ebx, dword [ebp + 8]
    mov ecx, dword [ebp + 4]
    call add_significands
    rol esi, 0x10
    mov si, word [ebp - 0xc]
    rol esi, 0x10
    pop ecx
    pop ecx
    pop ebx
    call divide_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    add esp, 0xc
    pop ecx
    lea esi, [exp2_factors - 0x10000]

.check_index:
    db 0x0b, 0xc9 ; OR ECX, ECX, register-destination encoding.
    je short .restore_sign
    shr ecx, 1
    jae short .advance_factor
    push ecx
    push esi
    mov ax, word [edi + 8]
    mov ecx, dword [edi + 4]
    mov ebx, dword [edi]
    shl eax, 0x10
    mov ax, word [cs:esi + 8]
    mov edx, dword [cs:esi + 4]
    mov esi, dword [cs:esi]
    xchg esi, eax
    call multiply_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    pop esi
    pop ecx

.advance_factor:
    lea esi, [esi + 0xa]
    jmp short .check_index

.restore_sign:
    pop esi
    add word [edi + 8], si
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    push strict dword 0xbfff
    push strict dword 0x80000000
    push 0
    db 0x8b, 0xdf ; MOV EBX, EDI, register-destination encoding.
    call add_extended_stack
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    pop ebp
    ret
