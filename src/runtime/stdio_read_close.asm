; Read buffered streams and close stream resources.
BITS 32
ORG 0x60638

set_errno equ 0x6468e
allocate_buffer equ 0x64932
qread equ 0x649a9
fill_buffer equ 0x64a80

fread_:
    push esi
    push edi
    push ebp
    sub esp, 8
    push eax
    push edx
    mov ebp, ecx
    test byte [ecx + 0xc], 1
    jne short .calculate_request
    mov eax, 4
    call set_errno
    mov dh, byte [ecx + 0xc]
    or dh, 0x20
    xor eax, eax
    mov byte [ecx + 0xc], dh
    jmp near .restore_read_registers

.calculate_request:
    imul ebx, edx
    test ebx, ebx
    jne short .ensure_buffer
    mov eax, ebx
    jmp near .restore_read_registers

.ensure_buffer:
    cmp dword [ecx + 8], 0
    jne short .select_translation
    mov eax, ebp
    call allocate_buffer

.select_translation:
    xor esi, esi
    mov dl, byte [ebp + 0xc]
    mov dword [esp + 0xc], esi
    test dl, 0x40
    je near .start_text_read
    mov dword [esp + 8], ebx

.read_binary:
    mov edx, dword [ebp + 4]
    test edx, edx
    je short .check_binary_remaining
    mov ebx, dword [esp + 8]
    cmp edx, ebx
    jbe short .copy_buffered_bytes
    mov edx, ebx

.copy_buffered_bytes:
    mov edi, dword [esp + 4]
    mov ecx, edx
    mov esi, dword [ebp]
    mov ebx, dword [esp + 0xc]
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
    mov eax, dword [esp + 8]
    mov ecx, dword [ebp]
    lea esi, [edi + edx]
    add ebx, edx
    mov dword [esp + 4], esi
    mov dword [esp + 0xc], ebx
    mov edi, dword [ebp + 4]
    add ecx, edx
    sub eax, edx
    sub edi, edx
    mov dword [ebp], ecx
    mov dword [esp + 8], eax
    mov dword [ebp + 4], edi

.check_binary_remaining:
    mov ecx, dword [esp + 8]
    test ecx, ecx
    je near .count_complete_items
    cmp ecx, dword [ebp + 0x14]
    jae short .check_direct_read_size
    test byte [ebp + 0xd], 4
    je short .refill_binary

.check_direct_read_size:
    mov cl, byte [ebp + 0xd]
    mov ebx, dword [esp + 8]
    test cl, 4
    jne short .read_descriptor
    cmp ebx, 0x200
    jbe short .read_descriptor
    and bh, 0xfe
    xor bl, bl

.read_descriptor:
    mov edx, dword [esp + 4]
    mov eax, dword [ebp + 0x10]
    call qread
    cmp eax, -1
    jne short .check_descriptor_eof
    or byte [ebp + 0xc], 0x20
    jmp near .count_complete_items

.check_descriptor_eof:
    test eax, eax
    jne short .advance_direct_read

.mark_eof:
    or byte [ebp + 0xc], 0x10
    jmp near .count_complete_items

.advance_direct_read:
    mov edx, dword [esp + 4]
    mov ebx, dword [esp + 8]
    mov ecx, dword [esp + 0xc]
    add edx, eax
    sub ebx, eax
    add ecx, eax
    mov dword [esp + 4], edx
    mov dword [esp + 8], ebx
    mov dword [esp + 0xc], ecx
    jmp near .read_binary

.refill_binary:
    mov eax, ebp
    call fill_buffer
    test eax, eax
    je near .count_complete_items
    jmp near .read_binary

.start_text_read:
    mov edx, dword [esp + 4]
    add ebx, edx

.read_text:
    cmp dword [ebp + 4], 0
    jne short .take_text_byte
    mov eax, ebp
    call fill_buffer
    test eax, eax
    je short .count_complete_items

.take_text_byte:
    mov ecx, dword [ebp + 4]
    mov eax, dword [ebp]
    dec ecx
    lea esi, [eax + 1]
    mov dword [ebp + 4], ecx
    mov dword [ebp], esi
    mov al, byte [eax]
    and eax, 0xff
    cmp eax, 0xd
    jne short .check_dos_eof_marker
    cmp dword [ebp + 4], 0
    jne short .take_byte_after_cr
    mov eax, ebp
    call fill_buffer
    test eax, eax
    je short .count_complete_items

.take_byte_after_cr:
    mov edi, dword [ebp + 4]
    mov eax, dword [ebp]
    dec edi
    lea esi, [eax + 1]
    mov dword [ebp + 4], edi
    mov dword [ebp], esi
    mov al, byte [eax]
    and eax, 0xff

.check_dos_eof_marker:
    cmp eax, 0x1a
    je near .mark_eof
    mov byte [edx], al
    mov eax, dword [esp + 0xc]
    inc eax
    inc edx
    mov dword [esp + 0xc], eax
    cmp edx, ebx
    jne short .read_text

.count_complete_items:
    mov eax, dword [esp + 0xc]
    mov esi, dword [esp]
    xor edx, edx
    div esi

.restore_read_registers:
    add esp, 0x10
    pop ebp
    pop edi
    pop esi
    ret

    times 47 db 0    ; fclose is supplied by C.
    times 21 db 0    ; __shutdown_stream is supplied by C.

    times 12 db 0    ; hex_digit is placed here from C.

    times 105 db 0    ; __MkTmpFile is supplied by C.

    times 137 db 0    ; __doclose is supplied by C.
