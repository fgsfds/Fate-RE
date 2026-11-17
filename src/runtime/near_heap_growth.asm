; Grow the Watcom near heap with a separate allocation or by extending DGROUP.
BITS 32
ORG 0x65486

discard_region_argument equ 0x6547d
free_ equ 0x6170a
link_and_initialize_heap equ 0x652f1
round_heap_request equ 0x65679
allocate_dpmi_heap equ 0x653b3
resize_data_segment equ 0x6b028
runtime_hook equ 0x17494
memory_limit equ 0x1446c
extender_type equ 0x1449a
extender_subtype equ 0x1449b
extender_flags equ 0x1449c
near_heap_head equ 0x141b8

expand_separate_heap:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push eax
    cmp dword [runtime_hook], 0
    jne short .check_limit

.return_zero:
    xor eax, eax
    jmp short discard_region_argument

.check_limit:
    cmp dword [memory_limit], -2
    je short .return_zero
    mov eax, esp
    call round_heap_request
    test eax, eax
    je short discard_region_argument
    cmp byte [extender_type], 1
    jne short .allocate_dos
    mov eax, dword [esp]
    call allocate_dpmi_heap
    mov ebx, eax
    mov edx, eax
    test eax, eax
    je short .check_block
    mov eax, dword [eax]
    mov dword [esp], eax
    jmp short .check_block

.allocate_dos:
    mov ebx, dword [esp]
    mov eax, 0x80004800
    int 0x21
    sbb ebx, ebx
    not ebx
    and eax, ebx
    mov ecx, dword [esp]
    sub ecx, 4
    mov edx, eax
    mov dword [esp], ecx

.check_block:
    test edx, edx
    je short .return_zero
    mov eax, dword [esp]
    mov esi, dword [esp]
    sub eax, 4
    cmp eax, esi
    ja short .return_zero
    mov dword [esp], eax
    cmp eax, 0x38
    jb short .return_zero
    mov dword [edx], eax
    mov eax, edx
    call link_and_initialize_heap
    mov ebx, eax
    mov eax, dword [eax]
    mov dword [esp], eax
    or al, 1
    mov dword [ebx], eax
    mov edi, dword [edx + 0x18]
    mov dword [edx + 0x14], 0xffffffff
    inc edi
    lea eax, [ebx + 4]
    mov dword [edx + 0x18], edi
    call free_
    mov eax, 1
    jmp near discard_region_argument

expand_dgroup:
    push ebx
    push ecx
    push edx
    push esi
    push ebp
    push eax
    cmp byte [extender_type], 1
    jne short .check_extender_nine
    cmp byte [extender_subtype], 0
    je short .use_separate_heap

.check_extender_nine:
    cmp byte [extender_type], 9
    jne short .check_runtime_hook

.use_separate_heap:
    mov eax, dword [esp]
    call expand_separate_heap
    jmp near .return

.check_runtime_hook:
    cmp dword [runtime_hook], 0
    jne short .check_limit

.return_zero:
    xor eax, eax
    jmp near .return

.check_limit:
    cmp dword [memory_limit], -2
    je short .return_zero
    mov eax, esp
    call round_heap_request
    test eax, eax
    je near .return
    mov bl, byte [extender_type]
    cmp bl, 2
    jb short .compute_new_limit
    cmp bl, 8
    ja short .compute_new_limit
    cmp byte [extender_flags], 0
    jne short .compute_new_limit
    xor eax, eax
    mov eax, ds
    lsl eax, eax
    inc eax
    mov dword [memory_limit], eax

.compute_new_limit:
    mov edx, dword [esp]
    mov ecx, dword [memory_limit]
    add edx, ecx
    cmp edx, ecx
    jae short .resize
    mov edx, 0xfffffffe

.resize:
    mov eax, edx
    call resize_data_segment
    cmp eax, -1
    je short .return_zero
    mov ebx, eax
    cmp eax, -8
    ja short .return_zero
    cmp edx, eax
    jbe short .return_zero
    sub edx, eax
    lea eax, [edx - 4]
    mov dword [esp], edx
    cmp eax, edx
    ja short .return_zero
    mov edx, dword [near_heap_head]
    mov dword [esp], eax
    jmp short .check_heap

.inspect_heap:
    mov ebp, dword [edx + 8]
    test ebp, ebp
    je short .check_contiguous
    cmp edx, ebx
    ja short .next_heap
    cmp ebx, ebp
    jb short .check_contiguous

.next_heap:
    mov edx, dword [edx + 8]

.check_heap:
    test edx, edx
    jne short .inspect_heap

.check_contiguous:
    test edx, edx
    je short .create_heap
    mov eax, dword [edx]
    lea ecx, [ebx - 4]
    add eax, edx
    cmp ecx, eax
    jne short .create_heap
    mov esi, dword [esp]
    add esi, 4
    mov dword [esp], esi
    add dword [edx], esi
    mov ebp, dword [esp]
    lea ecx, [nosplit eax + ebp]
    mov ebx, eax
    mov dword [ecx], 0xffffffff
    jmp short .release_initial_block

.create_heap:
    cmp dword [esp], 0x38
    jb near .return_zero
    mov eax, dword [esp]
    mov dword [ebx], eax
    mov eax, ebx
    mov edx, ebx
    call link_and_initialize_heap
    mov ebx, eax
    mov eax, dword [eax]
    mov dword [esp], eax

.release_initial_block:
    mov eax, dword [esp]
    or al, 1
    mov dword [ebx], eax
    inc dword [edx + 0x18]
    lea eax, [ebx + 4]
    mov dword [edx + 0x14], 0xffffffff
    call free_
    mov eax, 1

.return:
    add esp, 4
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

    times 119 db 0    ; round_heap_request is supplied by C.

    times 3 db 0      ; request_more_heap is supplied by C.
