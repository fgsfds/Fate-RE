; Software floating-point conversions and the adjacent result helpers.
BITS 32
ORG 0x73ec4

    times 60 db 0 ; Integer conversion wrappers are supplied by C.

    times 69 db 0 ; Truncation stages are supplied by C.

truncate_float_zero:
    sub eax, eax
    ret

    times 60 db 0 ; Integer-to-float routines are supplied by C.
    times 86 db 0 ; Float widening is supplied by C.
