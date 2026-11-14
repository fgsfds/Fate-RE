; Apply movement, clipping, and vertical motion to a player.
BITS 32
ORG 0x2b3ed

motion_state_548 equ 0x548
motion_state_552 equ 0x552
motion_state_55b equ 0x55b
motion_state_565 equ 0x565
toggled_word equ 0x203e
effect_speed equ 0x225f
status_flag equ 0x2261
item_stock equ 0x2277
item_alternate_stock equ 0x2287
weapon_action equ 0x2bdc
selected_weapon equ 0x2be2
mouse_motion_disabled equ 0x2bfc
motion_state_12c28 equ 0x12c28
move_listed_sprite equ 0x1351a
key_action_11 equ 0x13643
key_latched_secondary equ 0x1364f
motion_state_13652 equ 0x13652
fini_table_end equ 0x199e4
board_state_1ba44 equ 0x1ba44
board_state_1ba64 equ 0x1ba64
activate_sector equ 0x28710
adjust_player_status equ 0x29317
refresh_inventory equ 0x2944b
dispatch_hit_event equ 0x2b369
play_positioned_sound equ 0x34f76
play_sound equ 0x34f79
set_sprite_position equ 0x506f6
neartag equ 0x51fc1
clipmove equ 0x5291f
pushmove equ 0x53edd
krand equ 0x562e5
get_z_range equ 0x562f9
board_state_5ac8c equ 0x5ac8c
board_state_5ac8d equ 0x5ac8d
board_state_5ac8e equ 0x5ac8e
player_input_word equ 0x5ac8f
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
board_state_5ae1c equ 0x5ae1c
absolute_long equ 0x602c3
board_state_62edc equ 0x62edc
player_mode equ 0x62f1c
player_sprite equ 0x62f2c
motion_state_62f4c equ 0x62f4c
player_horizon equ 0x62f8c
motion_state_6306c equ 0x6306c
player_angle equ 0x6308c
motion_state_6308d equ 0x6308d
motion_state_630ac equ 0x630ac
status_right_tenths equ 0x6319c
key_state equ 0x6793c
special_case_flag equ 0x6793d
force_attack_frame equ 0x6f87c
player_hit_timer equ 0x6f89c
player_hit_y equ 0x7093c
player_hit_x equ 0x7097c
defer_mode_change equ 0x709bc
near_tag_distance equ 0x770a0
ceiling_z equ 0x770a4
floor_z equ 0x770a8
floor_hit equ 0x770b0
ceiling_hit equ 0x770b4
actor_clock equ 0x770b8
special_case_counter equ 0x77118
near_sector equ 0x7ded2
near_wall equ 0x7ded4
near_sprite equ 0x7ded6
smoothed_mouse_dx equ 0x7def2
motion_state_85258 equ 0x85258
motion_state_8525a equ 0x8525a
sprite equ 0x2040a0
sprite_y equ 0x2040a4
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_angle equ 0x2040bc
sprite_xvel equ 0x2040c0
sprite_yvel equ 0x2040c2
sprite_zvel equ 0x2040c4
sprite_lotag equ 0x2040c6
sprite_hitag equ 0x2040c8
sintable equ 0x2300a0
walls equ 0x2310a0
engine_2310a4 equ 0x2310a4
engine_2310a8 equ 0x2310a8
motion_state_2310b0 equ 0x2310b0
motion_state_2310b2 equ 0x2310b2
board_state_2310ba equ 0x2310ba
motion_state_2310bc equ 0x2310bc
floor_base equ 0x27c3a8
sector_lotag equ 0x27c3c2
sector_hitag equ 0x27c3c4
numsectors equ 0x289154

update_player_motion:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x1c
    mov esi, eax
    movsx edi, ax
    mov eax, edi
    shl eax, byte 0x2
    add eax, edi
    mov dx, [eax + player_input_word]
    lea ebp, [edi + edi]
    mov [esp + 0x18], edx
    movsx edx, word [ebp + defer_mode_change]
    cmp edx, 0x1
    jnz near .branch_2b49f
    push strict byte 0x0
    push strict dword 0x400
    mov ecx, player_sector
    mov eax, edi
    push strict dword 0x400
    shl eax, byte 0x2
    push strict dword 0x80
    mov edx, [eax + player_hit_y]
    add ecx, ebp
    push edx
    mov edx, player_z
    mov ebx, [eax + player_hit_x]
    add edx, eax
    push ebx
    mov [esp + 0x28], edx
    mov edx, player_y
    mov ebx, [esp + 0x28]
    add edx, eax
    add eax, player_x
    call clipmove
    mov [ebp + force_attack_frame], ax
    mov byte [edi + motion_state_630ac], 0x1
    movsx eax, word [player_sprite]
    imul eax, eax, 0x2c
    xor edi, edi
    mov [eax + sprite_xvel], di
    mov [eax + sprite_yvel], di
    mov [eax + sprite_zvel], di
    jmp near .resolve_position_and_vertical_bounds

