; Update board geometry, sprites, and player environment.
BITS 32
ORG 0x2a56e

board_state_538 equ 0x538
board_state_1a204 equ 0x1a204
board_state_1a214 equ 0x1a214
board_state_1a224 equ 0x1a224
board_state_1ba34 equ 0x1ba34
board_state_1ba84 equ 0x1ba84
board_state_1ba94 equ 0x1ba94
board_state_1baa4 equ 0x1baa4
board_state_1bab4 equ 0x1bab4
board_state_1babc equ 0x1babc
board_state_1bafc equ 0x1bafc
board_state_1bb3c equ 0x1bb3c
board_state_1bc7c equ 0x1bc7c
board_state_1bcbc equ 0x1bcbc
board_state_1bcfc equ 0x1bcfc
board_state_1bd0c equ 0x1bd0c
board_state_1bd1c equ 0x1bd1c
board_state_1c11c equ 0x1c11c
board_state_1c12c equ 0x1c12c
board_state_1c16c equ 0x1c16c
board_state_1c17c equ 0x1c17c
board_state_1c1fc equ 0x1c1fc
board_state_1c2fc equ 0x1c2fc
board_state_1c3fc equ 0x1c3fc
board_state_1c43c equ 0x1c43c
board_state_1c83c equ 0x1c83c
board_state_1cc3c equ 0x1cc3c
board_state_1cc44 equ 0x1cc44
board_state_1cc4c equ 0x1cc4c
board_state_1cc6c equ 0x1cc6c
board_state_1cc8c equ 0x1cc8c
board_state_1ccac equ 0x1ccac
board_state_1cd2c equ 0x1cd2c
board_state_1cdec equ 0x1cdec
board_state_1ce2c equ 0x1ce2c
board_state_1ce6c equ 0x1ce6c
board_state_1ceac equ 0x1ceac
board_state_1ceec equ 0x1ceec
board_state_1cf6c equ 0x1cf6c
board_state_1d08c equ 0x1d08c
board_state_1d10c equ 0x1d10c
dispatch_hit_event equ 0x2b369
sub_2e9ec equ 0x2e9ec
sub_2f3ce equ 0x2f3ce
sub_3452a equ 0x3452a
play_positioned_sound equ 0x34f76
classify_sector_hit equ 0x3fccb
handle_board_sector_event equ 0x4052f
sub_4c0c7 equ 0x4c0c7
set_sprite_position equ 0x506f6
dragpoint equ 0x52822
rotate_point equ 0x5437c
krand equ 0x562e5
previous_player_sector equ 0x5acdc
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
board_state_62f2c equ 0x62f2c
player_angle equ 0x6308c
actor_clock equ 0x770b8
board_state_7debc equ 0x7debc
board_state_7debe equ 0x7debe
board_state_7dec0 equ 0x7dec0
board_state_7dec2 equ 0x7dec2
board_state_7dec4 equ 0x7dec4
board_state_7dec6 equ 0x7dec6
board_state_7deca equ 0x7deca
board_state_7decc equ 0x7decc
board_state_7dece equ 0x7dece
current_board equ 0x7f87e
next_player equ 0x18fd78
first_player equ 0x19028a
next_sprite_in_sector equ 0x1f9ca0
sprite equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8
sprite_angle equ 0x2040bc
board_state_2040bd equ 0x2040bd
sintable equ 0x2300a0
walls equ 0x2310a0
engine_2310a4 equ 0x2310a4
board_state_2310b4 equ 0x2310b4
board_state_2310b8 equ 0x2310b8
board_state_2310b9 equ 0x2310b9
sectors equ 0x27c3a0
sector_wall_count equ 0x27c3a2
floor_base equ 0x27c3a8
engine_27c3b4 equ 0x27c3b4
engine_27c3bc equ 0x27c3bc
board_state_27c3be equ 0x27c3be
board_state_27c3bf equ 0x27c3bf
sector_lotag equ 0x27c3c2
sector_hitag equ 0x27c3c4
sector_sprite_head equ 0x28891e

update_board_environment:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x2c
    mov ax, [first_player]
    jmp near .check_trigger_player

; Lotag 1 clears after firing. Lotag 2 fires when the player enters.
.check_sector_triggers:
    movsx edx, dx
    add edx, edx
    movsx ebx, word [edx + player_sector]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    shl eax, byte 0x3
    movsx ebx, word [eax + sector_lotag]
    cmp ebx, 0x1
    jnz short .check_repeatable_trigger
    mov ax, [eax + sector_hitag]
    xor ah, ah
    cwde
    call dispatch_hit_event
    movsx edx, word [edx + player_sector]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    xor ebx, ebx
    xor dl, dl
    mov [nosplit eax*8 + sector_lotag], bx
    mov [nosplit eax*8 + sector_hitag], dl

