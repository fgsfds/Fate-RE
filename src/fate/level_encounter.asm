; Update the scripted encounter, sprite triggers and exit state.
BITS 32
ORG 0x1de8e

random_value equ 0x602d0
play_sound equ 0x34f79
sprite_tile equ 0x2040ae
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
sprite_xrepeat equ 0x2040b2
ticks_per_step equ 0x7a994
sprite_yrepeat equ 0x2040b5
advance_clock equ 0x229b
update_sector equ 0x542c4
update_actor_common equ 0x14897
encounter_clock equ 0x12814
first_trigger_state equ 0x127f4
second_trigger_state equ 0x127f6
encounter_parameters equ 0x127f8
exit_scan_initialized equ 0x12806
exit_trigger_state equ 0x12808
trigger_count equ 0x3be6
trigger_sprite equ 0x77124
sprite_hitag equ 0x2040c8
sprite_lotag equ 0x2040c6
sprite_shade_field equ 0x2040b4
encounter_actor_field equ 0x7dec0
encounter_position equ 0x729e0
first_trigger_sprite equ 0x7494e
second_trigger_sprite equ 0x74950
exit_sector_type equ 0x7659c
exit_sector_index equ 0x7659e
encounter_sprite_index equ 0x7db36
first_actor_state equ 0x7e32b
second_actor_state equ 0x7e32c
first_actor_kind equ 0x7f0de
second_actor_kind equ 0x7f0df
first_actor_mode equ 0x7f6bd
second_actor_mode equ 0x7f6be
exit_scan_index equ 0x851a8
tile_width equ 0x1f2020
sector_lotag equ 0x27c3c2
sector_count equ 0x289154
spawn_sprite_at_position equ 0x11073
add_listed_sprite equ 0x134c2
check_encounter_condition equ 0x10610
delete_sprite equ 0x50a09
update_sprite_sequence_state equ 0x10433
activate_sector equ 0x28710

spawn_positions:
    dd -10240, -6400
    dd -9728, -5632
    dd -8960, -5376
    dd -7936, -5888
    dd -7424, -5376
    dd -9984, -7168
    dd -8704, -6656
    dd -7936, -7424
    dd -7424, -7168
    dd -10752, -9216
    dd -10240, -8192
    dd -6912, -8448
    dd -9984, -9728
    dd -7680, -9728
    dd -8704, -10240
    dd -9216, -10752

spawn_counts:
    times 2 db 60
    times 4 db 30
    times 16 db 15
    times 10 db 7

update_level_encounter:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, strict dword 0xb8
    mov ecx, 0x20
    mov edi, esp
    mov esi, spawn_positions - 0x10000
    rep movsd
    mov ecx, 0x8
    lea edi, [esp + 0x80]
    mov esi, spawn_counts - 0x10000
    rep movsd
    movsx eax, word [encounter_clock]
    cmp eax, 0xa
    jz near .check_first_trigger_sprite
    cmp word [encounter_clock], 0x0
    jnz near .advance_encounter
    mov esi, 0x1
    jmp near .check_trigger_index

.inspect_encounter_trigger:
    movsx eax, si
    mov ax, [nosplit eax*4 + trigger_sprite]
    cwde
    imul eax, eax, 0x2c
    movsx edx, word [eax + sprite_hitag]
    cmp edx, strict dword 0x203
    jnz near .advance_trigger
    mov edx, [eax + sprite_x]
    cmp edx, strict dword 0xffffcffe
    jng near .advance_trigger
    cmp edx, strict dword 0xffffebfd
    jnl near .advance_trigger
    mov ecx, [eax + sprite_y]
    cmp ecx, strict dword 0xffffd2f5
    jng short .advance_trigger
    cmp ecx, strict dword 0xffffedfa
    jnl short .advance_trigger
    mov ecx, 0x1
    mov eax, 0x88
    xor ebx, ebx
    xor edx, edx
    mov [encounter_clock], cx
    xor ecx, ecx
    call play_sound
    mov eax, 0x87
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    xor edi, edi
    call play_sound
    mov [encounter_actor_field], di
    xor edx, edx
    jmp short .check_sector_index

