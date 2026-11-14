; Graphics runtime entry points.
BITS 32
ORG 0x70064

set_and_query_bios_mode equ 0x72180
color_text_offset equ 0x16d09
color_text_selector equ 0x16cfb
apply_graphics_mode_state equ 0x6fe1e

set_cga_graphics_mode:
    push ebx
    push ecx
    push edx
    mov edx, eax
    cwde
    call set_and_query_bios_mode
    cmp ax, dx
    jne short .failed
    cmp dx, 6
    jne short .two_bit
    push 0
    push 0
    push dword [color_text_offset]
    movsx eax, word [color_text_selector]
    push eax
    mov edx, 0xc8
    mov ebx, 2
    push 1
    mov ecx, 1
    mov eax, 0x280
    jmp short .apply
.two_bit:
    push 0
    push 0
    push dword [color_text_offset]
    movsx eax, word [color_text_selector]
    push eax
    mov edx, 0xc8
    mov ebx, 4
    push 1
    mov ecx, 2
    mov eax, 0x140
.apply:
    call apply_graphics_mode_state
    mov eax, 1
    pop edx
    pop ecx
    pop ebx
    ret
.failed:
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret
