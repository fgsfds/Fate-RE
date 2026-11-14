; Insert the player sprite and apply its palette lookup.
BITS 32
ORG 0x2e133

player_palette equ 0x1df6c
palette_color_ramp equ 0x1e02b
projectile_positions equ 0x20a2c
insert_sprite equ 0x508b8
set_brightness equ 0x593b4
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
player_sprite equ 0x62f2c
player_angle equ 0x6308c
sprite_visibility equ 0x1ecfa0
sprite equ 0x2040a0

; Map player indices 1 through 7 to their color ramps.
player_palette_dispatch:
    dd initialize_board_entry.apply_player_palette_1 - 0x10000
    dd initialize_board_entry.apply_player_palette_2 - 0x10000
    dd initialize_board_entry.apply_player_palette_3 - 0x10000
    dd initialize_board_entry.apply_player_palette_4 - 0x10000
    dd initialize_board_entry.apply_player_palette_5 - 0x10000
    dd initialize_board_entry.apply_player_palette_6 - 0x10000
    dd initialize_board_entry.apply_player_palette_7 - 0x10000

initialize_board_entry:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push eax
    movsx edi, ax
    lea ebx, [edi + edi]
    cmp word [ebx + player_sprite], 0x0
    jnl near .branch_2e347
    mov edx, 0x8
    movsx eax, word [ebx + player_sector]
    call insert_sprite
    mov [ebx + player_sprite], ax
    cwde
    imul eax, eax, 0x2c
    mov esi, sprite
    add esi, eax
    mov eax, edi
    mov edi, [nosplit edi*4 + player_x]
    mov [esi], edi
    mov edi, [nosplit eax*4 + player_y]
    mov [esi + 0x4], edi
    mov eax, [nosplit eax*4 + player_z]
    mov word [esi + 0xc], 0x101
    mov byte [esi + 0x10], 0x0
    mov byte [esi + 0x12], 0x20
    mov byte [esi + 0x14], 0x40
    mov byte [esi + 0x15], 0x40
    mov byte [esi + 0x16], 0x0
    mov byte [esi + 0x17], 0x0
    add eax, strict dword 0x2000
    mov word [esi + 0xe], 0x78
    mov [esi + 0x8], eax
    mov al, [esp]
    mov [esi + 0x11], al
    mov ax, [ebx + player_angle]
    mov word [esi + 0x20], 0x0
    mov word [esi + 0x22], 0x0
    mov word [esi + 0x24], 0x0
    mov word [esi + 0x26], 0x0
    mov word [esi + 0x28], 0x0
    mov [esi + 0x1c], ax
    mov eax, [esp]
    mov word [esi + 0x2a], 0x0
    add ah, 0x10
    mov [esi + 0x1e], ax
    movsx edi, word [ebx + player_sprite]
    mov eax, edi
    shl eax, byte 0x2
    sub eax, edi
    mov edi, projectile_positions
    shl eax, byte 0x2
    mov ecx, 0x3
    add edi, eax
    rep movsd
    movsx eax, word [ebx + player_sprite]
    mov cl, [ebx + player_sprite]
    mov bl, 0x1
    and cl, 0x7
    sar eax, byte 0x3
    shl bl, cl
    mov dl, [eax + sprite_visibility]
    not bl
    and dl, bl
    mov [eax + sprite_visibility], dl
    mov eax, [esp]
    dec eax
    cmp ax, strict word 0x6
    ja near .branch_2e31e
    and eax, strict dword 0xffff
    jmp dword near [cs:eax*4 + player_palette_dispatch - 0x10000]

.apply_player_palette_1:
    xor eax, eax
    jmp short .branch_2e284

.branch_2e278:
    mov bl, al
    inc eax
    add bl, 0x80
    mov [eax + palette_color_ramp], bl

.branch_2e284:
    cmp eax, 0x20
    jl short .branch_2e278
    jmp near .branch_2e330

.apply_player_palette_2:
    xor eax, eax
    jmp short .branch_2e29e

.branch_2e292:
    mov bl, al
    inc eax
    add bl, 0x20
    mov [eax + palette_color_ramp], bl

.branch_2e29e:
    cmp eax, 0x20
    jl short .branch_2e292
    jmp near .branch_2e330

.apply_player_palette_3:
    xor eax, eax
    jmp short .branch_2e2b8

.branch_2e2ac:
    mov bl, al
    inc eax
    add bl, 0xe0
    mov [eax + palette_color_ramp], bl

.branch_2e2b8:
    cmp eax, 0x20
    jl short .branch_2e2ac
    jmp near .branch_2e330

.apply_player_palette_4:
    xor eax, eax
    jmp short .branch_2e2d2

.branch_2e2c6:
    mov bl, al
    inc eax
    add bl, 0x40
    mov [eax + palette_color_ramp], bl

.branch_2e2d2:
    cmp eax, 0x20
    jl short .branch_2e2c6
    jmp short .branch_2e330

.apply_player_palette_5:
    xor eax, eax
    jmp short .branch_2e2e9

.branch_2e2dd:
    mov bl, al
    inc eax
    add bl, 0x60
    mov [eax + palette_color_ramp], bl

.branch_2e2e9:
    cmp eax, 0x20
    jl short .branch_2e2dd
    jmp short .branch_2e330

.apply_player_palette_6:
    xor eax, eax
    jmp short .branch_2e300

.branch_2e2f4:
    mov bl, al
    inc eax
    add bl, 0xa0
    mov [eax + palette_color_ramp], bl

.branch_2e300:
    cmp eax, 0x20
    jl short .branch_2e2f4
    jmp short .branch_2e330

.apply_player_palette_7:
    xor eax, eax
    jmp short .branch_2e317

.branch_2e30b:
    mov bl, al
    inc eax
    add bl, 0xc0
    mov [eax + palette_color_ramp], bl

.branch_2e317:
    cmp eax, 0x20
    jl short .branch_2e30b
    jmp short .branch_2e330

.branch_2e31e:
    xor eax, eax
    jmp short .branch_2e329

.branch_2e322:
    mov [eax + player_palette], al
    inc eax

.branch_2e329:
    cmp eax, strict dword 0x100
    jl short .branch_2e322

.branch_2e330:
    push strict byte 0x1
    movsx eax, word [esp + 0x4]
    mov edx, player_palette
    push strict byte 0x0
    xor ecx, ecx
    xor ebx, ebx
    call set_brightness

.branch_2e347:
    add esp, 0x4
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
