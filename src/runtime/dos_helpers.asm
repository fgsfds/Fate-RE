; Runtime initialization and shutdown thunks, string and DOS helpers.
BITS 32
ORG 0x60322

atexit_hook equ 0x141ac
int23_exit_hook equ 0x141b0
fpe_exit_hook equ 0x141b4
extender_type equ 0x1449a
runtime_init equ 0x6439c
runtime_fini equ 0x64521
startup_exit_jump equ 0x60197

runtime_init_thunk:
    jmp near runtime_init

runtime_fini_thunk:
    jmp near runtime_fini

abs_:
    test eax, eax
    jge short .return_magnitude
    neg eax

.return_magnitude:
    ret

strcpy_:
    push ecx
    push eax

.copy_byte_pair:
    mov cl, byte [edx]
    mov byte [eax], cl
    cmp cl, 0
    je short .return_destination
    mov cl, byte [edx + 1]
    add edx, 2
    mov byte [eax + 1], cl
    add eax, 2
    cmp cl, 0
    jne short .copy_byte_pair

.return_destination:
    pop eax
    pop ecx
    ret

__null_int23_exit_:
    ; Default no-op target for the three exit hooks.
    ret

exit_:
    push edx
    mov edx, eax
    call dword [atexit_hook]
    call dword [int23_exit_hook]
    mov eax, edx
    call _exit_
    pop edx
    ret

_exit_:
    push edx
    mov edx, eax
    call dword [int23_exit_hook]
    call dword [fpe_exit_hook]
    mov eax, edx
    jmp near startup_exit_jump

strlen_:
    push ecx
    push edi
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
    mov eax, ecx
    pop edi
    pop ecx
    ret

outp_:
    push ebx
    push ecx
    mov ebx, eax
    mov ecx, edx
    mov edx, eax
    mov al, cl
    out dx, al
    pop ecx
    pop ebx
    ret

_dos_getvect_:
    push ebx
    push ecx
    mov ebx, eax
    mov ah, byte [extender_type]
    cmp ah, 2
    jb short .get_vector_dos
    cmp ah, 8
    ja short .get_vector_dos
    mov eax, 0x2502
    mov cl, bl
    jmp short .interrupt_get_vector

.get_vector_dos:
    mov eax, ebx
    and eax, 0xff
    xor cl, cl
    or ah, 0x35

.interrupt_get_vector:
    push es
    int 0x21
    mov edx, es
    pop es
    mov eax, ebx
    pop ecx
    pop ebx
    ret

_disable_:
    cli
    ret

_dos_setvect_:
    push edx
    mov edx, ebx
    mov bl, byte [extender_type]
    cmp bl, 2
    jb short .set_vector_dos
    cmp bl, 8
    ja short .set_vector_dos
    push ds
    mov ds, ecx
    mov cl, al
    mov al, 4
    mov ah, 0x25
    int 0x21
    pop ds
    pop edx
    ret

.set_vector_dos:
    push ds
    mov ds, ecx
    mov ah, 0x25
    int 0x21
    pop ds
    pop edx
    ret

_enable_:
    sti
    ret