.branch_2b49f:
    movsx edx, byte [eax + board_state_5ac8d]
    movsx eax, byte [eax + board_state_5ac8c]
    or eax, edx
    jz near .branch_2b651
    cmp word [toggled_word], 0x0
    jz short .branch_2b4c6
    mov eax, 0x8
    jmp short .branch_2b4dc

.branch_2b4c6:
    mov eax, [esp + 0x18]
    xor al, al
    and ah, 0x1
    cwde
    test eax, eax
    setg cl
    mov eax, 0x4
    shl eax, cl

.branch_2b4dc:
    movsx ebx, si
    mov edx, ebx
    shl edx, byte 0x2
    lea ecx, [ebx + edx]
    xor ebp, ebp
    mov dl, [ecx + board_state_5ac8c]
    xor edi, edi
    test dl, dl
    jz short .branch_2b541
    mov edx, ebx
    movsx ebx, word [nosplit ebx*2 + player_angle]
    add ebx, strict dword 0x200
    and ebx, strict dword 0x7ff
    movsx edi, word [nosplit ebx*2 + sintable]
    movsx ebx, byte [ecx + board_state_5ac8c]
    imul ebx, eax
    mov ebp, ebx
    imul ebp, edi
    mov dx, [nosplit edx*2 + player_angle]
    and dh, 0x7
    movsx edx, dx
    movsx edi, word [nosplit edx*2 + sintable]
    imul edi, ebx
    sar ebp, byte 0x3
    sar edi, byte 0x3

.branch_2b541:
    movsx ebx, si
    mov edx, ebx
    shl edx, byte 0x2
    add edx, ebx
    mov cl, [edx + board_state_5ac8d]
    test cl, cl
    jz short .branch_2b5a3
    movsx edx, cl
    imul edx, eax
    add ebx, ebx
    mov [esp + 0x10], ebx
    mov bx, [ebx + player_angle]
    and bh, 0x7
    movsx ebx, bx
    movsx ebx, word [nosplit ebx*2 + sintable]
    imul ebx, edx
    mov eax, [esp + 0x10]
    movsx eax, word [eax + player_angle]
    add eax, strict dword 0x600
    and eax, strict dword 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    imul edx, eax
    sar ebx, byte 0x2
    sar edx, byte 0x2
    add ebp, ebx
    add edi, edx

.branch_2b5a3:
    push strict byte 0x0
    movsx eax, si
    push strict dword 0x1388
    mov ebx, player_z
    lea ecx, [eax + eax]
    push strict dword 0xbb8
    mov edx, player_y
    add ecx, player_sector
    push strict dword 0x80
    shl eax, byte 0x2
    push edi
    add ebx, eax
    add edx, eax
    push ebp
    add eax, player_x
    call clipmove
    mov ebx, eax
    test ax, ax
    jnz short .branch_2b60a
    mov eax, ebp
    sar eax, byte 0xc
    mov edx, eax
    movsx eax, word [player_sprite]
    imul eax, eax, 0x2c
    mov [eax + sprite_xvel], dx
    mov edx, edi
    sar edx, byte 0xc
    mov [eax + sprite_yvel], dx
    jmp short .branch_2b62b

.branch_2b60a:
    movsx eax, word [player_sprite]
    imul eax, eax, 0x2c
    xor ecx, ecx
    mov [eax + sprite_xvel], cx
    mov [eax + sprite_yvel], cx
    mov [eax + sprite_zvel], cx

.branch_2b62b:
    xor eax, eax
    mov ax, bx
    cmp eax, strict dword 0xc000
    jc short .branch_2b645
    sub eax, strict dword 0xc000
    mov ebx, edi
    mov edx, ebp
    call move_listed_sprite

.branch_2b645:
    movsx eax, si
    mov byte [eax + motion_state_630ac], 0x1
    jmp short .resolve_position_and_vertical_bounds

.branch_2b651:
    xor ah, ah
    mov [edi + motion_state_630ac], ah

; Clear the player sprite blocking bit while querying geometry.
.resolve_position_and_vertical_bounds:
    movsx eax, si
    mov [esp + 0x8], eax
    lea ebp, [eax + eax]
    movsx eax, word [ebp + player_sprite]
    imul eax, eax, 0x2c
    push strict byte 0x0
    push strict dword 0x400
    mov ecx, player_sector
    push strict dword 0x400
    mov ebx, player_z
    mov edi, [esp + 0x14]
    push strict dword 0x80
    shl edi, byte 0x2
    mov dl, [eax + sprite_cstat]
    add ecx, ebp
    and dl, 0xfe
    add ebx, edi
    mov [eax + sprite_cstat], dl
    mov edx, player_y
    mov eax, player_x
    add edx, edi
    add eax, edi
    call pushmove
    push strict byte 0x0
    push strict byte 0x7f
    push strict dword floor_hit
    push strict dword ceiling_hit
    push strict dword floor_z
    movsx ecx, word [ebp + player_sector]
    mov ebx, [edi + player_z]
    push strict dword ceiling_z
    mov edx, [edi + player_y]
    mov eax, [edi + player_x]
    call get_z_range
    movsx eax, word [ebp + player_sprite]
    imul eax, eax, 0x2c
    or byte [eax + sprite_cstat], 0x1
    mov edx, [esp + 0x8]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov bl, [eax + board_state_5ac8e]
    test bl, bl
    jz near .branch_2b7b4
    jng short .branch_2b71e
    mov eax, 0x1e
    jmp short .branch_2b723

