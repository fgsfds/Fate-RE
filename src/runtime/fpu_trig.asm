; Reduce an extended-precision angle and evaluate sine, cosine or tangent.
BITS 32
ORG 0x6a606

reduce_significands equ 0x6a26f
add_extended_stack equ 0x6959e
multiply_significands equ 0x699d2
evaluate_polynomial equ 0x6abd0
evaluate_odd_polynomial equ 0x6ac22
divide_significands equ 0x697fd

sine_coefficients:
    dd 0x856a5359, 0xca963b81
    dw 0x3fce
    dd 0x9dc0f88f, 0xd73f9f39
    dw 0xbfd6
    dd 0x43684be5, 0xb092309d
    dw 0x3fde
    dd 0xaa271c7f, 0xd7322b3f
    dw 0xbfe5
    dd 0xb6399c7d, 0xb8ef1d2a
    dw 0x3fec
    dd 0x0d00d00c, 0xd00d00d0
    dw 0xbff2
    dd 0x88888888, 0x88888888
    dw 0x3ff8
    dd 0xaaaaaaaa, 0xaaaaaaaa
    dw 0xbffc
    dd 0x00000000, 0x80000000
    dw 0x3fff

cosine_coefficients:
    dd 0x9dc0f88f, 0xd73f9f39
    dw 0x3fd2
    dd 0x03e4e905, 0xc9cba546
    dw 0xbfda
    dd 0xc6c4bdaa, 0x8f76c77f
    dw 0x3fe2
    dd 0xc4fae397, 0x93f27dbb
    dw 0xbfe9
    dd 0x0d00d00d, 0xd00d00d0
    dw 0x3fef
    dd 0x0b60b60b, 0xb60b60b6
    dw 0xbff5
    dd 0xaaaaaaaa, 0xaaaaaaaa
    dw 0x3ffa
    dd 0x00000000, 0x80000000
    dw 0xbffe
    dd 0x00000000, 0x80000000
    dw 0x3fff

trig_coefficient_skip:
    dw 0, 1, 2, 3, 4, 4, 5, 5, 6

trig_reduce_and_evaluate:
    push ebp
    push edi
    push edx
    push ecx
    push ebx
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    sub esp, 0xc
    db 0x8b, 0xf8 ; MOV EDI, EAX, register-destination encoding.
    db 0x2b, 0xc9 ; SUB ECX, ECX, register-destination encoding.
    mov cx, word [eax + 8]
    and cx, 0x7fff
    sub cx, 0x3ffe
    cmp cx, 0x20
    jl short .reduce_argument

.reduce_argument:
    push ecx
    push esi
    push edi
    mov si, word [eax + 8]
    mov di, 0x3ffe
    mov ecx, 0xc90fdaa2
    mov ebx, 0x2168c235
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call reduce_significands
    pop ecx
    mov dword [ecx], eax
    mov dword [ecx + 4], edx
    mov word [ecx + 8], si
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    db 0x8b, 0xf9 ; MOV EDI, ECX, register-destination encoding.
    pop esi
    test byte [edi + 9], 0x80
    je short .apply_mode
    push eax
    db 0x8b, 0xdf ; MOV EBX, EDI, register-destination encoding.
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    push strict dword 0x3ffe
    push strict dword 0xc90fdaa2
    push strict dword 0x2168c235
    call add_extended_stack
    pop eax
    dec eax

.apply_mode:
    db 0x8b, 0xde ; MOV EBX, ESI, register-destination encoding.
    db 0x8a, 0xe3 ; MOV AH, BL, register-destination encoding.
    and bl, 2
    db 0x02, 0xc3 ; ADD AL, BL, register-destination encoding.
    and al, 7
    push eax
    test al, 1
    je short .choose_terms
    push strict dword 0xbffe
    push strict dword 0xc90fdaa2
    push strict dword 0x2168c235
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    db 0x8b, 0xdf ; MOV EBX, EDI, register-destination encoding.
    call add_extended_stack
    xor byte [ebx + 9], 0x80

.choose_terms:
    db 0x2b, 0xc9 ; SUB ECX, ECX, register-destination encoding.
    mov cx, word [edi + 8]
    sub cx, 0x3ffe
    cmp cx, -0x20
    jge short .choose_precision
    mov dword [ebp - 0xc], 0
    mov dword [ebp - 8], 0x80000000
    mov word [ebp - 4], 0x3fff
    jmp near .choose_result

