; Manage the DOS timer callback slots and fixed-point tick accumulators.
BITS 32
ORG 0x60b2b

pit_programming_enabled equ 0x16528
use_dpmi_vector equ 0x1652c
timer_flags equ 0x166c4
pit_divisor equ 0x166c8
timer_callbacks equ 0x166cc
timer_frequencies equ 0x1670c
timer_increments equ 0x1674c
timer_accumulators equ 0x1678c
timer_contexts equ 0x167cc
current_timer_context equ 0x1680c
program_pit equ 0x64d6f
install_timer_vector equ 0x64db5
mask_timer_irq equ 0x64e70
unmask_timer_irq equ 0x64e9c
restore_timer_vector equ 0x64ec8
default_timer_slot equ 0x16708
default_timer_frequency equ 0x16748
default_timer_increment equ 0x16788
chain_original_timer equ 0x64f44

timer_module_noop:
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

timer_initialize:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0xc], edx
    test byte [ebp - 0xc], 2
    je short .use_dos_vector
    mov byte [use_dpmi_vector], 1
    jmp short .check_install_flag

.use_dos_vector:
    mov byte [use_dpmi_vector], 0

.check_install_flag:
    test byte [ebp - 0xc], 1
    jne short .clear_install_flag
    mov byte [pit_programming_enabled], 1
    or byte [timer_flags], 1
    call mask_timer_irq
    mov eax, timer_dispatch_callbacks - 0x10000
    push eax
    push 0xffff
    call install_timer_vector
    add esp, 8
    call unmask_timer_irq
    jmp short .check_initial_frequency

.clear_install_flag:
    and byte [timer_flags], 0xfe

.check_initial_frequency:
    cmp dword [ebp - 0x10], 0
    je short .branch_60baf
    test byte [ebp - 0xc], 1
    je short .select_initial_divisor

.branch_60baf:
    jmp short .record_default_divisor

.select_initial_divisor:
    cmp dword [ebp - 0x10], 0xff00
    jne short .calculate_initial_divisor
    mov eax, 0xffff
    call timer_set_divisor
    mov dword [default_timer_frequency], 0xff00
    jmp short .initialize_default_slot

.calculate_initial_divisor:
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 0x10]
    call timer_set_divisor
    mov eax, dword [ebp - 0x10]
    mov dword [default_timer_frequency], eax

.initialize_default_slot:
    mov dword [default_timer_slot], default_timer_callback - 0x10000
    mov dword [default_timer_increment], 0x10000
    jmp short .return_init_status

.record_default_divisor:
    mov dword [pit_divisor], 0xffff

.return_init_status:
    mov dword [ebp - 8], 0
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

timer_shutdown:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 8
    mov dword [ebp - 8], eax
    test byte [timer_flags], 1
    je short .return_shutdown_status
    call mask_timer_irq
    call restore_timer_vector
    call unmask_timer_irq

.return_shutdown_status:
    mov dword [ebp - 4], 0
    mov eax, dword [ebp - 4]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

timer_register_callback:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x20
    mov dword [ebp - 0x20], eax
    mov dword [ebp - 0x1c], edx
    mov dword [ebp - 0x18], ebx
    mov dword [ebp - 0xc], 0
    mov dword [ebp - 4], 0

.branch_60c74:
    cmp dword [ebp - 4], 0x10
    jb short .branch_60c81
    jmp short .branch_60c90

.branch_60c7c:
    inc dword [ebp - 4]
    jmp short .branch_60c74

.branch_60c81:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    jne short .branch_60c7c

.branch_60c90:
    cmp dword [ebp - 4], 0x10
    jb short .branch_60ca2
    mov dword [ebp - 0x14], 0xb
    jmp near .branch_60e37

.branch_60ca2:
    test byte [timer_flags], 1
    je short .branch_60cb0
    call mask_timer_irq

.branch_60cb0:
    mov eax, dword [ebp - 4]
    mov dword [ebp - 8], eax
    mov edx, dword [ebp - 4]
    shl edx, 2
    mov eax, dword [ebp - 0x1c]
    mov dword [edx + timer_callbacks], eax
    mov edx, dword [ebp - 4]
    shl edx, 2
    mov eax, dword [ebp - 0x20]
    mov dword [edx + timer_frequencies], eax
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 0x20]
    cmp eax, dword [pit_divisor]
    jae short .branch_60d13
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 0x20]
    call timer_set_divisor
    mov ecx, dword [pit_divisor]
    shl ecx, 0x10
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 0x20]
    mov ebx, eax
    xor edx, edx
    mov eax, ecx
    div ebx
    mov dword [ebp - 0xc], eax

.branch_60d13:
    mov dword [ebp - 4], 0

