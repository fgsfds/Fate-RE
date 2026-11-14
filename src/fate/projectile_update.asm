; Apply projectile hits and advance the active projectile list.
BITS 32
ORG 0x13115

adjust_status_value equ 0x1092e
start_sequence equ 0x11fdd
move_projectile equ 0x339b9
integer_square_root equ 0x4ca38
change_sprite_sector equ 0x50bc3
dispatch_hit_event equ 0x2b369
remove_projectile equ 0x10f9f
sprite_lotag equ 0x2040c6
sprite_actor_index equ 0x709dc
actor_health equ 0x7cefa
sprite_sector equ 0x2040b8
sector_floor_z equ 0x27c3a8
sprite_z equ 0x2040a8
sprite_xrepeat equ 0x2040b2
sprite_cstat equ 0x2040ac
actor_kind equ 0x7f0a0
sprite_owner equ 0x2040be
player_sprite equ 0x62f2c
held_item equ 0x2bf6
sprite_tile equ 0x2040ae
holding_sprite equ 0x2bfa
projectile_list equ 0x7053c
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
ticks_per_step equ 0x7a994
sprite_xvel equ 0x2040c0
sprite_yvel equ 0x2040c2
sprite_zvel equ 0x2040c4
player_x equ 0x5ad9c
player_y equ 0x5ad5c
player_hit_timer equ 0x6f89c
player_hit_x equ 0x7097c
player_hit_y equ 0x7093c
player_mode equ 0x62f1c
selected_weapon equ 0x2be2
close_hit_tile equ 0x2be6
projectile_count equ 0x2bee
sprite_hitag equ 0x2040c8
player_z equ 0x5ad1c
sprite_extra_high equ 0x2040cb

apply_projectile_hit:
    push ebx
    push ecx
    push esi
    push edi
    mov ebx, eax
    mov edi, edx
    movsx eax, dx
    imul eax, eax, 0x2c
    mov ax, word [eax + sprite_lotag]
    cmp ax, strict word 0xa00
    jb short .check_light_projectile
    jbe short .second_damage
    cmp ax, strict word 0x3000
    jb short .locate_target_actor
    jbe short .third_damage
    cmp ax, strict word 0x4200
    je short .fourth_damage
    jmp short .locate_target_actor

.check_light_projectile:
    cmp ax, strict word 0x100
    jne short .locate_target_actor
    mov ecx, 0xffffff38
    jmp short .locate_target_actor

.second_damage:
    mov ecx, 0xffffff83
    jmp short .locate_target_actor

.third_damage:
    mov ecx, 0xfffffed4
    jmp short .locate_target_actor

.fourth_damage:
    mov ecx, 0xffffffe7

.locate_target_actor:
    movsx esi, bx
    mov ax, word [nosplit esi*2 + sprite_actor_index]
    movsx edx, ax
    imul eax, esi, 0x2c
    cmp edx, -1
    je near .check_player_target
    add word [nosplit edx*2 + actor_health], cx
    cmp word [nosplit edx*2 + actor_health], 0
    jg short .actor_survived
    movsx ecx, word [eax + sprite_sector]
    mov ebx, ecx
    shl ebx, 2
    add ebx, ecx
    mov ebx, dword [ebx*8 + sector_floor_z]
    mov dword [eax + sprite_z], ebx
    xor edi, edi
    mov bl, byte [eax + sprite_xrepeat]
    mov word [eax + sprite_cstat], di
    add bl, bl
    mov byte [eax + sprite_xrepeat], bl
    mov bh, 3
    mov eax, esi
    mov byte [edx + actor_kind], bh
    jmp short .play_sequence

.actor_survived:
    movsx eax, di
    imul eax, eax, 0x2c
    movsx eax, word [eax + sprite_owner]
    cmp eax, 1
    jne short .ordinary_reaction
    mov byte [edx + actor_kind], 5
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

.ordinary_reaction:
    mov byte [edx + actor_kind], 4
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

.check_player_target:
    cmp bx, word [player_sprite]
    jne short .check_held_item
    movsx eax, cx
    call adjust_status_value
    jmp short .start_target_sequence

.check_held_item:
    mov cx, word [held_item]
    cmp cx, word [eax + sprite_tile]
    jne short .start_target_sequence
    xor esi, esi
    mov word [held_item], si
    mov word [holding_sprite], si

.start_target_sequence:
    movsx eax, bx

.play_sequence:
    call start_sequence
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

update_projectiles:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x14
    mov dword [esp + 0x10], 1
    jmp near .check_count

