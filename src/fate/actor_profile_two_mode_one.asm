; Update walking, reaction, and attack frames for profile two, mode one.
BITS 32
ORG 0x14b50

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
actor_last_frame_clock equ 0x7fb64
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8
sprite_xrepeat equ 0x2040b2
ticks_per_step equ 0x7a994
sector_floor_z equ 0x27c3a8
sector_hitag equ 0x27c3c4
tile_height equ 0x1f4020
sprite_yrepeat equ 0x2040b5
actor_z_offset equ 0x79214
actor_action equ 0x80b0c
actor_frame_counter equ 0x80338
actor_sequence_initial equ 0x7e4e2
advance_clock equ 0x229b
sprite_angle equ 0x2040bc
sine_table equ 0x2300a0
actor_target equ 0x7dede
player_sector equ 0x5acfc
player_z equ 0x5ad1c

update_actor_profile_two_mode_one:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x2c
    mov edi, eax
    mov dword [esp + 0x1c], edx
    cwde
    mov dx, word [nosplit eax*2 + actor_sprite_index]
    mov dword [esp + 0x28], edx
    xor edx, edx
    mov dl, byte [eax + actor_kind]
    cmp edx, 3
    je near .return
    movsx edx, word [esp + 0x28]
    imul edx, edx, 0x2c
    movsx ebx, word [esp + 0x1c]
    add ebx, 0x3b
    movsx ecx, word [edx + sprite_tile]
    cmp ecx, ebx
    jne short .check_reaction
    cmp byte [eax + actor_kind], 0
    jne near .return
    mov eax, dword [esp + 0x1c]
    add eax, strict dword 0x32
    mov word [edx + sprite_tile], ax

.check_reaction:
    movsx eax, di
    mov al, byte [eax + actor_kind]
    and eax, 0xff
    cmp eax, 4
    je short .handle_reaction
    cmp eax, 5
    jne near .measure_target

.handle_reaction:
    cmp word [defer_mode_change], 0
    je short .choose_reaction
    movsx eax, di
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
    movsx edx, di
    xor eax, eax
    mov al, byte [edx + actor_kind]
    cmp eax, 4
    jne short .show_alternate_reaction

.show_reaction_frame:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, dword [esp + 0x1c]
    add edx, 0x3b
    mov ebx, dword [eax + sprite_y]
    mov esi, dword [eax + sprite_x]
    mov word [eax + sprite_tile], dx
    call random_value
    mov edx, eax
    mov ecx, 2
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x3a]
    jmp near .play_actor_sound

.show_alternate_reaction:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov ebx, dword [esp + 0x1c]
    add ebx, 0x3c
    mov word [eax + sprite_tile], bx
    xor bh, bh
    mov esi, dword [eax + sprite_x]
    mov byte [edx + actor_kind], bh
    mov ebx, dword [eax + sprite_y]
    call random_value
    mov edx, eax
    mov ecx, 2
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x3a]
    xor ecx, ecx
    mov edx, esi
    call play_sound

.measure_target:
    movsx ebx, word [esp + 0x28]
    imul ebx, ebx, 0x2c
    mov edx, dword [player_x]
    mov eax, dword [ebx + sprite_x]
    sub eax, edx
    mov dword [esp + 0xc], eax
    imul eax, eax
    mov esi, dword [player_y]
    mov ecx, dword [ebx + sprite_y]
    sub ecx, esi
    mov edx, ecx
    imul edx, ecx
    add eax, edx
    call integer_square_root
    mov ebp, eax
    mov edx, ecx
    mov eax, dword [esp + 0xc]
    call get_angle
    mov si, word [player_angle]
    movsx edx, ax
    movsx eax, si
    sub edx, eax
    mov eax, edx
    call absolute_int
    mov dx, word [ebx + sprite_tile]
    movsx eax, dx
    movsx esi, word [esp + 0x1c]
    mov dword [esp + 0x14], eax
    lea eax, [esi + 0x3c]
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x14]
    cmp eax, dword [esp + 0x18]
    jl near .check_stationary_frames
    lea eax, [esi + 0x3f]
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x14]
    cmp eax, dword [esp + 0x18]
    jg near .check_stationary_frames
    lea eax, [esi + 0x3d]
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x1c]
    lea ebp, [esi + 0x3e]
    add eax, strict dword 0x32
    mov esi, dword [esp + 0x18]
    mov dword [esp + 0x24], eax
    cmp esi, dword [esp + 0x14]
    jne short .advance_walk_frame
    movsx eax, di
    shl eax, 2
    mov esi, dword [actor_clock]
    sub esi, dword [eax + actor_last_frame_clock]
    cmp esi, 0x14
    jle short .move_toward_target
    mov esi, dword [actor_clock]
    inc edx
    mov dword [eax + actor_last_frame_clock], esi
    movsx eax, dx
    mov word [ebx + sprite_tile], dx
    cmp eax, ebp
    jle short .move_toward_target
    jmp short .wrap_walk_frame

