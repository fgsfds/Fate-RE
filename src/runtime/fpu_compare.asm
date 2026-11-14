; Compare extended operands and return the emulator condition index.
BITS 32
ORG 0x6973a


compare_extended:
    push edi
    push esi
    mov si, word [eax + 8]
    or si, 0x8000
    inc si
    jne short check_right_nan
    mov esi, dword [eax + 4]
    db 0x03, 0xf6 ; ADD esi, esi uses the register-destination opcode.
    or esi, dword [eax]
    jne short return_unordered

check_right_nan:
    mov si, word [edx + 8]
    or si, 0x8000
    inc si
    jne short compare_signs
    mov esi, dword [edx + 4]
    db 0x03, 0xf6 ; ADD esi, esi uses the register-destination opcode.
    or esi, dword [edx]
    jne short return_unordered

compare_signs:
    mov esi, dword [eax + 6]
    mov edi, dword [edx + 6]
    db 0x33, 0xfe ; XOR edi, esi uses the register-destination opcode.
    mov edi, 0
    js short compare_opposite_signs
    mov si, word [eax + 8]
    cmp si, word [edx + 8]
    jne short compare_magnitudes
    mov edi, dword [eax + 4]
    cmp edi, dword [edx + 4]
    jne short compare_magnitudes
    mov edi, dword [eax]
    cmp edi, dword [edx]

compare_magnitudes:
    mov edi, 0
    je short return_order
    rcr eax, 1
    db 0x33, 0xf0 ; XOR esi, eax uses the register-destination opcode.

signed_order:
    db 0x03, 0xf6 ; ADD esi, esi uses the register-destination opcode.
    sbb edi, 0
    db 0x03, 0xff ; ADD edi, edi uses the register-destination opcode.
    inc edi

return_order:
    db 0x8b, 0xc7 ; MOV eax, edi uses the register-destination opcode.
    pop esi
    pop edi
    ret

return_unordered:
    mov eax, 2
    pop esi
    pop edi
    ret

compare_opposite_signs:
    or edi, dword [eax]
    or edi, dword [edx]
    or edi, dword [eax + 4]
    or edi, dword [edx + 4]
    mov ax, word [eax + 8]
    shl eax, 0x10
    mov ax, word [edx + 8]
    and eax, 0x7fff7fff
    db 0x0b, 0xc7 ; OR eax, edi uses the register-destination opcode.
    mov edi, 0
    jne short signed_order
    pop esi
    pop edi
    ret
