; Approximate the signed square root with the x87 exponent and a lookup table.
BITS 32
ORG 0x4ca6e

sqrt_lookup equ 0x1d3160
sqrt_float_bits equ 0x286b20

nsqrt:
    push ebx
    push ecx
    mov [sqrt_float_bits], eax
    fild dword [sqrt_float_bits]
    add eax, eax
    fstp dword [sqrt_float_bits]
    sbb ebx, ebx
    mov eax, [sqrt_float_bits]
    mov ecx, eax
    and eax, strict dword 0x7ff000
    shr eax, byte 0xa
    sub ecx, strict dword 0x3f800000
    shr ecx, byte 0x17
    mov eax, [eax + sqrt_lookup]
    sar eax, cl
    xor eax, ebx
    pop ecx
    pop ebx
    ret