.branch_60d1a:
    cmp dword [ebp - 4], 0x10
    jb short .branch_60d2a
    jmp near .branch_60e1a

.branch_60d25:
    inc dword [ebp - 4]
    jmp short .branch_60d1a

.branch_60d2a:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    je near .branch_60e15
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_frequencies], 0xff00
    jne short .branch_60d95
    cmp dword [pit_divisor], 0xffff
    jne short .branch_60d6d
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], 0x10000
    jmp short .branch_60d93

.branch_60d6d:
    xor edx, edx
    mov eax, 0x1234dc
    div dword [pit_divisor]
    mov ebx, eax
    xor edx, edx
    mov eax, 0x123333
    div ebx
    mov ebx, eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], ebx

.branch_60d93:
    jmp short .branch_60dc7

.branch_60d95:
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov ecx, dword [eax + timer_frequencies]
    shl ecx, 0x10
    xor edx, edx
    mov eax, 0x1234dc
    div dword [pit_divisor]
    mov ebx, eax
    xor edx, edx
    mov eax, ecx
    div ebx
    mov ebx, eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], ebx

.branch_60dc7:
    cmp dword [ebp - 0xc], 0
    je short .branch_60e15
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov edx, dword [ebp - 0xc]
    and edx, 0xffff
    mov eax, dword [eax + timer_accumulators]
    imul eax, edx
    shr eax, 0x10
    mov dword [ebp - 0x10], eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov edx, dword [ebp - 0xc]
    shr edx, 0x10
    mov eax, dword [eax + timer_accumulators]
    imul eax, edx
    shr eax, 0x10
    add dword [ebp - 0x10], eax
    mov edx, dword [ebp - 4]
    shl edx, 2
    mov eax, dword [ebp - 0x10]
    mov dword [edx + timer_accumulators], eax

.branch_60e15:
    jmp near .branch_60d25

.branch_60e1a:
    test byte [timer_flags], 1
    je short .branch_60e28
    call unmask_timer_irq

.branch_60e28:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 0x18]
    mov dword [edx], eax
    mov dword [ebp - 0x14], 0

.branch_60e37:
    mov eax, dword [ebp - 0x14]
    leave
    pop edi
    pop esi
    pop ecx
    ret

timer_set_frequency:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0xc], edx
    cmp dword [ebp - 0x10], 0x10
    jb short .branch_60e64
    mov dword [ebp - 8], 0xa
    jmp near .branch_60f9e

.branch_60e64:
    mov eax, dword [ebp - 0x10]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    je near .branch_60f8e
    test byte [timer_flags], 1
    je short .branch_60e85
    call mask_timer_irq

.branch_60e85:
    mov edx, dword [ebp - 0x10]
    shl edx, 2
    mov eax, dword [ebp - 0xc]
    mov dword [edx + timer_frequencies], eax
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 0xc]
    cmp eax, dword [pit_divisor]
    jae short .branch_60eb5
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 0xc]
    call timer_set_divisor

.branch_60eb5:
    mov dword [ebp - 4], 0

.branch_60ebc:
    cmp dword [ebp - 4], 0x10
    jb short .branch_60ecc
    jmp near .branch_60f7e

.branch_60ec7:
    inc dword [ebp - 4]
    jmp short .branch_60ebc

.branch_60ecc:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    je near .branch_60f79
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_frequencies], 0xff00
    jne short .branch_60f37
    cmp dword [pit_divisor], 0xffff
    jne short .branch_60f0f
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], 0x10000
    jmp short .branch_60f35

.branch_60f0f:
    xor edx, edx
    mov eax, 0x1234dc
    div dword [pit_divisor]
    mov ebx, eax
    xor edx, edx
    mov eax, 0x123333
    div ebx
    mov ebx, eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], ebx

.branch_60f35:
    jmp short .branch_60f69

.branch_60f37:
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov ecx, dword [eax + timer_frequencies]
    shl ecx, 0x10
    xor edx, edx
    mov eax, 0x1234dc
    div dword [pit_divisor]
    mov ebx, eax
    xor edx, edx
    mov eax, ecx
    div ebx
    mov ebx, eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], ebx

.branch_60f69:
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_accumulators], 0

.branch_60f79:
    jmp near .branch_60ec7

.branch_60f7e:
    test byte [timer_flags], 1
    je short .branch_60f8c
    call unmask_timer_irq

.branch_60f8c:
    jmp short .branch_60f97

.branch_60f8e:
    mov dword [ebp - 8], 0xa
    jmp short .branch_60f9e

.branch_60f97:
    mov dword [ebp - 8], 0

.branch_60f9e:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

timer_remove_callback:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 8], 0
    mov eax, dword [ebp - 0x10]
    shl eax, 2
    mov dword [eax + timer_callbacks], 0
    mov dword [ebp - 4], 0

