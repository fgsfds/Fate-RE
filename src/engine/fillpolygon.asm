; Fill the projected polygon using opaque, masked or translucent spans.
BITS 32
ORG 0x5bfb7

chainplace equ 0x286b4c
chainstat equ 0x14003
frameplace equ 0x286b74
row_offset equ 0x286bb0
pow2char equ 0x14029
rx1 equ 0x1cd160
ry1 equ 0x1d1160
globalshade equ 0x286a88
transarea equ 0x14008
asm1 equ 0x286aa4
asm2 equ 0x286aa8
globalbufplc equ 0x286a90
globalx1 equ 0x286a80
globaly2 equ 0x286a58
presentation_width equ 0x287e90
presentation_height equ 0x287e8c
engine_1a8960 equ 0x1a8960
engine_1e4d20 equ 0x1e4d20
engine_1e2a60 equ 0x1e2a60
engine_1c5160 equ 0x1c5160
engine_286bac equ 0x286bac
engine_286ad0 equ 0x286ad0
engine_286ad4 equ 0x286ad4
engine_2891d7 equ 0x2891d7
setuphlineasm4 equ 0x74110
hlineasm4 equ 0x74150
mhline equ 0x74a80
mhlineskipmodify equ 0x74ad0
thline equ 0x74bf0
thlineskipmodify equ 0x74c40
faketimerhandler equ 0x31ec4
transmaskvline_restore equ 0x4abbe

fillpolygon_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x58
    mov ebx, eax
    mov edx, 0x7fffffff
    mov ecx, 0x80000000
    dec eax
    mov dword [esp], edx
    mov dword [esp + 8], ecx
    mov dword [esp + 0x1c], eax
    jmp short .branch_054

.branch_023:
    mov eax, dword [esi*4 + ry1]
    mov dword [esp + 0x24], eax
    mov eax, dword [esp]
    mov edi, dword [esp + 0x24]
    cmp eax, edi
    jl short .branch_03b
    mov eax, edi

.branch_03b:
    mov ebp, dword [esp + 0x24]
    mov dword [esp], eax
    mov eax, dword [esp + 8]
    cmp eax, ebp
    jg short .branch_04c
    mov eax, ebp

.branch_04c:
    mov dword [esp + 8], eax
    dec dword [esp + 0x1c]

.branch_054:
    mov esi, dword [esp + 0x1c]
    test esi, esi
    jge short .branch_023
    mov edi, dword [esp]
    mov ebp, dword [esp + 8]
    sar edi, 0x10
    sar ebp, 0x10
    mov dword [esp], edi
    mov dword [esp + 8], ebp
    test edi, edi
    jge short .branch_079
    xor edx, edx
    mov dword [esp], edx

.branch_079:
    mov eax, dword [esp + 8]
    mov ecx, dword [presentation_height]
    cmp eax, ecx
    jl short .branch_08e
    lea eax, [ecx - 1]
    mov dword [esp + 8], eax

.branch_08e:
    mov esi, engine_1a8960
    mov eax, dword [esp]
    mov edx, dword [esp + 8]
    mov dword [esp + 0x30], esi
    mov dword [esp + 0x24], eax
    jmp short .branch_0cb

.branch_0a4:
    mov ecx, dword [esp + 0x30]
    mov dword [eax*4 + engine_1e4d20], ecx
    add ecx, 0x2a
    mov dword [eax*4 + engine_1e2a60], ecx
    mov ecx, dword [esp + 0x30]
    lea esi, [eax + 1]
    add ecx, 0x54
    mov dword [esp + 0x24], esi
    mov dword [esp + 0x30], ecx

.branch_0cb:
    mov eax, dword [esp + 0x24]
    cmp eax, edx
    jle short .branch_0a4
    dec ebx
    mov dword [esp + 0x1c], ebx
    jmp near .branch_207

