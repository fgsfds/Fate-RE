; Convert the emulator temporary to a 32-bit integer.
BITS 32
ORG 0x69b23

pack_signed_integer:
    push ebx
    mov bl, 0x1f
    jmp short read_sign

pack_unsigned_integer:
    push ebx
    mov bl, 0x20

read_sign:
    mov bh, byte [eax + 9]
    shr bh, 1
    db 0x0a, 0xfb ; OR bh, bl uses the register-destination opcode.
    push ecx
    mov cx, word [eax + 8]
    and cx, 0x7fff
    sub cx, 0x3ffe
    jl short return_zero
    cmp cx, 0x20
    jg short return_indefinite
    and bl, 0x3f
    db 0x3a, 0xcb ; CMP cl, bl uses the register-destination opcode.
    jg short return_indefinite
    db 0x8a, 0xef ; MOV ch, bh uses the register-destination opcode.
    mov ebx, dword [eax]
    mov eax, dword [eax + 4]
    db 0x03, 0xdb ; ADD ebx, ebx uses the register-destination opcode.
    rcr ch, 1
    cmp cl, 0x20
    jne short shift_magnitude
    db 0x02, 0xed ; ADD ch, ch uses the register-destination opcode.
    jmp short round_magnitude

shift_magnitude:
    db 0x2b, 0xdb ; SUB ebx, ebx uses the register-destination opcode.
    shld ebx, eax, cl
    shl eax, cl
    db 0x02, 0xed ; ADD ch, ch uses the register-destination opcode.
    db 0x03, 0xc0 ; ADD eax, eax uses the register-destination opcode.
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.

round_magnitude:
    mov cl, 0xff
    rcr cl, 1
    db 0x22, 0xe9 ; AND ch, cl uses the register-destination opcode.
    db 0x02, 0xed ; ADD ch, ch uses the register-destination opcode.
    adc eax, 0
    db 0x02, 0xed ; ADD ch, ch uses the register-destination opcode.
    jae short return_integer
    neg eax

return_integer:
    pop ecx
    pop ebx
    ret

return_indefinite:
    mov eax, 0x80000000
    pop ecx
    pop ebx
    ret

return_zero:
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    pop ecx
    pop ebx
    ret
