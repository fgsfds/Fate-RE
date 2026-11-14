; Convert printf arguments and account for width, sign and precision.
BITS 32
ORG 0x639ca

float_formatter equ 0x173d0
ltoa equ 0x62d2e
toupper equ 0x62dce
format_unsigned equ 0x674b6
format_integer equ 0x674ff

bounded_far_strlen:
    push ecx
    push esi
    push edi
    push es
    mov esi, edx
    mov edi, ebx
    mov edx, eax
    xor eax, eax

scan_byte:
    mov es, esi
    mov ebx, edx
    mov cl, byte es:[ebx]
    inc edx
    test cl, cl
    je short finish_far_length
    cmp eax, edi
    je short finish_far_length
    inc eax
    jmp short scan_byte

finish_far_length:
    pop es
    pop edi
    pop esi
    pop ecx
    ret

bounded_far_wcslen:
    push ecx
    push esi
    push edi
    push es
    mov ecx, edx
    mov esi, ebx
    mov edx, eax
    xor eax, eax

scan_word:
    mov es, ecx
    mov ebx, edx
    db 0x66 ; Operand-size prefix precedes the original ES override.
    mov edi, dword es:[ebx]
    add edx, 2
    test di, di
    je short finish_far_length
    cmp eax, esi
    je short finish_far_length
    inc eax
    jmp short scan_word

format_padded_hex:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 4
    mov ebp, edx
    mov dword [esp], ebx
    mov ebx, 0x10
    mov edi, ebp
    call ltoa
    push es
    mov eax, ds
    mov es, eax
    sub ecx, ecx
    dec ecx
    xor eax, eax
    repne scasb
    not ecx
    dec ecx
    pop es
    mov eax, dword [esp]
    mov esi, ecx
    mov edi, ebp
    dec eax
    lea edx, [ecx + ebp]
    lea ebx, [eax + ebp]
    jmp short check_hex_source

shift_hex_digit:
    dec edx
    dec esi
    mov cl, byte [edx]
    dec eax
    mov byte [ebx], cl
    dec ebx

check_hex_source:
    cmp edx, edi
    jne short shift_hex_digit
    lea edx, [eax + ebp]

pad_hex:
    test eax, eax
    jl short terminate_hex
    dec eax
    mov byte [edx], 0x30
    dec edx
    jmp short pad_hex

terminate_hex:
    add ebp, dword [esp]
    mov byte [ebp], 0
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

format_fixed_point:
    push ecx
    push esi
    push edi
    sub esp, 4
    mov ecx, eax
    mov esi, ebx
    mov dword [esp], edx
    test edx, edx
    jge short check_fixed_precision
    neg edx
    lea ecx, [eax + 1]
    mov byte [eax], 0x2d
    mov dword [esp], edx

check_fixed_precision:
    cmp dword [esi + 8], -1
    jne short write_fixed_integer
    mov dword [esi + 8], 4

write_fixed_integer:
    mov ebx, 0xa
    xor eax, eax
    mov edx, ecx
    mov ax, word [esp + 2]
    call ltoa
    mov ebx, ecx

find_integer_end:
    mov ah, byte [ecx]
    lea edx, [ecx + 1]
    test ah, ah
    je short check_fraction
    mov ecx, edx
    jmp short find_integer_end

check_fraction:
    cmp dword [esi + 8], 0
    je short check_rounding
    mov byte [ecx], 0x2e
    xor eax, eax
    mov ecx, edx
    jmp short check_fraction_length

write_fraction_digit:
    xor edx, edx
    mov word [esp + 2], dx
    mov edi, dword [esp]
    imul edx, edi, 0xa
    mov dword [esp], edx
    mov dl, byte [esp + 2]
    add dl, 0x30
    inc eax
    mov byte [ecx], dl
    inc ecx

check_fraction_length:
    cmp eax, dword [esi + 8]
    jl short write_fraction_digit
    mov byte [ecx], 0

check_rounding:
    test byte [esp + 1], 0x80
    je short return_fixed

propagate_rounding:
    cmp ecx, ebx
    jne short previous_rounding_digit
    lea ecx, [ebx + 1]
    mov byte [ebx], 0x31

skip_integer_zeroes:
    mov dl, byte [ecx]
    lea eax, [ecx + 1]
    cmp dl, 0x30
    jne short check_decimal_point
    mov ecx, eax
    jmp short skip_integer_zeroes

check_decimal_point:
    cmp dl, 0x2e
    jne short extend_rounded_value
    mov byte [ecx], 0x30
    lea ecx, [eax + 1]
    mov byte [eax], dl

