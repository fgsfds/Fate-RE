; Update movement, animation, and close-range attacks for actor profile one, mode one.
BITS 32
ORG 0x15411

random_value equ 0x602d0
play_sound equ 0x34f79
integer_square_root equ 0x4ca38
get_angle equ 0x4c94c
absolute_int equ 0x6032c
clipmove equ 0x5291f
change_sprite_sector equ 0x50bc3
check_attack_target equ 0x1d3ee
absolute_long equ 0x602c3
adjust_status_value equ 0x1092e
actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_tile equ 0x2040ae
defer_mode_change equ 0x709bc
actor_recovery_counter equ 0x7f295
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
player_x equ 0x5ad9c
player_y equ 0x5ad5c
player_angle equ 0x6308c
actor_clock equ 0x770b8
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8
sprite_xrepeat equ 0x2040b2
ticks_per_step equ 0x7a994
sector_floor_z equ 0x27c3a8
sector_hitag equ 0x27c3c4
tile_height equ 0x1f4020
sprite_yrepeat equ 0x2040b5
actor_z_offset equ 0x79214
actor_sequence_initial equ 0x7e4e2
advance_clock equ 0x229b
sprite_angle equ 0x2040bc
sine_table equ 0x2300a0
actor_target equ 0x7dede
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_horizon equ 0x62f8c
force_attack_frame equ 0x6f87c
player_hit_timer equ 0x6f89c
player_hit_y equ 0x7093c
player_hit_x equ 0x7097c
actor_last_frame_clock equ 0x80efc
actor_frame_counter equ 0x816d0
action_clock equ 0x81ea4
actor_action equ 0x81ea8

update_actor_profile_one_mode_one:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x1c
    push eax
    mov edi, edx
    cwde
    mov dx, word [nosplit eax*2 + actor_sprite_index]
    mov dword [esp + 0x1c], edx
    xor edx, edx
    mov dl, byte [eax + actor_kind]
    cmp edx, 3
    je near .return
    movsx edx, word [esp + 0x1c]
    imul edx, edx, 0x2c
    movsx ebx, di
    add ebx, 0x40
    movsx ecx, word [edx + sprite_tile]
    cmp ecx, ebx
    jne short .check_reaction
    cmp byte [eax + actor_kind], 0
    jne near .return
    mov eax, edi
    add eax, strict dword 0x37
    mov word [edx + sprite_tile], ax

.check_reaction:
    movsx eax, word [esp]
    mov al, byte [eax + actor_kind]
    and eax, 0xff
    cmp eax, 4
    je short .handle_reaction
    cmp eax, 5
    jne near .measure_target

.handle_reaction:
    cmp word [defer_mode_change], 0
    je short .choose_reaction
    movsx eax, word [esp]
    xor cl, cl
    mov byte [eax + actor_kind], cl
    mov byte [eax + actor_recovery_counter], cl
    jmp near .measure_target

.choose_reaction:
    call random_value
    xor ah, ah
    and al, 3
    cwde
    cmp eax, 3
    jl short .show_reaction_frame
    movsx edx, word [esp]
    xor eax, eax
    mov al, byte [edx + actor_kind]
    cmp eax, 4
    jne short .show_alternate_reaction

.show_reaction_frame:
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    add edi, 0x40
    mov ebx, dword [eax + sprite_y]
    mov esi, dword [eax + sprite_x]
    mov word [eax + sprite_tile], di
    call random_value
    mov edx, eax
    mov ecx, 4
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x24]
    xor ecx, ecx
    mov edx, esi
    jmp near .play_sound_and_return

.show_alternate_reaction:
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov ebx, edi
    add ebx, 0x41
    mov word [eax + sprite_tile], bx
    xor bh, bh
    mov esi, dword [eax + sprite_x]
    mov byte [edx + actor_kind], bh
    mov ebx, dword [eax + sprite_y]
    call random_value
    mov edx, eax
    mov ecx, 4
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x24]
    xor ecx, ecx
    mov edx, esi
    call play_sound

.measure_target:
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov edx, dword [player_x]
    mov ecx, dword [eax + sprite_x]
    sub ecx, edx
    mov edx, ecx
    imul edx, ecx
    mov esi, dword [player_y]
    mov ebx, dword [eax + sprite_y]
    sub ebx, esi
    mov eax, ebx
    imul eax, ebx
    add eax, edx
    call integer_square_root
    mov dword [action_clock], eax
    mov edx, ebx
    mov eax, ecx
    call get_angle
    mov dx, word [player_angle]
    cwde
    movsx edx, dx
    sub eax, edx
    call absolute_int
    movsx edx, ax
    mov dword [esp + 0x14], eax
    cmp edx, 0x400
    jle short .check_close_attack
    mov edx, 0x7ff
    sub edx, eax
    mov dword [esp + 0x14], edx

