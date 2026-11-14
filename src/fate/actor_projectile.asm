; Aim a sprite projectile at a position or apply the close-range player hit.
BITS 32
ORG 0x129e4

integer_square_root equ 0x4ca38
truncate_st0 equ 0x60304
adjust_status_value equ 0x1092e
update_sector equ 0x542c4
play_sound equ 0x34f79
insert_sprite equ 0x508b8
format_string equ 0x601f3
report_error equ 0x26a03
player_x equ 0x5ad9c
player_y equ 0x5ad5c
player_z equ 0x5ad1c
player_action equ 0x2297
player_mode equ 0x62f1c
close_hit_tile equ 0x2be6
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_tile equ 0x2040ae
sprite_yrepeat equ 0x2040b5
sprite_angle equ 0x2040bc
tile_height equ 0x1f4020
projectile_positions equ 0x20a2c
projectile_flags equ 0x1ecfa0
projectile_count equ 0x2bee
projectile_list equ 0x7053c
overflow_message equ 0x1f8
error_buffer equ 0x67e3c

projectile_dispatch:
    dd activate_sprite_at_position.type_zero - 0x10000
    dd activate_sprite_at_position.type_one - 0x10000
    dd activate_sprite_at_position.type_two - 0x10000
    dd activate_sprite_at_position.type_three - 0x10000
    dd activate_sprite_at_position.type_four - 0x10000
    dd activate_sprite_at_position.type_five - 0x10000

activate_sprite_at_position:
    push esi
    push edi
    push ebp
    sub esp, 0x44
    mov edi, eax
    cmp edx, dword [player_x]
    jne short .calculate_aim
    cmp ebx, dword [player_y]
    jne short .calculate_aim
    mov word [player_action], 2

.calculate_aim:
    movsx esi, di
    imul esi, esi, 0x2c
    mov eax, dword [esi + sprite_x]
    mov dword [esp + 0x18], eax
    mov eax, dword [esi + sprite_y]
    mov dword [esp + 0x24], eax
    movsx eax, word [esi + sprite_tile]
    movsx eax, word [nosplit eax*2 + tile_height]
    mov dword [esp + 0x10], eax
    xor eax, eax
    mov ebp, dword [esp + 0x10]
    mov al, byte [esi + sprite_yrepeat]
    imul eax, ebp
    mov esi, dword [esi + sprite_z]
    sub esi, eax
    mov dword [esp + 0x20], esi
    mov eax, edx
    sub eax, dword [esp + 0x18]
    mov ebp, dword [esp + 0x24]
    mov dword [esp + 0xc], eax
    mov eax, ebx
    sub eax, ebp
    mov esi, dword [esp + 0x20]
    mov dword [esp + 8], eax
    mov eax, ecx
    sub eax, esi
    mov esi, dword [esp + 0xc]
    imul esi, esi
    mov dword [esp + 4], eax
    mov eax, dword [esp + 8]
    imul eax, eax
    add eax, esi
    call integer_square_root
    fild word [esp + 0x54]
    mov dword [esp + 0x10], eax
    fild dword [esp + 0x10]
    fdivp st1
    fild dword [esp + 0xc]
    fmul st1
    call truncate_st0
    fistp dword [esp + 0x14]
    fild dword [esp + 8]
    fmul st1
    call truncate_st0
    fistp dword [esp + 0x28]
    fild dword [esp + 4]
    fmulp st1
    call truncate_st0
    fistp dword [esp + 0x2c]
    mov eax, dword [esp + 0x14]
    mov dword [esp + 0x38], eax
    mov eax, dword [esp + 0x28]
    mov dword [esp + 0x3c], eax
    mov eax, dword [esp + 0x2c]
    mov dword [esp + 0x30], eax
    cmp dword [esp + 0x10], 0x200
    jge near .locate_spawn_sector
    mov esi, dword [player_x]
    cmp edx, esi
    jne near .locate_spawn_sector
    cmp ebx, dword [player_y]
    jne near .locate_spawn_sector
    cmp ecx, dword [player_z]
    jne near .locate_spawn_sector
    mov eax, 0xffffffce
    call adjust_status_value
    xor eax, eax
    mov al, byte [player_mode]
    cmp eax, 2
    je near .return
    mov bh, byte [esp + 0x58]
    test bh, bh
    jne short .select_hit_tile

