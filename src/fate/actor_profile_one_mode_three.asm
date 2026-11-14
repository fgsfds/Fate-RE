; Patrol waypoints until player visibility or nearby activity triggers engagement.
BITS 32
ORG 0x18a37

random_value equ 0x602d0
play_sound equ 0x34f79
get_angle equ 0x4c94c
absolute_int equ 0x6032c
absolute_long equ 0x602c3
actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_tile equ 0x2040ae
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
player_x equ 0x5ad9c
player_y equ 0x5ad5c
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8
actor_sequence_initial equ 0x7e4e2
advance_clock equ 0x229b
sprite_angle equ 0x2040bc
player_sector equ 0x5acfc
player_z equ 0x5ad1c
actor_delay_byte equ 0x7df03
actor_x equ 0x799e8
actor_y equ 0x7a1bc
actor_sector equ 0x7d2e4
cansee equ 0x50d33
update_sector equ 0x542c4
move_actor equ 0x196b2
update_actor_profile_one_mode_two equ 0x163f2
actor_engaged equ 0x7e0f8
mode_two_tile equ 0x7abc4
mode_five_tile equ 0x7abca
player_action equ 0x2297
actor_visibility_timer equ 0x7f48a
actor_first_waypoint equ 0x78a40
actor_next_waypoint equ 0x78a42
waypoint_x equ 0x229d
waypoint_y equ 0x22a1

update_actor_profile_one_mode_three:
    push ebx
    push ecx
    push esi
    push edi
    sub esp, 0x4
    push eax
    movsx esi, ax
    mov ax, [nosplit esi*2 + actor_sprite_index]
    mov [esp + 0x4], eax
    xor eax, eax
    mov al, [esi + actor_engaged]
    cmp eax, 0x1
    jnz near .update_patrol
    mov eax, esi
    shl eax, byte 0x3
    add eax, esi
    mov dl, 0x10
    movsx eax, word [nosplit eax*2 + mode_two_tile]
    mov ecx, [player_y]
    push eax
    movsx eax, word [player_sector]
    mov [esi + actor_sequence_initial], dl
    push eax
    mov edx, [player_z]
    mov ebx, [player_x]
    push edx
    mov eax, esi
    xor edx, edx
    call update_actor_profile_one_mode_two
    movsx eax, word [player_sector]
    push eax
    movsx eax, word [esp + 0x8]
    imul eax, eax, 0x2c
    mov ebx, [player_z]
    push ebx
    mov ecx, [player_y]
    push ecx
    mov edi, [player_x]
    push edi
    movsx ecx, word [eax + sprite_sector]
    mov ebx, [eax + sprite_z]
    mov edx, [eax + sprite_y]
    mov eax, [eax + sprite_x]
    call cansee
    cwde
    cmp eax, 0x1
    jnz short .decay_visibility_timer
    mov byte [esi + actor_visibility_timer], 0x1e
    jmp short .check_visibility_timer

.decay_visibility_timer:
    cmp word [advance_clock], 0x0
    jz short .check_visibility_timer
    dec byte [esi + actor_visibility_timer]

.check_visibility_timer:
    movsx eax, word [esp]
    cmp byte [eax + actor_visibility_timer], 0x0
    ja near .return
    xor cl, cl
    mov [eax + actor_engaged], cl
    jmp near .return

.update_patrol:
    mov byte [esi + actor_sequence_initial], 0x6
    xor eax, eax
    mov al, [esi + actor_kind]
    cmp eax, 0x3
    jz near .return
    cmp eax, 0x4
    jz short .hold_reaction_frame
    cmp eax, 0x5
    jnz short .select_patrol_tile

.hold_reaction_frame:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    add edx, 0x5f
    mov [eax + sprite_tile], dx
    jmp near .check_player_action

.select_patrol_tile:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    add edx, 0x5
    movsx edi, word [esp]
    mov [eax + sprite_tile], dx

.read_waypoint:
    mov esi, edi
    shl esi, byte 0x2
    mov ax, [esi + actor_next_waypoint]
    cwde
    shl eax, byte 0x3
    mov edx, [eax + waypoint_x]
    mov [esi + actor_x], edx
    cmp edx, -1
    jnz short .resolve_waypoint_sector
    mov ax, [esi + actor_first_waypoint]
    mov [esi + actor_next_waypoint], ax
    jmp short .read_waypoint

