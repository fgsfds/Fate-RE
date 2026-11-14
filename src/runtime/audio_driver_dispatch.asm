; Query the driver interface for a selected slot.
BITS 32
ORG 0x662f6

copy_far_driver_interface equ 0x665e5
driver_slots equ 0x1663c

query_driver_interface:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 16
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0xc], edx
    mov eax, dword [ebp - 0x10]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .check_output
    mov dword [ebp - 8], 1
    jmp short .return

.check_output:
    cmp dword [ebp - 0xc], 0
    je short .missing_output
    push dword [ebp - 0xc]
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xe0]
    call copy_far_driver_interface
    add esp, 0x14
    jmp short .success

.missing_output:
    mov dword [ebp - 8], 2
    jmp short .return

.success:
    mov dword [ebp - 8], 0

.return:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

audio_dispatch_noop:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

audio_backend_region_start:
    ret
