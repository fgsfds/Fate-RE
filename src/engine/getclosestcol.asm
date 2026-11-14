; Find the nearest palette index using the color buckets and distance tables.
BITS 32
ORG 0x5976c

pow2char equ 0x14029
color_neighbor_order equ 0x140c3
restore_ebp_edi_esi_ecx equ 0x47f04
frame_state_191360 equ 0x191360
frame_state_196350 equ 0x196350
palette equ 0x27c0a0
frame_state_27c39d equ 0x27c39d
frame_state_2863d0 equ 0x2863d0
frame_state_28643c equ 0x28643c
frame_state_28655c equ 0x28655c
frame_state_286640 equ 0x286640
frame_state_286760 equ 0x286760
frame_state_286844 equ 0x286844
frame_state_286964 equ 0x286964
frame_state_289158 equ 0x289158

getclosestcol:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x10
    push eax
    mov edi, edx
    mov [esp + 0x10], ebx
    mov edx, eax
    mov eax, edi
    sar edx, byte 0x3
    sar eax, byte 0x3
    shl edx, byte 0x6
    shl eax, byte 0x3
    add edx, eax
    mov eax, ebx
    sar eax, byte 0x3
    add eax, edx
    add eax, 0x49
    mov [esp + 0x4], eax
    mov eax, [esp]
    and eax, 0x7
    xor edx, edx
    mov dl, [eax + color_neighbor_order]
    mov eax, edi
    and eax, 0x7
    shl edx, byte 0x2
    mov al, [eax + color_neighbor_order]
    and eax, strict dword 0xff
    shl eax, byte 0x2
    mov ebx, [edx + frame_state_28655c]
    mov ecx, [eax + frame_state_286964]
    cmp ebx, ecx
    jnl short .branch_597d2
    mov edx, ebx
    jmp short .branch_597d4

.branch_597d2:
    mov edx, ecx

.branch_597d4:
    mov eax, [esp + 0x10]
    and eax, 0x7
    mov al, [eax + color_neighbor_order]
    and eax, strict dword 0xff
    shl eax, byte 0x2
    mov esi, [eax + frame_state_286760]
    cmp edx, esi
    jl short .branch_597f5
    mov edx, esi

.branch_597f5:
    mov eax, 0x40
    mov ebp, [esp]
    mov ebx, 0xffffffff
    sub eax, ebp
    mov esi, 0x1a
    mov [esp], eax
    mov eax, 0x40
    lea ecx, [edx + 0x1]
    sub eax, edi
    mov edx, [esp + 0x10]
    mov edi, eax
    mov eax, 0x40
    mov [esp + 0xc], ebx
    sub eax, edx
    mov [esp + 0x8], esi
    mov [esp + 0x10], eax
    jmp near .branch_598d0

.branch_59834:
    mov edx, [esp + 0x4]
    mov ebx, [nosplit ebp*4 + frame_state_2863d0]
    add ebx, edx
    mov eax, ebx
    sar eax, byte 0x3
    xor edx, edx
    mov dl, [eax + frame_state_289158]
    mov eax, ebx
    and eax, 0x7
    mov al, [eax + pow2char]
    and eax, strict dword 0xff
    test edx, eax
    jz short .branch_598cc
    mov bl, [ebx + frame_state_191360]
    and ebx, strict dword 0xff

.branch_5986e:
    mov eax, ebx
    shl eax, byte 0x2
    mov edx, palette
    sub eax, ebx
    add edx, eax
    xor eax, eax
    mov al, [edx + 0x1]
    add eax, edi
    mov eax, [nosplit eax*4 + frame_state_286844]
    cmp eax, ecx
    jnl short .branch_598c1
    mov ebp, [esp]
    movzx esi, byte [edx]
    add esi, ebp
    add eax, [nosplit esi*4 + frame_state_28643c]
    cmp eax, ecx
    jnl short .branch_598c1
    mov dl, [edx + 0x2]
    mov esi, [esp + 0x10]
    and edx, strict dword 0xff
    add edx, esi
    add eax, [nosplit edx*4 + frame_state_286640]
    cmp eax, ecx
    jnl short .branch_598c1
    mov ecx, eax
    mov [esp + 0xc], ebx

.branch_598c1:
    mov ebx, [nosplit ebx*4 + frame_state_196350]
    test ebx, ebx
    jnl short .branch_5986e

.branch_598cc:
    dec dword [esp + 0x8]

.branch_598d0:
    mov ebp, [esp + 0x8]
    test ebp, ebp
    jnl near .branch_59834
    mov eax, [esp + 0xc]
    test eax, eax
    jnl near restore_ebp_edi_esi_ecx
    mov ecx, 0x7fffffff
    mov edx, frame_state_27c39d
    mov ebx, 0xff
    jmp short .branch_5993d

.branch_598f9:
    xor eax, eax
    mov al, [edx + 0x1]
    add eax, edi
    mov eax, [nosplit eax*4 + frame_state_286844]
    cmp eax, ecx
    jnl short .branch_59939
    mov ebp, [esp]
    movzx esi, byte [edx]
    add esi, ebp
    add eax, [nosplit esi*4 + frame_state_28643c]
    cmp eax, ecx
    jnl short .branch_59939
    mov ebp, [esp + 0x10]
    movzx esi, byte [edx + 0x2]
    add esi, ebp
    add eax, [nosplit esi*4 + frame_state_286640]
    cmp eax, ecx
    jnl short .branch_59939
    mov ecx, eax
    mov [esp + 0xc], ebx

.branch_59939:
    dec ebx
    sub edx, 0x3

.branch_5993d:
    test ebx, ebx
    jnl short .branch_598f9
    mov eax, [esp + 0xc]
    jmp near restore_ebp_edi_esi_ecx
