; Trace the player shot and spawn or resolve the selected projectile.
BITS 32
ORG 0x124a1

play_sound equ 0x34f79
hitscan equ 0x50f15
integer_square_root equ 0x4ca38
update_sector equ 0x542c4
insert_sprite equ 0x508b8
apply_projectile_hit equ 0x13115
start_sequence equ 0x11fdd
format_string equ 0x601f3
report_error equ 0x26a03
alternate_fire_requested equ 0x7dee6
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
player_angle equ 0x6308c
player_action equ 0x2297
sine_table equ 0x2300a0
player_horizon equ 0x62f8c
selected_weapon equ 0x2be2
weapon_stock equ 0x2277
player_sector equ 0x5acfc
sprite equ 0x2040a0
projectile_positions equ 0x20a2c
projectile_flags equ 0x1ecfa0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
projectile_count equ 0x2bee
projectile_list equ 0x7053c
projectile_overflow_message equ 0x1d4
error_buffer equ 0x67e3c

%macro spawn_projectile 3
    mov eax, %1
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    movsx eax, word [esp + 0x40]
    xor edx, edx
    call insert_sprite
    movsx edx, ax
    imul esi, edx, 0x2c
    add esi, sprite
    mov word [esi + 0xc], 0x80
    mov byte [esi + 0x10], 0xc0
    mov byte [esi + 0x11], 0
    mov byte [esi + 0x12], 0
    mov byte [esi + 0x14], 8
    mov byte [esi + 0x15], 8
    mov byte [esi + 0x16], 0
    mov byte [esi + 0x17], 0
    mov word [esi + 0xe], %2
    mov word [esi + 0x1c], 0
    mov word [esi + 0x1e], 1
    mov word [esi + 0x26], %3
    mov word [esi + 0x28], 0
    mov word [esi + 0x2a], 0
    mov word [esp + 0x1c], ax
    mov dword [esi], edi
    mov eax, dword [esp + 0x14]
    mov dword [esi + 4], ebp
    mov ecx, 3
    mov dword [esi + 8], eax
    mov edi, edx
    mov eax, dword [esp + 0x38]
    shl edi, 2
    mov word [esi + 0x20], ax
    sub edi, edx
    mov eax, dword [esp + 0x28]
    shl edi, 2
    mov word [esi + 0x22], ax
    mov eax, dword [esp + 0x30]
    add edi, projectile_positions
    mov word [esi + 0x24], ax
    rep movsd
%endmacro

fire_player_projectile:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x44
    mov esi, eax
    test ax, ax
    jne short .prepare_aim
    mov word [alternate_fire_requested], 1
    jmp near .return

.prepare_aim:
    mov eax, dword [player_z]
    mov edx, 2
    mov dword [esp + 0x10], eax
    movsx eax, word [player_angle]
    mov word [player_action], dx
    lea edx, [eax + 0x200]
    and edx, 0x7ff
    movsx edx, word [nosplit edx*2 + sine_table]
    sar edx, 5
    mov dword [esp + 0x38], edx
    mov dx, word [player_angle]
    and dh, 7
    movsx edx, dx
    movsx edx, word [nosplit edx*2 + sine_table]
    sar edx, 5
    mov bx, word [player_horizon]
    mov dword [esp + 0x28], edx
    mov edx, 0x64
    sub edx, ebx
    shl edx, 6
    mov edi, dword [player_x]
    mov dword [esp + 0x30], edx
    movsx edx, word [selected_weapon]
    mov ebp, dword [player_y]
    cmp edx, 3
    jne short .use_player_angle
    lea edx, [eax + 0x20f]
    add eax, 0xf
    and edx, 0x7ff
    and eax, 0x7ff
    movsx edx, word [nosplit edx*2 + sine_table]
    movsx eax, word [nosplit eax*2 + sine_table]
    sar edx, 5
    sar eax, 5
    mov dword [esp + 0x24], edx
    jmp short .store_aim

.use_player_angle:
    mov eax, dword [esp + 0x38]
    mov dword [esp + 0x24], eax
    mov eax, dword [esp + 0x28]

.store_aim:
    mov dword [esp + 0x2c], eax
    cmp si, 1
    jb short .trace_shot
    cmp si, 3
    ja short .trace_shot
    movsx eax, word [selected_weapon]
    dec word [nosplit eax*2 + weapon_stock]

