; Maintain near heaps and allocate or resize their DOS and DPMI backing blocks.
BITS 32
ORG 0x65151

free_ equ 0x6170a
near_heap_head equ 0x141b8
near_heap_rover equ 0x141bc
memory_limit equ 0x1446c
extender_type equ 0x1449a
extender_flags equ 0x1449c
dos_reserve_bytes equ 0x2892dc
dos_reserve_high_word equ 0x2892de

unlink_near_heap equ 0x65151
link_and_initialize_heap equ 0x652f1

    times 63 db 0    ; unlink_near_heap is supplied by C.

release_empty_heaps equ 0x65190
    times 94 db 0    ; release_empty_heaps is supplied by C.

resize_dpmi_heap:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebx, eax
    mov ebp, edx
    call release_empty_heaps
    mov edx, dword [near_heap_head]
    jmp near .check_heap

.check_target:
    cmp edx, ebx
    ja near .return_zero
    lea eax, [edx + 0x2c]
    cmp eax, ebx
    jne near .next_heap
    cmp dword [edx + 0x18], 1
    jne near .next_heap
    mov eax, edx
    call unlink_near_heap
    lea eax, [edx - 8]
    cmp dword [eax + 4], 0
    jne near .return_zero
    mov ecx, ebp
    mov ebx, dword [ebx]
    mov edx, dword [edx]
    sub ebx, 4
    add edx, 0xc
    sub ecx, ebx
    add edx, ecx
    add edx, 0xfff
    and dh, 0xf0
    xor dl, dl
    mov ebx, edx
    mov ecx, edx
    shr ebx, 0x10
    mov di, word [eax]
    mov si, word [eax + 2]
    mov ah, 5
    mov al, 3
    int 0x31
    sbb eax, eax
    inc eax
    je short .check_resize
    mov ax, bx
    shl eax, 0x10
    mov ax, cx
    mov word [eax], di
    mov word [eax + 2], si

.check_resize:
    test eax, eax
    je short .return
    lea ebx, [eax + 8]
    sub edx, 0xc
    inc ebp
    mov dword [eax + 4], 0
    mov eax, ebx
    mov dword [ebx], edx
    call link_and_initialize_heap
    mov dword [ebx + 0x18], 1
    and ebp, 0xfffffffe
    mov edx, dword [eax]
    mov ecx, eax
    sub edx, ebp
    mov esi, eax
    cmp edx, 0xc
    jb short .use_whole_block
    mov eax, ebp
    or al, 1
    mov dword [ecx], eax
    add ecx, ebp
    or dl, 1
    mov dword [ecx], edx
    mov edi, dword [ebx + 0x18]
    mov dword [ebx + 0x14], 0xffffffff
    inc edi
    lea eax, [ecx + 4]
    mov dword [ebx + 0x18], edi
    call free_
    jmp short .return_block

.use_whole_block:
    mov ah, byte [eax]
    or ah, 1
    mov byte [ecx], ah

.return_block:
    mov eax, esi
    jmp short .return

.next_heap:
    mov edx, dword [edx + 8]

.check_heap:
    test edx, edx
    jne near .check_target

.return_zero:
    xor eax, eax

.return:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

    times 116 db 0   ; link_and_initialize_heap is supplied by C.

    times 78 db 0    ; free_space_at_break is supplied by C.

allocate_dpmi_heap:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push eax
    call release_empty_heaps
    mov eax, dword [esp]
    shr eax, 0x10
    mov ecx, dword [esp]
    mov ebx, eax
    mov ah, 5
    mov al, 1
    int 0x31
    sbb eax, eax
    inc eax
    je short .check_dpmi_result
    mov ax, bx
    shl eax, 0x10
    mov ax, cx
    mov word [eax], di
    mov word [eax + 2], si

.check_dpmi_result:
    test eax, eax
    je short .allocate_dos_fallback
    mov ebx, dword [esp]
    lea edx, [eax + 8]
    sub ebx, 8
    mov dword [edx], ebx
    mov dword [eax + 4], 0
    mov eax, edx
    jmp near .discard_argument

.allocate_dos_fallback:
    test word [dos_reserve_high_word], 0xfff0
    je short .check_dos_size
    mov dword [dos_reserve_bytes], 0xfffff

.check_dos_size:
    cmp dword [esp], 0x10000
    ja short .return_zero
    mov ebx, dword [dos_reserve_bytes]
    shr ebx, 4
    or bl, 1
    mov ah, 0x48
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov edx, eax
    test eax, eax
    jl short .return_zero
    mov ebx, dword [esp]
    shr ebx, 4
    mov ah, 0x48
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov esi, eax
    mov ebx, eax
    mov eax, edx
    push es
    mov es, ax
    mov ah, 0x49
    int 0x21
    rcl eax, 1
    ror eax, 1
    pop es
    test esi, esi
    jl short .return_zero
    mov ah, 0
    mov al, 6
    int 0x31
    mov eax, ecx
    shl eax, 0x10
    mov ax, dx
    add eax, 8
    mov edx, dword [esp]
    mov dword [eax - 4], esi
    sub edx, 8
    mov dword [eax], edx
    jmp short .discard_argument

.return_zero:
    xor eax, eax

.discard_argument:
    add esp, 4

.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
