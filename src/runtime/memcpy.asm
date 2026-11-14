; Independently reconstructed Watcom-register-ABI memcpy from pinned FATE.
; No historical library object bytes are included in the output source.
; EAX destination, EDX source, EBX unsigned byte count; EAX returns destination.
; Caller supplies valid disjoint buffers and a clear direction flag.
BITS 32
memcpy_:
    push ecx
    push esi
    push edi
    mov edi, eax
    mov esi, edx
    mov ecx, ebx
    push es
    mov eax, ds
    mov es, eax
    push edi
    mov eax, ecx
    shr ecx, 2
    repne movsd
    ; MOV r8,r/m8 form: opcode 8A, register CL=1, source AL=0.
    ; NASM otherwise selects the equivalent opposite-direction opcode 88.
    db 0x8a, 0xc0 | (1 << 3) | 0
    and cl, 3
    repne movsb
    pop edi
    pop es
    mov eax, edi
    pop edi
    pop esi
    pop ecx
    ret
