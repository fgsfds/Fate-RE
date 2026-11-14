; Call the mapped driver and copy its interface table into the caller segment.
BITS 32
ORG 0x665e5

copy_far_driver_interface:
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    mov eax, 8
    lfs edi, [ebp + 0x10]
    mov dx, ds
    call far [ebp + 8]
    push ds
    push es
    push ds
    pop es
    mov edi, dword [ebp + 0x18]
    lds esi, [ebp + 0x10]
    db 0x8b, 0xf2 ; MOV ESI, EDX, register-destination encoding.
    mov ecx, 0x6a
    cld
    rep movsb
    pop es
    pop ds
    push ds
    push es
    push ds
    pop es
    mov edi, dword [ebp + 0x18]
    mov ds, [ebp + 0x14]
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x44], ds
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x4c], ds
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x54], ds
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x5c], ds
    pop es
    pop ds
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret
