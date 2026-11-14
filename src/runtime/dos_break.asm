; Adjust the DOS extender data break or allocate a separate memory block.
BITS 32
ORG 0x6af69

get_errno_address equ 0x67a09
memory_limit equ 0x1446c
initial_stack_top equ 0x14480
extender_type equ 0x1449a
extender_subtype equ 0x1449b

sbrk_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ecx, eax
    cmp byte [extender_type], 1
    jne short .check_extender_nine
    cmp byte [extender_subtype], 0
    je short .allocate_pages

.check_extender_nine:
    mov dh, byte [extender_type]
    cmp dh, 9
    jne near .adjust_segment

.allocate_pages:
    test ecx, ecx
    jle short .set_invalid_size
    add ecx, 0xfff
    mov al, byte [extender_type]
    and cx, 0xf000
    cmp al, 1
    jne short .allocate_dos_pages
    mov eax, ecx
    sar eax, 0x10
    mov ebx, eax
    mov ah, 5
    mov al, 1
    int 0x31
    sbb eax, eax
    inc eax
    je short .finish_dpmi_allocate
    mov ax, bx
    shl eax, 0x10
    mov ax, cx
    mov word [eax], di
    mov word [eax + 2], si

.finish_dpmi_allocate:
    jmp short .check_allocation

.allocate_dos_pages:
    mov ebx, ecx
    mov eax, 0x80004800
    int 0x21
    sbb ebx, ebx
    not ebx
    and eax, ebx

.check_allocation:
    test eax, eax
    jne short .return
    call get_errno_address
    mov dword [eax], 5
    jmp short .return_error

.set_invalid_size:
    call get_errno_address
    mov dword [eax], 9

.return_error:
    mov eax, 0xffffffff
    jmp short .return

.adjust_segment:
    cmp dh, 2
    jb short .compute_new_limit
    cmp dh, 8
    ja short .compute_new_limit
    xor eax, eax
    mov eax, ds
    lsl eax, eax
    inc eax
    mov dword [memory_limit], eax

.compute_new_limit:
    mov eax, dword [memory_limit]
    add eax, ecx
    call resize_data_segment

.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

resize_data_segment:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es
    push ebp
    push eax
    cmp eax, dword [initial_stack_top]
    jb short .resize_error
    cmp byte [extender_type], 0
    jne short .compute_pages
    mov ebp, dword [esp]
    add ebp, 0xf
    shr ebp, 4
    test ebp, ebp
    jne short .get_dos_selector
    mov ebp, 0xfffffff

.get_dos_selector:
    xor ebx, ebx
    mov eax, ds
    mov bx, ax
    mov ah, 0xed
    int 0x21
    shl eax, 0x1f
    and edi, 0xffff
    or edi, eax
    test edi, edi
    jge short .resize_ds_in_paragraphs
    mov es, di
    mov ebx, ebp
    mov ah, 0x4a
    int 0x21
    rcl eax, 1
    ror eax, 1
    test eax, eax
    jl short .resize_error

.resize_ds_in_paragraphs:
    mov eax, ds
    mov es, ax
    mov ebx, ebp

.resize_segment:
    mov ah, 0x4a
    int 0x21
    rcl eax, 1
    ror eax, 1
    test eax, eax
    jge short .update_limit

.resize_error:
    call get_errno_address
    mov dword [eax], 5
    mov eax, 0xffffffff
    jmp short .restore_segment_register

.compute_pages:
    mov ebx, dword [esp]
    add ebx, 0xfff
    shr ebx, 0xc
    test ebx, ebx
    jne short .check_page_units
    mov ebx, 0xfffff

.check_page_units:
    mov dl, byte [extender_type]
    cmp dl, 1
    jne short .resize_ds_in_pages
    cmp dl, byte [extender_subtype]
    jne short .resize_ds_in_pages
    shl ebx, 8

.resize_ds_in_pages:
    mov eax, ds
    mov es, ax
    jmp short .resize_segment

.update_limit:
    mov ebx, dword [esp]
    mov eax, dword [memory_limit]
    mov dword [memory_limit], ebx

.restore_segment_register:
    add esp, 4
    pop ebp
    pop es
    jmp near sbrk_.return
