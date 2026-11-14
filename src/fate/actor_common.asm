; Handle shared actor recovery, death, and close-range hit reactions.
BITS 32
ORG 0x14897

start_sequence equ 0x11fdd
integer_square_root equ 0x4ca38
get_angle equ 0x4c94c
absolute_int equ 0x6032c
random_value equ 0x602d0
play_sound equ 0x34f79
actor_kind equ 0x7f0a0
actor_recovery_counter equ 0x7f295
actor_sprite_index equ 0x7dab8
advance_clock equ 0x229b
actor_health equ 0x7cefa
sprite_sector equ 0x2040b8
sector_floor_z equ 0x27c3a8
sprite_z equ 0x2040a8
sprite_xrepeat equ 0x2040b2
sprite_cstat equ 0x2040ac
alternate_fire_requested equ 0x7dee6
player_x equ 0x5ad9c
player_y equ 0x5ad5c
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
player_angle equ 0x6308c
player_input_word equ 0x5ac8f
actor_mode equ 0x7f67f
actor_tiles equ 0x7abc0

update_actor_common:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov esi, eax
    cwde
    xor edx, edx
    mov dl, byte [eax + actor_kind]
    cmp edx, 3
    je near .return
    mov dl, byte [eax + actor_recovery_counter]
    mov bx, word [nosplit eax*2 + actor_sprite_index]
    test dl, dl
    je short .check_health
    cmp word [advance_clock], 0
    je short .check_health
    inc byte [eax + actor_recovery_counter]
    xor edx, edx
    mov dl, byte [eax + actor_recovery_counter]
    cmp edx, 6
    jle short .check_health
    xor cl, cl
    mov byte [eax + actor_recovery_counter], cl
    mov byte [eax + actor_kind], cl

.check_health:
    movsx edi, si
    cmp word [nosplit edi*2 + actor_health], 0
    jg short .check_close_attack
    movsx ecx, bx
    imul eax, ecx, 0x2c
    movsx ebx, word [eax + sprite_sector]
    mov edx, ebx
    shl edx, 2
    add edx, ebx
    mov edx, dword [nosplit edx*8 + sector_floor_z]
    mov dword [eax + sprite_z], edx
    xor esi, esi
    mov dl, byte [eax + sprite_xrepeat]
    mov word [eax + sprite_cstat], si
    add dl, dl
    mov byte [eax + sprite_xrepeat], dl
    mov dl, 3
    mov eax, ecx
    mov byte [edi + actor_kind], dl
    call start_sequence
    jmp near .return

.check_close_attack:
    cmp word [alternate_fire_requested], 0
    je near .check_hit_reaction
    movsx eax, bx
    imul eax, eax, 0x2c
    mov edx, dword [player_x]
    mov ecx, dword [eax + sprite_x]
    mov edi, dword [player_y]
    sub ecx, edx
    mov edx, dword [eax + sprite_y]
    sub edx, edi
    mov edi, ecx
    imul edi, ecx
    mov eax, edx
    imul eax, edx
    add eax, edi
    call integer_square_root
    cmp eax, strict dword 0x15e
    jge near .check_hit_reaction
    mov eax, ecx
    call get_angle
    mov dx, word [player_angle]
    movsx ecx, ax
    movsx eax, dx
    sub ecx, eax
    mov eax, ecx
    call absolute_int
    movsx ecx, ax
    mov edx, eax
    cmp ecx, 0x400
    jle short .check_attack_angle
    mov edx, 0x7ff
    sub edx, eax

.check_attack_angle:
    movsx eax, dx
    cmp eax, 0x78
    jge short .check_hit_reaction
    movsx eax, word [player_input_word]
    sar eax, 0xd
    test al, 7
    jne short .apply_heavy_hit
    call random_value
    and eax, 3
    cmp eax, 3
    je short .apply_light_hit
    movsx eax, si
    mov al, byte [eax + actor_mode]
    and eax, 0xff
    cmp eax, 2
    jne short .check_hit_reaction

.apply_light_hit:
    movsx eax, si
    mov cx, word [nosplit eax*2 + actor_health]
    mov dh, 5
    sub ecx, 0xc8
    mov byte [eax + actor_kind], dh
    mov word [nosplit eax*2 + actor_health], cx
    jmp short .check_hit_reaction

.apply_heavy_hit:
    movsx eax, si
    mov byte [eax + actor_kind], 4
    sub word [nosplit eax*2 + actor_health], 0x12c

.check_hit_reaction:
    movsx eax, si
    mov al, byte [eax + actor_kind]
    and eax, 0xff
    cmp eax, 4
    je short .check_recovery
    cmp eax, 5
    jne near .return

.check_recovery:
    movsx eax, si
    cmp byte [eax + actor_recovery_counter], 0
    jne near .return
    mov edx, eax
    shl eax, 3
    add eax, edx
    mov ax, word [nosplit eax*2 + actor_tiles]
    cmp ax, 0x9b8
    jb short .check_first_sound
    jbe short .second_sound
    cmp ax, 0xa02
    jb near .start_recovery
    jbe short .third_sound
    cmp ax, 0xa70
    je near .fourth_sound
    jmp near .start_recovery

.check_first_sound:
    cmp ax, 0x966
    jne near .start_recovery
    movsx eax, bx
    imul eax, eax, 0x2c
    mov ebx, dword [eax + sprite_y]
    mov edi, dword [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 4
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x24]
    jmp short .play_reaction

.second_sound:
    movsx eax, bx
    imul eax, eax, 0x2c
    mov ebx, dword [eax + sprite_y]
    mov edi, dword [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 2
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x3a]
    jmp short .play_reaction

.third_sound:
    movsx eax, bx
    imul eax, eax, 0x2c
    mov ebx, dword [eax + sprite_y]
    mov edi, dword [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 2
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x57]
    jmp short .play_reaction

.fourth_sound:
    movsx eax, bx
    imul eax, eax, 0x2c
    mov ebx, dword [eax + sprite_y]
    mov edi, dword [eax + sprite_x]
    call random_value
    mov edx, eax
    mov ecx, 2
    sar edx, 0x1f
    idiv ecx
    lea eax, [edx + 0x49]

.play_reaction:
    xor ecx, ecx
    mov edx, edi
    call play_sound

.start_recovery:
    movsx eax, si
    mov byte [eax + actor_recovery_counter], 3

.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