.resolve_waypoint_sector:
    mov ebx, actor_sector
    mov eax, [eax + waypoint_y]
    lea ecx, [edi + edi]
    mov edx, eax
    add ebx, ecx
    mov [esi + actor_y], eax
    mov eax, [esi + actor_x]
    call update_sector
    movsx ecx, word [ecx + actor_sector]
    cmp ecx, -1
    jz short .test_player_visibility
    xor eax, eax
    mov al, [edi + actor_kind]
    cmp eax, 0x4
    jz short .test_player_visibility
    push strict byte 0x0
    mov eax, edi
    push strict byte 0x0
    mov ebx, [esi + actor_y]
    mov edx, [esi + actor_x]
    call move_actor
    cmp byte [edi + actor_kind], 0x0
    jnz short .test_player_visibility
    inc word [esi + actor_next_waypoint]

.test_player_visibility:
    movsx esi, word [esp + 0x4]
    imul esi, esi, 0x2c
    movsx eax, word [player_sector]
    push eax
    mov eax, [player_z]
    push eax
    mov edx, [player_y]
    push edx
    mov ebx, [player_x]
    push ebx
    movsx ecx, word [esi + sprite_sector]
    mov ebx, [esi + sprite_z]
    mov edx, [esi + sprite_y]
    mov eax, [esi + sprite_x]
    call cansee
    mov edx, [player_y]
    mov ebx, eax
    mov ecx, [esi + sprite_y]
    mov edi, [esi + sprite_x]
    mov eax, [player_x]
    sub edx, ecx
    sub eax, edi
    call get_angle
    mov dx, [esi + sprite_angle]
    movsx ecx, ax
    movsx eax, dx
    sub ecx, eax
    mov eax, ecx
    call absolute_int
    movsx ecx, ax
    mov edx, eax
    cmp ecx, strict dword 0x400
    jng short .check_view_cone
    mov edx, 0x7ff
    sub edx, eax

.check_view_cone:
    movsx eax, dx
    cmp eax, strict dword 0x2aa
    jg near .check_player_action
    movsx eax, bx
    cmp eax, 0x1
    jnz near .check_player_action
    movsx eax, word [esp]
    mov byte [eax + actor_engaged], 0x1
    mov byte [eax + actor_visibility_timer], 0x1e
    mov edx, eax
    shl eax, byte 0x3
    add eax, edx
    mov ax, [nosplit eax*2 + mode_five_tile]
    cmp ax, 0x9b8
    jc short .check_lower_sight_sound_tiles
    jna short .choose_second_sight_sound
    cmp ax, 0xa02
    jc near .engage_visible_player
    jna near .choose_third_sight_sound
    cmp ax, 0xa70
    jz near .choose_fourth_sight_sound
    jmp near .engage_visible_player

.check_lower_sight_sound_tiles:
    cmp ax, 0x8f8
    jc near .engage_visible_player
    jna short .choose_first_sight_sound
    cmp ax, 0x966
    jnz near .engage_visible_player

.choose_first_sight_sound:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x5
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x1f]
    jmp near .play_sight_sound

.choose_second_sight_sound:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x2
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x38]
    jmp short .play_sight_sound

.choose_third_sight_sound:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x3
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x54]
    jmp short .play_sight_sound

.choose_fourth_sight_sound:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x3
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x46]

.play_sight_sound:
    mov ecx, 0x4
    mov edx, esi
    call play_sound

.engage_visible_player:
    movsx edx, word [esp + 0x4]
    imul edx, edx, 0x2c
    movsx eax, word [esp]
    mov ebx, [edx + sprite_x]
    mov [nosplit eax*4 + actor_x], ebx
    mov ebx, [edx + sprite_y]
    mov [nosplit eax*4 + actor_y], ebx
    mov ebx, eax
    xor bl, al
    mov dx, [edx + sprite_sector]
    mov [eax + actor_delay_byte], bl
    mov bh, 0x2
    mov [nosplit eax*2 + actor_sector], dx
    mov [eax + actor_kind], bh