.branch_2b71e:
    mov eax, 0xffffffe2

.branch_2b723:
    mov edx, [esp + 0x18]
    xor dl, dl
    and dh, 0x1
    movsx edx, dx
    test edx, edx
    jng short .branch_2b73f
    test eax, eax
    jng short .branch_2b73c
    add eax, 0x14
    jmp short .branch_2b73f

.branch_2b73c:
    sub eax, 0x14

.branch_2b73f:
    mov cx, [motion_state_85258]
    inc ecx
    movsx edx, cx
    mov [motion_state_85258], cx
    cmp edx, 0x10
    jng short .branch_2b75f
    xor edi, edi
    mov [motion_state_85258], di

.branch_2b75f:
    movsx edx, word [motion_state_85258]
    xor ecx, ecx
    mov [nosplit edx*2 + motion_state_8525a], ax
    xor eax, eax
    jmp short .branch_2b77f

.branch_2b774:
    mov di, [nosplit eax*2 + motion_state_8525a]
    inc eax
    add ecx, edi

.branch_2b77f:
    cmp eax, 0x10
    jng short .branch_2b774
    movsx edx, cx
    mov ebx, 0x11
    mov eax, edx
    sar edx, byte 0x1f
    idiv ebx
    movsx edi, si
    mov edx, eax
    movsx eax, word [nosplit edi*2 + player_angle]
    add eax, edx
    mov [nosplit edi*2 + player_angle], ax
    and byte [nosplit edi*2 + motion_state_6308d], 0x7
    jmp short .branch_2b7c8

.branch_2b7b4:
    xor eax, eax
    jmp short .branch_2b7c3

.branch_2b7b8:
    inc eax
    xor ebx, ebx
    mov [nosplit eax*2 + motion_state_85258], bx

.branch_2b7c3:
    cmp eax, 0x10
    jng short .branch_2b7b8

.branch_2b7c8:
    movsx edx, word [smoothed_mouse_dx]
    mov ecx, edx
    sar ecx, byte 0x2
    sub edx, ecx
    movsx ebx, si
    mov ecx, edx
    movsx edx, word [nosplit ebx*2 + player_angle]
    add edx, ecx
    mov [nosplit ebx*2 + player_angle], dx
    mov ch, [nosplit ebx*2 + motion_state_6308d]
    mov eax, ebx
    and ch, 0x7
    shl eax, byte 0x2
    mov [nosplit ebx*2 + motion_state_6308d], ch
    cmp dword [eax + status_right_tenths], 0x0
    jnl short .branch_2b820
    xor esi, esi
    mov al, 0x1
    mov [special_case_counter], esi
    mov [special_case_flag], al
    jmp near .branch_2c433

.branch_2b820:
    mov edx, [esp + 0x18]
    xor dh, dh
    and dl, 0x8
    movsx edx, dx
    test edx, edx
    jng short .branch_2b843
    mov edi, [eax + player_horizon]
    test edi, edi
    jng short .branch_2b843
    lea ebp, [edi-0x4]
    mov [eax + player_horizon], ebp

.branch_2b843:
    mov eax, [esp + 0x18]
    xor ah, ah
    and al, 0x4
    cwde
    test eax, eax
    jng short .branch_2b86d
    movsx eax, si
    shl eax, byte 0x2
    mov edx, [eax + player_horizon]
    cmp edx, strict dword 0xc8
    jnl short .branch_2b86d
    lea ebx, [edx + 0x4]
    mov [eax + player_horizon], ebx

.branch_2b86d:
    movsx ebx, si
    lea ebp, [ebx + ebx]
    mov edi, [ceiling_hit]
    movsx eax, word [ebp + player_hit_timer]
    sub edi, strict dword 0x2400
    shl eax, byte 0x8
    movsx edx, word [ebp + player_sector]
    add edi, eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0x4
    jnz near .branch_2b995
    mov eax, [floor_hit]
    and eax, strict dword 0xc000
    cmp eax, strict dword 0xc000
    jz near .branch_2b995
    mov edi, [ceiling_hit]
    mov eax, ebx
    mov edx, [ceiling_hit]
    shl eax, byte 0x2
    sub edx, strict dword 0xa00
    mov ecx, [eax + player_z]
    sub edi, strict dword 0x800
    cmp edx, ecx
    jg near .branch_2b995
    push strict byte 0x0
    push strict dword 0x400
    mov edx, player_sector
    push strict dword 0x400
    mov ebx, player_z
    add edx, ebp
    push strict dword 0x80
    add ebx, eax
    mov [esp + 0x20], edx
    push strict dword 0xffff4000
    mov edx, player_y
    mov ecx, [esp + 0x24]
    push strict dword 0xffff4000
    add edx, eax
    add eax, player_x
    call clipmove
    mov ax, [ebp + board_state_1ba64]
    test ax, ax
    jl short .branch_2b995
    mov edx, eax
    sub edx, 0x3
    mov [ebp + board_state_1ba64], dx