skip_fraction_zeroes:
    cmp byte [ecx], 0x30
    jne short extend_rounded_value
    inc ecx
    jmp short skip_fraction_zeroes

extend_rounded_value:
    mov byte [ecx], 0x30
    inc ecx
    mov byte [ecx], 0
    jmp short return_fixed

previous_rounding_digit:
    dec ecx
    cmp byte [ecx], 0x2e
    jne short round_digit
    dec ecx

round_digit:
    mov al, byte [ecx]
    cmp al, 0x39
    je short carry_rounding
    mov ah, al
    inc ah
    mov byte [ecx], ah
    jmp short return_fixed

carry_rounding:
    mov byte [ecx], 0x30
    jmp short propagate_rounding

return_fixed:
    add esp, 4
    pop edi
    pop esi
    pop ecx
    ret

call_float_formatter:
    call dword [float_formatter]
    ret

convert_format_value:
    push esi
    push edi
    push es
    push ebp
    sub esp, 8
    mov edi, eax
    mov esi, ebx
    mov dword [esp], ecx
    mov ebx, 1
    mov eax, ds
    mov ecx, edi
    mov dword [esp + 4], ebx
    mov es, eax
    mov al, byte [esi + 0x15]
    mov dword [esi + 0xc], 0
    cmp al, 0x69
    jb short check_uppercase_argument
    jbe near check_numeric_precision
    cmp al, 0x75
    jb short check_octal_argument
    jbe short read_unsigned_argument
    cmp al, 0x78

branch_unsigned_argument:
    je short read_unsigned_argument
    jmp short dispatch_conversion

check_octal_argument:
    cmp al, 0x6f
    jmp short branch_unsigned_argument

check_uppercase_argument:
    cmp al, 0x58
    jb short dispatch_conversion
    jbe short read_unsigned_argument
    cmp al, 0x64
    je short check_numeric_precision
    jmp short dispatch_conversion

read_unsigned_argument:
    mov ah, byte [esi + 0x14]
    test ah, 0x20
    je short check_unsigned_short
    mov ebx, dword [edx]
    add ebx, 4
    mov dword [edx], ebx
    mov ebp, dword [ebx - 4]
    jmp short clear_unsigned_sign_flags

check_unsigned_short:
    test ah, 0x10
    je short read_unsigned_dword
    mov eax, dword [edx]
    add eax, 4
    mov dword [edx], eax
    movzx ebp, word [eax - 4]
    jmp short clear_unsigned_sign_flags

read_unsigned_dword:
    mov ebp, dword [edx]
    add ebp, 4
    mov dword [edx], ebp
    mov ebp, dword [ebp - 4]

clear_unsigned_sign_flags:
    and byte [esi + 0x14], 0xf9

check_numeric_precision:
    cmp dword [esi + 8], -1
    je short dispatch_conversion
    mov byte [esi + 0x16], 0x20

dispatch_conversion:
    mov al, byte [esi + 0x15]
    mov ebx, 0xa
    cmp al, 0x65
    jb short check_upper_conversions
    jbe near format_float
    cmp al, 0x6f
    jb short check_lower_float
    jbe near format_octal
    cmp al, 0x73
    jb short check_pointer
    jbe near format_string
    cmp al, 0x75
    jb near format_unknown_specifier
    jbe near write_unsigned_digits
    cmp al, 0x78
    je near format_hex
    jmp near format_unknown_specifier

check_pointer:
    cmp al, 0x70
    je near format_pointer
    jmp near format_unknown_specifier

check_lower_float:
    cmp al, 0x67
    jb short check_fixed_point
    jbe near format_float
    cmp al, 0x69
    je near format_signed
    jmp near format_unknown_specifier

check_upper_conversions:
    cmp al, 0x50
    jb short check_upper_float
    jbe near format_pointer
    cmp al, 0x58
    jb short check_upper_string
    jbe near format_hex
    cmp al, 0x63
    jb near format_unknown_specifier
    jbe near format_character
    jmp near format_signed

check_upper_string:
    cmp al, 0x53
    je near format_string
    jmp near format_unknown_specifier

check_upper_float:
    cmp al, 0x46
    jb short check_upper_exponent
    jbe short check_fixed_point
    cmp al, 0x47

branch_upper_float:
    je short format_float
    jmp near format_unknown_specifier

check_upper_exponent:
    cmp al, 0x45
    jmp short branch_upper_float

check_fixed_point:
    test byte [esi + 0x14], 0x10
    je short format_float
    mov ebx, dword [edx]
    add ebx, 4
    mov dword [edx], ebx
    mov eax, edi
    mov edx, dword [ebx - 4]
    mov ebx, esi
    call format_fixed_point
    mov ebx, 0xffffffff
    mov eax, ds
    mov edx, ds
    mov es, eax
    mov eax, edi
    mov ecx, edi
    jmp short measure_far_bytes

