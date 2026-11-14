; Advance the moving-sprite list, including gravity, bounces and impact events.
BITS 32
ORG 0x13860

clipmove equ 0x5291f
get_angle equ 0x4c94c
change_sprite_sector equ 0x50bc3
get_z_range equ 0x562f9
random_value equ 0x602d0
absolute_int equ 0x6032c
remove_sprite equ 0x10f9f
start_sequence equ 0x11fdd
append_sprite_event equ 0x10f4e
apply_sprite_blast equ 0x10d3a
moving_sprites equ 0x6fcbc
moving_sprite_count equ 0x2be8
ticks_per_step equ 0x7a994
tile_height equ 0x1f4020
sine_table equ 0x2300a0
wall_x equ 0x2310a0
wall_y equ 0x2310a4
wall_point2 equ 0x2310a8
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_xrepeat equ 0x2040b2
sprite_yrepeat equ 0x2040b5
sprite_sector equ 0x2040b8
sprite_xvel equ 0x2040c0
sprite_yvel equ 0x2040c2
sprite_zvel equ 0x2040c4
sprite_lotag equ 0x2040c6
sprite_hitag equ 0x2040c8
sprite_extra equ 0x2040ca
sprite_extra_high equ 0x2040cb

update_moving_sprite_physics:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x30
    mov dword [esp + 0x28], 1
    jmp near .check_count

.next_sprite:
    cwde
    mov ax, word [nosplit eax*2 + moving_sprites]
    mov dword [esp + 0x24], eax
    cwde
    imul eax, eax, 0x2c
    xor edx, edx
    mov dword [esp + 0x20], edx
    mov dword [esp + 8], edx
    mov dword [esp + 0x10], edx
    mov dx, word [eax + sprite_cstat]
    xor dh, dh
    and dl, 0x80
    movsx edx, dx
    test edx, edx
    je short .no_height_offset
    movsx edx, word [eax + sprite_tile]
    movsx edx, word [nosplit edx*2 + tile_height]
    mov al, byte [eax + sprite_yrepeat]
    and eax, 0xff
    imul eax, edx
    add eax, eax
    mov dword [esp + 0x1c], eax
    jmp short .move_and_apply_gravity

.no_height_offset:
    mov dword [esp + 0x1c], edx

.move_and_apply_gravity:
    movsx ebp, word [esp + 0x24]
    imul ebp, ebp, 0x2c
    mov edi, dword [ticks_per_step]
    movsx eax, word [ebp + sprite_zvel]
    imul eax, edi
    mov edx, dword [ebp + sprite_z]
    mov cx, word [ticks_per_step]
    add edx, eax
    imul eax, ecx, 0x64
    mov si, word [ebp + sprite_zvel]
    push 0
    add esi, eax
    mov ax, word [ebp + sprite_sector]
    mov ebx, dword [esp + 0x20]
    mov dword [esp + 0x30], eax
    xor eax, eax
    push ebx
    mov al, byte [ebp + sprite_xrepeat]
    push ebx
    add eax, eax
    push eax
    movsx eax, word [ebp + sprite_yvel]
    shl eax, 9
    imul eax, edi
    push eax
    movsx eax, word [ebp + sprite_xvel]
    shl eax, 9
    imul eax, edi
    push eax
    mov eax, sprite_x
    add eax, ebp
    mov dword [ebp + sprite_z], edx
    lea ebx, [eax + 8]
    lea ecx, [esp + 0x44]
    lea edx, [eax + 4]
    mov word [ebp + sprite_zvel], si
    call clipmove

    ; Reflect sufficiently fast horizontal motion along the hit wall.
    test ax, ax
    je near .check_sector_change
    xor edx, edx
    mov dx, ax
    mov dword [esp + 0x20], edx
    movsx edx, word [ebp + sprite_xvel]
    mov dword [esp + 4], edx
    mov ebx, dword [esp + 4]
    imul ebx, ebx
    movsx edx, word [ebp + sprite_yvel]
    mov dword [esp], edx
    imul edx, edx
    add edx, ebx
    cmp edx, 0x200
    jl near .check_sector_change
    and ah, 0xf
    and eax, 0xffff
    shl eax, 5
    movsx ecx, word [eax + wall_point2]
    mov esi, dword [eax + wall_y]
    shl ecx, 5
    mov edi, dword [eax + wall_x]
    mov ebx, dword [ecx + wall_x]
    mov edx, dword [ecx + wall_y]
    mov eax, ebx
    sub edx, esi
    sub eax, edi
    call get_angle
    lea ecx, [eax + 0x200]
    mov eax, ecx
    and eax, 0x7ff
    mov dx, word [nosplit eax*2 + sine_table]
    lea eax, [ecx + 0x200]
    and eax, 0x7ff
    movsx ebx, dx
    lea edi, [ecx + ecx]
    mov ax, word [nosplit eax*2 + sine_table]
    add edi, 0x200
    cwde
    and edi, 0x7ff
    imul ebx
    shrd eax, edx, 0xd
    mov dword [esp + 0x18], eax
    movsx edi, word [nosplit edi*2 + sine_table]
    movsx edx, word [ebp + sprite_yvel]
    mov ebx, dword [esp + 0x18]
    movsx eax, word [ebp + sprite_xvel]
    mov dword [esp], edx
    mov dword [esp + 4], eax
    neg eax
    neg edx
    mov dword [esp + 4], eax
    mov esi, eax
    mov eax, edx
    mov dword [esp], edx
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    mov esi, dword [esp]
    mov ebx, dword [esp + 0x18]
    sar eax, 2
    neg esi
    mov word [ebp + sprite_xvel], ax
    mov eax, dword [esp + 4]
    imul ebx
    xchg esi, eax
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, 0xe
    sar eax, 2
    mov word [ebp + sprite_yvel], ax

