; Remaining VESA BIOS boundaries, address conversion and return.
; Initialize VESA mode.
BITS 32
ORG 0x43d62

dpmi_real_mode_interrupt equ 0x4380a
dpmi_real_mode_far_call equ 0x438f9
allocate_video_dos_memory equ 0x43a50
restore_ebp_edi_esi_ecx_ebx equ 0x50347
vesa_mode_list_far_pointer equ 0x1ec2ae
use_software_framebuffer equ 0x286b84

initialize_vesa_mode equ 0x43d0c
initialize_vesa_mode_asm:
; vesa_init_controller_bios_call
    call allocate_video_dos_memory
section .gap1 align=1 vstart=0x43da5 follows=.text
; vesa_init_list_address
    mov edx, [vesa_mode_list_far_pointer]
    xor ax, ax
    and edx, strict dword 0xffff
    shr eax, byte 0xc
section .gap2 align=1 vstart=0x43ea3 follows=.gap1
; vesa_init_setmode_bios_call
    call dpmi_real_mode_interrupt
section .gap3 align=1 vstart=0x43ee2 follows=.gap2
; vesa_init_pm_bios_call
    call dpmi_real_mode_far_call
section .gap4 align=1 vstart=0x43f24 follows=.gap3
; vesa_init_linear_predicate
    mov eax, [esp]
    xor ah, ah
    and al, 0x80
    cwde
    test eax, eax
section .gap5 align=1 vstart=0x44093 follows=.gap4
; vesa_init_software_one
    mov edi, 0x1
section .gap6 align=1 vstart=0x440a2 follows=.gap5
; vesa_init_software_store
    mov [use_software_framebuffer], edi
section .gap7 align=1 vstart=0x44137 follows=.gap6
; vesa_init_shared_return
    jmp near restore_ebp_edi_esi_ecx_ebx