.check_close_attack:
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    movsx edx, di
    mov ax, word [eax + sprite_tile]
    lea ebp, [edx + 0x45]
    movsx esi, ax
    cmp esi, ebp
    jl near .check_walk_range
    add edx, 0x46
    cmp esi, edx
    jg near .check_walk_range
    movsx esi, word [esp]
    mov edx, dword [actor_clock]
    sub edx, dword [nosplit esi*4 + actor_last_frame_clock]
    cmp edx, 0xc8
    jg short .check_last_attack_frame
    cmp word [force_attack_frame], 0
    je short .check_attack_cooldown

.check_last_attack_frame:
    movsx esi, di
    movsx edx, ax
    add esi, 0x46
    cmp edx, esi
    jne short .check_attack_cooldown
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    jmp near .reset_idle_tile

.check_attack_cooldown:
    movsx edx, word [esp]
    shl edx, 2
    mov esi, dword [actor_clock]
    sub esi, dword [edx + actor_last_frame_clock]
    cmp esi, 0x3c
    jle short .adjust_player_horizon
    cmp dword [player_horizon], 0x64
    jne short .adjust_player_horizon
    movsx esi, di
    cwde
    add esi, 0x46
    cmp eax, esi
    je near .return
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    add edi, 0x46
    neg ecx
    neg ebx
    shl ecx, 0xd
    mov word [eax + sprite_tile], di
    mov eax, dword [actor_clock]
    shl ebx, 0xd
    sub eax, 0x3d
    mov dword [player_hit_x], ecx
    mov dword [edx + actor_last_frame_clock], eax
    mov eax, 0xffffff9c
    mov dword [player_hit_y], ebx
    call adjust_status_value
    call random_value
    mov edx, eax
    mov ebx, 2
    sar edx, 0x1f
    idiv ebx
    xor ecx, ecx
    lea eax, [edx + 0xf]

.play_player_hit_sound:
    xor ebx, ebx
    xor edx, edx
    jmp near .play_sound_and_return

.adjust_player_horizon:
    mov edx, dword [ticks_per_step]
    mov eax, edx
    shl eax, 2
    mov edi, dword [player_horizon]
    sub eax, edx
    shl edx, 2
    cmp edi, 0x64
    jle short .check_horizon_below_center
    lea ebx, [edi - 0x64]
    cmp ebx, edx
    jg short .lower_horizon

.center_horizon:
    mov dword [player_horizon], 0x64
    jmp near .return

.lower_horizon:
    mov ebp, edi
    sub ebp, eax
    mov dword [player_horizon], ebp
    jmp near .return

.check_horizon_below_center:
    jge near .return
    mov ebx, 0x64
    sub ebx, edi
    cmp ebx, edx
    jle short .center_horizon
    lea esi, [edi + eax]
    mov dword [player_horizon], esi
    jmp near .return

.check_walk_range:
    movsx edx, di
    lea ebp, [edx + 0x41]
    movsx esi, ax
    cmp esi, ebp
    jl near .check_stationary_frames
    lea ebp, [edx + 0x44]
    cmp esi, ebp
    jg near .check_stationary_frames
    add edx, 0x43
    add edi, 0x37
    cmp esi, edx
    jne short .advance_walk_frame
    movsx edx, word [esp]
    shl edx, 2
    mov eax, dword [actor_clock]
    sub eax, dword [edx + actor_last_frame_clock]
    cmp eax, 0x14
    jle near .move_toward_target
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov esi, dword [actor_clock]
    mov dword [edx + actor_last_frame_clock], esi
    mov si, word [eax + sprite_tile]
    inc esi
    movsx edx, si
    mov word [eax + sprite_tile], si
    cmp edx, ebp
    jle short .move_toward_target
    jmp short .wrap_walk_frame

.advance_walk_frame:
    movsx edx, word [esp]
    shl edx, 2
    mov eax, dword [actor_clock]
    sub eax, dword [edx + actor_last_frame_clock]
    cmp eax, 0xa
    jle short .move_toward_target
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov esi, dword [actor_clock]
    mov dword [edx + actor_last_frame_clock], esi
    mov dx, word [eax + sprite_tile]
    inc edx
    mov word [eax + sprite_tile], dx
    movsx edx, dx
    cmp edx, ebp
    jle short .move_toward_target

