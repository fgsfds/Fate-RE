; Show intro.
BITS 32
ORG 0x38a16

menu_redraw_pending equ 0x1314f
dispatch_ticks equ 0x35415
presentation_reset equ 0x36246
presentation_input equ 0x3625c
draw_intro_screen equ 0x38808
draw_animated_intro equ 0x388d7
nextpage equ 0x4b496
rotatesprite equ 0x57181
status_right_tenths equ 0x6319c
totalclock equ 0x287e88
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

show_intro:
    push ebx
    push ecx
    push edx
    cmp dword [status_right_tenths], 0x0
    jg short .branch_38a2e
    call presentation_reset
    call draw_animated_intro
    jmp short .branch_38a41

.branch_38a2e:
    cmp byte [menu_redraw_pending], 0x0
    jz short .branch_38a41
    call presentation_reset
    call draw_intro_screen

.branch_38a41:
    call presentation_reset
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict dword 0x92
    push strict byte 0x0
    push strict byte 0x0
    mov ebx, 0x10000
    xor ecx, ecx
    push strict dword 0x838
    xor edx, edx
    xor eax, eax
    call rotatesprite
    call nextpage
    mov edx, [totalclock]
    mov eax, 0x1
    call dispatch_ticks
    add eax, edx

.branch_38a8d:
    cmp eax, [totalclock]
    jg short .branch_38a8d

.branch_38a95:
    call presentation_input
    test eax, eax
    jz short .branch_38a95
    pop edx
    pop ecx
    pop ebx
    ret
