; Update level effects.
BITS 32
ORG 0x40662

frame_state_1634 equ 0x1634
frame_state_1651 equ 0x1651
frame_state_1675 equ 0x1675
report_error equ 0x26a03
get_animation_goal equ 0x2efa1
restore_crusher_registers equ 0x40261
check_crushed_player equ 0x4038a
check_crushed_sprites equ 0x40434
play_crusher_sound equ 0x404d6
activate_crush_sector equ 0x40849
crusher_state equ 0x174640
sectors equ 0x27c3a0
ceil_base equ 0x27c3a4
engine_27c3bc equ 0x27c3bc
numsectors equ 0x289154

update_level_effects:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push eax
    test eax, eax
    jl short .branch_40672
    cmp eax, 0x19
    jl short .branch_4067c

.branch_40672:
    mov eax, frame_state_1634
    call report_error

.branch_4067c:
    mov edx, [esp]
    mov eax, edx
    shl eax, byte 0x7
    add eax, edx
    mov esi, crusher_state
    shl eax, byte 0x3
    add esi, eax
    cmp dword [esi], 0x0
    jnz short .branch_4069f
    mov eax, frame_state_1651
    call report_error

.branch_4069f:
    xor ecx, ecx
    jmp near .branch_4080c

.branch_406a6:
    mov eax, ecx
    lea ebx, [esi + 0x8]
    shl eax, byte 0x6
    add ebx, eax
    mov di, [ebx]
    test di, di
    jl short .branch_406c1
    cmp di, [numsectors]
    jl short .branch_406cb

.branch_406c1:
    mov eax, frame_state_1675
    call report_error

.branch_406cb:
    cmp dword [ebx + 0x15], 0x1
    jnz near .branch_4080b
    movsx ebp, di
    mov eax, ebp
    shl eax, byte 0x2
    add eax, ebp
    mov eax, [nosplit eax*8 + ceil_base]
    mov edx, [ebx + 0xa]
    mov [ebx + 0x2], eax
    cmp eax, edx
    jng near .branch_4077b
    mov eax, [ebx + 0x6]
    mov ebp, [ebx + 0x2]
    sub eax, strict dword 0x400
    cmp eax, ebp
    jz near .branch_4077b
    mov eax, ebp
    sub eax, [ebx + 0xe]
    test eax, eax
    jns short .branch_40712
    neg eax

.branch_40712:
    cmp eax, [ebx + 0x1d]
    jl short .branch_4074d
    mov eax, [ebx + 0xe]
    cmp eax, [ebx + 0x2]
    jng short .branch_40733
    mov dl, [ebx + 0x13]
    dec dl
    mov [ebx + 0x13], dl
    mov dh, [ebx + 0x14]
    cmp dl, dh
    jnl short .branch_40747
    mov [ebx + 0x13], dh
    jmp short .branch_40747

.branch_40733:
    mov ah, [ebx + 0x13]
    inc ah
    mov [ebx + 0x13], ah
    movsx eax, ah
    cmp eax, 0x20
    jng short .branch_40747
    mov byte [ebx + 0x13], 0x20

.branch_40747:
    mov eax, [ebx + 0x2]
    mov [ebx + 0xe], eax

.branch_4074d:
    movsx ebp, di
    mov eax, ebp
    shl eax, byte 0x2
    add eax, ebp
    mov dl, [ebx + 0x13]
    mov [nosplit eax*8 + engine_27c3bc], dl
    mov eax, [ebx + 0x19]
    cmp eax, 0x2
    jnz short .branch_4077b
    mov edx, ebp
    mov eax, ebx
    call check_crushed_player
    mov edx, ebp
    mov eax, ebx
    call check_crushed_sprites

.branch_4077b:
    movsx edi, di
    mov eax, edi
    shl eax, byte 0x2
    add eax, edi
    shl eax, byte 0x3
    add eax, sectors
    add eax, 0x4
    call get_animation_goal
    test eax, eax
    jnl near .branch_4080b
    mov eax, [ebx + 0x19]
    mov dword [ebx + 0x15], 0x0
    cmp eax, 0x2
    jnz short .branch_407c9
    mov edx, edi
    mov eax, ebx
    call check_crushed_player
    mov edx, edi
    mov eax, ebx
    call check_crushed_sprites
    mov eax, [ebx + 0x6]
    sub eax, strict dword 0x400
    mov [ebx + 0x2], eax

.branch_407c9:
    mov eax, ebx
    xor edx, edx
    mov dword [ebx + 0x19], 0x0
    call play_crusher_sound
    mov edx, [ebx + 0x31]
    cmp edx, 0x1
    jnz short .branch_407eb
    cmp edx, [ebx + 0x35]
    jnz short .branch_407eb
    mov [ebx + 0x39], edx
    jmp short .branch_4080b

.branch_407eb:
    mov ebp, [ebx + 0x31]
    cmp ebp, 0x1
    jnz short .branch_4080b
    cmp dword [ebx + 0x35], 0x0
    jnz short .branch_4080b
    mov eax, [ebx + 0x6]
    mov edx, [ebx + 0x2]
    sub eax, strict dword 0x400
    cmp eax, edx
    jnz short .branch_4080b
    mov [ebx + 0x39], ebp

.branch_4080b:
    inc ecx

.branch_4080c:
    cmp ecx, [esi + 0x4]
    jl near .branch_406a6
    xor ecx, ecx
    jmp short .branch_4083c

.branch_40819:
    mov eax, ecx
    lea ebx, [esi + 0x8]
    shl eax, byte 0x6
    add ebx, eax
    cmp dword [ebx + 0x39], 0x1
    jnz short .branch_4083b
    mov eax, [esp]
    movsx edx, word [ebx]
    call activate_crush_sector
    mov dword [ebx + 0x39], 0x0

.branch_4083b:
    inc ecx

.branch_4083c:
    cmp ecx, [esi + 0x4]
    jl short .branch_40819
    add esp, 0x4
    jmp near restore_crusher_registers