.wrap_walk_frame:
    mov word [eax + sprite_tile], di

.move_toward_target:
    movsx ebp, word [esp + 0x1c]
    imul esi, ebp, 0x2c
    imul ecx, dword [ticks_per_step]
    mov eax, dword [esi + sprite_x]
    mov dword [esp + 0xc], eax
    mov eax, dword [esi + sprite_y]
    mov dword [esp + 8], eax
    mov eax, dword [esi + sprite_z]
    mov dword [esp + 4], eax
    mov ax, word [esi + sprite_sector]
    push 0
    mov dword [esp + 0x1c], eax
    xor eax, eax
    push strict dword 0xe40
    mov al, byte [esi + sprite_xrepeat]
    push strict dword 0x1c80
    shl eax, 2
    push eax
    mov eax, dword [ticks_per_step]
    imul eax, ebx
    shl eax, 0xa
    lea edx, [esp + 0x18]
    push eax
    shl ecx, 0xa
    lea ebx, [esp + 0x18]
    push ecx
    lea eax, [esp + 0x24]
    lea ecx, [esp + 0x30]
    call clipmove
    movsx edx, word [esi + sprite_sector]
    movsx ebx, word [esp + 0x18]
    mov ecx, edx
    mov eax, ebx
    shl ecx, 2
    shl eax, 2
    add ecx, edx
    lea edx, [ebx + eax]
    shl ecx, 3
    shl edx, 3
    mov edi, dword [ecx + sector_floor_z]
    mov eax, dword [edx + sector_floor_z]
    sub eax, edi
    cmp eax, strict dword 0xc00
    jge near .return
    cmp word [esp + 0x18], 0
    jl near .return
    movsx eax, word [edx + sector_hitag]
    test ah, 0x80
    jne near .return
    movsx edi, word [esi + sprite_tile]
    xor ecx, ecx
    movsx edi, word [nosplit edi*2 + tile_height]
    mov cl, byte [esi + sprite_yrepeat]
    imul edi, ecx
    mov eax, dword [esp + 0xc]
    mov dword [esi + sprite_x], eax
    mov eax, dword [esp + 8]
    mov dword [esi + sprite_y], eax
    movsx ecx, word [esp]
    mov eax, dword [edx + sector_floor_z]
    mov edx, dword [nosplit ecx*4 + actor_z_offset]
    add edi, edi
    add eax, edx
    sub eax, edi
    mov dx, word [esi + sprite_sector]
    mov dword [esi + sprite_z], eax
    cmp dx, word [esp + 0x18]
    je near .return
    mov edx, ebx
    mov eax, ebp
    call change_sprite_sector
    jmp near .return

.check_stationary_frames:
    movsx edx, di
    movsx ebx, ax
    lea ecx, [edx + 0x3b]
    cmp ebx, ecx
    jl short .check_second_frame_range
    lea ebp, [edx + 0x3c]
    cmp ebx, ebp
    jg short .check_second_frame_range
    movsx eax, word [esp]
    shl eax, 2
    mov edx, dword [actor_clock]
    sub edx, dword [eax + actor_last_frame_clock]
    cmp edx, 0xa
    jle near .return
    mov edx, dword [actor_clock]
    mov dword [eax + actor_last_frame_clock], edx
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov si, word [eax + sprite_tile]
    inc esi
    movsx edx, si
    mov word [eax + sprite_tile], si
    cmp edx, ebp

.check_stationary_wrap:
    jle near .return

.reset_idle_tile:
    add edi, 0x37
    mov word [eax + sprite_tile], di
    jmp near .return

.check_second_frame_range:
    movsx edx, di
    cwde
    lea ebx, [edx + 0x3d]
    cmp eax, ebx
    jl short .choose_action
    lea ebx, [edx + 0x3f]
    cmp eax, ebx
    jg short .choose_action
    movsx eax, word [esp]
    shl eax, 2
    mov edx, dword [actor_clock]
    sub edx, dword [eax + actor_last_frame_clock]
    cmp edx, 0xa
    jle near .return
    mov edx, dword [actor_clock]
    mov dword [eax + actor_last_frame_clock], edx
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov cx, word [eax + sprite_tile]
    inc ecx
    movsx edx, cx
    mov word [eax + sprite_tile], cx
    cmp edx, ebx
    jmp short .check_stationary_wrap

