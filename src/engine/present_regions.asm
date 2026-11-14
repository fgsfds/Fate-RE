; Copy rendered screen regions through the selected presentation path.
BITS 32
ORG 0x44220

row_offset equ 0x286bb0
startdmost equ 0x1f8020
startumost equ 0x1f13a0
windowx1 equ 0x286b9c
windowy1 equ 0x286b94
presentation_width equ 0x287e90
presentation_height equ 0x287e8c
draw_columns_callback equ 0x13ff5
draw_frame_callback equ 0x13ff9
engine_286b84 equ 0x286b84
engine_286b98 equ 0x286b98
engine_286b90 equ 0x286b90
engine_13ffd equ 0x13ffd
engine_286b60 equ 0x286b60
engine_13ff0 equ 0x13ff0
engine_1ec5a0 equ 0x1ec5a0
engine_1eafe0 equ 0x1eafe0
engine_1eafe4 equ 0x1eafe4
engine_1eafdc equ 0x1eafdc
engine_1f13a2 equ 0x1f13a2
engine_286bb4 equ 0x286bb4
engine_13ffe equ 0x13ffe
engine_286b5c equ 0x286b5c
engine_286b54 equ 0x286b54
engine_286b70 equ 0x286b70
engine_1ec4a0 equ 0x1ec4a0
engine_1ec4a2 equ 0x1ec4a2
faketimerhandler equ 0x31ec4
blit_region equ 0x4380a
transmaskvline_restore equ 0x4abbe

present_regions_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x34
    push eax
    cmp dword [engine_286b84], 0
    je near .branch_4b5
    mov edx, dword [engine_286b98]
    mov dword [esp + 0x1c], edx
    mov edx, dword [engine_286b90]
    mov eax, dword [windowx1]
    mov dword [esp + 0x18], edx
    mov dl, byte [engine_13ffd]
    mov ecx, dword [windowy1]
    test dl, dl
    je short .branch_05a
    mov edx, dword [presentation_width]
    dec edx
    mov dword [esp + 0x1c], edx
    mov edx, dword [presentation_height]
    xor eax, eax
    dec edx
    xor ecx, ecx
    mov dword [esp + 0x18], edx

.branch_05a:
    mov edx, dword [esp + 0x1c]
    sub edx, eax
    inc edx
    mov dword [esp + 0x20], edx
    mov edx, ecx
    mov ebx, dword [engine_286b60]
    shl edx, 2
    test ebx, ebx
    je near .branch_311
    mov ebx, dword [engine_13ff0]
    mov dword [esp + 0x34], ebx
    mov ebx, dword [esp]
    shl ebx, 2
    mov edi, dword [esp + 0x34]
    mov esi, dword [ebx + engine_1ec5a0]
    sub esi, edi
    mov dword [esp + 0x30], esi
    cmp byte [engine_13ffd], 0
    jne near .branch_29c
    movsx edx, word [nosplit eax*2 + startumost]
    mov dword [esp + 0x14], eax
    mov ebx, edx
    jmp near .branch_242

.branch_0b8:
    movsx ecx, word [nosplit eax*2 + startumost]
    movsx eax, word [nosplit eax*2 + startdmost]
    dec ecx
    mov dword [esp + 0x28], eax
    dec eax
    mov dword [esp + 0x2c], ecx
    cmp eax, ecx
    jle near .branch_1e3
    cmp ebx, ecx
    jg short .branch_12b

.branch_0de:
    lea eax, [ebx - 1]
    cmp edx, eax
    jge short .branch_125
    inc edx
    test dl, 0x1f
    jne short .branch_0f0
    call faketimerhandler

.branch_0f0:
    mov ebp, dword [esp + 0x34]
    mov edi, dword [esp + 0x30]
    mov ecx, dword [edx*4 + row_offset]
    mov esi, dword [edx*4 + engine_1eafe0]
    add ebp, ecx
    mov ecx, dword [esp + 0x14]
    add ebp, esi
    sub ecx, esi
    add edi, ebp
    mov esi, ebp
    test cl, 1
    je short .branch_11a
    movsb

.branch_11a:
    shr ecx, 2
    jae short .branch_121
    movsw

.branch_121:
    rep movsd
    jmp short .branch_0de

.branch_125:
    mov edx, dword [esp + 0x2c]
    jmp short .branch_187

.branch_12b:
    cmp edx, dword [esp + 0x2c]
    jge short .branch_171
    inc edx
    test dl, 0x1f
    jne short .branch_13c
    call faketimerhandler

.branch_13c:
    mov ebp, dword [esp + 0x34]
    mov edi, dword [esp + 0x30]
    mov ecx, dword [edx*4 + row_offset]
    mov esi, dword [edx*4 + engine_1eafe0]
    add ebp, ecx
    mov ecx, dword [esp + 0x14]
    add ebp, esi
    sub ecx, esi
    add edi, ebp
    mov esi, ebp
    test cl, 1
    je short .branch_166
    movsb

.branch_166:
    shr ecx, 2
    jae short .branch_16d
    movsw

.branch_16d:
    rep movsd
    jmp short .branch_12b