.branch_2b944:
    movsx edx, si
    lea eax, [edx + edx]
    mov bx, [eax + board_state_1ba64]
    test bx, bx
    jnl short .branch_2b995
    mov ecx, ebx
    add ecx, 0x78
    shl edx, byte 0x2
    mov [eax + board_state_1ba64], cx
    mov eax, player_y
    push strict byte 0x1
    add eax, edx
    push eax
    mov ecx, player_x
    call krand
    and eax, 0x7f
    add ecx, edx
    lea edx, [eax + 0xfc0]
    mov ebx, 0x100
    mov eax, motion_state_548
    call play_positioned_sound
    jmp short .branch_2b944

.branch_2b995:
    mov eax, [ceiling_z]
    add eax, strict dword 0x1000
    cmp edi, eax
    jnl short .branch_2b9b2
    mov eax, [ceiling_hit]
    mov edi, [ceiling_z]
    add edi, eax
    sar edi, 1

.branch_2b9b2:
    movsx eax, si
    shl eax, byte 0x2
    cmp dword [eax + status_right_tenths], 0x0
    jl near .branch_2baa4
    mov edx, [esp + 0x18]
    xor dh, dh
    and dl, 0x1
    movsx edx, dx
    test edx, edx
    jng short .branch_2ba3e
    mov edx, [esp + 0x18]
    mov ecx, [actor_clock]
    xor dl, dl
    mov ebx, [eax + board_state_62edc]
    and dh, 0x1
    cmp ebx, ecx
    jg short .branch_2ba19
    mov ebx, [ceiling_hit]
    mov ecx, [eax + player_z]
    sub ebx, strict dword 0x2400
    cmp ebx, ecx
    jg short .branch_2ba3e
    movsx eax, dx
    sub edi, strict dword 0x2000
    test eax, eax
    jz short .branch_2ba3e
    sub edi, strict dword 0x2000
    jmp short .branch_2ba3e

.branch_2ba19:
    mov ebp, [eax + motion_state_62f4c]
    sub ebp, strict dword 0xc0
    movsx edx, dx
    mov [eax + motion_state_62f4c], ebp
    test edx, edx
    jz short .branch_2ba3e
    lea edx, [ebp-0xc0]
    mov [eax + motion_state_62f4c], edx

.branch_2ba3e:
    mov eax, [esp + 0x18]
    xor ah, ah
    and al, 0x2
    cwde
    test eax, eax
    jng short .branch_2baa4
    mov edx, [esp + 0x18]
    movsx eax, si
    mov ebp, [actor_clock]
    shl eax, byte 0x2
    xor dl, dl
    mov ebx, [eax + board_state_62edc]
    and dh, 0x1
    cmp ebx, ebp
    jg short .branch_2ba7f
    movsx eax, dx
    add edi, strict dword 0xc00
    test eax, eax
    jz short .branch_2baa4
    add edi, strict dword 0xc00
    jmp short .branch_2baa4

.branch_2ba7f:
    mov ebx, [eax + motion_state_62f4c]
    add ebx, strict dword 0xc0
    movsx edx, dx
    mov [eax + motion_state_62f4c], ebx
    test edx, edx
    jz short .branch_2baa4
    lea ecx, [ebx + 0xc0]
    mov [eax + motion_state_62f4c], ecx

.branch_2baa4:
    movsx edx, si
    shl edx, byte 0x2
    mov ebp, [actor_clock]
    cmp ebp, [edx + board_state_62edc]
    jl short .branch_2bae1
    mov ebp, [edx + player_z]
    cmp edi, ebp
    jng short .branch_2bacb
    add dword [edx + motion_state_62f4c], 0x60
    jmp short .branch_2bb06

.branch_2bacb:
    mov ebx, edi
    sub ebx, ebp
    mov eax, ebx
    shl eax, byte 0x2
    sub eax, ebx
    sar eax, byte 0x5
    mov [edx + motion_state_62f4c], eax
    jmp short .branch_2bb06

.branch_2bae1:
    mov eax, [edx + motion_state_62f4c]
    mov ebx, [edx + motion_state_62f4c]
    sar eax, byte 0x2
    sub ebx, eax
    mov [edx + motion_state_62f4c], ebx
    add ebx, ebx
    sbb eax, eax
    cmp eax, ebx
    adc al, 0x0
    sub [edx + motion_state_62f4c], eax

