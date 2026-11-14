; Check crushed sprites.
BITS 32
ORG 0x40434

frame_state_14a3 equ 0x14a3
frame_state_14c8 equ 0x14c8
report_error equ 0x26a03
is_first_player_sprite equ 0x4037a
crush_sprite equ 0x40a48
tilesizy equ 0x1f4020
engine_1f9ca0 equ 0x1f9ca0
sprite_tile equ 0x2040ae
sprite_yrepeat equ 0x2040b5
ceil_base equ 0x27c3a4
floor_base equ 0x27c3a8
engine_28891e equ 0x28891e
numsectors equ 0x289154

check_crushed_sprites:
    push ebx
    push ecx
    push esi
    push edi
    mov ebx, eax
    mov edi, edx
    test dx, dx
    jl short .branch_4044a
    cmp di, [numsectors]
    jl short .branch_40454

.branch_4044a:
    mov eax, frame_state_14a3
    call report_error

.branch_40454:
    test ebx, ebx
    jnz short .branch_40462
    mov eax, frame_state_14c8
    call report_error

.branch_40462:
    movsx edx, di
    movsx edx, word [nosplit edx*2 + engine_28891e]
    jmp short .branch_404cd

.branch_4046f:
    movsx ebx, dx
    mov eax, ebx
    movsx ecx, word [nosplit edx*2 + engine_1f9ca0]
    call is_first_player_sprite
    test eax, eax
    jnz short .branch_404cb
    imul edx, edx, 0x2c
    movsx esi, word [edx + sprite_tile]
    movsx esi, word [nosplit esi*2 + tilesizy]
    mov dl, [edx + sprite_yrepeat]
    and edx, strict dword 0xff
    imul esi, edx
    movsx edx, di
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    add esi, esi
    mov edx, [nosplit eax*8 + floor_base]
    sub edx, esi
    cmp edx, [nosplit eax*8 + ceil_base]
    jnl short .branch_404cb
    mov eax, ebx
    call crush_sprite

.branch_404cb:
    mov edx, ecx

.branch_404cd:
    test edx, edx
    jnl short .branch_4046f
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
