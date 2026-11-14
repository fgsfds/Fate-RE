; Pack the emulator significand and exponent into IEEE binary32 or binary64.
BITS 32
ORG 0x69c58

signal_x87_exception equ 0x68060

pack_single:
    push edx
    push ecx
    push ebx
    db 0x8b, 0xd8 ; MOV ebx, eax uses the register-destination opcode.
    mov edx, 0xffffff00
    mov eax, dword [ebx + 4]
    db 0x8b, 0xc8 ; MOV ecx, eax uses the register-destination opcode.
    shl ecx, 0x19
    mov cx, word [ebx + 8]
    jae short apply_single_mask
    jne short round_single_up
    cmp dword [ebx], 0
    jne short round_single_up
    db 0x03, 0xd2 ; ADD edx, edx uses the register-destination opcode.

round_single_up:
    add eax, 0x100
    jae short apply_single_mask
    mov eax, 0x80000000
    inc cx

apply_single_mask:
    db 0x23, 0xc2 ; AND eax, edx uses the register-destination opcode.
    db 0x8b, 0xd9 ; MOV ebx, ecx uses the register-destination opcode.
    and cx, 0x7fff
    je short return_single
    cmp cx, 0x7fff
    jne short rebase_single_exponent
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    shr eax, 8
    or eax, 0xff000000
    db 0x66, 0x03, 0xdb ; ADD bx, bx uses the register-destination opcode.
    rcr eax, 1
    jmp short return_single

rebase_single_exponent:
    add cx, 0xc080
    jns short check_single_overflow
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    jmp short return_single

check_single_overflow:
    cmp cx, strict word 0xff
    jl short assemble_finite_single
    mov eax, 0xff000000
    db 0x66, 0x03, 0xdb ; ADD bx, bx uses the register-destination opcode.
    rcr eax, 1
    jmp short return_single

assemble_finite_single:
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    shrd eax, ecx, 8
    db 0x66, 0x03, 0xdb ; ADD bx, bx uses the register-destination opcode.
    rcr eax, 1

return_single:
    pop ebx
    pop ecx
    pop edx
    ret

pack_double:
    push ecx
    push ebx
    push esi
    mov cx, word [eax + 8]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    mov esi, 0xfffff800
    db 0x8b, 0xd8 ; MOV ebx, eax uses the register-destination opcode.
    shl ebx, 0x16
    jae short apply_double_mask
    jne short round_double_up
    db 0x03, 0xf6 ; ADD esi, esi uses the register-destination opcode.

round_double_up:
    add eax, 0x800
    adc edx, 0
    jae short apply_double_mask
    mov edx, 0x80000000
    inc cx

apply_double_mask:
    db 0x23, 0xc6 ; AND eax, esi uses the register-destination opcode.
    db 0x8b, 0xd9 ; MOV ebx, ecx uses the register-destination opcode.
    and cx, 0x7fff
    add cx, 0xc400
    cmp cx, strict word 0x7ff
    jae short check_double_range
    db 0x66, 0x0b, 0xc9 ; OR cx, cx uses the register-destination opcode.
    jne short assemble_normal_double
    shrd eax, edx, 0xc
    db 0x03, 0xd2 ; ADD edx, edx uses the register-destination opcode.
    shr edx, 0xc
    jmp short apply_double_sign

assemble_normal_double:
    shrd eax, edx, 0xb
    db 0x03, 0xd2 ; ADD edx, edx uses the register-destination opcode.
    shrd edx, ecx, 0xb

apply_double_sign:
    db 0x66, 0x03, 0xdb ; ADD bx, bx uses the register-destination opcode.
    rcr edx, 1
    jmp short return_double

check_double_range:
    cmp cx, 0xc400
    jb short assemble_special_double
    cmp cx, -0x34
    jl short underflow_to_zero
    sub cx, 0xc
    neg cx
    cmp cl, 0x20
    jb short shift_denormal_double
    sub cl, 0x20
    db 0x8b, 0xf0 ; MOV esi, eax uses the register-destination opcode.
    db 0x8b, 0xc2 ; MOV eax, edx uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.

shift_denormal_double:
    shrd esi, eax, cl
    shrd eax, edx, cl
    shr edx, cl
    db 0x03, 0xf6 ; ADD esi, esi uses the register-destination opcode.
    adc eax, 0
    adc edx, 0
    jmp short finish_underflow

underflow_to_zero:
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    db 0x2b, 0xd2 ; SUB edx, edx uses the register-destination opcode.

finish_underflow:
    jmp short return_double

assemble_special_double:
    shrd eax, edx, 0xb
    db 0x03, 0xd2 ; ADD edx, edx uses the register-destination opcode.
    shr edx, 0xb
    db 0x66, 0x03, 0xdb ; ADD bx, bx uses the register-destination opcode.
    rcr edx, 1
    or edx, 0x7ff00000
    cmp cx, 0x43ff
    je short return_double
    push eax
    mov al, 8
    mov ah, 0x84
    call signal_x87_exception
    pop eax

return_double:
    pop esi
    pop ebx
    pop ecx
    ret