.choose_precision:
    db 0x66, 0x0b, 0xc9 ; OR CX, CX, register-destination encoding.
    js short .clamp_terms
    mov cx, 0

.clamp_terms:
    neg cx
    cmp cx, 8
    jle short .load_skip
    mov cx, 8

.load_skip:
    db 0x2e, 0x66, 0x8b, 0x0c, 0x4d ; MOV CX, [CS:ECX*2 + disp32].
    dd trig_coefficient_skip - 0x10000
    push ecx
    mov eax, dword [ebp - 0x14]
    inc al
    and al, 2
    jne short .evaluate_cosine
    cmp ah, 1
    je short .evaluate_cosine
    jmp short .check_sine

.evaluate_cosine:
    push eax
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    shl esi, 0x10
    mov si, word [edi + 8]
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    call multiply_significands
    mov ecx, dword [ebp - 0x18]
    mov ebx, 8
    db 0x2b, 0xd9 ; SUB EBX, ECX, register-destination encoding.
    lea ecx, [ecx + ecx*4]
    db 0x8d, 0x0c, 0x4d ; LEA ECX, [ECX*2 + disp32].
    dd cosine_coefficients - 0x10000
    call evaluate_polynomial
    mov dword [ebp - 0xc], eax
    mov dword [ebp - 8], edx
    mov word [ebp - 4], si
    pop eax

.check_sine:
    cmp al, 0
    je short .evaluate_sine
    cmp ah, 1
    je short .evaluate_sine
    jmp short .choose_result

.evaluate_sine:
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    mov ecx, dword [ebp - 0x18]
    mov ebx, 8
    db 0x2b, 0xd9 ; SUB EBX, ECX, register-destination encoding.
    lea ecx, [ecx + ecx*4]
    db 0x03, 0xc9 ; ADD ECX, ECX, register-destination encoding.
    lea edx, [sine_coefficients - 0x10000]
    db 0x03, 0xd1 ; ADD EDX, ECX, register-destination encoding.
    call evaluate_odd_polynomial

.choose_result:
    mov eax, dword [ebp - 0x14]
    inc al
    and al, 2
    je short .load_sine
    mov eax, dword [ebp - 0xc]
    mov edx, dword [ebp - 8]
    mov si, word [ebp - 4]
    jmp short .correct_sign

.load_sine:
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]

.correct_sign:
    mov ecx, dword [ebp - 0x14]
    test cl, 4
    je short .check_tangent
    xor si, 0x8000

.check_tangent:
    cmp ch, 1
    jne short .store
    rol esi, 0x10
    add cl, 2
    db 0x8a, 0xd9 ; MOV BL, CL, register-destination encoding.
    inc bl
    and bl, 2
    je short .load_sine_divisor
    and cl, 4
    mov ebx, dword [ebp - 0xc]
    mov ecx, dword [ebp - 8]
    mov si, word [ebp - 4]
    jmp short .correct_divisor_sign

.load_sine_divisor:
    and cl, 4
    mov ebx, dword [edi]
    mov ecx, dword [edi + 4]
    mov si, word [edi + 8]

.correct_divisor_sign:
    je short .check_divisor
    xor esi, 0x8000

.check_divisor:
    rol esi, 0x10
    db 0x0b, 0xdb ; OR EBX, EBX, register-destination encoding.
    jne short .divide
    db 0x0b, 0xc9 ; OR ECX, ECX, register-destination encoding.
    jne short .divide
    test esi, 0x7fff0000
    jne short .divide
    db 0x2b, 0xc0 ; SUB EAX, EAX, register-destination encoding.
    mov edx, 0x80000000
    or si, 0x7fff
    jmp short .store

.divide:
    call divide_significands

.store:
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    db 0x8b, 0xe5 ; MOV ESP, EBP, register-destination encoding.
    pop ebx
    pop ecx
    pop edx
    pop edi
    pop ebp
    ret

sine_extended:
    push esi
    db 0x2b, 0xf6 ; SUB ESI, ESI, register-destination encoding.
    call trig_reduce_and_evaluate
    pop esi
    ret

cosine_extended:
    push esi
    mov esi, 2
    call trig_reduce_and_evaluate
    pop esi
    ret

tangent_extended:
    push esi
    mov esi, 1
    call trig_reduce_and_evaluate
    pop esi
    ret
