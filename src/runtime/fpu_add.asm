; Extended addition and subtraction, including alignment and normalization.
BITS 32
ORG 0x69566

subtract_extended:
    push esi
    push ecx
    push ebx
    mov si, word [edx + 8]
    xor si, 0x8000
    jmp short load_operands

add_extended:
    push esi
    push ecx
    push ebx
    mov si, word [edx + 8]

load_operands:
    mov ecx, dword [edx + 4]
    mov ebx, dword [edx]
    shl esi, 0x10
    mov si, word [eax + 8]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call add_significands
    pop ebx
    mov dword [ebx], eax
    mov dword [ebx + 4], edx
    mov word [ebx + 8], si
    pop ecx
    pop esi
    ret

add_extended_stack:
    push esi
    push ecx
    push ebx
    mov si, word [esp + 0x18]
    mov ecx, dword [esp + 0x14]
    mov ebx, dword [esp + 0x10]
    shl esi, 0x10
    mov si, word [eax + 8]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call add_significands
    pop ebx
    mov dword [ebx], eax
    mov dword [ebx + 4], edx
    mov word [ebx + 8], si
    pop ecx
    pop esi
    ret 0xc

add_significands:
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jne short check_right_zero
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short check_right_zero
    db 0x66, 0x03, 0xf6 ; ADD si, si uses the register-destination opcode.
    jne short restore_left_exponent
    shr esi, 0x10
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.
    db 0x8b, 0xd1 ; MOV edx, ecx uses the register-destination opcode.
    db 0x03, 0xf6 ; ADD esi, esi uses the register-destination opcode.
    db 0x66, 0x0b, 0xde ; OR bx, si uses the register-destination opcode.
    db 0x0b, 0xda ; OR ebx, edx uses the register-destination opcode.
    je short return_right
    shr esi, 1

return_right:
    ret

restore_left_exponent:
    rcr si, 1

check_right_zero:
    db 0x0b, 0xc9 ; OR ecx, ecx uses the register-destination opcode.
    jne short align_exponents
    db 0x0b, 0xdb ; OR ebx, ebx uses the register-destination opcode.
    jne short align_exponents
    test esi, 0x7fff0000
    jne short align_exponents
    ret

align_exponents:
    push ebp
    push edi
    xchg ecx, esi
    db 0x8b, 0xf9 ; MOV edi, ecx uses the register-destination opcode.
    rol edi, 0x10
    sar edi, 0x10
    sar ecx, 0x10
    and edi, 0x80007fff
    and ecx, 0x80007fff
    db 0x8b, 0xe9 ; MOV ebp, ecx uses the register-destination opcode.
    rol edi, 0x10
    rol ecx, 0x10
    db 0x66, 0x03, 0xcf ; ADD cx, di uses the register-destination opcode.
    rol edi, 0x10
    rol ecx, 0x10
    db 0x66, 0x2b, 0xcf ; SUB cx, di uses the register-destination opcode.
    je short apply_operand_sign
    jae short check_exponent_gap
    db 0x8b, 0xef ; MOV ebp, edi uses the register-destination opcode.
    neg cx
    xchg ebx, eax
    xchg edx, esi

check_exponent_gap:
    cmp cx, 0x40
    jbe short apply_operand_sign
    db 0x03, 0xed ; ADD ebp, ebp uses the register-destination opcode.
    rcr bp, 1
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.
    db 0x8b, 0xd6 ; MOV edx, esi uses the register-destination opcode.
    db 0x8b, 0xf5 ; MOV esi, ebp uses the register-destination opcode.
    pop edi
    pop ebp
    ret

apply_operand_sign:
    mov ch, 0
    db 0x0b, 0xc9 ; OR ecx, ecx uses the register-destination opcode.
    jns short check_shift
    mov ch, 0xff
    neg esi
    neg ebx
    sbb esi, 0
    xor ebp, 0x80000000

check_shift:
    db 0x2b, 0xff ; SUB edi, edi uses the register-destination opcode.
    cmp cl, 0
    je short sum_aligned_operands
    push ebx
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    cmp cl, 0x20
    jb short shift_remaining_bits
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    setne bl
    db 0x8b, 0xfb ; MOV edi, ebx uses the register-destination opcode.
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    cmp cl, 0x40
    jne short shift_whole_word
    db 0x0b, 0xfa ; OR edi, edx uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.

shift_whole_word:
    db 0x8b, 0xc2 ; MOV eax, edx uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.

shift_remaining_bits:
    shrd ebx, eax, cl
    db 0x0b, 0xfb ; OR edi, ebx uses the register-destination opcode.
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    shrd eax, edx, cl
    shrd edx, ebx, cl
    pop ebx

sum_aligned_operands:
    db 0x03, 0xc3 ; ADD eax, ebx uses the register-destination opcode.
    db 0x13, 0xd6 ; ADC edx, esi uses the register-destination opcode.
    adc ch, 0
    jns short check_sum
    cmp cl, 0x40
    jne short negate_sum
    test edi, 0x7fffffff
    setne bl
    shr ebx, 1
    adc eax, 0
    adc edx, 0
    adc ch, 0

negate_sum:
    neg edx
    neg eax
    sbb edx, 0
    mov ch, 0
    xor ebp, 0x80000000

check_sum:
    db 0x8b, 0xd8 ; MOV ebx, eax uses the register-destination opcode.
    db 0x0a, 0xdd ; OR bl, ch uses the register-destination opcode.
    db 0x0b, 0xda ; OR ebx, edx uses the register-destination opcode.
    je short zero_exponent
    db 0x66, 0x0b, 0xed ; OR bp, bp uses the register-destination opcode.
    je short restore_result_sign
    cmp ch, 0
    jne short normalize_right
    rol edi, 1
    ror edi, 1

normalize_left:
    dec bp
    je short restore_result_sign
    db 0x13, 0xc0 ; ADC eax, eax uses the register-destination opcode.
    db 0x13, 0xd2 ; ADC edx, edx uses the register-destination opcode.
    jae short normalize_left

normalize_right:
    inc bp
    cmp bp, 0x7fff
    je near overflow_to_infinity
    stc
    rcr edx, 1
    rcr eax, 1
    jae short finish_rounding
    db 0x03, 0xff ; ADD edi, edi uses the register-destination opcode.
    jne short round_sum
    ror eax, 1
    rol eax, 1

round_sum:
    adc eax, 0
    adc edx, 0
    jae short finish_rounding
    rcr edx, 1
    rcr eax, 1
    inc bp
    cmp bp, 0x7fff
    je near overflow_to_infinity

finish_rounding:
    jmp short restore_result_sign

zero_exponent:
    db 0x8b, 0xeb ; MOV ebp, ebx uses the register-destination opcode.

restore_result_sign:
    db 0x03, 0xed ; ADD ebp, ebp uses the register-destination opcode.
    rcr bp, 1
    db 0x8b, 0xf5 ; MOV esi, ebp uses the register-destination opcode.
    pop edi
    pop ebp
    ret

overflow_to_infinity:
    mov bp, 0x7fff
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    mov edx, 0x80000000
    jmp short restore_result_sign