format_float:
    mov eax, edi
    mov ebx, esi
    call call_float_formatter
    mov ebx, 0xffffffff
    mov es, edx
    mov ecx, eax
    jmp short measure_far_bytes

format_octal:
    mov al, byte [esi + 0x14]
    mov ebx, 8
    test al, 1
    je short write_octal_digits
    mov byte [edi], 0x30
    inc edi

write_octal_digits:
    mov eax, ebp
    mov edx, edi
    call format_integer

check_zero_precision:
    cmp dword [esi + 8], 0
    jne short prepare_numeric_length
    cmp byte [edi], 0x30
    jne short prepare_numeric_length
    mov byte es:[ecx], 0

prepare_numeric_length:
    mov ebx, 0xffffffff
    mov edx, es
    mov eax, ecx

measure_far_bytes:
    call bounded_far_strlen
    jmp near check_numeric_prefix

format_signed:
    mov al, byte [esi + 0x14]
    test al, 0x20
    je short check_signed_short
    mov ebp, dword [edx]
    add ebp, 4
    mov dword [edx], ebp
    mov edx, edi
    mov eax, dword [ebp - 4]

write_integer_digits:
    call format_integer
    jmp short check_zero_precision

check_signed_short:
    test al, 0x10
    je short read_signed_dword
    mov eax, dword [edx]
    add eax, 4
    mov dword [edx], eax
    mov edx, edi
    movsx eax, word [eax - 4]
    jmp short write_integer_digits

read_signed_dword:
    mov ebp, dword [edx]
    add ebp, 4
    mov dword [edx], ebp
    mov edx, edi
    mov eax, dword [ebp - 4]
    call ltoa
    jmp short check_zero_precision

format_string:
    mov ah, byte [esi + 0x14]
    test ah, 0x80
    je short check_near_string
    mov ecx, dword [edx]
    add ecx, 8
    mov dword [edx], ecx
    mov dx, word [ecx - 4]
    mov ecx, dword [ecx - 8]
    test ecx, ecx
    jne short use_far_string
    test dx, dx
    je short use_null_string

use_far_string:
    mov es, edx
    jmp short prepare_string_length

use_null_string:
    mov eax, ds
    mov ecx, dword [esp]
    jmp short load_string_segment

check_near_string:
    test ah, 0x40
    je short read_default_string
    mov ebx, dword [edx]
    add ebx, 4
    mov dword [edx], ebx
    mov ecx, dword [ebx - 4]
    test ecx, ecx
    je short use_null_string

select_near_segment:
    mov eax, ds
    jmp short load_string_segment

read_default_string:
    mov eax, dword [edx]
    add eax, 4
    mov dword [edx], eax
    mov ecx, dword [eax - 4]
    test ecx, ecx
    jne short select_near_segment
    mov eax, ds
    mov ecx, dword [esp]

load_string_segment:
    mov es, eax

prepare_string_length:
    mov bh, byte [esi + 0x14]
    mov al, byte [esi + 0x15]
    xor edi, edi
    and bh, 0xf9
    mov dword [esp + 4], edi
    mov byte [esi + 0x14], bh
    cmp al, 0x53
    jne short measure_terminated_string
    test bh, 0x20
    je short read_byte_length
    xor eax, eax
    db 0x66 ; Operand-size prefix precedes the original ES override.
    mov eax, dword es:[ecx]
    add ecx, 2
    jmp near check_numeric_prefix

read_byte_length:
    xor eax, eax
    mov al, byte es:[ecx]
    inc ecx
    jmp near check_numeric_prefix

measure_terminated_string:
    test bh, 0x20
    je short prepare_byte_length
    mov edx, es
    mov eax, ecx
    mov ebx, dword [esi + 8]
    call bounded_far_wcslen
    jmp near check_numeric_prefix

prepare_byte_length:
    mov edx, es
    mov eax, ecx
    mov ebx, dword [esi + 8]
    jmp near measure_far_bytes

format_hex:
    test byte [esi + 0x14], 1
    je short use_hex_base
    test ebp, ebp
    je short use_hex_base
    mov byte [esi + 0x17], 0x30
    mov al, byte [esi + 0x15]
    mov byte [esi + 0x19], 0
    mov byte [esi + 0x18], al

use_hex_base:
    mov ebx, 0x10

write_unsigned_digits:
    mov eax, ebp
    mov edx, edi
    call format_unsigned
    cmp byte [esi + 0x15], 0x58
    jne near check_zero_precision
    mov eax, edi
    call uppercase_output
    jmp near check_zero_precision

