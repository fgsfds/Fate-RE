; Build palette fade tables.
BITS 32
ORG 0x36305

; NASM defaults to opcode 19 for this register pair. Preserve the original 1B form.
%macro sbb_eax_edx 0
    db 0x1b, 0xc2 ; sbb eax, edx
%endmacro

frame_state_171614 equ 0x171614
frame_state_172214 equ 0x172214
saved_palette equ 0x172e14
frame_state_173114 equ 0x173114

build_palette_fade_tables:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x14
    xor ecx, ecx

.branch_36310:
    lea edi, [ecx + 0x1]
    xor ebx, ebx

.branch_36315:
    mov esi, ebx
    shl esi, byte 0x2
    sub esi, ebx
    lea eax, [esi + 0x1]
    mov [esp + 0x4], eax
    xor eax, eax
    mov al, [esi + saved_palette]
    mov [esp + 0x8], eax
    mov eax, 0x40
    sub eax, [esp + 0x8]
    imul eax, edi
    mov edx, eax
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, [esp + 0x8]
    mov [esp + 0x10], al
    mov eax, ecx
    shl eax, byte 0x2
    sub eax, ecx
    lea ebp, [esi + 0x2]
    shl eax, byte 0x8
    add esi, eax
    mov [esp + 0x8], eax
    mov al, [esp + 0x10]
    mov [esi + frame_state_171614], al
    mov esi, [esp + 0x4]
    movzx esi, byte [esi + saved_palette]
    mov edx, esi
    neg edx
    imul edx, edi
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, esi
    mov esi, [esp + 0x4]
    mov dl, al
    mov eax, [esp + 0x8]
    add eax, esi
    movzx esi, byte [ebp + saved_palette]
    mov [eax + frame_state_171614], dl
    mov edx, esi
    neg edx
    imul edx, edi
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    mov edx, [esp + 0x8]
    add ebp, edx
    add eax, esi
    inc ebx
    mov [ebp + frame_state_171614], al
    cmp ebx, strict dword 0x100
    jl near .branch_36315
    mov ecx, edi
    cmp edi, 0x4
    jl near .branch_36310
    xor ecx, edi

.branch_363e3:
    lea edi, [ecx + 0x1]
    xor ebx, ebx

.branch_363e8:
    mov esi, ebx
    shl esi, byte 0x2
    sub esi, ebx
    lea eax, [esi + 0x1]
    mov [esp + 0x4], eax
    mov edx, [esp + 0x4]
    xor eax, eax
    mov al, [edx + saved_palette]
    mov edx, 0x40
    sub edx, eax
    imul edx, edi
    mov [esp + 0x8], eax
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, [esp + 0x8]
    mov [esp + 0x10], al
    mov eax, ecx
    shl eax, byte 0x2
    sub eax, ecx
    shl eax, byte 0x8
    mov edx, [esp + 0x4]
    mov [esp + 0xc], eax
    add eax, edx
    mov dl, [esp + 0x10]
    mov [eax + frame_state_172214], dl
    xor eax, eax
    mov al, [esi + saved_palette]
    mov edx, eax
    neg edx
    imul edx, edi
    mov [esp + 0x8], eax
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    mov edx, [esp + 0x8]
    lea ebp, [esi + 0x2]
    add eax, edx
    add esi, [esp + 0xc]
    mov [esi + frame_state_172214], al
    movzx esi, byte [ebp + saved_palette]
    mov edx, esi
    neg edx
    imul edx, edi
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, esi
    add ebp, [esp + 0xc]
    inc ebx
    mov [ebp + frame_state_172214], al
    cmp ebx, strict dword 0x100
    jl near .branch_363e8
    mov ecx, edi
    cmp edi, 0x4
    jl near .branch_363e3
    xor ecx, edi

.branch_364b7:
    lea edi, [ecx + 0x1]
    xor ebx, ebx

.branch_364bc:
    mov esi, ebx
    shl esi, byte 0x2
    sub esi, ebx
    lea ebp, [esi + 0x1]
    lea eax, [esi + 0x2]
    mov [esp], eax
    mov edx, [esp]
    xor eax, eax
    mov al, [edx + saved_palette]
    mov edx, 0x40
    sub edx, eax
    imul edx, edi
    mov [esp + 0x8], eax
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, [esp + 0x8]
    mov [esp + 0x10], al
    mov eax, ecx
    shl eax, byte 0x2
    sub eax, ecx
    shl eax, byte 0x8
    mov edx, [esp]
    mov [esp + 0x8], eax
    add eax, edx
    mov dl, [esp + 0x10]
    mov [eax + frame_state_173114], dl
    xor eax, eax
    mov al, [ebp + saved_palette]
    mov edx, eax
    neg edx
    imul edx, edi
    mov [esp + 0xc], eax
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, [esp + 0xc]
    add ebp, [esp + 0x8]
    mov [ebp + frame_state_173114], al
    movzx ebp, byte [esi + saved_palette]
    mov edx, ebp
    neg edx
    imul edx, edi
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x3
    sbb_eax_edx
    sar eax, byte 0x3
    add eax, ebp
    add esi, [esp + 0x8]
    inc ebx
    mov [esi + frame_state_173114], al
    cmp ebx, strict dword 0x100
    jl near .branch_364bc
    mov ecx, edi
    cmp edi, 0x4
    jl near .branch_364b7
    add esp, 0x14
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
