; Draw menu entries.
BITS 32
ORG 0x38aa2

frame_state_cef equ 0xcef
frame_state_cf3 equ 0xcf3
frame_state_12ddc equ 0x12ddc
frame_state_12de4 equ 0x12de4
frame_state_12df4 equ 0x12df4
frame_state_12e00 equ 0x12e00
frame_state_12e04 equ 0x12e04
frame_state_12e0c equ 0x12e0c
frame_state_1314e equ 0x1314e
small_text_return equ 0x386cd
draw_menu_text equ 0x386d3
rotatesprite equ 0x57181
strlen equ 0x60381
frame_state_173fe8 equ 0x173fe8
frame_state_174010 equ 0x174010
frame_state_174028 equ 0x174028
frame_state_1740d0 equ 0x1740d0
frame_state_1741e0 equ 0x1741e0
frame_state_17455c equ 0x17455c
frame_state_17456c equ 0x17456c
frame_state_174580 equ 0x174580
frame_state_1745b0 equ 0x1745b0
frame_state_1745bc equ 0x1745bc
frame_state_1745d0 equ 0x1745d0
frame_state_1745e8 equ 0x1745e8
frame_state_174608 equ 0x174608
frame_state_1f310c equ 0x1f310c
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

    db 0x8b, 0xc0 ; mov eax, eax using the original alignment encoding

menu_entry_dispatch:
    dd draw_menu_entries.entry_case_38d76 - 0x10000
    dd draw_menu_entries.entry_case_38fec - 0x10000
    dd draw_menu_entries.entry_case_38eac - 0x10000
    dd draw_menu_entries.entry_case_38e1d - 0x10000
    dd draw_menu_entries.entry_case_38e1d - 0x10000
    dd draw_menu_entries.entry_case_38e77 - 0x10000
    dd draw_menu_entries.entry_case_38fb2 - 0x10000

draw_menu_entries:
    push esi
    push edi
    push ebp
    sub esp, 0x18
    push eax
    push edx
    mov esi, ebx
    cmp bx, 0x820
    jc short .branch_38ae8
    jna short .branch_38ae1
    cmp bx, 0x874
    jc short .branch_38ae8
    cmp bx, 0x875
    ja short .branch_38ae8

.branch_38ae1:
    mov edi, 0x4b
    jmp short .branch_38aea

.branch_38ae8:
    xor edi, edi

.branch_38aea:
    test si, si
    jz short .branch_38b21
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
    mov ebx, 0x10000
    mov edx, edi
    push strict byte 0x0
    movsx eax, si
    xor ecx, ecx
    push eax
    shl edx, byte 0x10
    xor eax, eax
    call rotatesprite

.branch_38b21:
    movsx eax, si
    cmp eax, strict dword 0x820
    jnz near .branch_38bd5
    mov edx, [esp + 0x30]
    mov eax, 0x822
    cmp edx, frame_state_174010
    jnz short .branch_38b4a
    mov eax, 0x823
    jmp near .branch_38ba3

.branch_38b4a:
    cmp edx, frame_state_1745d0
    jnz short .branch_38b59
    mov eax, 0x82f
    jmp short .branch_38ba3

.branch_38b59:
    cmp edx, frame_state_17455c
    jnz short .branch_38b68
    mov eax, 0x82e
    jmp short .branch_38ba3

.branch_38b68:
    cmp edx, frame_state_17456c
    jnz short .branch_38b77
    mov eax, 0x830
    jmp short .branch_38ba3

.branch_38b77:
    cmp edx, frame_state_173fe8
    jnz short .branch_38b86
    mov eax, 0x832
    jmp short .branch_38ba3

.branch_38b86:
    cmp edx, frame_state_1740d0
    jz short .branch_38b9e
    cmp edx, frame_state_1745bc
    jz short .branch_38b9e
    cmp edx, frame_state_1745b0
    jnz short .branch_38ba3

.branch_38b9e:
    mov eax, 0x833

.branch_38ba3:
    mov edx, [presentation_height]
    dec edx
    push edx
    mov edx, [presentation_width]
    dec edx
    push edx
    push strict byte 0x0
    push strict byte 0x0
    push strict dword 0x92
    push strict byte 0x0
    mov ebx, 0x10000
    push strict byte 0x0
    cwde
    xor ecx, ecx
    push eax
    mov edx, 0x4b0000
    xor eax, eax
    call rotatesprite

