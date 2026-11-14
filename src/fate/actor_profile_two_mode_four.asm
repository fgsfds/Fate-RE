; Move toward the stored destination until player visibility or nearby activity triggers engagement.
BITS 32
ORG 0x1711b

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
update_actor_profile_two_mode_two equ 0x15e07
actor_engaged equ 0x7e0f8
mode_two_tile equ 0x7abc4
mode_five_tile equ 0x7abca
player_action equ 0x2297
actor_visibility_timer equ 0x7f48a
actor_destination_x equ 0x729fc
actor_destination_y equ 0x72a00
actor_destination_parameter_one equ 0x72a04
actor_destination_parameter_two equ 0x72a08

update_actor_profile_two_mode_four:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x8
    push eax
    mov eax, edx
    movsx esi, word [esp]
    xor edx, edx
    mov dl, [esi + actor_engaged]
    mov di, [nosplit esi*2 + actor_sprite_index]
    cmp edx, 0x1
    jnz near .update_patrol
    mov edx, esi
    shl edx, byte 0x3
    mov al, 0x8
    add edx, esi
    mov [esi + actor_sequence_initial], al
    movsx eax, word [nosplit edx*2 + mode_two_tile]
    push eax
    movsx eax, word [player_sector]
    mov ebp, [player_z]
    push eax
    mov ecx, [player_y]
    mov ebx, [player_x]
    push ebp
    xor edx, edx
    mov eax, esi
    call update_actor_profile_two_mode_two
    movsx eax, word [player_sector]
    push eax
    mov eax, [player_z]
    push eax
    mov edx, [player_y]
    push edx
    movsx edx, di
    imul edx, edx, 0x2c
    mov ebx, [player_x]
    push ebx
    movsx ecx, word [edx + sprite_sector]
    mov ebx, [edx + sprite_z]
    mov eax, [edx + sprite_y]
    mov ebp, [edx + sprite_x]
    mov edx, eax
    mov eax, ebp
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
    xor bl, bl
    mov [eax + actor_engaged], bl
    jmp near .return

.update_patrol:
    mov byte [esi + actor_sequence_initial], 0x8
    xor edx, edx
    mov dl, [esi + actor_kind]
    cmp edx, 0x3
    jz near .return
    cmp edx, 0x4
    jz short .hold_reaction_frame
    cmp edx, 0x5
    jnz short .check_patrol_tile

.hold_reaction_frame:
    mov edx, eax
    movsx eax, di
    imul eax, eax, 0x2c
    add edx, 0x2d
    mov [eax + sprite_tile], dx
    jmp near .check_player_action

.check_patrol_tile:
    test dl, dl
    jnz short .select_offset_patrol_tile
    movsx edx, di
    imul edx, edx, 0x2c
    mov [edx + sprite_tile], ax
    jmp short .load_actor_destination

.select_offset_patrol_tile:
    mov edx, eax
    movsx eax, di
    imul eax, eax, 0x2c
    add edx, 0x5
    mov [eax + sprite_tile], dx

.load_actor_destination:
    movsx ebp, word [esp]
    mov edx, ebp
    mov esi, ebp
    shl edx, byte 0x4
    shl esi, byte 0x2
    mov eax, [edx + actor_destination_x]
    mov [esi + actor_x], eax
    mov eax, [edx + actor_destination_y]
    mov ebx, actor_sector
    mov [esi + actor_y], eax
    mov eax, [edx + actor_destination_parameter_one]
    lea ecx, [ebp + ebp + 0x0]
    mov [esp + 0x4], eax
    mov eax, [edx + actor_destination_parameter_two]
    add ebx, ecx
    mov [esp + 0x8], eax
    mov edx, [esi + actor_y]
    mov eax, [esi + actor_x]
    call update_sector
    movsx ecx, word [ecx + actor_sector]
    cmp ecx, -1
    jz short .test_player_visibility
    xor eax, eax
    mov al, [ebp + actor_kind]
    cmp eax, 0x4
    jz short .test_player_visibility
    mov edx, [esp + 0x8]
    push edx
    mov ebx, [esp + 0x8]
    mov eax, ebp
    push ebx
    mov edx, [esi + actor_x]
    mov ebx, [esi + actor_y]
    call move_actor

