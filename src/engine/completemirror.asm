; Find the mirror span and reverse its scanlines in planar or linear video memory.
BITS 32
ORG 0x5d91e

chainstat equ 0x14003
window_left equ 0x286b9c
window_right equ 0x286b98
mirror_sector equ 0x289120
mirror_z equ 0x2863a4
sector_ceilingz equ 0x27c3a4
sector_floorz equ 0x27c3a8
mirror_row equ 0x2863a0
chainplace equ 0x286b4c
ylookup equ 0x286bb0
window_top equ 0x286b94
window_bottom equ 0x286b90
transarea equ 0x14008
mirror_scanline equ 0x1dda60
plane_bits equ 0x14029
frameplace equ 0x286b74
completemirror_restore equ 0x4abbb
faketimerhandler equ 0x31ec4

completemirror_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x10
    cmp byte [chainstat], 0
    je near .complete_linear_mirror
    mov eax, 4
    mov edx, 0x3ce
    out dx, al
    mov eax, 2
    mov edx, 0x3c4
    out dx, al
    mov eax, dword [window_left]
    mov dword [esp + 8], eax
    mov eax, dword [window_right]
    movsx edx, word [mirror_sector]
    mov dword [esp + 0xc], eax
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    mov edx, dword [mirror_z]
    cmp edx, dword [eax + sector_ceilingz]
    jle near .check_planar_bounds
    cmp edx, dword [eax + sector_floorz]
    jge near .check_planar_bounds

.scan_planar_left_edge:
    mov eax, dword [esp + 0xc]
    mov ebp, dword [esp + 8]
    cmp eax, ebp
    jl short .start_planar_right_edge
    mov eax, ebp
    mov edx, 0x3cf
    and eax, 3
    out dx, al
    mov edx, dword [mirror_row]
    mov eax, dword [chainplace]
    mov ebx, dword [edx*4 + ylookup]
    mov edx, ebp
    add eax, ebx
    sar edx, 2
    add edx, eax
    xor eax, eax
    mov al, byte [edx]
    cmp eax, 0xff
    jne short .start_planar_right_edge
    lea ecx, [ebp + 1]
    mov dword [esp + 8], ecx
    jmp short .scan_planar_left_edge

.start_planar_right_edge:
    mov esi, dword [esp + 8]

.scan_planar_right_edge:
    mov eax, dword [esp + 0xc]
    cmp eax, esi
    jl short .branch_0f6
    mov edx, 0x3cf
    and eax, 3
    out dx, al
    mov edx, dword [mirror_row]
    mov eax, dword [chainplace]
    mov edi, dword [edx*4 + ylookup]
    mov edx, dword [esp + 0xc]
    add eax, edi
    sar edx, 2
    add edx, eax
    xor eax, eax
    mov al, byte [edx]
    cmp eax, 0xff
    jne short .branch_0f6
    dec dword [esp + 0xc]
    jmp short .scan_planar_right_edge

.branch_0f6:
    mov eax, dword [esp + 8]
    cmp eax, dword [window_left]
    jle short .branch_109
    lea ebx, [eax - 1]
    mov dword [esp + 8], ebx

.branch_109:
    mov eax, dword [esp + 0xc]
    cmp eax, dword [window_right]
    jge short .check_planar_bounds
    lea esi, [eax + 1]
    mov dword [esp + 0xc], esi

.check_planar_bounds:
    mov eax, dword [esp + 0xc]
    mov edi, dword [esp + 8]
    cmp eax, edi
    jl near completemirror_restore
    mov ebx, dword [window_top]
    mov edx, eax
    mov eax, dword [window_bottom]
    sub edx, edi
    sub eax, ebx
    imul eax, edx
    mov ecx, dword [transarea]
    add ecx, eax
    mov dword [esp + 4], ebx
    mov dword [transarea], ecx
    jmp near .check_planar_row

.reverse_planar_row:
    mov ebx, dword [esp + 0xc]
    sub ebx, dword [esp + 8]
    xor ebp, ebp
    cmp ebx, 3
    jl short .check_planar_read_plane
    mov ebx, 3
    jmp short .check_planar_read_plane