.branch_2bb06:
    movsx edx, si
    mov eax, edx
    shl eax, byte 0x2
    mov ebx, [eax + motion_state_62f4c]
    mov ecx, [eax + player_z]
    add ecx, ebx
    movsx ebx, word [nosplit edx*2 + player_sector]
    mov edx, ebx
    shl edx, byte 0x2
    add edx, ebx
    shl edx, byte 0x3
    mov edi, [edx + floor_base]
    mov [eax + player_z], ecx
    cmp ecx, edi
    jng short .branch_2bb4a
    lea edx, [edi-0x400]
    mov [eax + player_z], edx

.branch_2bb4a:
    cmp dword [player_hit_x], 0x0
    jnz short .branch_2bb5c
    cmp dword [player_hit_y], 0x0
    jz short .branch_2bbce

.branch_2bb5c:
    mov edx, 0x1
    mov eax, [player_hit_x]
    mov [defer_mode_change], dx
    sar eax, byte 0x3
    mov edx, [player_hit_x]
    sub edx, eax
    mov eax, [player_hit_y]
    mov ebx, [player_hit_y]
    sar eax, byte 0x3
    mov [player_hit_x], edx
    sub ebx, eax
    mov eax, edx
    mov [player_hit_y], ebx
    call absolute_long
    cmp eax, strict dword 0x1000
    jnl short .branch_2bbaa
    xor ecx, ecx
    mov [player_hit_x], ecx

.branch_2bbaa:
    mov eax, [player_hit_y]
    call absolute_long
    cmp eax, strict dword 0x1000
    jnl short .branch_2bbc3
    xor edi, edi
    mov [player_hit_y], edi

.branch_2bbc3:
    xor ebx, ebx
    mov [player_hit_timer], bx
    jmp short .branch_2bbee

.branch_2bbce:
    mov eax, [motion_state_62f4c]
    call absolute_long
    cmp eax, 0x14
    jnl short .branch_2bbee
    xor edi, edi
    xor eax, eax
    mov [defer_mode_change], di
    mov [player_hit_timer], ax

.branch_2bbee:
    movsx eax, si
    mov edx, [ceiling_hit]
    shl eax, byte 0x2
    sub edx, strict dword 0x400
    cmp edx, [eax + player_z]
    jnl short .branch_2bc16
    mov [eax + player_z], edx
    xor edx, edx
    mov [eax + motion_state_62f4c], edx

.branch_2bc16:
    movsx eax, si
    mov edx, [ceiling_z]
    shl eax, byte 0x2
    add edx, strict dword 0x400
    cmp edx, [eax + player_z]
    jng short .branch_2bc3e
    xor ecx, ecx
    mov [eax + player_z], edx
    mov [eax + motion_state_62f4c], ecx

.branch_2bc3e:
    movsx edx, si
    movsx ebx, word [nosplit edx*2 + player_sector]
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ebx, [nosplit eax*8 + floor_base]
    mov eax, edx
    shl eax, byte 0x2
    sub ebx, strict dword 0x400
    cmp ebx, [eax + player_z]
    jnl short .branch_2bc70
    mov [eax + player_z], ebx

.branch_2bc70:
    movsx eax, si
    xor edx, edx
    mov dl, [eax + player_mode]
    cmp edx, 0x3
    jz short .branch_2bcdc
    mov edx, [esp + 0x18]
    xor dh, dh
    and dl, 0x20
    movsx edx, dx
    test edx, edx
    jng short .branch_2bcad
    shl eax, byte 0x2
    mov ebp, [eax + board_state_5ae1c]
    cmp ebp, 0x30
    jng short .branch_2bcad
    mov edx, ebp
    mov ebx, ebp
    sar edx, byte 0x4
    sub ebx, edx
    mov [eax + board_state_5ae1c], ebx

.branch_2bcad:
    mov eax, [esp + 0x18]
    xor ah, ah
    and al, 0x10
    cwde
    test eax, eax
    jng short .branch_2bcdc
    movsx eax, si
    shl eax, byte 0x2
    mov ecx, [eax + board_state_5ae1c]
    cmp ecx, strict dword 0x1000
    jnl short .branch_2bcdc
    mov edx, ecx
    sar edx, byte 0x4
    lea edi, [ecx + edx]
    mov [eax + board_state_5ae1c], edi

.branch_2bcdc:
    movsx eax, si
    mov ebp, eax
    mov [esp + 0xc], eax
    shl ebp, byte 0x2
    lea edi, [eax + eax]
    mov ecx, [ebp + player_z]
    mov ebx, [ebp + player_y]
    mov edx, [ebp + player_x]
    movsx eax, word [edi + player_sprite]
    add ecx, strict dword 0x2000
    call set_sprite_position
    movsx eax, word [edi + player_sprite]
    imul eax, eax, 0x2c
    mov dx, [edi + player_angle]
    mov [eax + sprite_angle], dx
    cmp dword [ebp + status_right_tenths], 0x0
    jl near .branch_2bdd8
    mov cx, [edi + player_sector]
    test cx, cx
    jl short .branch_2bd49
    cmp cx, [numsectors]
    jl short .branch_2bd88

