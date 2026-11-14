; Extended division and multiplication for the x87 emulator.
BITS 32
ORG 0x697d3

signal_exception equ 0x68060

divide_extended:
    push esi
    push ecx
    push ebx
    mov si, word [edx + 8]
    mov ecx, dword [edx + 4]
    mov ebx, dword [edx]
    shl esi, 0x10
    mov si, word [eax + 8]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call divide_significands
    pop ebx
    mov dword [ebx], eax
    mov dword [ebx + 4], edx
    mov word [ebx + 8], si
    pop ecx
    pop esi
    ret

divide_significands:
    db 0x0b, 0xc9 ; OR ecx, ecx uses the register-destination opcode.
    jne short check_zero_dividend
    db 0x0b, 0xdb ; OR ebx, ebx uses the register-destination opcode.
    jne short check_zero_dividend
    test esi, 0x7fff0000
    jne short check_zero_dividend
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jne short signal_zero_divisor
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short signal_zero_divisor
    db 0x8b, 0xc6 ; MOV eax, esi uses the register-destination opcode.
    db 0x66, 0x03, 0xc0 ; ADD ax, ax uses the register-destination opcode.
    jne short signal_zero_divisor
    mov al, 1
    mov ah, 0x81
    call signal_exception
    mov edx, 0xc0000000
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    mov si, 0xffff
    jmp short return_special_division

signal_zero_divisor:
    mov al, 4
    mov ah, 0x83
    call signal_exception
    mov edx, 0x80000000
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    or si, 0x7fff

return_special_division:
    ret

check_zero_dividend:
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jne short unpack_division_exponents
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short unpack_division_exponents
    db 0x66, 0x03, 0xf6 ; ADD si, si uses the register-destination opcode.
    jne short restore_dividend_sign
    ret

restore_dividend_sign:
    rcr si, 1

unpack_division_exponents:
    push ebp
    db 0x8b, 0xec ; MOV ebp, esp uses the register-destination opcode.
    push edi
    xchg ecx, esi
    db 0x8b, 0xf9 ; MOV edi, ecx uses the register-destination opcode.
    rol edi, 0x10
    sar edi, 0x10
    sar ecx, 0x10
    and edi, 0x80007fff
    and ecx, 0x80007fff
    rol edi, 0x10
    rol ecx, 0x10
    db 0x66, 0x03, 0xf9 ; ADD di, cx uses the register-destination opcode.
    rol edi, 0x10
    rol ecx, 0x10
    db 0x66, 0x0b, 0xff ; OR di, di uses the register-destination opcode.
    jne short check_divisor_exponent

normalize_dividend:
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    db 0x13, 0xd2 ; ADC edx, edx uses the register-destination opcode.
    dec di
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jns short normalize_dividend

check_divisor_exponent:
    db 0x66, 0x0b, 0xc9 ; OR cx, cx uses the register-destination opcode.
    jne short compute_quotient_exponent

normalize_divisor:
    db 0x03, 0xdb ; ADD ebx, ebx uses the register-destination opcode.
    db 0x13, 0xf6 ; ADC esi, esi uses the register-destination opcode.
    dec cx
    db 0x0b, 0xf6 ; OR esi, esi uses the register-destination opcode.
    jns short normalize_divisor

compute_quotient_exponent:
    db 0x66, 0x2b, 0xf9 ; SUB di, cx uses the register-destination opcode.
    add di, 0x3fff
    js short check_quotient_underflow
    cmp di, 0x7fff
    jb short check_quotient_underflow
    db 0x8b, 0xf9 ; MOV edi, ecx uses the register-destination opcode.
    mov di, 0x7fff
    mov edx, 0x80000000
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    jmp near restore_quotient_sign

check_quotient_underflow:
    cmp di, -0x40
    jge short compute_quotient
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.
    db 0x2b, 0xff ; SUB edi, edi uses the register-destination opcode.
    jmp near restore_quotient_sign

compute_quotient:
    push edi
    push esi
    push ebx
    db 0x8b, 0xce ; MOV ecx, esi uses the register-destination opcode.
    db 0x8b, 0xfa ; MOV edi, edx uses the register-destination opcode.
    db 0x8b, 0xf0 ; MOV esi, eax uses the register-destination opcode.
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    db 0x3b, 0xcf ; CMP ecx, edi uses the register-destination opcode.
    ja short estimate_high_quotient
    db 0x2b, 0xd1 ; SUB edx, ecx uses the register-destination opcode.
    inc eax

