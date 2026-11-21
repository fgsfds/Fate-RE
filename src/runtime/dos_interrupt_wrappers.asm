; Read selectors, dispatch DOS interrupts and wrap runtime I/O.
BITS 32
ORG 0x63072

dosret0 equ 0x65711

segread_:
    times 40 db 0 ; supplied by C

    times 52 db 0 ; int386x and int386 are supplied by C

far_memmove:
    push esi
    push edi
    push es
    push fs
    push edx
    mov esi, ecx
    mov ecx, dword [esp + 0x18]
    mov edx, eax
    mov eax, ebx
    cmp ebx, edx
    jne short .check_overlap
    cmp si, word [esp]
    je short .return_destination

.check_overlap:
    cmp eax, edx
    jae short .copy_forward
    lea edi, [eax + ecx]
    cmp edi, edx
    jbe short .copy_forward
    mov fs, word [esp]
    mov es, esi
    mov eax, edi
    add edx, ecx

.check_backward_count:
    test ecx, ecx
    je short .return_destination
    dec eax
    dec edx
    mov bl, byte es:[eax]
    dec ecx
    mov byte fs:[edx], bl
    jmp short .check_backward_count

.copy_forward:
    mov es, word [esp]
    mov edi, edx
    push ds
    xchg eax, esi
    mov ds, eax
    shr ecx, 1
    db 0x66 ; Operand-size prefix precedes REP.
    rep movsd
    adc ecx, ecx
    rep movsb
    pop ds

.return_destination:
    mov ebx, dword [esp]
    mov eax, edx
    mov edx, ebx
    add esp, 4
    pop fs
    pop es
    pop edi
    pop esi
    ret 4

access_ equ 0x63130
    times 59 db 0    ; access_ is supplied by C.

    times 17 db 0    ; stream_format_putc is supplied by C.

    times 133 db 0    ; The stream formatter is supplied by C.
