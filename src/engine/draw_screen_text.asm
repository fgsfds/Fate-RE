; Draw bitmap text to planar or linear screen memory.
BITS 32
ORG 0x560de

chainstat equ 0x14003
pow2char equ 0x14029
pow2long equ 0x14031
restore_ebp_edi_esi equ 0x4918a
textfont equ 0x1c1960
smalltextfont equ 0x1d5160
chainplace equ 0x286b4c
draw_page_address equ 0x286b74
ylookup_second_row equ 0x286bb4
frame_state_286bcc equ 0x286bcc

draw_screen_text:
    push esi
    push edi
    push ebp
    sub esp, 0x18
    push edx
    push ebx
    push ecx
    mov [esp + 0x20], eax
    cmp byte [esp + 0x38], 0x0
    jz short .branch_56106
    mov ecx, smalltextfont
    mov esi, 0x4
    mov [esp + 0x14], ecx
    mov [esp + 0x1c], esi
    jmp short .branch_56118

.branch_56106:
    mov edx, textfont
    mov ebx, 0x8
    mov [esp + 0x14], edx
    mov [esp + 0x1c], ebx

.branch_56118:
    cmp byte [chainstat], 0x0
    jz near .branch_56221
    mov eax, 0x2
    mov edx, 0x3c4
    xor ebp, ebp
    out dx, al
    mov [esp + 0x18], ebp
    jmp near .branch_5620a

.branch_5613b:
    mov al, bl
    mov ebp, [esp + 0x14]
    mov edi, [esp + 0x8]
    mov esi, 0x7
    and eax, strict dword 0xff
    mov ebx, [chainplace]
    shl eax, byte 0x3
    mov edi, [nosplit edi*4 + frame_state_286bcc]
    add ebp, eax
    add edi, ebx
    jmp near .branch_561eb

.branch_56168:
    mov ebx, [esp + 0x1c]
    jmp short .branch_561de

.branch_5616e:
    xor eax, eax
    mov ecx, 0x7
    mov al, [esp + 0x38]
    sub ecx, eax
    sub ecx, ebx
    xor edx, edx
    mov dl, [ecx + pow2char]
    mov [esp + 0x10], edx
    xor edx, edx
    mov dl, [esi + ebp]
    mov [esp + 0xc], edx
    mov edx, [esp + 0x20]
    add edx, ebx
    sub edx, eax
    mov eax, edx
    sar eax, byte 0x2
    and edx, 0x3
    lea ecx, [edi + eax]
    mov eax, edx
    mov edx, [esp + 0xc]
    shl eax, byte 0x2
    test [esp + 0x10], edx
    jz short .branch_561c6
    mov edx, 0x3c5
    mov eax, [eax + pow2long]
    out dx, al
    mov al, [esp + 0x4]
    jmp short .branch_561dc

.branch_561c6:
    cmp word [esp], 0x0
    jl short .branch_561de
    mov edx, 0x3c5
    mov eax, [eax + pow2long]
    out dx, al
    mov al, [esp]

.branch_561dc:
    mov [ecx], al

.branch_561de:
    dec ebx
    test ebx, ebx
    jnl short .branch_5616e
    mov eax, [ylookup_second_row]
    dec esi
    sub edi, eax

.branch_561eb:
    test esi, esi
    jnl near .branch_56168
    mov eax, [esp + 0x1c]
    mov ecx, [esp + 0x20]
    mov esi, [esp + 0x18]
    add ecx, eax
    inc esi
    mov [esp + 0x20], ecx
    mov [esp + 0x18], esi

.branch_5620a:
    mov eax, [esp + 0x34]
    add eax, [esp + 0x18]
    mov bl, [eax]
    test bl, bl
    jnz near .branch_5613b
    jmp near .branch_562dd

.branch_56221:
    xor edi, edi
    mov [esp + 0x18], edi
    jmp near .branch_562cb

.branch_5622c:
    mov al, dh
    mov ebp, [esp + 0x14]
    mov ebx, [esp + 0x20]
    and eax, strict dword 0xff
    xor edx, edx
    shl eax, byte 0x3
    mov dl, [esp + 0x38]
    add ebp, eax
    sub ebx, edx
    mov eax, [esp + 0x8]
    mov edx, ebx
    mov ebx, [nosplit eax*4 + frame_state_286bcc]
    mov edi, [draw_page_address]
    add edx, ebx
    mov esi, 0x7
    add edi, edx
    jmp short .branch_562b0

.branch_56266:
    mov ebx, [esp + 0x1c]
    jmp short .branch_562a3

.branch_5626c:
    xor eax, eax
    mov edx, 0x7
    mov al, [esp + 0x38]
    sub edx, eax
    mov eax, edx
    sub eax, ebx
    xor ecx, ecx
    xor edx, edx
    mov cl, [eax + pow2char]
    mov dl, [esi + ebp]
    lea eax, [edi + ebx]
    test edx, ecx
    jz short .branch_56297
    mov dl, [esp + 0x4]
    jmp short .branch_562a1

.branch_56297:
    cmp word [esp], 0x0
    jl short .branch_562a3
    mov dl, [esp]

.branch_562a1:
    mov [eax], dl

.branch_562a3:
    dec ebx
    test ebx, ebx
    jnl short .branch_5626c
    mov eax, [ylookup_second_row]
    dec esi
    sub edi, eax

.branch_562b0:
    test esi, esi
    jnl short .branch_56266
    mov eax, [esp + 0x1c]
    mov ecx, [esp + 0x20]
    mov esi, [esp + 0x18]
    add ecx, eax
    inc esi
    mov [esp + 0x20], ecx
    mov [esp + 0x18], esi

.branch_562cb:
    mov eax, [esp + 0x34]
    add eax, [esp + 0x18]
    mov dh, [eax]
    test dh, dh
    jnz near .branch_5622c

.branch_562dd:
    add esp, 0x24
    jmp near restore_ebp_edi_esi