.check_sector_change:
    mov edi, dword [esp + 0x2c]
    test di, di
    jl short .check_floor_collision
    movsx ecx, word [esp + 0x24]
    imul edx, ecx, 0x2c
    cmp di, word [edx + sprite_sector]
    je short .check_floor_collision
    movsx edx, di
    mov eax, ecx
    call change_sprite_sector

    ; Probe floor clearance with the sprite blocking bit temporarily cleared.

.check_floor_collision:
    movsx ebp, word [esp + 0x24]
    imul ebp, ebp, 0x2c
    cmp word [ebp + sprite_zvel], 0
    jl near .check_collision_event
    mov si, word [ebp + sprite_cstat]
    mov eax, esi
    and al, 0xfe
    mov word [ebp + sprite_cstat], ax
    xor eax, eax
    mov al, byte [ebp + sprite_xrepeat]
    push 0
    add eax, eax
    push eax
    lea eax, [esp + 0x10]
    push eax
    lea eax, [esp + 0x18]
    push eax
    lea eax, [esp + 0x20]
    movsx ecx, word [ebp + sprite_sector]
    push eax
    lea eax, [esp + 0x28]
    mov ebx, dword [ebp + sprite_z]
    push eax
    mov edx, dword [ebp + sprite_y]
    mov eax, dword [ebp + sprite_x]
    call get_z_range
    movsx eax, word [ebp + sprite_zvel]
    mov word [ebp + sprite_cstat], si
    imul eax, dword [ticks_per_step]
    mov edx, dword [esp + 0xc]
    mov ebx, dword [esp + 0x1c]
    mov ecx, dword [ebp + sprite_z]
    sub edx, ebx
    sub edx, ecx
    cmp eax, edx
    jle near .check_collision_event
    cmp dword [esp + 0x20], 0
    jne short .check_floor_effect
    mov eax, dword [esp + 8]
    mov dword [esp + 0x20], eax

.check_floor_effect:
    movsx ebp, word [esp + 0x24]
    imul ebp, ebp, 0x2c
    movsx eax, word [ebp + sprite_tile]
    cmp eax, strict dword 0x23e
    je near .check_collision_event
    cmp eax, strict dword 0x262
    je near .check_collision_event
    cmp eax, strict dword 0x353
    je near .check_collision_event
    cmp dword [esp + 8], 0xc000
    jb short .bounce_off_floor
    call random_value
    and ah, 7
    mov edx, eax
    cwde
    add eax, strict dword 0x200
    and eax, 0x7ff
    movsx eax, word [nosplit eax*2 + sine_table]
    sar eax, 4
    and dh, 7
    mov word [ebp + sprite_xvel], ax
    movsx eax, dx
    mov ecx, 0xfffffed4
    movsx eax, word [nosplit eax*2 + sine_table]
    mov word [ebp + sprite_zvel], cx
    sar eax, 4
    mov ecx, dword [esp + 0x1c]
    mov word [ebp + sprite_yvel], ax
    mov eax, dword [esp + 0xc]
    sub eax, ecx
    mov dword [ebp + sprite_z], eax
    jmp near .check_collision_event

