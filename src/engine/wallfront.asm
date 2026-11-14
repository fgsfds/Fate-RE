; Compare two scanned walls for front-to-back ordering.
BITS 32
ORG 0x45313

wall equ 0x2310a0
scan_wall_index equ 0x1c2160
engine_286ad4 equ 0x286ad4
engine_286ad0 equ 0x286ad0
ceiling_sprite_restore_registers equ 0x50347

wallfront_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x28
    movsx eax, word [nosplit eax*2 + scan_wall_index]
    shl eax, 5
    add eax, wall
    mov ecx, dword [eax]
    mov dword [esp + 0x14], ecx
    mov ecx, dword [eax + 4]
    movsx eax, word [eax + 8]
    shl eax, 5
    add eax, wall
    mov dword [esp + 0x24], ecx
    mov ecx, dword [eax]
    mov eax, dword [eax + 4]
    mov dword [esp + 0x10], eax
    movsx eax, word [nosplit edx*2 + scan_wall_index]
    shl eax, 5
    add eax, wall
    mov edx, dword [eax]
    mov dword [esp + 0x18], edx
    mov edx, dword [eax + 4]
    movsx eax, word [eax + 8]
    shl eax, 5
    mov ebx, dword [esp + 0x24]
    add eax, wall
    mov dword [esp + 0xc], ecx
    mov dword [esp + 0x20], edx
    mov edx, dword [eax]
    mov edi, dword [esp + 0x20]
    mov dword [esp + 4], edx
    mov eax, dword [eax + 4]
    mov edx, dword [esp + 0x14]
    mov dword [esp + 8], eax
    mov eax, ecx
    sub edi, ebx
    sub eax, edx
    mov ecx, dword [esp + 0x10]
    mov dword [esp + 0x1c], eax
    mov dword [esp], eax
    mov ebp, eax
    sub ecx, ebx
    mov eax, dword [esp + 0x18]
    neg ebp
    mov ebx, ecx
    mov esi, ebp
    sub eax, edx
    mov dword [esp], ebp
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 2
    mov edi, dword [esp + 8]
    mov ebx, dword [esp + 0x24]
    mov esi, dword [esp + 0x14]
    mov ebp, eax
    mov eax, dword [esp + 4]
    sub edi, ebx
    mov ebx, ecx
    sub eax, esi
    mov esi, dword [esp]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 2
    mov edi, ebp
    mov edx, eax
    test edi, edi
    jne short .branch_0f5
    mov ebp, eax
    test eax, eax
    jne short .branch_0f5

.branch_0eb:
    mov eax, 0xffffffff
    jmp near .branch_20c

.branch_0f5:
    test eax, eax
    jne short .branch_0fb
    mov eax, ebp

.branch_0fb:
    xor eax, ebp
    test eax, eax
    jl short .branch_140
    mov ebx, dword [esp + 0x24]
    mov esi, dword [esp + 0x1c]
    mov edx, dword [esp + 0x14]
    mov edi, dword [engine_286ad4]
    mov eax, dword [engine_286ad0]
    neg esi
    sub edi, ebx
    sub eax, edx
    mov ebx, ecx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 2
    xor eax, ebp
    test eax, eax
    setge al

.branch_136:
    and eax, 0xff
    jmp near .branch_20c

.branch_140:
    mov eax, dword [esp + 4]
    mov ebp, dword [esp + 0x18]
    sub eax, ebp
    mov ecx, dword [esp + 8]
    mov dword [esp + 0x1c], eax
    mov eax, dword [esp + 0x20]
    mov edi, dword [esp + 0x24]
    sub ecx, eax
    sub edi, eax
    mov eax, dword [esp + 0x1c]
    mov ebx, eax
    mov dword [esp], eax
    neg ebx
    mov eax, dword [esp + 0x14]
    mov dword [esp], ebx
    mov esi, ebx
    sub eax, ebp
    mov ebx, ecx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 2
    mov edi, dword [esp + 0x10]
    mov edx, dword [esp + 0x18]
    mov ebp, eax
    mov eax, dword [esp + 0x20]
    mov esi, dword [esp]
    sub edi, eax
    mov eax, dword [esp + 0xc]
    mov ebx, ecx
    sub eax, edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 2
    mov ebx, ebp
    mov edx, eax
    test ebx, ebx
    jne short .branch_1c1
    mov ebp, eax
    test eax, eax
    je near .branch_0eb

.branch_1c1:
    test eax, eax
    jne short .branch_1c7
    mov eax, ebp

.branch_1c7:
    xor eax, ebp
    test eax, eax
    jl short .branch_207
    mov esi, dword [esp + 0x20]
    mov edx, dword [esp + 0x18]
    mov edi, dword [engine_286ad4]
    mov eax, dword [engine_286ad0]
    mov ebx, ecx
    sub edi, esi
    mov esi, dword [esp + 0x1c]
    sub eax, edx
    neg esi
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 2
    xor eax, ebp
    test eax, eax
    setl al
    jmp near .branch_136

.branch_207:
    mov eax, 0xfffffffe

.branch_20c:
    add esp, 0x28
    jmp near ceiling_sprite_restore_registers
