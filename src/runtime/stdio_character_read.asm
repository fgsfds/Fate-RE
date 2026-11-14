; Read through the stream buffer with DOS refill and text-mode handling.
BITS 32
ORG 0x649a9

flush_matching_streams equ 0x62e88
set_errno equ 0x6468e
allocate_stream_buffer equ 0x64932
set_dos_errno equ 0x6571d
read_console_character equ 0x6aea1

read_descriptor_raw:
    push ecx
    mov ecx, ebx
    mov ebx, eax
    mov ah, 0x3f
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov edx, eax
    test eax, eax
    jge short .return
    and eax, 0xffff
    call set_dos_errno

.return:
    pop ecx
    ret

fgetc_:
    push ebx
    push ecx
    push edx
    push esi
    mov edx, eax
    test byte [eax + 0xc], 1
    jne short .read_first
    mov eax, 4
    call set_errno
    mov bl, byte [edx + 0xc]
    or bl, 0x20
    mov eax, 0xffffffff
    mov byte [edx + 0xc], bl
    jmp short .check_text

.read_first:
    mov ebx, dword [edx + 4]
    dec ebx
    mov dword [edx + 4], ebx
    test ebx, ebx
    jge short .first_buffered_byte
    mov eax, edx
    call refill_and_get_character
    jmp short .check_text

.first_buffered_byte:
    mov ebx, dword [edx]
    mov al, byte [ebx]
    inc ebx
    and eax, 0xff
    mov dword [edx], ebx

.check_text:
    test byte [edx + 0xc], 0x40
    jne short .return
    cmp eax, 0xd
    jne short .check_text_eof
    mov esi, dword [edx + 4]
    dec esi
    mov dword [edx + 4], esi
    test esi, esi
    jge short .next_buffered_byte
    mov eax, edx
    call refill_and_get_character
    jmp short .check_text_eof

.next_buffered_byte:
    mov ebx, dword [edx]
    mov al, byte [ebx]
    inc ebx
    and eax, 0xff
    mov dword [edx], ebx

.check_text_eof:
    cmp eax, 0x1a
    jne short .return
    mov cl, byte [edx + 0xc]
    or cl, 0x10
    mov eax, 0xffffffff
    mov byte [edx + 0xc], cl

.return:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

refill_and_get_character:
    push ebx
    push ecx
    push edx
    mov edx, eax
    call fill_buffer
    test eax, eax
    jne short .consume_byte
    mov eax, 0xffffffff
    pop edx
    pop ecx
    pop ebx
    ret

.consume_byte:
    mov ebx, dword [edx + 4]
    mov ecx, dword [edx]
    dec ebx
    inc ecx
    mov dword [edx + 4], ebx
    mov dword [edx], ecx
    mov al, byte [ecx - 1]
    and eax, 0xff
    pop edx
    pop ecx
    pop ebx
    ret

fill_buffer:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    cmp dword [eax + 8], 0
    jne short .check_terminal
    call allocate_stream_buffer

.check_terminal:
    mov ah, byte [ecx + 0xd]
    test ah, 0x20
    je short .reset_buffer
    test ah, 6
    je short .reset_buffer
    mov eax, 0x2000
    call flush_matching_streams

.reset_buffer:
    mov edx, dword [ecx + 0xc]
    mov bl, byte [ecx + 0xc]
    mov eax, dword [ecx + 8]
    and bl, 0xfb
    mov dword [ecx], eax
    and edx, 0x2400
    mov byte [ecx + 0xc], bl
    cmp edx, 0x2400
    jne short .read_descriptor
    mov ebx, dword [ecx + 0x10]
    test ebx, ebx
    jne short .read_descriptor
    mov dword [ecx + 4], ebx
    call read_console_character
    cmp eax, -1
    je short .check_count
    mov ebx, dword [ecx]
    mov byte [ebx], al
    mov dword [ecx + 4], 1
    jmp short .check_count

.read_descriptor:
    test byte [ecx + 0xd], 4
    je short .use_capacity
    mov ebx, 1
    jmp short .read_bytes

.use_capacity:
    mov ebx, dword [ecx + 0x14]

.read_bytes:
    mov edx, dword [ecx]
    mov eax, dword [ecx + 0x10]
    call read_descriptor_raw
    mov dword [ecx + 4], eax

.check_count:
    mov esi, dword [ecx + 4]
    test esi, esi
    jg short .return
    jne short .mark_error
    or byte [ecx + 0xc], 0x10
    jmp short .return

.mark_error:
    mov al, byte [ecx + 0xc]
    mov dword [ecx + 4], 0
    or al, 0x20
    mov byte [ecx + 0xc], al

.return:
    mov eax, dword [ecx + 4]
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
