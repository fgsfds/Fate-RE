; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's original clipmove.
BITS 32
ORG 0x5291f
getcliplines equ 0x52c88
raytrace equ 0x53cd5
keepaway equ 0x53c2e
inside equ 0x4c88f
ceil_slope equ 0x5de70
floor_slope equ 0x5df75

line_x2 equ 0x190360
line_x1 equ 0x190b60
line_y2 equ 0x196b50
line_y1 equ 0x197350
line_hits equ 0x196750
trace_hits equ 0x191748
clip_sectors equ 0x195f50
clip_sector_count equ 0x28912e
numsectors equ 0x289154
ceil_flags equ 0x27c3ac
floor_flags equ 0x27c3ae
ceil_base equ 0x27c3a4
floor_base equ 0x27c3a8

; Stack layout after the saved registers and local frame are allocated.
%define hit_y esp
%define hit_x esp+4
%define goal_y esp+8
%define goal_x esp+12
%define result esp+16
%define sector_ptr esp+20
%define z_ptr esp+24
%define y_ptr esp+28
%define original_vy esp+32
%define original_vx esp+36
%define line_index esp+40
%define remaining esp+44
%define x_vector esp+64
%define y_vector esp+68

clipmove_:
    push esi
    push edi
    push ebp
    sub esp, 48
    mov esi, [y_vector]
    mov edi, eax
    mov [y_ptr], edx
    mov [z_ptr], ebx
    mov [sector_ptr], ecx
    mov eax, [x_vector]
    or eax, esi
    je near .return
    xor edx, edx
    mov eax, [x_vector]
    mov [result], edx
    mov [original_vx], eax
    sar eax, 14
    mov edx, [edi]
    add edx, eax
    mov [goal_x], edx
    mov eax, esi
    mov edx, [y_ptr]
    sar eax, 14
    mov edx, [edx]
    add edx, eax

    ; Build collision lines for the original sector and target point.
    xor eax, eax
    mov al, [esp+84]
    push eax
    mov ebx, [esp+84]
    push ebx
    mov ecx, [esp+84]
    mov ebp, [esp+80]
    push ecx
    mov eax, [esp+32]
    mov [esp+20], edx
    push ebp
    movsx eax, word [eax]
    push eax
    mov ebx, [esp+44]
    mov ecx, [esp+32]
    push edx
    mov edx, [esp+52]
    mov ebx, [ebx]
    mov eax, [edi]
    mov edx, [edx]
    call getcliplines
    mov edx, 3
    mov [original_vy], esi
    mov [remaining], edx

.trace:
    mov eax, [goal_x]
    mov edx, [y_ptr]
    mov [hit_x], eax
    mov eax, [goal_y]
    mov ecx, esp
    mov [hit_y], eax
    lea ebx, [hit_x]
    mov edx, [edx]
    mov eax, [edi]
    call raytrace
    mov [line_index], eax
    test ax, ax
    jl near .store_position

    ; Project the remaining displacement along the hit line.
    cwde
    mov ebp, [nosplit eax*4+line_x2]
    mov edx, [nosplit eax*4+line_x1]
    mov ecx, [nosplit eax*4+line_y2]
    mov ebx, [nosplit eax*4+line_y1]
    sub ebp, edx
    sub ecx, ebx
    mov ebx, ebp
    imul ebx, ebp
    mov eax, ecx
    imul eax, ecx
    add ebx, eax
    test ebx, ebx
    jle .direction
    mov eax, [goal_x]
    mov esi, [hit_x]
    sub eax, esi
    mov esi, eax
    imul esi, ebp
    mov edx, [hit_y]
    mov eax, [goal_y]
    sub eax, edx
    imul eax, ecx
    add eax, esi
    mov edx, eax
    sar edx, 12
    shl eax, 20
    idiv ebx
    mov ebx, eax
    mov eax, ebp
    imul ebx
    shrd eax, edx, 20
    mov edx, [hit_x]
    add edx, eax
    mov eax, ecx
    mov [goal_x], edx
    imul ebx
    shrd eax, edx, 20
    mov edx, [hit_y]
    add edx, eax
    mov [goal_y], edx
.direction:
    mov esi, [original_vx]
    sar esi, 6
    imul esi, ebp
    mov eax, [original_vy]
    sar eax, 6
    imul eax, ecx
    movsx edx, word [remaining]
    inc edx
    add esi, eax
    jmp short .check_prior