.check_repeatable_trigger:
    movsx edx, word [esp + 0x24]
    add edx, edx
    movsx ebx, word [edx + player_sector]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    shl eax, byte 0x3
    movsx ebx, word [eax + sector_lotag]
    cmp ebx, 0x2
    jnz short .check_board_sector_event
    mov bx, [edx + player_sector]
    cmp bx, [edx + previous_player_sector]
    jz short .check_board_sector_event
    mov ax, [eax + sector_hitag]
    xor ah, ah
    cwde
    call dispatch_hit_event

.check_board_sector_event:
    movsx edx, word [esp + 0x24]
    add edx, edx
    mov ax, [edx + player_sector]
    cmp ax, [edx + previous_player_sector]
    jz short .advance_trigger_player
    cwde
    call classify_sector_hit
    cmp eax, 0x1
    jnz short .advance_trigger_player
    movsx eax, byte [current_board]
    movsx edx, word [edx + player_sector]
    call handle_board_sector_event

.advance_trigger_player:
    movsx eax, word [esp + 0x24]
    mov ax, [nosplit eax*2 + next_player]

.check_trigger_player:
    mov [esp + 0x24], eax
    mov edx, [esp + 0x24]
    test dx, dx
    jnl near .check_sector_triggers
    xor edi, edi
    jmp near .check_pulsing_sector

; Apply the same triangular shade cycle to both planes and the sector walls.
.update_pulsing_sector:
    mov ax, [nosplit edi*2 + board_state_1ccac]
    mov [esp + 0x18], eax
    mov eax, [actor_clock]
    and eax, 0x7f
    sar eax, byte 0x2
    mov [esp + 0xc], eax
    cmp eax, 0x10
    jl short .branch_2a6a0
    mov eax, 0x1f
    mov ebx, [esp + 0xc]
    sub eax, ebx
    mov [esp + 0xc], eax

.branch_2a6a0:
    movsx edx, word [esp + 0x18]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov dl, [esp + 0xc]
    mov [nosplit eax*8 + engine_27c3b4], dl
    mov [nosplit eax*8 + engine_27c3bc], dl
    mov dx, [nosplit eax*8 + sectors]
    mov bx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x28], edx
    add edx, ebx
    movsx esi, word [esp + 0x28]
    mov [esp + 0x1c], edx
    mov dl, [esp + 0xc]
    jmp short .branch_2a6ef

.branch_2a6e3:
    mov eax, esi
    shl eax, byte 0x5
    inc esi
    mov [eax + board_state_2310b4], dl

.branch_2a6ef:
    movsx eax, word [esp + 0x1c]
    cmp esi, eax
    jl short .branch_2a6e3
    inc edi

.check_pulsing_sector:
    movsx eax, word [board_state_7dece]
    cmp edi, eax
    jl near .update_pulsing_sector
    mov ax, [first_player]
    jmp near .check_teleport_player

; Lotag 10 relocates the player sprite on sector entry, then copies its pose.
.check_player_teleport:
    movsx ecx, cx
    lea edx, [ecx + ecx]
    movsx ebx, word [edx + player_sector]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0xa
    jnz short .advance_teleport_player
    mov ax, [edx + player_sector]
    cmp ax, [edx + previous_player_sector]
    jz short .advance_teleport_player
    movsx eax, word [edx + board_state_62f2c]
    call sub_2e9ec
    movsx eax, word [edx + board_state_62f2c]
    imul eax, eax, 0x2c
    mov ebx, ecx
    mov ecx, [eax + sprite]
    mov [nosplit ebx*4 + player_x], ecx
    mov ecx, [eax + sprite_y]
    mov [nosplit ebx*4 + player_y], ecx
    mov ecx, [eax + sprite_z]
    mov [nosplit ebx*4 + player_z], ecx
    mov bx, [eax + sprite_angle]
    add ecx, strict dword 0x2000
    mov [edx + player_angle], bx
    mov bx, [eax + sprite_sector]
    mov [eax + sprite_z], ecx
    mov [edx + player_sector], bx

.advance_teleport_player:
    movsx eax, word [esp + 0x24]
    mov ax, [nosplit eax*2 + next_player]

.check_teleport_player:
    mov [esp + 0x24], eax
    mov ecx, [esp + 0x24]
    test cx, cx
    jnl near .check_player_teleport
    xor edi, edi
    jmp short .branch_2a829

