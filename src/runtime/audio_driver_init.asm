; Initialize the DOS audio system and open a digital audio driver.
BITS 32
ORG 0x61768

audio_system_flags equ 0x16538
driver_path equ 0x1653c
driver_slots equ 0x1663c
driver_table_16a64 equ 0x16a64
driver_table_16a84 equ 0x16a84
initialize_audio_backend equ 0x65802
shutdown_audio_backend equ 0x65b74
strcpy equ 0x60333
load_driver_image equ 0x65f10
driver_call_661e2 equ 0x661e2
memset equ 0x61350
driver_call_662f6 equ 0x662f6
driver_call_61e80 equ 0x61e80
driver_call_660f2 equ 0x660f2
driver_call_66b45 equ 0x66b45
driver_call_6684c equ 0x6684c
driver_call_66777 equ 0x66777
driver_call_667fb equ 0x667fb
driver_call_667d5 equ 0x667d5
driver_call_667ac equ 0x667ac

audio_init_noop:
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

audio_system_init:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0xc], edx
    call initialize_audio_backend
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    je short .record_initialized_state
    mov eax, dword [ebp - 4]
    mov dword [ebp - 8], eax
    jmp short .restore_registers

.record_initialized_state:
    or byte [audio_system_flags], 1
    cmp dword [ebp - 0x10], 0
    je short .clear_driver_path
    mov edx, dword [ebp - 0x10]
    mov eax, driver_path
    call strcpy
    jmp short .return_init_success

.clear_driver_path:
    mov byte [driver_path], 0

.return_init_success:
    mov dword [ebp - 8], 0

.restore_registers:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

audio_system_shutdown:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 8
    call shutdown_audio_backend
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    je short .clear_initialized_state
    mov dword [ebp - 8], 0
    jmp short .restore_registers

.clear_initialized_state:
    and byte [audio_system_flags], 0xfe
    mov dword [ebp - 8], 0

.restore_registers:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

audio_noop_61816:
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

audio_noop_6182b:
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

audio_driver_init:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x18
    mov dword [ebp - 0x18], eax
    mov dword [ebp - 0x14], edx
    mov dword [ebp - 4], 0

.check_slot_index:
    cmp dword [ebp - 4], 5
    jb short .check_slot
    jmp short .check_slot_result

.advance_slot:
    inc dword [ebp - 4]
    jmp short .check_slot_index

.check_slot:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + driver_slots], 0
    jne short .advance_slot

.check_slot_result:
    cmp dword [ebp - 4], 6
    jne short .store_driver
    mov dword [ebp - 0x10], 0xb
    jmp near .return_driver_status

.store_driver:
    mov edx, dword [ebp - 4]
    shl edx, 2
    mov eax, dword [ebp - 0x18]
    mov dword [edx + driver_slots], eax
    mov eax, dword [ebp - 0x18]
    cmp dword [eax + 0xd8], 0
    jne near .branch_61934
    mov eax, dword [ebp - 0x18]
    cmp word [eax + 0xdc], 0
    jne near .branch_61934
    mov eax, dword [ebp - 0x18]
    add eax, 0xec
    push eax
    mov eax, dword [ebp - 0x18]
    add eax, 0xe8
    push eax
    mov eax, dword [ebp - 0x18]
    add eax, 0xfc
    push eax
    mov ecx, dword [ebp - 0x18]
    add ecx, 0xd8
    mov ebx, dword [ebp - 0x18]
    add ebx, 0xe0
    mov edx, dword [ebp - 4]
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x104]
    call load_driver_image
    mov dword [ebp - 0xc], eax
    cmp dword [ebp - 0xc], 0
    je short .branch_6190a
    mov eax, dword [ebp - 0xc]
    mov dword [ebp - 0x10], eax
    jmp near .return_driver_status

.branch_6190a:
    mov eax, 0x1e00
    call driver_call_661e2
    mov edx, eax
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x58], edx
    mov eax, 0x4000
    call driver_call_661e2
    mov edx, eax
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x48], edx
    mov eax, dword [ebp - 0x18]
    or byte [eax], 2

.branch_61934:
    mov ebx, 0x1e00
    xor edx, edx
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x58]
    call memset
    mov edx, dword [ebp - 0x18]
    add edx, 0x6c
    mov eax, dword [ebp - 4]
    call driver_call_662f6
    mov dword [ebp - 0xc], eax
    cmp dword [ebp - 0xc], 0
    je short .branch_61968
    mov eax, dword [ebp - 0xc]
    mov dword [ebp - 0x10], eax
    jmp near .return_driver_status