.advance_walk_frame:
    movsx eax, di
    shl eax, 2
    mov esi, dword [actor_clock]
    sub esi, dword [eax + actor_last_frame_clock]
    cmp esi, 0xa
    jle short .move_toward_target
    mov esi, dword [actor_clock]
    inc edx
    mov dword [eax + actor_last_frame_clock], esi
    movsx eax, dx
    mov word [ebx + sprite_tile], dx
    cmp eax, ebp
    jle short .move_toward_target

.wrap_walk_frame:
    mov eax, dword [esp + 0x24]
    mov word [ebx + sprite_tile], ax

.move_toward_target:
    movsx ebp, word [esp + 0x28]
    imul esi, ebp, 0x2c
    mov eax, dword [esi + sprite_x]
    mov dword [esp + 8], eax
    mov eax, dword [esi + sprite_y]
    mov dword [esp + 4], eax
    mov eax, dword [esi + sprite_z]
    mov dword [esp], eax
    mov ax, word [esi + sprite_sector]
    push 0
    mov dword [esp + 0x24], eax
    xor eax, eax
    push strict dword 0xe40
    mov al, byte [esi + sprite_xrepeat]
    push strict dword 0x1c80
    shl eax, 2
    push eax
    imul ecx, dword [ticks_per_step]
    mov edx, dword [ticks_per_step]
    mov eax, dword [esp + 0x1c]
    imul eax, edx
    shl ecx, 0xa
    lea ebx, [esp + 0x10]
    push ecx
    shl eax, 0xa
    lea ecx, [esp + 0x34]
    push eax
    lea edx, [esp + 0x1c]
    lea eax, [esp + 0x20]
    call clipmove
    movsx edx, word [esi + sprite_sector]
    movsx ebx, word [esp + 0x20]
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
    jge near .return
    cmp word [esp + 0x20], 0
    jl near .return
    movsx eax, word [edx + sector_hitag]
    test ah, 0x80
    jne near .return
    mov eax, dword [esp + 8]
    mov dword [esi + sprite_x], eax
    mov eax, dword [esp + 4]
    mov dword [esi + sprite_y], eax
    movsx eax, word [esi + sprite_tile]
    movsx eax, word [nosplit eax*2 + tile_height]
    mov dword [esp + 0x18], eax
    xor eax, eax
    mov ecx, dword [esp + 0x18]
    mov al, byte [esi + sprite_yrepeat]
    imul eax, ecx
    add eax, eax
    movsx ecx, di
    mov dword [esp + 0x18], eax
    mov edi, dword [nosplit ecx*4 + actor_z_offset]
    mov eax, dword [edx + sector_floor_z]
    mov edx, dword [esp + 0x18]
    add eax, edi
    sub eax, edx
    mov dx, word [esi + sprite_sector]
    mov dword [esi + sprite_z], eax
    cmp dx, word [esp + 0x20]
    je near .return
    mov edx, ebx
    mov eax, ebp
    call change_sprite_sector
    jmp near .return

.check_stationary_frames:
    movsx ebx, word [esp + 0x1c]
    mov esi, dword [esp + 0x1c]
    movsx eax, dx
    lea ecx, [ebx + 0x2d]
    add esi, 0x32
    cmp eax, ecx
    jne short .check_first_frame_range
    movsx edx, di
    mov eax, dword [actor_clock]
    sub eax, dword [nosplit edx*4 + actor_last_frame_clock]
    cmp eax, 0x32
    jle near .return
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov word [eax + sprite_tile], si
    xor ah, ah
    mov byte [edx + actor_kind], ah
    jmp near .return

