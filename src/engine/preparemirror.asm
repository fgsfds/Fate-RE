; Reflect the camera across a wall and mark the mirror scanline.
BITS 32
ORG 0x5d656

wall_x equ 0x2310a0
wall_point2 equ 0x2310a8
wall_y equ 0x2310a4
mirror_z equ 0x2863a4
mirror_sector equ 0x289120
sector_ceilingz equ 0x27c3a4
sector_floorz equ 0x27c3a8
window_top equ 0x286b94
window_bottom equ 0x286b90
window_right equ 0x286b98
window_left equ 0x286b9c
mirror_row equ 0x2863a0
chainstat equ 0x14003
chainplace equ 0x286b4c
ylookup equ 0x286bb0
plane_bits equ 0x14029
frameplace equ 0x286b74
getangle equ 0x4c94c
preparemirror_restore equ 0x52c82

preparemirror_:
    push esi
    push edi
    push ebp
    sub esp, 0xc
    push eax
    push edx
    push ebx
    push ecx
    movsx eax, word [esp + 0x30]
    shl eax, 5
    mov ecx, dword [eax + wall_x]
    movsx edi, word [eax + wall_point2]
    mov eax, dword [eax + wall_y]
    shl edi, 5
    mov dword [esp + 0x14], eax
    mov esi, dword [edi + wall_x]
    mov edi, dword [edi + wall_y]
    sub esi, ecx
    sub edi, eax
    mov eax, esi
    imul eax, esi
    mov ebp, edi
    imul ebp, edi
    mov dword [esp + 0x18], esi
    add ebp, eax
    je near .discard_saved_arguments
    mov esi, dword [esp + 0xc]
    mov eax, dword [esp + 0x18]
    sub esi, ecx
    imul esi, eax
    mov eax, edx
    sub eax, dword [esp + 0x14]
    imul eax, edi
    add ecx, ecx
    mov dword [esp + 0x10], ecx
    add esi, eax
    mov ecx, ebp
    add esi, esi
    mov eax, dword [esp + 0x18]
    mov ebx, esi
    imul ebx
    idiv ecx
    mov ebx, dword [esp + 0x10]
    mov ecx, dword [esp + 0xc]
    add eax, ebx
    sub eax, ecx
    mov ecx, dword [esp + 0x38]
    mov ebx, esi
    mov dword [ecx], eax
    mov eax, dword [esp + 0x14]
    mov ecx, ebp
    add eax, eax
    mov ebp, dword [esp + 8]
    mov dword [esp + 0x10], eax
    mov eax, edi
    mov esi, dword [esp + 0x10]
    imul ebx
    idiv ecx
    add eax, esi
    mov ecx, dword [esp + 0x3c]
    sub eax, ebp
    mov edx, edi
    mov dword [ecx], eax
    mov eax, dword [esp + 0x18]
    call getangle
    mov edx, dword [esp]
    add eax, eax
    sub eax, edx
    mov ecx, dword [esp + 0x40]
    and ah, 7
    mov word [ecx], ax
    mov eax, dword [esp + 4]
    mov dword [mirror_z], eax
    mov eax, dword [esp + 0x34]
    mov word [mirror_sector], ax
    cwde
    mov esi, eax
    shl esi, 2
    add esi, eax
    shl esi, 3
    mov eax, dword [esp + 4]
    cmp eax, dword [esi + sector_ceilingz]
    jle near .discard_saved_arguments
    cmp eax, dword [esi + sector_floorz]
    jge near .discard_saved_arguments
    mov eax, dword [esp + 0x2c]
    mov ebp, dword [window_top]
    mov ecx, dword [window_bottom]
    mov ebx, dword [window_right]
    mov edi, dword [window_left]
    sub eax, 0x64
    add ebp, ecx
    sub ebx, edi
    mov ecx, 0x140
    sar ebp, 1
    imul ebx
    idiv ecx
    add eax, ebp
    mov ecx, dword [esi + sector_ceilingz]
    mov dword [mirror_row], eax
    mov ebp, dword [esi + sector_floorz]
    mov eax, dword [esp + 4]
    add ecx, ebp
    add eax, eax
    cmp eax, ecx
    jle short .move_marker_down
    dec dword [mirror_row]
    jmp short .clamp_marker_to_view

.move_marker_down:
    inc dword [mirror_row]

.clamp_marker_to_view:
    mov eax, dword [mirror_row]
    mov ebx, dword [window_top]
    cmp eax, ebx
    jg short .branch_178
    mov eax, ebx

.branch_178:
    mov ecx, dword [window_bottom]
    cmp eax, ecx
    jge short .check_bottom
    mov eax, dword [mirror_row]
    mov esi, dword [window_top]
    cmp eax, esi
    jle short .branch_195
    mov ecx, eax
    jmp short .check_bottom

.branch_195:
    mov ecx, esi

.check_bottom:
    mov ah, byte [chainstat]
    mov dword [mirror_row], ecx

.fill_marker_row:
    test ah, ah
    je near .fill_linear_marker
    mov eax, 2
    mov edx, 0x3c4
    out dx, al
    mov ebp, dword [mirror_row]
    mov eax, dword [chainplace]
    mov ebp, dword [ebp*4 + ylookup]
    mov ecx, dword [window_left]
    add ebp, eax
    mov eax, dword [window_right]
    add ecx, 4
    inc eax
    cmp ecx, eax
    jge short .branch_1df
    mov eax, ecx

.branch_1df:
    lea esi, [eax - 1]
    jmp short .check_plane_column

.select_plane:
    mov eax, esi
    and eax, 3
    mov al, byte [eax + plane_bits]
    mov edx, 0x3c5
    and eax, 0xff
    out dx, al
    mov edi, esi
    mov ecx, dword [window_right]
    mov eax, 0xffffffff
    add ecx, 4
    sar edi, 2
    sub ecx, esi
    add edi, ebp
    sar ecx, 2
    cmp ecx, 4
    jae short .branch_226
    test cl, 1
    je short .branch_21f
    stosb

.branch_21f:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .branch_251

.branch_226:
    test edi, 1
    je short .branch_230
    stosb
    dec ecx

.branch_230:
    test edi, 2
    je short .branch_23d
    stosw
    sub ecx, 2

.branch_23d:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_24b
    stosw

.branch_24b:
    test bl, 1
    je short .branch_251
    stosb

.branch_251:
    dec esi

.check_plane_column:
    cmp esi, dword [window_left]
    jge short .select_plane
    jmp short .discard_saved_arguments

.fill_linear_marker:
    mov eax, dword [window_right]
    mov edi, dword [window_left]
    sub eax, edi
    lea esi, [eax + 1]
    mov ebp, dword [ecx*4 + ylookup]
    mov eax, dword [frameplace]
    add eax, ebp
    mov ecx, esi
    add edi, eax
    mov eax, 0xffffffff
    cmp ecx, 4
    jae short .branch_295
    test cl, 1
    je short .branch_28e
    stosb

.branch_28e:
    shr ecx, 1
    db 0xf3                       ; REP precedes the operand-size prefix
    stosw
    jmp short .discard_saved_arguments

.branch_295:
    test edi, 1
    je short .branch_29f
    stosb
    dec ecx

.branch_29f:
    test edi, 2
    je short .branch_2ac
    stosw
    sub ecx, 2

.branch_2ac:
    mov ebx, ecx
    shr ecx, 2
    rep stosd
    test bl, 2
    je short .branch_2ba
    stosw

.branch_2ba:
    test bl, 1
    je short .discard_saved_arguments
    stosb

.discard_saved_arguments:
    add esp, 0x1c
    jmp near preparemirror_restore
