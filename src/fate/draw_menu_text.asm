; Draw menu text.
BITS 32
ORG 0x386d3

character_types equ 0x1f20
frame_state_12de8 equ 0x12de8
frame_state_12df4 equ 0x12df4
menu_glyph_tile equ 0x38499
small_text_return equ 0x386cd
draw_screen_text equ 0x560de
rotatesprite equ 0x57181
strlen equ 0x60381
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

draw_menu_text:
    push esi
    push edi
    push ebp
    sub esp, 0x14
    mov ebp, [esp + 0x24]
    mov edi, eax
    mov [esp + 0x4], edx
    mov [esp + 0xc], ebx
    mov [esp + 0x8], ecx
    cmp ebp, 0x2
    jnz short .branch_38736
    cmp ebx, -1
    setz al
    push strict byte 0x0
    and eax, strict dword 0xff
    mov ebx, 0x60
    dec eax
    push ecx
    mov ecx, 0xffffffff
    mov [esp + 0x14], eax
    mov eax, edi
    call draw_screen_text
    push strict byte 0x0
    mov ecx, [esp + 0xc]
    mov edx, [esp + 0x8]
    mov ebx, 0x70
    lea eax, [edi-0x1]
    push ecx
    dec edx
    mov ecx, [esp + 0x14]
    call draw_screen_text
    jmp near .branch_387f8

.branch_38736:
    mov eax, ecx
    call strlen
    xor esi, esi
    mov [esp], eax
    jmp near .branch_387ef

.branch_38747:
    mov eax, [esp + 0x8]
    xor edx, edx
    add eax, esi
    test ebp, ebp
    jnz short .branch_38763
    mov al, [eax]
    and eax, strict dword 0xff
    call menu_glyph_tile
    mov edx, eax
    jmp short .branch_387a7

.branch_38763:
    mov bl, [eax]
    inc bl
    and ebx, strict dword 0xff
    mov cl, [ebx + character_types]
    and cl, 0xc0
    mov [esp + 0x10], cl
    xor ecx, ecx
    mov cl, [esp + 0x10]
    test ecx, ecx
    jz short .branch_3878e
    mov dl, [eax]
    add edx, strict dword 0x7c4
    jmp short .branch_387a7

.branch_3878e:
    mov bl, [ebx + character_types]
    and bl, 0x20
    and ebx, strict dword 0xff
    jz short .branch_387a7
    mov dl, [eax]
    add edx, strict dword 0x7c9

.branch_387a7:
    test edx, edx
    jz short .branch_387e5
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x12
    mov ebx, [nosplit ebp*4 + frame_state_12de8]
    push strict byte 0x0
    movsx eax, byte [esp + 0x24]
    xor ecx, ecx
    push eax
    movsx eax, dx
    mov edx, [esp + 0x20]
    push eax
    mov eax, edi
    shl edx, byte 0x10
    shl eax, byte 0x10
    call rotatesprite

.branch_387e5:
    mov edx, [nosplit ebp*4 + frame_state_12df4]
    inc esi
    add edi, edx

.branch_387ef:
    cmp esi, [esp]
    jl near .branch_38747

.branch_387f8:
    add esp, 0x14
    jmp near small_text_return
