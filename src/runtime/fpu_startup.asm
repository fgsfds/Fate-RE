; Initialize the x87 and install or restore the extender-specific handler.
BITS 32
ORG 0x6439c

install_dpmi_emulator equ 0x6ac6a
remove_dpmi_emulator equ 0x6ad34
initial_fpu_control_word equ 0x17490
fpu_type equ 0x141a8
fpu_handler_installed equ 0x144f4
saved_msw_bits equ 0x144f2
direct_idt_access equ 0x1449c
idt_selector equ 0x1419a
extender_type equ 0x1449a
emulator_handler equ 0x57e2c
extender_handler equ 0x57dbc
extender_services equ 0x14194
extender_selector equ 0x14198
saved_vector_offset equ 0x144ec
saved_vector_selector equ 0x144f0
extender_config equ 0x144ac

runtime_init:
    push es
    push ecx
    push ebx
    push edx
    fninit
    push eax
    fnstcw word [esp]
    pop eax
    cmp ah, 3
    je short check_init_request
    inc ebp

check_init_request:
    or ebp, ebp
    je short reset_fpu
    call install_fpu_handler

reset_fpu:
    wait
    fninit
    fldcw word [initial_fpu_control_word]
    fldz
    fldz
    fldz
    fldz
    pop edx
    pop ebx
    pop ecx
    pop es
    ret

install_fpu_handler:
    mov byte [fpu_type], 3
    mov byte [fpu_handler_installed], 1
    db 0x66 ; Preserve the original operand-size prefix.
    smsw [saved_msw_bits]
    and word [saved_msw_bits], 6
    sub esp, 8
    sidt [esp]
    mov ebx, dword [esp + 2]
    add ebx, 0x38
    add esp, 8
    cmp byte [direct_idt_access], 0
    je short check_native_dos
    call build_interrupt_gate
    db 0x66 ; Preserve the original operand-size prefix.
    mov es, [idt_selector]
    mov dword es:[ebx], edx
    mov dword es:[ebx + 4], ecx
    call enable_extender_emulation
    jmp short return_from_install

check_native_dos:
    cmp byte [extender_type], 0
    jne short check_extender_type_9
    mov ax, 0x2507
    push ds
    mov cx, cs
    mov ds, ecx
    lea edx, [emulator_handler]
    int 0x21
    pop ds
    mov al, 4
    mov ah, 0xf3
    int 0x21
    jmp short return_from_install

check_extender_type_9:
    cmp byte [extender_type], 9
    jne short check_extender_type_1
    call build_interrupt_gate
    mov dword [ebx], edx
    mov dword [ebx + 4], ecx
    mov eax, 0xe02
    mov ebx, 4
    mov ecx, dword [extender_services]
    call dword [ecx + 0x30]
    jmp short return_from_install

check_extender_type_1:
    cmp byte [extender_type], 1
    jne short install_default_emulator
    mov dx, word [extender_selector]
    sub eax, eax
    call install_dpmi_emulator
    jmp short return_from_install

install_default_emulator:
    sub dx, dx
    sub eax, eax
    call install_dpmi_emulator
    cmp al, 1
    je short return_from_install
    call install_extender_vector

return_from_install:
    ret

build_interrupt_gate:
    lea ecx, [emulator_handler]
    mov dx, cs
    shl edx, 0x10
    mov dx, cx
    mov cx, cs
    and cl, 3
    shl cx, 0xd
    or ch, 0x8e
    ret

install_extender_vector:
    mov cl, 7
    mov ax, 0x2502
    int 0x21
    mov dword [saved_vector_offset], ebx
    db 0x66 ; Preserve the original operand-size prefix.
    mov [saved_vector_selector], es
    cmp byte [extender_type], 3
    mov cl, 7
    mov ax, 0x2504
    push ds
    push cs
    pop ds
    jl short install_legacy_vector
    lea edx, [extender_handler]
    int 0x21
    pop ds
    call enable_extender_emulation
    jmp short return_from_vector_install

install_legacy_vector:
    lea edx, [emulator_handler]
    int 0x21
    pop ds
    mov ecx, cr0
    or ecx, 4
    and ecx, 0xfffffffd
    mov cr0, ecx

return_from_vector_install:
    ret

enable_extender_emulation:
    xor ebx, ebx
    lea edx, [extender_config]
    mov ax, 0x2535
    int 0x21
    or dword [extender_config], 4
    and dword [extender_config], 0xfffffffd
    inc ebx
    int 0x21
    ret

runtime_fini:
    cmp byte [fpu_handler_installed], 1
    je short restore_handler
    ret

restore_handler:
    push ecx
    push ebx
    push edx
    mov al, byte [extender_type]
    cmp byte [direct_idt_access], 0
    je short check_restore_type_9
    call restore_extender_emulation
    jmp short clear_installed_flag

check_restore_type_9:
    cmp al, 9
    jne short check_restore_native_dos
    mov eax, 0xe02
    mov ebx, 0
    mov ecx, dword [extender_services]
    call dword [ecx + 0x30]
    jmp short clear_installed_flag

check_restore_native_dos:
    cmp al, 0
    jne short check_restore_type_1
    mov ax, word [saved_msw_bits]
    mov ah, 0xf3
    int 0x21
    jmp short clear_installed_flag

check_restore_type_1:
    cmp al, 1
    jne short remove_default_emulator
    mov dx, word [extender_selector]
    sub eax, eax
    call remove_dpmi_emulator
    jmp short clear_installed_flag

remove_default_emulator:
    sub edx, edx
    call remove_dpmi_emulator
    cmp al, 1
    je short clear_installed_flag
    call restore_extender_vector

clear_installed_flag:
    mov byte [fpu_handler_installed], 0
    pop edx
    pop ebx
    pop ecx
    ret

restore_extender_vector:
    mov cl, 7
    mov ax, 0x2504
    mov edx, dword [saved_vector_offset]
    push ds
    db 0x66 ; Preserve the original operand-size prefix.
    mov ds, [saved_vector_selector]
    int 0x21
    pop ds
    cmp byte [extender_type], 3
    jl short restore_cr0
    call restore_extender_emulation
    jmp short return_from_vector_restore

restore_cr0:
    mov ecx, cr0
    and ecx, 0xfffffff9
    mov dx, word [saved_msw_bits]
    or cx, dx
    mov cr0, ecx

return_from_vector_restore:
    ret

restore_extender_emulation:
    xor ebx, ebx
    lea edx, [extender_config]
    mov ax, 0x2535
    int 0x21
    xor ecx, ecx
    mov cx, word [saved_msw_bits]
    mov dword [extender_config], ecx
    inc ebx
    int 0x21
    ret
