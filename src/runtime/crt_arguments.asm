; Build argc and argv from the DOS command line.
BITS 32
ORG 0x63414

command_line equ 0x14470
program_name equ 0x14474
argument_vector equ 0x141a0
argument_count equ 0x1419c
argc_value equ 0x28924c
argv_pointer equ 0x289250
malloc equ 0x6126d

crt_argument_noop:
    ret

initialize_arguments:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 8
    mov ebx, esp
    mov eax, dword [command_line]
    xor edx, edx
    call parse_command_line
    mov ecx, dword [esp]
    lea ebp, [eax + 1]
    mov edx, dword [command_line]
    mov eax, ebp
    sub ecx, edx
    shl eax, 2
    inc ecx
    mov dword [esp + 4], eax
    add eax, 4
    add eax, ecx
    call malloc
    mov edx, eax
    test eax, eax
    je short .clear_failed_allocation
    mov esi, dword [command_line]
    add eax, ecx
    mov edi, edx
    mov dword [argument_vector], eax
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
    mov ecx, dword [argument_vector]
    mov eax, dword [program_name]
    mov ebx, esp
    mov dword [ecx], eax
    add ecx, 4
    mov eax, edx
    mov edx, ecx
    mov esi, dword [esp + 4]
    call parse_command_line
    mov edx, dword [argument_vector]
    add edx, esi
    mov dword [argument_count], ebp
    mov dword [edx], 0
    jmp short .publish_arguments

.clear_failed_allocation:
    mov dword [argument_vector], eax
    mov dword [argument_count], eax

.publish_arguments:
    mov eax, dword [argument_vector]
    mov dword [argc_value], ebp
    mov dword [argv_pointer], eax
    add esp, 8
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

parse_command_line:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 8
    mov esi, edx
    mov dword [esp + 4], ebx
    xor ecx, ecx

.skip_whitespace:
    mov dl, byte [eax]
    cmp dl, 0x20
    je short .advance_whitespace
    cmp dl, 9
    jne short .check_argument_start

.advance_whitespace:
    inc eax
    jmp short .skip_whitespace

.check_argument_start:
    test dl, dl
    je near .return_count_and_end
    cmp dl, 0x22
    jne short .start_unquoted_argument
    inc eax
    mov dword [esp], eax
    mov edx, eax

.read_quoted_character:
    mov bh, byte [eax]
    cmp bh, 0x22
    je near .finish_argument
    test bh, bh
    je near .finish_argument
    cmp bh, 0x5c
    jne short .advance_quoted_input
    mov bl, byte [eax + 1]
    cmp bl, 0x22
    je short .skip_quoted_escape
    cmp bl, bh
    jne short .advance_quoted_input

.skip_quoted_escape:
    inc eax

.advance_quoted_input:
    lea ebx, [eax + 1]
    test esi, esi
    je short .scan_quoted_argument
    mov al, byte [eax]
    mov byte [edx], al
    mov eax, ebx
    inc edx
    jmp short .read_quoted_character

.scan_quoted_argument:
    mov eax, ebx
    jmp short .read_quoted_character

.start_unquoted_argument:
    mov dword [esp], eax
    mov edx, eax

.read_unquoted_character:
    mov bl, byte [eax]
    test bl, bl
    je short .finish_argument
    cmp bl, 0x20
    je short .finish_argument
    cmp bl, 9
    je short .finish_argument
    cmp bl, 0x5c
    jne short .advance_unquoted_input
    cmp byte [eax + 1], 0x22
    jne short .advance_unquoted_input
    inc eax

.advance_unquoted_input:
    lea ebx, [eax + 1]
    test esi, esi
    je short .scan_unquoted_argument
    mov al, byte [eax]
    mov byte [edx], al
    mov eax, ebx
    inc edx
    jmp short .read_unquoted_character

.scan_unquoted_argument:
    mov eax, ebx
    jmp short .read_unquoted_character

.finish_argument:
    lea ebp, [eax + 1]
    lea edi, [ecx + 1]
    test esi, esi
    je short .count_and_continue
    shl ecx, 2
    lea ebx, [esi + ecx]
    mov ecx, dword [esp]
    mov dword [ebx], ecx
    mov bl, byte [eax]
    mov ecx, edi
    test bl, bl
    jne short .terminate_and_continue
    mov byte [edx], bl
    jmp short .return_count_and_end

.terminate_and_continue:
    mov eax, ebp
    mov byte [edx], 0
    jmp near .skip_whitespace

.count_and_continue:
    mov dl, byte [eax]
    mov ecx, edi
    test dl, dl
    je short .return_count_and_end
    mov eax, ebp
    jmp near .skip_whitespace

.return_count_and_end:
    mov edx, dword [esp + 4]
    mov dword [edx], eax
    mov eax, ecx
    add esp, 8
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