.branch_0dd:
    mov ebx, edi
    shl ebx, 2
    mov eax, dword [ebx + engine_1c5160]
    shl eax, 2
    mov ecx, dword [ebx + ry1]
    mov ebp, dword [eax + ry1]
    mov esi, ecx
    mov edi, ebp
    sar esi, 0x10
    sar edi, 0x10
    mov dword [esp + 4], ecx
    cmp esi, edi
    je near .branch_203
    mov ebx, dword [ebx + rx1]
    mov eax, dword [eax + rx1]
    mov dword [esp + 0x4c], ebx
    mov dword [esp + 0x48], eax
    mov ebx, ebp
    mov edx, dword [esp + 0x4c]
    sub ebx, ecx
    sub eax, edx
    mov edx, eax
    sar edx, 0x10
    shl eax, 0x10
    idiv ebx
    mov ecx, eax
    cmp edi, esi
    jle short .branch_1a2
    mov ebx, esi
    shl ebx, 0x10
    mov ebp, dword [esp + 4]
    add ebx, 0xffff
    sub ebx, ebp
    mov ebp, ebx
    mov ebx, eax
    mov eax, ebp
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp + 0x4c]
    add edx, eax
    mov dword [esp + 0x24], esi
    mov dword [esp + 0x4c], edx
    jmp short .branch_19a

.branch_168:
    mov eax, dword [esp + 0x4c]
    sar eax, 0x10
    mov esi, eax
    mov eax, dword [esp + 0x24]
    mov ebx, dword [eax*4 + engine_1e2a60]
    lea ebp, [ebx + 2]
    mov edx, dword [esp + 0x4c]
    mov dword [eax*4 + engine_1e2a60], ebp
    add edx, ecx
    mov word [ebx], si
    lea ebx, [eax + 1]
    mov dword [esp + 0x4c], edx
    mov dword [esp + 0x24], ebx

.branch_19a:
    cmp edi, dword [esp + 0x24]
    jg short .branch_168
    jmp short .branch_203

.branch_1a2:
    mov ebx, edi
    shl ebx, 0x10
    add ebx, 0xffff
    sub ebx, ebp
    mov ebp, ebx
    mov ebx, eax
    mov eax, ebp
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [esp + 0x48]
    add ebx, eax
    mov dword [esp + 0x24], edi
    mov dword [esp + 0x48], ebx
    jmp short .branch_1fb

.branch_1cb:
    mov eax, dword [esp + 0x48]
    sar eax, 0x10
    mov edi, eax
    mov eax, ebx
    mov ebx, dword [ebx*4 + engine_1e4d20]
    lea ebp, [ebx + 2]
    mov dword [eax*4 + engine_1e4d20], ebp
    mov ebp, eax
    mov word [ebx], di
    mov edi, dword [esp + 0x48]
    inc ebp
    add edi, ecx
    mov dword [esp + 0x24], ebp
    mov dword [esp + 0x48], edi

.branch_1fb:
    mov ebx, dword [esp + 0x24]
    cmp esi, ebx
    jg short .branch_1cb

.branch_203:
    dec dword [esp + 0x1c]

.branch_207:
    mov edi, dword [esp + 0x1c]
    test edi, edi
    jge near .branch_0dd
    mov ebx, dword [engine_286bac]
    mov eax, dword [globalx1]
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [engine_286bac]
    mov dword [globalx1], eax
    mov eax, dword [globaly2]
    mov ecx, dword [esp]
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [presentation_height]
    inc ecx
    sar ebx, 1
    sub ecx, ebx
    mov dword [globaly2], eax
    imul eax, ecx
    mov ebp, dword [globalx1]
    mov ebx, ecx
    imul ebx, ebp
    mov edx, dword [engine_286ad0]
    mov dword [esp + 0x28], ecx
    mov ecx, dword [engine_286ad4]
    add edx, ebx
    add ecx, eax
    mov ah, byte [chainstat]
    mov dword [engine_286ad0], edx
    mov dword [engine_286ad4], ecx
    test ah, ah
    je short .branch_298
    mov ebx, dword [asm2]
    mov eax, dword [asm1]
    shl ebx, 2
    shl eax, 2
    jmp short .branch_2a3

.branch_298:
    mov ebx, dword [asm2]
    mov eax, dword [asm1]

.branch_2a3:
    call setuphlineasm4
    mov esi, engine_1a8960
    mov eax, dword [esp]
    mov dword [esp + 0x30], esi
    mov dword [esp + 0x24], eax
    jmp near .branch_7cf

.branch_2bd:
    mov edi, dword [esp + 0x30]
    mov eax, dword [eax*4 + engine_1e4d20]
    sub eax, edi
    sar eax, 1
    lea ebx, [edi + 0x2a]
    dec eax
    mov dword [esp + 0x34], ebx
    mov dword [esp + 0x1c], eax
    jmp near .branch_789

