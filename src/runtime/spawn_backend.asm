; Build a child environment and command tail, then invoke DOS EXEC.
BITS 32
ORG 0x67603

strlen equ 0x60381
malloc equ 0x6126d
set_errno equ 0x6468e
set_runtime_error equ 0x646b1
copy_c_string equ 0x675f4
strcpy equ 0x60333
free equ 0x6170a
translate_exec_result equ 0x65718
environment_vector equ 0x173d8
heap_allocation_unit equ 0x17498
exec_environment equ 0x173e0
exec_environment_selector equ 0x173e4
exec_command_tail equ 0x173e6
exec_command_selector equ 0x173ea
exec_fcb1_offset equ 0x173ec
exec_fcb1_selector equ 0x173f0
exec_fcb2_offset equ 0x173f2
exec_fcb2_selector equ 0x173f6
exec_reserved_1 equ 0x173f8
exec_reserved_2 equ 0x173fc
saved_stack_pointer equ 0x17400
saved_stack_selector equ 0x17404
saved_data_selector equ 0x17406
exec_in_progress equ 0x14494

build_child_environment:
    push esi
    push edi
    enter 8, 0
    mov esi, eax
    mov edi, edx
    mov dword [ebp - 4], ebx
    test edx, edx
    jne short measure_environment
    mov edi, dword [environment_vector]

measure_environment:
    xor ebx, ebx
    test edi, edi
    je short count_terminator
    mov edx, edi
    jmp short check_environment_entry

count_environment_string:
    mov eax, dword [edx]
    call strlen
    inc eax
    add edx, 4
    add ebx, eax

check_environment_entry:
    cmp dword [edx], 0
    jne short count_environment_string

count_terminator:
    inc ebx
    cmp dword [ebp + 0x18], 0
    je short allocate_environment
    mov eax, dword [esi]
    call strlen
    add eax, 3
    add ebx, eax

allocate_environment:
    mov eax, dword [heap_allocation_unit]
    add ebx, 0xf
    mov dword [ebp - 8], eax
    mov eax, ebx
    mov dword [heap_allocation_unit], 0x10
    call malloc
    test eax, eax
    jne short save_environment_pointer
    mov eax, ebx
    call malloc
    test eax, eax
    jne short save_environment_pointer
    mov eax, 5
    call set_errno
    mov eax, 8
    call set_runtime_error
    mov eax, dword [ebp - 8]
    mov dword [heap_allocation_unit], eax

return_failure:
    mov eax, 0xffffffff
    jmp near return_environment

save_environment_pointer:
    mov edx, dword [ebp - 8]
    mov dword [heap_allocation_unit], edx
    mov edx, dword [ebp - 4]
    mov dword [edx], eax
    mov edx, dword [ebp + 0x10]
    mov dword [edx], 0
    mov dword [ecx], eax
    test edi, edi
    je short terminate_environment
    mov ecx, edi
    jmp short check_copy_entry

copy_environment_string:
    mov edx, dword [ecx]
    call copy_c_string
    inc eax
    add ecx, 4

check_copy_entry:
    cmp dword [ecx], 0
    jne short copy_environment_string

terminate_environment:
    mov byte [eax], 0
    inc eax
    cmp dword [ebp + 0x18], 0
    je short measure_arguments
    inc eax
    inc eax
    mov edx, dword [esi]
    call strcpy

measure_arguments:
    xor edx, edx
    cmp dword [esi], 0
    je short check_command_length
    add esi, 4
    jmp short check_argument

count_argument:
    test edx, edx
    je short measure_argument
    inc edx

measure_argument:
    call strlen
    add esi, 4
    add edx, eax

check_argument:
    mov eax, dword [esi]
    test eax, eax
    jne short count_argument

check_command_length:
    cmp edx, 0x7e
    jbe short return_paragraph_count
    mov eax, 2
    call set_errno
    mov eax, 0xa
    call set_runtime_error
    mov eax, dword [ebp - 4]
    mov eax, dword [eax]
    call free
    jmp near return_failure

return_paragraph_count:
    mov eax, dword [ebp + 0x14]
    mov dword [eax], 0x90
    mov eax, ebx
    shr eax, 4

return_environment:
    leave
    pop edi
    pop esi
    ret 0xc

build_command_tail:
    push esi
    enter 4, 0
    mov esi, edx
    mov dword [ebp - 4], ebx
    test ecx, ecx
    jne short skip_program_name
    inc ebx

skip_program_name:
    cmp dword [esi], 0
    je short terminate_command_tail
    add esi, 4
    cmp dword [esi], 0
    je short terminate_command_tail

copy_argument:
    mov eax, ebx
    mov edx, dword [esi]
    call copy_c_string
    add esi, 4
    mov edx, eax
    mov ebx, eax
    cmp dword [esi], 0
    je short terminate_command_tail
    lea ebx, [eax + 1]
    mov byte [eax], 0x20
    jmp short copy_argument

terminate_command_tail:
    test ecx, ecx
    je short store_dos_tail_length
    mov byte [ebx], 0
    leave
    pop esi
    ret

store_dos_tail_length:
    mov dl, bl
    mov byte [ebx], 0xd
    sub dl, byte [ebp - 4]
    mov ebx, dword [ebp - 4]
    dec dl
    mov byte [ebx], dl
    leave
    pop esi
    ret

dos_exec:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push edx
    push ecx
    push ebx
    push es
    push ds
    mov ax, ss
    mov ds, eax
    mov eax, dword [ebp + 0x14]
    mov dword [exec_environment], eax
    db 0x66 ; Preserve the original redundant segment-move prefix.
    mov [exec_environment_selector], ds
    sub eax, eax
    mov dword [exec_fcb1_offset], eax
    mov dword [exec_fcb2_offset], eax
    mov word [exec_fcb1_selector], ax
    mov word [exec_fcb2_selector], ax
    mov dword [exec_reserved_1], eax
    mov dword [exec_reserved_2], eax
    mov eax, dword [ebp + 0x10]
    mov dword [exec_command_tail], eax
    db 0x66 ; Preserve the original redundant segment-move prefix.
    mov [exec_command_selector], ds
    push ds
    pop es
    push ebp
    push es
    push ds
    db 0x66 ; Preserve the original redundant segment-move prefix.
    mov [saved_stack_selector], ss
    mov dword [saved_stack_pointer], esp
    db 0x66 ; Preserve the original redundant segment-move prefix.
    mov [saved_data_selector], ds
    db 0x3e ; Preserve the original DS prefix on the immediate load.
    mov ebx, exec_environment
    cmp dword [ebp + 8], 1
    jne short select_load_and_execute
    mov al, 4
    xor ecx, ecx
    jmp short prepare_exec

select_load_and_execute:
    xor al, al

prepare_exec:
    clc
    push eax
    mov ah, 0xb
    int 0x21
    pop eax
    mov dword [exec_in_progress], 1
    mov edx, dword [ebp + 0xc]
    mov ah, 0x4b
    int 0x21
    db 0x66 ; Preserve the original redundant segment-move prefix.
    mov ss, [saved_stack_selector]
    mov esp, dword [saved_stack_pointer]
    db 0x66 ; Preserve the original redundant segment-move prefix.
    mov ds, [saved_data_selector]
    pop ds
    mov dword [exec_in_progress], 0
    pop es
    pop ebp
    jb short convert_exec_status
    mov ah, 0x4d
    int 0x21

convert_exec_status:
    sbb edx, edx
    movzx eax, ax
    call translate_exec_result
    pop ds
    pop es
    pop ebx
    pop ecx
    pop edx
    pop edi
    pop esi
    pop ebp
    ret