.default_hit_tile:
    mov word [close_hit_tile], 0x327
    jmp near .return

.select_hit_tile:
    xor edx, esi
    mov dl, bh
    cmp edx, 1
    jne short .check_hit_variant_two
    mov word [close_hit_tile], 0x323
    jmp near .return

.check_hit_variant_two:
    cmp edx, 2
    je short .default_hit_tile
    cmp edx, 3
    jne short .check_hit_variant_four
    mov word [close_hit_tile], 0x362
    jmp near .return

.check_hit_variant_four:
    cmp edx, 4
    jne near .return
    mov word [close_hit_tile], 0x303
    jmp near .return

.locate_spawn_sector:
    movsx eax, word [esp + 0x38]
    mov ebp, dword [esp + 0x18]
    sar eax, 1
    add ebp, eax
    movsx eax, word [esp + 0x3c]
    mov edx, dword [esp + 0x24]
    sar eax, 1
    lea ebx, [esp + 0x34]
    add edx, eax
    mov eax, ebp
    mov dword [esp + 0x1c], edx
    call update_sector
    cmp word [esp + 0x34], 0
    jl near .return
    cmp byte [esp + 0x58], 5
    ja near .append_projectile
    xor eax, eax
    mov al, byte [esp + 0x58]
    jmp dword [cs:projectile_dispatch-0x10000+eax*4]

.type_zero:
    movsx edi, di
    imul edi, edi, 0x2c
    mov eax, 0x40
    xor ecx, ecx
    mov ebx, dword [edi + sprite_y]
    mov edx, dword [edi + sprite_x]
    call play_sound
    movsx eax, word [esp + 0x34]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite_x
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 8
    mov byte [esi + 0x15], 8
    mov word [esp + 0x40], ax
    mov byte [esi + 0x16], 0
    mov eax, dword [esp + 0x1c]
    mov byte [esi + 0x17], 0
    mov ebx, dword [esp + 0x20]
    mov dword [esi + 4], eax
    movsx eax, word [esp + 0x30]
    mov word [esi + 0xe], 0x2fe
    sar eax, 1
    mov dword [esi], ebp
    add ebx, eax
    mov dword [esi + 8], ebx
    mov ax, word [edi + sprite_angle]
    mov word [esi + 0x1e], 2
    mov ecx, 3
    mov word [esi + 0x26], 0x100
    mov ebp, edx
    mov word [esi + 0x28], 0
    shl ebp, 2
    mov word [esi + 0x2a], 0
    sub ebp, edx
    mov word [esi + 0x1c], ax
    mov eax, dword [esp + 0x38]
    shl ebp, 2
    mov word [esi + 0x20], ax
    mov eax, dword [esp + 0x3c]
    mov edi, projectile_positions
    jmp near .store_velocity_yz