.branch_171:
    mov ecx, dword [esp + 0x14]
    mov ebp, dword [esp + 0x2c]

.branch_179:
    cmp edx, ebp
    jle short .branch_187
    dec edx
    mov dword [edx*4 + engine_1eafe4], ecx
    jmp short .branch_179

.branch_187:
    cmp ebx, dword [esp + 0x28]
    jle short .branch_1cd
    dec ebx
    test bl, 0x1f
    jne short .branch_198
    call faketimerhandler

.branch_198:
    mov ebp, dword [esp + 0x34]
    mov edi, dword [esp + 0x30]
    mov ecx, dword [ebx*4 + row_offset]
    mov esi, dword [ebx*4 + engine_1eafe0]
    add ebp, ecx
    mov ecx, dword [esp + 0x14]
    add ebp, esi
    sub ecx, esi
    add edi, ebp
    mov esi, ebp
    test cl, 1
    je short .branch_1c2
    movsb

.branch_1c2:
    shr ecx, 2
    jae short .branch_1c9
    movsw

.branch_1c9:
    rep movsd
    jmp short .branch_187

.branch_1cd:
    mov ecx, dword [esp + 0x14]
    mov ebp, dword [esp + 0x28]

.branch_1d5:
    cmp ebx, ebp
    jge short .branch_23e
    inc ebx
    mov dword [ebx*4 + engine_1eafdc], ecx
    jmp short .branch_1d5

.branch_1e3:
    lea eax, [ebx - 1]
    cmp edx, eax
    jge short .branch_22a
    inc edx
    test dl, 0x1f
    jne short .branch_1f5
    call faketimerhandler

.branch_1f5:
    mov ebp, dword [esp + 0x34]
    mov edi, dword [esp + 0x30]
    mov ecx, dword [edx*4 + row_offset]
    mov esi, dword [edx*4 + engine_1eafe0]
    add ebp, ecx
    mov ecx, dword [esp + 0x14]
    add ebp, esi
    sub ecx, esi
    add edi, ebp
    mov esi, ebp
    test cl, 1
    je short .branch_21f
    movsb

.branch_21f:
    shr ecx, 2
    jae short .branch_226
    movsw

.branch_226:
    rep movsd
    jmp short .branch_1e3

.branch_22a:
    mov eax, dword [esp + 0x14]
    cmp eax, dword [esp + 0x1c]
    je short .branch_250
    movsx edx, word [nosplit eax*2 + engine_1f13a2]
    mov ebx, edx

.branch_23e:
    inc dword [esp + 0x14]

.branch_242:
    mov eax, dword [esp + 0x14]
    cmp eax, dword [esp + 0x1c]
    jle near .branch_0b8

.branch_250:
    lea eax, [ebx - 1]
    cmp edx, eax
    jge near .branch_4ad
    inc edx
    test dl, 0x1f
    jne short .branch_266
    call faketimerhandler

.branch_266:
    mov ebp, dword [esp + 0x34]
    mov edi, dword [esp + 0x30]
    mov ecx, dword [edx*4 + row_offset]
    mov esi, dword [edx*4 + engine_1eafe0]
    add ebp, ecx
    mov ecx, dword [esp + 0x1c]
    add ebp, esi
    inc ecx
    add edi, ebp
    sub ecx, esi
    mov esi, ebp
    test cl, 1
    je short .branch_291
    movsb

.branch_291:
    shr ecx, 2
    jae short .branch_298
    movsw

.branch_298:
    rep movsd
    jmp short .branch_250

.branch_29c:
    add eax, dword [edx + row_offset]
    lea edx, [edi + eax]
    mov eax, dword [ebx + engine_1ec5a0]
    mov ebx, dword [engine_13ff0]
    mov dword [esp + 0x24], ecx
    sub eax, ebx
    mov dword [esp + 0x34], edx
    mov dword [esp + 0x30], eax
    jmp short .branch_302

.branch_2c1:
    mov edi, dword [esp + 0x34]
    mov esi, dword [esp + 0x30]
    mov ecx, dword [esp + 0x20]
    add edi, esi
    mov esi, dword [esp + 0x34]
    test cl, 1
    je short .branch_2d9
    movsb

.branch_2d9:
    shr ecx, 2
    jae short .branch_2e0
    movsw

.branch_2e0:
    rep movsd
    mov edi, dword [esp + 0x34]
    add edi, dword [engine_286bb4]
    mov dh, byte [esp + 0x24]
    mov dword [esp + 0x34], edi
    test dh, 0x1f
    jne short .branch_2fe
    call faketimerhandler

.branch_2fe:
    inc dword [esp + 0x24]

.branch_302:
    mov eax, dword [esp + 0x24]
    cmp eax, dword [esp + 0x18]
    jle short .branch_2c1
    jmp near .branch_4ad

.branch_311:
    mov edx, dword [edx + row_offset]
    add edx, eax
    mov dword [esp + 0x24], ecx
    mov dword [esp + 0x34], edx
    jmp near .branch_49f