.choose_action:
    movsx edx, word [esp]
    mov esi, edi
    mov bx, word [nosplit edx*2 + actor_action]
    add esi, 0x37
    test bx, bx
    jle short .choose_idle_frame
    movsx eax, word [esp + 0x1c]
    imul eax, eax, 0x2c
    mov word [eax + sprite_tile], si
    jmp near .check_random_action

.choose_idle_frame:
    movsx ebx, word [esp + 0x1c]
    imul ebx, ebx, 0x2c
    mov eax, edi
    add eax, strict dword 0x23
    mov word [ebx + sprite_tile], ax
    mov eax, edx
    shl eax, 2
    mov ecx, dword [action_clock]
    add ecx, dword [eax + actor_frame_counter]
    cmp ecx, 0x352
    jl short .reset_frame_counter
    mov ebx, 0xc8
    mov ch, 0x10
    mov dword [eax + actor_frame_counter], ebx
    mov byte [edx + actor_sequence_initial], ch
    jmp short .check_random_action

.reset_frame_counter:
    mov dword [eax + actor_frame_counter], 0xffffff38
    mov cl, 4
    mov ebp, dword [eax + actor_frame_counter]
    mov byte [edx + actor_sequence_initial], cl
    mov edx, dword [action_clock]
    add edx, ebp
    cmp edx, 0x190
    jg short .check_random_action
    mov word [ebx + sprite_tile], si

.check_random_action:
    cmp word [advance_clock], 0
    je short .check_action
    movsx edx, word [esp]
    add edx, edx
    cmp word [edx + actor_action], 0
    jne short .check_action
    cmp dword [action_clock], 0x190
    jg short .check_action
    call random_value
    xor ah, ah
    and al, 0x3f
    movsx ebx, ax
    cmp ebx, 0x10
    jge short .check_action
    and al, 1
    cwde
    cmp eax, 1
    setne al
    xor ah, ah
    inc eax
    mov word [edx + actor_action], ax
    movsx eax, word [esp]
    mov edx, dword [actor_clock]
    mov dword [nosplit eax*4 + actor_last_frame_clock], edx

.check_action:
    movsx ebx, word [esp]
    lea eax, [ebx + ebx]
    cmp word [eax + actor_action], 0
    jle near .move_along_sprite_angle
    mov edx, dword [actor_clock]
    sub edx, dword [nosplit ebx*4 + actor_last_frame_clock]
    cmp edx, 0x32
    jge near .clear_action
    movsx ebx, word [esp + 0x1c]
    imul ebx, ebx, 0x2c
    movsx ebx, word [ebx + sprite_angle]
    lea edx, [ebx + 0x400]
    and edx, 0x7ff
    mov esi, dword [ticks_per_step]
    movsx edx, word [nosplit edx*2 + sine_table]
    imul edx, esi
    add ebx, 0x200
    and ebx, 0x7ff
    movsx ebx, word [nosplit ebx*2 + sine_table]
    imul ebx, esi
    movsx eax, word [eax + actor_action]
    shl edx, 3
    shl ebx, 3
    cmp eax, 2
    jne short .scale_action_motion
    neg edx
    neg ebx