.check_player_action:
    movsx eax, word [player_action]
    cmp eax, 0x1
    jnz near .check_second_player_action
    movsx edx, word [esp + 0x4]
    imul edx, edx, 0x2c
    mov eax, [player_x]
    sub eax, [edx + sprite_x]
    call absolute_long
    cmp eax, strict dword 0xbb8
    jg near .return
    mov eax, [player_y]
    sub eax, [edx + sprite_y]
    call absolute_long
    cmp eax, strict dword 0xbb8
    jg near .return
    movsx eax, word [esp]
    mov byte [eax + actor_engaged], 0x1
    mov byte [eax + actor_visibility_timer], 0x1e
    mov ebx, eax
    shl eax, byte 0x3
    add eax, ebx
    mov ax, [nosplit eax*2 + mode_five_tile]
    cmp ax, 0x9b8
    jc short .check_lower_tiles_first_action
    jna short .choose_second_sound_first_action
    cmp ax, 0xa02
    jc near .reset_delay_after_first_action
    jna short .choose_third_sound_first_action
    cmp ax, 0xa70
    jz near .choose_fourth_sound_first_action
    jmp near .reset_delay_after_first_action

.check_lower_tiles_first_action:
    cmp ax, 0x8f8
    jc near .reset_delay_after_first_action
    jna short .choose_first_sound_first_action
    cmp ax, 0x966
    jnz near .reset_delay_after_first_action

.choose_first_sound_first_action:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x5
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x1f]
    jmp short .play_sound_first_action

.choose_second_sound_first_action:
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x2
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x38]
    jmp short .play_sound_first_action

.choose_third_sound_first_action:
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x3
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x54]
    jmp short .play_sound_first_action

.choose_fourth_sound_first_action:
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x3
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x46]

.play_sound_first_action:
    mov ecx, 0x4
    mov edx, esi
    call play_sound

.reset_delay_after_first_action:
    movsx eax, word [esp]
    xor cl, cl
    mov [eax + actor_delay_byte], cl
    jmp near .set_reaction_kind

.check_second_player_action:
    cmp eax, 0x2
    jnz near .return
    movsx edx, word [esp + 0x4]
    imul edx, edx, 0x2c
    mov eax, [player_x]
    sub eax, [edx + sprite_x]
    call absolute_long
    cmp eax, strict dword 0xfa0
    jg near .return
    mov eax, [player_y]
    sub eax, [edx + sprite_y]
    call absolute_long
    cmp eax, strict dword 0xfa0
    jg near .return
    movsx eax, word [esp]
    mov byte [eax + actor_engaged], 0x1
    mov ch, 0x1e
    mov ebx, eax
    mov [eax + actor_visibility_timer], ch
    shl eax, byte 0x3
    add eax, ebx
    mov ax, [nosplit eax*2 + mode_five_tile]
    cmp ax, 0x9b8
    jc short .check_lower_tiles_second_action
    jna short .choose_second_sound_second_action
    cmp ax, 0xa02
    jc near .reset_delay_after_second_action
    jna short .choose_third_sound_second_action
    cmp ax, 0xa70
    jz near .choose_fourth_sound_second_action
    jmp near .reset_delay_after_second_action

.check_lower_tiles_second_action:
    cmp ax, 0x8f8
    jc near .reset_delay_after_second_action
    jna short .choose_first_sound_second_action
    cmp ax, 0x966
    jnz near .reset_delay_after_second_action

.choose_first_sound_second_action:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x5
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x1f]
    jmp short .play_sound_second_action

.choose_second_sound_second_action:
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x2
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x38]
    jmp short .play_sound_second_action

.choose_third_sound_second_action:
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x3
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x54]
    jmp short .play_sound_second_action

.choose_fourth_sound_second_action:
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x3
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x46]

.play_sound_second_action:
    mov ecx, 0x4
    mov edx, esi
    call play_sound

.reset_delay_after_second_action:
    movsx eax, word [esp]
    xor dl, dl
    mov [eax + actor_delay_byte], dl

.set_reaction_kind:
    mov byte [eax + actor_kind], 0x2

.return:
    add esp, 0x8
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
