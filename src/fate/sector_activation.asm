; Activate a registered sector using its tag, wall bounds and animation state.
BITS 32
ORG 0x28710

activation_state_504 equ 0x504
left_icon equ 0x2038
middle_icon equ 0x203a
right_icon equ 0x203c
activation_state_1aa34 equ 0x1aa34
activation_state_1b234 equ 0x1b234
find_sector_animation equ 0x2efa1
set_sector_animation equ 0x2efc0
play_positioned_sound equ 0x34f76
play_sound equ 0x34f79
select_item equ 0x380d8
neighbor_sector_at_z equ 0x50c63
interpolation_hook equ 0x562e5
activation_state_7499c equ 0x7499c
activation_state_749a0 equ 0x749a0
level_sector_ids equ 0x7639c
level_sector_active equ 0x7639e
activation_state_7aa3c equ 0x7aa3c
current_board equ 0x7f87e
activation_state_2310a0 equ 0x2310a0
activation_state_2310a4 equ 0x2310a4
activation_state_2310a8 equ 0x2310a8
activation_state_2310ba equ 0x2310ba
sector_wall_start equ 0x27c3a0
sector_wall_count equ 0x27c3a2
activation_state_27c3a4 equ 0x27c3a4
sector_floor_z equ 0x27c3a8
sector_lotag equ 0x27c3c2
sector_hitag equ 0x27c3c4

activate_sector:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x34
    push eax
    movsx edx, ax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    movsx edi, word [nosplit eax*8 + sector_lotag]
    mov ax, [nosplit eax*8 + sector_hitag]
    mov edx, 0x1
    xor ah, ah
    mov [esp + 0x34], edx
    mov [esp + 0x30], eax
    jmp short .check_registered_sector_index

.inspect_registered_sector:
    mov edx, eax
    movsx ebx, bx
    shl edx, byte 0x7
    mov esi, ebx
    mov dx, [edx + esi*4 + level_sector_ids]
    mov esi, [esp]
    cmp dx, si
    jz short .read_registered_sector
    inc dword [esp + 0x34]

.check_registered_sector_index:
    movsx eax, byte [current_board]
    mov ebx, [esp + 0x34]
    cmp bx, [nosplit eax*2 + activation_state_7aa3c]
    jng short .inspect_registered_sector
    jmp near .return

.read_registered_sector:
    movsx esi, si
    mov edx, esi
    shl edx, byte 0x2
    add edx, esi
    mov si, [nosplit edx*8 + sector_wall_start]
    mov [esp + 0x2c], esi
    add si, [nosplit edx*8 + sector_wall_count]
    mov edx, ebx
    shl eax, byte 0x8
    shl edx, byte 0x3
    add edx, eax
    mov eax, [edx + activation_state_7499c]
    mov [esp + 0xc], eax
    mov eax, [edx + activation_state_749a0]
    mov [esp + 0x28], esi
    mov [esp + 0x8], eax
    cmp edi, 0x10
    jc short .branch_28818
    jna near .branch_288c1
    cmp edi, 0x47
    jc short .branch_28805
    cmp edi, 0x49
    jna near .branch_28874
    cmp edi, 0x51
    jc near .dispatch_sector_sound
    cmp edi, 0x53
    jna near .branch_288a3
    cmp edi, strict dword 0xa1
    jc near .dispatch_sector_sound
    cmp edi, strict dword 0xa3
    jna near .branch_288c1
    jmp near .dispatch_sector_sound

.branch_28805:
    cmp edi, 0x3d
    jc near .dispatch_sector_sound
    cmp edi, 0x3f
    jna short .branch_28836
    jmp near .dispatch_sector_sound

.branch_28818:
    cmp edi, 0x7
    jc short .branch_2882d
    jna short .branch_28874
    cmp edi, 0x8
    jz near .branch_288a3
    jmp near .dispatch_sector_sound

.branch_2882d:
    cmp edi, 0x6
    jnz near .dispatch_sector_sound

