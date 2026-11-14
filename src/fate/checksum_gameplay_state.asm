; Compute a 16-bit synchronization checksum of the current game state.
BITS 32
ORG 0x33c3f

player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
player_horizon equ 0x62f8c
player_angle equ 0x6308c
status_right_tenths equ 0x6319c
checksum_table equ 0x18f778
next_player equ 0x18fd78
first_player equ 0x19028a
next_sprite_stat equ 0x1fbca0
sprite equ 0x2040a0
random_seed equ 0x287e78
hit_sprite_list_head equ 0x28811c

checksum_gameplay_state:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov eax, [random_seed]
    and eax, strict dword 0xff
    mov ebx, [random_seed]
    xor edx, edx
    mov ax, [nosplit eax*4 + checksum_table]
    sar ebx, byte 0x8
    mov dx, ax
    and ebx, strict dword 0xff
    sar edx, byte 0x8
    xor edx, ebx
    shl eax, byte 0x8
    mov bx, [nosplit edx*4 + checksum_table]
    movsx edi, word [first_player]
    xor eax, ebx
    jmp near .check_player

.checksum_player:
    mov edx, edi
    xor ebx, ebx
    shl edx, byte 0x2
    mov bx, ax
    mov ecx, [edx + player_x]
    sar ebx, byte 0x8
    and ecx, strict dword 0xff
    xor ebx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit ebx*4 + checksum_table]
    xor ebx, ebx
    mov ecx, [edx + player_x]
    mov bx, ax
    sar ecx, byte 0x8
    sar ebx, byte 0x8
    and ecx, strict dword 0xff
    xor ebx, ecx
    shl eax, byte 0x8
    mov si, [nosplit ebx*4 + checksum_table]
    mov ecx, [edx + player_x]
    xor eax, esi
    xor ebx, ebx
    sar ecx, byte 0x10
    mov bx, ax
    and ecx, strict dword 0xff
    sar ebx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit ebx*4 + checksum_table]
    xor ebx, ebx
    mov ecx, [edx + player_x]
    mov bx, ax
    sar ecx, byte 0x18
    sar ebx, byte 0x8
    and ecx, strict dword 0xff
    xor ebx, ecx
    shl eax, byte 0x8
    mov si, [nosplit ebx*4 + checksum_table]
    xor ecx, ecx
    xor eax, esi
    mov ebx, [edx + player_y]
    mov cx, ax
    and ebx, strict dword 0xff
    sar ecx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    mov cx, [nosplit ebx*4 + checksum_table]
    mov ebx, [edx + player_y]
    xor eax, ecx
    xor ecx, ecx
    sar ebx, byte 0x8
    mov cx, ax
    and ebx, strict dword 0xff
    sar ecx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    mov si, [nosplit ebx*4 + checksum_table]
    mov ecx, [edx + player_y]
    xor eax, esi
    xor ebx, ebx
    sar ecx, byte 0x10
    mov bx, ax
    and ecx, strict dword 0xff
    sar ebx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit ebx*4 + checksum_table]
    xor ebx, ebx
    mov ecx, [edx + player_y]
    mov bx, ax
    sar ecx, byte 0x18
    sar ebx, byte 0x8
    and ecx, strict dword 0xff
    xor ebx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit ebx*4 + checksum_table]
    xor ebx, ebx
    mov ecx, [edx + player_z]
    mov bx, ax
    and ecx, strict dword 0xff
    sar ebx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit ebx*4 + checksum_table]
    mov ecx, [edx + player_z]
    xor ebx, ebx
    sar ecx, byte 0x8
    mov bx, ax
    and ecx, strict dword 0xff
    sar ebx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    mov si, [nosplit ebx*4 + checksum_table]
    mov ecx, [edx + player_z]
    xor eax, esi
    xor ebx, ebx
    sar ecx, byte 0x10
    mov bx, ax
    and ecx, strict dword 0xff
    sar ebx, byte 0x8
    xor ebx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit ebx*4 + checksum_table]
    xor ebx, ebx
    mov ecx, [edx + player_z]
    mov bx, ax
    sar ecx, byte 0x18
    sar ebx, byte 0x8
    and ecx, strict dword 0xff
    xor ebx, ecx
    mov si, [nosplit ebx*4 + checksum_table]
    lea ebx, [edi + edi]
    mov cx, [ebx + player_angle]
    shl eax, byte 0x8
    xor ch, ch
    xor eax, esi
    movsx esi, cx
    xor ecx, ecx
    mov cx, ax
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    mov di, [nosplit ecx*4 + checksum_table]
    xor esi, esi
    movsx ecx, word [ebx + player_angle]
    xor eax, edi
    sar ecx, byte 0x8
    mov si, ax
    and ecx, strict dword 0xff
    sar esi, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + player_horizon]
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    mov di, [nosplit ecx*4 + checksum_table]
    mov esi, [edx + player_horizon]
    xor eax, edi
    xor ecx, ecx
    sar esi, byte 0x8
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    mov si, [nosplit ecx*4 + checksum_table]
    mov ecx, [edx + player_horizon]
    xor eax, esi
    xor esi, esi
    sar ecx, byte 0x10
    mov si, ax
    and ecx, strict dword 0xff
    sar esi, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    mov di, [nosplit ecx*4 + checksum_table]
    mov esi, [edx + player_horizon]
    xor eax, edi
    xor ecx, ecx
    sar esi, byte 0x18
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + status_right_tenths]
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    mov di, [nosplit ecx*4 + checksum_table]
    mov esi, [edx + status_right_tenths]
    xor eax, edi
    xor ecx, ecx
    sar esi, byte 0x8
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + status_right_tenths]
    mov cx, ax
    sar esi, byte 0x10
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    mov di, [nosplit ecx*4 + checksum_table]
    mov ecx, [edx + status_right_tenths]
    xor eax, edi
    xor edx, edx
    sar ecx, byte 0x18
    mov dx, ax
    and ecx, strict dword 0xff
    sar edx, byte 0x8
    xor edx, ecx
    mov cx, [nosplit edx*4 + checksum_table]
    mov dx, [ebx + player_sector]
    shl eax, byte 0x8
    xor dh, dh
    xor eax, ecx
    movsx ecx, dx
    xor edx, edx
    mov dx, ax
    sar edx, byte 0x8
    xor edx, ecx
    shl eax, byte 0x8
    mov si, [nosplit edx*4 + checksum_table]
    movsx ecx, word [ebx + player_sector]
    xor eax, esi
    xor edx, edx
    sar ecx, byte 0x8
    mov dx, ax
    and ecx, strict dword 0xff
    sar edx, byte 0x8
    xor edx, ecx
    shl eax, byte 0x8
    xor ax, [nosplit edx*4 + checksum_table]
    movsx edi, word [ebx + next_player]

