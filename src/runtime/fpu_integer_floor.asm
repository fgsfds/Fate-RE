; Alternate integer packing entry and signed floor conversion.
BITS 32
ORG 0x69ace

pack_integer_sign equ 0x69b2b

pack_integer_with_sign_flag:
    push ebx
    mov bl, 0xa0
    jmp short pack_integer_sign

floor_extended_to_int32:
    push ebx
    mov bh, [eax + 9]
    push ecx
    mov cx, [eax + 8]
    and cx, 0x7fff
    jne short .rebase_exponent
    db 0x2b, 0xc0 ; SUB EAX, EAX, register-destination encoding.
    jmp short .return

.rebase_exponent:
    sub cx, 0x3ffe
    jg short .check_range
    db 0x02, 0xff ; ADD BH, BH, register-destination encoding.
    db 0x1b, 0xc0 ; SBB EAX, EAX, register-destination encoding.
    jmp short .return

.check_range:
    cmp cx, 31
    jle short .extract_integer
    mov eax, 0x80000000
    jmp short .return

.extract_integer:
    db 0x8a, 0xef ; MOV CH, BH, register-destination encoding.
    mov ebx, [eax]
    mov eax, [eax + 4]
    push edx
    db 0x2b, 0xd2 ; SUB EDX, EDX, register-destination encoding.
    shld edx, eax, cl
    shl eax, cl
    db 0x0b, 0xd8 ; OR EBX, EAX, register-destination encoding.
    db 0x8b, 0xc2 ; MOV EAX, EDX, register-destination encoding.
    pop edx
    db 0x02, 0xed ; ADD CH, CH, register-destination encoding.
    jae short .return
    db 0x0b, 0xdb ; OR EBX, EBX, register-destination encoding.
    je short .negate
    inc eax
.negate:
    neg eax
.return:
    pop ecx
    pop ebx
    ret
