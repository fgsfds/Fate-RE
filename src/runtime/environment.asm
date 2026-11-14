; Find an environment entry by name and form the DOS shell's command switch.
BITS 32
ORG 0x63fb5

environment_vector equ 0x173d8
strnicmp equ 0x6751a

getenv_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, eax
    mov esi, [environment_vector]
    test esi, esi
    je short .missing
    test eax, eax
    je short .missing
    mov edi, eax
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
    mov edi, ecx
    jmp short .read_entry
.compare_name:
    mov eax, ecx
    mov edx, ebp
    mov ebx, edi
    call strnicmp
    test eax, eax
    jne short .advance
    cmp byte [ecx + edi], '='
    jne short .advance
    lea eax, [edi + 1]
    add eax, ecx
    jmp short .return
.advance:
    add esi, 4
.read_entry:
    mov ecx, [esi]
    test ecx, ecx
    jne short .compare_name
.missing:
    xor eax, eax
.return:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

select_shell_switch:
    push ebx
    mov ebx, eax
    test dl, dl
    je short .query_dos
    mov byte [eax], '/'
    jmp short .append_command_letter
.query_dos:
    push edx
    mov ah, 0x37
    mov al, 0
    int 0x21
    mov al, dl
    mov ah, 0
    pop edx
    mov [ebx], al
.append_command_letter:
    mov byte [ebx + 1], 'c'
    mov eax, ebx
    mov byte [ebx + 2], 0
    pop ebx
    ret
