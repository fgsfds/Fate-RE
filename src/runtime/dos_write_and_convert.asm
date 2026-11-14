; Write DOS descriptors and provide integer conversion and overlapping memory copy.
BITS 32
ORG 0x62a97

character_types equ 0x1f20
get_io_mode equ 0x65783
set_errno equ 0x6468e
set_dos_errno equ 0x6571d
stackavail equ 0x67006
report_stack_overflow equ 0x67049

write_:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, 0x18
    push eax
    push edx
    push ebx
    call get_io_mode
    mov edx, eax
    mov dword [ebp - 0x18], eax
    test eax, eax
    jne short .check_write_access
    mov eax, 4

.report_mode_error:
    call set_errno
    mov eax, 0xffffffff
    jmp near .restore_registers

.check_write_access:
    test al, 2
    jne short .check_append
    mov eax, 6
    jmp short .report_mode_error

.check_append:
    test al, 0x80
    je short .select_translation
    mov ebx, dword [ebp - 0x1c]
    xor edx, eax
    mov al, 2
    mov ah, 0x42
    mov ecx, edx
    shr ecx, 0x10
    int 0x21
    rcl dx, 1
    ror dx, 1
    shl edx, 0x10
    mov dx, ax
    mov dword [ebp - 0x10], edx
    test edx, edx
    jge short .select_translation

.report_dos_error:
    xor eax, eax
    mov ax, word [ebp - 0x10]
    call set_dos_errno
    jmp near .restore_registers

.select_translation:
    test byte [ebp - 0x18], 0x40
    je short .prepare_text_buffer
    mov ebx, dword [ebp - 0x1c]
    mov edx, dword [ebp - 0x20]
    mov ecx, dword [ebp - 0x24]
    mov ah, 0x40
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov edx, eax
    mov dword [ebp - 0x10], eax
    test eax, eax
    jl short .report_dos_error
    cmp eax, dword [ebp - 0x24]
    je near .return_count
    mov eax, 0xc
    call set_errno
    mov dword [ebp - 0x24], edx
    jmp near .return_count

.prepare_text_buffer:
    call stackavail
    mov edx, eax
    cmp eax, 0xb0
    jae short .select_buffer_size
    call report_stack_overflow

.select_buffer_size:
    mov edi, 0x200
    cmp edx, 0x230
    jae short .allocate_text_buffer
    mov edi, 0x80

.allocate_text_buffer:
    lea eax, [edi + 3]
    xor edx, edx
    and al, 0xfc
    xor esi, esi
    sub esp, eax
    mov dword [ebp - 4], edx
    mov dword [ebp - 0x14], edx
    mov eax, dword [ebp - 0x20]
    mov dword [ebp - 8], esp
    mov dword [ebp - 0xc], eax

.check_source_end:
    mov eax, dword [ebp - 4]
    cmp eax, dword [ebp - 0x24]
    jae near .flush_tail
    mov eax, dword [ebp - 0xc]
    cmp byte [eax], 0xa
    jne short .copy_source_byte
    mov eax, dword [ebp - 8]
    mov byte [esi + eax], 0xd
    inc esi
    cmp esi, edi
    jne short .copy_source_byte
    mov ebx, dword [ebp - 0x1c]
    mov edx, eax
    mov ecx, edi
    mov ah, 0x40
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov esi, eax
    mov dword [ebp - 0x10], eax
    test eax, eax
    jl near .report_dos_error
    cmp eax, edi
    je short .reset_chunk_after_cr

.report_partial_chunk:
    mov eax, 0xc
    call set_errno
    mov eax, dword [ebp - 0x14]
    add eax, esi
    jmp near .restore_registers

.reset_chunk_after_cr:
    mov eax, dword [ebp - 4]
    xor esi, edi
    mov dword [ebp - 0x14], eax

.copy_source_byte:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 0xc]
    mov ebx, dword [ebp - 0xc]
    mov ecx, dword [ebp - 4]
    inc ebx
    inc ecx
    mov dl, byte [edx]
    mov dword [ebp - 0xc], ebx
    mov byte [esi + eax], dl
    inc esi
    mov dword [ebp - 4], ecx
    cmp esi, edi
    jne short .check_source_end
    mov ebx, dword [ebp - 0x1c]
    mov edx, eax
    mov ecx, edi
    mov ah, 0x40
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov esi, eax
    mov dword [ebp - 0x10], eax
    test eax, eax
    jl near .report_dos_error
    cmp eax, edi
    jne short .report_partial_chunk
    mov eax, dword [ebp - 4]
    xor esi, edi
    mov dword [ebp - 0x14], eax
    jmp near .check_source_end

