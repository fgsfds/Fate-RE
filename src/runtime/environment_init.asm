; Initialize the Watcom environment vector from the DOS environment segment.
BITS 32
ORG 0x6e6b9

malloc_ equ 0x6126d
memset_ equ 0x61350
free_ equ 0x6170a
environment_vector equ 0x173d8
environment_flags equ 0x173dc
environment_selector equ 0x144a1
environment_offset equ 0x1449d

initialize_environment:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es
    push fs
    cmp dword [environment_vector], 0
    jne near .return
    mov fs, word [environment_selector]
    xor ecx, ecx
    xor dl, dl
    mov eax, fs
    mov edi, dword [environment_offset]
    mov es, eax
    mov eax, edi

.check_string:
    cmp dl, byte [es:eax]
    je short .measure_strings

.scan_string:
    mov dh, byte [es:eax]
    lea ebx, [eax + 1]
    cmp dl, dh
    je short .count_string
    mov eax, ebx
    jmp short .scan_string

.count_string:
    inc ecx
    mov eax, ebx
    jmp short .check_string

.measure_strings:
    sub eax, edi
    jne short .allocate_strings
    mov eax, 1

.allocate_strings:
    call malloc_
    mov edx, eax
    mov ebx, eax
    test eax, eax
    je near .return
    mov eax, ecx
    shl eax, 2
    add eax, 4
    add eax, ecx
    call malloc_
    test eax, eax
    je short .release_strings
    mov dword [environment_vector], eax
    xor esi, esi
    mov eax, fs
    xor ecx, ecx
    mov es, eax
    mov eax, edi

.check_copy:
    cmp byte [es:eax], 0
    je short .terminate_vector
    mov edx, dword [environment_vector]
    mov [nosplit ecx + edx], ebx

.copy_byte:
    mov dl, byte [es:eax]
    inc eax
    mov byte [ebx], dl
    inc ebx
    test dl, dl
    jne short .copy_byte
    add ecx, 4
    inc esi
    jmp short .check_copy

.terminate_vector:
    mov edx, dword [environment_vector]
    mov dword [nosplit ecx + edx], 0
    add ecx, 4
    add edx, ecx
    mov ebx, esi
    mov dword [environment_flags], edx
    mov eax, edx
    xor edx, edx
    call memset_
    jmp short .return

.release_strings:
    mov eax, edx
    call free_

.return:
    pop fs
    pop es
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
