; Update the viewing range and aspect lookup tables.
BITS 32
ORG 0x5708a

xdimen equ 0x140b5
restore_edi_esi_edx_ecx_ebx equ 0x4abbf
frame_state_286ac4 equ 0x286ac4
horizycent equ 0x286ae0
horizlookup equ 0x286aec
viewingrange_scaled equ 0x286b00
viewingrange_reciprocal_scaled equ 0x286b14
viewingrange_reciprocal equ 0x286bac
viewingrange equ 0x287e7c
ydim equ 0x287e8c

setaspect:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edx, 0x1
    mov ecx, 0x140
    mov esi, [viewingrange_reciprocal]
    mov ebx, eax
    mov [viewingrange], eax
    xor eax, eax
    idiv ebx
    mov ebx, [viewingrange]
    mov [viewingrange_reciprocal], eax
    mov eax, [xdimen]
    imul ebx
    idiv ecx
    mov ecx, [xdimen]
    mov ebx, [viewingrange_reciprocal]
    mov [viewingrange_scaled], eax
    mov eax, 0x140
    imul ebx
    idiv ecx
    mov edx, [viewingrange_reciprocal]
    mov [viewingrange_reciprocal_scaled], eax
    cmp esi, edx
    jz near restore_edi_esi_edx_ecx_ebx
    mov edi, edx
    shl edi, byte 0x2
    add edi, edx
    shl edi, byte 0x6
    mov eax, 0x20000
    mov ebx, edi
    mov edx, eax
    sar edx, byte 0x4
    shl eax, byte 0x1c
    idiv ebx
    mov ecx, [horizlookup]
    mov ebx, eax
    mov eax, [horizycent]
    mov [ecx + eax*4-0x4], ebx
    mov ebx, [ydim]
    mov eax, ebx
    shl eax, byte 0x2
    sub eax, ebx
    lea ecx, [eax-0x1]
    jmp short .branch_57178

.branch_57129:
    mov ebx, [horizycent]
    dec ebx
    cmp ecx, ebx
    jz short .branch_57177
    mov eax, ecx
    sub eax, ebx
    mov ebx, eax
    mov eax, 0x1
    mov esi, ecx
    mov edx, eax
    sar edx, byte 0x4
    shl eax, byte 0x1c
    idiv ebx
    mov ebx, [frame_state_286ac4]
    mov [ebx + esi*4], eax
    mov eax, [frame_state_286ac4]
    mov eax, [eax + esi*4]
    mov ebx, edi
    test eax, eax
    jns short .branch_57164
    neg eax

.branch_57164:
    mov edx, eax
    sar edx, byte 0x10
    shl eax, byte 0x10
    idiv ebx
    mov ebx, [horizlookup]
    mov [ebx + esi*4], eax

.branch_57177:
    dec ecx

.branch_57178:
    test ecx, ecx
    jnl short .branch_57129
    jmp near restore_edi_esi_edx_ecx_ebx