.branch_28836:
    movsx ecx, byte [current_board]
    mov edx, ecx
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    cmp word [edx + eax*4 + level_sector_active], 0x0
    jnz short .branch_28861
    cmp ecx, 0x5
    jng short .branch_28895

.branch_28857:
    mov ecx, 0x75
    jmp near .dispatch_sector_sound

.branch_28861:
    cmp ecx, 0x5
    jng near .branch_288e2

.branch_2886a:
    mov ecx, 0x76
    jmp near .dispatch_sector_sound

.branch_28874:
    movsx ecx, byte [current_board]
    mov edx, ecx
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    cmp word [edx + eax*4 + level_sector_active], 0x0
    jnz short .branch_2889c

.branch_28890:
    cmp ecx, 0x5
    jg short .branch_28857

.branch_28895:
    mov ecx, 0x73
    jmp short .dispatch_sector_sound

.branch_2889c:
    cmp ecx, 0x5
    jg short .branch_2886a
    jmp short .branch_288e2

.branch_288a3:
    movsx ecx, byte [current_board]
    mov edx, ecx
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    cmp word [edx + eax*4 + level_sector_active], 0x0
    jz short .branch_28890
    jmp short .branch_2889c

.branch_288c1:
    movsx ecx, byte [current_board]
    mov edx, ecx
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    cmp word [edx + eax*4 + level_sector_active], 0x0
    jz short .branch_28890
    cmp ecx, 0x5
    jg short .branch_2886a

.branch_288e2:
    mov ecx, 0x74

.dispatch_sector_sound:
    cmp edi, 0x48
    jc short .branch_2893e
    jna near .check_middle_icon_sound
    cmp edi, 0x53
    jc short .branch_2892d
    jna near .check_right_icon_sound
    cmp edi, strict dword 0xa2
    jc short .branch_2891c
    jna near .check_middle_icon_sound
    cmp edi, strict dword 0xa3

.branch_28911:
    jz near .check_right_icon_sound
    jmp near .check_ceiling_activation

.branch_2891c:
    cmp edi, strict dword 0xa1

.branch_28922:
    jz near .check_left_icon_sound
    jmp near .check_ceiling_activation

.branch_2892d:
    cmp edi, 0x51
    jc short .branch_28939
    jna short .check_left_icon_sound
    jmp near .check_middle_icon_sound

.branch_28939:
    cmp edi, 0x49
    jmp short .branch_28911

.branch_2893e:
    cmp edi, 0x3d
    jc short .branch_28951
    jna short .check_left_icon_sound
    cmp edi, 0x3f
    jc short .check_middle_icon_sound
    jna short .check_right_icon_sound
    cmp edi, 0x47
    jmp short .branch_28922

.branch_28951:
    cmp edi, 0x6
    jc near .check_ceiling_activation
    cmp edi, 0x8
    jna short .branch_28968
    cmp edi, 0x10
    jnz near .check_ceiling_activation

.branch_28968:
    movsx eax, word [esp + 0x30]
    cmp eax, 0x2
    jz short .check_ceiling_activation

.play_activation_sound:
    mov ebx, [esp + 0x8]
    mov edx, [esp + 0xc]
    movsx eax, cx
    mov ecx, 0x2
    call play_sound
    jmp short .check_ceiling_activation

.check_left_icon_sound:
    cmp word [left_icon], 0x0
    jnz short .play_activation_sound
    mov eax, 0xf
    jmp short .show_required_item

.check_middle_icon_sound:
    cmp word [middle_icon], 0x0
    jnz short .play_activation_sound
    mov eax, 0x10
    jmp short .show_required_item

.check_right_icon_sound:
    cmp word [right_icon], 0x0
    jnz short .play_activation_sound
    movsx eax, byte [current_board]
    cmp eax, 0x7
    jnz short .branch_289c8
    mov eax, 0x18
    jmp short .show_required_item

.branch_289c8:
    mov eax, 0x11

.show_required_item:
    call select_item

.check_ceiling_activation:
    cmp edi, 0x6
    jz near .activate_ceiling
    cmp edi, 0x8
    jz near .activate_ceiling
    cmp edi, 0x3d
    jnz short .branch_289f3
    cmp word [left_icon], 0x0
    jnz short .activate_ceiling

