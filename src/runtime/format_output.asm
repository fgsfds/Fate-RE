; Callback-driven format output and conversion-specifier parsing.
BITS 32
ORG 0x635bb

convert_format_value equ 0x63b54

__prtf_:
    push esi
    push edi
    push es
    push ebp
    sub esp, 0x4c
    mov esi, ebx
    mov dword [esp + 0x44], ecx
    xor bl, bl
    mov dword [esp + 0x28], eax
    mov byte [esp + 0x48], bl
    mov byte [esp + 0x3c], bl
    xor ebx, ebx
    mov edi, edx
    mov dword [esp + 0x38], ebx
    mov ebp, 4
    jmp short .scan_format

.parse_conversion:
    lea ebx, [esp + 0x28]
    mov edx, esi
    call parse_format_specifier
    mov edi, eax
    mov al, byte [eax]
    inc edi
    mov byte [esp + 0x3d], al
    test al, al
    je near .return_count
    cmp al, 0x6e
    jne near .format_value
    mov bl, byte [esp + 0x3c]
    test bl, 0x20
    je short .check_short_count
    test bl, 0x80
    je short .check_near_long_count
    mov ecx, dword [esi]
    add ecx, 8
    mov dword [esi], ecx
    les edx, [ecx - 8]

.store_far_count:
    mov eax, dword [esp + 0x38]
    mov dword es:[edx], eax
    jmp short .scan_format

.check_near_long_count:
    test bl, 0x40
    je short .store_near_long_count
    mov ebx, dword [esi]
    add ebx, ebp
    mov dword [esi], ebx
    mov edx, dword [ebx - 4]

.store_count:
    mov eax, dword [esp + 0x38]
    mov dword [edx], eax

.scan_format:
    mov cl, byte [edi]
    test cl, cl
    je near .return_count
    lea eax, [edi + 1]
    cmp cl, 0x25
    je short .parse_conversion
    mov edi, eax
    xor edx, edx
    lea eax, [esp + 0x28]
    mov dl, cl
    call dword [esp + 0x44]
    jmp short .scan_format

.store_near_long_count:
    mov edx, dword [esi]
    add edx, ebp
    mov dword [esi], edx
    mov edx, dword [edx - 4]
    jmp short .store_count

.check_short_count:
    test bl, 0x10
    je short .check_default_far_count
    test bl, 0x80
    je short .check_near_short_count
    mov eax, dword [esi]
    add eax, 8
    mov dword [esi], eax
    les edx, [eax - 8]
    mov eax, dword [esp + 0x38]
    db 0x66 ; The original emits the operand-size prefix before ES.
    mov dword es:[edx], eax
    jmp short .scan_format

.check_near_short_count:
    test bl, 0x40
    je short .read_short_count_pointer
    mov ecx, dword [esi]
    add ecx, ebp
    mov dword [esi], ecx
    mov edx, dword [ecx - 4]

.store_short_count:
    mov eax, dword [esp + 0x38]
    mov word [edx], ax
    jmp short .scan_format

.read_short_count_pointer:
    mov ebx, dword [esi]
    add ebx, ebp
    mov dword [esi], ebx
    mov edx, dword [ebx - 4]
    jmp short .store_short_count

.check_default_far_count:
    test bl, 0x80
    je short .check_default_near_count
    mov edx, dword [esi]
    add edx, 8
    mov dword [esi], edx
    les edx, [edx - 8]
    jmp near .store_far_count

.check_default_near_count:
    test bl, 0x40
    je short .read_default_count_pointer
    mov eax, dword [esi]
    add eax, ebp
    mov dword [esi], eax
    mov edx, dword [eax - 4]
    jmp near .store_count

.read_default_count_pointer:
    mov ecx, dword [esi]
    add ecx, ebp
    mov dword [esi], ecx
    mov edx, dword [ecx - 4]
    jmp near .store_count

.format_value:
    mov eax, esp
    lea ebx, [esp + 0x28]
    lea ecx, [esp + 0x48]
    mov edx, esi
    call convert_format_value
    mov es, edx
    mov dl, byte [esp + 0x3c]
    mov ebx, eax
    test dl, 8
    jne short .start_prefix
    cmp byte [esp + 0x3e], 0x20
    jne short .start_prefix

.leading_spaces:
    mov eax, dword [esp + 0x2c]
    dec eax
    mov dword [esp + 0x2c], eax
    test eax, eax
    jl short .start_prefix
    xor edx, edx
    lea eax, [esp + 0x28]
    mov dl, byte [esp + 0x3e]
    call dword [esp + 0x44]
    jmp short .leading_spaces