.scale_action_motion:
    movsx ebp, word [esp + 0x1c]
    imul esi, ebp, 0x2c
    mov eax, dword [esi + sprite_x]
    mov dword [esp + 0xc], eax
    mov eax, dword [esi + sprite_y]
    mov dword [esp + 8], eax
    mov eax, dword [esi + sprite_z]
    mov dword [esp + 4], eax
    mov ax, word [esi + sprite_sector]
    push 0
    mov dword [esp + 0x1c], eax
    xor eax, eax
    push strict dword 0xe40
    mov al, byte [esi + sprite_xrepeat]
    push strict dword 0x1c80
    shl eax, 2
    push eax
    push ebx
    lea ecx, [esp + 0x2c]
    lea eax, [esp + 0x20]
    push edx
    lea ebx, [esp + 0x1c]
    lea edx, [esp + 0x20]
    call clipmove
    movsx edx, word [esi + sprite_sector]
    movsx ebx, word [esp + 0x18]
    mov ecx, edx
    mov eax, ebx
    shl ecx, 2
    shl eax, 2
    add ecx, edx
    lea edx, [ebx + eax]
    shl edx, 3
    shl ecx, 3
    mov eax, dword [edx + sector_floor_z]
    sub eax, dword [ecx + sector_floor_z]
    cmp eax, strict dword 0xc00
    jge near .check_attack_clock
    cmp word [esp + 0x18], 0
    jl near .check_attack_clock
    movsx eax, word [edx + sector_hitag]
    test ah, 0x80
    jne near .check_attack_clock
    mov eax, dword [esp + 0xc]
    mov dword [esi + sprite_x], eax
    mov eax, dword [esp + 8]
    mov dword [esi + sprite_y], eax
    xor ecx, ecx
    movsx eax, word [esi + sprite_tile]
    mov cl, byte [esi + sprite_yrepeat]
    movsx eax, word [nosplit eax*2 + tile_height]
    imul eax, ecx
    add eax, eax
    movsx ecx, word [esp]
    mov dword [esp + 0x10], eax
    mov eax, dword [edx + sector_floor_z]
    mov edx, dword [nosplit ecx*4 + actor_z_offset]
    mov ecx, dword [esp + 0x10]
    add eax, edx
    sub eax, ecx
    mov dx, word [esi + sprite_sector]
    mov dword [esi + sprite_z], eax
    cmp dx, word [esp + 0x18]
    je short .check_attack_clock
    mov edx, ebx
    mov eax, ebp
    call change_sprite_sector
    jmp short .check_attack_clock

.clear_action:
    xor esi, esi
    mov word [eax + actor_action], si
    jmp short .check_attack_clock

.move_along_sprite_angle:
    mov esi, dword [action_clock]
    cmp esi, 0x11d
    jle short .check_attack_clock
    cmp esi, 0x181
    jge short .check_attack_visibility
    mov word [actor_target], 1

.check_attack_visibility:
    movsx eax, word [esp]
    movsx ecx, word [player_sector]
    mov ebx, dword [player_y]
    mov edx, dword [player_x]
    call check_attack_target
    xor ecx, ecx
    mov word [actor_target], cx

.check_attack_clock:
    cmp word [advance_clock], 0
    je near .return
    cmp dword [action_clock], 0x11d
    jg near .return
    movsx edx, word [esp + 0x1c]
    imul edx, edx, 0x2c
    mov ebp, dword [player_z]
    mov eax, dword [edx + sprite_z]
    sub eax, ebp
    call absolute_long
    cmp eax, strict dword 0x1388
    jge near .return
    call random_value
    xor ah, ah
    and al, 0x1f
    cwde
    cmp eax, 0x1f
    jne short .check_other_attack_frame
    movsx eax, word [esp + 0x14]
    cmp eax, 0x3c
    jge near .return
    cmp word [player_hit_timer], 0
    jne near .return
    mov eax, 1
    mov ebx, 0xfffffff1
    add edi, 0x45
    mov word [defer_mode_change], ax
    mov word [edx + sprite_tile], di
    xor eax, eax
    mov edx, dword [actor_clock]
    mov dword [player_hit_x], eax
    mov dword [player_hit_y], eax
    movsx eax, word [esp]
    mov word [player_hit_timer], bx
    mov dword [nosplit eax*4 + actor_last_frame_clock], edx
    jmp near .return

.check_other_attack_frame:
    cmp eax, 0x10
    jge near .return
    movsx ebx, word [esp]
    xor ecx, ecx
    mov word [nosplit ebx*2 + actor_action], cx
    call random_value
    xor ah, ah
    and al, 1
    shl ebx, 2
    test ax, ax
    jne short .second_attack_frame
    mov eax, dword [actor_clock]
    add edi, 0x3b
    mov dword [ebx + actor_last_frame_clock], eax
    mov eax, 0xffffffce
    mov word [edx + sprite_tile], di
    call adjust_status_value
    call random_value
    mov edx, eax
    mov ebx, 4
    sar edx, 0x1f
    idiv ebx
    xor ecx, ecx
    lea eax, [edx + 0x17]
    jmp near .play_player_hit_sound

.second_attack_frame:
    mov eax, dword [actor_clock]
    add edi, 0x3d
    mov dword [ebx + actor_last_frame_clock], eax
    mov eax, 0xffffffce
    mov word [edx + sprite_tile], di
    call adjust_status_value
    call random_value
    mov edx, eax
    mov ebx, 4
    sar edx, 0x1f
    idiv ebx
    xor ecx, ecx
    lea eax, [edx + 0x17]
    xor ebx, ebx
    xor edx, edx

.play_sound_and_return:
    call play_sound

.return:
    add esp, 0x20
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