.clear_sector_tag:
    movsx ebx, dx
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    shl eax, byte 0x3
    movsx ebx, word [eax + sector_lotag]
    cmp ebx, 0xe
    jnz short .advance_sector
    xor ebx, ebx
    mov [eax + sector_lotag], bx

.advance_sector:
    inc edx

.check_sector_index:
    cmp dx, [sector_count]
    jl short .clear_sector_tag

.advance_trigger:
    inc esi

.check_trigger_index:
    cmp si, [trigger_count]
    jng near .inspect_encounter_trigger

.advance_encounter:
    mov cx, [encounter_clock]
    test cx, cx
    jng near .check_first_trigger_sprite
    cmp word [advance_clock], 0x0
    jz short .prepare_spawn_loop
    mov edi, ecx
    inc edi
    mov [encounter_clock], di

.prepare_spawn_loop:
    mov eax, 0x1
    mov ebp, 0xffff3c06
    mov [esp + 0xb4], eax
    jmp near .check_spawn_count

.spawn_encounter_sprite:
    call random_value
    mov edx, eax
    xor dh, ah
    and dl, 0xf
    movsx ebx, dx
    mov eax, [esp + ebx*8]
    mov [esp + 0xa0], eax
    mov eax, [esp + ebx*8 + 0x4]
    lea ebx, [esp + 0xac]
    mov [esp + 0xa4], eax
    mov edx, eax
    mov eax, [esp + 0xa0]
    mov [esp + 0xa8], ebp
    call update_sector
    movsx ebx, word [esp + 0xac]
    lea edx, [esp + 0xa0]
    mov eax, 0x2b
    call spawn_sprite_at_position
    mov edi, eax
    movsx edi, di
    imul esi, edi, 0x2c
    call random_value
    mov edx, eax
    xor dh, ah
    and dl, 0x1
    add edx, strict dword 0x350
    mov [esi + sprite_tile], dx
    call random_value
    mov edx, eax
    xor dh, ah
    call random_value
    mov ebx, eax
    xor bh, ah
    call random_value
    xor ah, ah
    and dl, 0xf
    and al, 0x1
    and bl, 0x1
    mov [esp + 0xb0], eax
    movsx eax, dx
    xor edx, edx
    movsx ecx, bx
    mov dl, [esp + eax*2 + 0x80]
    sar edx, cl
    mov al, [esp + eax*2 + 0x81]
    mov [esi + sprite_shade_field], dl
    movsx ecx, word [esp + 0xb0]
    and eax, strict dword 0xff
    sar eax, cl
    mov [esi + sprite_yrepeat], al
    movsx eax, word [esi + sprite_tile]
    mov ax, [nosplit eax*2 + tile_width]
    mov dl, [esi + sprite_shade_field]
    movsx ebx, ax
    xor eax, eax
    mov al, dl
    imul ebx
    shrd eax, edx, byte 0x7
    mov edx, [esp + 0xb4]
    mov [esi + sprite_xrepeat], al
    mov eax, edi
    inc edx
    call add_listed_sprite
    mov [esp + 0xb4], edx

.check_spawn_count:
    mov eax, [ticks_per_step]
    movsx edx, word [esp + 0xb4]
    add eax, eax
    cmp edx, eax
    jng near .spawn_encounter_sprite

.check_first_trigger_sprite:
    movsx eax, word [first_trigger_sprite]
    imul eax, eax, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x568
    jnz short .check_second_trigger_state
    movsx eax, word [second_trigger_state]
    cmp eax, 0x3
    jz short .check_second_trigger_state
    xor eax, eax
    mov al, [second_actor_kind]
    cmp eax, 0x3
    jz short .activate_trigger_sectors
    mov byte [second_actor_mode], 0x2

