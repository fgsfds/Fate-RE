; Program the PIT and manage the DOS timer interrupt vector.
BITS 32
ORG 0x64cfd

inside_timer_irq equ 0x16526
saved_stack equ 0x14516
saved_stack_selector equ 0x1451a
irq_stack equ 0x1450e
dispatch_stack equ 0x1651e
dispatch_offset equ 0x14508
pit_programming_enabled equ 0x16528
dispatch_selector equ 0x1450c
irq_stack_selector equ 0x14512
use_dpmi_vector equ 0x1652c
old_vector_offset equ 0x144fc
old_vector_selector equ 0x14500
saved_chain_eax equ 0x16522
get_runtime_ds equ 0x601d4

timer_irq:
    push ax
    mov ax, 0x20
    out 0x20, al
    pop ax
    push ds
    call get_runtime_ds
    cmp word [inside_timer_irq], 1
    je short .return_from_irq
    nop
    nop
    nop
    nop
    sti
    push ax
    mov ax, 0x20
    out 0x20, al
    pop ax
    mov word [inside_timer_irq], 1
    mov dword [saved_stack], esp
    o16 mov word [saved_stack_selector], ss
    lss esp, [irq_stack]
    pushad
    push es
    push fs
    push gs
    push ds
    pop es
    mov dword [dispatch_stack], esp
    call dword [dispatch_offset]
    pop gs
    pop fs
    pop es
    popad
    lss esp, [saved_stack]
    mov word [inside_timer_irq], 0

.return_from_irq:
    pop ds
    iretd

program_pit equ 0x64d6f
    times 70 db 0    ; program_pit is supplied by C.

install_timer_vector:
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP uses the register-destination opcode.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    mov edi, dword [ebp + 0xc]
    mov dword [dispatch_offset], edi
    o16 mov word [dispatch_selector], ds
    o16 mov word [irq_stack_selector], ds
    cmp dword [pit_programming_enabled], 0
    je near .restore_registers
    mov dx, 0x21
    in al, dx
    or al, 1
    out dx, al
    cmp dword [use_dpmi_vector], 0
    je short .install_dos_vector
    nop
    nop
    nop
    nop
    mov ax, 0x204
    mov bl, 8
    int 0x31
    mov dword [old_vector_offset], edx
    mov word [old_vector_selector], cx
    mov ax, 0x205
    mov bl, 8
    mov edx, timer_irq - 0x10000
    mov cx, cs
    int 0x31
    jmp short .program_initial_divisor
    nop
    nop
    nop

.install_dos_vector:
    mov ax, 0x3508
    int 0x21
    mov dword [old_vector_offset], ebx
    o16 mov word [old_vector_selector], es
    push ds
    db 0x66, 0x33, 0xc0 ; XOR AX, AX uses the register-destination opcode.
    mov es, eax
    mov ax, 0x2508
    mov edx, timer_irq - 0x10000
    push cs
    pop ds
    int 0x21
    pop ds

.program_initial_divisor:
    mov dx, 0x43
    mov al, 0x36
    out dx, al
    mov dx, 0x40
    mov eax, dword [ebp + 8]
    out dx, al
    db 0x8a, 0xc4 ; MOV AL, AH uses the register-destination opcode.
    out dx, al
    mov dx, 0x21
    in al, dx
    and al, 0xfe
    out dx, al

.restore_registers:
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

mask_timer_irq equ 0x64e70
    times 44 db 0    ; mask_timer_irq is supplied by C.
unmask_timer_irq equ 0x64e9c
    times 44 db 0    ; unmask_timer_irq is supplied by C.

restore_timer_vector:
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP uses the register-destination opcode.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    cmp dword [pit_programming_enabled], 0
    je short .restore_registers
    nop
    nop
    nop
    nop
    mov dx, 0x21
    in al, dx
    or al, 1
    out dx, al
    cmp dword [use_dpmi_vector], 0
    je short .restore_dos_vector
    nop
    nop
    nop
    nop
    mov ax, 0x205
    mov bl, 8
    mov cx, word [old_vector_selector]
    mov edx, dword [old_vector_offset]
    int 0x31
    jmp short .reset_divisor
    nop
    nop
    nop

.restore_dos_vector:
    push ds
    mov ax, 0x2508
    mov cx, word [old_vector_selector]
    mov edx, dword [old_vector_offset]
    mov ds, ecx
    int 0x21
    pop ds

.reset_divisor:
    mov dx, 0x40
    mov ax, 0
    out dx, al
    out dx, al
    mov dx, 0x21
    in al, dx
    and al, 0xfe
    out dx, al

.restore_registers:
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

chain_original_timer:
    cmp dword [pit_programming_enabled], 0
    je short .return_without_chaining
    nop
    nop
    nop
    nop
    mov word [inside_timer_irq], 0
    mov esp, dword [dispatch_stack]
    pop gs
    pop fs
    pop es
    popad
    lss esp, [saved_stack]
    mov dword [saved_chain_eax], eax
    pop eax
    mov word [dispatch_stack], ax
    push eax
    push eax
    mov eax, dword [old_vector_offset]
    mov dword [esp], eax
    mov eax, dword [old_vector_selector]
    mov dword [esp + 4], eax
    mov eax, dword [saved_chain_eax]
    push eax
    mov ax, word [dispatch_stack]
    mov ds, eax
    pop eax
    retf

.return_without_chaining:
    ret

timer_vector_noop_c_slot:
    db 0 ; Byte supplied by timer_vector_noop.c.
