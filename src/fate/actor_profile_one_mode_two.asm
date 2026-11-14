; Advance two firing animations, select a target and move actor profile one in mode two.
BITS 32
ORG 0x163f2

random_value equ 0x602d0
actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_tile equ 0x2040ae
actor_recovery_counter equ 0x7f295
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8
sprite_xrepeat equ 0x2040b2
sector_floor_z equ 0x27c3a8
sector_hitag equ 0x27c3c4
tile_height equ 0x1f4020
sprite_yrepeat equ 0x2040b5
advance_clock equ 0x229b
actor_has_fired equ 0x7df03
actor_x equ 0x799e8
actor_y equ 0x7a1bc
actor_sector equ 0x7d2e4
sprite_cstat equ 0x2040ac
activate_sprite_at_position equ 0x129fc
cansee equ 0x50d33
get_z_range equ 0x562f9
update_sector equ 0x542c4
move_actor equ 0x196b2
actor_projectile_type equ 0x7eeab

update_actor_profile_one_mode_two:
    push esi
    push edi
    push ebp
    sub esp, 0x28
    push eax
    push ebx
    push ecx
    cwde
    mov bx, [nosplit eax*2 + actor_sprite_index]
    xor edi, edi
    mov [esp + 0x28], ebx
    mov al, [eax + actor_kind]
    and eax, strict dword 0xff
    cmp eax, 0x3
    jz near .return
    cmp eax, 0x4
    jz short .hold_reaction_frame
    cmp eax, 0x5
    jnz short .check_first_attack_frames

.hold_reaction_frame:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, [esp + 0x4c]
    add edx, 0x5f
    mov [eax + sprite_tile], dx
    movsx edx, word [esp + 0x8]
    mov ecx, [eax + sprite_x]
    mov [nosplit edx*4 + actor_x], ecx
    mov ecx, [eax + sprite_y]
    mov ax, [eax + sprite_sector]
    mov [nosplit edx*4 + actor_y], ecx
    mov [nosplit edx*2 + actor_sector], ax
    jmp near .return

.check_first_attack_frames:
    ; Advance each firing strip by five tiles per clock step.
    movsx eax, bx
    imul eax, eax, 0x2c
    movsx ebx, word [esp + 0x4c]
    lea esi, [ebx + 0x3c]
    movsx ecx, word [eax + sprite_tile]
    cmp ecx, esi
    jl short .check_second_attack_frames
    add ebx, 0x46
    cmp ecx, ebx
    jg short .check_second_attack_frames
    cmp word [advance_clock], 0x0
    jz near .return
    mov dx, [eax + sprite_tile]
    add edx, 0x5
    mov [eax + sprite_tile], dx
    movsx edx, dx
    cmp edx, ebx
    jng near .return
    mov edx, [esp + 0x4c]
    add edx, 0x37

.store_tile:
    mov [eax + sprite_tile], dx
    jmp near .return

.check_second_attack_frames:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    movsx ebx, word [esp + 0x4c]
    lea esi, [ebx + 0x50]
    movsx ecx, word [eax + sprite_tile]
    cmp ecx, esi
    jl short .check_sprite_target
    add ebx, 0x5a
    cmp ecx, ebx
    jg short .check_sprite_target
    cmp word [advance_clock], 0x0
    jz near .return
    mov si, [eax + sprite_tile]
    add esi, 0x5
    movsx edx, si
    mov [eax + sprite_tile], si
    cmp edx, ebx
    jng near .return
    mov edx, [esp + 0x4c]
    add edx, 0x4b
    jmp short .store_tile

.check_sprite_target:
    ; A nonzero actor target replaces the supplied player coordinates.
    test dx, dx
    jz short .check_idle_visibility
    movsx eax, dx
    mov ax, [nosplit eax*2 + actor_sprite_index]
    cwde
    imul eax, eax, 0x2c
    mov edx, [eax + sprite_x]
    mov [esp + 0x4], edx
    mov edx, [eax + sprite_y]
    xor ebx, ebx
    mov [esp], edx
    movsx edx, word [eax + sprite_tile]
    mov bl, [eax + sprite_yrepeat]
    movsx edx, word [nosplit edx*2 + tile_height]
    imul edx, ebx
    mov ebx, [eax + sprite_z]
    sub ebx, edx
    mov ax, [eax + sprite_sector]
    mov [esp + 0x44], ebx
    mov [esp + 0x48], eax

