; Expand signed integers and binary64 operands into the x87 emulator format.
BITS 32
ORG 0x69b92

signal_exception equ 0x68060

extend_integer:
    push ebx
    db 0x8b, 0xda ; MOV ebx, edx uses the register-destination opcode.
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jns short positive_integer
    neg eax
    mov edx, 0xbfff
    jmp short normalize_integer

positive_integer:
    pop ebx
    push ebx
    db 0x8b, 0xda ; MOV ebx, edx uses the register-destination opcode.
    mov edx, 0x3fff

normalize_integer:
    push ecx
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    je short zero_integer
    bsr ecx, eax
    db 0x8a, 0xe9 ; MOV ch, cl uses the register-destination opcode.
    mov cl, 0x1f
    db 0x2a, 0xcd ; SUB cl, ch uses the register-destination opcode.
    shl eax, cl
    db 0x8a, 0xcd ; MOV cl, ch uses the register-destination opcode.
    movzx ecx, ch
    db 0x03, 0xca ; ADD ecx, edx uses the register-destination opcode.
    db 0x8b, 0xd0 ; MOV edx, eax uses the register-destination opcode.
    jmp short store_integer

zero_integer:
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.
    db 0x2b, 0xc9 ; SUB ecx, ecx uses the register-destination opcode.

store_integer:
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    mov dword [ebx], eax
    mov dword [ebx + 4], edx
    mov word [ebx + 8], cx
    pop ecx
    pop ebx
    ret

extend_double:
    push ecx
    db 0x8b, 0xca ; MOV ecx, edx uses the register-destination opcode.
    shld edx, eax, 0xb
    shl eax, 0xb
    sar ecx, 0x14
    and cx, 0x7ff
    je short check_denormal
    cmp cx, 0x7ff
    je short special_double
    add cx, 0x3c00
    jmp short set_explicit_bit

special_double:
    mov cx, 0x7fff
    test edx, strict dword 0x7fffffff
    jne short check_nan
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.

check_nan:
    je short set_explicit_bit
    push eax
    mov al, 1
    mov ah, 0x81
    call signal_exception
    pop eax
    or edx, 0x40000000

set_explicit_bit:
    or edx, 0x80000000
    jmp short store_double

check_denormal:
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    jne short normalize_denormal
    db 0x0b, 0xc0 ; OR eax, eax uses the register-destination opcode.
    jne short normalize_denormal
    db 0x2b, 0xc9 ; SUB ecx, ecx uses the register-destination opcode.
    jmp short store_double

normalize_denormal:
    mov cx, 0x3c01
    db 0x0b, 0xd2 ; OR EDX, EDX uses the register-destination opcode.
    jne short normalize_significand
    xchg edx, eax
    sub cx, 0x20

normalize_significand:
    db 0x0b, 0xd2 ; OR edx, edx uses the register-destination opcode.
    js short store_double
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    db 0x13, 0xd2 ; ADC edx, edx uses the register-destination opcode.
    dec cx
    jmp short normalize_significand

store_double:
    mov dword [ebx], eax
    mov dword [ebx + 4], edx
    db 0x03, 0xc9 ; ADD ecx, ecx uses the register-destination opcode.
    rcr cx, 1
    mov word [ebx + 8], cx
    pop ecx
    ret
