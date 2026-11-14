; Allocate and coalesce blocks in a Watcom near-heap free list.
BITS 32
ORG 0x64f9e


__MemAllocator:
    push esi
    push edi
    push ecx
    push ds
    mov ds, edx
    or eax, eax
    je short .return_null
    add eax, 7
    jb short .return_null
    and al, 0xfc
    mov edx, 0xc
    sub eax, edx
    cmc
    sbb ecx, ecx
    and eax, ecx
    add eax, edx
    cmp eax, dword [ebx + 0x14]
    ja short .return_null
    mov esi, dword [ebx + 0xc]
    mov edi, dword [ebx + 0x10]
    cmp eax, edi
    ja short .check_free_block
    mov esi, dword [ebx + 0x28]
    sub edi, edi

.check_free_block:
    mov edx, dword [esi]
    cmp eax, edx
    jbe short .allocate_block
    sub edi, edx
    cmc
    sbb ecx, ecx
    and edi, ecx
    add edi, edx
    lea edx, [ebx + 0x20]
    mov esi, dword [esi + 8]
    cmp esi, edx
    jne short .check_free_block
    mov dword [ebx + 0x14], edi

.return_null:
    sub eax, eax
    jmp short .restore_registers

.allocate_block:
    sub edx, eax
    mov dword [ebx + 0x10], edi
    inc dword [ebx + 0x18]
    mov ecx, dword [esi + 8]
    cmp edx, 0xc
    jb short .unlink_whole_block
    mov edi, esi
    add edi, eax
    mov dword [ebx + 0xc], edi
    mov dword [edi], edx
    mov dword [esi], eax
    mov ebx, dword [esi + 4]
    mov dword [edi + 4], ebx
    mov dword [edi + 8], ecx
    mov dword [ebx + 8], edi
    mov ebx, ecx
    mov dword [ebx + 4], edi
    jmp short .mark_allocated

.unlink_whole_block:
    dec dword [ebx + 0x1c]
    mov eax, esi
    mov edi, ecx
    mov esi, dword [esi + 4]
    mov dword [esi + 8], edi
    mov dword [edi + 4], esi
    mov dword [ebx + 0xc], esi
    mov esi, eax

.mark_allocated:
    or dword [esi], 1
    mov eax, esi
    add eax, 4

.restore_registers:
    pop ds
    pop ecx
    pop edi
    pop esi
    ret

memfree_return_thunk:
    jmp near memfree_shared_return

__MemFree:
    push esi
    push edi
    push ecx
    push ds
    mov ds, edx
    or eax, eax
    je short memfree_return_thunk
    mov esi, eax
    sub esi, 4
    mov eax, dword [esi]
    test al, 1
    je short memfree_return_thunk
    and al, 0xfe
    mov edi, esi
    add edi, eax
    test dword [edi], 1
    jne short .find_insertion_point
    cmp edi, dword [ebx + 0xc]
    jne short .merge_next_block
    mov dword [ebx + 0xc], esi

.merge_next_block:
    add eax, dword [edi]
    mov dword [esi], eax
    push ebx
    mov ebx, dword [edi + 4]
    mov edi, dword [edi + 8]
    mov dword [ebx + 8], edi
    mov dword [edi + 4], ebx
    pop ebx
    dec dword [ebx + 0x1c]
    jmp short .check_previous_block

.find_insertion_point:
    mov dword [esi], eax
    mov edi, dword [ebx + 0xc]
    cmp esi, edi
    jae short .check_next_free_block
    cmp esi, dword [edi + 4]
    ja short .check_previous_block
    mov edi, dword [ebx + 0x28]
    cmp esi, edi
    jb short .check_previous_block
    jmp short .estimate_scan_cost

.check_next_free_block:
    mov edi, dword [edi + 8]
    cmp esi, edi
    jb short .check_previous_block
    lea edi, [ebx + 0x20]
    cmp esi, dword [ebx + 0x24]
    ja short .check_previous_block

.estimate_scan_cost:
    sub edx, edx
    mov eax, dword [ebx + 0x18]
    mov ecx, dword [ebx + 0x1c]
    inc ecx
    div ecx
    dec ecx
    cmp eax, ecx
    jae short .scan_free_list
    mov edx, dword [ebx + 0x18]
    sub edx, ecx
    add eax, eax
    cmp edx, ecx
    ja short .scan_forward
    sub eax, eax

.scan_forward:
    mov edi, esi
    add edi, dword [esi]

.inspect_adjacent_block:
    mov edx, dword [edi]
    test dl, 1
    je short .check_previous_block
    cmp edx, -1
    je short .scan_free_list
    and dl, 0xfe
    add edi, edx
    dec eax
    jne short .inspect_adjacent_block

.scan_free_list:
    mov edi, dword [ebx + 0xc]
    cmp esi, edi
    jae short .check_free_list_position
    mov edi, dword [ebx + 0x28]

.check_free_list_position:
    cmp esi, edi
    jb short .check_previous_block
    mov edi, dword [edi + 8]
    cmp esi, edi
    jb short .check_previous_block
    mov edi, dword [edi + 8]
    cmp esi, edi
    jb short .check_previous_block
    mov edi, dword [edi + 8]
    jmp short .check_free_list_position

.check_previous_block:
    mov edx, dword [edi + 4]
    mov ecx, dword [esi]
    xchg edi, edx
    mov eax, edi
    add eax, dword [edi]
    cmp eax, esi
    jne short .insert_free_block
    add ecx, dword [edi]
    mov dword [edi], ecx
    cmp esi, dword [ebx + 0xc]
    jne short .use_merged_block
    mov dword [ebx + 0xc], edi

.use_merged_block:
    mov esi, edi
    jmp short .update_heap_counters

.insert_free_block:
    inc dword [ebx + 0x1c]
    mov dword [esi + 8], edx
    mov dword [esi + 4], edi
    mov dword [edi + 8], esi
    mov edi, edx
    mov dword [edi + 4], esi

.update_heap_counters:
    dec dword [ebx + 0x18]
    cmp esi, dword [ebx + 0xc]
    jae short .check_largest_free_block
    cmp ecx, dword [ebx + 0x10]
    jbe short .check_largest_free_block
    mov dword [ebx + 0x10], ecx

.check_largest_free_block:
    cmp ecx, dword [ebx + 0x14]
    jbe short memfree_shared_return
    mov dword [ebx + 0x14], ecx

memfree_shared_return:
    pop ds
    pop ecx
    pop edi
    pop esi
    ret