.check_idle_visibility:
    movsx esi, word [esp + 0x8]
    cmp byte [esi + actor_kind], 0x0
    jnz near .check_active_visibility
    cmp word [advance_clock], 0x0
    jz near .check_retarget
    movsx eax, word [esp + 0x48]
    push eax
    mov eax, [esp + 0x48]
    push eax
    movsx eax, word [esp + 0x30]
    imul eax, eax, 0x2c
    mov edx, [esp + 0x8]
    push edx
    mov ebx, [esp + 0x10]
    push ebx
    movsx ecx, word [eax + sprite_sector]
    mov ebx, [eax + sprite_z]
    mov edx, [eax + sprite_y]
    mov eax, [eax + sprite_x]
    call cansee
    mov [esp + 0x30], eax
    call random_value
    mov edx, eax
    xor dh, ah
    and dl, 0xf
    movsx eax, dx
    cmp eax, 0x7
    jnz short .check_visible_target
    xor eax, eax
    mov al, [esi + actor_has_fired]
    cmp eax, 0x1
    jz short .choose_new_target

.check_visible_target:
    movsx eax, word [esp + 0x30]
    cmp eax, 0x1
    jz short .check_target_sector

.choose_new_target:
    mov edi, 0x1
    jmp short .check_first_attack_start

.check_target_sector:
    movsx eax, word [esp + 0x8]
    movsx eax, word [nosplit eax*2 + actor_sector]
    cmp eax, -1
    jz short .choose_new_target
    xor edi, edi

.check_first_attack_start:
    ; Visibility and the random roll gate projectile activation from either idle tile.
    movsx ebx, word [esp + 0x28]
    imul ebx, ebx, 0x2c
    movsx eax, word [esp + 0x4c]
    add eax, 0x37
    movsx edx, word [ebx + sprite_tile]
    cmp edx, eax
    jnz short .check_second_attack_start
    call random_value
    xor ah, ah
    cwde
    cmp eax, 0x50
    jnl short .check_second_attack_start
    movsx eax, word [esp + 0x30]
    cmp eax, 0x1
    jnz short .check_second_attack_start
    mov eax, [esp + 0x4c]
    add eax, strict dword 0x3c
    movsx esi, word [esp + 0x8]
    mov [ebx + sprite_tile], ax
    xor eax, eax
    mov al, [esi + actor_projectile_type]
    mov ecx, [esp + 0x44]
    push eax
    mov edx, [esp + 0x8]
    mov ebx, [esp + 0x4]
    push strict dword 0x200
    movsx eax, word [nosplit esi*2 + actor_sprite_index]
    call activate_sprite_at_position
    mov dl, 0x1
    mov [esi + actor_recovery_counter], dl
    mov [esi + actor_has_fired], dl

.check_second_attack_start:
    movsx ebx, word [esp + 0x28]
    imul ebx, ebx, 0x2c
    movsx eax, word [esp + 0x4c]
    add eax, 0x4b
    movsx edx, word [ebx + sprite_tile]
    cmp edx, eax
    jnz near .check_retarget
    call random_value
    xor ah, ah
    cwde
    cmp eax, 0x50
    jnl near .check_retarget
    movsx eax, word [esp + 0x30]
    cmp eax, 0x1
    jnz near .check_retarget
    mov eax, [esp + 0x4c]
    add eax, strict dword 0x50
    movsx esi, word [esp + 0x8]
    mov [ebx + sprite_tile], ax
    xor eax, eax
    mov al, [esi + actor_projectile_type]
    mov ecx, [esp + 0x44]
    push eax
    mov edx, [esp + 0x8]
    mov ebx, [esp + 0x4]
    push strict dword 0x200
    movsx eax, word [nosplit esi*2 + actor_sprite_index]
    call activate_sprite_at_position
    mov bl, 0x1
    mov [esi + actor_recovery_counter], bl
    mov [esi + actor_has_fired], bl
    jmp near .check_retarget

