; Software floating-point conversions and the adjacent result helpers.
BITS 32
ORG 0x73ec4

    times 60 db 0 ; Integer conversion wrappers are supplied by C.

    times 69 db 0 ; Truncation stages are supplied by C.

truncate_float_zero:
    sub eax, eax
    ret

    times 60 db 0 ; Integer-to-float routines are supplied by C.

float_to_double:
    mov edx, eax
    and edx, 0x7fffffff
    jne short .nonzero
    jmp short .done

.nonzero:
    cmp edx, 0x7f800000
    jne short .finite_or_nan
    mov edx, eax
    or edx, 0x7ff00000
    sub eax, eax
    jmp short .done

.finite_or_nan:
    test edx, 0x7f800000
    jnz short .pack
    xor eax, edx
    push ecx
    sub ecx, ecx
.normalize:
    add ecx, 0x800000
    add edx, edx
    test edx, 0x800000
    jz short .normalize
    or eax, edx
    sub edx, ecx
    pop ecx

.pack:
    sar edx, 2
    add eax, eax
    rcr edx, 1
    and eax, 0xe
    ror eax, 4
    add edx, 0x38000000
.done:
    ret