.bounce_off_floor:
    movsx eax, word [ebp + sprite_zvel]
    sar eax, 1
    neg eax
    mov edx, dword [esp + 0x1c]
    mov word [ebp + sprite_zvel], ax
    mov eax, dword [esp + 0xc]
    sub eax, edx
    mov dword [ebp + sprite_z], eax
    movsx eax, word [ebp + sprite_lotag]
    test ah, 0xff
    jne short .settle_or_remove
    movsx eax, word [ebp + sprite_zvel]
    call absolute_int
    mov edx, dword [ticks_per_step]
    mov ebx, eax
    mov eax, edx
    shl eax, 6
    add eax, edx
    cmp ebx, eax
    jg near .check_collision_event

.settle_or_remove:
    movsx eax, word [esp + 0x24]
    imul ebp, eax, 0x2c
    movsx edx, word [ebp + sprite_extra]
    test dh, 0x80
    je short .settle_sprite
    call remove_sprite
    jmp short .check_collision_event

.settle_sprite:
    mov edx, dword [esp + 0xc]
    xor esi, esi
    mov ebx, dword [esp + 0x1c]
    mov word [ebp + sprite_xvel], si
    sub edx, ebx
    mov word [ebp + sprite_yvel], si
    mov dword [ebp + sprite_z], edx
    movsx ecx, word [esp + 0x28]
    mov dl, byte [ebp + sprite_extra_high]
    mov word [ebp + sprite_zvel], si
    and dl, 0xbf
    mov bx, word [moving_sprite_count]
    mov byte [ebp + sprite_extra_high], dl
    movsx edx, word [moving_sprite_count]
    dec ebx
    mov dx, word [nosplit edx*2 + moving_sprites]
    mov word [moving_sprite_count], bx
    mov word [nosplit ecx*2 + moving_sprites], dx
    call start_sequence

    ; Dispatch tagged collisions and handle the three impact tiles.

.check_collision_event:
    cmp dword [esp + 0x20], 0
    je near .advance
    movsx eax, word [esp + 0x24]
    imul edx, eax, 0x2c
    mov dx, word [edx + sprite_hitag]
    xor dl, dl
    and dh, 2
    movsx edx, dx
    test edx, edx
    je short .check_impact_tiles
    xor edx, edx
    mov dx, word [esp + 0x20]
    call append_sprite_event

.check_impact_tiles:
    movsx eax, word [esp + 0x24]
    imul eax, eax, 0x2c
    movsx eax, word [eax + sprite_tile]
    cmp eax, strict dword 0x23e
    je short .trigger_impact
    cmp eax, strict dword 0x262
    je short .trigger_impact
    cmp eax, strict dword 0x353
    jne short .advance

.trigger_impact:
    cmp dword [esp + 0x20], 0x8000
    jae short .animate_impact
    movsx eax, word [esp + 0x24]
    imul eax, eax, 0x2c
    or byte [eax + sprite_extra_high], 0x20

.animate_impact:
    movsx ecx, word [esp + 0x24]
    mov eax, ecx
    call start_sequence
    mov eax, ecx
    imul ecx, ecx, 0x2c
    movsx edx, word [esp + 0x28]
    call apply_sprite_blast
    mov si, word [moving_sprite_count]
    movsx eax, word [moving_sprite_count]
    dec esi
    mov ax, word [nosplit eax*2 + moving_sprites]
    mov bl, byte [ecx + sprite_extra_high]
    mov word [moving_sprite_count], si
    and bl, 0xbf
    mov word [nosplit edx*2 + moving_sprites], ax
    mov byte [ecx + sprite_extra_high], bl

.advance:
    inc dword [esp + 0x28]

.check_count:
    mov eax, dword [esp + 0x28]
    cmp ax, word [moving_sprite_count]
    jle near .next_sprite
    add esp, 0x30
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