.branch_2dd:
    mov eax, ebp
    xor esi, esi
    xor edi, edi
    jmp short .branch_316

.branch_2e5:
    mov edx, dword [esp + 0x30]
    lea ebp, [eax + eax]
    add ebp, edx
    mov cx, word [ebp]
    cmp cx, word [ebx]
    jge short .branch_2f9
    mov esi, eax

.branch_2f9:
    mov ebx, dword [esp + 0x34]
    lea ecx, [eax + eax]
    mov ebp, dword [esp + 0x34]
    add ecx, ebx
    lea ebx, [edi + edi]
    add ebx, ebp
    mov cx, word [ecx]
    cmp cx, word [ebx]
    jge short .branch_315
    mov edi, eax

.branch_315:
    dec eax

.branch_316:
    mov ebp, dword [esp + 0x30]
    lea ebx, [esi + esi]
    add ebx, ebp
    test eax, eax
    jg short .branch_2e5
    movsx eax, word [ebx]
    mov ecx, dword [esp + 0x1c]
    mov dword [esp + 0x4c], eax
    mov eax, ebp
    mov ax, word [eax + ecx*2]
    mov edx, dword [esp + 0x34]
    mov word [ebx], ax
    lea eax, [edi + edi]
    add eax, edx
    movsx ebx, word [eax]
    dec ebx
    mov dword [esp + 0x48], ebx
    mov ebx, edx
    mov bx, word [ebx + ecx*2]
    mov word [eax], bx
    mov eax, dword [esp + 0x4c]
    cmp eax, dword [esp + 0x48]
    jg near .branch_785
    mov ebx, dword [presentation_width]
    inc eax
    sar ebx, 1
    sub eax, ebx
    mov ecx, dword [asm1]
    mov dword [esp + 0x2c], eax
    imul eax, ecx
    mov esi, dword [asm2]
    mov ebp, dword [esp + 0x2c]
    imul ebp, esi
    mov edx, dword [esp + 0x4c]
    mov ebx, dword [engine_286ad0]
    mov edi, dword [engine_286ad4]
    add ebx, eax
    mov eax, dword [esp + 0x48]
    mov dword [esp + 0x50], ebx
    sub ebp, edi
    sub eax, edx
    xor ebx, ebx
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x24]
    mov bl, byte [engine_2891d7]
    shl eax, 2
    cmp ebx, 1
    jge near .branch_4d7
    cmp byte [chainstat], 0
    je near .branch_49b
    mov eax, ecx
    shl eax, 2
    mov dword [asm1], eax
    mov eax, esi
    mov ebx, dword [esp + 0x4c]
    shl eax, 2
    mov dword [esp + 0x2c], ecx
    mov dword [asm2], eax
    mov eax, dword [esp + 0x48]
    add ebx, 4
    inc eax
    mov dword [esp + 0x28], esi
    cmp eax, ebx
    jl short .branch_3f9
    mov eax, ebx

.branch_3f9:
    mov dword [esp + 0x20], eax
    mov eax, dword [esp + 0x24]
    mov ecx, dword [chainplace]
    mov eax, dword [eax*4 + row_offset]
    add eax, ecx
    mov dword [esp + 0x44], eax

.branch_414:
    mov eax, dword [esp + 0x4c]
    cmp eax, dword [esp + 0x20]
    jge short .branch_484
    and eax, 3
    mov al, byte [eax + pow2char]
    mov edx, 0x3c5
    mov edi, dword [esp + 0x4c]
    mov esi, dword [esp + 0x50]
    and eax, 0xff
    mov ebx, 0xffffffff
    out dx, al
    mov eax, dword [esp + 0x44]
    sar edi, 2
    mov edx, dword [esp + 0x4c]
    add edi, eax
    mov eax, dword [esp + 0x48]
    mov ecx, dword [globalshade]
    sub eax, edx
    shl ecx, 8
    sar eax, 2
    mov edx, ebp
    call hlineasm4
    mov eax, dword [esp + 0x2c]
    mov ebx, dword [esp + 0x50]
    mov esi, dword [esp + 0x4c]
    mov ecx, dword [esp + 0x28]
    inc esi
    add ebx, eax
    add ebp, ecx
    mov dword [esp + 0x50], ebx
    mov dword [esp + 0x4c], esi
    jmp short .branch_414