.branch_38bd5:
    xor esi, esi
    mov [esp + 0x1c], esi
    jmp short .branch_38c19

.branch_38bdd:
    mov eax, edi
    mov edi, [esp + 0x30]
    shl eax, byte 0x2
    add eax, edi
    mov eax, [eax]
    cmp byte [eax], 0x0
    jz short .branch_38c15
    mov dx, [eax + 0x1]
    cmp dx, 0x2
    jnz short .branch_38c0a
    movsx eax, word [eax + 0x13]
    mov eax, [nosplit eax*4 + frame_state_12e00]
    add eax, eax
    add esi, eax
    jmp short .branch_38c15

.branch_38c0a:
    movsx eax, word [eax + 0x13]
    add esi, [nosplit eax*4 + frame_state_12e00]

.branch_38c15:
    inc dword [esp + 0x1c]

.branch_38c19:
    movsx eax, word [esp]
    mov edi, [esp + 0x1c]
    cmp eax, edi
    jg short .branch_38bdd
    mov eax, [esp + 0x30]
    mov eax, [eax]
    cmp word [eax + 0x13], 0x0
    jnz short .branch_38c36
    xor edi, edi
    jmp short .branch_38c99

.branch_38c36:
    mov ebp, [esp + 0x30]
    cmp ebp, frame_state_1745e8
    jnz short .branch_38c49

.branch_38c42:
    mov edi, 0x10
    jmp short .branch_38c99

.branch_38c49:
    cmp ebp, frame_state_174608
    jz short .branch_38c42
    mov edi, [frame_state_12e04]
    sar edi, byte 0x2
    cmp ebp, frame_state_174580
    jnz short .branch_38c7e
    mov edx, [frame_state_12e04]
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov edx, 0xc8

.branch_38c74:
    sub edx, eax
    mov eax, edx
    sub eax, edi
    mov edi, eax
    jmp short .branch_38c99

.branch_38c7e:
    cmp ebp, frame_state_1741e0
    jnz short .branch_38c94
    mov eax, [frame_state_12e04]
    mov edx, 0xc8
    add eax, eax
    jmp short .branch_38c74

.branch_38c94:
    mov edi, 0x64

.branch_38c99:
    xor ecx, ecx
    mov [frame_state_12ddc], edi
    mov [esp + 0x1c], ecx
    jmp near .branch_390a4

.branch_38caa:
    mov ebx, 0x8
    mov eax, [esp + 0x4]
    mov [esp + 0x14], ebx
    cmp eax, edx
    jnz short .branch_38cc3
    mov dword [esp + 0x14], 0xffffffff

.branch_38cc3:
    mov eax, [esp + 0x1c]
    mov ebp, [esp + 0x30]
    shl eax, byte 0x2
    add eax, ebp
    mov eax, [eax]
    cmp byte [eax], 0x0
    jz near .branch_390a0
    cmp word [eax + 0x13], 0x0
    jz short .branch_38ce6
    mov [eax + 0x11], di

.branch_38ce6:
    mov eax, [esp + 0x1c]
    mov edx, [esp + 0x30]
    shl eax, byte 0x2
    add eax, edx
    mov ebp, [eax]
    xor eax, eax
    mov al, [frame_state_1314e]
    mov ebp, [ebp + 0x3]
    cmp eax, 0x1
    jnz short .branch_38d4b
    mov eax, [esp + 0x4]
    cmp eax, [esp + 0x1c]
    jnz short .branch_38d4b
    cmp dword [frame_state_12de4], 0x2
    jl short .branch_38d4b
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x12
    push strict byte 0x0
    mov ebx, 0x4000
    push strict byte 0xffffffffffffffe0
    lea edx, [edi-0x2]
    xor ecx, ecx
    push strict dword 0x2a2
    shl edx, byte 0x10
    mov eax, 0xa40000
    call rotatesprite

