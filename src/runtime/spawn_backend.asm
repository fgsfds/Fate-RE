; Build a child environment and command tail, then invoke DOS EXEC.
BITS 32
ORG 0x67603

translate_exec_result equ 0x65718
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

    times 312 db 0    ; The environment builder is supplied by C.

    times 85 db 0    ; build_command_tail is supplied by C.

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