.branch_484:
    mov eax, dword [esp + 0x2c]
    mov dword [asm1], eax
    mov eax, dword [esp + 0x28]

.branch_491:
    mov dword [asm2], eax
    jmp near .branch_785

.branch_49b:
    mov ebx, dword [esp + 0x4c]
    mov esi, dword [esp + 0x50]
    mov ecx, dword [globalshade]
    mov eax, dword [eax + row_offset]
    mov edx, ebp
    add eax, ebx
    mov ebx, dword [frameplace]
    shl ecx, 8
    add ebx, eax
    mov eax, dword [esp + 0x18]
    mov dword [esp + 0x44], ebx
    mov edi, ebx
    mov ebx, 0xffffffff
    call hlineasm4
    jmp near .branch_785

.branch_4d7:
    cmp byte [chainstat], 0
    je near .branch_729
    mov edi, dword [chainplace]
    mov ebx, ecx
    mov dword [esp + 0x3c], ecx
    mov dword [esp + 0x38], esi
    mov eax, dword [eax + row_offset]
    shl ebx, 2
    add eax, edi
    mov dword [asm1], ebx
    mov dword [esp + 0x44], eax
    mov eax, dword [esp + 0x4c]
    mov ebx, esi
    add eax, 3
    shl ebx, 2
    mov dword [esp + 0x40], eax
    mov eax, dword [esp + 0x48]
    mov edx, dword [esp + 0x40]
    mov dword [asm2], ebx
    cmp eax, edx
    jge short .branch_52f
    mov dword [esp + 0x40], eax

.branch_52f:
    mov ebx, dword [esp + 0x4c]
    mov ecx, dword [esp + 0x3c]
    mov esi, dword [esp + 0x4c]
    mov edx, dword [esp + 0x44]
    xor eax, eax
    inc ebx
    mov al, byte [engine_2891d7]
    mov dword [esp + 0x14], ebx
    mov ebx, dword [esp + 0x38]
    mov edi, esi
    add ebx, ebp
    sar edi, 2
    mov dword [esp + 0x10], ebx
    mov ebx, dword [esp + 0x50]
    add edi, edx
    add ebx, ecx
    mov ecx, dword [esp + 0x48]
    mov dword [esp + 0xc], ebx
    sub ecx, esi
    mov ebx, esi
    sar ecx, 2
    and ebx, 3
    shl ecx, 0x10
    cmp eax, 1
    jne near .branch_633
    mov edx, dword [esp + 0x40]
    mov dword [esp + 0x54], esi
    cmp esi, edx
    jg short .branch_5c3
    mov al, byte [ebx + pow2char]
    mov edx, 0x3c5
    and eax, 0xff
    mov ebx, dword [esp + 0x50]
    out dx, al
    mov esi, ebp
    mov eax, dword [globalbufplc]
    xor edx, edx
    call mhline
    mov eax, dword [esp + 0xc]
    mov dword [esp + 0x50], eax
    mov eax, dword [esp + 0x14]
    mov ebp, dword [esp + 0x10]
    mov dword [esp + 0x54], eax

.branch_5c3:
    mov eax, dword [esp + 0x54]
    cmp eax, dword [esp + 0x40]
    jg near .branch_717
    and eax, 3
    mov al, byte [eax + pow2char]
    mov edx, 0x3c5
    mov edi, dword [esp + 0x54]
    mov ecx, dword [esp + 0x48]
    and eax, 0xff
    mov ebx, dword [esp + 0x50]
    out dx, al
    mov esi, ebp
    mov eax, dword [esp + 0x44]
    sar edi, 2
    mov edx, dword [esp + 0x54]
    add edi, eax
    sub ecx, edx
    mov eax, dword [globalbufplc]
    sar ecx, 2
    xor edx, edx
    shl ecx, 0x10
    call mhlineskipmodify
    mov eax, dword [esp + 0x3c]
    mov ebx, dword [esp + 0x50]
    mov esi, dword [esp + 0x54]
    mov ecx, dword [esp + 0x38]
    inc esi
    add ebx, eax
    add ebp, ecx
    mov dword [esp + 0x50], ebx
    mov dword [esp + 0x54], esi
    jmp short .branch_5c3

