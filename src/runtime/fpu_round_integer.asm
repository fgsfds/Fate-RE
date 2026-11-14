; Apply x87 rounding control to an integer-valued temporary.
BITS 32
ORG 0x69e63

fraction_masks equ 0x69de3 - 0x10000

round_to_integer:
    push edi
    db 0x8b, 0xf8 ; MOV edi, eax uses the register-destination opcode.
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    mov bx, word [edi + 8]
    cmp dx, 0x400
    je short check_directed_rounding
    cmp dx, 0x800

check_directed_rounding:
    jne short check_truncation
    db 0x0a, 0xff ; OR bh, bh uses the register-destination opcode.
    jns short check_truncation
    xor dx, 0xc00

check_truncation:
    cmp dx, 0xc00
    jne short measure_integer_bits
    mov dx, 0x400

measure_integer_bits:
    and bx, 0x7fff
    sub bx, 0x403f
    jl short round_low_dword
    pop edi
    ret

round_low_dword:
    mov ecx, dword [edi]
    add bx, 0x20
    jl short round_high_dword
    mov eax, dword cs:[ebx*4 + fraction_masks]
    db 0x23, 0xc8 ; AND ecx, eax uses the register-destination opcode.
    xor dword [edi], ecx
    inc eax
    cmp dx, 0x400
    je short return_low_round
    cmp dx, 0
    jne short check_low_fraction
    db 0x03, 0xc9 ; ADD ecx, ecx uses the register-destination opcode.
    db 0x3b, 0xc1 ; CMP eax, ecx uses the register-destination opcode.
    ja near return_low_round
    jne short check_low_fraction
    rol eax, 1
    jae short test_low_even_bit
    test dword [edi + 4], eax
    jmp short check_even_bit

test_low_even_bit:
    test dword [edi], eax

check_even_bit:
    je near return_low_round
    ror eax, 1

check_low_fraction:
    db 0x0b, 0xc9 ; OR ecx, ecx uses the register-destination opcode.
    je short return_low_round
    add dword [edi], eax
    adc dword [edi + 4], 0
    jae short return_low_round
    rcr dword [edi + 4], 1
    inc word [edi + 8]

return_low_round:
    pop edi
    ret

round_high_dword:
    push esi
    mov dword [edi], 0
    mov esi, dword [edi + 4]
    add bx, 0x20
    jl short round_below_one
    mov eax, dword cs:[ebx*4 + fraction_masks]
    db 0x23, 0xf0 ; AND esi, eax uses the register-destination opcode.
    xor dword [edi + 4], esi
    inc eax
    cmp dx, 0x400
    je short return_high_round
    cmp dx, 0
    jne short check_high_fraction
    rol ecx, 1
    db 0x13, 0xf6 ; ADC esi, esi uses the register-destination opcode.
    db 0x3b, 0xc6 ; CMP eax, esi uses the register-destination opcode.
    ja near return_high_round
    jne short check_high_fraction
    db 0x0b, 0xc9 ; OR ecx, ecx uses the register-destination opcode.
    jne near increment_high
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    jb short check_high_even_bit
    test dword [edi + 4], eax

check_high_even_bit:
    je near return_high_round
    shr eax, 1

check_high_fraction:
    db 0x0b, 0xce ; OR ecx, esi uses the register-destination opcode.
    je short return_high_round

increment_high:
    add dword [edi + 4], eax
    jae short return_high_round
    rcr dword [edi + 4], 1
    inc word [edi + 8]

return_high_round:
    pop esi
    pop edi
    ret

round_below_one:
    cmp dx, 0x400
    je short store_zero
    cmp dx, 0
    jne short store_one
    inc bx
    jne near store_zero
    cmp esi, 0x80000000
    jne short store_one
    db 0x0b, 0xc9 ; OR ECX, ECX uses the register-destination opcode.
    je near store_zero

store_one:
    mov dword [edi + 4], 0x80000000
    or word [edi + 8], 0x3fff
    pop esi
    pop edi
    ret

store_zero:
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    mov dword [edi + 4], eax
    mov word [edi + 8], ax
    pop esi
    pop edi
    ret
