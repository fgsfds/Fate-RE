; Check crushed player.
BITS 32
ORG 0x4038a

frame_state_145c equ 0x145c
frame_state_1481 equ 0x1481
adjust_status_value equ 0x1092e
report_error equ 0x26a03
player_sector equ 0x5acfc
player_horizon equ 0x62f8c
ceil_base equ 0x27c3a4
floor_base equ 0x27c3a8
numsectors equ 0x289154

check_crushed_player:
    push ebx
    push ecx
    push esi
    push edi
    mov ebx, eax
    test dx, dx
    jl short .branch_4039e
    cmp dx, [numsectors]
    jl short .branch_403a8

.branch_4039e:
    mov eax, frame_state_145c
    call report_error

.branch_403a8:
    test ebx, ebx
    jnz short .branch_403b6
    mov eax, frame_state_1481
    call report_error

.branch_403b6:
    mov si, [player_sector]
    cmp dx, si
    jnz short .branch_4042f
    movsx ecx, si
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    movsx ecx, dx
    mov esi, [nosplit eax*8 + floor_base]
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    sub esi, strict dword 0x4000
    cmp esi, [nosplit eax*8 + ceil_base]
    jnl short .branch_4042f
    cmp dword [player_horizon], 0x64
    jng short .branch_403ff
    mov dword [player_horizon], 0x64

.branch_403ff:
    mov eax, [ebx + 0x21]
    sar eax, 1
    mov edi, [player_horizon]
    add eax, 0x8
    sub edi, eax
    mov [player_horizon], edi
    test edi, edi
    jnl short .branch_40420
    xor eax, eax
    mov [player_horizon], eax

.branch_40420:
    mov ax, [ebx + 0x21]
    shl eax, byte 0x4
    neg eax
    cwde
    call adjust_status_value

.branch_4042f:
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
