; Legacy BIOS input boundaries and shared restore jump.
; Initialize VESA mode.
BITS 32
ORG 0x43d62

dpmi_real_mode_interrupt equ 0x4380a
dpmi_real_mode_far_call equ 0x438f9
allocate_video_dos_memory equ 0x43a50
restore_ebp_edi_esi_ecx_ebx equ 0x50347

initialize_vesa_mode equ 0x43d0c
initialize_vesa_mode_asm:
; vesa_init_controller_bios_call
    call allocate_video_dos_memory
section .gap1 align=1 vstart=0x43ea3 follows=.text
; vesa_init_setmode_bios_call
    call dpmi_real_mode_interrupt
section .gap2 align=1 vstart=0x43ee2 follows=.gap1
; vesa_init_pm_bios_call
    call dpmi_real_mode_far_call
section .gap3 align=1 vstart=0x44137 follows=.gap2
; vesa_init_shared_return
    jmp near restore_ebp_edi_esi_ecx_ebx