.step_projectile:
    movsx edi, ax
    mov di, word [nosplit edi*2 + projectile_list]
    movsx eax, di
    imul esi, eax, 0x2c
    mov edx, dword [esi + sprite_x]
    mov dword [esp + 8], edx
    mov edx, dword [esi + sprite_y]
    mov dword [esp + 4], edx
    mov dx, word [esi + sprite_sector]
    mov ebx, dword [ticks_per_step]
    mov dword [esp + 0xc], edx
    movsx edx, word [esi + sprite_xvel]
    imul edx, ebx
    mov ecx, dword [ticks_per_step]
    movsx ebx, word [esi + sprite_yvel]
    imul ebx, ecx
    movsx ecx, word [esi + sprite_zvel]
    imul ecx, dword [ticks_per_step]
    push 1
    push 0x10
    push 0x10
    shl edx, 0xc
    shl ebx, 0xc
    sar ecx, 2
    mov ebp, dword [esi + sprite_z]
    call move_projectile
    mov ecx, eax
    test ax, ax
    je near .advance
    mov dx, word [esi + sprite_owner]
    movsx edx, dx
    cmp edx, 1
    jne near .remove_from_list
    and eax, 0xffff
    movsx edx, word [player_sprite]
    sub eax, strict dword 0xc000
    cmp eax, edx
    je near .advance
    mov edx, dword [player_x]
    mov eax, dword [esi + sprite_x]
    sub eax, edx
    mov ebx, dword [player_y]
    mov edx, eax
    mov eax, dword [esi + sprite_y]
    sub eax, ebx
    mov ebx, eax
    mov eax, edx
    imul eax, edx
    mov dword [esp], eax
    mov eax, ebx
    imul eax, ebx
    add eax, dword [esp]
    call integer_square_root
    cmp eax, strict dword 0x100
    jge short .remove_from_list
    mov esi, 0xffffffce
    mov eax, 0xfffffea2
    neg edx
    neg ebx
    shl edx, 0xe
    shl ebx, 0xe
    mov word [player_hit_timer], si
    mov dword [player_hit_x], edx
    mov dword [player_hit_y], ebx
    call adjust_status_value
    xor eax, eax
    mov al, byte [player_mode]
    cmp eax, 2
    je short .remove_from_list
    movsx eax, word [selected_weapon]
    cmp eax, 1
    jne short .check_other_weapon
    mov word [close_hit_tile], 0x323
    jmp short .remove_from_list

.check_other_weapon:
    cmp eax, 2
    je short .set_close_hit_tile
    cmp eax, 3
    jne short .remove_from_list

.set_close_hit_tile:
    mov word [close_hit_tile], 0x327

.remove_from_list:
    movsx esi, di
    imul ebx, esi, 0x2c
    movsx eax, word [projectile_count]
    movsx edx, word [esp + 0x10]
    mov ax, word [nosplit eax*2 + projectile_list]
    mov word [nosplit edx*2 + projectile_list], ax
    dec word [projectile_count]
    mov eax, dword [esp + 8]
    mov edx, dword [ebx + sprite_x]
    sub edx, eax
    mov eax, edx
    sar edx, 0x1f
    db 0x2b, 0xc2 ; sub eax, edx using the register-load opcode
    sar eax, 1
    sub dword [ebx + sprite_x], eax
    mov eax, dword [esp + 4]
    mov edx, dword [ebx + sprite_y]
    sub edx, eax
    mov eax, edx
    sar edx, 0x1f
    db 0x2b, 0xc2 ; sub eax, edx using the register-load opcode
    sar eax, 1
    sub dword [ebx + sprite_y], eax
    mov edx, dword [ebx + sprite_z]
    sub edx, ebp
    mov eax, edx
    sar edx, 0x1f
    db 0x2b, 0xc2 ; sub eax, edx using the register-load opcode
    sar eax, 1
    mov ebp, dword [ebx + sprite_z]
    movsx edx, word [esp + 0xc]
    sub ebp, eax
    mov eax, esi
    mov dword [ebx + sprite_z], ebp
    call change_sprite_sector
    xor eax, eax
    mov ax, cx
    cmp eax, strict dword 0xc000
    jb short .check_other_collision
    mov ebx, ecx
    sub ebx, 0xc000
    movsx eax, bx
    imul eax, eax, 0x2c
    mov dx, word [eax + sprite_lotag]
    xor dh, dh
    movsx edx, dx
    cmp edx, 4
    jne short .apply_sprite_hit
    mov ax, word [eax + sprite_hitag]
    xor ah, ah
    cwde
    call dispatch_hit_event

.apply_sprite_hit:
    movsx edx, di
    movsx eax, bx
    call apply_projectile_hit
    jmp short .finish_collision

.check_other_collision:
    cmp eax, strict dword 0x8000
    jae short .finish_collision
    mov edx, dword [player_z]
    cmp edx, dword [ebx + sprite_z]
    jge short .finish_collision
    or byte [ebx + sprite_extra_high], 0x20

.finish_collision:
    cmp word [close_hit_tile], 0
    jne short .remove_sprite
    movsx eax, di
    call start_sequence
    jmp short .advance

.remove_sprite:
    movsx eax, di
    call remove_projectile

.advance:
    inc dword [esp + 0x10]

.check_count:
    mov eax, dword [esp + 0x10]
    cmp ax, word [projectile_count]
    jle near .step_projectile
    add esp, 0x14
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