.check_active_visibility:
    lea eax, [esi + esi]
    movsx ecx, word [eax + actor_sector]
    mov [esp + 0x1c], eax
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    mov ebp, [nosplit eax*8 + sector_floor_z]
    movsx eax, word [esp + 0x48]
    mov edx, [esp + 0x44]
    push eax
    mov ebx, [esp + 0x4]
    mov edi, [esp + 0x8]
    push edx
    shl esi, byte 0x2
    push ebx
    sub ebp, strict dword 0xbb8
    mov eax, [esi + actor_x]
    push edi
    mov edx, [esi + actor_y]
    mov ebx, ebp
    call cansee
    cwde
    cmp eax, 0x1
    jnz near .choose_active_target
    movsx edi, word [esp + 0x28]
    imul edi, edi, 0x2c
    mov ax, [edi + sprite_cstat]
    mov [esp + 0x20], eax
    and al, 0xfe
    mov [edi + sprite_cstat], ax
    xor eax, eax
    mov al, [edi + sprite_xrepeat]
    push strict byte 0x0
    shl eax, byte 0x2
    push eax
    lea eax, [esp + 0x14]
    push eax
    lea eax, [esp + 0x1c]
    mov ecx, [esp + 0x28]
    push eax
    lea eax, [esp + 0x24]
    mov ebx, ebp
    push eax
    lea eax, [esp + 0x2c]
    mov edx, [esi + actor_y]
    push eax
    movsx ecx, word [ecx + actor_sector]
    mov eax, [esi + actor_x]
    call get_z_range
    mov eax, [esp + 0x20]
    mov ebp, [esp + 0xc]
    mov [edi + sprite_cstat], ax
    cmp ebp, strict dword 0xc000
    jnc short .choose_active_target
    xor edi, edi
    jmp short .check_retarget

.choose_active_target:
    mov edi, 0x1

.check_retarget:
    movsx eax, di
    cmp eax, 0x1
    jnz near .check_movement
    xor ebx, ebx
    mov [esp + 0x2c], ebx
    jmp near .check_attempt_count

.sample_target:
    ; Try up to two nearby positions around the target.
    call random_value
    mov edx, eax
    add edx, eax
    movsx eax, dx
    sar eax, byte 0x3
    and eax, strict dword 0xf880
    mov edx, eax
    call random_value
    add eax, eax
    cwde
    sar eax, byte 0x4
    and eax, strict dword 0xf880
    test dx, dx
    jnz short .check_candidate_sector
    test ax, ax
    jz near .advance_attempt

.check_candidate_sector:
    mov ecx, [esp + 0x4]
    mov ebp, [esp]
    lea ebx, [esp + 0x24]
    movsx esi, ax
    movsx edi, dx
    add esi, ebp
    add edi, ecx
    mov edx, esi
    mov eax, edi
    call update_sector
    mov ebx, [esp + 0x24]
    test bx, bx
    jl near .advance_attempt
    movsx ecx, bx
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    shl eax, byte 0x3
    movsx ebx, word [eax + sector_hitag]
    test bh, 0x80
    jnz short .advance_attempt
    mov ebp, [eax + sector_floor_z]
    movsx eax, word [esp + 0x48]
    push eax
    mov eax, [esp + 0x48]
    push eax
    mov edx, [esp + 0x8]
    mov ebx, [esp + 0xc]
    push edx
    sub ebp, strict dword 0xbb8
    mov eax, edi
    push ebx
    mov edx, esi
    mov ebx, ebp
    call cansee
    cwde
    cmp eax, 0x1
    jnz short .advance_attempt
    movsx eax, word [esp + 0x8]
    xor cl, cl
    lea ebx, [eax + eax]
    mov [eax + actor_has_fired], cl
    mov [nosplit eax*4 + actor_x], edi
    mov [nosplit eax*4 + actor_y], esi
    mov eax, [esp + 0x24]
    mov [ebx + actor_sector], ax
    jmp short .check_movement

