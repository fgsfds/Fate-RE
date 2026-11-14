; Draw bitmap text using EGA graphics-controller write mode 2.
BITS 32
ORG 0x55e2c

pow2char equ 0x14029
restore_ebp_edi_esi equ 0x4918a
textfont equ 0x1c1960
smalltextfont equ 0x1d5160

draw_ega_text:
    push esi
    push edi
    push ebp
    sub esp, 0x24
    push edx
    push ebx
    mov esi, ecx
    mov edx, 0x3ce
    mov [esp + 0x20], eax
    mov eax, 0x5
    out dx, al
    mov edx, 0x3cf
    in al, dx
    and eax, strict dword 0xfc
    add eax, 0x2
    out dx, al
    mov eax, 0x8
    mov edx, 0x3ce
    out dx, al
    xor eax, eax
    mov al, [esp + 0x40]
    cmp eax, 0x1
    jnz short .branch_55e7e
    mov ecx, smalltextfont
    mov edi, 0x4
    mov [esp + 0x1c], ecx
    mov [esp + 0xc], edi
    jmp short .branch_55e90

.branch_55e7e:
    mov edx, textfont
    mov ebx, 0x8
    mov [esp + 0x1c], edx
    mov [esp + 0xc], ebx

.branch_55e90:
    xor ebp, ebp
    mov [esp + 0x18], ebp

.branch_55e96:
    mov eax, [esp + 0x3c]
    add eax, [esp + 0x18]
    mov dl, [eax]
    test dl, dl
    jz near .branch_560bf
    mov eax, [esp + 0x20]
    mov [esp + 0x28], dl
    mov edx, 0x8
    and eax, 0x7
    sub edx, eax
    mov ch, [edx + pow2char]
    mov edx, [esp + 0x4]
    mov ebx, [esp + 0x18]
    mov eax, edx
    inc ebx
    shl eax, byte 0x2
    mov [esp + 0x18], ebx
    add eax, edx
    mov edx, [esp + 0x20]
    shl eax, byte 0x4
    sar edx, byte 0x3
    dec ch
    add eax, edx
    mov dh, [esp + 0x20]
    lea ebx, [eax + 0xa0000]
    test dh, 0x7
    jnz near .branch_55f77
    xor ebp, ebp
    mov ecx, [esp + 0x1c]
    jmp short .branch_55f67

.branch_55efd:
    test si, si
    jl short .branch_55f23
    mov eax, 0xff
    mov edx, 0x3cf
    out dx, al
    cmp dword [esp + 0xc], 0x4
    jnz short .branch_55f1a
    mov eax, 0x7c
    out dx, al

.branch_55f1a:
    mov edi, ebx
    mov al, [edi]
    movsx eax, si
    mov [edi], al

.branch_55f23:
    movzx ebp, byte [esp + 0x28]
    mov edx, [esp + 0x14]
    shl ebp, byte 0x3
    add ebp, edx
    add ebp, ecx
    mov al, [ebp + 0x0]
    mov edx, 0x3cf
    and eax, strict dword 0xff
    mov edi, [esp + 0xc]
    out dx, al
    cmp edi, 0x4
    jnz short .branch_55f55
    mov al, [ebp + 0x0]
    and al, 0x7c
    and eax, strict dword 0xff
    out dx, al

.branch_55f55:
    mov edi, ebx
    mov al, [edi]
    movsx eax, word [esp]
    mov ebp, [esp + 0x14]
    mov [edi], al
    inc ebp
    add ebx, 0x50

.branch_55f67:
    mov [esp + 0x14], ebp
    cmp dword [esp + 0x14], 0x8
    jl short .branch_55efd
    jmp near .branch_560b2

.branch_55f77:
    xor edi, edi
    jmp near .branch_560a3

.branch_55f7e:
    test si, si
    jl short .branch_55feb
    mov edx, [esp + 0xc]
    lea ebp, [ebx + 0x1]
    cmp edx, 0x8
    jnz short .branch_55faa
    xor eax, eax
    mov edx, 0x3cf
    mov al, ch
    mov edi, ebx
    out dx, al
    mov al, [edi]
    movsx eax, si
    mov [edi], al
    xor eax, eax
    mov al, ch
    not eax
    jmp short .branch_55fe1

.branch_55faa:
    mov eax, [esp + 0x20]
    and eax, 0x7
    mov [esp + 0x8], eax
    mov cl, [esp + 0x8]
    mov eax, 0x7c
    mov edx, 0x3cf
    sar eax, cl
    mov edi, ebx
    out dx, al
    mov al, [edi]
    movsx eax, si
    mov [edi], al
    mov eax, 0x8
    sub eax, [esp + 0x8]
    mov cl, al
    mov eax, 0x7c
    shl eax, cl

.branch_55fe1:
    mov edi, ebp
    out dx, al
    mov al, [edi]
    movsx eax, si
    mov [edi], al

.branch_55feb:
    xor eax, eax
    mov al, [esp + 0x28]
    mov ebp, [esp + 0x14]
    shl eax, byte 0x3
    mov edx, [esp + 0x1c]
    add eax, ebp
    add eax, edx
    mov dl, [eax]
    mov eax, [esp + 0x20]
    mov edi, 0x8
    and eax, 0x7
    sub edi, eax
    mov [esp + 0x24], edi
    mov edi, [esp + 0xc]
    lea ebp, [ebx + 0x1]
    cmp edi, 0x8
    jnz short .branch_56063
    and edx, strict dword 0xff
    mov cl, al
    mov [esp + 0x8], edx
    mov eax, edx
    xor edx, edx
    mov edi, ebx
    mov dl, ch
    sar eax, cl
    mov [esp + 0x10], edx
    and eax, edx
    mov edx, 0x3cf
    mov cl, [esp + 0x24]
    out dx, al
    mov al, [edi]
    movsx eax, word [esp]
    mov edx, [esp + 0x8]
    mov [edi], al
    mov eax, [esp + 0x10]
    shl edx, cl
    not eax
    and eax, edx
    mov edx, 0x3cf
    jmp short .branch_56090

.branch_56063:
    mov ah, dl
    and ah, 0x7c
    xor edx, edx
    mov dl, ah
    mov cl, al
    mov [esp + 0x10], edx
    mov eax, edx
    mov edx, 0x3cf
    sar eax, cl
    mov edi, ebx
    out dx, al
    mov al, [edi]
    movsx eax, word [esp]
    mov cl, [esp + 0x24]
    mov [edi], al
    mov eax, [esp + 0x10]
    shl eax, cl

.branch_56090:
    mov edi, ebp
    out dx, al
    mov al, [edi]
    movsx eax, word [esp]
    mov [edi], al
    mov edi, [esp + 0x14]
    inc edi
    add ebx, 0x50

.branch_560a3:
    mov [esp + 0x14], edi
    cmp dword [esp + 0x14], 0x8
    jl near .branch_55f7e

.branch_560b2:
    mov eax, [esp + 0xc]
    add [esp + 0x20], eax
    jmp near .branch_55e96

.branch_560bf:
    mov eax, 0x5
    mov edx, 0x3ce
    out dx, al
    mov edx, 0x3cf
    in al, dx
    and eax, strict dword 0xfc
    out dx, al
    add esp, 0x2c
    jmp near restore_ebp_edi_esi
