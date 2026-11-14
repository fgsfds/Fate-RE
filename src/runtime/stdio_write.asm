; Write complete items through binary or text streams.
BITS 32
ORG 0x60944

set_errno equ 0x6468e
allocate_buffer equ 0x64932
qwrite equ 0x62a97
flush_stream equ 0x64b31
fputc equ 0x64c57

fwrite_:
    push esi
    push edi
    push ebp
    sub esp, 0x10
    push eax
    push edx
    mov ebp, ecx
    test byte [ecx + 0xc], 2
    jne short .calculate_request
    mov eax, 4
    call set_errno
    or byte [ecx + 0xc], 0x20
    xor eax, eax
    jmp near .restore_registers

.calculate_request:
    imul ebx, edx
    test ebx, ebx
    jne short .ensure_buffer
    mov eax, ebx
    jmp near .restore_registers

.ensure_buffer:
    cmp dword [ecx + 8], 0
    jne short .save_error_flags
    mov eax, ebp
    call allocate_buffer

.save_error_flags:
    mov eax, dword [ebp + 0xc]
    mov dl, byte [ebp + 0xc]
    xor esi, esi
    and eax, 0x30
    and dl, 0xcf
    mov dword [esp + 0xc], esi
    mov dword [esp + 8], eax
    mov byte [ebp + 0xc], dl
    test dl, 0x40
    je near .start_text_write
    mov dword [esp + 0x10], ebx

.write_binary:
    cmp dword [ebp + 4], 0
    jne short .calculate_buffer_copy
    mov eax, dword [esp + 0x10]
    cmp eax, dword [ebp + 0x14]
    jb short .calculate_buffer_copy
    and ah, 0xfe
    xor al, al
    mov dword [esp + 0x14], eax
    test eax, eax
    jne short .write_descriptor
    mov eax, dword [esp + 0x10]
    mov dword [esp + 0x14], eax

.write_descriptor:
    mov edx, dword [esp + 4]
    mov ebx, dword [esp + 0x14]
    mov eax, dword [ebp + 0x10]
    call qwrite
    cmp eax, -1
    jne short .check_short_write

.mark_write_error:
    or byte [ebp + 0xc], 0x20
    jmp near .advance_binary

.check_short_write:
    cmp eax, dword [esp + 0x14]
    je near .advance_binary
    mov eax, 0xc
    call set_errno
    jmp short .mark_write_error

.calculate_buffer_copy:
    mov eax, dword [ebp + 0x14]
    sub eax, dword [ebp + 4]
    mov ecx, dword [esp + 0x10]
    mov dword [esp + 0x14], eax
    cmp eax, ecx
    jbe short .copy_buffered_bytes
    mov dword [esp + 0x14], ecx

.copy_buffered_bytes:
    mov esi, dword [esp + 4]
    mov ecx, dword [esp + 0x14]
    mov edi, dword [ebp]
    push es
    mov eax, ds
    mov es, eax
    push edi
    mov eax, ecx
    shr ecx, 2
    db 0xf2 ; Original repeat prefix.
    movsd
    db 0x8a, 0xc8 ; MOV CL, AL uses the register-destination opcode.
    and cl, 3
    db 0xf2 ; Original repeat prefix.
    movsb
    pop edi
    pop es
    mov eax, dword [esp + 0x14]
    mov esi, dword [ebp]
    mov edi, dword [ebp + 4]
    add esi, eax
    mov bh, byte [ebp + 0xd]
    mov dword [ebp], esi
    add edi, eax
    mov edx, dword [ebp + 0x14]
    mov dword [ebp + 4], edi
    or bh, 0x10
    mov eax, dword [ebp + 4]
    mov byte [ebp + 0xd], bh
    cmp eax, edx
    je short .flush_binary
    test bh, 4
    je short .advance_binary

.flush_binary:
    mov eax, ebp
    call flush_stream

.advance_binary:
    mov eax, dword [esp + 0x14]
    mov esi, dword [esp + 4]
    mov edi, dword [esp + 0xc]
    mov edx, dword [esp + 0x10]
    add esi, eax
    add edi, eax
    mov dword [esp + 4], esi
    mov dword [esp + 0xc], edi
    sub edx, eax
    mov dword [esp + 0x10], edx
    je near .check_write_error
    test byte [ebp + 0xc], 0x20
    je near .write_binary
    jmp short .check_write_error

.start_text_write:
    mov cl, byte [ebp + 0xd]
    xor edi, edi
    test cl, 4
    je short .write_text_byte
    mov ch, cl
    and ch, 0xfa
    mov al, ch
    mov byte [ebp + 0xd], ch
    or al, 1
    mov edi, 1
    mov byte [ebp + 0xd], al

.write_text_byte:
    mov edx, dword [esp + 4]
    xor eax, eax
    mov al, byte [edx]
    inc edx
    mov dword [esp + 4], edx
    mov edx, ebp
    call fputc
    test byte [ebp + 0xc], 0x30
    jne short .restore_text_buffering
    mov ecx, dword [esp + 0xc]
    inc ecx
    mov dword [esp + 0xc], ecx
    cmp ebx, ecx
    jne short .write_text_byte

.restore_text_buffering:
    test edi, edi
    je short .check_write_error
    mov dh, byte [ebp + 0xd]
    and dh, 0xfa
    mov bl, dh
    mov byte [ebp + 0xd], dh
    or bl, 4
    mov eax, ebp
    mov byte [ebp + 0xd], bl
    call flush_stream

.check_write_error:
    test byte [ebp + 0xc], 0x20
    je short .count_complete_items
    xor ecx, ecx
    mov dword [esp + 0xc], ecx

.count_complete_items:
    mov eax, dword [esp + 8]
    mov edi, dword [esp]
    mov esi, dword [ebp + 0xc]
    xor edx, edx
    or esi, eax
    mov eax, dword [esp + 0xc]
    mov dword [ebp + 0xc], esi
    div edi

.restore_registers:
    add esp, 0x18
    pop ebp
    pop edi
    pop esi
    ret
