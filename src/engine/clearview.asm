; Fill the viewport in stereo, planar VGA or linear video memory.
BITS 32
ORG 0x5cd99

qsetmode equ 0x140ba
window_right equ 0x286b98
window_left equ 0x286b9c
window_top equ 0x286b94
stereofps equ 0x14014
stereo_buffer equ 0x13ff0
ylookup equ 0x286bb0
ylookup_second_row equ 0x286bb4
window_bottom equ 0x286b90
chainstat equ 0x14003
plane_bits equ 0x14029
chainplace equ 0x286b4c
frameplace equ 0x286b74
clearview_restore equ 0x4bb05
faketimerhandler equ 0x31ec4

clearview_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 4
    push eax
    cmp dword [qsetmode], 0xc8
    jne near clearview_restore
    mov eax, dword [window_right]
    mov ebx, dword [window_left]
    sub eax, ebx
    lea ebp, [eax + 1]
    mov eax, dword [esp]
    mov ecx, dword [esp]
    shl eax, 8
    add ecx, eax
    mov edx, dword [window_top]
    mov eax, ecx
    mov edi, dword [stereofps]
    shl eax, 0x10
    mov dword [esp], ecx
    lea esi, [ecx + eax]
    shl edx, 2
    mov dword [esp], esi
    test edi, edi
    je near .check_planar_mode
    mov eax, dword [stereo_buffer]
    add eax, dword [edx + ylookup]
    mov edx, dword [window_top]
    lea esi, [ebx + eax]
    jmp near .check_stereo_row

.fill_stereo_row:
    mov eax, dword [esp]
    mov ecx, ebp
    mov edi, esi
    cmp ecx, 4
    jae short .branch_08c
    test cl, 1
    je short .branch_085
    stosb

.branch_085:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_0b7

.branch_08c:
    test edi, 1
    je short .branch_096
    stosb
    dec ecx

.branch_096:
    test edi, 2
    je short .branch_0a3
    stosw
    sub ecx, 2

.branch_0a3:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_0b1
    stosw

.branch_0b1:
    test bl, 1
    je short .branch_0b7
    stosb

.branch_0b7:
    mov eax, dword [esp]
    lea edi, [esi + 0x10000]
    mov ecx, ebp
    cmp ecx, 4
    jae short .branch_0d4
    test cl, 1
    je short .branch_0cd
    stosb

.branch_0cd:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_0ff

.branch_0d4:
    test edi, 1
    je short .branch_0de
    stosb
    dec ecx

.branch_0de:
    test edi, 2
    je short .branch_0eb
    stosw
    sub ecx, 2

.branch_0eb:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_0f9
    stosw

.branch_0f9:
    test bl, 1
    je short .branch_0ff
    stosb

.branch_0ff:
    mov ebx, dword [ylookup_second_row]
    inc edx
    add esi, ebx

.check_stereo_row:
    cmp edx, dword [window_bottom]
    jle near .fill_stereo_row
    jmp near .service_timer

.check_planar_mode:
    cmp byte [chainstat], 0
    je near .clear_linear_window
    mov eax, dword [window_right]
    inc eax
    mov edx, 0x3c4
    mov dword [esp + 4], eax
    mov eax, 2
    mov ecx, ebx
    out dx, al
    test bl, 3
    je short .check_right_edge
    mov eax, ebx
    and eax, 3
    mov al, byte [eax + plane_bits]
    mov edx, 0x10
    and eax, 0xff
    sub edx, eax
    mov eax, edx
    mov edx, 0x3c5
    out dx, al
    mov esi, dword [chainplace]
    mov eax, ebx
    mov edx, dword [window_top]
    sar eax, 2
    mov bl, byte [esp]
    add eax, esi
    jmp short .check_left_edge_row

.fill_left_edge_row:
    mov esi, dword [edx*4 + ylookup]
    inc edx
    mov byte [esi + eax], bl

.check_left_edge_row:
    cmp edx, dword [window_bottom]
    jle short .fill_left_edge_row

.check_right_edge:
    test byte [esp + 4], 3
    je short .planar_interior
    mov eax, dword [esp + 4]
    and eax, 3
    mov al, byte [eax + plane_bits]
    and eax, 0xff
    mov edx, 0x3c5
    dec eax
    mov bl, byte [esp]
    out dx, al
    mov eax, dword [esp + 4]
    mov edi, dword [chainplace]
    sar eax, 2
    mov edx, dword [window_top]
    add eax, edi
    jmp short .check_right_edge_row

.fill_right_edge_row:
    mov esi, dword [edx*4 + ylookup]
    inc edx
    mov byte [esi + eax], bl

.check_right_edge_row:
    cmp edx, dword [window_bottom]
    jle short .fill_right_edge_row

.planar_interior:
    mov eax, dword [esp + 4]
    add ecx, 3
    sar eax, 2
    sar ecx, 2
    mov dword [esp + 4], eax
    cmp ecx, eax
    jge near .service_timer
    mov eax, 0xf
    mov edx, 0x3c5
    out dx, al
    mov edx, dword [window_top]
    mov eax, dword [chainplace]
    mov ebx, dword [edx*4 + ylookup]
    mov ebp, dword [esp + 4]
    add eax, ebx
    sub ebp, ecx
    lea esi, [eax + ecx]
    jmp short .check_planar_row

.branch_21c:
    mov eax, dword [esp]

.fill_planar_row:
    mov ecx, ebp
    mov edi, esi
    cmp ecx, 4
    jae short .branch_235
    test cl, 1
    je short .branch_22e
    stosb

.branch_22e:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_260

.branch_235:
    test edi, 1
    je short .branch_23f
    stosb
    dec ecx

.branch_23f:
    test edi, 2
    je short .branch_24c
    stosw
    sub ecx, 2

.branch_24c:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_25a
    stosw

.branch_25a:
    test bl, 1
    je short .branch_260
    stosb

.branch_260:
    mov edi, dword [ylookup_second_row]
    inc edx
    add esi, edi

.check_planar_row:
    cmp edx, dword [window_bottom]
    jle short .branch_21c
    jmp short .service_timer

.clear_linear_window:
    mov eax, dword [frameplace]
    mov ebx, dword [edx + ylookup]
    mov esi, dword [window_left]
    add eax, ebx
    mov edx, dword [window_top]
    add esi, eax
    jmp short .check_linear_row

.fill_linear_row:
    mov eax, dword [esp]
    mov ecx, ebp
    mov edi, esi
    cmp ecx, 4
    jae short .branch_2a9
    test cl, 1
    je short .branch_2a2
    stosb

.branch_2a2:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_2d4

.branch_2a9:
    test edi, 1
    je short .branch_2b3
    stosb
    dec ecx

.branch_2b3:
    test edi, 2
    je short .branch_2c0
    stosw
    sub ecx, 2

.branch_2c0:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_2ce
    stosw

.branch_2ce:
    test bl, 1
    je short .branch_2d4
    stosb

.branch_2d4:
    mov ebx, dword [ylookup_second_row]
    inc edx
    add esi, ebx

.check_linear_row:
    cmp edx, dword [window_bottom]
    jle short .fill_linear_row

.service_timer:
    call faketimerhandler
    jmp near clearview_restore
