; Compute the extended square root and provide an in-place polynomial entry.
BITS 32
ORG 0x6aae4

evaluate_polynomial equ 0x6abd0

square_root_extended:
    push edi
    push esi
    push edx
    push ecx
    push ebx
    mov cx, word [eax + 8]
    mov edx, dword [eax + 4]
    mov ebx, dword [eax]
    db 0x0b, 0xdb ; OR EBX, EBX, register-destination encoding.
    jne short .check_special
    db 0x0b, 0xd2 ; OR EDX, EDX, register-destination encoding.
    jne short .check_infinity
    db 0x66, 0x03, 0xc9 ; ADD CX, CX, register-destination encoding.
    je near .return

.set_indefinite:
    mov word [eax + 8], 0xffff
    mov dword [eax + 4], 0
    mov dword [eax], 0

.quiet_result:
    or byte [eax + 7], 0xc0
    jmp near .return

.check_infinity:
    cmp cx, 0x7fff
    je near .return

.check_special:
    db 0x8b, 0xd1 ; MOV EDX, ECX, register-destination encoding.
    and dh, 0x7f
    cmp dx, 0x7fff
    je short .quiet_result
    db 0x66, 0x03, 0xc9 ; ADD CX, CX, register-destination encoding.
    jb short .quiet_result
    shr cx, 1
    je short .normalize_exponent
    mov edx, dword [eax + 4]
    db 0x03, 0xd2 ; ADD EDX, EDX, register-destination encoding.
    jae short .set_indefinite

.normalize_exponent:
    mov edx, dword [eax + 4]
    db 0x2b, 0xff ; SUB EDI, EDI, register-destination encoding.
    push eax
    sub cx, 0x3fff
    sar cx, 1
    jb short .store_exponent
    shr edx, 1
    rcr ebx, 1
    rcr edi, 1

.store_exponent:
    add cx, 0x3fff
    mov word [eax + 8], cx
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    db 0x8b, 0xc3 ; MOV EAX, EBX, register-destination encoding.
    db 0x8b, 0xf2 ; MOV ESI, EDX, register-destination encoding.
    stc
    rcr esi, 1
    inc edx
    je short .check_maximum_estimate
    dec edx

.refine_estimate:
    div esi
    dec esi
    db 0x3b, 0xf0 ; CMP ESI, EAX, register-destination encoding.
    jbe short .divide_low_bits
    inc esi
    db 0x03, 0xf0 ; ADD ESI, EAX, register-destination encoding.
    rcr esi, 1
    db 0x8b, 0xd1 ; MOV EDX, ECX, register-destination encoding.
    db 0x8b, 0xc3 ; MOV EAX, EBX, register-destination encoding.
    jmp short .refine_estimate

.divide_low_bits:
    inc esi
    db 0x8b, 0xc8 ; MOV ECX, EAX, register-destination encoding.
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    div esi
    db 0x03, 0xf1 ; ADD ESI, ECX, register-destination encoding.
    jmp short .combine_quotients

.check_maximum_estimate:
    db 0x3b, 0xc6 ; CMP EAX, ESI, register-destination encoding.
    je short .finish_high_word
    xchg edx, eax
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    div esi

.combine_quotients:
    db 0x2b, 0xd2 ; SUB EDX, EDX, register-destination encoding.
    stc
    rcr esi, 1
    rcr eax, 1
    db 0x13, 0xc2 ; ADC EAX, EDX, register-destination encoding.

.finish_high_word:
    db 0x13, 0xd6 ; ADC EDX, ESI, register-destination encoding.
    pop esi
    mov dword [esi], eax
    mov dword [esi + 4], edx

.return:
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    ret

evaluate_polynomial_in_place:
    push esi
    push ecx
    push eax
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    mov si, word [eax + 8]
    mov edx, dword [eax + 4]
    mov eax, dword [eax]
    call evaluate_polynomial
    pop ecx
    mov dword [ecx], eax
    mov dword [ecx + 4], edx
    mov word [ecx + 8], si
    pop ecx
    pop esi
    ret