estimate_high_quotient:
    push eax
    db 0x8b, 0xc6 ; MOV eax, esi uses the register-destination opcode.
    div ecx
    push eax
    xchg ebx, eax
    mul ebx
    xchg ecx, eax
    xchg ebx, edx
    mul edx
    db 0x03, 0xc3 ; ADD eax, ebx uses the register-destination opcode.
    adc edx, 0
    mov ebx, dword [ebp - 0x10]
    test byte [ebp - 0x14], 1
    je short subtract_high_product
    db 0x03, 0xc3 ; ADD eax, ebx uses the register-destination opcode.
    adc edx, dword [ebp - 0xc]

subtract_high_product:
    neg ecx
    db 0x1b, 0xf0 ; SBB esi, eax uses the register-destination opcode.
    db 0x1b, 0xfa ; SBB edi, edx uses the register-destination opcode.
    je short estimate_low_quotient

correct_high_quotient:
    sub dword [ebp - 0x18], 1
    sbb dword [ebp - 0x14], 0
    db 0x03, 0xcb ; ADD ecx, ebx uses the register-destination opcode.
    adc esi, dword [ebp - 0xc]
    adc edi, 0
    jne short correct_high_quotient

estimate_low_quotient:
    db 0x8b, 0xfe ; MOV edi, esi uses the register-destination opcode.
    db 0x8b, 0xf1 ; MOV esi, ecx uses the register-destination opcode.
    mov ecx, dword [ebp - 0xc]
    db 0x3b, 0xcf ; CMP ecx, edi uses the register-destination opcode.
    ja short divide_low_word
    db 0x2b, 0xf9 ; SUB edi, ecx uses the register-destination opcode.
    add dword [ebp - 0x18], 1
    adc dword [ebp - 0x14], 0

divide_low_word:
    db 0x8b, 0xd7 ; MOV edx, edi uses the register-destination opcode.
    db 0x8b, 0xc6 ; MOV eax, esi uses the register-destination opcode.
    div ecx
    push eax
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    je short collect_quotient
    xchg ebx, eax
    mul ebx
    xchg ecx, eax
    xchg ebx, edx
    mul edx
    db 0x03, 0xc3 ; ADD eax, ebx uses the register-destination opcode.
    adc edx, 0
    neg ecx
    db 0x1b, 0xf0 ; SBB esi, eax uses the register-destination opcode.
    db 0x1b, 0xfa ; SBB edi, edx uses the register-destination opcode.
    je short collect_quotient

correct_low_quotient:
    sub dword [ebp - 0x1c], 1
    sbb dword [ebp - 0x18], 0
    sbb dword [ebp - 0x14], 0
    add ecx, dword [ebp - 0x10]
    adc esi, dword [ebp - 0xc]
    adc edi, 0
    jne short correct_low_quotient

collect_quotient:
    pop eax
    pop edx
    pop ebx
    add esp, 8
    pop edi
    dec di
    shr ebx, 1
    jae short check_denormal_quotient
    rcr edx, 1
    rcr eax, 1
    inc edi

check_denormal_quotient:
    db 0x66, 0x0b, 0xff ; OR di, di uses the register-destination opcode.
    jg short restore_quotient_sign
    jne short negate_quotient_exponent
    mov cl, 1
    jmp short shift_quotient

negate_quotient_exponent:
    neg di
    db 0x66, 0x8b, 0xcf ; MOV cx, di uses the register-destination opcode.

shift_quotient:
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    shrd eax, edx, cl
    shrd edx, ebx, cl
    db 0x66, 0x2b, 0xff ; SUB di, di uses the register-destination opcode.

restore_quotient_sign:
    db 0x03, 0xff ; ADD edi, edi uses the register-destination opcode.
    rcr di, 1
    db 0x8b, 0xf7 ; MOV esi, edi uses the register-destination opcode.
    pop edi
    pop ebp
    ret

multiply_extended:
    push esi
    push ecx
    push ebx
    mov si, word [edx + 8]
    mov ecx, dword [edx + 4]
    mov ebx, dword [edx]
    shl esi, 0x10
    mov si, word [eax + 8]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call multiply_significands
    pop ebx
    mov dword [ebx], eax
    mov dword [ebx + 4], edx
    mov word [ebx + 8], si
    pop ecx
    pop esi
    ret

multiply_significands:
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jne short check_zero_multiplier
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short check_zero_multiplier
    db 0x66, 0x03, 0xf6 ; ADD si, si uses the register-destination opcode.
    jne short restore_multiplicand_sign
    ret

