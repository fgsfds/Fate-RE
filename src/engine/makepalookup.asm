; Build a shade lookup table for a remapped and tinted palette.
BITS 32
ORG 0x593b4

frame_state_1401c equ 0x1401c
palette_loaded equ 0x140c2
allocache equ 0x40c73
engine_malloc equ 0x4478c
restore_ebp_edi_esi equ 0x4918a
getclosestcol equ 0x5976c
palookup equ 0x203ca0
palette equ 0x27c0a0
numpalookups equ 0x289156

makepalookup:
    push esi
    push edi
    push ebp
    sub esp, 0x18
    mov ebp, eax
    mov [esp + 0xc], edx
    mov [esp + 0x14], bl
    mov [esp + 0x10], cl
    cmp byte [palette_loaded], 0x0
    jz near .branch_5957a
    mov ecx, ebp
    shl ecx, byte 0x2
    cmp dword [ecx + palookup], 0x0
    jnz short .branch_59417
    movsx eax, word [numpalookups]
    shl eax, byte 0x8
    call engine_malloc
    mov [ecx + palookup], eax
    test eax, eax
    jnz short .branch_59417
    mov eax, palookup
    movsx edx, word [numpalookups]
    mov ebx, frame_state_1401c
    shl edx, byte 0x8
    add eax, ecx
    call allocache

.branch_59417:
    cmp byte [esp + 0x2c], 0x0
    jz near .branch_5957a
    movsx eax, byte [esp + 0x14]
    movsx edx, byte [esp + 0x10]
    or eax, edx
    movsx edx, byte [esp + 0x28]
    or eax, edx
    mov edx, eax
    or dl, 0x3f
    cmp edx, 0x3f
    jnz near .branch_5957a
    test eax, eax
    jnz short .branch_594a1
    mov [esp + 0x8], eax
    jmp short .branch_59490

.branch_5944d:
    mov eax, [esp + 0xc]
    mov edi, [palookup]
    add eax, ecx
    xor ecx, ecx
    mov esi, [nosplit ebp*4 + palookup]
    mov cl, [eax]
    mov eax, [esp + 0x8]
    add ecx, edi
    add esi, eax
    xor edi, edi
    jmp short .branch_59481

.branch_59470:
    inc edi
    mov al, [ecx]
    add ecx, strict dword 0x100
    mov [esi], al
    add esi, strict dword 0x100

.branch_59481:
    movsx eax, word [numpalookups]
    cmp edi, eax
    jl short .branch_59470
    inc dword [esp + 0x8]

.branch_59490:
    mov ecx, [esp + 0x8]
    cmp ecx, strict dword 0x100
    jl short .branch_5944d
    jmp near .branch_5957a

.branch_594a1:
    xor ebx, ebx
    mov esi, [nosplit ebp*4 + palookup]
    mov [esp + 0x8], ebx
    jmp near .branch_59567

.branch_594b3:
    mov ax, [numpalookups]
    movsx ebx, ax
    mov eax, edi
    mov edx, eax
    sar edx, byte 0x10
    shl eax, byte 0x10
    idiv ebx
    mov ebp, eax
    xor edi, edi
    jmp near .branch_59557

.branch_594d1:
    mov eax, [esp + 0xc]
    mov al, [edi + eax]
    and eax, strict dword 0xff
    mov ecx, eax
    shl ecx, byte 0x2
    sub ecx, eax
    add ecx, palette
    xor eax, eax
    mov al, [ecx + 0x2]
    mov [esp], eax
    movsx eax, byte [esp + 0x28]
    mov edx, [esp]
    mov ebx, ebp
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp]
    add edx, eax
    xor eax, eax
    mov al, [ecx + 0x1]
    mov [esp + 0x4], eax
    movsx eax, byte [esp + 0x10]
    sub eax, [esp + 0x4]
    mov ebx, ebp
    mov [esp], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0x4]
    add edx, eax
    mov cl, [ecx]
    mov [esp + 0x4], edx
    movsx eax, byte [esp + 0x14]
    and ecx, strict dword 0xff
    sub eax, ecx
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [esp]
    mov edx, [esp + 0x4]
    add eax, ecx
    inc edi
    call getclosestcol
    mov [esi], al
    inc esi

.branch_59557:
    cmp edi, strict dword 0x100
    jl near .branch_594d1
    inc dword [esp + 0x8]

.branch_59567:
    mov edi, [esp + 0x8]
    movsx eax, word [numpalookups]
    cmp eax, edi
    jg near .branch_594b3

.branch_5957a:
    add esp, 0x18
    jmp near restore_ebp_edi_esi
