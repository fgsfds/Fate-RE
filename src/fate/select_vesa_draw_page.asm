; Select VESA draw page.
BITS 32
ORG 0x4417c

software_framebuffer equ 0x13ff0
vesa_pm_set_window equ 0x13ff5
dpmi_real_mode_interrupt equ 0x4380a
restore_edi_esi_edx_ecx_ebx equ 0x4abbf
linear_page_addresses equ 0x1ec5a0
skip_bank_switch equ 0x286b54
bank_shift equ 0x286b5c
linear_framebuffer_enabled equ 0x286b60
draw_page_address equ 0x286b74
use_software_framebuffer equ 0x286b84

select_vesa_draw_page:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x10
    mov esi, eax
    cmp dword [skip_bank_switch], 0x0
    jnz short .branch_441f1
    mov ebx, [linear_framebuffer_enabled]
    test ebx, ebx
    jnz short .branch_441f1
    mov ecx, 0xa0000
    mov edi, [vesa_pm_set_window]
    mov [draw_page_address], ecx
    test edi, edi
    jz short .branch_441c4
    mov cl, [bank_shift]
    mov edx, eax
    shl edx, cl
    xor eax, eax
    xor ecx, ecx
    call dword [vesa_pm_set_window]
    jmp short .branch_441f1

.branch_441c4:
    mov edx, 0x4f05
    mov cl, [bank_shift]
    xor ebx, ebx
    mov [esp], dx
    mov [esp + 0x2], bx
    mov edx, eax
    mov ebx, esp
    shl edx, cl
    mov eax, 0x10
    mov [esp + 0x6], dx
    mov edx, esp
    call dpmi_real_mode_interrupt

.branch_441f1:
    cmp dword [use_software_framebuffer], 0x0
    jz short .branch_44202
    mov edx, [software_framebuffer]
    jmp short .branch_44212

.branch_44202:
    cmp dword [linear_framebuffer_enabled], 0x0
    jz short .branch_44218
    mov edx, [nosplit esi*4 + linear_page_addresses]

.branch_44212:
    mov [draw_page_address], edx

.branch_44218:
    add esp, 0x10
    jmp near restore_edi_esi_edx_ecx_ebx
