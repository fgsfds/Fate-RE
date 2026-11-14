; Seek within the read buffer when possible, otherwise seek on the DOS descriptor.
BITS 32
ORG 0x647c3

lseek_ equ 0x615b6
set_errno equ 0x6468e
flush_stream equ 0x64b31
tell_ equ 0x6adb5

seek_within_buffer:
    push ebx
    push ecx
    push esi
    push edi
    and byte [edx + 0xc], 0xef
    cmp eax, dword [edx + 4]
    jg short .discard_buffer
    mov ebx, dword [edx + 8]
    mov ecx, dword [edx]
    sub ebx, ecx
    cmp eax, ebx
    jl short .discard_buffer
    mov edi, dword [edx + 4]
    lea esi, [nosplit ecx + eax]
    sub edi, eax
    mov dword [edx], esi
    xor eax, eax
    mov dword [edx + 4], edi
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

.discard_buffer:
    mov eax, dword [edx + 8]
    mov dword [edx + 4], 0
    mov dword [edx], eax
    mov eax, 1
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

fseek_:
    push ecx
    push esi
    push edi
    mov ecx, eax
    mov esi, edx
    test byte [eax + 0xc], 6
    je short .seek_read_stream
    test byte [ecx + 0xd], 0x10
    je short .discard_read_buffer
    mov eax, ecx
    call flush_stream
    test eax, eax
    je short .seek_descriptor
    test ebx, ebx
    jne short .return_error
    test esi, esi
    jge short .return_error

.invalid_seek:
    mov eax, 9
    call set_errno

.return_error:
    mov eax, 0xffffffff
    pop edi
    pop esi
    pop ecx
    ret

.discard_read_buffer:
    cmp ebx, 1
    jne short .reset_read_buffer
    sub esi, dword [ecx + 4]

.reset_read_buffer:
    mov eax, dword [ecx + 8]
    mov dword [ecx + 4], 0
    mov dword [ecx], eax

.seek_descriptor:
    and byte [ecx + 0xc], 0xeb
    mov edx, esi
    mov eax, dword [ecx + 0x10]
    call lseek_
    cmp eax, -1
    jne near .return_success
    pop edi
    pop esi
    pop ecx
    ret

.seek_read_stream:
    cmp ebx, 1
    jb short .check_seek_set
    jbe short .seek_cur
    cmp ebx, 2
    je short .seek_end
    jmp short .invalid_seek

.check_seek_set:
    test ebx, ebx
    je short .seek_set
    jmp short .invalid_seek

.seek_cur:
    mov eax, edx
    mov edx, ecx
    mov edi, dword [ecx + 4]
    call seek_within_buffer
    test eax, eax
    je short .return_success
    mov edx, esi
    mov eax, dword [ecx + 0x10]
    sub edx, edi
    call lseek_
    cmp eax, -1
    jne short .return_success
    pop edi
    pop esi
    pop ecx
    ret

.seek_set:
    mov eax, dword [ecx + 0x10]
    call tell_
    mov edx, dword [ecx + 4]
    mov edi, esi
    sub eax, edx
    sub edi, eax
    mov edx, ecx
    mov eax, edi
    call seek_within_buffer
    test eax, eax
    je short .return_success
    mov edx, esi
    mov eax, dword [ecx + 0x10]
    call lseek_
    cmp eax, -1
    jne short .return_success
    pop edi
    pop esi
    pop ecx
    ret

.seek_end:
    mov eax, dword [ecx + 8]
    mov dl, byte [ecx + 0xc]
    mov dword [ecx], eax
    and dl, 0xef
    mov eax, dword [ecx + 0x10]
    mov byte [ecx + 0xc], dl
    mov edx, esi
    mov dword [ecx + 4], 0
    call lseek_
    cmp eax, -1
    je short .return

.return_success:
    xor eax, eax

.return:
    pop edi
    pop esi
    pop ecx
    ret