.check_player:
    test edi, edi
    jnl near .checksum_player
    mov edi, 0x7
    jmp near .branch_341fe

.branch_34012:
    movsx ebx, word [nosplit edi*2 + hit_sprite_list_head]
    jmp near .branch_341f5

.branch_3401f:
    imul edx, ebx, 0x2c
    xor ecx, ecx
    add edx, sprite
    mov cx, ax
    mov esi, [edx]
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx]
    mov cx, ax
    sar esi, byte 0x8
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx]
    mov cx, ax
    sar esi, byte 0x10
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx]
    mov cx, ax
    sar esi, byte 0x18
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x4]
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x4]
    mov cx, ax
    sar esi, byte 0x8
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x4]
    mov cx, ax
    sar esi, byte 0x10
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x4]
    mov cx, ax
    sar esi, byte 0x18
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x8]
    mov cx, ax
    and esi, strict dword 0xff
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x8]
    mov cx, ax
    sar esi, byte 0x8
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    mov ecx, [edx + 0x8]
    xor esi, esi
    sar ecx, byte 0x10
    mov si, ax
    and ecx, strict dword 0xff
    sar esi, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    xor ax, [nosplit ecx*4 + checksum_table]
    xor ecx, ecx
    mov esi, [edx + 0x8]
    mov cx, ax
    sar esi, byte 0x18
    sar ecx, byte 0x8
    and esi, strict dword 0xff
    xor ecx, esi
    mov si, [nosplit ecx*4 + checksum_table]
    mov cx, [edx + 0x1c]
    shl eax, byte 0x8
    xor ch, ch
    xor eax, esi
    movsx esi, cx
    xor ecx, ecx
    mov cx, ax
    sar ecx, byte 0x8
    xor ecx, esi
    shl eax, byte 0x8
    mov si, [nosplit ecx*4 + checksum_table]
    movsx ecx, word [edx + 0x1c]
    xor eax, esi
    xor edx, edx
    sar ecx, byte 0x8
    mov dx, ax
    and ecx, strict dword 0xff
    sar edx, byte 0x8
    xor edx, ecx
    shl eax, byte 0x8
    mov cx, [nosplit edx*4 + checksum_table]
    movsx ebx, word [nosplit ebx*2 + next_sprite_stat]
    xor eax, ecx

.branch_341f5:
    test ebx, ebx
    jnl near .branch_3401f
    dec edi

.branch_341fe:
    test edi, edi
    jnl near .branch_34012
    and eax, strict dword 0xffff
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
