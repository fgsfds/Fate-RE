; Software single-precision arithmetic and the double-to-single narrowing helper.
BITS 32
ORG 0x73cca

float_positive_zero equ 0x73fda
float_largest_finite equ 0x73fdd

double_to_float:
    push ebx
    test edx, 0x7ff00000
    jz short .underflow
    sub ebx, ebx
    add eax, eax
    adc edx, edx
    rcr ebx, 1
    add eax, 0x20000000
    adc edx, 0
    jz short .infinity
    cmp edx, 0x8fe00000
    jae short .infinity
    cmp edx, 0x70200000
    jb short .underflow
    sub edx, 0x70000000
    add eax, eax
    adc edx, edx
    add eax, eax
    adc edx, edx
    or edx, ebx
    mov eax, edx
    pop ebx
    ret

.infinity:
    mov eax, 0x7f800000
    or eax, ebx
    pop ebx
    ret

.underflow:
    sub eax, eax
    pop ebx
    ret

float_subtract:
    db 0xb, 0xd2 ; or edx, edx (register destination)
    jz short float_add.return
    xor edx, 0x80000000

; Both entries share the unpacking, normalization and rounding below.
float_add:
    db 0xb, 0xd2 ; or edx, edx (register destination)
    jz short .return
    db 0xb, 0xc0 ; or eax, eax (register destination)
    jnz short .unpack
    db 0x8b, 0xc2 ; mov eax, edx (register destination)
.return:
    ret

.unpack:
    push ecx
    push ebx
    db 0x2b, 0xc9 ; sub ecx, ecx (register destination)
    db 0x3, 0xc0 ; add eax, eax (register destination)
    db 0x12, 0xc9 ; adc cl, cl (register destination)
    db 0x8a, 0xe9 ; mov ch, cl (register destination)
    db 0x2, 0xc9 ; add cl, cl (register destination)
    db 0x2, 0xc9 ; add cl, cl (register destination)
    db 0x2, 0xcd ; add cl, ch (register destination)
    rol eax, 8
    db 0x3, 0xd2 ; add edx, edx (register destination)
    adc cl, 0
    rol edx, 8
    db 0x8a, 0xd8 ; mov bl, al (register destination)
    db 0x8a, 0xfa ; mov bh, dl (register destination)
    mov al, 0
    stc
    rcr eax, 1
    mov dl, 0
    stc
    rcr edx, 1
    db 0x8a, 0xeb ; mov ch, bl (register destination)
    db 0x2a, 0xdf ; sub bl, bh (register destination)
    jz short .combine
    jae short .align
    db 0x8a, 0xef ; mov ch, bh (register destination)
    neg bl
    xchg edx, eax
    xor cl, 4
.align:
    xchg cl, bl
    cmp cl, 0x20
    jl short .shift
    db 0x2b, 0xd2 ; sub edx, edx (register destination)
    jmp short .restore_flags
.shift:
    shr edx, cl
.restore_flags:
    xchg cl, bl
.combine:
    shr cl, 1
    jc short .subtract_magnitudes
    db 0x3, 0xc2 ; add eax, edx (register destination)
    jae short .sum_ready
    rcr eax, 1
    inc ch
    jnz short .sum_ready
    ror cl, 1
    rcr eax, 1
    jmp short .overflow
.sum_ready:
    jmp short .round
.subtract_magnitudes:
    shr cl, 1
    db 0x2b, 0xc2 ; sub eax, edx (register destination)
    jae short .check_zero
    inc cl
    neg eax
    jmp short .round
.check_zero:
    db 0xb, 0xc0 ; or eax, eax (register destination)
    jnz short .round
    pop ebx
    pop ecx
    ret
.round:
    add eax, strict dword 0x80
    mov al, 0
    jae short .normalize
    inc ch
    jmp short .pack
.normalize:
    db 0x3, 0xc0 ; add eax, eax (register destination)
    jc short .pack
    dec ch
    jnz short .normalize
    jmp short .underflow
.pack:
    db 0x8a, 0xc5 ; mov al, ch (register destination)
    ror eax, 8
    ror cl, 1
    rcr eax, 1
    pop ebx
    pop ecx
    ret
.underflow:
    pop ebx
    pop ecx
    jmp near float_positive_zero
