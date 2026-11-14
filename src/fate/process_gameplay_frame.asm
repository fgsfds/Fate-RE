; Consume one queued input frame, save interpolation state, and advance gameplay.
BITS 32
ORG 0x2d23e

network_enabled equ 0x3c98
view_state_3ccb equ 0x3ccb
frame_state_3cd6 equ 0x3cd6
event_write_index equ 0x3cdc
player_count equ 0x13ce0
event_queue equ 0x1f7fc
board_state_209fc equ 0x209fc
projectile_positions equ 0x20a2c
update_board_environment equ 0x2a56e
update_player_motion equ 0x2b3ed
board_state_2ca2c equ 0x2ca2c
board_state_2ca6c equ 0x2ca6c
board_state_2caac equ 0x2caac
board_state_2caec equ 0x2caec
board_state_2cb2c equ 0x2cb2c
frame_state_2db6c equ 0x2db6c
frame_state_2db6d equ 0x2db6d
frame_state_2db6e equ 0x2db6e
frame_state_2db6f equ 0x2db6f
do_animations equ 0x2eeae
sub_2f035 equ 0x2f035
sub_33c3f equ 0x33c3f
update_interpolations equ 0x34589
input_history equ 0x55bbc
frame_state_55bbd equ 0x55bbd
frame_state_55bbe equ 0x55bbe
frame_state_55bbf equ 0x55bbf
board_state_5ac8c equ 0x5ac8c
board_state_5ac8d equ 0x5ac8d
board_state_5ac8e equ 0x5ac8e
player_input_word equ 0x5ac8f
previous_player_sector equ 0x5acdc
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
board_state_5ae1c equ 0x5ae1c
player_horizon equ 0x62f8c
player_angle equ 0x6308c
actor_clock equ 0x770b8
input_read_index equ 0x770cc
recorded_frame_count equ 0x770d0
processed_frame_count equ 0x770d4
next_player equ 0x18fd78
first_player equ 0x19028a
next_sprite_stat equ 0x1fbca0
sprite equ 0x2040a0
hit_sprite_list_head equ 0x28811c

process_gameplay_frame:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov edx, [processed_frame_count]
    mov ax, [first_player]
    inc edx
    mov [esp], eax
    mov [processed_frame_count], edx
    jmp short .branch_2d2bb

.copy_player_input:
    mov edx, [input_read_index]
    movsx ebx, word [esp]
    mov esi, edx
    mov eax, ebx
    shl esi, byte 0x2
    shl eax, byte 0x2
    add esi, edx
    add eax, ebx
    shl esi, byte 0x4
    mov cl, [esi + eax + input_history]
    mov dx, [esi + eax + frame_state_55bbf]
    mov [eax + board_state_5ac8c], cl
    mov [eax + player_input_word], dx
    mov cl, [esi + eax + frame_state_55bbd]
    mov [eax + board_state_5ac8d], cl
    mov cl, [esi + eax + frame_state_55bbe]
    mov [eax + board_state_5ac8e], cl
    mov ax, [nosplit ebx*2 + next_player]
    mov [esp], eax

.branch_2d2bb:
    cmp word [esp], 0x0
    jnl short .copy_player_input
    mov eax, [input_read_index]
    inc eax
    and eax, strict dword 0xff
    mov [input_read_index], eax
    cmp byte [network_enabled], 0x0
    jz short .branch_2d2fb
    call sub_33c3f
    mov edx, [event_write_index]
    mov [nosplit edx*2 + event_queue], ax
    lea eax, [edx + 0x1]
    and eax, strict dword 0xff
    mov [event_write_index], eax

.branch_2d2fb:
    mov ax, [first_player]
    jmp short .branch_2d366

.snapshot_player_pose:
    movsx edx, bx
    mov ebx, [nosplit edx*4 + player_x]
    mov [nosplit edx*4 + board_state_2caac], ebx
    mov ebx, [nosplit edx*4 + player_y]
    mov [nosplit edx*4 + board_state_2caec], ebx
    mov ebx, [nosplit edx*4 + player_z]
    mov [nosplit edx*4 + board_state_2ca6c], ebx
    mov ebx, [nosplit edx*4 + player_horizon]
    mov [nosplit edx*4 + board_state_2ca2c], ebx
    mov ebx, [nosplit edx*4 + board_state_5ae1c]
    mov eax, edx
    mov [nosplit edx*4 + board_state_2cb2c], ebx
    mov dx, [nosplit edx*2 + player_angle]
    mov [nosplit eax*2 + board_state_209fc], dx
    mov ax, [nosplit eax*2 + next_player]

