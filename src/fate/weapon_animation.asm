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

section .text align=1
update_weapon_animation equ 0x29cd4
; Exact C phases own removed code; original branch targets remain fixed.
.hold_frame_clock equ 0x29cfa
.check_weapon_animation equ 0x29cfc
.branch_29d8e equ 0x29d8e
.check_weapon_action equ 0x29d9c
.check_projectile_frame equ 0x29e5a
.branch_29e71 equ 0x29e71
.advance_active_animation equ 0x29f51
.branch_29f89 equ 0x29f89
.branch_29f97 equ 0x29f97
.branch_29fbf equ 0x29fbf
.branch_2a01a equ 0x2a01a
.branch_2a062 equ 0x2a062
.branch_2a07b equ 0x2a07b
.branch_2a0a0 equ 0x2a0a0
.branch_2a0ba equ 0x2a0ba
.branch_2a0fd equ 0x2a0fd
.branch_2a124 equ 0x2a124
.branch_2a14f equ 0x2a14f
.branch_2a175 equ 0x2a175
.compute_weapon_offsets equ 0x2a17b
.compute_default_frame_index equ 0x2a1a6
.lookup_frame_offsets equ 0x2a1b3

section .retained_0 align=1 vstart=0x29cee follows=.text
    mov [last_frame_tick], eax
    mov eax, 0x1
    jmp short .check_weapon_animation
    xor eax, eax

section .retained_1 align=1 vstart=0x29d0c follows=.retained_0
    movsx eax, word [weapon_input_bits]

section .retained_2 align=1 vstart=0x29d35 follows=.retained_1
    mov ax, [nosplit eax*8 + lower_start_tile]
    movsx edx, bx
    mov [weapon_tile], ax

section .retained_3 align=1 vstart=0x29d4d follows=.retained_2
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
    mov word [frame_direction], 0xffff
    jmp near .compute_weapon_offsets
    movsx eax, word [weapon_action]
    cmp eax, 0x1
    jnz near .branch_29e71
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax

section .retained_4 align=1 vstart=0x29de6 follows=.retained_3
    movsx edx, word [requested_weapon]
    mov [animation_limit], ax

section .retained_5 align=1 vstart=0x29e16 follows=.retained_4
    mov ebx, 0x4
    mov ax, [nosplit eax*8 + primary_projectile]
    mov cx, [animation_limit]
    mov [projectile_type], ax
    mov ax, [weapon_tile]
    mov [weapon_animation_state], bx
    cmp ax, cx

section .retained_6 align=1 vstart=0x29e46 follows=.retained_5
    mov si, [projectile_frame]
    mov [frame_direction], ax
    cmp si, [weapon_tile]
    jnz near .compute_weapon_offsets

section .retained_7 align=1 vstart=0x29e6c follows=.retained_6
    jmp near .compute_weapon_offsets
    movsx eax, word [weapon_action]
    cmp eax, 0x2
    jnz near .compute_weapon_offsets

section .retained_8 align=1 vstart=0x29ea4 follows=.retained_7
    movsx edx, ax
    mov [displayed_weapon], ax

section .retained_9 align=1 vstart=0x29ed8 follows=.retained_8
    movsx edx, word [requested_weapon]
    mov [animation_limit], ax

section .retained_10 align=1 vstart=0x29f08 follows=.retained_9
    mov esi, 0x4
    mov ax, [nosplit eax*8 + secondary_projectile]
    mov di, [animation_limit]
    mov [projectile_type], ax
    mov ax, [weapon_tile]
    mov [weapon_animation_state], si
    cmp ax, di

section .retained_11 align=1 vstart=0x29f38 follows=.retained_10
    mov dx, [projectile_frame]
    mov [frame_direction], ax
    cmp dx, [weapon_tile]
    jmp near .check_projectile_frame

section .retained_12 align=1 vstart=0x29f63 follows=.retained_11
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jnl short .branch_29f89
    test ax, ax
    jz near .compute_weapon_offsets
    inc edx
    mov [weapon_tile], dx
    jmp near .compute_weapon_offsets

section .retained_13 align=1 vstart=0x29f97 follows=.retained_12
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jng short .branch_29f89
    test ax, ax
    jz near .compute_weapon_offsets
    mov esi, edx
    dec esi
    mov [weapon_tile], si
    jmp near .compute_weapon_offsets

section .retained_14 align=1 vstart=0x29fc4 follows=.retained_13
    mov edx, 0x3
    mov ax, [requested_weapon]
    mov [weapon_animation_state], dx
    movsx edx, ax
    mov [displayed_weapon], ax

section .retained_15 align=1 vstart=0x29fe6 follows=.retained_14
    mov dx, [nosplit eax*8 + weapon_base_tile]
    mov ax, [nosplit eax*8 + weapon_ready_tile]
    mov [weapon_tile], dx
    mov [animation_limit], ax
    cmp dx, ax
    jg near .branch_29d8e
    xor esi, esi
    mov [frame_direction], si
    jmp near .compute_weapon_offsets
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
    mov ax, [requested_weapon]
    mov [selected_weapon], ax
    xor eax, eax
    mov [weapon_animation_state], ax
    jmp near .compute_weapon_offsets
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jng short .branch_2a0a0
    test ax, ax

section .retained_16 align=1 vstart=0x2a0a6 follows=.retained_15
    xor esi, esi
    mov [selected_weapon], ax
    mov [weapon_animation_state], si
    jmp near .compute_weapon_offsets

section .retained_17 align=1 vstart=0x2a0c3 follows=.retained_16
    test ax, ax
    jz near .compute_weapon_offsets
    mov si, [frame_direction]
    test si, si

section .retained_18 align=1 vstart=0x2a0e5 follows=.retained_17
    jnl short .branch_2a0fd
    mov si, [projectile_frame]
    mov [weapon_tile], cx
    cmp cx, si
    jmp near .check_projectile_frame
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax

section .retained_19 align=1 vstart=0x2a113 follows=.retained_18
    mov ax, [nosplit eax*8 + weapon_ready_tile]
    mov [weapon_animation_state], si
    jmp short .branch_2a175
    mov dx, [weapon_tile]
    cmp dx, [animation_limit]
    jng short .branch_2a14f
    test ax, ax
    jz short .compute_weapon_offsets
    mov dx, [projectile_frame]
    mov [weapon_tile], bx
    cmp bx, dx
    jmp near .check_projectile_frame
    xor eax, eax
    mov [weapon_animation_state], ax
    mov ax, [requested_weapon]
    movsx edx, ax
    mov [displayed_weapon], ax

section .retained_20 align=1 vstart=0x2a175 follows=.retained_19
    mov [weapon_tile], ax
