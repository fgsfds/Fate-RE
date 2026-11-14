; Draw menu selection marker.
BITS 32
ORG 0x39143

frame_state_12de0 equ 0x12de0
frame_state_12de8 equ 0x12de8
rotatesprite equ 0x57181
frame_state_1f5068 equ 0x1f5068
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

draw_menu_selection_marker:
    push ecx
    push esi
    push edi
    movsx esi, ax
    shl esi, byte 0x2
    add esi, ebx
    mov eax, [esi]
    cmp word [eax + 0x13], 0x0
    jz near .branch_39231
    movsx ebx, word [frame_state_1f5068]
    movsx edi, word [eax + 0x11]
    mov edx, ebx
    mov cx, [eax + 0x1]
    sar edx, 1
    sar ebx, byte 0x2
    add edi, edx
    mov edx, [presentation_height]
    sub edi, ebx
    mov ebx, [presentation_width]
    dec edx
    dec ebx
    cmp cx, 0x6
    jnz short .branch_391b8
    cmp dword [eax + 0x7], 0x0
    jz near .branch_39231
    push edx
    push ebx
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x44
    push strict byte 0x0
    mov ecx, 0x200
    push strict byte 0x0
    movsx edx, word [eax + 0x7]
    mov ebx, [eax + 0xb]
    push edx
    mov eax, 0x5a0000
    mov edx, 0x640000
    jmp short .branch_3922c

.branch_391b8:
    push edx
    push ebx
    push strict byte 0x0
    push strict byte 0x0
    shl edi, byte 0x10
    mov dx, [frame_state_12de0]
    push strict byte 0x2
    xor ecx, ecx
    add edx, strict dword 0x824
    push strict byte 0x0
    movsx ebx, word [eax + 0x13]
    push strict byte 0x0
    movsx edx, dx
    mov eax, 0x200000
    push edx
    mov ebx, [nosplit ebx*4 + frame_state_12de8]
    mov edx, edi
    call rotatesprite
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x2
    mov ax, [frame_state_12de0]
    push strict byte 0x0
    add eax, strict dword 0x824
    push strict byte 0x0
    cwde
    push eax
    mov eax, [esi]
    mov edx, edi
    xor ecx, ecx
    movsx ebx, word [eax + 0x13]
    mov eax, 0x1200000
    mov ebx, [nosplit ebx*4 + frame_state_12de8]

.branch_3922c:
    call rotatesprite

.branch_39231:
    pop edi
    pop esi
    pop ecx
    ret
