; Near-heap allocation and runtime memory and file wrappers.
BITS 32
ORG 0x6126d

near_heap_head equ 0x141b8
near_heap_rover equ 0x141bc
largest_prior_free_block equ 0x141c0
near_heap_clean equ 0x2891e5
allocate_from_heap equ 0x64f9e
expand_dgroup equ 0x65535
request_more_heap equ 0x656f0
fill_byte_pattern equ 0x62de0
sopen equ 0x6138c

malloc_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es
    push fs
    push gs
    push ebp
    sub esp, 4
    mov esi, eax
    test eax, eax
    je short .reject_size
    cmp eax, -0x2c
    jbe short .prepare_search

.reject_size:
    xor eax, eax
    jmp near .restore_registers

.prepare_search:
    mov ebp, near_heap_head
    lea edi, [esi + 3]
    xor ah, ah
    xor ebx, ebx
    mov byte [esp], ah
    and di, 0xfffc

.restart_search:
    mov eax, edi
    cmp edi, 0xc
    jae short .choose_rover
    mov eax, 0xc

.choose_rover:
    cmp eax, dword [largest_prior_free_block]
    jbe short .reset_rover_search
    mov ecx, dword [near_heap_rover]
    test ecx, ecx
    jne short .check_heap

.search_from_head:
    mov dword [largest_prior_free_block], ecx
    mov ecx, dword [near_heap_head]
    jmp short .check_heap

.reset_rover_search:
    xor ecx, ecx
    jmp short .search_from_head

.try_current_heap:
    mov edx, ds
    mov eax, ebp
    mov dword [near_heap_rover], ecx
    and edx, 0xffff
    mov eax, esi
    mov ebx, ecx
    call allocate_from_heap
    mov ebx, eax
    test eax, eax
    jne short .finish_search
    mov eax, dword [largest_prior_free_block]
    mov edx, dword [ecx + 0x14]
    cmp edx, eax
    jbe short .advance_heap
    mov dword [largest_prior_free_block], edx

.advance_heap:
    mov ecx, dword [ecx + 8]

.check_heap:
    test ecx, ecx
    jne short .try_current_heap
    cmp byte [esp], 0
    jne short .call_memory_hook
    mov eax, esi
    call expand_dgroup
    test eax, eax
    jne short .retry_after_expansion

.call_memory_hook:
    mov eax, esi
    call request_more_heap
    test eax, eax
    je short .finish_search
    xor cl, cl
    mov byte [esp], cl
    jmp near .restart_search

.retry_after_expansion:
    mov byte [esp], 1
    jmp near .restart_search

.finish_search:
    xor ch, ch
    mov eax, ebx
    mov byte [near_heap_clean], ch

.restore_registers:
    add esp, 4
    pop ebp
    pop gs
    pop fs
    pop es
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

memset_:
    push eax
    push ecx
    mov dh, dl
    shl edx, 8
    mov dl, dh
    shl edx, 8
    mov dl, dh
    mov ecx, ebx
    call fill_byte_pattern
    pop ecx
    pop eax
    ret

open_:
    push ebx
    push edx
    lea eax, [esp + 0x14]
    add eax, 4
    mov eax, dword [eax - 4]
    push eax
    push 0
    mov edx, dword [esp + 0x18]
    push edx
    mov ebx, dword [esp + 0x18]
    push ebx
    call sopen
    add esp, 0x10
    pop edx
    pop ebx
    ret