.branch_2bd49:
    movsx edi, si
    mov eax, edi
    mov edx, player_y
    shl eax, byte 0x2
    push strict byte 0x1
    add edx, eax
    mov ecx, player_x
    push edx
    add ecx, eax
    call krand
    and eax, 0x7f
    lea edx, [eax + 0xfc0]
    mov ebx, 0x40
    mov eax, motion_state_552
    call play_positioned_sound
    mov edx, 0xfffffffd
    mov eax, edi
    jmp short .branch_2bdd3

.branch_2bd88:
    mov eax, [ceiling_z]
    mov edx, [ceiling_hit]
    add eax, strict dword 0x800
    cmp eax, edx
    jng short .branch_2bdd8
    mov eax, player_y
    push strict byte 0x1
    add eax, ebp
    push eax
    mov ecx, player_x
    call krand
    and eax, 0x7f
    mov ebx, 0x40
    lea edx, [eax + 0xfc0]
    add ecx, ebp
    mov eax, motion_state_552
    call play_positioned_sound
    mov edx, 0xfffffffd
    mov eax, [esp + 0xc]

.branch_2bdd3:
    call adjust_player_status

.branch_2bdd8:
    movsx eax, si
    cmp word [nosplit eax*2 + fini_table_end], 0x0
    jl near .check_use_input
    cmp dword [nosplit eax*4 + status_right_tenths], 0x0
    jl near .check_use_input
    movsx eax, word [near_sprite]
    shl eax, byte 0x5
    movsx eax, word [eax + board_state_2310ba]
    cmp eax, 0x7
    jnz short .branch_2be1c
    mov eax, [esp + 0x18]
    xor al, al
    and ah, 0x4
    cwde
    test eax, eax
    jnz short .check_use_input

.branch_2be1c:
    movsx eax, si
    movsx eax, word [nosplit eax*2 + fini_table_end]
    shl eax, byte 0x5
    movsx edx, word [eax + motion_state_2310b2]
    cmp edx, 0x5b
    jnz short .branch_2be41
    mov word [eax + motion_state_2310b2], 0x5a
    jmp short .branch_2be56

.branch_2be41:
    movsx edx, word [eax + motion_state_2310b0]
    cmp edx, 0x5b
    jnz short .branch_2be56
    mov word [eax + motion_state_2310b0], 0x5a

.branch_2be56:
    movsx eax, si
    mov word [nosplit eax*2 + fini_table_end], 0xffff

; Find tagged objects in front of the player. Fall back to the current tagged sector.
.check_use_input:
    mov eax, [esp + 0x18]
    xor al, al
    and ah, 0x4
    cwde
    test eax, eax
    jng near .branch_2c27a
    push strict byte 0x3
    push strict dword 0x400
    push strict dword near_tag_distance
    movsx eax, si
    push strict dword near_wall
    lea edi, [eax + eax]
    mov ebx, [nosplit eax*4 + player_z]
    push strict dword near_sprite
    movsx edx, word [edi + player_angle]
    push strict dword near_sector
    movsx ecx, word [edi + player_sector]
    push edx
    mov edx, [nosplit eax*4 + player_y]
    mov eax, [nosplit eax*4 + player_x]
    call neartag
    movsx eax, word [near_sector]
    cmp eax, -1
    jnz short .check_tagged_sprite
    movsx eax, word [edi + player_sector]
    mov edx, eax
    shl edx, byte 0x2
    add edx, eax
    mov bx, [nosplit edx*8 + sector_hitag]
    xor bh, bh
    movsx edx, word [nosplit edx*8 + sector_lotag]
    movsx ebx, bx
    or edx, ebx
    jz short .check_tagged_sprite
    mov [near_sector], ax

.check_tagged_sprite:
    movsx eax, word [near_sprite]
    shl eax, byte 0x5
    movsx edx, word [eax + board_state_2310ba]
    cmp edx, 0x7
    jnz near .branch_2c061
    movsx edx, word [eax + motion_state_2310b2]
    cmp edx, 0x5a
    jnz short .branch_2bf7b
    movsx edi, si
    mov eax, edi
    mov edx, player_y
    shl eax, byte 0x2
    push strict byte 0x1
    add edx, eax
    mov ecx, player_x
    push edx
    add ecx, eax
    call krand
    and eax, 0x7f
    lea edx, [eax + 0xfc0]
    mov ebx, 0x100
    mov eax, motion_state_55b
    call play_positioned_sound
    mov ecx, 0x5b
    movsx eax, word [near_sprite]
    mov dx, [near_sprite]
    shl eax, byte 0x5
    mov [nosplit edi*2 + fini_table_end], dx
    mov [eax + motion_state_2310b2], cx
    jmp short .branch_2bfe2