.branch_326:
    mov eax, dword [esp + 0x34]
    mov esi, dword [engine_13ffe]
    sar eax, 0x10
    cmp eax, esi
    je short .branch_399
    mov edi, dword [draw_columns_callback]
    mov dword [engine_13ffe], eax
    test edi, edi
    je short .branch_35e
    mov cl, byte [engine_286b5c]
    mov edx, eax
    xor ebx, ebx
    shl edx, cl
    xor eax, eax
    xor ecx, ecx
    call dword [draw_columns_callback]
    jmp short .branch_394

.branch_35e:
    mov edx, 0x4f05
    mov ax, word [engine_13ffe]
    mov cl, byte [engine_286b5c]
    xor ebx, ebx
    mov word [esp + 4], dx
    mov word [esp + 6], bx
    shl eax, cl
    lea ebx, [esp + 4]
    lea edx, [esp + 4]
    mov word [esp + 0xa], ax
    mov eax, 0x10
    call blit_region

.branch_394:
    call faketimerhandler

.branch_399:
    mov ecx, dword [esp + 0x34]
    mov ebp, dword [esp + 0x20]
    and ecx, 0xffff
    mov eax, dword [esp + 0x34]
    add ebp, ecx
    mov edx, dword [engine_13ff0]
    sub ebp, 0x10000
    add eax, edx
    test ebp, ebp
    jg short .branch_3d0
    lea edi, [ecx + 0xa0000]
    mov esi, eax
    mov ecx, dword [esp + 0x20]
    jmp near .branch_478

.branch_3d0:
    mov ecx, dword [esp + 0x20]
    mov edi, 0xb0000
    sub ecx, ebp
    mov esi, eax
    sub edi, ecx
    mov ebx, dword [esp + 0x20]
    test cl, 1
    je short .branch_3e9
    movsb

.branch_3e9:
    shr ecx, 2
    jae short .branch_3f0
    movsw

.branch_3f0:
    rep movsd
    mov eax, dword [esp + 0x34]
    add eax, ebx
    dec eax
    sar eax, 0x10
    mov ecx, dword [draw_columns_callback]
    mov dword [engine_13ffe], eax
    test ecx, ecx
    je short .branch_423
    mov cl, byte [engine_286b5c]
    mov edx, eax
    xor ebx, ebx
    shl edx, cl
    xor eax, eax
    xor ecx, ecx
    call dword [draw_columns_callback]
    jmp short .branch_459

.branch_423:
    mov ecx, 0x4f05
    lea ebx, [esp + 4]
    mov ax, word [engine_13ffe]
    mov word [esp + 4], cx
    mov cl, byte [engine_286b5c]
    lea edx, [esp + 4]
    shl eax, cl
    xor esi, esi
    mov word [esp + 0xa], ax
    mov eax, 0x10
    mov word [esp + 6], si
    call blit_region

.branch_459:
    call faketimerhandler
    mov esi, dword [esp + 0x20]
    mov edi, dword [esp + 0x34]
    mov eax, dword [engine_13ff0]
    sub esi, ebp
    mov ecx, ebp
    add esi, edi
    mov edi, 0xa0000
    add esi, eax

.branch_478:
    test cl, 1
    je short .branch_47e
    movsb

.branch_47e:
    shr ecx, 2
    jae short .branch_485
    movsw

.branch_485:
    rep movsd
    mov edx, dword [esp + 0x34]
    mov eax, dword [engine_286bb4]
    mov ebx, dword [esp + 0x24]
    add edx, eax
    inc ebx
    mov dword [esp + 0x34], edx
    mov dword [esp + 0x24], ebx

.branch_49f:
    mov eax, dword [esp + 0x24]
    cmp eax, dword [esp + 0x18]
    jle near .branch_326

.branch_4ad:
    xor bl, bl
    mov byte [engine_13ffd], bl

.branch_4b5:
    cmp dword [engine_286b54], 0
    jne near .branch_544
    cmp dword [draw_frame_callback], 0
    je short .branch_4f6
    mov ecx, dword [esp]
    mov ebp, dword [engine_286b70]
    imul ebp, ecx
    mov dx, 0x3da

.branch_4db:
    in al, dx
    test al, 1
    jne short .branch_4db
    xor ebx, ebx
    xor eax, eax
    mov edx, ebp
    mov ecx, ebp
    sar edx, 0x12
    sar ecx, 2
    call dword [draw_frame_callback]
    jmp short .branch_53f

.branch_4f6:
    mov edx, dword [esp]
    xor eax, eax
    mov edi, 0x4f07
    mov word [esp + 6], ax
    mov ax, word [edx*4 + engine_1ec4a0]
    lea ebx, [esp + 4]
    mov word [esp + 8], ax
    mov ax, word [edx*4 + engine_1ec4a2]
    mov word [esp + 4], di
    mov word [esp + 0xa], ax
    mov dx, 0x3da

.branch_52c:
    in al, dx
    test al, 1
    jne short .branch_52c
    lea edx, [esp + 4]
    mov eax, 0x10
    call blit_region

.branch_53f:
    call faketimerhandler

.branch_544:
    add esp, 0x38
    jmp near transmaskvline_restore