restore_multiplicand_sign:
    rcr si, 1

check_zero_multiplier:
    db 0x0b, 0xc9 ; OR ecx, ecx uses the register-destination opcode.
    jne short unpack_product_exponents
    db 0x0b, 0xdb ; OR ebx, ebx uses the register-destination opcode.
    jne short unpack_product_exponents
    test esi, 0x7fff0000
    jne short unpack_product_exponents
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.
    db 0x2b, 0xf6 ; SUB esi, esi uses the register-destination opcode.
    ret

unpack_product_exponents:
    push ebp
    push edi
    xchg ecx, esi
    db 0x8b, 0xf9 ; MOV edi, ecx uses the register-destination opcode.
    rol edi, 0x10
    sar edi, 0x10
    sar ecx, 0x10
    and edi, 0x80007fff
    and ecx, 0x80007fff
    db 0x03, 0xcf ; ADD ecx, edi uses the register-destination opcode.
    sub cx, 0x3ffe
    jb short check_product_underflow
    cmp cx, 0x7fff
    jb short check_product_underflow
    jmp near product_infinity

check_product_underflow:
    cmp cx, -0x40
    jge short multiply_words
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.
    db 0x2b, 0xc9 ; SUB ecx, ecx uses the register-destination opcode.
    jmp short restore_product_sign
    nop
    nop
    nop

multiply_words:
    push ecx
    db 0x2b, 0xed ; SUB ebp, ebp uses the register-destination opcode.
    push esi
    push edx
    push eax
    mul ebx
    xchg esi, eax
    db 0x8b, 0xca ; MOV ecx, edx uses the register-destination opcode.
    pop edx
    mul edx
    db 0x8b, 0xfa ; MOV edi, edx uses the register-destination opcode.
    db 0x03, 0xc8 ; ADD ecx, eax uses the register-destination opcode.
    db 0x13, 0xfd ; ADC edi, ebp uses the register-destination opcode.
    db 0x13, 0xed ; ADC ebp, ebp uses the register-destination opcode.
    pop eax
    xchg ebx, eax
    mul ebx
    db 0x03, 0xc8 ; ADD ecx, eax uses the register-destination opcode.
    db 0x13, 0xfa ; ADC edi, edx uses the register-destination opcode.
    adc ebp, 0
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.
    pop edx
    mul edx
    db 0x03, 0xc7 ; ADD eax, edi uses the register-destination opcode.
    db 0x13, 0xd5 ; ADC edx, ebp uses the register-destination opcode.
    db 0x8b, 0xd9 ; MOV ebx, ecx uses the register-destination opcode.
    pop ecx
    js short check_product_rounding
    db 0x03, 0xdb ; ADD ebx, ebx uses the register-destination opcode.
    db 0x13, 0xc0 ; ADC eax, eax uses the register-destination opcode.
    db 0x13, 0xd2 ; ADC edx, edx uses the register-destination opcode.
    dec cx

check_product_rounding:
    db 0x03, 0xdb ; ADD ebx, ebx uses the register-destination opcode.
    jae short check_denormal_product
    jne short round_product
    db 0x0b, 0xf6 ; OR esi, esi uses the register-destination opcode.
    setne bl
    shr ebx, 1
    jb short round_product
    db 0x8b, 0xf0 ; MOV esi, eax uses the register-destination opcode.
    shr esi, 1

round_product:
    adc eax, 0
    adc edx, 0
    jae short check_denormal_product
    rcr edx, 1
    rcr eax, 1
    inc cx
    cmp cx, 0x7fff
    je near product_infinity

check_denormal_product:
    db 0x66, 0x0b, 0xc9 ; OR cx, cx uses the register-destination opcode.
    jg short restore_product_sign
    jne short negate_product_exponent
    mov cl, 1
    jmp short shift_product

negate_product_exponent:
    neg cx

shift_product:
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    shrd eax, edx, cl
    shrd edx, ebx, cl
    db 0x66, 0x2b, 0xc9 ; SUB cx, cx uses the register-destination opcode.

restore_product_sign:
    db 0x03, 0xc9 ; ADD ecx, ecx uses the register-destination opcode.
    rcr cx, 1
    db 0x8b, 0xf1 ; MOV esi, ecx uses the register-destination opcode.
    pop edi
    pop ebp
    ret

product_infinity:
    mov cx, 0x7fff
    mov edx, 0x80000000
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    jmp short restore_product_sign