.check_first_frame_range:
    lea ecx, [ebx + 0x36]
    cmp eax, ecx
    jl short .check_second_frame_range
    add ebx, 0x37
    cmp eax, ebx
    jg short .check_second_frame_range
    movsx eax, di
    shl eax, 2
    mov edx, dword [actor_clock]
    sub edx, dword [eax + actor_last_frame_clock]
    cmp edx, 0xa
    jle near .return
    mov edx, dword [actor_clock]
    mov dword [eax + actor_last_frame_clock], edx
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov di, word [eax + sprite_tile]
    inc edi
    movsx edx, di
    mov word [eax + sprite_tile], di
    cmp edx, ebx
    jle near .return
    mov word [eax + sprite_tile], si
    jmp near .return

.check_second_frame_range:
    movsx eax, word [esp + 0x1c]
    movsx edx, dx
    lea ebx, [eax + 0x38]
    cmp edx, ebx
    jl short .prepare_action
    lea ebx, [eax + 0x3a]
    cmp edx, ebx
    jg short .prepare_action
    movsx eax, di
    shl eax, 2
    mov edx, dword [actor_clock]
    sub edx, dword [eax + actor_last_frame_clock]
    cmp edx, 0xa
    jle near .return
    mov edx, dword [actor_clock]
    mov dword [eax + actor_last_frame_clock], edx
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov si, word [eax + sprite_tile]
    inc esi
    movsx edx, si
    mov word [eax + sprite_tile], si
    cmp edx, ebx
    jle near .return
    mov edx, dword [esp + 0x1c]
    add edx, 0x32
    mov word [eax + sprite_tile], dx
    jmp near .return

.prepare_action:
    movsx edx, di
    mov ecx, dword [esp + 0x1c]
    mov bx, word [nosplit edx*2 + actor_action]
    add ecx, 0x32
    test bx, bx
    jle short .choose_idle_frame
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov word [eax + sprite_tile], cx
    jmp short .check_action

.choose_idle_frame:
    movsx ebx, word [esp + 0x28]
    imul ebx, ebx, 0x2c
    mov eax, dword [esp + 0x1c]
    add eax, strict dword 5
    mov word [ebx + sprite_tile], ax
    mov eax, edx
    shl eax, 2
    mov esi, dword [eax + actor_frame_counter]
    add esi, ebp
    cmp esi, 0x352
    jl short .reset_frame_counter
    mov dword [eax + actor_frame_counter], 0xc8
    mov byte [edx + actor_sequence_initial], 8
    jmp short .check_action

.reset_frame_counter:
    mov esi, 0xffffff38
    mov dword [eax + actor_frame_counter], esi
    lea eax, [esi + ebp]
    mov byte [edx + actor_sequence_initial], 4
    cmp eax, strict dword 0x190
    jg short .check_action
    mov word [ebx + sprite_tile], cx

.check_action:
    cmp word [advance_clock], 0
    je short .check_action_frame
    movsx edx, di
    add edx, edx
    cmp word [edx + actor_action], 0
    jne short .check_action_frame
    cmp ebp, 0x190
    jg short .check_action_frame
    call random_value
    xor ah, ah
    and al, 0x3f
    movsx ebx, ax
    cmp ebx, 0x10
    jge short .check_action_frame
    and al, 1
    cwde
    cmp eax, 1
    setne al
    xor ah, ah
    inc eax
    mov word [edx + actor_action], ax
    movsx eax, di
    mov edx, dword [actor_clock]
    mov dword [nosplit eax*4 + actor_last_frame_clock], edx

.check_action_frame:
    movsx ebx, di
    lea eax, [ebx + ebx]
    cmp word [eax + actor_action], 0
    jle near .check_attack_distance
    mov edx, dword [actor_clock]
    sub edx, dword [nosplit ebx*4 + actor_last_frame_clock]
    cmp edx, 0x32
    jge near .clear_action
    movsx ebx, word [esp + 0x28]
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
    jne short .move_along_sprite_angle
    neg edx
    neg ebx

