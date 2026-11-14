; Set the selectors and offsets used to access BIOS and video memory.
BITS 32
ORG 0x71b8c

dos_extender_type equ 0x1449a
extender_flags equ 0x1449c
low_memory_selector equ 0x1419a
saved_data_selector equ 0x289238
bios_data_selector equ 0x16cf7
mono_text_selector equ 0x16cf9
color_text_selector equ 0x16cfb
graphics_selector equ 0x16cfd
video_rom_selector equ 0x16cff
bios_data_offset equ 0x16d01
mono_text_offset equ 0x16d05
color_text_offset equ 0x16d09
graphics_offset equ 0x16d0d
video_rom_offset equ 0x16d11

initialize_graphics_memory_windows:
    push edx
    enter 4, 0
    lea eax, [ebp - 4]
    mov edx, ds
    mov word [saved_data_selector], dx
    cmp byte [dos_extender_type], 1
    je short .use_ds
    cmp byte [dos_extender_type], 9
    jne short .check_low_memory
.use_ds:
    mov eax, bios_data_selector
    mov edx, ds
    mov dword [ebp - 4], edx
    jmp short .install_windows
.check_low_memory:
    cmp byte [extender_flags], 0
    je short .done
    mov ax, word [low_memory_selector]
    mov dword [ebp - 4], eax
.install_windows:
    mov eax, dword [ebp - 4]
    mov dword [bios_data_offset], 0x400
    mov dword [mono_text_offset], 0xb0000
    mov dword [color_text_offset], 0xb8000
    mov dword [graphics_offset], 0xa0000
    mov dword [video_rom_offset], 0xc0000
    mov word [bios_data_selector], ax
    mov word [mono_text_selector], ax
    mov word [color_text_selector], ax
    mov word [graphics_selector], ax
    mov word [video_rom_selector], ax
.done:
    leave
    pop edx
    ret
