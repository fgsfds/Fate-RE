; Retained entry and first drawing setup; fall through to the compiled C body.
BITS 32
ORG 0x1067a

draw_tile equ 0x57181

panel_top equ 0x7f898
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c

%macro push_panel_clip 4
    mov %1, [window_bottom]
    push %1
    mov %2, [window_right]
    push %2
    mov %3, [window_top]
    push %3
    mov %4, [window_left]
    push %4
    push 0x82
    push 0
%endmacro


draw_status_panel:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 4
    push_panel_clip ebx, ecx, esi, edi
    mov edx, 4
    mov eax, 0x50000
    push 0
    mov [panel_top], edx
    mov ebx, 0x10000
    push 0x828
    mov edx, 0x40000
    xor ecx, ecx
    call draw_tile