.overflow:
    pop ebx
    pop ecx
    jmp near float_largest_finite

float_multiply:
    db 0xb, 0xc0 ; or eax, eax (register destination)
    jz short .zero
    db 0xb, 0xd2 ; or edx, edx (register destination)
    jz short .zero
    jnz near .unpack
.zero:
    db 0x2b, 0xc0 ; sub eax, eax (register destination)
    ret
.unpack:
    push ecx
    db 0x3, 0xc0 ; add eax, eax (register destination)
    db 0x13, 0xc9 ; adc ecx, ecx (register destination)
    db 0x3, 0xd2 ; add edx, edx (register destination)
    adc ecx, 0
    ror ecx, 1
    rol eax, 8
    rol edx, 8
    sub al, 0x7f
    sub dl, 0x7f
    db 0x2, 0xd0 ; add dl, al (register destination)
    jno short .check_exponent
    js short .overflow
    jmp short .underflow
.check_exponent:
    cmp dl, 0x81
    jle short .underflow
    add dl, 0x80
    db 0x8a, 0xca ; mov cl, dl (register destination)
    mov al, 0
    mov dl, 0
    stc
    rcr eax, 1
    stc
    rcr edx, 1
    mul edx
    db 0xb, 0xd2 ; or edx, edx (register destination)
    js short .round
    db 0x3, 0xd2 ; add edx, edx (register destination)
    dec cl
.round:
    sar edx, 8
    adc edx, 0
    adc cl, 0
    jz short .overflow
    shl edx, 9
    db 0x8a, 0xd1 ; mov dl, cl (register destination)
    ror edx, 8
    db 0x3, 0xc9 ; add ecx, ecx (register destination)
    rcr edx, 1
    db 0x8b, 0xc2 ; mov eax, edx (register destination)
    pop ecx
    ret
.underflow:
    pop ecx
    jmp near float_positive_zero
.overflow:
    db 0x8b, 0xc1 ; mov eax, ecx (register destination)
    pop ecx
    jmp near float_largest_finite

float_divide:
    db 0x3, 0xd2 ; add edx, edx (register destination)
    jnz short .nonzero_divisor
    jmp near float_largest_finite
.nonzero_divisor:
    push ecx
    db 0x13, 0xc9 ; adc ecx, ecx (register destination)
    db 0x3, 0xc0 ; add eax, eax (register destination)
    jnz short .unpack
    pop ecx
    ret
.unpack:
    adc ecx, 0
    ror ecx, 1
    rol eax, 8
    rol edx, 8
    sub al, 0x7f
    sub dl, 0x7f
    db 0x2a, 0xc2 ; sub al, dl (register destination)
    jno short .check_exponent
    jns short .underflow
    db 0x3, 0xc9 ; add ecx, ecx (register destination)
    rcr eax, 1
    jmp short .overflow
.check_exponent:
    cmp al, 0x81
    jle short .underflow
    add al, 0x7f
    db 0x8a, 0xe8 ; mov ch, al (register destination)
    mov al, 0
    mov dl, 0
    stc
    rcr edx, 1
    stc
    rcr eax, 1
    push ecx
    db 0x8b, 0xca ; mov ecx, edx (register destination)
    db 0x8b, 0xd0 ; mov edx, eax (register destination)
    db 0x2b, 0xc0 ; sub eax, eax (register destination)
    shr edx, 1
    div ecx
    pop ecx
    db 0xb, 0xc0 ; or eax, eax (register destination)
    js short .round
    db 0x3, 0xc0 ; add eax, eax (register destination)
    dec ch
.round:
    sar eax, 8
    adc eax, strict dword 0
    jae short .pack
    inc ch
    jnz short .pack
    db 0x8b, 0xc1 ; mov eax, ecx (register destination)
    jmp short .overflow
.pack:
    shl eax, 9
    db 0x8a, 0xc5 ; mov al, ch (register destination)
    ror eax, 8
    db 0x3, 0xc9 ; add ecx, ecx (register destination)
    rcr eax, 1
    pop ecx
    ret
.underflow:
    pop ecx
    jmp near float_positive_zero
.overflow:
    pop ecx
    jmp near float_largest_finite