.trace_shot:
    mov eax, esp
    push eax
    lea eax, [esp + 8]
    push eax
    lea eax, [esp + 0x10]
    push eax
    lea eax, [esp + 0x40]
    push eax
    lea eax, [esp + 0x28]
    push eax
    lea eax, [esp + 0x50]
    push eax
    movsx eax, word [esp + 0x48]
    mov ebx, dword [esp + 0x28]
    push eax
    movsx eax, word [esp + 0x44]
    movsx ecx, word [player_sector]
    push eax
    movsx eax, word [esp + 0x58]
    mov edx, ebp
    push eax
    add ebx, 0x800
    mov eax, edi
    call hitscan
    mov eax, dword [esp + 8]
    sub eax, edi
    imul eax, eax
    mov edx, dword [esp + 4]
    sub edx, ebp
    imul edx, edx
    add eax, edx
    call integer_square_root
    mov dword [esp + 0xc], eax
    cmp eax, strict dword 0x400
    jge short .use_muzzle_position
    movsx eax, word [esp + 0x34]
    cmp eax, -1
    je short .use_muzzle_position
    mov edx, 1
    mov edi, dword [esp + 8]
    mov ebp, dword [esp + 4]
    mov eax, dword [esp]
    mov dword [esp + 0x20], edx
    mov dword [esp + 0x14], eax
    jmp short .locate_sector

.use_muzzle_position:
    xor eax, eax
    mov dword [esp + 0x20], eax
    mov eax, dword [esp + 0x10]
    mov edx, dword [esp + 0xc]
    add eax, strict dword 0x800
    cmp edx, 0x200
    jl short .finish_muzzle_position
    movsx edx, word [esp + 0x24]
    add edi, edx
    movsx edx, word [esp + 0x2c]
    add ebp, edx

.finish_muzzle_position:
    movsx edx, word [esp + 0x30]
    add eax, edx
    mov dword [esp + 0x14], eax
    movsx edx, word [esp + 0x38]
    imul edx, edx
    movsx eax, word [esp + 0x28]
    imul eax, eax
    add eax, edx
    call integer_square_root
    mov dword [esp + 0xc], eax

.locate_sector:
    lea ebx, [esp + 0x40]
    mov edx, ebp
    mov eax, edi
    call update_sector
    cmp word [esp + 0x40], 0
    jl near .return
    cmp si, 2
    jb short .check_first_projectile
    jbe near .second_projectile
    cmp si, 3
    je near .third_projectile
    jmp near .check_immediate_hit

.check_first_projectile:
    cmp si, 1
    jne near .check_immediate_hit
    spawn_projectile 0x1b, 0x31d, 0x100
    mov cl, byte [esp + 0x1c]
    mov al, 1
    mov esi, edx
    and cl, 7
    sar esi, 3
    shl al, cl
    mov dh, byte [esi + projectile_flags]
    not al
    and dh, al
    mov byte [esi + projectile_flags], dh
    jmp near .check_immediate_hit

.second_projectile:
    spawn_projectile 0x2e, 0x30b, 0xa00
    mov cl, byte [esp + 0x1c]
    mov al, 1
    mov esi, edx
    and cl, 7
    sar esi, 3
    shl al, cl
    mov dl, byte [esi + projectile_flags]
    not al
    and dl, al
    mov byte [esi + projectile_flags], dl
    jmp near .check_immediate_hit

.third_projectile:
    spawn_projectile 0x40, 0x302, 0x100
    mov cl, byte [esp + 0x1c]
    mov al, 1
    and cl, 7
    mov esi, edx
    shl al, cl
    sar esi, 3
    not al
    and byte [esi + projectile_flags], al

.check_immediate_hit:
    movsx eax, word [esp + 0x20]
    cmp eax, 1
    jne short .append_projectile
    cmp dword [esp + 0xc], 0x2bc
    jle short .apply_immediate_hit
    movsx esi, word [esp + 0x1c]
    imul esi, esi, 0x2c
    movsx eax, word [esp + 0x38]
    mov ecx, dword [esi + sprite]
    mov edi, dword [esi + sprite_y]
    mov ebp, dword [esi + sprite_z]
    sub ecx, eax
    movsx eax, word [esp + 0x28]
    mov dword [esi + sprite], ecx
    sub edi, eax
    movsx eax, word [esp + 0x30]
    mov dword [esi + sprite_y], edi
    sub ebp, eax
    mov dword [esi + sprite_z], ebp

.apply_immediate_hit:
    movsx esi, word [esp + 0x1c]
    movsx eax, word [esp + 0x34]
    mov edx, esi
    call apply_projectile_hit
    mov eax, esi
    call start_sequence
    jmp short .return

.append_projectile:
    mov cx, word [projectile_count]
    inc ecx
    movsx eax, cx
    mov word [projectile_count], cx
    cmp eax, strict dword 0x1ff
    jle short .store_projectile
    push strict dword projectile_overflow_message
    push strict dword error_buffer
    call format_string
    add esp, 8
    mov eax, error_buffer
    call report_error

.store_projectile:
    movsx eax, word [projectile_count]
    mov edx, dword [esp + 0x1c]
    mov word [nosplit eax*2 + projectile_list], dx

.return:
    add esp, 0x44
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