.branch_61968:
    mov eax, dword [ebp - 0x18]
    cmp dword [eax + 0x3c], 0
    jne near .branch_61a5c
    mov eax, dword [ebp - 0x18]
    or byte [eax], 4
    mov ecx, dword [ebp - 0x18]
    add ecx, 0xf4
    mov ebx, dword [ebp - 0x18]
    add ebx, 0x100
    mov edx, dword [ebp - 0x18]
    add edx, 0xf0
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x44]
    call driver_call_61e80
    mov edx, eax
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x3c], edx
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x3c]
    test eax, eax
    jne short .branch_619c7
    mov eax, dword [ebp - 4]
    call driver_call_660f2
    mov dword [ebp - 0x10], 5
    jmp near .return_driver_status

.branch_619c7:
    mov eax, dword [ebp - 0x18]
    cmp dword [eax + 0x90], 8
    jne near .branch_61a35
    mov eax, dword [ebp - 0x18]
    test byte [eax + 0xa9], 0x80
    je short .branch_61a0c
    mov dword [ebp - 8], 0

.branch_619ea:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 0x18]
    cmp eax, dword [edx + 0x44]
    jb short .branch_619fc
    jmp short .branch_61a0a

.branch_619f7:
    inc dword [ebp - 8]
    jmp short .branch_619ea

.branch_619fc:
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x3c]
    add eax, dword [ebp - 8]
    mov byte [eax], 0
    jmp short .branch_619f7

.branch_61a0a:
    jmp short .branch_61a33

.branch_61a0c:
    mov dword [ebp - 8], 0

.branch_61a13:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 0x18]
    cmp eax, dword [edx + 0x44]
    jb short .branch_61a25
    jmp short .branch_61a33

.branch_61a20:
    inc dword [ebp - 8]
    jmp short .branch_61a13

.branch_61a25:
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x3c]
    add eax, dword [ebp - 8]
    mov byte [eax], 0x80
    jmp short .branch_61a20

.branch_61a33:
    jmp short .branch_61a5c

.branch_61a35:
    mov dword [ebp - 8], 0

.branch_61a3c:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 0x18]
    cmp eax, dword [edx + 0x44]
    jb short .branch_61a4e
    jmp short .branch_61a5c

.branch_61a49:
    inc dword [ebp - 8]
    jmp short .branch_61a3c

.branch_61a4e:
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x3c]
    add eax, dword [ebp - 8]
    mov byte [eax], 0
    jmp short .branch_61a49

.branch_61a5c:
    mov eax, dword [ebp - 0x18]
    mov edx, dword [eax + 0x3c]
    mov eax, dword [ebp - 0x18]
    mov ebx, dword [eax + 0x44]
    mov eax, dword [ebp - 0x18]
    add edx, ebx
    mov dword [eax + 0x40], edx
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax + 0x64]
    shl eax, 2
    mov edx, dword [eax + driver_table_16a64]
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x18], edx
    mov eax, dword [ebp - 0x18]
    mov edx, dword [eax + 0x3c]
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x28], edx
    mov eax, dword [ebp - 0x18]
    mov edx, dword [eax + 0x48]
    mov eax, dword [ebp - 0x18]
    add edx, 0x4000
    mov dword [eax + 0x4c], edx
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x50], 0x4000
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x30], 0
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x54], 0xffffffff
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x2c], 0x400
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x14], 0x20
    mov eax, dword [ebp - 0x18]
    mov edx, dword [eax + 0x90]
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0xc], edx
    mov eax, dword [ebp - 0x18]
    mov edx, dword [eax + 0x94]
    inc edx
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 8], edx
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x10], 0x8000
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov edx, dword [eax + driver_table_16a84]
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x108], edx
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x1c], 0
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x20], 0
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x24], 0
    mov eax, dword [ebp - 0x18]
    test byte [eax + 0xa9], 2
    je short .branch_61b7e
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xe0]
    call driver_call_66b45
    mov ebx, edx
    mov ecx, eax
    add esp, 0x10
    mov eax, dword [ebp - 0x18]
    mov word [eax + 0x38], bx
    mov eax, dword [ebp - 0x18]
    mov dword [eax + 0x34], ecx

.branch_61b7e:
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x64]
    call driver_call_6684c
    add esp, 4
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x68]
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x68]
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x68]
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x64]
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x60]
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x5c]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xe0]
    call driver_call_66777
    add esp, 0x28
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xe0]
    call driver_call_667fb
    add esp, 0x10
    mov eax, dword [ebp - 0x18]
    push dword [eax + 4]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xe0]
    call driver_call_667d5
    add esp, 0x14
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0x44]
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xf0]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax + 0xe0]
    call driver_call_667ac
    add esp, 0x18
    mov eax, dword [ebp - 0x18]
    or byte [eax], 1
    mov eax, dword [ebp - 4]
    mov edx, dword [ebp - 0x14]
    mov dword [edx], eax
    mov dword [ebp - 0x10], 0

.return_driver_status:
    mov eax, dword [ebp - 0x10]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
