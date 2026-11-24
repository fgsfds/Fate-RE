; Unmatched VESA BIOS input and transfer boundaries; six C phases own the rest.
; Initialize VESA mode.
BITS 32
ORG 0x43d49

software_framebuffer equ 0x13ff0
vesa_pm_set_window equ 0x13ff5
vesa_pm_set_display_start equ 0x13ff9
dpmi_real_mode_interrupt equ 0x4380a
dpmi_real_mode_far_call equ 0x438f9
allocate_video_dos_memory equ 0x43a50
restore_ebp_edi_esi_ecx_ebx equ 0x50347
vesa_controller_info equ 0x1ec2a0
vesa_mode_list_far_pointer equ 0x1ec2ae
video_page_size equ 0x286b70
use_software_framebuffer equ 0x286b84

initialize_vesa_mode equ 0x43d0c
initialize_vesa_mode_asm:
; vesa_init_probe_inputs
    mov ebx, 0x200
    lea eax, [esp + 0x100]
    mov [esp + 0x100], dx
    mov edx, vesa_controller_info
    call allocate_video_dos_memory
    xor eax, eax
    mov ax, [esp + 0x100]
    cmp eax, 0x4f
section .gap1 align=1 vstart=0x43da5 follows=.text
; vesa_init_list_address
    mov edx, [vesa_mode_list_far_pointer]
    xor ax, ax
    and edx, strict dword 0xffff
    shr eax, byte 0xc
section .gap2 align=1 vstart=0x43dfe follows=.gap1
; vesa_init_mode_predicates
    xor eax, eax
    mov al, [esp + 0x1b]
    cmp eax, 0x4
    jnz near 0x4410c
    xor eax, eax
    mov al, [esp + 0x19]
    cmp eax, 0x8
    jnz near 0x4410c
    xor eax, eax
    mov al, [esp + 0x18]
    cmp eax, 0x1
section .gap3 align=1 vstart=0x43e65 follows=.gap2
; vesa_init_bios_and_pm
    mov eax, [esp]
    mov ecx, 0x4f02
    xor ah, ah
    mov [esp + 0x100], cx
    and al, 0x80
    mov dx, [ebx]
    shl eax, byte 0x7
    lea ebx, [esp + 0x100]
    or edx, eax
    mov eax, 0x10
    mov [esp + 0x102], dx
    lea edx, [esp + 0x100]
    lea ecx, [esp + 0x110]
    call dpmi_real_mode_interrupt
    mov eax, 0x4f0a
    lea ebx, [esp + 0x100]
    xor edx, edx
    mov [esp + 0x100], ax
    mov [esp + 0x102], dx
    mov [esp + 0x104], dx
    mov [esp + 0x106], dx
    lea edx, [esp + 0x100]
    mov eax, 0x10
    call dpmi_real_mode_far_call
    xor eax, eax
    mov ax, [esp + 0x100]
    cmp eax, 0x4f
    jnz short 0x43f24
    xor eax, eax
    xor ebx, ebx
    mov ax, [esp + 0x110]
    mov bx, [esp + 0x10a]
    shl eax, byte 0x4
    add ebx, eax
    movsx eax, word [ebx]
    add eax, ebx
    mov [vesa_pm_set_window], eax
    movsx eax, word [ebx + 0x2]
    add eax, ebx
    mov [vesa_pm_set_display_start], eax
    mov eax, [esp]
    xor ah, ah
    and al, 0x80
    cwde
    test eax, eax
section .gap4 align=1 vstart=0x44093 follows=.gap3
; vesa_init_software_fallback
    mov edi, 0x1
    mov [video_page_size], eax
    mov eax, [software_framebuffer]
    mov [use_software_framebuffer], edi
section .gap5 align=1 vstart=0x44137 follows=.gap4
; vesa_init_shared_return
    jmp near restore_ebp_edi_esi_ecx_ebx