.branch_289f3:
    cmp edi, 0x3e
    jnz short .branch_28a02
    cmp word [middle_icon], 0x0
    jnz short .activate_ceiling

.branch_28a02:
    cmp edi, 0x3f
    jnz short .branch_28a11
    cmp word [right_icon], 0x0
    jnz short .activate_ceiling

.branch_28a11:
    cmp edi, 0x51
    jnz short .branch_28a20
    cmp word [left_icon], 0x0
    jnz short .activate_ceiling

.branch_28a20:
    cmp edi, 0x52
    jnz short .branch_28a2f
    cmp word [middle_icon], 0x0
    jnz short .activate_ceiling

.branch_28a2f:
    cmp edi, 0x53
    jnz near .check_floor_activation
    cmp word [right_icon], 0x0
    jz near .check_floor_activation

.activate_ceiling:
    movsx edx, byte [current_board]
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    mov bl, [edx + eax*4 + level_sector_active]
    xor bl, 0x1
    movsx ebp, word [esp]
    mov [edx + eax*4 + level_sector_active], bl
    mov edx, ebp
    shl edx, byte 0x2
    add edx, ebp
    mov eax, sector_wall_start
    shl edx, byte 0x3
    add eax, edx
    add eax, 0x4
    call find_sector_animation
    mov esi, eax
    test eax, eax
    jl near .branch_28b1c
    cmp edi, 0x8
    jz short .branch_28aa1
    cmp edi, 0x51
    jz short .branch_28aa1
    cmp edi, 0x52
    jz short .branch_28aa1
    cmp edi, 0x53
    jnz short .branch_28ac1

.branch_28aa1:
    movsx edx, word [esp]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, [nosplit eax*8 + activation_state_27c3a4]
    mov ebp, [nosplit eax*8 + sector_floor_z]
    lea eax, [edx + ebp]
    sar eax, 1
    jmp short .branch_28ac7

.branch_28ac1:
    mov eax, [edx + sector_floor_z]

.branch_28ac7:
    mov ebp, esi
    shl ebp, byte 0x2
    cmp eax, [ebp + activation_state_1b234]
    jnz short .branch_28b08
    movsx eax, word [esp]
    mov [esp + 0x10], eax
    mov edx, eax
    shl eax, byte 0x2
    mov ecx, 0xffffffff
    add eax, edx
    mov ebx, ecx
    mov edx, [nosplit eax*8 + sector_floor_z]
    mov eax, [esp + 0x10]
    call neighbor_sector_at_z
    mov edx, eax
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + activation_state_27c3a4]

.branch_28b08:
    mov [ebp + activation_state_1b234], eax
    xor ebx, ebx
    mov [nosplit esi*4 + activation_state_1aa34], ebx
    jmp near .check_floor_activation

.branch_28b1c:
    mov eax, [edx + activation_state_27c3a4]
    mov ebx, [edx + sector_floor_z]
    cmp eax, ebx
    jnz short .branch_28b4c
    mov ecx, 0xffffffff
    mov edx, ebx
    mov eax, ebp
    mov ebx, ecx
    call neighbor_sector_at_z
    mov edx, eax
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + activation_state_27c3a4]
    jmp short .branch_28b82

.branch_28b4c:
    cmp edi, 0x8
    jz short .branch_28b60
    cmp edi, 0x51
    jz short .branch_28b60
    cmp edi, 0x52
    jz short .branch_28b60
    cmp edi, 0x53
    jnz short .branch_28b80

.branch_28b60:
    movsx edx, word [esp]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, [nosplit eax*8 + activation_state_27c3a4]
    mov ecx, [nosplit eax*8 + sector_floor_z]
    lea eax, [edx + ecx]
    sar eax, 1
    jmp short .branch_28b82

.branch_28b80:
    mov eax, ebx

