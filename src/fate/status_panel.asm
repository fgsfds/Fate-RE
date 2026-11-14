; Draw the status panel, numeric fields, and conditional icons.
BITS 32
ORG 0x1067a

format_string equ 0x601f3
draw_tile equ 0x57181
draw_number_text equ 0x385f4

number_format equ 0xe4
show_left_icon equ 0x2038
show_middle_icon equ 0x203a
show_right_icon equ 0x203c
status_left_value equ 0x225d
status_left_tenths equ 0x2263
status_right_values equ 0x2277
status_right_index equ 0x2be2
status_right_tenths equ 0x6319c
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

%macro draw_status_number 3
    test eax, eax
    jge short %%format
    xor eax, eax
%%format:
    push eax
    push number_format
    lea eax, [esp+8]
    push eax
    lea ecx, [esp+12]
    call format_string
    add esp, 12
    mov ebx, %1
    mov edx, [panel_top]
    push 0
    mov eax, %2
    add edx, %3
    call draw_number_text
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

    push_panel_clip ebp, eax, edx, ebx
    xor ecx, ecx
    mov eax, 0x1060000
    push 0
    mov edx, [panel_top]
    mov ebx, 0x10000
    push 0x82c
    shl edx, 16
    call draw_tile

    movsx eax, word [status_left_value]
    draw_status_number -1, 27, 13
    mov dx, [status_right_index]
    test dx, dx
    jl short .no_right_value
    movsx eax, dx
    movsx eax, word [nosplit eax*2+status_right_values]
    jmp short .draw_right_value
.no_right_value:
    xor eax, eax
.draw_right_value:
    draw_status_number 1, 27, 31
    movsx edx, word [status_left_tenths]
    mov ecx, 10
    mov eax, edx
    sar edx, 31
    idiv ecx
    draw_status_number -1, 284, 13
    mov eax, [status_right_tenths]
    mov edx, eax
    mov ecx, 10
    sar edx, 31
    idiv ecx
    draw_status_number 1, 284, 31

    cmp word [show_left_icon], 0
    je short .check_middle_icon
    push_panel_clip ecx, esi, edi, ebp
    mov ebx, 0x10000
    mov edx, [panel_top]
    push 0
    mov eax, 0x90000
    add edx, 2
    push 0x82a
    shl edx, 16
    xor ecx, ecx
    call draw_tile
.check_middle_icon:
    cmp word [show_middle_icon], 0
    je short .check_right_icon
    push_panel_clip eax, edx, ebx, ecx
    mov eax, 0x1a0000
    mov edx, [panel_top]
    push 0
    mov ebx, 0x10000
    add edx, 2
    push 0x829
    shl edx, 16
    xor ecx, ecx
    call draw_tile
.check_right_icon:
    cmp word [show_right_icon], 0
    je short .return
    push_panel_clip esi, edi, ebp, eax
    mov ebx, 0x10000
    mov edx, [panel_top]
    push 0
    xor ecx, ecx
    add edx, 2
    push 0x82b
    shl edx, 16
    mov eax, 0x2a0000
    call draw_tile
.return:
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