.read_planar_plane:
    mov eax, dword [esp + 0xc]
    mov ecx, dword [esp + 8]
    inc eax
    add ecx, ebx
    sub eax, ecx
    add eax, 3
    sar eax, 2
    mov dword [esp], eax
    mov eax, ecx
    mov edx, 0x3cf
    and eax, 3
    out dx, al
    mov eax, dword [esp + 4]
    mov edi, mirror_scanline
    mov edx, dword [chainplace]
    mov esi, dword [eax*4 + ylookup]
    sar ecx, 2
    add esi, edx
    add edi, ebp
    add esi, ecx
    mov ecx, dword [esp]
    test cl, 1
    je short .branch_1b6
    movsb

.branch_1b6:
    shr ecx, 2
    jae short .branch_1bd
    movsw

.branch_1bd:
    rep movsd
    mov edi, dword [esp]
    dec ebx
    add ebp, edi

.check_planar_read_plane:
    test ebx, ebx
    jge short .read_planar_plane
    mov ebx, dword [esp + 0xc]
    sub ebx, dword [esp + 8]
    xor ebp, ebp
    cmp ebx, 3
    jl near .check_planar_write_plane
    mov ebx, 3
    jmp near .check_planar_write_plane

.write_planar_plane:
    mov ecx, dword [esp + 0xc]
    mov eax, dword [esp + 8]
    inc ecx
    add eax, ebx
    mov edx, dword [window_left]
    sub ecx, eax
    mov esi, dword [window_right]
    add ecx, 3
    add esi, edx
    sar ecx, 2
    sub esi, eax
    mov eax, ecx
    shl eax, 2
    sub eax, 4
    sub esi, eax
    mov edx, esi
    and edx, 3
    mov al, byte [edx + plane_bits]
    mov edx, 0x3c5
    and eax, 0xff
    mov edi, dword [esp + 4]
    out dx, al
    add ebp, ecx
    mov edx, dword [chainplace]
    mov eax, dword [edi*4 + ylookup]
    mov edi, esi
    add eax, edx
    lea esi, [ebp - 1]
    sar edi, 2
    add esi, mirror_scanline
    add edi, eax
    dec ebx
    shr ecx, 1
    jae short .branch_259
    mov al, byte [esi]
    dec esi
    mov byte [edi], al
    inc edi

.branch_259:
    shr ecx, 1
    jae short .branch_26e
    mov ax, word [esi - 1]
    sub esi, 2
    ror ax, 8
    mov word [edi], ax
    add edi, 2

.branch_26e:
    test ecx, ecx
    je short .check_planar_write_plane

.branch_272:
    mov eax, dword [esi - 3]
    sub esi, 4
    bswap eax
    mov dword [edi], eax
    add edi, 4
    dec ecx
    jne short .branch_272

.check_planar_write_plane:
    test ebx, ebx
    jge near .write_planar_plane
    mov ebp, dword [esp + 4]
    inc ebp
    call faketimerhandler
    mov dword [esp + 4], ebp

.check_planar_row:
    mov eax, dword [esp + 4]
    cmp eax, dword [window_bottom]
    jle near .reverse_planar_row
    jmp near completemirror_restore

.complete_linear_mirror:
    mov eax, dword [window_right]
    xor edx, edx
    mov ebx, dword [window_left]
    mov dword [esp + 8], edx
    sub eax, ebx
    movsx edx, word [mirror_sector]
    mov dword [esp + 0xc], eax
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    mov edx, dword [mirror_z]
    cmp edx, dword [eax + sector_ceilingz]
    jle near .check_linear_bounds
    cmp edx, dword [eax + sector_floorz]
    jge near .check_linear_bounds
    mov edx, dword [mirror_row]
    mov eax, dword [frameplace]
    add eax, dword [edx*4 + ylookup]
    lea edx, [ebx + eax]

.scan_linear_left_edge:
    mov eax, dword [esp + 8]
    mov al, byte [edx + eax]
    and eax, 0xff
    cmp eax, 0xff
    jne short .branch_330
    mov eax, dword [esp + 0xc]
    mov ecx, dword [esp + 8]
    cmp eax, ecx
    jl short .branch_330
    lea esi, [ecx + 1]
    mov dword [esp + 8], esi
    jmp short .scan_linear_left_edge