.branch_2d366:
    mov [esp], eax
    mov ebx, [esp]
    test bx, bx
    jnl short .snapshot_player_pose
    mov dword [esp], 0xa
    jmp short .branch_2d3de

.branch_2d37a:
    movsx eax, si
    cmp byte [eax + view_state_3ccb], 0x0
    jl short .branch_2d3db
    mov dx, [nosplit eax*2 + hit_sprite_list_head]
    jmp short .branch_2d3d6

.snapshot_sprite_position:
    movsx eax, word [esp]
    movsx ebx, dx
    movsx esi, byte [eax + view_state_3ccb]
    mov eax, [processed_frame_count]
    sub eax, ebx
    test eax, esi
    jnz short .branch_2d3cb
    mov eax, ebx
    shl eax, byte 0x2
    sub eax, ebx
    imul ebx, ebx, 0x2c
    mov edi, projectile_positions
    mov esi, sprite
    shl eax, byte 0x2
    mov ecx, 0x3
    add edi, eax
    add esi, ebx
    rep movsd

.branch_2d3cb:
    movsx edx, dx
    mov dx, [nosplit edx*2 + next_sprite_stat]

.branch_2d3d6:
    test dx, dx
    jnl short .snapshot_sprite_position

.branch_2d3db:
    dec dword [esp]

.branch_2d3de:
    mov esi, [esp]
    test si, si
    jnl short .branch_2d37a
    mov ax, [first_player]
    jmp short .branch_2d409

.branch_2d3ee:
    movsx eax, di
    mov dx, [nosplit eax*2 + player_sector]
    mov [nosplit eax*2 + previous_player_sector], dx
    mov ax, [nosplit eax*2 + next_player]

.branch_2d409:
    mov [esp], eax
    mov edi, [esp]
    test di, di
    jnl short .branch_2d3ee
    call update_interpolations
    movsx eax, word [player_count]
    cmp eax, 0x2
    jg near .branch_2d4ca
    cmp dword [frame_state_3cd6], 0x1
    jnz near .branch_2d4ca
    mov ax, [first_player]
    xor edx, edx
    jmp short .branch_2d4a0

.record_player_input:
    mov esi, [recorded_frame_count]
    mov ecx, esi
    shl ecx, byte 0x2
    movsx edi, ax
    add ecx, esi
    movsx esi, dx
    mov eax, edi
    mov ebx, esi
    shl eax, byte 0x2
    shl ebx, byte 0x2
    add ecx, ecx
    add ebx, esi
    add eax, edi
    add ebx, ecx
    mov cl, [eax + board_state_5ac8c]
    mov [ebx + frame_state_2db6c], cl
    mov cl, [eax + board_state_5ac8d]
    mov [ebx + frame_state_2db6d], cl
    mov cl, [eax + board_state_5ac8e]
    mov ax, [eax + player_input_word]
    inc edx
    mov [ebx + frame_state_2db6f], ax
    mov ax, [nosplit edi*2 + next_player]
    mov [ebx + frame_state_2db6e], cl

.branch_2d4a0:
    mov [esp], eax
    mov eax, [esp]
    test ax, ax
    jnl short .record_player_input
    mov ecx, [recorded_frame_count]
    inc ecx
    mov [recorded_frame_count], ecx
    cmp ecx, strict dword 0x3fff
    jng short .branch_2d4ca
    mov dword [recorded_frame_count], 0x3fff

.branch_2d4ca:
    mov ebp, [actor_clock]
    mov ax, [first_player]
    add ebp, 0x3
    mov [esp], eax
    mov [actor_clock], ebp
    jmp short .branch_2d4f9

.update_player:
    movsx edx, dx
    mov eax, edx
    call update_player_motion
    mov ax, [nosplit edx*2 + next_player]
    mov [esp], eax

.branch_2d4f9:
    mov edx, [esp]
    test dx, dx
    jnl short .update_player
    call do_animations
    call update_board_environment
    call sub_2f035
    add esp, 0x4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