.move_along_sprite_angle:
    movsx eax, word [esp + 0x28]
    mov dword [esp + 0x10], eax
    imul esi, eax, 0x2c
    mov eax, dword [esi + sprite_x]
    mov dword [esp + 8], eax
    mov eax, dword [esi + sprite_y]
    mov dword [esp + 4], eax
    mov eax, dword [esi + sprite_z]
    mov dword [esp], eax
    mov ax, word [esi + sprite_sector]
    push 0
    mov dword [esp + 0x24], eax
    xor eax, eax
    push strict dword 0xe40
    mov al, byte [esi + sprite_xrepeat]
    push strict dword 0x1c80
    shl eax, 2
    push eax
    push ebx
    lea ecx, [esp + 0x34]
    lea eax, [esp + 0x1c]
    push edx
    lea ebx, [esp + 0x18]
    lea edx, [esp + 0x1c]
    call clipmove
    movsx edx, word [esi + sprite_sector]
    movsx ebx, word [esp + 0x20]
    mov ecx, edx
    mov eax, ebx
    shl ecx, 2
    shl eax, 2
    add ecx, edx
    lea edx, [ebx + eax]
    shl edx, 3
    mov eax, dword [edx + sector_floor_z]
    shl ecx, 3
    mov dword [esp + 0x18], eax
    mov eax, dword [ecx + sector_floor_z]
    mov ecx, dword [esp + 0x18]
    sub ecx, eax
    cmp ecx, 0xc00
    jge near .check_attack_clock
    cmp word [esp + 0x20], 0
    jl near .check_attack_clock
    movsx eax, word [edx + sector_hitag]
    test ah, 0x80
    jne near .check_attack_clock
    mov eax, dword [esp + 8]
    mov dword [esi + sprite_x], eax
    mov eax, dword [esp + 4]
    mov dword [esi + sprite_y], eax
    movsx eax, word [esi + sprite_tile]
    movsx eax, word [nosplit eax*2 + tile_height]
    mov dword [esp + 0x18], eax
    xor eax, eax
    mov ecx, dword [esp + 0x18]
    mov al, byte [esi + sprite_yrepeat]
    imul eax, ecx
    add eax, eax
    movsx ecx, di
    mov dword [esp + 0x18], eax
    mov eax, dword [edx + sector_floor_z]
    mov edx, dword [nosplit ecx*4 + actor_z_offset]
    mov ecx, dword [esp + 0x18]
    add eax, edx
    sub eax, ecx
    mov dx, word [esi + sprite_sector]
    mov dword [esi + sprite_z], eax
    cmp dx, word [esp + 0x20]
    je short .check_attack_clock
    mov eax, dword [esp + 0x10]
    mov edx, ebx
    call change_sprite_sector
    jmp short .check_attack_clock

.clear_action:
    xor esi, esi
    mov word [eax + actor_action], si
    jmp short .check_attack_clock

.check_attack_distance:
    cmp ebp, 0x11d
    jle short .check_attack_clock
    cmp ebp, 0x181
    jge short .check_attack_visibility
    mov word [actor_target], 1

.check_attack_visibility:
    movsx ecx, word [player_sector]
    mov ebx, dword [player_y]
    mov edx, dword [player_x]
    movsx eax, di
    call check_attack_target
    xor ecx, ecx
    mov word [actor_target], cx

.check_attack_clock:
    cmp word [advance_clock], 0
    je near .return
    cmp ebp, 0x11d
    jg near .return
    movsx edx, word [esp + 0x28]
    imul edx, edx, 0x2c
    mov esi, dword [player_z]
    mov eax, dword [edx + sprite_z]
    sub eax, esi
    call absolute_long
    cmp eax, strict dword 0x1388
    jge near .return
    call random_value
    xor ah, ah
    and al, 0x1f
    cwde
    cmp eax, 0x10
    jge near .return
    movsx ebx, di
    xor ecx, ecx
    mov word [nosplit ebx*2 + actor_action], cx
    call random_value
    xor ah, ah
    and al, 1
    shl ebx, 2
    test ax, ax
    jne short .second_attack_frame
    mov eax, dword [esp + 0x1c]
    add eax, strict dword 0x36
    mov word [edx + sprite_tile], ax
    mov eax, dword [actor_clock]
    mov dword [ebx + actor_last_frame_clock], eax
    mov eax, 0xffffffce
    call adjust_status_value
    mov ebx, dword [edx + sprite_y]
    mov esi, dword [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 3
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x32]
    jmp short .play_actor_sound

.second_attack_frame:
    mov eax, dword [esp + 0x1c]
    add eax, strict dword 0x38
    mov word [edx + sprite_tile], ax
    mov eax, dword [actor_clock]
    mov dword [ebx + actor_last_frame_clock], eax
    mov eax, 0xffffffce
    call adjust_status_value
    mov ebx, dword [edx + sprite_y]
    mov esi, dword [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 3
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x35]

.play_actor_sound:
    xor ecx, ecx
    mov edx, esi
    call play_sound

.return:
    add esp, 0x2c
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