.start_prefix:
    lea ecx, [esp + 0x3f]

.emit_prefix:
    mov al, byte [ecx]
    test al, al
    je short .emit_precision_zeroes
    xor edx, edx
    mov dl, al
    lea eax, [esp + 0x28]
    inc ecx
    call dword [esp + 0x44]
    jmp short .emit_prefix

.emit_precision_zeroes:
    mov eax, dword [esp + 0x34]
    lea ecx, [eax - 1]
    mov dword [esp + 0x34], ecx
    test eax, eax
    je short .check_width_zeroes
    lea eax, [esp + 0x28]
    mov edx, 0x30
    call dword [esp + 0x44]
    jmp short .emit_precision_zeroes

.check_width_zeroes:
    test byte [esp + 0x3c], 8
    jne short .check_string
    cmp byte [esp + 0x3e], 0x20
    je short .check_string

.emit_width_zeroes:
    mov eax, dword [esp + 0x2c]
    dec eax
    mov dword [esp + 0x2c], eax
    test eax, eax
    jl short .check_string
    xor edx, edx
    lea eax, [esp + 0x28]
    mov dl, byte [esp + 0x3e]
    call dword [esp + 0x44]
    jmp short .emit_width_zeroes

.check_string:
    mov dh, byte [esp + 0x3d]
    cmp dh, 0x73
    je short .check_wide_string
    cmp dh, 0x53
    jne short .emit_value

.check_wide_string:
    test byte [esp + 0x3c], 0x20
    je short .emit_string

.emit_wide_string:
    mov eax, dword [esp + 0x30]
    lea ecx, [eax - 1]
    mov dword [esp + 0x30], ecx
    test eax, eax
    je short .check_trailing_spaces
    xor edx, edx
    lea eax, [esp + 0x28]
    mov dl, byte es:[ebx]
    call dword [esp + 0x44]
    add ebx, 2
    jmp short .emit_wide_string

.emit_string:
    mov eax, dword [esp + 0x30]
    lea edx, [eax - 1]
    mov dword [esp + 0x30], edx
    test eax, eax
    je short .check_trailing_spaces
    xor edx, edx
    lea eax, [esp + 0x28]
    mov dl, byte es:[ebx]
    call dword [esp + 0x44]
    inc ebx
    jmp short .emit_string

.emit_value:
    mov eax, dword [esp + 0x30]
    lea ecx, [eax - 1]
    mov dword [esp + 0x30], ecx
    test eax, eax
    je short .check_trailing_spaces
    xor edx, edx
    lea eax, [esp + 0x28]
    mov dl, byte es:[ebx]
    call dword [esp + 0x44]
    inc ebx
    jmp short .emit_value

.check_trailing_spaces:
    test byte [esp + 0x3c], 8
    je near .scan_format
    cmp dword [esp + 0x2c], 0
    jle near .scan_format

.emit_trailing_spaces:
    mov eax, dword [esp + 0x2c]
    lea edx, [eax - 1]
    mov dword [esp + 0x2c], edx
    test eax, eax
    je near .scan_format
    lea eax, [esp + 0x28]
    mov edx, 0x20
    call dword [esp + 0x44]
    jmp short .emit_trailing_spaces

.return_count:
    mov eax, dword [esp + 0x38]
    add esp, 0x4c
    pop ebp
    pop es
    pop edi
    pop esi
    ret

parse_format_specifier:
    push ecx
    push esi
    push edi
    mov esi, edx
    mov byte [ebx + 0x17], 0
    mov edx, ebx
    mov byte [ebx + 0x16], 0x20
    call parse_format_flags
    mov dword [ebx + 4], 0
    mov cl, byte [eax]
    mov edx, eax
    cmp cl, 0x30
    jb short .check_star_width
    cmp cl, 0x39
    ja short .check_star_width

.accumulate_width:
    imul ecx, dword [ebx + 4], 0xa
    xor edx, edx
    mov dl, byte [eax]
    sub edx, 0x30
    add ecx, edx
    inc eax
    mov dword [ebx + 4], ecx
    mov cl, byte [eax]
    cmp cl, 0x30
    jb short .check_precision
    cmp cl, 0x39
    jbe short .accumulate_width
    jmp short .check_precision

