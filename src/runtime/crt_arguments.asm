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
parse_command_line equ 0x634d2

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

    times 233 db 0    ; The command-line parser is supplied by C.