.branch_2a7cd:
    mov ax, [nosplit edi*2 + board_state_1cc8c]
    movsx edx, ax
    mov [esp + 0x18], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov dx, [nosplit eax*8 + sectors]
    mov bx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x28], edx
    add edx, ebx
    movsx esi, word [esp + 0x28]
    mov [esp + 0x1c], edx
    jmp short .branch_2a81f

.branch_2a804:
    mov eax, [actor_clock]
    sar eax, byte 0x2
    and eax, strict dword 0xff
    mov dl, al
    mov eax, esi
    shl eax, byte 0x5
    inc esi
    mov [eax + board_state_2310b8], dl

.branch_2a81f:
    movsx eax, word [esp + 0x1c]
    cmp esi, eax
    jl short .branch_2a804
    inc edi

.branch_2a829:
    movsx eax, word [board_state_7dec4]
    cmp edi, eax
    jl short .branch_2a7cd
    xor edi, edi
    jmp short .branch_2a852

.branch_2a838:
    mov dl, [actor_clock]
    movsx eax, word [nosplit edi*2 + board_state_1ceec]
    not dl
    shl eax, byte 0x5
    inc edi
    mov [eax + board_state_2310b9], dl

.branch_2a852:
    movsx eax, word [board_state_7decc]
    cmp edi, eax
    jl short .branch_2a838
    xor edi, edi
    jmp short .branch_2a884

.rotate_sprite:
    movsx eax, word [nosplit edi*2 + board_state_1cf6c]
    imul eax, eax, 0x2c
    add word [eax + sprite_angle], 0xc
    mov dh, [eax + board_state_2040bd]
    and dh, 0x7
    inc edi
    mov [eax + board_state_2040bd], dh

.branch_2a884:
    movsx eax, word [board_state_7deca]
    cmp edi, eax
    jl short .rotate_sprite
    xor edi, edi
    jmp short .branch_2a8c0

.branch_2a893:
    mov eax, [actor_clock]
    sar eax, byte 0x2
    and eax, strict dword 0xff
    movsx edx, word [nosplit edi*2 + board_state_1d08c]
    mov bl, al
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov [nosplit eax*8 + board_state_27c3be], bl
    inc edi
    mov [nosplit eax*8 + board_state_27c3bf], bl

.branch_2a8c0:
    movsx eax, word [board_state_7dec2]
    cmp edi, eax
    jl short .branch_2a893
    xor edi, edi
    jmp near .branch_2aae7

; Translate the walls and carry sprites through setsprite.
.translate_sector:
    lea edx, [edi + edi]
    mov ax, [edx + board_state_1d10c]
    movsx ebx, ax
    mov [esp + 0x18], eax
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov bx, [nosplit eax*8 + sectors]
    mov si, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x28], ebx
    add ebx, esi
    movsx eax, word [esp + 0x28]
    mov [esp + 0x1c], ebx
    shl eax, byte 0x5
    movsx ebx, word [edx + board_state_1cc4c]
    mov esi, [eax + walls]
    mov ebp, [nosplit edi*4 + board_state_1ce2c]
    add ebx, esi
    cmp ebx, ebp
    jnl short .branch_2a92f
    mov word [edx + board_state_1cc4c], 0x10

.branch_2a92f:
    movsx edx, word [esp + 0x28]
    lea eax, [edi + edi]
    shl edx, byte 0x5
    movsx ebx, word [eax + board_state_1cc6c]
    mov ecx, [edx + engine_2310a4]
    mov esi, [nosplit edi*4 + board_state_1ceac]
    add ebx, ecx
    cmp ebx, esi
    jnl short .branch_2a95d
    mov word [eax + board_state_1cc6c], 0x10

.branch_2a95d:
    movsx edx, word [esp + 0x28]
    lea eax, [edi + edi]
    shl edx, byte 0x5
    movsx ebx, word [eax + board_state_1cc4c]
    mov ebp, [edx + walls]
    mov ecx, [nosplit edi*4 + board_state_1cdec]
    add ebx, ebp
    cmp ebx, ecx
    jng short .branch_2a98b
    mov word [eax + board_state_1cc4c], 0xfff0

.branch_2a98b:
    movsx edx, word [esp + 0x28]
    lea eax, [edi + edi]
    shl edx, byte 0x5
    movsx ebx, word [eax + board_state_1cc6c]
    mov esi, [edx + engine_2310a4]
    mov ebp, [nosplit edi*4 + board_state_1ce6c]
    add ebx, esi
    cmp ebx, ebp
    jng short .branch_2a9b9
    mov word [eax + board_state_1cc6c], 0xfff0

.branch_2a9b9:
    movsx eax, word [esp + 0x28]
    mov [esp + 0xc], eax
    jmp short .branch_2a9f9