.test_player_visibility:
    movsx eax, word [player_sector]
    push eax
    mov ecx, [player_z]
    push ecx
    mov esi, [player_y]
    push esi
    movsx esi, di
    imul esi, esi, 0x2c
    mov ebp, [player_x]
    push ebp
    movsx ecx, word [esi + sprite_sector]
    mov ebx, [esi + sprite_z]
    mov edx, [esi + sprite_y]
    mov eax, [esi + sprite_x]
    call cansee
    mov ebx, eax
    mov edx, [esi + sprite_y]
    mov eax, [player_y]
    sub eax, edx
    mov ecx, [esi + sprite_x]
    mov edx, eax
    mov eax, [player_x]
    sub eax, ecx
    call get_angle
    mov dx, [esi + sprite_angle]
    cwde
    movsx edx, dx
    sub eax, edx
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
    jnl near .check_player_action
    movsx eax, bx
    cmp eax, 0x1
    jnz near .check_player_action
    movsx edx, word [esp]
    mov byte [edx + actor_engaged], 0x1
    mov bh, 0x1e
    mov eax, edx
    mov [edx + actor_visibility_timer], bh
    shl edx, byte 0x3
    add edx, eax
    mov ax, [nosplit edx*2 + mode_five_tile]
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
    movsx eax, di
    imul eax, eax, 0x2c
    mov ebx, [eax + sprite_y]
    mov esi, [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x5
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x1f]
    jmp short .play_sight_sound

.choose_second_sight_sound:
    movsx edx, di
    imul edx, edx, 0x2c
    mov ebx, [edx + sprite_y]
    mov esi, [edx + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 0x2
    sar edx, byte 0x1f
    idiv ecx
    lea eax, [edx + 0x38]
    jmp short .play_sight_sound

.choose_third_sight_sound:
    movsx eax, di
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
    movsx eax, di
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
    movsx esi, di
    imul esi, esi, 0x2c
    movsx edx, word [esp]
    xor cl, cl
    mov ebx, [esi + sprite_x]
    mov [edx + actor_delay_byte], cl
    mov [nosplit edx*4 + actor_x], ebx
    mov ebx, [esi + sprite_y]
    mov ch, 0x2
    mov [nosplit edx*4 + actor_y], ebx
    mov bx, [esi + sprite_sector]
    mov [edx + actor_kind], ch
    mov [nosplit edx*2 + actor_sector], bx

.check_player_action:
    movsx eax, word [player_action]
    cmp eax, 0x1
    jnz near .check_second_player_action
    movsx edx, di
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
    movsx esi, word [esp]
    mov byte [esi + actor_engaged], 0x1
    mov bh, 0x1e
    mov eax, esi
    mov [esi + actor_visibility_timer], bh
    shl esi, byte 0x3
    add esi, eax
    mov ax, [nosplit esi*2 + mode_five_tile]
    cmp ax, 0x9b8
    jc short .check_lower_tiles_first_action
    jna short .choose_second_sound_first_action
    cmp ax, 0xa02
    jc near .react_to_first_action
    jna short .choose_third_sound_first_action
    cmp ax, 0xa70
    jz near .choose_fourth_sound_first_action
    jmp near .react_to_first_action

.check_lower_tiles_first_action:
    cmp ax, 0x8f8
    jc near .react_to_first_action
    jna short .choose_first_sound_first_action
    cmp ax, 0x966
    jnz near .react_to_first_action

.choose_first_sound_first_action:
    movsx eax, di
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

.react_to_first_action:
    movsx edx, word [esp]
    xor cl, cl
    mov [edx + actor_delay_byte], cl
    mov byte [edx + actor_kind], 0x2
    jmp near .return

.check_second_player_action:
    cmp eax, 0x2
    jnz near .return
    movsx edx, di
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
    movsx esi, word [esp]
    mov byte [esi + actor_engaged], 0x1
    mov byte [esi + actor_visibility_timer], 0x1e
    mov eax, esi
    shl esi, byte 0x3
    add esi, eax
    mov ax, [nosplit esi*2 + mode_five_tile]
    cmp ax, 0x9b8
    jc short .check_lower_tiles_second_action
    jna short .choose_second_sound_second_action
    cmp ax, 0xa02
    jc near .react_to_second_action
    jna short .choose_third_sound_second_action
    cmp ax, 0xa70
    jz near .choose_fourth_sound_second_action
    jmp near .react_to_second_action

.check_lower_tiles_second_action:
    cmp ax, 0x8f8
    jc near .react_to_second_action
    jna short .choose_first_sound_second_action
    cmp ax, 0x966
    jnz near .react_to_second_action

.choose_first_sound_second_action:
    movsx eax, di
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

.react_to_second_action:
    movsx eax, word [esp]
    xor dl, dl
    mov [eax + actor_delay_byte], dl
    mov byte [eax + actor_kind], 0x2

.return:
    add esp, 0xc
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
