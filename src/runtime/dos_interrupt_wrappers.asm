; Read selectors, dispatch DOS interrupts and wrap runtime I/O.
BITS 32
ORG 0x63072

dispatch_interrupt equ 0x67096
dosret0 equ 0x65711
fputc equ 0x64c57
allocate_stream_buffer equ 0x64932
format_engine equ 0x635bb
flush_stream equ 0x64b31

segread_:
    push edx
    mov edx, eax
    mov eax, cs
    mov word [edx + 2], ax
    mov eax, ds
    mov word [edx + 6], ax
    mov eax, es
    mov word [edx], ax
    mov eax, ss
    mov word [edx + 4], ax
    mov eax, fs
    mov word [edx + 8], ax
    mov eax, gs
    mov word [edx + 0xa], ax
    pop edx
    ret

int386x_:
    push esi
    push edi
    push ebp
    mov ebp, ebx
    mov ebx, ecx
    mov esi, eax
    mov edi, edx
    mov edx, ebp
    call dispatch_interrupt
    mov eax, dword [ebp]
    pop ebp
    pop edi
    pop esi
    ret

int386_:
    push ecx
    sub esp, 0xc
    mov ecx, eax
    mov eax, esp
    call segread_
    mov eax, ecx
    mov ecx, esp
    call int386x_
    add esp, 0xc
    pop ecx
    ret

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

access_:
    push ebx
    push ecx
    mov ebx, edx
    mov edx, eax
    xor eax, eax
    mov ah, 0x43
    int 0x21
    jb short .translate_dos_status
    test bl, 2
    je short .translate_dos_status
    test cl, 1
    je short .translate_dos_status
    mov al, 0
    mov ah, 6
    stc

.translate_dos_status:
    sbb ecx, ecx
    mov cx, ax
    mov eax, ecx
    mov ebx, eax
    mov edx, eax
    and ebx, 0xffff
    shr edx, 0x10
    mov eax, ebx
    call dosret0
    pop ecx
    pop ebx
    ret

stream_format_putc:
    push ebx
    mov ebx, eax
    mov eax, edx
    mov edx, dword [ebx]
    call fputc
    inc dword [ebx + 0x10]
    pop ebx
    ret

stream_format:
    push ecx
    push esi
    push edi
    push ebp
    mov esi, eax
    mov ebp, dword [eax + 0xc]
    mov ah, byte [eax + 0xc]
    mov ecx, dword [esi + 8]
    and ah, 0xcf
    and ebp, 0x30
    mov byte [esi + 0xc], ah
    test ecx, ecx
    jne short .check_buffering_mode
    mov eax, esi
    call allocate_stream_buffer

.check_buffering_mode:
    mov cl, byte [esi + 0xd]
    xor edi, edi
    test cl, 4
    je short .format_into_stream
    mov ch, cl
    and ch, 0xfa
    mov al, ch
    mov byte [esi + 0xd], ch
    or al, 1
    mov edi, 1
    mov byte [esi + 0xd], al

.format_into_stream:
    mov ecx, stream_format_putc - 0x10000
    mov eax, esi
    call format_engine
    mov edx, eax
    test edi, edi
    je short .check_stream_error
    mov ah, byte [esi + 0xd]
    and ah, 0xfa
    mov bl, ah
    mov byte [esi + 0xd], ah
    or bl, 4
    mov eax, esi
    mov byte [esi + 0xd], bl
    call flush_stream

.check_stream_error:
    test byte [esi + 0xc], 0x20
    je short .restore_stream_flags
    mov edx, 0xffffffff

.restore_stream_flags:
    mov edi, dword [esi + 0xc]
    or edi, ebp
    mov eax, edx
    mov dword [esi + 0xc], edi
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