.branch_2a9c4:
    mov ebp, [esp + 0xc]
    shl edx, byte 0x5
    movsx ebx, word [nosplit edi*2 + board_state_1cc6c]
    movsx eax, word [nosplit edi*2 + board_state_1cc4c]
    mov esi, [edx + engine_2310a4]
    mov edx, [edx + walls]
    add ebx, esi
    add edx, eax
    mov eax, [esp + 0xc]
    inc ebp
    call dragpoint
    mov [esp + 0xc], ebp

.branch_2a9f9:
    movsx eax, word [esp + 0x1c]
    mov edx, [esp + 0xc]
    cmp eax, edx
    jg short .branch_2a9c4
    movsx edx, word [esp + 0x18]
    mov eax, edx
    shl eax, byte 0x2
    add edx, eax
    mov eax, [actor_clock]
    shl eax, byte 0x4
    and eax, strict dword 0x7ff
    mov ecx, [nosplit edi*4 + board_state_1cd2c]
    movsx ebx, word [nosplit eax*2 + sintable]
    shl edx, byte 0x3
    sar ebx, byte 0x3
    mov ax, [first_player]
    add ebx, ecx
    mov [esp + 0x24], eax
    mov [edx + floor_base], ebx
    jmp near .branch_2aad9

.branch_2aa4b:
    movsx eax, si
    lea esi, [eax + eax]
    mov ebx, [esp + 0x18]
    cmp bx, [esi + player_sector]
    jnz short .branch_2aac8
    movsx ebx, word [nosplit edi*2 + board_state_1cc4c]
    movsx edx, word [nosplit edi*2 + board_state_1cc6c]
    mov ebp, [nosplit eax*4 + player_y]
    mov ecx, [nosplit eax*4 + player_x]
    add ebp, edx
    add ecx, ebx
    mov ebx, ebp
    mov [nosplit eax*4 + player_x], ecx
    mov [nosplit eax*4 + player_y], ebp
    mov ecx, [nosplit eax*4 + player_z]
    mov edx, [nosplit eax*4 + player_x]
    add ecx, strict dword 0x2000
    movsx eax, word [esi + board_state_62f2c]
    call set_sprite_position
    movsx eax, word [esi + board_state_62f2c]
    imul eax, eax, 0x2c
    mov dx, [esi + player_angle]
    mov [eax + sprite_angle], dx

.branch_2aac8:
    movsx eax, word [esp + 0x24]
    mov ax, [nosplit eax*2 + next_player]
    mov [esp + 0x24], eax

.branch_2aad9:
    mov esi, [esp + 0x24]
    test si, si
    jnl near .branch_2aa4b
    inc edi

.branch_2aae7:
    movsx eax, word [board_state_7dec6]
    cmp edi, eax
    jl near .translate_sector
    xor edi, edi
    jmp near .branch_2ae66

.branch_2aafd:
    lea eax, [edi + edi]
    cmp word [eax + board_state_1bafc], 0x0
    jz near .branch_2ae04
    mov ax, [eax + board_state_1c12c]
    mov [esp + 0x20], eax
    xor eax, eax
    mov [esp + 0xc], eax
    jmp near .branch_2abab

.branch_2ab24:
    lea esi, [edi + edi]
    mov ax, [esi + board_state_1c12c]
    add ax, [esi + board_state_1bafc]
    and ah, 0x7
    mov bx, [esi + board_state_1bcbc]
    mov [esi + board_state_1c12c], ax
    cmp ax, bx
    jnz short .branch_2ab88
    mov ecx, edi
    mov eax, board_state_1c83c
    shl ecx, byte 0x5
    push strict byte 0x0
    add eax, ecx
    push eax
    call krand
    and eax, strict dword 0x1ff
    mov ebx, 0x100
    lea edx, [eax + 0xf00]
    add ecx, board_state_1c43c
    mov eax, board_state_538
    call play_positioned_sound
    xor ecx, ecx
    mov [esi + board_state_1bafc], cx

.branch_2ab88:
    lea eax, [edi + edi]
    mov dx, [eax + board_state_1c12c]
    mov si, [eax + board_state_1babc]
    cmp dx, si
    jnz short .branch_2aba7
    xor edx, esi
    mov [eax + board_state_1bafc], dx

.branch_2aba7:
    inc dword [esp + 0xc]

.branch_2abab:
    cmp dword [esp + 0xc], 0xc
    jl near .branch_2ab24
    mov esi, 0x1
    jmp short .branch_2ac0d