.branch_38d4b:
    mov eax, [esp + 0x1c]
    mov edx, [esp + 0x30]
    shl eax, byte 0x2
    add edx, eax
    mov eax, [edx]
    mov [esp + 0x18], edx
    mov dx, [eax + 0x1]
    cmp dx, 0x6
    ja short .branch_38d76
    and edx, strict dword 0xffff
    jmp dword near [cs:edx*4 + menu_entry_dispatch - 0x10000]

.branch_38d76:
.entry_case_38d76:
    mov eax, [esp + 0x1c]
    mov edx, [esp + 0x30]
    shl eax, byte 0x2
    add edx, eax
    mov eax, [edx]
    mov cx, [eax + 0x13]
    mov [esp + 0x10], edx
    test cx, cx
    jnz short .branch_38dae
    movsx edx, cx
    mov ebx, [esp + 0x14]
    push edx
    mov ecx, ebp
    movsx edx, word [eax + 0x11]
    movsx eax, word [eax + 0xf]
    call draw_menu_text
    jmp near .branch_390a0

.branch_38dae:
    mov eax, ebp
    call strlen
    mov esi, eax
    mov eax, [edx]
    movsx ebx, word [eax + 0x13]
    imul esi, [nosplit ebx*4 + frame_state_12df4]
    mov edx, edi
    mov eax, 0xa0
    push ebx
    mov ebx, [esp + 0x18]
    sar esi, 1
    mov ecx, ebp
    sub eax, esi
    mov esi, [esp + 0x34]
    call draw_menu_text
    cmp esi, frame_state_174028
    jnz short .branch_38e07
    mov eax, [esp + 0x10]
    mov eax, [eax]
    movsx eax, word [eax + 0x13]
    mov edx, [nosplit eax*4 + frame_state_12e0c]
    mov eax, edx
    add edi, edx
    sar eax, byte 0x3
    sub edi, eax
    jmp near .branch_390a0

.branch_38e07:
    mov eax, [esp + 0x10]
    mov eax, [eax]
    movsx eax, word [eax + 0x13]
    add edi, [nosplit eax*4 + frame_state_12e0c]
    jmp near .branch_390a0
.entry_case_38e1d:
    mov eax, ebp
    call strlen
    mov esi, eax
    mov eax, [esp + 0x1c]
    mov edx, [esp + 0x30]
    shl eax, byte 0x2
    add edx, eax
    mov eax, [edx]
    mov [esp + 0x8], edx
    movsx edx, word [eax + 0x13]
    imul esi, [nosplit edx*4 + frame_state_12df4]
    mov edx, 0xa0
    sar esi, 1
    sub edx, esi
    mov [eax + 0xf], dx
    mov eax, [esp + 0x8]
    mov eax, [eax]
    mov ecx, ebp
    mov ebx, [esp + 0x14]
    movsx eax, word [eax + 0x13]
    mov esi, edx
    push eax
    mov edx, edi
    mov eax, esi
    call draw_menu_text
    mov eax, [esp + 0x8]
    jmp near .branch_39093
.entry_case_38e77:
    movsx edx, word [eax + 0x13]
    mov esi, [nosplit edx*4 + frame_state_12df4]
    add esi, 0x20
    mov [eax + 0xf], si
    mov eax, [esp + 0x18]

.branch_38e8d:
    mov eax, [eax]
    mov ebx, [esp + 0x14]
    movsx eax, word [eax + 0x13]
    mov ecx, ebp
    push eax
    mov edx, edi
    mov eax, esi
    call draw_menu_text
    mov eax, [esp + 0x18]
    jmp near .branch_39093