.branch_28b82:
    movsx ebx, word [esp]
    mov edx, ebx
    shl edx, byte 0x2
    add edx, ebx
    mov esi, sector_wall_start
    shl edx, byte 0x3
    mov ecx, 0x30
    add esi, edx
    mov ebx, ecx
    add esi, 0x4
    mov edx, eax
    mov eax, esi
    call set_sector_animation
    test eax, eax
    jl short .check_floor_activation
    push strict byte 0x0
    lea eax, [esp + 0xc]
    push eax
    call interpolation_hook
    and eax, strict dword 0xff
    lea ecx, [esp + 0x14]
    lea edx, [eax + 0xf80]
    mov ebx, 0x100
    mov eax, activation_state_504
    call play_positioned_sound

.check_floor_activation:
    cmp edi, 0x7
    jz near .activate_floor
    cmp edi, 0x8
    jz near .activate_floor
    cmp edi, 0x47
    jnz short .branch_28bf9
    cmp word [left_icon], 0x0
    jnz short .activate_floor

.branch_28bf9:
    cmp edi, 0x48
    jnz short .branch_28c08
    cmp word [middle_icon], 0x0
    jnz short .activate_floor

.branch_28c08:
    cmp edi, 0x49
    jnz short .branch_28c17
    cmp word [right_icon], 0x0
    jnz short .activate_floor

.branch_28c17:
    cmp edi, 0x51
    jnz short .branch_28c26
    cmp word [left_icon], 0x0
    jnz short .activate_floor

.branch_28c26:
    cmp edi, 0x52
    jnz short .branch_28c35
    cmp word [middle_icon], 0x0
    jnz short .activate_floor

.branch_28c35:
    cmp edi, 0x53
    jnz near .check_wall_activation
    cmp word [right_icon], 0x0
    jz near .check_wall_activation

.activate_floor:
    cmp edi, 0x7
    jz short .branch_28c60
    cmp edi, 0x47
    jz short .branch_28c60
    cmp edi, 0x48
    jz short .branch_28c60
    cmp edi, 0x49
    jnz short .branch_28c77

.branch_28c60:
    movsx eax, byte [current_board]
    movsx edx, word [esp + 0x34]
    shl eax, byte 0x7
    xor byte [eax + edx*4 + level_sector_active], 0x1

.branch_28c77:
    movsx ebp, word [esp]
    mov edx, ebp
    shl edx, byte 0x2
    add edx, ebp
    mov eax, sector_wall_start
    shl edx, byte 0x3
    add eax, edx
    add eax, 0x8
    call find_sector_animation
    mov esi, eax
    test eax, eax
    jl near .branch_28d2d
    cmp edi, 0x8
    jz short .branch_28cb2
    cmp edi, 0x51
    jz short .branch_28cb2
    cmp edi, 0x52
    jz short .branch_28cb2
    cmp edi, 0x53
    jnz short .branch_28cd2

.branch_28cb2:
    movsx edx, word [esp]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, [nosplit eax*8 + activation_state_27c3a4]
    mov ebp, [nosplit eax*8 + sector_floor_z]
    lea eax, [edx + ebp]
    sar eax, 1
    jmp short .branch_28cd8

.branch_28cd2:
    mov eax, [edx + activation_state_27c3a4]

.branch_28cd8:
    mov ebp, esi
    shl ebp, byte 0x2
    cmp eax, [ebp + activation_state_1b234]
    jnz short .branch_28d19
    movsx eax, word [esp]
    mov [esp + 0x10], eax
    mov edx, eax
    shl eax, byte 0x2
    mov ecx, 0x1
    add eax, edx
    mov ebx, ecx
    mov edx, [nosplit eax*8 + activation_state_27c3a4]
    mov eax, [esp + 0x10]
    call neighbor_sector_at_z
    mov edx, eax
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + sector_floor_z]

.branch_28d19:
    mov [ebp + activation_state_1b234], eax
    xor ebx, ebx
    mov [nosplit esi*4 + activation_state_1aa34], ebx
    jmp near .check_wall_activation

