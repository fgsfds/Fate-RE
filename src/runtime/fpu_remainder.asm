; Reduce the left operand by the selected divisor and return signed quotient bits.
BITS 32
ORG 0x6a209

partial_remainder:
    cmp word [eax + 8], 0
    jne short check_divisor_zero
    cmp dword [eax + 4], 0
    jne short check_divisor_zero
    cmp dword [eax], 0
    jne short check_divisor_zero
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    ret

check_divisor_zero:
    cmp word [edx + 8], 0
    jne short load_operands
    cmp dword [edx + 4], 0
    jne short load_operands
    cmp dword [edx], 0
    jne short load_operands
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.
    mov dword [eax], edx
    mov dword [eax + 4], edx
    mov word [eax + 8], dx
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    ret

load_operands:
    push ebp
    push esi
    push edi
    push edx
    push ecx
    push ebx
    push eax
    mov si, word [eax + 8]
    mov di, word [edx + 8]
    mov ecx, dword [edx + 4]
    mov ebx, dword [edx]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call reduce_significands
    pop ecx
    mov dword [ecx], eax
    mov dword [ecx + 4], edx
    mov word [ecx + 8], si
    db 0x8b, 0xc7 ; MOV eax, edi uses the register-destination opcode.
    pop ebx
    pop ecx
    pop edx
    pop edi
    pop esi
    pop ebp
    ret

reduce_significands:
    push esi
    push edi
    and esi, strict dword 0x7fff
    and edi, strict dword 0x7fff
    db 0x2b, 0xf7 ; SUB esi, edi uses the register-destination opcode.
    jl short dividend_exponent_smaller
    db 0x2b, 0xff ; SUB edi, edi uses the register-destination opcode.

compare_significands:
    db 0x3b, 0xca ; CMP ecx, edx uses the register-destination opcode.
    jne short check_subtraction
    db 0x3b, 0xd8 ; CMP ebx, eax uses the register-destination opcode.
    je near subtract_divisor

check_subtraction:
    jae short accumulate_quotient_bit

subtract_divisor:
    db 0x2b, 0xc3 ; SUB eax, ebx uses the register-destination opcode.
    db 0x1b, 0xd1 ; SBB edx, ecx uses the register-destination opcode.
    stc

accumulate_quotient_bit:
    db 0x13, 0xff ; ADC edi, edi uses the register-destination opcode.
    dec esi
    jl near check_zero_remainder
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    db 0x13, 0xd2 ; ADC edx, edx uses the register-destination opcode.
    jb short subtract_divisor
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    js short compare_significands
    jmp short accumulate_quotient_bit

check_zero_remainder:
    db 0x2b, 0xf6 ; SUB esi, esi uses the register-destination opcode.
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jne short normalize_remainder
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short normalize_remainder
    jmp short finish_normalization

normalize_remainder:
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    js short restore_exponent
    db 0x13, 0xc0 ; ADC eax, eax uses the register-destination opcode.
    db 0x13, 0xd2 ; ADC edx, edx uses the register-destination opcode.
    dec esi
    jmp short normalize_remainder

restore_exponent:
    pop ecx
    push ecx
    and ecx, strict dword 0x7fff
    db 0x03, 0xf1 ; ADD esi, ecx uses the register-destination opcode.

finish_normalization:
    jmp short restore_sign

dividend_exponent_smaller:
    db 0x03, 0xf7 ; ADD esi, edi uses the register-destination opcode.
    db 0x2b, 0xff ; SUB edi, edi uses the register-destination opcode.

restore_sign:
    pop ecx
    pop ebx
    and ebx, strict dword 0x8000
    db 0x0b, 0xf3 ; OR esi, ebx uses the register-destination opcode.
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short sign_quotient
    db 0x2b, 0xf6 ; SUB esi, esi uses the register-destination opcode.

sign_quotient:
    db 0x66, 0x33, 0xd9 ; XOR bx, cx uses the register-destination opcode.
    jns short return_quotient
    neg edi

return_quotient:
    ret
