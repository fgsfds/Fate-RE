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

unlink_near_heap:
    push ebx
    push edx
    mov edx, dword [near_heap_rover]
    cmp eax, edx
    jne short .check_head
    mov edx, dword [edx + 8]
    mov dword [near_heap_rover], edx

.check_head:
    mov ebx, dword [near_heap_head]
    cmp eax, ebx
    jne short .load_neighbors
    mov edx, dword [ebx + 8]
    mov dword [near_heap_head], edx

.load_neighbors:
    mov edx, dword [eax + 4]
    mov eax, dword [eax + 8]
    test edx, edx
    je short .update_successor
    mov dword [edx + 8], eax

.update_successor:
    test eax, eax
    je short .return
    mov dword [eax + 4], edx

.return:
    pop edx
    pop ebx
    ret

release_empty_heaps:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edx, dword [near_heap_head]

.check_heap:
    test edx, edx
    je near allocate_dpmi_heap.return
    mov eax, dword [edx + 0x24]
    mov eax, dword [eax]
    mov ebx, dword [edx]
    add eax, 0x2c
    cmp eax, ebx
    jne short .next_heap
    lea ebx, [edx - 8]
    mov eax, edx
    mov ecx, dword [edx + 8]
    call unlink_near_heap
    mov edx, ecx
    mov ecx, dword [ebx + 4]
    test ecx, ecx
    jne short .free_dos_selector
    mov eax, dword [ebx]
    shr eax, 0x10
    mov di, word [ebx]
    mov esi, eax
    mov ah, 5
    mov al, 2
    int 0x31
    jmp short .check_heap

.free_dos_selector:
    mov eax, ecx
    push es
    mov es, ax
    mov ah, 0x49
    int 0x21
    rcl eax, 1
    ror eax, 1
    pop es
    jmp short .check_heap

.next_heap:
    mov edx, dword [edx + 8]
    jmp short .check_heap

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

link_and_initialize_heap:
    push ebx
    push edx
    mov edx, eax
    mov eax, dword [near_heap_head]
    xor ebx, ebx
    jmp short .check_node

.compare_address:
    cmp edx, eax
    jb short .set_neighbors
    mov ebx, eax
    mov eax, dword [eax + 8]

.check_node:
    test eax, eax
    jne short .compare_address

.set_neighbors:
    mov dword [edx + 4], ebx
    mov dword [edx + 8], eax
    test ebx, ebx
    je short .update_head
    mov dword [ebx + 8], edx
    jmp short .update_successor

.update_head:
    mov dword [near_heap_head], edx

.update_successor:
    test eax, eax
    je short .initialize_heap
    mov dword [eax + 4], edx

.initialize_heap:
    lea ebx, [edx + 0x20]
    mov eax, dword [edx]
    add edx, 0x2c
    mov dword [edx - 0xc], 0
    mov dword [edx - 0x1c], 0
    mov dword [edx - 0x14], 0
    mov dword [edx - 0x10], 0
    mov dword [edx - 8], ebx
    mov dword [edx - 4], ebx
    sub eax, 0x2c
    mov dword [edx - 0x20], ebx
    mov dword [edx], eax
    mov dword [edx + eax], 0xffffffff
    mov eax, edx
    pop edx
    pop ebx
    ret

free_space_at_break:
    push ebx
    push edx
    mov edx, dword [near_heap_head]
    test edx, edx
    je short .return_zero
    mov edx, dword [edx + 0x24]
    mov ebx, dword [edx]
    add ebx, edx
    mov ah, byte [extender_type]
    add ebx, 4
    cmp ah, 2
    jb short .compare_limit
    cmp ah, 8
    ja short .compare_limit
    cmp byte [extender_flags], 0
    jne short .compare_limit
    xor eax, eax
    mov eax, ds
    lsl eax, eax
    inc eax
    mov dword [memory_limit], eax

.compare_limit:
    cmp ebx, dword [memory_limit]
    jne short .return_zero
    mov eax, dword [edx]
    pop edx
    pop ebx
    ret

.return_zero:
    xor eax, eax
    pop edx
    pop ebx
    ret

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
