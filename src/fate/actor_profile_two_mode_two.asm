; Update target selection, movement and projectile frames for actor profile two, mode two.
BITS 32
ORG 0x15e07

random_value equ 0x602d0
integer_square_root equ 0x4ca38
actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_tile equ 0x2040ae
actor_recovery_counter equ 0x7f295
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
player_x equ 0x5ad9c
player_y equ 0x5ad5c
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

update_actor_profile_two_mode_two:
    push esi
    push edi
    push ebp
    sub esp, 0x30
    mov edi, dword [esp + 0x40]
    mov dword [esp + 0x1c], eax
    mov dword [esp + 0x10], ebx
    mov ebp, ecx
    cwde
    mov cx, word [nosplit eax*2 + actor_sprite_index]
    xor ebx, ebx
    mov dword [esp + 0x28], ecx
    mov al, byte [eax + actor_kind]
    and eax, 0xff
    cmp eax, 3
    je near .return
    cmp eax, 4
    je short .hold_reaction_frame
    cmp eax, 5
    jne short .check_target

.hold_reaction_frame:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, dword [esp + 0x48]
    movsx ebx, word [esp + 0x1c]
    add edx, 0x3b
    mov ecx, dword [eax + sprite_x]
    mov word [eax + sprite_tile], dx
    mov dword [nosplit ebx*4 + actor_x], ecx
    mov ecx, dword [eax + sprite_y]
    mov ax, word [eax + sprite_sector]
    mov dword [nosplit ebx*4 + actor_y], ecx
    mov word [nosplit ebx*2 + actor_sector], ax
    jmp near .return

.check_target:
    test dx, dx
    je short .check_attack_frames
    movsx eax, dx
    mov ax, word [nosplit eax*2 + actor_sprite_index]
    cwde
    imul eax, eax, 0x2c
    mov edx, dword [eax + sprite_x]
    mov dword [esp + 0x10], edx
    movsx edx, word [eax + sprite_tile]
    movsx ecx, word [nosplit edx*2 + tile_height]
    xor edx, edx
    mov dl, byte [eax + sprite_yrepeat]
    imul edx, ecx
    mov ebp, dword [eax + sprite_y]
    mov edi, dword [eax + sprite_z]
    mov ax, word [eax + sprite_sector]
    mov dword [esp + 0x44], eax
    sub edi, edx

.check_attack_frames:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    movsx ecx, word [esp + 0x48]
    lea esi, [ecx + 0x1e]
    movsx edx, word [eax + sprite_tile]
    cmp edx, esi
    jl near .check_idle_visibility
    add ecx, 0x28
    cmp edx, ecx
    jg near .check_idle_visibility
    cmp word [advance_clock], 0
    je near .return
    mov dx, word [eax + sprite_tile]
    add edx, 5
    mov word [eax + sprite_tile], dx
    movsx eax, dx
    cmp eax, ecx
    jne short .check_attack_end
    movsx esi, word [esp + 0x1c]
    xor eax, ecx
    mov al, byte [esi + actor_projectile_type]
    mov edx, dword [esp + 0x10]
    push eax
    mov ebx, ebp
    mov ecx, edi
    push strict dword 0x200
    movsx eax, word [nosplit esi*2 + actor_sprite_index]
    call activate_sprite_at_position
    mov byte [esi + actor_has_fired], 1

.check_attack_end:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    movsx edx, word [esp + 0x48]
    add edx, 0x28
    movsx ebx, word [eax + sprite_tile]
    cmp ebx, edx
    jle near .return
    mov edx, dword [esp + 0x48]
    add edx, 0x19

.store_tile:
    mov word [eax + sprite_tile], dx
    jmp near .return

.check_idle_visibility:
    movsx esi, word [esp + 0x1c]
    cmp byte [esi + actor_kind], 0
    jne near .check_active_visibility
    cmp word [advance_clock], 0
    je near .check_retarget
    movsx eax, word [esp + 0x44]
    push eax
    movsx eax, word [esp + 0x2c]
    imul eax, eax, 0x2c
    push edi
    push ebp
    mov edx, dword [esp + 0x1c]
    push edx
    movsx ecx, word [eax + sprite_sector]
    mov ebx, dword [eax + sprite_z]
    mov edx, dword [eax + sprite_y]
    mov eax, dword [eax + sprite_x]
    call cansee
    mov edi, eax
    call random_value
    mov edx, eax
    xor dh, ah
    and dl, 0xf
    movsx eax, dx
    cmp eax, 7
    jne short .check_visible_target
    xor eax, eax
    mov al, byte [esi + actor_has_fired]
    cmp eax, 1
    je short .choose_new_target

