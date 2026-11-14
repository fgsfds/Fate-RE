; Reduce the tangent ratio, evaluate its arctangent and restore the original sign.
BITS 32
ORG 0x6a0a6

divide_significands equ 0x697fd
add_significands equ 0x695ce
multiply_significands equ 0x699d2
add_extended_stack equ 0x6959e
evaluate_odd_polynomial equ 0x6ac22
atan_coefficients_code_offset equ 0x69f96 - 0x10000

reduced_arctangent:
    push edi
    push esi
    push ecx
    db 0x8b, 0xf8 ; MOV EDI, EAX, register-destination encoding.
    mov ch, 0
    mov cl, byte [edi + 9]
    and byte [edi + 9], 0x7f
    cmp word [edi + 8], 0x3fff
    jne short .reduce_ratio
    cmp dword [edi + 4], 0x80000000
    jne short .reduce_ratio
    cmp dword [edi], 0
    jne short .reduce_ratio
    mov dword [edi], 0x2168c235
    mov dword [edi + 4], 0xc90fdaa2
    mov ax, 0x3ffe
    and cl, 0x80
    db 0x0a, 0xe1 ; OR AH, CL, register-destination encoding.
    mov word [edi + 8], ax
    pop ecx
    pop esi
    pop edi
    ret

.reduce_ratio:
    push edx
    push ebx
    cmp word [edi + 8], 0x3fff
    jl short .compare_threshold
    push ecx
    mov si, word [edi + 8]
    mov ecx, dword [edi + 4]
    mov ebx, dword [edi]
    shl esi, 0x10
    mov si, 0x3fff
    mov edx, 0x80000000
    mov eax, 0
    call divide_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    pop ecx
    mov ch, 2

.compare_threshold:
    mov ax, word [edi + 8]
    cmp ax, 0x3ffd
    jne short .check_transform
    mov eax, dword [edi + 4]
    cmp eax, 0x8930a2f4
    jne short .check_transform
    mov eax, dword [edi]
    cmp eax, 0xf66ab09b

.check_transform:
    jbe short .evaluate
    push ecx
    mov ebx, 0xc265539e
    mov ecx, 0xddb3d742
    mov esi, 0x3fff0000
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    call add_significands
    push eax
    push edx
    push esi
    mov ebx, 0xc265539e
    mov ecx, 0xddb3d742
    mov esi, 0x3fff0000
    mov eax, dword [edi]
    mov edx, dword [edi + 4]
    mov si, word [edi + 8]
    call multiply_significands
    db 0x2b, 0xdb ; SUB EBX, EBX, register-destination encoding.
    mov ecx, 0x80000000
    rol esi, 0x10
    mov si, 0xbfff
    rol esi, 0x10
    call add_significands
    pop ebx
    shl ebx, 0x10
    db 0x66, 0x8b, 0xde ; MOV BX, SI, register-destination encoding.
    db 0x8b, 0xf3 ; MOV ESI, EBX, register-destination encoding.
    pop ecx
    pop ebx
    call divide_significands
    mov dword [edi], eax
    mov dword [edi + 4], edx
    mov word [edi + 8], si
    pop ecx
    or ch, 1

.evaluate:
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    lea edx, [atan_coefficients_code_offset]
    mov ebx, 8
    call evaluate_odd_polynomial
    shr ch, 1
    jae short .correct_reciprocal
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    push strict dword 0x3ffe
    push strict dword 0x860a91c1
    push strict dword 0x6b9b2c23
    db 0x8b, 0xdf ; MOV EBX, EDI, register-destination encoding.
    call add_extended_stack

.correct_reciprocal:
    shr ch, 1
    jae short .restore_sign
    push strict dword 0xbfff
    push strict dword 0xc90fdaa2
    push strict dword 0x2168c235
    db 0x8b, 0xc7 ; MOV EAX, EDI, register-destination encoding.
    db 0x8b, 0xdf ; MOV EBX, EDI, register-destination encoding.
    call add_extended_stack
    xor byte [ebx + 9], 0x80

.restore_sign:
    cmp cl, 0
    jns short .return
    xor byte [edi + 9], 0x80

.return:
    pop ebx
    pop edx
    pop ecx
    pop esi
    pop edi
    ret