.type_one:
    movsx ebx, di
    imul ebx, ebx, 0x2c
    xor ecx, ecx
    mov eax, dword [ebx + sprite_y]
    mov edx, dword [ebx + sprite_x]
    mov ebx, eax
    mov eax, 0x2e
    call play_sound
    movsx eax, word [esp + 0x34]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite_x
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 6
    mov byte [esi + 0x15], 6
    mov byte [esi + 0x16], 0
    mov byte [esi + 0x17], 0
    mov word [esi + 0xe], 0x30b
    mov word [esi + 0x1c], 0
    mov word [esi + 0x1e], 2
    mov edi, projectile_positions
    mov word [esi + 0x26], 0xa00
    mov ebx, dword [esp + 0x20]
    mov word [esi + 0x28], 0
    mov word [esp + 0x40], ax
    mov word [esi + 0x2a], 0
    mov eax, dword [esp + 0x1c]
    mov dword [esi], ebp
    mov ecx, 3
    mov dword [esi + 4], eax
    movsx eax, word [esp + 0x30]
    mov ebp, edx
    sar eax, 1
    shl ebp, 2
    add ebx, eax
    mov eax, dword [esp + 0x38]
    mov dword [esi + 8], ebx
    sub ebp, edx
    mov word [esi + 0x20], ax
    mov eax, dword [esp + 0x3c]
    shl ebp, 2
    jmp near .copy_spawn_position

.type_two:
    movsx edi, di
    imul edi, edi, 0x2c
    mov eax, 0x1b
    xor ecx, ecx
    mov ebx, dword [edi + sprite_y]
    mov edx, dword [edi + sprite_x]
    call play_sound
    movsx eax, word [esp + 0x34]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite_x
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 8
    mov byte [esi + 0x15], 8
    mov word [esp + 0x40], ax
    mov byte [esi + 0x16], 0
    mov eax, dword [esp + 0x1c]
    mov byte [esi + 0x17], 0
    mov ebx, dword [esp + 0x20]
    mov dword [esi + 4], eax
    movsx eax, word [esp + 0x30]
    mov word [esi + 0xe], 0x311
    sar eax, 1
    mov dword [esi], ebp
    add ebx, eax
    mov dword [esi + 8], ebx
    mov ax, word [edi + sprite_angle]
    mov word [esi + 0x1e], 2
    mov ecx, 3
    mov word [esi + 0x26], 0x100

.store_type_two_velocity:
    mov ebp, edx
    mov word [esi + 0x28], 0
    shl ebp, 2
    mov word [esi + 0x2a], 0
    sub ebp, edx
    mov word [esi + 0x1c], ax
    mov eax, dword [esp + 0x38]
    shl ebp, 2
    mov word [esi + 0x20], ax
    mov eax, dword [esp + 0x3c]
    mov edi, projectile_positions

.copy_spawn_position:
    mov word [esi + 0x22], ax
    mov eax, dword [esp + 0x30]
    add edi, ebp
    mov word [esi + 0x24], ax
    rep movsd
    mov cl, byte [esp + 0x40]
    mov al, 1
    and cl, 7
    shl al, cl
    sar edx, 3
    not al
    and byte [edx + projectile_flags], al
    jmp near .append_projectile

.type_three:
    movsx edi, di
    imul edi, edi, 0x2c
    mov eax, 0x4f
    xor ecx, ecx
    mov ebx, dword [edi + sprite_y]
    mov edx, dword [edi + sprite_x]
    call play_sound
    movsx eax, word [esp + 0x34]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite_x
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 8
    mov byte [esi + 0x15], 8
    mov word [esp + 0x40], ax
    mov byte [esi + 0x16], 0
    mov eax, dword [esp + 0x1c]
    mov byte [esi + 0x17], 0
    mov ebx, dword [esp + 0x20]
    mov dword [esi + 4], eax
    movsx eax, word [esp + 0x30]
    mov word [esi + 0xe], 0x366
    sar eax, 1
    mov dword [esi], ebp
    add ebx, eax
    mov dword [esi + 8], ebx
    mov ax, word [edi + sprite_angle]
    mov word [esi + 0x1e], 2
    mov ecx, 3
    mov word [esi + 0x26], 0x3000
    jmp near .store_type_two_velocity

