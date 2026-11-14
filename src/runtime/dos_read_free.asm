; Read DOS handles with text translation and release near-heap allocations.
BITS 32
ORG 0x615f7

near_heap_head equ 0x141b8
near_heap_rover equ 0x141bc
largest_prior_free_block equ 0x141c0
near_heap_clean equ 0x2891e5
get_io_mode equ 0x65783
set_errno equ 0x6468e
set_dos_errno equ 0x6571d
lseek equ 0x615b6
release_heap_block equ 0x65046

read_:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x14
    push eax
    mov ebp, edx
    mov ecx, ebx
    call get_io_mode
    mov edx, eax
    mov dword [esp + 0xc], eax
    test eax, eax
    jne short .check_read_access
    mov eax, 4

.report_mode_error:
    call set_errno
    mov eax, 0xffffffff
    jmp near .restore_registers

.check_read_access:
    test al, 1
    jne short .check_binary
    mov eax, 6
    jmp short .report_mode_error

.check_binary:
    test al, 0x40
    je short .prepare_text_read
    mov ebx, dword [esp]
    mov edx, ebp
    mov ah, 0x3f
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov esi, eax
    mov dword [esp + 8], eax
    test eax, eax
    jge near .return_count
    xor eax, eax
    mov ax, si

.report_dos_error:
    call set_dos_errno
    jmp near .restore_registers

.prepare_text_read:
    xor edx, eax
    mov dword [esp + 4], ebx
    mov dword [esp + 8], edx

.read_text_chunk:
    mov ebx, dword [esp]
    mov ecx, dword [esp + 4]
    mov edx, ebp
    mov ah, 0x3f
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov ebx, eax
    mov esi, eax
    mov dword [esp + 0x10], eax
    test eax, eax
    jge short .check_text_eof
    xor eax, eax
    mov ax, bx
    jmp short .report_dos_error

.check_text_eof:
    je near .return_count
    mov esi, dword [esp + 8]
    mov eax, ebp
    xor edi, edi
    lea ecx, [ebx + ebp]
    xor edx, edx
    mov dword [esp + 0x14], ecx
    jmp short .check_chunk_end

.translate_byte:
    mov bl, byte [eax]
    cmp bl, 0x1a
    jne short .check_carriage_return
    mov ebp, dword [esp + 0x10]
    mov edx, edi
    mov eax, dword [esp]
    sub edx, ebp
    mov ebx, 1
    inc edx
    call lseek
    mov eax, esi
    jmp short .restore_registers

.check_carriage_return:
    cmp bl, 0xd
    je short .advance_input
    mov ebx, edx
    inc esi
    mov cl, byte [eax]
    inc edx
    mov byte [ebx + ebp], cl

.advance_input:
    inc eax
    inc edi

.check_chunk_end:
    cmp eax, dword [esp + 0x14]
    jb short .translate_byte
    mov ecx, dword [esp + 4]
    mov ah, byte [esp + 0xd]
    mov dword [esp + 8], esi
    sub ecx, edx
    add ebp, edx
    mov dword [esp + 4], ecx
    test ah, 0x20
    jne short .return_count
    test ecx, ecx
    jne near .read_text_chunk

.return_count:
    mov eax, dword [esp + 8]

.restore_registers:
    add esp, 0x18
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret

free_:
    push ebx
    push ecx
    push edx
    push ebp
    mov ebx, eax
    mov ecx, dword [near_heap_head]
    jmp short .check_heap_link

.check_heap_range:
    cmp ecx, ebx
    ja short .advance_heap
    cmp ebx, edx
    jb short .release_block

.advance_heap:
    mov ecx, dword [ecx + 8]

.check_heap_link:
    mov edx, dword [ecx + 8]
    test edx, edx
    jne short .check_heap_range

.release_block:
    mov eax, near_heap_head
    mov edx, ds
    and edx, 0xffff
    mov eax, ebx
    mov ebx, ecx
    call release_heap_block
    cmp ecx, dword [near_heap_rover]
    je short .invalidate_heap_status
    mov ebp, dword [largest_prior_free_block]
    mov edx, dword [ecx + 0x14]
    cmp edx, ebp
    jbe short .invalidate_heap_status
    mov dword [largest_prior_free_block], edx

.invalidate_heap_status:
    xor ah, ah
    mov byte [near_heap_clean], ah
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