.branch_28d2d:
    mov eax, [edx + sector_floor_z]
    mov ecx, [edx + activation_state_27c3a4]
    cmp eax, ecx
    jnz short .branch_28d5d
    mov edx, ecx
    mov ecx, 0x1
    mov eax, ebp
    mov ebx, ecx
    call neighbor_sector_at_z
    mov edx, eax
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + sector_floor_z]
    jmp short .branch_28d93

.branch_28d5d:
    cmp edi, 0x8
    jz short .branch_28d71
    cmp edi, 0x51
    jz short .branch_28d71
    cmp edi, 0x52
    jz short .branch_28d71
    cmp edi, 0x53
    jnz short .branch_28d91

.branch_28d71:
    movsx edx, word [esp]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edx, [nosplit eax*8 + activation_state_27c3a4]
    mov esi, [nosplit eax*8 + sector_floor_z]
    lea eax, [edx + esi]
    sar eax, 1
    jmp short .branch_28d93

.branch_28d91:
    mov eax, ecx

.branch_28d93:
    movsx ebx, word [esp]
    mov edx, ebx
    shl edx, byte 0x2
    add edx, ebx
    mov esi, sector_wall_start
    shl edx, byte 0x3
    mov ecx, 0x30
    add esi, edx
    mov ebx, ecx
    add esi, 0x8
    mov edx, eax
    mov eax, esi
    call set_sector_animation
    test eax, eax
    jl short .check_wall_activation
    push strict byte 0x0
    lea eax, [esp + 0xc]
    push eax
    call interpolation_hook
    and eax, strict dword 0xff
    lea ecx, [esp + 0x14]
    lea edx, [eax + 0xf80]
    mov ebx, 0x100
    mov eax, activation_state_504
    call play_positioned_sound

.check_wall_activation:
    cmp edi, 0x10
    jz short .branch_28e2c
    cmp edi, strict dword 0xa1
    jnz short .branch_28e00
    cmp word [left_icon], 0x0
    jnz short .branch_28e2c

.branch_28e00:
    cmp edi, strict dword 0xa2
    jnz short .branch_28e12
    cmp word [middle_icon], 0x0
    jnz short .branch_28e2c

.branch_28e12:
    cmp edi, strict dword 0xa3
    jnz near .return
    cmp word [right_icon], 0x0
    jz near .return

.branch_28e2c:
    movsx edx, byte [current_board]
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    mov cl, [edx + eax*4 + level_sector_active]
    movsx esi, word [esp + 0x2c]
    and cl, 0xfe
    mov di, [left_icon]
    mov [edx + eax*4 + level_sector_active], cl
    mov ecx, 0xffffffff
    mov dx, [right_icon]
    mov [esp + 0x4], cx
    mov [esp + 0x6], cx
    jmp near .branch_28ed6

.branch_28e73:
    mov eax, esi
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310ba]
    cmp eax, 0x6
    jz short .branch_28ebf
    cmp eax, 0x3d
    jnz short .branch_28e8e
    test di, di
    jnz short .branch_28ebf

.branch_28e8e:
    mov eax, esi
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310ba]
    cmp eax, 0x3e
    jnz short .branch_28ea9
    cmp word [middle_icon], 0x0
    jnz short .branch_28ebf

.branch_28ea9:
    mov eax, esi
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310ba]
    cmp eax, 0x3f
    jnz short .branch_28ed5
    test dx, dx
    jz short .branch_28ed5

.branch_28ebf:
    movsx eax, word [esp + 0x4]
    cmp eax, -1
    jnz short .branch_28ed0
    mov [esp + 0x4], si
    jmp short .branch_28ed5

.branch_28ed0:
    mov [esp + 0x6], si

.branch_28ed5:
    inc esi

.branch_28ed6:
    movsx eax, word [esp + 0x28]
    cmp esi, eax
    jl short .branch_28e73
    xor ecx, ecx
    mov [esp + 0x24], ecx
    jmp near .check_wall_component_index