.check_visible_target:
    movsx eax, di
    cmp eax, 1
    je short .check_target_sector

.choose_new_target:
    mov ebx, 1
    jmp short .check_attack_start

.check_target_sector:
    movsx eax, word [esp + 0x1c]
    movsx eax, word [nosplit eax*2 + actor_sector]
    cmp eax, -1
    je short .choose_new_target
    xor ebx, ebx

.check_attack_start:
    movsx ecx, word [esp + 0x28]
    imul ecx, ecx, 0x2c
    movsx edx, word [esp + 0x48]
    add edx, 0x19
    movsx eax, word [ecx + sprite_tile]
    cmp eax, edx
    jne near .check_retarget
    call random_value
    xor ah, ah
    cwde
    cmp eax, 0x50
    jge near .check_retarget
    movsx eax, di
    cmp eax, 1
    jne near .check_retarget
    mov eax, dword [esp + 0x48]
    add eax, strict dword 0x1e
    mov word [ecx + sprite_tile], ax
    movsx eax, word [esp + 0x1c]
    mov byte [eax + actor_recovery_counter], 1
    jmp near .check_retarget

.check_active_visibility:
    lea eax, [esi + esi]
    movsx ecx, word [eax + actor_sector]
    mov dword [esp + 0x18], eax
    mov eax, ecx
    shl eax, 2
    add eax, ecx
    mov eax, dword [nosplit eax*8 + sector_floor_z]
    sub eax, strict dword 0xbb8
    mov dword [esp + 0x14], eax
    movsx eax, word [esp + 0x44]
    push eax
    push edi
    shl esi, 2
    push ebp
    mov edi, dword [esp + 0x1c]
    mov edx, dword [esi + actor_y]
    push edi
    mov ebx, dword [esp + 0x24]
    mov eax, dword [esi + actor_x]
    call cansee
    cwde
    cmp eax, 1
    jne near .choose_active_target
    movsx edi, word [esp + 0x28]
    imul edi, edi, 0x2c
    mov ax, word [edi + sprite_cstat]
    mov dword [esp + 0x2c], eax
    and al, 0xfe
    mov word [edi + sprite_cstat], ax
    xor eax, eax
    mov al, byte [edi + sprite_xrepeat]
    push 0
    add eax, eax
    push eax
    lea eax, [esp + 8]
    push eax
    lea eax, [esp + 0x10]
    mov ecx, dword [esp + 0x24]
    push eax
    lea eax, [esp + 0x18]
    mov ebx, dword [esp + 0x24]
    push eax
    lea eax, [esp + 0x20]
    mov edx, dword [esi + actor_y]
    push eax
    movsx ecx, word [ecx + actor_sector]
    mov eax, dword [esi + actor_x]
    call get_z_range
    mov eax, dword [esp + 0x2c]
    mov word [edi + sprite_cstat], ax
    cmp dword [esp], 0xc000
    jb short .keep_target
    mov edx, dword [esp]
    movsx eax, word [esp + 0x28]
    sub edx, 0xc000
    cmp edx, eax
    jne short .choose_active_target

.keep_target:
    xor ebx, ebx
    jmp short .check_retarget

.choose_active_target:
    mov ebx, 1

.check_retarget:
    movsx eax, bx
    cmp eax, 1
    jne near .check_movement
    xor ebx, ebx
    mov dword [esp + 0x24], ebx
    jmp near .check_attempt_count

.sample_target:
    call random_value
    mov edx, eax
    add edx, eax
    movsx eax, dx
    sar eax, 3
    and eax, 0xf880
    mov edx, eax
    call random_value
    add eax, eax
    cwde
    sar eax, 3
    and eax, 0xf880
    test dx, dx
    jne short .check_candidate_sector
    test ax, ax
    je near .advance_attempt