.branch_2abbd:
    mov eax, edi
    shl eax, byte 0x2
    lea ebx, [edi + eax]
    mov eax, esi
    add ebx, ebx
    movsx eax, word [ebx + eax*2 + board_state_1bb3c]
    shl eax, byte 0x5
    add eax, walls
    lea ebx, [eax + 0x4]
    push ebx
    push eax
    movsx eax, word [edx + board_state_1c12c]
    push eax
    mov eax, edi
    mov edx, esi
    shl eax, byte 0x5
    mov ecx, [eax + edx*4 + board_state_1c83c]
    mov ebx, [eax + edx*4 + board_state_1c43c]
    mov edx, [eax + board_state_1c83c]
    mov eax, [eax + board_state_1c43c]
    inc esi
    call rotate_point

.branch_2ac0d:
    lea edx, [edi + edi]
    cmp esi, 0x3
    jng short .branch_2abbd
    cmp word [edx + board_state_1bafc], 0x0
    jz near .branch_2ae04
    mov ax, [first_player]
    jmp near .branch_2adf3

.branch_2ac2e:
    movsx eax, si
    lea edx, [edi + edi]
    add eax, eax
    mov cx, [edx + board_state_1bc7c]
    mov bx, [eax + player_sector]
    cmp bx, cx
    jz short .branch_2ac5d
    movsx edx, cx
    movsx eax, bx
    call sub_2f3ce
    cmp eax, 0x1
    jnz near .branch_2ade6

.branch_2ac5d:
    mov dword [esp + 0x14], 0x100

.branch_2ac65:
    mov dword [esp + 0x10], 0x1
    cmp word [nosplit edi*2 + board_state_1c3fc], 0x0
    setg al
    movzx esi, al
    mov ebp, esi
    add esi, 0x3
    jmp short .branch_2acbf

.branch_2ac83:
    mov eax, edi
    shl eax, byte 0x2
    lea ebx, [esi + esi]
    add eax, edi
    movsx ebx, word [ebx + eax*2 + board_state_1bb3c]
    movsx eax, word [esp + 0x24]
    mov ecx, 0x80
    mov edx, [nosplit eax*4 + player_y]
    mov eax, [nosplit eax*4 + player_x]
    call sub_4c0c7
    test eax, eax
    jz short .branch_2acbe
    xor ebp, ebp
    mov [esp + 0x10], ebp
    jmp short .branch_2acc3

.branch_2acbe:
    dec esi

.branch_2acbf:
    cmp esi, ebp
    jnl short .branch_2ac83

.branch_2acc3:
    cmp dword [esp + 0x10], 0x0
    jnz near .branch_2add4
    mov edx, [esp + 0x14]
    lea eax, [edi + edi]
    cmp edx, strict dword 0x100
    jnz short .branch_2acf3
    mov dx, [eax + board_state_1bafc]
    neg edx
    mov [eax + board_state_1bafc], dx
    mov edx, [esp + 0x20]
    jmp short .branch_2ad04

.branch_2acf3:
    mov dx, [eax + board_state_1c12c]
    sub dx, [eax + board_state_1bafc]
    and dh, 0x7

.branch_2ad04:
    mov [eax + board_state_1c12c], dx
    mov esi, 0x1
    jmp short .branch_2ad61

.branch_2ad12:
    mov eax, edi
    shl eax, byte 0x2
    lea ebx, [edi + eax]
    mov eax, esi
    add ebx, ebx
    movsx eax, word [ebx + eax*2 + board_state_1bb3c]
    shl eax, byte 0x5
    add eax, walls
    lea ebx, [eax + 0x4]
    push ebx
    push eax
    movsx eax, word [ebp + board_state_1c12c]
    push eax
    mov eax, esi
    mov ecx, [edx + eax*4 + board_state_1c83c]
    mov ebx, [edx + eax*4 + board_state_1c43c]
    mov eax, [edx + board_state_1c83c]
    mov ebp, [edx + board_state_1c43c]
    mov edx, eax
    mov eax, ebp
    inc esi
    call rotate_point

.branch_2ad61:
    mov edx, edi
    shl edx, byte 0x5
    lea ebp, [edi + edi]
    cmp esi, 0x3
    jng short .branch_2ad12
    mov ax, [ebp + board_state_1c12c]
    cmp ax, [ebp + board_state_1bcbc]
    jnz short .branch_2adb9
    mov eax, board_state_1c83c
    push strict byte 0x0
    add eax, edx
    push eax
    mov ecx, board_state_1c43c
    call krand
    and eax, strict dword 0x1ff
    add ecx, edx
    lea edx, [eax + 0xf00]
    mov ebx, 0x100
    mov eax, board_state_538
    call play_positioned_sound
    xor edx, edx
    mov [ebp + board_state_1bafc], dx
    jmp short .branch_2ade6