.activate_trigger_sectors:
    mov ebx, 0x3
    mov eax, 0x96
    xor ecx, ecx
    mov [second_trigger_state], bx
    call activate_sector
    mov eax, 0x99
    xor edx, edx
    call activate_sector
    xor ebx, ebx
    mov eax, 0x7e
    call play_sound
    mov eax, 0x8e
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    movsx eax, word [first_trigger_sprite]
    imul eax, eax, 0x2c
    xor ecx, ecx
    mov [eax + sprite_lotag], cx

.check_second_trigger_state:
    mov si, [second_trigger_state]
    test si, si
    jnz short .update_second_actor
    mov edx, 0x1000
    mov eax, 0x2a00
    call check_encounter_condition
    mov edx, 0x2000
    mov ebx, eax
    mov eax, 0x2a00
    call check_encounter_condition
    movsx edx, bx
    cwde
    or edx, eax
    jnz short .reset_second_actor_kind
    xor eax, eax
    mov al, [second_actor_kind]
    cmp eax, 0x4
    jz short .reset_second_actor_kind
    cmp eax, 0x5
    jnz near .check_exit_scan

.reset_second_actor_kind:
    xor dh, dh
    mov [second_actor_kind], dh
    mov word [second_trigger_state], 0x1
    jmp near .check_exit_scan

.update_second_actor:
    movsx eax, si
    cmp eax, 0x1
    jnz short .check_exit_scan
    mov eax, 0x3f
    call update_actor_common
    push strict dword encounter_parameters
    mov ecx, 0x410a
    mov ebx, 0x1800
    push strict dword 0x1800
    mov edx, 0x3100
    mov eax, 0x3f
    call update_sprite_sequence_state
    mov ax, [encounter_sprite_index]
    cwde
    imul eax, eax, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x34b
    jnz short .check_second_actor_reaction
    movsx eax, word [first_trigger_sprite]
    imul eax, eax, 0x2c
    mov word [eax + sprite_tile], 0x568

.check_second_actor_reaction:
    cmp byte [second_actor_state], 0x0
    jnz short .check_exit_scan
    mov word [second_trigger_state], 0x2

.check_exit_scan:
    cmp word [exit_scan_initialized], 0x0
    jnz short .check_first_actor_kind
    mov ecx, 0x1
    mov [exit_scan_initialized], cx
    mov [exit_scan_index], cx
    jmp short .check_exit_scan_index

.inspect_exit_sector_type:
    movsx eax, word [nosplit eax*4 + exit_sector_type]
    cmp eax, 0xb
    jz short .check_first_actor_kind
    inc word [exit_scan_index]

.check_exit_scan_index:
    movsx eax, word [exit_scan_index]
    cmp eax, 0x1f
    jng short .inspect_exit_sector_type

.check_first_actor_kind:
    xor eax, eax
    mov al, [first_actor_kind]
    cmp eax, 0x3
    jz near .return
    movsx eax, word [first_trigger_state]
    cmp eax, 0x2
    jz near .return
    movsx eax, word [encounter_position]
    cmp eax, 0x1
    jnz short .check_exit_trigger_state
    mov eax, 0x2
    mov bl, 0x1
    mov [first_trigger_state], ax
    mov [first_actor_mode], bl

.check_exit_trigger_state:
    mov dx, [first_trigger_state]
    test dx, dx
    jnz short .update_first_actor
    movsx eax, word [exit_scan_index]
    cmp word [nosplit eax*4 + exit_sector_index], 0x0
    jz short .return
    mov word [first_trigger_state], 0x1
    jmp short .return

.update_first_actor:
    movsx eax, dx
    cmp eax, 0x1
    jnz short .return
    mov eax, 0x3e
    call update_actor_common
    push strict dword exit_trigger_state
    mov ecx, 0x410a
    mov ebx, 0x18f8
    push strict dword 0x1800
    mov edx, 0x1df4
    mov eax, 0x3e
    call update_sprite_sequence_state
    cmp byte [first_actor_state], 0x0
    jnz short .return
    mov cl, 0x2
    movsx eax, word [second_trigger_sprite]
    mov ebx, 0x2
    call delete_sprite
    mov [first_actor_mode], cl
    mov [first_trigger_state], bx

.return:
    add esp, strict dword 0xb8
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
