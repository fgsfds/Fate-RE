; Manage audio workspace using caller hooks or locked heap allocations.
BITS 32
ORG 0x661e2

malloc_ equ 0x6126d
free_ equ 0x6170a
lock_memory_region equ 0x66391
unlock_memory_region equ 0x663ce
allocate_hook equ 0x166bc
release_hook equ 0x166c0

%macro frame 2
    push ebx
    push ecx
%if %2
    push edx
%endif
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword %1
%endmacro

%macro restore 1
    leave
    pop edi
    pop esi
%if %1
    pop edx
%endif
    pop ecx
    pop ebx
    ret
%endmacro

allocate_driver_workspace:
    frame 12, 1
    mov [ebp - 12], eax
    cmp dword [allocate_hook], 0
    je short .allocate_from_heap
    mov eax, [ebp - 12]
    call dword [allocate_hook]
    mov [ebp - 8], eax
    jmp short .return
.allocate_from_heap:
    mov eax, [ebp - 12]
    call malloc_
    mov [ebp - 4], eax
    cmp dword [ebp - 4], 0
    je short .return_pointer
    push dword [ebp - 12]
    push dword [ebp - 4]
    call lock_memory_region
    add esp, 8
    test eax, eax
    je short .return_pointer
    mov dword [ebp - 8], 0
    jmp short .return
.return_pointer:
    mov eax, [ebp - 4]
    mov [ebp - 8], eax
.return:
    mov eax, [ebp - 8]
    restore 1

release_driver_workspace:
    frame 8, 0
    mov [ebp - 8], eax
    mov [ebp - 4], edx
    cmp dword [allocate_hook], 0
    je short .release_heap
    mov edx, [ebp - 4]
    mov eax, [ebp - 8]
    call dword [release_hook]
    jmp short .return
.release_heap:
    push dword [ebp - 4]
    push dword [ebp - 8]
    call unlock_memory_region
    add esp, 8
    mov eax, [ebp - 8]
    call free_
.return:
    restore 0

%macro set_hook 1
    frame 4, 1
    mov [ebp - 4], eax
    mov eax, [ebp - 4]
    mov [%1], eax
    restore 1
%endmacro

set_workspace_allocate_hook:
    set_hook allocate_hook

set_workspace_release_hook:
    set_hook release_hook