.branch_2adb9:
    mov si, [ebp + board_state_1babc]
    cmp ax, si
    jnz short .branch_2add0
    xor eax, esi
    mov [ebp + board_state_1bafc], ax
    jmp short .branch_2ade6

.branch_2add0:
    dec dword [esp + 0x14]

.branch_2add4:
    cmp dword [esp + 0x10], 0x0
    jnz short .branch_2ade6
    cmp dword [esp + 0x14], 0x0
    jg near .branch_2ac65

.branch_2ade6:
    movsx eax, word [esp + 0x24]
    mov ax, [nosplit eax*2 + next_player]

.branch_2adf3:
    mov [esp + 0x24], eax
    mov esi, [esp + 0x24]
    test si, si
    jnl near .branch_2ac2e

.branch_2ae04:
    cmp word [nosplit edi*2 + board_state_1bafc], 0x0
    jnz short .branch_2ae65
    mov dword [esp + 0xc], 0x1
    jmp short .branch_2ae5e

.branch_2ae19:
    mov eax, edi
    shl eax, byte 0x2
    mov edx, [esp + 0xc]
    add eax, edi
    add edx, edx
    add eax, eax
    add edx, eax
    movsx eax, word [edx + board_state_1bb3c]
    shl eax, byte 0x5
    add eax, walls
    call sub_3452a
    movsx eax, word [edx + board_state_1bb3c]
    shl eax, byte 0x5
    add eax, walls
    mov edx, [esp + 0xc]
    add eax, 0x4
    inc edx
    call sub_3452a
    mov [esp + 0xc], edx

.branch_2ae5e:
    cmp dword [esp + 0xc], 0x3
    jng short .branch_2ae19

.branch_2ae65:
    inc edi

.branch_2ae66:
    movsx eax, word [board_state_7debe]
    cmp edi, eax
    jl near .branch_2aafd
    xor edi, edi
    jmp near .check_rotating_sector

; Rotate the stored wall positions around the sector pivot.
.rotate_sector:
    movsx ebx, word [nosplit edi*2 + board_state_1bab4]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov bx, [nosplit eax*8 + sectors]
    mov cx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x28], ebx
    mov ax, [nosplit edi*2 + board_state_1cc44]
    movsx esi, word [esp + 0x28]
    sub eax, 0xc
    add ebx, ecx
    and ah, 0x7
    mov [esp + 0x1c], ebx
    mov [nosplit edi*2 + board_state_1cc44], ax
    jmp short .branch_2af13

.rotate_sector_wall:
    mov eax, esp
    push eax
    lea eax, [esp + 0x8]
    push eax
    movsx eax, word [nosplit edi*2 + board_state_1cc44]
    mov edx, esi
    push eax
    movsx eax, word [esp + 0x34]
    sub edx, eax
    mov eax, edx
    mov edx, edi
    shl edx, byte 0x6
    mov ecx, [edx + eax*4 + board_state_1c1fc]
    mov ebx, [edx + eax*4 + board_state_1c2fc]
    mov edx, [nosplit edi*4 + board_state_1ba94]
    mov eax, [nosplit edi*4 + board_state_1baa4]
    call rotate_point
    mov ebx, [esp]
    mov edx, [esp + 0x4]
    mov eax, esi
    call dragpoint
    inc esi

.branch_2af13:
    movsx eax, word [esp + 0x1c]
    cmp esi, eax
    jl short .rotate_sector_wall
    inc edi

.check_rotating_sector:
    movsx eax, word [board_state_7dec0]
    cmp edi, eax
    jl near .rotate_sector
    xor edi, edi
    jmp near .branch_2b350

.branch_2af33:
    mov eax, edi
    shl eax, byte 0x2
    mov ecx, [eax + board_state_1a204]
    cmp ecx, 0xfffffffffffffffe
    jl short .branch_2af4c
    cmp ecx, 0x2
    jng near .branch_2b1b5

.branch_2af4c:
    mov eax, edi
    shl eax, byte 0x8
    mov ax, [eax + board_state_1bd1c]
    movsx edx, ax
    mov [esp + 0x18], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov dx, [nosplit eax*8 + sectors]
    mov si, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x28], edx
    add edx, esi
    movsx esi, word [esp + 0x28]
    mov [esp + 0x1c], edx
    jmp short .branch_2afd6