.check_star_width:
    cmp byte [eax], 0x2a
    jne short .check_precision
    mov edx, dword [esi]
    add edx, 4
    mov dword [esi], edx
    mov edx, dword [edx - 4]
    mov dword [ebx + 4], edx
    test edx, edx
    jge short .consume_star_width
    mov edi, edx
    mov dh, byte [ebx + 0x14]
    neg edi
    or dh, 8
    mov dword [ebx + 4], edi
    mov byte [ebx + 0x14], dh

.consume_star_width:
    inc eax

.check_precision:
    mov dword [ebx + 8], 0xffffffff
    cmp byte [eax], 0x2e
    jne short .check_length_modifier
    inc eax
    mov dword [ebx + 8], 0
    cmp byte [eax], 0x2a
    jne short .scan_precision_digits
    mov edx, dword [esi]
    add edx, 4
    mov dword [esi], edx
    mov edx, dword [edx - 4]
    mov dword [ebx + 8], edx
    test edx, edx
    jge short .consume_star_precision
    mov dword [ebx + 8], 0xffffffff

.consume_star_precision:
    inc eax
    jmp short .check_length_modifier

.scan_precision_digits:
    mov cl, byte [eax]
    cmp cl, 0x30
    jb short .check_length_modifier
    cmp cl, 0x39
    ja short .check_length_modifier
    imul ecx, dword [ebx + 8], 0xa
    xor edx, edx
    mov dl, byte [eax]
    sub edx, 0x30
    add ecx, edx
    inc eax
    mov dword [ebx + 8], ecx
    jmp short .scan_precision_digits

.check_length_modifier:
    mov cl, byte [eax]
    lea edx, [eax + 1]
    cmp cl, 0x4e
    jb short .check_uppercase_modifier
    jbe short .set_near_modifier
    cmp cl, 0x6c
    jb short .check_short_modifier
    jbe short .set_long_modifier
    cmp cl, 0x77
    je short .set_long_modifier
    pop edi
    pop esi
    pop ecx
    ret

.check_short_modifier:
    cmp cl, 0x68
    je short .set_short_modifier
    pop edi
    pop esi
    pop ecx
    ret

.check_uppercase_modifier:
    cmp cl, 0x46
    jb short .return_specifier
    jbe short .set_far_modifier
    cmp cl, 0x4c
    je short .set_long_pointer_modifier
    pop edi
    pop esi
    pop ecx
    ret

.set_long_modifier:
    mov dl, byte [ebx + 0x14]
    or dl, 0x20
    inc eax
    mov byte [ebx + 0x14], dl
    pop edi
    pop esi
    pop ecx
    ret

.set_short_modifier:
    mov cl, byte [ebx + 0x14]
    or cl, 0x10
    mov eax, edx
    mov byte [ebx + 0x14], cl
    pop edi
    pop esi
    pop ecx
    ret

.set_long_pointer_modifier:
    or byte [ebx + 0x14], 0x40

.return_consumed_modifier:
    mov eax, edx
    pop edi
    pop esi
    pop ecx
    ret

.set_far_modifier:
    or byte [ebx + 0x14], 0x80
    jmp short .return_consumed_modifier

.set_near_modifier:
    mov ch, byte [ebx + 0x14]
    or ch, 0x40
    mov eax, edx
    mov byte [ebx + 0x14], ch

.return_specifier:
    pop edi
    pop esi
    pop ecx
    ret

parse_format_flags:
    push ebx
    push ecx
    mov byte [edx + 0x14], 0

.scan_flags:
    mov bl, byte [eax]
    cmp bl, 0x2d
    jne short .check_alternate_flag
    or byte [edx + 0x14], 8
    jmp short .advance_flag

.check_alternate_flag:
    cmp bl, 0x23
    jne short .check_plus_flag
    or byte [edx + 0x14], 1
    jmp short .advance_flag

.check_plus_flag:
    cmp bl, 0x2b
    jne short .check_space_flag
    mov ch, byte [edx + 0x14]
    or ch, 4
    mov bl, ch
    mov byte [edx + 0x14], ch
    and bl, 0xfd
    mov byte [edx + 0x14], bl
    jmp short .advance_flag

.check_space_flag:
    cmp bl, 0x20
    jne short .check_zero_flag
    mov bh, byte [edx + 0x14]
    test bh, 4
    jne short .advance_flag
    mov cl, bh
    or cl, 2
    mov byte [edx + 0x14], cl
    jmp short .advance_flag

.check_zero_flag:
    cmp bl, 0x30
    jne short .return_flags
    mov byte [edx + 0x16], bl

.advance_flag:
    inc eax
    jmp short .scan_flags

.return_flags:
    pop ecx
    pop ebx
    ret