.branch_633:
    mov eax, 4
    mov edx, 0x3ce
    out dx, al
    mov dword [esp + 0x54], esi
    mov eax, esi
    cmp eax, dword [esp + 0x40]
    jg short .branch_689
    mov al, byte [ebx + pow2char]
    mov edx, 0x3c5
    and eax, 0xff
    out dx, al
    mov edx, 0x3cf
    mov eax, ebx
    mov esi, ebp
    out dx, al
    mov ebx, dword [esp + 0x50]
    mov eax, dword [globalbufplc]
    xor edx, edx
    call thline
    mov eax, dword [esp + 0xc]
    mov dword [esp + 0x50], eax
    mov eax, dword [esp + 0x14]
    mov ebp, dword [esp + 0x10]
    mov dword [esp + 0x54], eax

.branch_689:
    mov eax, dword [esp + 0x54]
    cmp eax, dword [esp + 0x40]
    jg short .branch_6ff
    mov ebx, eax
    and ebx, 3
    mov al, byte [ebx + pow2char]
    mov edx, 0x3c5
    mov edi, dword [esp + 0x54]
    and eax, 0xff
    mov esi, dword [esp + 0x44]
    out dx, al
    mov edx, 0x3cf
    mov eax, ebx
    mov ecx, dword [esp + 0x48]
    out dx, al
    sar edi, 2
    mov edx, dword [esp + 0x54]
    mov ebx, dword [esp + 0x50]
    mov eax, dword [globalbufplc]
    add edi, esi
    sub ecx, edx
    mov esi, ebp
    sar ecx, 2
    xor edx, edx
    shl ecx, 0x10
    call thlineskipmodify
    mov eax, dword [esp + 0x3c]
    mov ebx, dword [esp + 0x50]
    mov esi, dword [esp + 0x54]
    mov ecx, dword [esp + 0x38]
    inc esi
    add ebx, eax
    add ebp, ecx
    mov dword [esp + 0x50], ebx
    mov dword [esp + 0x54], esi
    jmp short .branch_689

.branch_6ff:
    mov eax, dword [esp + 0x48]
    mov ebx, dword [esp + 0x4c]
    mov ecx, dword [transarea]
    sub eax, ebx
    add ecx, eax
    mov dword [transarea], ecx

.branch_717:
    mov eax, dword [esp + 0x3c]
    mov dword [asm1], eax
    mov eax, dword [esp + 0x38]
    jmp near .branch_491

.branch_729:
    mov ecx, dword [esp + 0x4c]
    mov eax, dword [eax + row_offset]
    add eax, ecx
    mov ecx, dword [frameplace]
    add ecx, eax
    mov dword [esp + 0x44], ecx
    mov ecx, dword [esp + 0x18]
    shl ecx, 0x10
    cmp ebx, 1
    jne short .branch_765
    mov edi, dword [esp + 0x44]
    mov ebx, dword [esp + 0x50]
    mov eax, dword [globalbufplc]
    mov esi, ebp
    xor edx, edx
    call mhline
    jmp short .branch_785

.branch_765:
    mov edi, dword [esp + 0x44]
    mov ebx, dword [esp + 0x50]
    mov eax, dword [globalbufplc]
    mov esi, ebp
    xor edx, edx
    call thline
    mov eax, dword [esp + 0x18]
    add dword [transarea], eax

.branch_785:
    dec dword [esp + 0x1c]

.branch_789:
    mov ebp, dword [esp + 0x1c]
    test ebp, ebp
    jge near .branch_2dd
    mov ecx, dword [esp + 0x30]
    mov esi, dword [esp + 0x24]
    mov eax, dword [globalx1]
    mov edx, dword [engine_286ad0]
    mov ebx, dword [engine_286ad4]
    add ecx, 0x54
    inc esi
    add edx, eax
    mov eax, dword [globaly2]
    mov dword [engine_286ad0], edx
    mov dword [esp + 0x30], ecx
    add ebx, eax
    mov dword [esp + 0x24], esi
    mov dword [engine_286ad4], ebx

.branch_7cf:
    mov eax, dword [esp + 0x24]
    cmp eax, dword [esp + 8]
    jle near .branch_2bd
    call faketimerhandler
    add esp, 0x58
    jmp near transmaskvline_restore
