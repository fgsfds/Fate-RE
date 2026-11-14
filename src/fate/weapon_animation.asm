; Advance the displayed weapon animation and fire on the configured frame.
BITS 32
ORG 0x29cd4

last_frame_tick equ 0x2034
weapon_action equ 0x2bdc
weapon_animation_state equ 0x2bde
selected_weapon equ 0x2be0
displayed_weapon equ 0x2be2
weapon_tile equ 0x2be4
fire_player_projectile equ 0x124a1
frame_x_offset equ 0x12868
frame_y_offset equ 0x1286a
weapon_base_tile equ 0x12b68
weapon_ready_tile equ 0x12b6a
lower_start_tile equ 0x12b6c
lower_end_tile equ 0x12b6e
primary_start_tile equ 0x12b70
primary_end_tile equ 0x12b72
primary_fire_tile equ 0x12b74
primary_projectile equ 0x12b76
secondary_start_tile equ 0x12b78
secondary_end_tile equ 0x12b7a
secondary_fire_tile equ 0x12b7c
secondary_projectile equ 0x12b7e
weapon_input_bits equ 0x5ac8f
weapon_x_offset equ 0x7dee8
weapon_y_offset equ 0x7deea
projectile_type equ 0x8523c
projectile_frame equ 0x8523e
frame_direction equ 0x85240
animation_limit equ 0x85242
requested_weapon equ 0x85246
game_clock equ 0x287e88

update_weapon_animation:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov eax, [game_clock]
    sub eax, [last_frame_tick]
    cmp eax, 0x6
    jng short .hold_frame_clock
    mov eax, [game_clock]
    mov [last_frame_tick], eax
    mov eax, 0x1
    jmp short .check_weapon_animation

.hold_frame_clock:
    xor eax, eax

.check_weapon_animation:
    mov dx, [weapon_animation_state]
    test dx, dx
    jnz near .advance_active_animation
    movsx eax, word [weapon_input_bits]
    sar eax, byte 0xd
    and eax, 0x7
    mov bx, [selected_weapon]
    mov [requested_weapon], ax
    cmp ax, bx
    jz short .check_weapon_action
    movsx edx, bx
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + lower_start_tile]
    movsx edx, bx
    mov [weapon_tile], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov edi, 0x1
    mov ax, [nosplit eax*8 + lower_end_tile]
    mov [displayed_weapon], bx
    mov [animation_limit], ax
    mov ax, [weapon_tile]
    mov dx, [animation_limit]
    mov [weapon_animation_state], di
    cmp ax, dx
    jg short .branch_29d8e
    xor ecx, ecx
    mov [frame_direction], cx
    jmp near .compute_weapon_offsets

.branch_29d8e:
    mov word [frame_direction], 0xffff
    jmp near .compute_weapon_offsets

.check_weapon_action:
    movsx eax, word [weapon_action]
    cmp eax, 0x1
    jnz near .branch_29e71
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + primary_start_tile]
    movsx edx, word [requested_weapon]
    mov [weapon_tile], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + primary_end_tile]
    movsx edx, word [requested_weapon]
    mov [animation_limit], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + primary_fire_tile]
    movsx edx, word [requested_weapon]
    mov [projectile_frame], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ebx, 0x4
    mov ax, [nosplit eax*8 + primary_projectile]
    mov cx, [animation_limit]
    mov [projectile_type], ax
    mov ax, [weapon_tile]
    mov [weapon_animation_state], bx
    cmp ax, cx
    setng al
    xor ah, ah
    dec eax
    mov si, [projectile_frame]
    mov [frame_direction], ax
    cmp si, [weapon_tile]

.check_projectile_frame:
    jnz near .compute_weapon_offsets
    movsx eax, word [projectile_type]
    call fire_player_projectile
    jmp near .compute_weapon_offsets

.branch_29e71:
    movsx eax, word [weapon_action]
    cmp eax, 0x2
    jnz near .compute_weapon_offsets
    movsx edx, word [requested_weapon]
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    cmp word [nosplit eax*8 + secondary_start_tile], 0x0
    jz near .compute_weapon_offsets
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + secondary_start_tile]
    movsx edx, word [requested_weapon]
    mov [weapon_tile], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + secondary_end_tile]
    movsx edx, word [requested_weapon]
    mov [animation_limit], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + secondary_fire_tile]
    movsx edx, word [requested_weapon]
    mov [projectile_frame], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov esi, 0x4
    mov ax, [nosplit eax*8 + secondary_projectile]
    mov di, [animation_limit]
    mov [projectile_type], ax
    mov ax, [weapon_tile]
    mov [weapon_animation_state], si
    cmp ax, di
    setng al
    xor ah, ah
    dec eax
    mov dx, [projectile_frame]
    mov [frame_direction], ax
    cmp dx, [weapon_tile]
    jmp near .check_projectile_frame