.check_candidate_sector:
    movsx ecx, word [esp + 0x28]
    imul ecx, ecx, 0x2c
    movsx esi, dx
    movsx edi, ax
    mov ebx, dword [ecx + sprite_x]
    mov eax, dword [ecx + sprite_y]
    add esi, ebx
    add edi, eax
    lea ebx, [esp + 0x20]
    mov edx, edi
    mov eax, esi
    call update_sector
    mov ebx, dword [esp + 0x20]
    test bx, bx
    jl near .advance_attempt
    movsx edx, bx
    mov eax, edx
    shl eax, 2
    add eax, edx
    movsx eax, word [nosplit eax*8 + sector_hitag]
    test ah, 0x80
    jne near .advance_attempt
    mov edx, dword [player_x]
    mov eax, dword [ecx + sprite_x]
    sub eax, edx
    imul eax, eax
    mov ebx, dword [player_y]
    mov ecx, dword [ecx + sprite_y]
    sub ecx, ebx
    imul ecx, ecx
    add eax, ecx
    call integer_square_root
    mov ecx, dword [player_x]
    mov edx, eax
    mov eax, esi
    mov ebx, dword [player_y]
    sub eax, ecx
    mov ecx, edi
    sub ecx, ebx
    mov ebx, eax
    imul ebx, eax
    mov eax, ecx
    imul eax, ecx
    add eax, ebx
    call integer_square_root
    cmp eax, edx
    jg short .advance_attempt
    movsx edx, word [esp + 0x1c]
    xor bl, bl
    mov eax, dword [esp + 0x20]
    mov byte [edx + actor_has_fired], bl
    mov dword [nosplit edx*4 + actor_x], esi
    mov dword [nosplit edx*4 + actor_y], edi
    mov word [nosplit edx*2 + actor_sector], ax
    jmp short .check_movement

.advance_attempt:
    inc dword [esp + 0x24]

.check_attempt_count:
    movsx eax, word [esp + 0x24]
    cmp eax, 1
    jle near .sample_target

.check_movement:
    movsx esi, word [esp + 0x1c]
    movsx ecx, word [nosplit esi*2 + actor_sector]
    cmp ecx, -1
    je short .finish_frame
    xor eax, eax
    mov al, byte [esi + actor_kind]
    cmp eax, 4
    je short .finish_frame
    cmp eax, 5
    je short .finish_frame
    push ebp
    mov edi, dword [esp + 0x14]
    mov eax, esi
    push edi
    mov ebx, dword [nosplit esi*4 + actor_y]
    mov edx, dword [nosplit esi*4 + actor_x]
    call move_actor
    xor eax, eax
    mov al, byte [esi + actor_kind]
    cmp eax, 1
    jne short .finish_frame
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, dword [esp + 0x48]
    add edx, 5
    mov word [eax + sprite_tile], dx

.finish_frame:
    movsx edx, word [esp + 0x1c]
    cmp byte [edx + actor_recovery_counter], 0
    jne near .return
    mov cl, byte [edx + actor_kind]
    test cl, cl
    jne short .check_active_frame
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    movsx edx, word [esp + 0x48]
    add edx, 0x19
    movsx ebx, word [eax + sprite_tile]
    cmp ebx, edx
    je near .return
    mov edx, dword [esp + 0x48]
    add edx, 0x19
    mov word [eax + sprite_tile], dx
    movsx edx, dx
    movsx ebx, word [nosplit edx*2 + tile_height]
    xor edx, edx
    mov dl, byte [eax + sprite_yrepeat]
    mov ecx, edx
    imul ecx, ebx
    movsx ebx, word [eax + sprite_sector]
    mov edx, ebx
    shl edx, 2
    add edx, ebx
    add ecx, ecx
    mov edx, dword [nosplit edx*8 + sector_floor_z]
    jmp short .set_floor_relative_z

.check_active_frame:
    xor eax, eax
    mov al, cl
    cmp eax, 1
    jne short .reset_other_frame
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov edx, dword [esp + 0x48]
    add edx, 5
    jmp near .store_tile

.reset_other_frame:
    movsx eax, word [esp + 0x28]
    imul eax, eax, 0x2c
    mov esi, dword [esp + 0x48]
    cmp si, word [eax + sprite_tile]
    je short .return
    mov byte [edx + actor_recovery_counter], 1
    movsx edx, si
    movsx ebx, word [nosplit edx*2 + tile_height]
    xor edx, edx
    mov dl, byte [eax + sprite_yrepeat]
    mov ecx, edx
    imul ecx, ebx
    movsx ebx, word [eax + sprite_sector]
    mov edx, ebx
    shl edx, 2
    add edx, ebx
    add ecx, ecx
    mov edx, dword [nosplit edx*8 + sector_floor_z]
    mov word [eax + sprite_tile], si

.set_floor_relative_z:
    sub edx, ecx
    mov dword [eax + sprite_z], edx

.return:
    add esp, 0x30
    pop ebp
    pop edi
    pop esi
    ret 0xc
