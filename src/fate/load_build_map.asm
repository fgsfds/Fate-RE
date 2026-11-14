; Read a Build v7 board and rebuild sprite lists and the starting sector.
BITS 32
ORG 0x49f89

open_game_file equ 0x41281
read_game_file equ 0x4137d
close_game_file equ 0x41503
restore_ebp_edi_esi equ 0x4918a
initialize_sprite_lists equ 0x507e3
insert_sprite equ 0x508b8
update_sector equ 0x542c4
show_2d_sectors equ 0x1ec6a0
show_2d_walls equ 0x1ec920
show_2d_sprites equ 0x1ecfa0
sprites equ 0x2040a0
sprite_sector equ 0x2040b8
sprite_status equ 0x2040ba
walls equ 0x2310a0
sectors equ 0x27c3a0
map_version equ 0x286b28
wall_count equ 0x289152
sector_count equ 0x289154

load_build_map:
    push esi
    push edi
    push ebp
    sub esp, 0xc
    push edx
    mov ebp, ebx
    mov [esp + 0x4], ecx
    xor edx, edx
    call open_game_file
    movsx esi, ax
    mov [esp + 0x8], eax
    cmp esi, -1
    jnz short .branch_49fbb
    mov ebx, 0x7
    mov eax, esi
    mov [map_version], ebx
    jmp near .branch_4a112

.branch_49fbb:
    mov ebx, 0x4
    mov edx, map_version
    mov eax, esi
    call read_game_file
    cmp dword [map_version], 0x7
    jz short .branch_49fdf
    mov eax, 0xffffffff
    jmp near .branch_4a112

.branch_49fdf:
    call initialize_sprite_lists
    mov ecx, 0x20
    mov edi, show_2d_sectors
    xor eax, eax
    rep stosd
    mov ecx, 0x80
    mov edi, show_2d_sprites
    mov ebx, 0x4
    rep stosd
    mov ecx, 0x100
    mov edi, show_2d_walls
    mov edx, [esp]
    rep stosd
    mov eax, esi
    call read_game_file
    mov ebx, 0x4
    mov edx, ebp
    mov eax, esi
    call read_game_file
    mov ebx, 0x4
    mov edx, [esp + 0x4]
    mov eax, esi
    call read_game_file
    mov ebx, 0x2
    mov edx, [esp + 0x20]
    mov eax, esi
    call read_game_file
    mov ebx, 0x2
    mov edx, [esp + 0x24]
    mov eax, esi
    call read_game_file
    mov ebx, 0x2
    mov edx, sector_count
    mov eax, esi
    call read_game_file
    movsx edx, word [sector_count]
    mov ebx, edx
    shl ebx, byte 0x2
    mov eax, esi
    add ebx, edx
    mov edx, sectors
    shl ebx, byte 0x3
    call read_game_file
    mov ebx, 0x2
    mov edx, wall_count
    mov eax, esi
    call read_game_file
    mov edx, walls
    movsx ebx, word [wall_count]
    mov eax, esi
    shl ebx, byte 0x5
    call read_game_file
    mov ebx, 0x2
    lea edx, [esp + 0xc]
    mov eax, esi
    call read_game_file
    movsx ebx, word [esp + 0xc]
    imul ebx, ebx, 0x2c
    mov edx, sprites
    mov eax, esi
    call read_game_file
    xor ebx, ebx
    jmp short .branch_4a0ee

.branch_4a0d4:
    movsx eax, bx
    imul eax, eax, 0x2c
    movsx edx, word [eax + sprite_status]
    movsx eax, word [eax + sprite_sector]
    inc ebx
    call insert_sprite

.branch_4a0ee:
    cmp bx, [esp + 0xc]
    jl short .branch_4a0d4
    mov eax, [esp]
    mov ebx, [esp + 0x24]
    mov edx, [ebp + 0x0]
    mov eax, [eax]
    call update_sector
    movsx eax, word [esp + 0x8]
    call close_game_file
    xor eax, eax

.branch_4a112:
    add esp, 0x10
    jmp near restore_ebp_edi_esi