.advance_active_animation:
    movsx edx, dx
    cmp edx, 0x1
    jnz short .branch_29fbf
    cmp word [frame_direction], 0x0
    jnz short .branch_29f97
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jnl short .branch_29f89
    test ax, ax
    jz near .compute_weapon_offsets
    inc edx
    mov [weapon_tile], dx
    jmp near .compute_weapon_offsets

.branch_29f89:
    mov word [weapon_animation_state], 0x2
    jmp near .compute_weapon_offsets

.branch_29f97:
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jng short .branch_29f89
    test ax, ax
    jz near .compute_weapon_offsets
    mov esi, edx
    dec esi
    mov [weapon_tile], si
    jmp near .compute_weapon_offsets

.branch_29fbf:
    cmp edx, 0x2
    jnz short .branch_2a01a
    mov edx, 0x3
    mov ax, [requested_weapon]
    mov [weapon_animation_state], dx
    movsx edx, ax
    mov [displayed_weapon], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov dx, [nosplit eax*8 + weapon_base_tile]
    mov ax, [nosplit eax*8 + weapon_ready_tile]
    mov [weapon_tile], dx
    mov [animation_limit], ax
    cmp dx, ax
    jg near .branch_29d8e
    xor esi, esi
    mov [frame_direction], si
    jmp near .compute_weapon_offsets

.branch_2a01a:
    mov cx, [weapon_tile]
    mov bx, [weapon_tile]
    inc ecx
    dec ebx
    cmp edx, 0x3
    jnz near .branch_2a0ba
    cmp word [frame_direction], 0x0
    jnz short .branch_2a07b
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jnl short .branch_2a062
    test ax, ax
    jz near .compute_weapon_offsets
    mov [weapon_tile], cx
    jmp near .compute_weapon_offsets

.branch_2a062:
    mov ax, [requested_weapon]
    mov [selected_weapon], ax
    xor eax, eax
    mov [weapon_animation_state], ax
    jmp near .compute_weapon_offsets

.branch_2a07b:
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jng short .branch_2a0a0
    test ax, ax
    jz near .compute_weapon_offsets
    mov [weapon_tile], bx
    jmp near .compute_weapon_offsets

.branch_2a0a0:
    mov ax, [requested_weapon]
    xor esi, esi
    mov [selected_weapon], ax
    mov [weapon_animation_state], si
    jmp near .compute_weapon_offsets

.branch_2a0ba:
    cmp edx, 0x4
    jnz near .compute_weapon_offsets
    test ax, ax
    jz near .compute_weapon_offsets
    mov si, [frame_direction]
    test si, si
    jnz short .branch_2a124
    mov ax, [weapon_tile]
    cmp ax, [animation_limit]
    jnl short .branch_2a0fd
    mov si, [projectile_frame]
    mov [weapon_tile], cx
    cmp cx, si
    jmp near .check_projectile_frame

.branch_2a0fd:
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + weapon_ready_tile]
    mov [weapon_animation_state], si
    jmp short .branch_2a175

.branch_2a124:
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jng short .branch_2a14f
    test ax, ax
    jz short .compute_weapon_offsets
    mov dx, [projectile_frame]
    mov [weapon_tile], bx
    cmp bx, dx
    jmp near .check_projectile_frame

.branch_2a14f:
    xor eax, eax
    mov [weapon_animation_state], ax
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov ax, [nosplit eax*8 + weapon_ready_tile]

.branch_2a175:
    mov [weapon_tile], ax

.compute_weapon_offsets:
    mov si, [displayed_weapon]
    test si, si
    jz short .compute_default_frame_index
    movsx edx, si
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov edx, eax
    shl edx, byte 0x3
    mov bx, [weapon_tile]
    sub bx, [edx + weapon_base_tile]
    jmp short .lookup_frame_offsets

.compute_default_frame_index:
    mov bx, [weapon_tile]
    sub ebx, strict dword 0x41d

.lookup_frame_offsets:
    movsx edx, word [displayed_weapon]
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov edx, eax
    movsx eax, bx
    shl edx, byte 0x5
    shl eax, byte 0x2
    add eax, edx
    mov dx, [eax + frame_x_offset]
    mov ax, [eax + frame_y_offset]
    mov [weapon_x_offset], dx
    mov [weapon_y_offset], ax
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