.activate_wall_component:
    movsx ebx, word [esp + esi*2 + 0x4]
    mov eax, ebx
    shl eax, byte 0x5
    movsx edx, word [eax + activation_state_2310a8]
    shl edx, byte 0x5
    mov esi, [eax + activation_state_2310a0]
    add esi, [edx + activation_state_2310a0]
    mov ebp, [esp + 0xc]
    sar esi, 1
    cmp esi, ebp
    jnz near .branch_2914a
    mov eax, [eax + activation_state_2310a4]
    add eax, [edx + activation_state_2310a4]
    mov esi, [esp + 0x8]
    sar eax, 1
    cmp eax, esi
    jnz near .branch_2914a
    movsx edx, byte [current_board]
    movsx eax, word [esp + 0x34]
    shl edx, byte 0x7
    mov ch, [edx + eax*4 + level_sector_active]
    or ch, 0x1
    lea esi, [ebx-0x1]
    mov [edx + eax*4 + level_sector_active], ch
    movsx eax, word [esp + 0x2c]
    cmp esi, eax
    jnl short .branch_28f64
    movsx esi, word [esp + 0x28]
    dec esi

.branch_28f64:
    mov ebp, [esp + 0x24]
    shl esi, byte 0x5
    add ebp, ebp
    mov [esp + 0x20], esi
    movsx eax, word [esp + ebp + 0x4]
    mov edi, [esp + 0x20]
    shl eax, byte 0x5
    mov edi, [edi + activation_state_2310a4]
    mov edx, [eax + activation_state_2310a4]
    mov ebx, [esp + 0x20]
    sub edi, edx
    mov edx, activation_state_2310a0
    add edx, ebx
    mov esi, [esi + activation_state_2310a0]
    mov [esp + 0x18], edx
    mov edx, activation_state_2310a0
    mov ecx, [eax + activation_state_2310a0]
    add edx, eax
    sub esi, ecx
    mov [esp + 0x14], edx
    test esi, esi
    jz near .branch_29076
    movsx edx, word [eax + activation_state_2310a8]
    shl edx, byte 0x5
    movsx edx, word [edx + activation_state_2310a8]
    shl edx, byte 0x5
    movsx esi, word [edx + activation_state_2310a8]
    shl esi, byte 0x5
    mov edi, [edx + activation_state_2310a0]
    mov esi, [esi + activation_state_2310a0]
    sub esi, edi
    mov ebx, 0x30
    lea edx, [ecx + esi]
    mov eax, [esp + 0x14]
    xor ecx, ecx
    call set_sector_animation
    mov edx, [esp + 0x20]
    mov ebx, 0x30
    mov eax, [esp + 0x18]
    mov edx, [edx + activation_state_2310a0]
    xor ecx, ecx
    add edx, esi
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    mov ebx, 0x30
    shl eax, byte 0x5
    xor ecx, ecx
    mov edx, [eax + activation_state_2310a0]
    add eax, activation_state_2310a0
    add edx, esi
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    mov ebx, 0x30
    shl eax, byte 0x5
    xor ecx, ecx
    mov edx, [eax + activation_state_2310a0]
    add eax, activation_state_2310a0
    add edx, esi
    jmp near .branch_292b9

.branch_29076:
    test edi, edi
    jz near .branch_292be
    movsx edx, word [eax + activation_state_2310a8]
    shl edx, byte 0x5
    movsx edx, word [edx + activation_state_2310a8]
    shl edx, byte 0x5
    mov ebx, 0x30
    movsx edi, word [edx + activation_state_2310a8]
    mov ecx, [edx + activation_state_2310a4]
    shl edi, byte 0x5
    mov edx, [eax + activation_state_2310a4]
    mov edi, [edi + activation_state_2310a4]
    mov eax, [esp + 0x14]
    sub edi, ecx
    add eax, 0x4
    add edx, edi
    xor ecx, ecx
    call set_sector_animation
    mov edx, [esp + 0x20]
    mov eax, [esp + 0x18]
    mov ebx, 0x30
    xor ecx, ecx
    mov edx, [edx + activation_state_2310a4]
    add eax, 0x4
    add edx, edi
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    mov ebx, 0x30
    shl eax, byte 0x5
    xor ecx, ecx
    mov edx, [eax + activation_state_2310a4]
    add eax, activation_state_2310a0
    add edx, edi
    add eax, 0x4
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    mov ebx, 0x30
    shl eax, byte 0x5
    xor ecx, ecx
    mov edx, [eax + activation_state_2310a4]
    add eax, activation_state_2310a0
    add edx, edi
    add eax, 0x4
    jmp near .branch_292b9

