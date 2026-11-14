; Run mouse button menu.
BITS 32
ORG 0x3abbc

frame_state_122c equ 0x122c
frame_state_1232 equ 0x1232
frame_state_1233 equ 0x1233
frame_state_123b equ 0x123b
frame_state_1248 equ 0x1248
frame_state_13558 equ 0x13558
frame_state_139f4 equ 0x139f4
frame_state_139f7 equ 0x139f7
presentation_input equ 0x3625c
draw_menu_frame equ 0x39511
run_menu_loop equ 0x3963b
format_string equ 0x601f3
mouse_buttons equ 0x7dee2
frame_state_1741f4 equ 0x1741f4
frame_state_174268 equ 0x174268
frame_state_1745ac equ 0x1745ac

run_mouse_button_menu:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    xor ebx, ebx

.branch_3abc4:
    mov eax, [nosplit ebx*4 + frame_state_1741f4]
    xor edx, edx
    mov dword [eax + 0x7], 0xffffffff

.branch_3abd4:
    xor eax, eax
    mov al, [edx + frame_state_139f4]
    cmp eax, ebx
    jnz short .branch_3ac16
    mov ecx, [nosplit edx*4 + frame_state_139f7]
    shl eax, byte 0x4
    push ecx
    mov esi, [nosplit ebx*8 + frame_state_13558]
    sub eax, ebx
    push esi
    add eax, eax
    push strict dword frame_state_122c
    add eax, frame_state_174268
    push eax
    call format_string
    mov eax, [nosplit ebx*4 + frame_state_1741f4]
    add esp, 0x10
    mov [eax + 0x7], edx
    jmp short .branch_3ac1c

.branch_3ac16:
    inc edx
    cmp edx, 0x3
    jl short .branch_3abd4

.branch_3ac1c:
    mov eax, [nosplit ebx*4 + frame_state_1741f4]
    cmp dword [eax + 0x7], -1
    jnz short .branch_3ac52
    mov eax, ebx
    push strict dword frame_state_1232
    shl eax, byte 0x4
    mov ebp, [nosplit ebx*8 + frame_state_13558]
    sub eax, ebx
    push ebp
    add eax, eax
    push strict dword frame_state_1233
    add eax, frame_state_174268
    push eax
    call format_string
    add esp, 0x10

.branch_3ac52:
    inc ebx
    cmp ebx, 0x19
    jl near .branch_3abc4
    mov edi, 0x1

.branch_3ac61:
    test edi, edi
    jz near .branch_3ada6
    mov esi, 0x83d
    push strict dword frame_state_1741f4
    mov ecx, frame_state_123b
    mov edx, 0x19
    mov eax, frame_state_1745ac
    movsx ebx, si
    call run_menu_loop
    mov edi, eax
    test eax, eax
    jz short .branch_3ac61
    mov eax, [frame_state_1745ac]
    push strict dword frame_state_1232
    mov edx, [nosplit eax*8 + frame_state_13558]
    push edx
    mov edx, eax
    shl eax, byte 0x4
    sub eax, edx
    add eax, eax
    push strict dword frame_state_1233
    add eax, frame_state_174268
    push eax
    call format_string
    add esp, 0x10

.branch_3acbe:
    call presentation_input
    test eax, eax
    jnz short .branch_3ace5
    push strict dword frame_state_1741f4
    mov ecx, frame_state_1248
    mov edx, 0x19
    mov eax, [frame_state_1745ac]
    movsx ebx, si
    call draw_menu_frame
    jmp short .branch_3acbe

.branch_3ace5:
    mov dx, [mouse_buttons]
    test dx, dx
    jz near .branch_3ac61
    mov eax, edx
    xor ah, dh
    and al, 0x1
    cwde
    test eax, eax
    jz short .branch_3ad04
    xor ebx, ebx
    jmp short .branch_3ad1b

.branch_3ad04:
    mov eax, edx
    xor ah, dh
    and al, 0x2
    cwde
    test eax, eax
    jz short .branch_3ad16
    mov ebx, 0x2
    jmp short .branch_3ad1b

.branch_3ad16:
    mov ebx, 0x1

.branch_3ad1b:
    xor edx, edx

.branch_3ad1d:
    mov eax, [nosplit edx*4 + frame_state_1741f4]
    cmp ebx, [eax + 0x7]
    jnz short .branch_3ad5b
    mov dword [eax + 0x7], 0xffffffff
    mov eax, edx
    push strict dword frame_state_1232
    shl eax, byte 0x4
    mov esi, [nosplit edx*8 + frame_state_13558]
    sub eax, edx
    push esi
    add eax, eax
    push strict dword frame_state_1233
    add eax, frame_state_174268
    push eax
    call format_string
    add esp, 0x10
    jmp short .branch_3ad61

.branch_3ad5b:
    inc edx
    cmp edx, 0x19
    jl short .branch_3ad1d

.branch_3ad61:
    mov ebp, [nosplit ebx*4 + frame_state_139f7]
    mov eax, [frame_state_1745ac]
    push ebp
    mov edx, [nosplit eax*8 + frame_state_13558]
    push edx
    mov edx, eax
    shl eax, byte 0x4
    sub eax, edx
    add eax, eax
    push strict dword frame_state_122c
    add eax, frame_state_174268
    push eax
    call format_string
    mov eax, [frame_state_1745ac]
    mov eax, [nosplit eax*4 + frame_state_1741f4]
    add esp, 0x10
    mov [eax + 0x7], ebx
    jmp near .branch_3ac61

.branch_3ada6:
    xor ebx, ebx

.branch_3ada8:
    mov edx, [nosplit ebx*4 + frame_state_1741f4]
    mov edx, [edx + 0x7]
    cmp edx, -1
    jz short .branch_3adbd
    mov [edx + frame_state_139f4], bl

.branch_3adbd:
    inc ebx
    cmp ebx, 0x19
    jl short .branch_3ada8
    xor ebx, ebx

.branch_3adc5:
    mov eax, [nosplit ebx*4 + frame_state_1741f4]
    inc ebx
    mov dword [eax + 0x7], 0x0
    cmp ebx, 0x19
    jl short .branch_3adc5
    mov eax, edi
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