.branch_330:
    mov edi, dword [esp + 8]

.scan_linear_right_edge:
    mov eax, dword [esp + 0xc]
    mov al, byte [edx + eax]
    and eax, 0xff
    cmp eax, 0xff
    jne short .branch_358
    mov eax, dword [esp + 0xc]
    cmp eax, edi
    jl short .branch_358
    lea ebp, [eax - 1]
    mov dword [esp + 0xc], ebp
    jmp short .scan_linear_right_edge

.branch_358:
    mov ebp, dword [esp + 8]
    test ebp, ebp
    jle short .branch_367
    lea eax, [ebp - 1]
    mov dword [esp + 8], eax

.branch_367:
    mov eax, dword [window_right]
    mov edx, dword [window_left]
    mov ebx, dword [esp + 0xc]
    sub eax, edx
    cmp eax, ebx
    jle short .branch_383
    lea ecx, [ebx + 1]
    mov dword [esp + 0xc], ecx

.branch_383:
    mov dl, byte [esp + 0xc]
    mov eax, dword [window_right]
    or dl, 3
    mov esi, dword [window_left]
    mov byte [esp + 0xc], dl
    sub eax, esi
    cmp eax, dword [esp + 0xc]
    jge short .check_linear_bounds
    mov dword [esp + 0xc], eax

.check_linear_bounds:
    mov eax, dword [esp + 0xc]
    mov edx, dword [esp + 8]
    cmp eax, edx
    jl near completemirror_restore
    mov ecx, dword [window_bottom]
    mov ebx, eax
    mov esi, dword [window_top]
    sub ebx, edx
    sub ecx, esi
    mov eax, ebx
    imul eax, ecx
    mov edi, dword [transarea]
    mov ebp, dword [esi*4 + ylookup]
    mov edx, dword [window_left]
    mov esi, dword [window_left]
    mov dword [esp + 4], ecx
    add edi, eax
    mov eax, dword [frameplace]
    mov dword [transarea], edi
    mov edi, dword [esp + 0xc]
    add eax, ebp
    mov ebp, dword [window_right]
    mov dword [esp + 0xc], ebx
    add edx, eax
    sub ebp, esi
    inc ebx
    sub ebp, edi
    jmp near .check_linear_row

.reverse_linear_row:
    mov esi, dword [esp + 8]
    mov edi, mirror_scanline
    inc esi
    mov ecx, ebx
    add esi, edx
    test cl, 1
    je short .branch_426
    movsb

.branch_426:
    shr ecx, 2
    jae short .branch_42d
    movsw

.branch_42d:
    rep movsd
    mov eax, dword [esp + 0xc]
    mov ecx, dword [esp + 0xc]
    mov esi, mirror_scanline
    lea edi, [edx + ebp]
    mov al, byte [eax + mirror_scanline - 1]
    add esi, ecx
    mov byte [ecx + mirror_scanline], al
    mov ecx, ebx
    shr ecx, 1
    jae short .branch_459
    mov al, byte [esi]
    dec esi
    mov byte [edi], al
    inc edi

.branch_459:
    shr ecx, 1
    jae short .branch_46e
    mov ax, word [esi - 1]
    sub esi, 2
    ror ax, 8
    mov word [edi], ax
    add edi, 2

.branch_46e:
    test ecx, ecx
    je short .advance_linear_row

.write_linear_dword:
    mov eax, dword [esi - 3]
    sub esi, 4
    bswap eax
    mov dword [edi], eax
    add edi, 4
    dec ecx
    jne short .write_linear_dword

.advance_linear_row:
    mov edi, dword [esp + 4]
    mov esi, dword [ylookup + 4]
    call faketimerhandler
    dec edi
    add edx, esi
    mov dword [esp + 4], edi

.check_linear_row:
    cmp dword [esp + 4], 0
    jge near .reverse_linear_row
    jmp near completemirror_restore