.branch_60fd6:
    cmp dword [ebp - 4], 0x10
    jb short .branch_60fe3
    jmp short .branch_61028

.branch_60fde:
    inc dword [ebp - 4]
    jmp short .branch_60fd6

.branch_60fe3:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    je short .branch_61026
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov eax, dword [eax + timer_frequencies]
    cmp eax, dword [ebp - 8]
    jbe short .branch_61015
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_frequencies], 0xff00
    jne short .branch_61017

.branch_61015:
    jmp short .branch_61026

.branch_61017:
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov eax, dword [eax + timer_frequencies]
    mov dword [ebp - 8], eax

.branch_61026:
    jmp short .branch_60fde

.branch_61028:
    cmp dword [ebp - 8], 0
    je short .branch_6103f
    xor edx, edx
    mov eax, 0x1234dc
    div dword [ebp - 8]
    call timer_set_divisor
    jmp short .branch_61049

.branch_6103f:
    mov eax, 0xffff
    call timer_set_divisor

.branch_61049:
    test byte [timer_flags], 1
    je short .branch_61057
    call mask_timer_irq

.branch_61057:
    mov dword [ebp - 4], 0

.branch_6105e:
    cmp dword [ebp - 4], 0x10
    jb short .branch_6106e
    jmp near .branch_61120

.branch_61069:
    inc dword [ebp - 4]
    jmp short .branch_6105e

.branch_6106e:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    je near .branch_6111b
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_frequencies], 0xff00
    jne short .branch_610d9
    cmp dword [pit_divisor], 0xffff
    jne short .branch_610b1
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], 0x10000
    jmp short .branch_610d7

.branch_610b1:
    xor edx, edx
    mov eax, 0x1234dc
    div dword [pit_divisor]
    mov ebx, eax
    xor edx, edx
    mov eax, 0x123333
    div ebx
    mov ebx, eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], ebx

.branch_610d7:
    jmp short .branch_6110b

.branch_610d9:
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov ecx, dword [eax + timer_frequencies]
    shl ecx, 0x10
    xor edx, edx
    mov eax, 0x1234dc
    div dword [pit_divisor]
    mov ebx, eax
    xor edx, edx
    mov eax, ecx
    div ebx
    mov ebx, eax
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_increments], ebx

.branch_6110b:
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov dword [eax + timer_accumulators], 0

.branch_6111b:
    jmp near .branch_61069

.branch_61120:
    test byte [timer_flags], 1
    je short .branch_6112e
    call unmask_timer_irq

.branch_6112e:
    mov dword [ebp - 0xc], 0
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

timer_get_frequency:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 8
    mov dword [ebp - 8], eax
    mov eax, dword [ebp - 8]
    shl eax, 2
    mov eax, dword [eax + timer_frequencies]
    mov dword [ebp - 4], eax
    mov eax, dword [ebp - 4]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

timer_set_divisor:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 8
    mov dword [ebp - 8], eax
    mov eax, dword [ebp - 8]
    mov dword [pit_divisor], eax
    push dword [ebp - 8]
    call program_pit
    add esp, 4
    mov dword [ebp - 4], 0
    mov eax, dword [ebp - 4]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

timer_dispatch_callbacks:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 4
    mov dword [ebp - 4], 0

.check_callback_slot:
    cmp dword [ebp - 4], 0x10
    jb short .check_callback
    jmp near .restore_dispatch_registers

.advance_callback_slot:
    inc dword [ebp - 4]
    jmp short .check_callback_slot

.check_callback:
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp dword [eax + timer_callbacks], 0
    je short .next_callback
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov edx, dword [ebp - 4]
    shl edx, 2
    mov edx, dword [edx + timer_increments]
    add dword [eax + timer_accumulators], edx
    mov eax, dword [ebp - 4]
    shl eax, 2
    test byte [eax + timer_accumulators + 2], 1
    je short .next_callback
    mov eax, dword [ebp - 4]
    shl eax, 2
    mov word [eax + timer_accumulators + 2], 0
    mov eax, dword [ebp - 4]
    shl eax, 2
    cmp byte [eax + timer_contexts], 0xff
    je short .invoke_callback
    mov eax, dword [ebp - 4]
    shl eax, 2
    movzx eax, byte [eax + timer_contexts]
    mov dword [current_timer_context], eax

.invoke_callback:
    mov eax, dword [ebp - 4]
    shl eax, 2
    call dword [eax + timer_callbacks]

.next_callback:
    jmp short .advance_callback_slot

.restore_dispatch_registers:
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

default_timer_callback:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    call chain_original_timer
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

timer_tail_noop:
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