.branch_2af87:
    mov eax, esi
    mov edx, edi
    shl eax, byte 0x5
    shl edx, byte 0x2
    mov ebx, [eax + walls]
    cmp ebx, [edx + board_state_1bd0c]
    jng short .branch_2afd5
    mov ebx, [eax + engine_2310a4]
    cmp ebx, [edx + board_state_1c11c]
    jng short .branch_2afd5
    mov ebx, [eax + walls]
    cmp ebx, [edx + board_state_1bcfc]
    jnl short .branch_2afd5
    mov ebx, [eax + engine_2310a4]
    cmp ebx, [edx + board_state_1a214]
    jnl short .branch_2afd5
    mov edx, [edx + board_state_1a204]
    add [eax + walls], edx

.branch_2afd5:
    inc esi

.branch_2afd6:
    movsx eax, word [esp + 0x1c]
    cmp esi, eax
    jl short .branch_2af87
    mov dword [esp + 0xc], 0x1
    jmp near .branch_2b085

.branch_2afec:
    mov eax, edi
    mov edx, ecx
    shl eax, byte 0x8
    mov ax, [eax + edx*2 + board_state_1bd1c]
    movsx edx, ax
    mov [esp + 0x18], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov dx, [nosplit eax*8 + sectors]
    mov bx, [nosplit eax*8 + sector_wall_count]
    mov [esp + 0x28], edx
    add edx, ebx
    movsx esi, word [esp + 0x28]
    mov [esp + 0x1c], edx
    jmp short .branch_2b045

.branch_2b02a:
    mov eax, esi
    shl eax, byte 0x5
    mov edx, [nosplit edi*4 + board_state_1a204]
    mov ecx, [eax + walls]
    add ecx, edx
    inc esi
    mov [eax + walls], ecx

.branch_2b045:
    movsx eax, word [esp + 0x1c]
    cmp esi, eax
    jl short .branch_2b02a
    movsx esi, word [esp + 0x18]
    movsx esi, word [nosplit esi*2 + sector_sprite_head]
    jmp short .branch_2b07d

.branch_2b05d:
    imul eax, esi, 0x2c
    mov edx, [nosplit edi*4 + board_state_1a204]
    mov ebp, [eax + sprite]
    add ebp, edx
    movsx esi, word [nosplit esi*2 + next_sprite_in_sector]
    mov [eax + sprite], ebp

.branch_2b07d:
    test esi, esi
    jnl short .branch_2b05d
    inc dword [esp + 0xc]

.branch_2b085:
    mov ecx, [esp + 0xc]
    movsx eax, word [nosplit edi*2 + board_state_1cc3c]
    cmp eax, ecx
    jg near .branch_2afec
    mov ax, [first_player]
    jmp near .branch_2b193

.branch_2b0a4:
    movsx ecx, cx
    lea esi, [ecx + ecx]
    mov ebx, edi
    mov ax, [esi + player_sector]
    shl ebx, byte 0x8
    cmp ax, [ebx + board_state_1bd1c]
    jz near .branch_2b186
    cwde
    mov [esp + 0x8], eax
    mov ebp, [esp + 0x8]
    shl eax, byte 0x2
    movsx ebx, word [ebx + board_state_1bd1c]
    add ebp, eax
    mov eax, ebx
    shl eax, byte 0x2
    shl ebp, byte 0x3
    add eax, ebx
    mov ebx, [ebp + floor_base]
    cmp ebx, [nosplit eax*8 + floor_base]
    jz near .branch_2b186
    mov eax, ecx
    shl eax, byte 0x2
    mov ecx, [edx + board_state_1bd0c]
    cmp ecx, [eax + player_x]
    jnl near .branch_2b186
    mov ebx, [eax + player_y]
    cmp ebx, [edx + board_state_1c11c]
    jng short .branch_2b186
    mov ebx, [eax + player_x]
    cmp ebx, [edx + board_state_1bcfc]
    jnl short .branch_2b186
    mov ebx, [eax + player_y]
    cmp ebx, [edx + board_state_1a214]
    jnl short .branch_2b186
    mov edx, [edx + board_state_1a204]
    mov ebx, [eax + player_x]
    mov ecx, [eax + player_z]
    add ebx, edx
    add ecx, strict dword 0x2000
    mov [eax + player_x], ebx
    mov ebx, [eax + player_y]
    mov edx, [eax + player_x]
    movsx eax, word [esi + board_state_62f2c]
    call set_sprite_position
    movsx eax, word [esi + board_state_62f2c]
    imul eax, eax, 0x2c
    mov dx, [esi + player_angle]
    mov [eax + sprite_angle], dx

.branch_2b186:
    movsx eax, word [esp + 0x24]
    mov ax, [nosplit eax*2 + next_player]