.branch_2bf7b:
    movsx eax, word [eax + motion_state_2310b0]
    cmp eax, 0x5a
    jnz short .branch_2bfe2
    movsx edi, si
    mov eax, edi
    mov edx, player_y
    shl eax, byte 0x2
    push strict byte 0x1
    add edx, eax
    mov ecx, player_x
    push edx
    add ecx, eax
    call krand
    and eax, 0x7f
    lea edx, [eax + 0xfc0]
    mov ebx, 0x100
    mov eax, motion_state_55b
    call play_positioned_sound
    mov ebx, 0x5b
    movsx eax, word [near_sprite]
    mov dx, [near_sprite]
    shl eax, byte 0x5
    mov [nosplit edi*2 + fini_table_end], dx
    mov [eax + motion_state_2310b0], bx

.branch_2bfe2:
    movsx eax, si
    add eax, eax
    cmp word [eax + fini_table_end], 0x0
    jl short .branch_2c061
    mov dx, [eax + board_state_1ba44]
    sub edx, 0x3
    movsx edi, si
    mov [eax + board_state_1ba44], dx

.branch_2c005:
    lea eax, [edi + edi]
    mov bx, [eax + board_state_1ba44]
    test bx, bx
    jnl short .branch_2c061
    mov ecx, ebx
    mov edx, edi
    add ecx, 0x78
    shl edx, byte 0x2
    mov [eax + board_state_1ba44], cx
    mov eax, player_y
    push strict byte 0x1
    add eax, edx
    push eax
    mov ecx, player_x
    call krand
    and eax, 0x7f
    add ecx, edx
    lea edx, [eax + 0xfc0]
    mov ebx, 0x100
    mov eax, motion_state_55b
    call play_positioned_sound
    mov edx, 0x2
    mov eax, edi
    call adjust_player_status
    jmp short .branch_2c005

.branch_2c061:
    movsx eax, si
    mov ax, [nosplit eax*2 + motion_state_6306c]
    xor al, al
    and ah, 0x4
    cwde
    test eax, eax
    jnz near .branch_2c27a
    mov di, [near_sector]
    test di, di
    jl short .branch_2c0a6
    movsx edx, di
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov ax, [nosplit eax*8 + sector_hitag]
    xor ah, ah
    cwde
    test eax, eax
    jnz short .branch_2c0a6
    mov eax, edx
    call activate_sector

.branch_2c0a6:
    mov ax, [near_sprite]
    test ax, ax
    jl near .branch_2c177
    cwde
    shl eax, byte 0x5
    movsx edx, word [eax + board_state_2310ba]
    cmp edx, 0x2
    jnz near .branch_2c177
    movsx eax, word [eax + motion_state_2310bc]
    mov ecx, [esp + 0x14]
    call dispatch_hit_event
    cmp ecx, strict dword 0x568
    jnz short .branch_2c0f4
    movsx eax, word [near_sprite]
    shl eax, byte 0x5
    mov word [eax + motion_state_2310b2], 0x567

.branch_2c0f4:
    cmp dword [esp + 0x14], strict dword 0x567
    jnz short .branch_2c111
    movsx eax, word [near_sprite]
    shl eax, byte 0x5
    mov word [eax + motion_state_2310b2], 0x568

.branch_2c111:
    movsx edx, word [near_sprite]
    shl edx, byte 0x5
    push strict byte 0x0
    movsx eax, word [edx + engine_2310a8]
    mov ecx, [edx + walls]
    shl eax, byte 0x5
    mov edx, [edx + engine_2310a4]
    mov ebp, [eax + walls]
    mov ebx, [eax + engine_2310a4]
    lea eax, [esp + 0x4]
    add ecx, ebp
    add edx, ebx
    sar ecx, 1
    sar edx, 1
    push eax
    mov [esp + 0xc], ecx
    mov [esp + 0x8], edx
    call krand
    and eax, strict dword 0xff
    mov ebx, 0x100
    lea edx, [eax + 0xf80]
    lea ecx, [esp + 0xc]
    mov eax, motion_state_565
    call play_positioned_sound

.branch_2c177:
    mov cx, [near_wall]
    test cx, cx
    jl near .branch_2c27a
    movsx eax, cx
    imul eax, eax, 0x2c
    mov dx, [eax + sprite_lotag]
    xor dh, dh
    movsx edx, dx
    cmp edx, 0x4
    jnz near .branch_2c27a
    mov ax, [eax + sprite_hitag]
    xor ah, ah
    cwde
    call dispatch_hit_event
    movsx eax, word [near_wall]
    imul eax, eax, 0x2c
    movsx edx, word [eax + sprite_tile]
    mov [esp + 0x14], edx
    cmp edx, strict dword 0x568
    jnz short .branch_2c1d7
    mov word [eax + sprite_tile], 0x567

.branch_2c1d7:
    cmp dword [esp + 0x14], strict dword 0x567
    jnz short .branch_2c1f4
    movsx eax, word [near_wall]
    imul eax, eax, 0x2c
    mov word [eax + sprite_tile], 0x568