.advance_attempt:
    inc dword [esp + 0x2c]

.check_attempt_count:
    movsx eax, word [esp + 0x2c]
    cmp eax, 0x1
    jng near .sample_target

.check_movement:
    movsx esi, word [esp + 0x8]
    movsx ecx, word [nosplit esi*2 + actor_sector]
    cmp ecx, -1
    jz short .finish_frame
    xor eax, eax
    mov al, [esi + actor_kind]
    cmp eax, 0x4
    jz short .finish_frame
    cmp eax, 0x5
    jz short .finish_frame
    mov edi, [esp]
    push edi
    mov ebp, [esp + 0x8]
    mov eax, esi
    push ebp
    mov ebx, [nosplit esi*4 + actor_y]
    mov edx, [nosplit esi*4 + actor_x]
    call move_actor
    xor eax, eax
    mov al, [esi + actor_kind]
    cmp eax, 0x1
    jnz short .finish_frame
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, [esp + 0x4c]
    add edx, 0x23
    mov [eax + sprite_tile], dx

.finish_frame:
    ; Recovery holds the current frame; a new idle tile also updates sprite height.
    movsx ebx, word [esp + 0x8]
    cmp byte [ebx + actor_recovery_counter], 0x0
    jnz near .return
    cmp byte [ebx + actor_kind], 0x0
    jnz near .check_moving_frame
    movsx ebx, word [esp + 0x28]
    imul ebx, ebx, 0x2c
    movsx eax, word [esp + 0x4c]
    lea ecx, [eax + 0x37]
    movsx edx, word [ebx + sprite_tile]
    cmp edx, ecx
    jz near .return
    add eax, 0x4b
    cmp edx, eax
    jz near .return
    call random_value
    xor ah, ah
    cwde
    cmp eax, 0x7f
    jng short .select_second_idle_tile
    mov eax, [esp + 0x4c]
    add eax, strict dword 0x37
    jmp short .place_idle_frame

.select_second_idle_tile:
    mov eax, [esp + 0x4c]
    add eax, strict dword 0x4b

.place_idle_frame:
    mov [ebx + sprite_tile], ax
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    movsx edx, word [eax + sprite_tile]
    movsx ebx, word [nosplit edx*2 + tile_height]
    xor edx, edx
    mov dl, [eax + sprite_yrepeat]
    mov ecx, edx
    imul ecx, ebx
    movsx edx, word [eax + sprite_sector]
    mov ebx, edx
    shl ebx, byte 0x2
    add ebx, edx
    add ecx, ecx
    mov edx, [nosplit ebx*8 + sector_floor_z]
    sub edx, ecx
    mov [eax + sprite_z], edx
    jmp near .return

.check_moving_frame:
    xor eax, eax
    mov al, [ebx + actor_kind]
    cmp eax, 0x1
    jnz short .reset_other_frame
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, [esp + 0x4c]
    add edx, 0x23
    jmp near .store_tile

.reset_other_frame:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    movsx ecx, word [esp + 0x4c]
    add ecx, 0x4b
    movsx edx, word [eax + sprite_tile]
    cmp edx, ecx
    jz short .return
    mov edx, [esp + 0x4c]
    mov [eax + sprite_tile], dx
    mov byte [ebx + actor_recovery_counter], 0x1
    movsx ebx, word [eax + sprite_tile]
    movsx edx, word [nosplit ebx*2 + tile_height]
    xor ebx, ebx
    mov bl, [eax + sprite_yrepeat]
    imul edx, ebx
    movsx ecx, word [eax + sprite_sector]
    mov ebx, ecx
    shl ebx, byte 0x2
    add ebx, ecx
    add edx, edx
    mov ebx, [nosplit ebx*8 + sector_floor_z]
    sub ebx, edx
    mov [eax + sprite_z], ebx

.return:
    add esp, 0x34
    pop ebp
    pop edi
    pop esi
    ret 0xc