.prior:
    movsx eax, word [nosplit edx*2+trace_hits]
    mov ebx, [nosplit eax*4+line_x2]
    sub ebx, [nosplit eax*4+line_x1]
    mov ecx, [original_vx]
    sar ecx, 6
    imul ebx, ecx
    mov ebp, [nosplit eax*4+line_y1]
    mov ecx, [nosplit eax*4+line_y2]
    mov eax, [original_vy]
    sub ecx, ebp
    sar eax, 6
    imul eax, ecx
    add ebx, eax
    xor ebx, esi
    test ebx, ebx
    jl near .result
    inc edx
.check_prior:
    cmp edx, 3
    jle .prior

    movsx ecx, word [line_index]
    lea edx, [goal_y]
    lea eax, [goal_x]
    mov ebx, ecx
    call keepaway
    mov eax, [goal_x]
    mov ebx, [hit_x]
    mov esi, [goal_y]
    sub eax, ebx
    mov ebp, [hit_y]
    shl eax, 14
    sub esi, ebp
    mov [x_vector], eax
    movsx eax, word [remaining]
    shl esi, 14
    cmp eax, 3
    jne .record_line
    movsx eax, word [nosplit ecx*2+line_hits]
    mov [result], eax
.record_line:
    movsx eax, word [remaining]
    mov edx, [line_index]
    mov [nosplit eax*2+trace_hits], dx
.store_position:
    mov eax, [hit_x]
    mov [edi], eax
    mov edx, [y_ptr]
    mov eax, [hit_y]
    mov ebx, [remaining]
    mov [edx], eax
    mov eax, [x_vector]
    dec ebx
    or eax, esi
    mov [remaining], ebx
    test eax, eax
    je .find_sector
    cmp word [line_index], 0
    jl .find_sector
    test bx, bx
    jg near .trace

.find_sector:
    xor ecx, ecx
    jmp short .test_candidate
.candidate:
    lea esi, [ecx+ecx]
    mov edx, [y_ptr]
    mov eax, [edi]
    movsx ebx, word [esi+clip_sectors]
    mov edx, [edx]
    call inside
    cmp eax, 1
    jne .next_candidate
    mov edx, [sector_ptr]
    mov ax, [esi+clip_sectors]
    mov [edx], ax
    jmp near .result
.next_candidate:
    inc ecx
.test_candidate:
    movsx eax, word [clip_sector_count]
    cmp ecx, eax
    jl .candidate

    ; If the collision list has no containing sector, search all sectors.
    mov eax, [sector_ptr]
    mov word [eax], -1
    movsx ecx, word [numsectors]
    mov esi, 0x7fffffff
    jmp near .next_sector
.sector:
    mov edx, [y_ptr]
    movsx ebp, cx
    mov eax, [edi]
    mov ebx, ebp
    mov edx, [edx]
    call inside
    cmp eax, 1
    jne near .next_sector
    mov eax, ecx
    shl eax, 2
    add eax, ecx
    shl eax, 3
    mov dx, [eax+ceil_flags]
    xor dh, dh
    and dl, 2
    movsx edx, dx
    test edx, edx
    je .flat_ceil
    mov ebx, [y_ptr]
    mov eax, ebp
    mov edx, [edi]
    mov ebx, [ebx]
    call ceil_slope
    mov edx, [z_ptr]
    mov ebx, [edx]
    sub eax, ebx
    mov ebx, eax
    jmp .check_ceil
.flat_ceil:
    mov ebx, [eax+ceil_base]
    mov eax, [z_ptr]
    sub ebx, [eax]
.check_ceil:
    test ebx, ebx
    jle .check_floor
    cmp ebx, esi
    jge .next_sector
    jmp .closer
.check_floor:
    mov eax, ecx
    shl eax, 2
    add eax, ecx
    shl eax, 3
    mov dx, [eax+floor_flags]
    xor dh, dh
    and dl, 2
    movsx edx, dx
    test edx, edx
    je .flat_floor
    mov ebx, [y_ptr]
    movsx eax, cx
    mov edx, [edi]
    mov ebx, [ebx]
    call floor_slope
    mov ebx, [z_ptr]
    mov ebx, [ebx]
    sub ebx, eax
    jmp .check_distance
.flat_floor:
    mov ebx, [z_ptr]
    mov ebp, [eax+floor_base]
    mov ebx, [ebx]
    sub ebx, ebp
.check_distance:
    test ebx, ebx
    jg .outside_height
    mov eax, [sector_ptr]
    mov [eax], cx
    jmp .result
.outside_height:
    cmp ebx, esi
    jge .next_sector
.closer:
    mov eax, [sector_ptr]
    mov esi, ebx
    mov [eax], cx
.next_sector:
    dec ecx
    test ecx, ecx
    jge near .sector
.result:
    mov eax, [result]
.return:
    add esp, 48
shared_clip_return:
    pop ebp
    pop edi
    pop esi
    ret 24