.branch_2914a:
    mov eax, [esp + 0x24]
    movsx esi, word [esp + eax*2 + 0x4]
    movsx eax, word [esp + 0x2c]
    dec esi
    cmp esi, eax
    jnl short .branch_29163
    movsx esi, word [esp + 0x28]
    dec esi

.branch_29163:
    mov ebp, [esp + 0x24]
    add ebp, ebp
    mov edx, esi
    movsx eax, word [esp + ebp + 0x4]
    shl edx, byte 0x5
    shl eax, byte 0x5
    mov esi, [edx + activation_state_2310a0]
    mov edi, [eax + activation_state_2310a0]
    mov ebx, [eax + activation_state_2310a4]
    sub esi, edi
    mov edi, [edx + activation_state_2310a4]
    sub edi, ebx
    mov ebx, activation_state_2310a0
    add ebx, edx
    add eax, activation_state_2310a0
    mov [esp + 0x1c], ebx
    test esi, esi
    jz near .branch_2922a
    mov ebx, 0x30
    mov edx, [esp + 0xc]
    xor ecx, ecx
    call set_sector_animation
    mov edx, [esp + 0xc]
    mov ebx, 0x30
    mov eax, [esp + 0x1c]
    xor ecx, ecx
    add edx, esi
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    mov ebx, 0x30
    movsx eax, word [eax + activation_state_2310a8]
    mov edx, [esp + 0xc]
    shl eax, byte 0x5
    xor ecx, ecx
    add eax, activation_state_2310a0
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    mov edx, [esp + 0xc]
    shl eax, byte 0x5
    mov ebx, 0x30
    movsx eax, word [eax + activation_state_2310a8]
    xor ecx, ecx
    shl eax, byte 0x5
    add edx, esi
    add eax, activation_state_2310a0
    jmp near .branch_292b9

.branch_2922a:
    test edi, edi
    jz near .branch_292be
    mov ebx, 0x30
    mov edx, [esp + 0x8]
    add eax, 0x4
    xor ecx, ecx
    call set_sector_animation
    mov edx, [esp + 0x8]
    mov eax, [esp + 0x1c]
    mov ebx, 0x30
    xor ecx, ecx
    add eax, 0x4
    add edx, edi
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    mov ebx, 0x30
    shl eax, byte 0x5
    mov edx, [esp + 0x8]
    add eax, activation_state_2310a0
    xor ecx, ecx
    add eax, 0x4
    call set_sector_animation
    movsx eax, word [esp + ebp + 0x4]
    shl eax, byte 0x5
    movsx eax, word [eax + activation_state_2310a8]
    shl eax, byte 0x5
    mov edx, [esp + 0x8]
    movsx eax, word [eax + activation_state_2310a8]
    mov ebx, 0x30
    shl eax, byte 0x5
    xor ecx, ecx
    add eax, activation_state_2310a0
    add edx, edi
    add eax, 0x4

.branch_292b9:
    call set_sector_animation

.branch_292be:
    inc dword [esp + 0x24]

.check_wall_component_index:
    mov esi, [esp + 0x24]
    cmp esi, 0x2
    jl near .activate_wall_component
    push strict byte 0x0
    lea eax, [esp + 0xc]
    lea ecx, [esp + 0x10]
    mov ebx, 0x100
    push eax
    mov edx, 0xfc0
    mov eax, activation_state_504
    call play_positioned_sound
    push strict byte 0x0
    lea eax, [esp + 0xc]
    lea ecx, [esp + 0x10]
    mov ebx, 0x100
    push eax
    mov edx, 0x1040
    mov eax, activation_state_504
    call play_positioned_sound

.return:
    add esp, 0x38
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