.branch_2b193:
    mov [esp + 0x24], eax
    mov edx, edi
    mov ecx, [esp + 0x24]
    shl edx, byte 0x2
    test cx, cx
    jnl near .branch_2b0a4
    mov eax, [edx + board_state_1a204]
    add [edx + board_state_1ba34], eax

.branch_2b1b5:
    mov eax, edi
    shl eax, byte 0x2
    mov edx, [eax + board_state_1a204]
    mov [esp + 0xc], edx
    mov edx, edi
    mov esi, [eax + board_state_1a224]
    shl edx, byte 0x5
    mov esi, [edx + esi*4 + board_state_1c17c]
    mov edx, [eax + board_state_1ba34]
    sub esi, edx
    mov edx, esi
    sar edx, byte 0x4
    test esi, esi
    jng short .branch_2b203
    cmp esi, strict dword 0x1000
    jng short .branch_2b200
    mov ecx, [esp + 0xc]
    cmp ecx, strict dword 0x100
    jnl short .branch_2b225
    lea edx, [ecx + 0x1]
    jmp short .branch_2b21f

.branch_2b200:
    inc edx
    jmp short .branch_2b21f

.branch_2b203:
    jnl short .branch_2b225
    cmp esi, strict dword 0xfffff000
    jnl short .branch_2b21e
    mov ebx, [esp + 0xc]
    cmp ebx, strict dword 0xffffff00
    jng short .branch_2b225
    lea edx, [ebx-0x1]
    jmp short .branch_2b21f

.branch_2b21e:
    dec edx

.branch_2b21f:
    mov [eax + board_state_1a204], edx

.branch_2b225:
    cmp dword [esp + 0xc], 0x0
    jnl short .branch_2b244
    mov eax, edi
    shl eax, byte 0x2
    cmp dword [eax + board_state_1a204], 0x0
    jl short .branch_2b244
    mov dword [eax + board_state_1a204], 0xffffffff

.branch_2b244:
    cmp dword [esp + 0xc], 0x0
    jng short .branch_2b263
    mov eax, edi
    shl eax, byte 0x2
    cmp dword [eax + board_state_1a204], 0x0
    jg short .branch_2b263
    mov dword [eax + board_state_1a204], 0x1

.branch_2b263:
    mov edx, edi
    shl edx, byte 0x2
    mov ebx, [edx + board_state_1a204]
    cmp ebx, 0x2
    jg near .branch_2b34f
    cmp ebx, 0xfffffffffffffffe
    jl near .branch_2b34f
    mov eax, esi
    test eax, eax
    jns short .branch_2b288
    neg eax

.branch_2b288:
    cmp eax, strict dword 0x800
    jnl near .branch_2b34f
    mov esi, [edx + board_state_1ba84]
    cmp esi, strict dword 0x2d0
    jz short .branch_2b2ae
    cmp esi, 0x78
    jl short .branch_2b2d1
    lea eax, [esi-0x3]
    cmp eax, 0x78
    jnl short .branch_2b2d1

.branch_2b2ae:
    mov eax, edi
    shl eax, byte 0x8
    movsx edx, word [eax + board_state_1bd1c]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov ax, [nosplit eax*8 + sector_hitag]
    xor ah, ah
    cwde
    call dispatch_hit_event

.branch_2b2d1:
    mov eax, edi
    shl eax, byte 0x2
    mov edx, [eax + board_state_1ba84]
    sub edx, 0x3
    mov [eax + board_state_1ba84], edx
    test edx, edx
    jnl short .branch_2b34f
    mov ecx, 0x2d0
    mov esi, [eax + board_state_1a204]
    mov [eax + board_state_1ba84], ecx
    test esi, esi
    jnl short .branch_2b322
    mov esi, [eax + board_state_1a224]
    dec esi
    mov [eax + board_state_1a224], esi
    test esi, esi
    jnl short .branch_2b34f
    mov edx, 0x1
    mov [eax + board_state_1a224], edx
    mov [eax + board_state_1a204], edx
    jmp short .branch_2b34f

.branch_2b322:
    jng short .branch_2b34f
    mov edx, [eax + board_state_1a224]
    inc edx
    mov ebx, [eax + board_state_1c16c]
    mov [eax + board_state_1a224], edx
    cmp edx, ebx
    jl short .branch_2b34f
    lea edx, [ebx-0x2]
    mov ecx, 0xffffffff
    mov [eax + board_state_1a224], edx
    mov [eax + board_state_1a204], ecx

.branch_2b34f:
    inc edi

.branch_2b350:
    movsx eax, word [board_state_7debc]
    cmp edi, eax
    jl near .branch_2af33
    add esp, 0x2c
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
