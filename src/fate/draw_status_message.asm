; Draw status text as character tiles.
BITS 32
ORG 0x3462d

rotatesprite equ 0x57181

draw_status_message:
    push esi
    push edi
    push ebp
    sub esp, 0x18
    mov esi, eax
    mov edi, edx
    mov [esp + 0xc], ebx
    mov [esp + 0x10], ecx
    xor ebp, ebp
    jmp near .branch_346d9

.branch_34646:
    lea eax, [edi + 0x7]
    push eax
    mov [esp + 0x4], eax
    lea eax, [esi + 0x7]
    push eax
    push edi
    push esi
    mov ebx, 0x10000
    mov [esp + 0x24], dl
    push strict dword 0xd8
    xor ecx, ecx
    mov [esp + 0x18], eax
    push strict byte 0x0
    movsx eax, word [esp + 0x28]
    push strict byte 0x0
    mov edx, edi
    mov [esp + 0x24], eax
    push eax
    lea eax, [esi-0x40]
    shl edx, byte 0x10
    shl eax, byte 0x10
    call rotatesprite
    mov eax, [esp]
    push eax
    mov edx, [esp + 0x8]
    push edx
    xor eax, eax
    push edi
    mov al, [esp + 0x20]
    mov edx, edi
    push esi
    sar eax, byte 0x4
    push strict dword 0x98
    shl eax, byte 0x3
    push strict byte 0x0
    mov ebx, [esp + 0x20]
    sub edx, eax
    push strict byte 0x0
    mov al, [esp + 0x30]
    shl edx, byte 0x10
    push ebx
    and al, 0xf
    and eax, strict dword 0xff
    mov ebx, esi
    shl eax, byte 0x3
    inc ebp
    sub ebx, eax
    xor ecx, ecx
    mov eax, ebx
    mov ebx, 0x10000
    shl eax, byte 0x10
    add esi, 0x8
    call rotatesprite

.branch_346d9:
    mov eax, [esp + 0xc]
    add eax, ebp
    mov dl, [eax]
    test dl, dl
    jnz near .branch_34646
    add esp, 0x18
    pop ebp
    pop edi
    pop esi
    ret word 0x4