.type_four:
    movsx edx, di
    imul edx, edx, 0x2c
    mov eax, 0x9b
    xor ecx, ecx
    mov ebx, dword [edx + sprite_y]
    mov edx, dword [edx + sprite_x]
    call play_sound
    movsx eax, word [esp + 0x34]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite_x
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 8
    mov byte [esi + 0x15], 8
    mov byte [esi + 0x16], 0
    mov byte [esi + 0x17], 0
    mov word [esi + 0xe], 0x30e
    mov word [esi + 0x1c], 0
    mov word [esi + 0x1e], 2
    mov edi, projectile_positions
    mov word [esi + 0x26], 0x100
    mov ebx, dword [esp + 0x20]
    mov word [esi + 0x28], 0
    mov word [esp + 0x40], ax
    mov word [esi + 0x2a], 0
    mov eax, dword [esp + 0x1c]
    mov dword [esi], ebp
    mov ecx, 3
    mov dword [esi + 4], eax
    movsx eax, word [esp + 0x30]
    mov ebp, edx
    sar eax, 1
    shl ebp, 2
    add ebx, eax
    mov eax, dword [esp + 0x38]
    mov dword [esi + 8], ebx
    sub ebp, edx
    mov word [esi + 0x20], ax
    mov eax, dword [esp + 0x3c]
    shl ebp, 2
    mov word [esi + 0x22], ax
    mov eax, dword [esp + 0x30]
    add edi, ebp
    mov word [esi + 0x24], ax
    rep movsd
    mov cl, byte [esp + 0x40]
    mov al, 1
    and cl, 7
    sar edx, 3
    shl al, cl
    mov bh, byte [edx + projectile_flags]
    not al
    and bh, al
    mov byte [edx + projectile_flags], bh
    jmp near .append_projectile

.type_five:
    movsx ebx, di
    imul ebx, ebx, 0x2c
    xor ecx, ecx
    mov eax, dword [ebx + sprite_y]
    mov edx, dword [ebx + sprite_x]
    mov ebx, eax
    mov eax, 0xa2
    call play_sound
    movsx eax, word [esp + 0x34]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite_x
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 0x12
    mov byte [esi + 0x15], 0x12
    mov byte [esi + 0x16], 0
    mov byte [esi + 0x17], 0
    mov word [esi + 0xe], 0x366
    mov word [esi + 0x1c], 0
    mov word [esi + 0x26], 0x4200
    mov word [esi + 0x28], 0
    mov word [esp + 0x40], ax
    mov word [esi + 0x2a], 0
    mov eax, dword [esp + 0x1c]
    mov dword [esi], ebp
    mov ebx, dword [esp + 0x20]
    mov dword [esi + 4], eax
    mov ecx, 3
    mov word [esi + 0x1e], di
    movsx eax, word [esp + 0x30]
    mov edi, projectile_positions
    mov ebp, edx
    sar eax, 1
    shl ebp, 2
    add ebx, eax
    mov eax, dword [esp + 0x38]
    mov dword [esi + 8], ebx
    sub ebp, edx
    mov word [esi + 0x20], ax
    mov eax, dword [esp + 0x3c]
    shl ebp, 2

.store_velocity_yz:
    mov word [esi + 0x22], ax
    mov eax, dword [esp + 0x30]
    add edi, ebp
    mov word [esi + 0x24], ax
    rep movsd
    mov cl, byte [esp + 0x40]
    mov al, 1
    and cl, 7
    sar edx, 3
    shl al, cl
    mov bl, byte [edx + projectile_flags]
    not al
    and bl, al
    mov byte [edx + projectile_flags], bl

.append_projectile:
    mov dx, word [projectile_count]
    inc edx
    movsx eax, dx
    mov word [projectile_count], dx
    cmp eax, strict dword 0x1ff
    jle short .store_projectile
    push strict dword overflow_message
    push strict dword error_buffer
    call format_string
    add esp, 8
    mov eax, error_buffer
    call report_error

.store_projectile:
    movsx eax, word [projectile_count]
    mov edx, dword [esp + 0x40]
    mov word [nosplit eax*2 + projectile_list], dx

.return:
    add esp, 0x44
    pop ebp
    pop edi
    pop esi
    ret 8