format_pointer:
    cmp dword [esi + 4], 0
    jne short read_pointer_offset
    test byte [esi + 0x14], 0x80
    je short set_near_pointer_width
    mov dword [esi + 4], 0xd
    jmp short read_pointer_offset

set_near_pointer_width:
    mov dword [esi + 4], 8

read_pointer_offset:
    and byte [esi + 0x14], 0xf9
    mov eax, dword [edx]
    add eax, 4
    mov dword [edx], eax
    mov bl, byte [esi + 0x14]
    mov ebp, dword [eax - 4]
    test bl, 0x80
    je short format_near_offset
    add eax, 4
    mov dword [edx], eax
    mov ebx, 4
    mov eax, dword [eax - 4]
    mov edx, edi
    and eax, 0xffff
    call format_padded_hex
    mov ebx, 8
    lea edx, [edi + 5]
    mov eax, ebp
    mov byte [edi + 4], 0x3a
    jmp short write_pointer_offset

format_near_offset:
    mov ebx, 8
    mov eax, ebp
    mov edx, edi

write_pointer_offset:
    call format_padded_hex

check_upper_pointer:
    cmp byte [esi + 0x15], 0x50
    jne near prepare_numeric_length
    mov eax, edi
    call uppercase_output
    jmp near prepare_numeric_length

format_character:
    mov ebx, dword [edx]
    add ebx, 4
    mov dword [edx], ebx
    mov al, byte [ebx - 4]
    mov byte [edi + 1], 0
    mov byte [edi], al
    mov dword [esi + 8], 1
    mov eax, 1
    mov dh, byte [esi + 0x14]
    xor edi, edi
    and dh, 0xf9
    mov dword [esp + 4], edi
    mov byte [esi + 0x14], dh
    jmp short check_numeric_prefix

format_unknown_specifier:
    mov dword [esi + 4], 0
    mov al, byte [esi + 0x15]
    mov byte [edi + 1], 0
    mov byte [edi], al
    mov dword [esi + 8], 1
    mov al, byte [esi + 0x14]
    xor edi, edi
    and al, 0xf9
    mov dword [esp + 4], edi
    mov byte [esi + 0x14], al
    mov eax, 1

check_numeric_prefix:
    cmp dword [esp + 4], 0
    je short check_special_padding
    mov dl, byte es:[ecx]
    cmp dl, 0x2d
    jne short check_space_prefix
    inc ecx
    mov byte [esi + 0x18], 0
    dec eax
    mov byte [esi + 0x17], dl
    jmp short check_numeric_digit_count

check_space_prefix:
    mov dh, byte [esi + 0x14]
    test dh, 2
    je short check_plus_prefix
    mov byte [esi + 0x17], 0x20
    jmp short terminate_sign_prefix

check_plus_prefix:
    test dh, 4
    je short check_numeric_digit_count
    mov byte [esi + 0x17], 0x2b

terminate_sign_prefix:
    mov byte [esi + 0x18], 0

check_numeric_digit_count:
    mov edx, dword [esi + 8]
    cmp eax, edx
    jle short set_precision_padding
    mov dword [esi + 8], eax
    jmp short check_special_padding

set_precision_padding:
    sub edx, eax
    mov dword [esi + 0xc], edx

check_special_padding:
    cmp byte [esi + 0x16], 0x2a
    jne short limit_output_length
    mov dl, byte [esi + 0x14]
    mov byte [esi + 0x17], 0
    and dl, 0xf9
    mov byte [esi + 0x14], dl

limit_output_length:
    mov ebx, dword [esi + 8]
    cmp ebx, -1
    je short check_character_length
    cmp eax, ebx
    jge short measure_prefix

check_character_length:
    cmp byte [esi + 0x15], 0x63
    je short measure_prefix
    mov dword [esi + 8], eax

measure_prefix:
    mov ebx, 0xffffffff
    lea eax, [esi + 0x17]
    mov edx, ds
    call bounded_far_strlen
    mov ebp, dword [esi + 8]
    mov edx, dword [esi + 0xc]
    add eax, ebp
    mov ebx, dword [esi + 4]
    add eax, edx
    mov edx, es
    sub ebx, eax
    mov eax, ecx
    mov dword [esi + 4], ebx
    add esp, 8
    pop ebp
    pop es
    pop edi
    pop esi
    ret

uppercase_output:
    push edx
    mov edx, eax

scan_uppercase_byte:
    cmp byte [edx], 0
    je short finish_uppercase
    xor eax, eax
    mov al, byte [edx]
    call toupper
    mov byte [edx], al
    inc edx
    jmp short scan_uppercase_byte

finish_uppercase:
    pop edx
    ret