.flush_tail:
    test esi, esi
    je short .return_count
    mov ebx, dword [ebp - 0x1c]
    mov edx, dword [ebp - 8]
    mov ecx, esi
    mov ah, 0x40
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov edx, eax
    mov dword [ebp - 0x10], eax
    test eax, eax
    jl near .report_dos_error
    cmp eax, esi
    je short .return_count
    mov eax, 0xc
    call set_errno
    mov eax, dword [ebp - 0x14]
    add eax, edx
    jmp short .restore_registers

.return_count:
    mov eax, dword [ebp - 0x24]

.restore_registers:
    mov esp, ebp
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

atoi_:
    push ebx
    push ecx
    push edx

.skip_space:
    mov dl, byte [eax]
    inc dl
    and edx, 0xff
    test byte [edx + character_types], 2
    je short .read_sign
    inc eax
    jmp short .skip_space

.read_sign:
    mov cl, byte [eax]
    cmp cl, 0x2b
    je short .skip_sign
    cmp cl, 0x2d
    jne short .start_decimal

.skip_sign:
    inc eax

.start_decimal:
    xor ebx, ebx

.check_digit:
    mov dl, byte [eax]
    inc dl
    and edx, 0xff
    test byte [edx + character_types], 0x20
    je short .apply_sign
    imul ebx, ebx, 0xa
    xor edx, edx
    mov dl, byte [eax]
    add ebx, edx
    inc eax
    sub ebx, 0x30
    jmp short .check_digit

.apply_sign:
    cmp cl, 0x2d
    jne short .return_integer
    neg ebx

.return_integer:
    mov eax, ebx
    pop edx
    pop ecx
    pop ebx
    ret

integer_digits:
    db "0123456789abcdefghijklmnopqrstuvwxyz", 0

ultoa_:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x28
    mov ebp, edx
    mov edi, ebx
    mov esi, edx
    xor dl, dl
    lea ecx, [esp + 1]
    mov byte [esp], dl

.divide_by_radix:
    lea ebx, [esp + 0x24]
    mov dword [esp + 0x24], edi
    xor edx, edx
    div dword [ebx]
    mov dword [ebx], eax
    mov al, byte cs:[edx + integer_digits - 0x10000]
    mov byte [ecx], al
    mov eax, dword [esp + 0x24]
    inc ecx
    test eax, eax
    jne short .divide_by_radix

.copy_digit_in_reverse:
    dec ecx
    mov al, byte [ecx]
    mov byte [esi], al
    inc esi
    test al, al
    jne short .copy_digit_in_reverse
    mov eax, ebp
    add esp, 0x28
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

ltoa_:
    push ecx
    mov ecx, edx
    cmp ebx, 0xa
    jne short .convert_magnitude
    test eax, eax
    jge short .convert_magnitude
    neg eax
    mov byte [edx], 0x2d
    inc edx

.convert_magnitude:
    call ultoa_
    mov eax, ecx
    pop ecx
    ret

memmove_:
    push ecx
    push esi
    push edi
    mov esi, edx
    mov ecx, ebx
    cmp edx, eax
    je short .restore_registers
    jae short .copy_forward
    add edx, ebx
    cmp edx, eax
    jbe short .copy_forward
    lea edi, [eax + ebx]
    lea esi, [edx - 1]
    dec edi
    mov edx, ds
    push es
    mov es, edx
    std
    dec esi
    dec edi
    shr ecx, 1
    db 0x66 ; Original operand-size prefix precedes REP.
    rep movsd
    adc ecx, ecx
    inc esi
    inc edi
    db 0x66 ; Original operand-size prefix precedes REP.
    rep movsb
    pop es
    cld
    pop edi
    pop esi
    pop ecx
    ret

.copy_forward:
    mov edx, ds
    mov edi, eax
    push es
    mov es, edx
    push ecx
    shr ecx, 2
    rep movsd
    pop ecx
    and ecx, 3
    rep movsb
    pop es

.restore_registers:
    pop edi
    pop esi
    pop ecx
    ret