.entry_case_38eac:
    mov eax, ebp
    call strlen
    mov edx, eax
    mov eax, [esp + 0x18]
    mov eax, [eax]
    movsx esi, word [eax + 0x13]
    imul edx, [nosplit esi*4 + frame_state_12df4]
    mov esi, 0xa0
    sar edx, 1
    sub esi, edx
    mov [eax + 0xf], si
    mov eax, [esp + 0x18]
    mov eax, [eax]
    mov ecx, ebp
    movsx eax, word [eax + 0x13]
    mov ebx, [esp + 0x14]
    push eax
    mov edx, edi
    mov eax, esi
    call draw_menu_text
    mov eax, [esp + 0x18]
    mov eax, [eax]
    movsx eax, word [eax + 0x13]
    mov ecx, [nosplit eax*4 + frame_state_12e00]
    movsx eax, word [frame_state_1f310c]
    mov esi, 0xa0
    sar eax, 1
    sub esi, eax
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x12
    mov ebx, 0x10000
    add edi, ecx
    push strict byte 0x0
    mov edx, edi
    xor ecx, ecx
    push strict byte 0x0
    shl edx, byte 0x10
    mov eax, esi
    push strict dword 0x876
    shl eax, byte 0x10
    mov ebp, [esp + 0x38]
    call rotatesprite
    mov ebp, [ebp + 0x0]
    cmp dword [ebp + 0xb], 0x0
    jz short .branch_38f6b
    movsx edx, word [frame_state_1f310c]
    sub edx, 0x8
    mov ebx, [ebp + 0xb]
    mov eax, edx
    sar edx, byte 0x1f
    idiv ebx
    imul eax, [ebp + 0x7]
    add esi, eax

.branch_38f6b:
    mov eax, [presentation_height]
    dec eax
    push eax
    mov eax, [presentation_width]
    dec eax
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x12
    mov ebx, 0x10000
    push strict byte 0x0
    lea edx, [edi + 0x1]
    xor ecx, ecx
    push strict byte 0x0
    shl edx, byte 0x10
    lea eax, [esi + 0x3]
    push strict dword 0x877
    shl eax, byte 0x10
    call rotatesprite
    mov eax, [esp + 0x1c]
    mov esi, [esp + 0x30]
    shl eax, byte 0x2
    add eax, esi
    jmp near .branch_39093
.entry_case_38fb2:
    mov eax, ebp
    mov edx, [esp + 0x18]
    call strlen
    mov edx, [edx]
    mov esi, eax
    movsx eax, word [edx + 0x13]
    imul esi, [nosplit eax*4 + frame_state_12df4]
    mov ebx, 0x140
    sub ebx, esi
    mov ecx, [nosplit eax*4 + frame_state_12df4]
    mov esi, ebx
    sub esi, ecx
    mov eax, [esp + 0x18]
    mov [edx + 0xf], si
    jmp near .branch_38e8d
.entry_case_38fec:
    mov dword [esp + 0xc], 0x80
    movsx edx, word [eax + 0x13]
    mov esi, [nosplit edx*4 + frame_state_12df4]
    add esi, 0x20
    mov [eax + 0xf], si
    mov eax, [esp + 0x18]
    mov eax, [eax]
    mov ebx, [esp + 0x14]
    movsx eax, word [eax + 0x13]
    mov ecx, ebp
    push eax
    mov edx, edi
    mov eax, esi
    call draw_menu_text
    mov eax, [esp + 0x18]
    mov eax, [eax]
    cmp dword [eax + 0x7], 0x0
    jz short .branch_39033
    mov ebp, frame_state_cef
    jmp short .branch_39038

.branch_39033:
    mov ebp, frame_state_cf3

.branch_39038:
    mov eax, [esp + 0x1c]
    mov edx, [esp + 0x30]
    shl eax, byte 0x2
    add edx, eax
    mov eax, [edx]
    mov [esp + 0x8], edx
    movsx edx, word [eax + 0x13]
    mov eax, ebp
    call strlen
    mov edx, [nosplit edx*4 + frame_state_12df4]
    imul edx, eax
    mov esi, [esp + 0xc]
    mov eax, [esp + 0x8]
    add esi, strict dword 0xa0
    mov eax, [eax]
    mov ebx, [esp + 0x14]
    sub esi, edx
    movsx eax, word [eax + 0x13]
    mov edx, edi
    mov ecx, [nosplit eax*4 + frame_state_12df4]
    push eax
    sub esi, ecx
    mov ecx, ebp
    mov eax, esi
    call draw_menu_text
    mov eax, [esp + 0x8]

.branch_39093:
    mov eax, [eax]
    movsx eax, word [eax + 0x13]
    add edi, [nosplit eax*4 + frame_state_12e00]

.branch_390a0:
    inc dword [esp + 0x1c]

.branch_390a4:
    movsx eax, word [esp]
    mov edx, [esp + 0x1c]
    cmp eax, edx
    jg near .branch_38caa
    add esp, 0x20
    jmp near small_text_return
