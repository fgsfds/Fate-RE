; Detect terminal buffering and allocate the stream buffer with an inline fallback.
BITS 32
ORG 0x64901

malloc_ equ 0x6126d
isatty_ equ 0x656f3

detect_terminal:
    push ebx
    push ecx
    push edx
    mov edx, eax
    test byte [eax + 0xd], 0x20
    jne short .return
    mov eax, dword [edx + 0x10]
    call isatty_
    test eax, eax
    je short .return
    mov bl, byte [edx + 0xd]
    or bl, 0x20
    mov byte [edx + 0xd], bl
    test bl, 7
    jne short .return
    mov cl, bl
    or cl, 2
    mov byte [edx + 0xd], cl

.return:
    pop edx
    pop ecx
    pop ebx
    ret

allocate_stream_buffer:
    push ecx
    push edx
    mov edx, eax
    call detect_terminal
    cmp dword [edx + 0x14], 0
    jne short .allocate
    mov ah, byte [edx + 0xd]
    test ah, 2
    je short .check_unbuffered
    mov dword [edx + 0x14], 0x86
    jmp short .allocate

.check_unbuffered:
    test ah, 4
    je short .set_full_size
    mov dword [edx + 0x14], 1
    jmp short .allocate

.set_full_size:
    mov dword [edx + 0x14], 0x1000

.allocate:
    mov eax, dword [edx + 0x14]
    call malloc_
    mov dword [edx + 8], eax
    test eax, eax
    jne short .mark_owned
    lea eax, [edx + 0x18]
    mov cl, byte [edx + 0xd]
    mov dword [edx + 0x14], 1
    and cl, 0xf8
    mov dword [edx + 8], eax
    mov ch, cl
    mov byte [edx + 0xd], cl
    or ch, 4
    mov byte [edx + 0xd], ch
    jmp short .reset_buffer

.mark_owned:
    or byte [edx + 0xc], 8

.reset_buffer:
    mov eax, dword [edx + 8]
    mov dword [edx + 4], 0
    mov dword [edx], eax
    pop edx
    pop ecx
    ret