.branch_2c1f4:
    cmp dword [esp + 0x14], strict dword 0x3aa
    jnz short .branch_2c232
    mov eax, 0xa0
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    movsx eax, word [near_wall]
    imul eax, eax, 0x2c
    mov ebx, 0x3ab
    xor dl, dl
    mov [eax + sprite_tile], bx
    mov [eax + sprite_lotag], dl
    mov [eax + sprite_hitag], dl

.branch_2c232:
    movsx edx, word [near_wall]
    imul edx, edx, 0x2c
    mov eax, [edx + sprite]
    mov [esp + 0x4], eax
    mov eax, [edx + sprite_y]
    push strict byte 0x0
    mov [esp + 0x4], eax
    lea eax, [esp + 0x4]
    push eax
    call krand
    and eax, strict dword 0xff
    lea ecx, [esp + 0xc]
    lea edx, [eax + 0xf80]
    mov ebx, 0x100
    mov eax, motion_state_565
    call play_positioned_sound

.branch_2c27a:
    xor eax, eax
    mov al, [key_action_11]
    cmp byte [eax + key_state], 0x0
    jna near .branch_2c317
    cmp word [selected_weapon], 0x0
    jnz short .branch_2c2a0
    xor bh, bh
    mov [eax + key_state], bh

.branch_2c2a0:
    movsx eax, word [selected_weapon]
    cmp eax, 0x1
    jnz short .branch_2c2c0
    cmp word [nosplit eax*2 + item_stock], 0x0
    jg short .branch_2c2c0
    mov word [weapon_action], 0x2

.branch_2c2c0:
    cmp word [mouse_motion_disabled], 0x0
    jnz short .branch_2c317
    movsx eax, word [selected_weapon]
    cmp eax, 0x1
    jl short .branch_2c30e
    cmp word [nosplit eax*2 + item_stock], 0x0
    jng short .branch_2c2ea
    mov word [weapon_action], 0x1

.branch_2c2ea:
    movsx eax, word [selected_weapon]
    add eax, eax
    cmp word [eax + item_stock], 0x0
    jnz short .branch_2c317
    cmp word [eax + item_alternate_stock], 0x0
    jnz short .branch_2c317
    call refresh_inventory
    jmp short .branch_2c317

.branch_2c30e:
    mov word [weapon_action], 0x1

.branch_2c317:
    xor eax, eax
    mov al, [key_latched_secondary]
    cmp byte [eax + key_state], 0x0
    jna short .branch_2c37c
    xor ch, ch
    mov [eax + key_state], ch
    movsx eax, word [selected_weapon]
    cmp eax, 0x1
    jl short .branch_2c373
    cmp word [nosplit eax*2 + item_alternate_stock], 0x0
    jng short .branch_2c34f
    mov word [weapon_action], 0x2

.branch_2c34f:
    movsx eax, word [selected_weapon]
    add eax, eax
    cmp word [eax + item_stock], 0x0
    jnz short .branch_2c37c
    cmp word [eax + item_alternate_stock], 0x0
    jnz short .branch_2c37c
    call refresh_inventory
    jmp short .branch_2c37c

.branch_2c373:
    mov word [weapon_action], 0x2

.branch_2c37c:
    xor eax, eax
    mov al, [motion_state_13652]
    cmp byte [eax + key_state], 0x0
    jna short .branch_2c396
    add word [motion_state_12c28], 0x10
    jmp short .branch_2c3db

.branch_2c396:
    xor eax, eax
    mov ax, [motion_state_12c28]
    cmp eax, strict dword 0x100
    jng short .branch_2c3db
    sar eax, byte 0x8
    mov [effect_speed], ax
    xor eax, eax
    mov ax, [effect_speed]
    cmp eax, 0x4
    jng short .branch_2c3c4
    mov word [effect_speed], 0x4

.branch_2c3c4:
    mov edi, 0x100
    mov eax, 0x3
    mov [motion_state_12c28], di
    mov [weapon_action], ax

.branch_2c3db:
    movsx eax, si
    mov dx, [nosplit eax*2 + motion_state_6306c]
    xor dl, dl
    and dh, 0x10
    movsx ebx, dx
    mov edx, [esp + 0x18]
    xor dl, dl
    and dh, 0x10
    movsx edx, dx
    cmp edx, ebx
    jng short .save_input_word
    movsx edx, word [status_flag]
    cmp edx, 0x1
    jnz short .save_input_word
    inc byte [eax + player_mode]
    xor edx, edx
    mov dl, [eax + player_mode]
    cmp edx, 0x3
    jng short .save_input_word
    mov byte [eax + player_mode], 0x1

.save_input_word:
    movsx eax, si
    mov edx, [esp + 0x18]
    mov [nosplit eax*2 + motion_state_6306c], dx

.branch_2c433:
    add esp, 0x1c
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
