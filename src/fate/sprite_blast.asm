; Apply a nearby blast to the player and to eligible sprites in status list zero.
BITS 32
ORG 0x10d3a

adjust_status_value equ 0x1092e
random_value equ 0x602d0
absolute_long equ 0x602c3
play_sound equ 0x34f79
integer_square_root equ 0x4ca38
truncate_st0 equ 0x60304
start_sequence equ 0x11fdd
add_listed_sprite equ 0x134c2

blast_horizontal_scale equ 0xf8
blast_vertical_scale equ 0xfc
blast_vertical_limit equ 0x100
blast_vertical_velocity equ 0x104
player_x equ 0x5ad9c
player_y equ 0x5ad5c
sprite_actor_index equ 0x709dc
actor_kind equ 0x7f0a0
next_sprite_stat equ 0x1fbca0
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_xrepeat equ 0x2040b2
sprite_xvel equ 0x2040c0
sprite_yvel equ 0x2040c2
sprite_zvel equ 0x2040c4
sprite_lotag equ 0x2040c6
head_sprite_stat equ 0x28811c

apply_sprite_blast:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 28
    mov edi, eax
    cwde
    imul eax, eax, 44
    mov edx, [player_x]
    sub edx, [eax+sprite_x]
    mov ecx, [eax+sprite_y]
    mov [esp+20], edx
    mov edx, [player_y]
    mov eax, [esp+20]
    sub edx, ecx
    call absolute_long
    mov [esp+16], edx
    cmp eax, 1024
    jge short .start_list
    mov eax, edx
    call absolute_long
    cmp eax, 1024
    jge short .start_list
    mov eax, -400
    call adjust_status_value
    call random_value
    mov edx, eax
    mov ecx, 2
    sar edx, 31
    idiv ecx
    xor ebx, ebx
    lea eax, [edx+15]
    xor ecx, ecx
    xor edx, edx
    call play_sound
.start_list:
    mov bx, [head_sprite_stat]
    jmp near .check_list
.next_sprite:
    movsx eax, di
    imul eax, eax, 44
    movsx edx, bx
    mov si, [nosplit edx*2+next_sprite_stat]
    imul edx, edx, 44
    mov ebp, [eax+sprite_x]
    mov ecx, [edx+sprite_x]
    sub ecx, ebp
    mov [esp+20], ecx
    mov ebp, [eax+sprite_y]
    mov ecx, [edx+sprite_y]
    mov eax, [esp+20]
    sub ecx, ebp
    call absolute_long
    mov [esp+16], ecx
    cmp eax, 1024
    jge near .advance
    mov eax, ecx
    call absolute_long
    cmp eax, 1024
    jge near .advance
    mov ax, [edx+sprite_lotag]
    xor ah, ah
    cwde
    cmp eax, 100
    je short .apply_impulse
    cmp eax, 101
    jne near .check_tile
.apply_impulse:
    mov eax, [esp+20]
    imul eax, eax
    mov edx, [esp+16]
    imul edx, edx
    add eax, edx
    call integer_square_root
    mov [esp+4], eax
    fild dword [esp+4]
    fdivr dword [blast_horizontal_scale]
    imul eax, eax
    fstp dword [esp+8]
    mov [esp+4], eax
    fild dword [esp+4]
    fdivr dword [blast_vertical_scale]
    fst dword [esp]
    fcomp dword [blast_vertical_limit]
    fnstsw ax
    sahf
    jbe short .scale_velocity
    mov dword [esp], 0x40400000
.scale_velocity:
    fld dword [esp+8]
    fild dword [esp+20]
    fmul st1
    fld dword [esp]
    fxch st1
    fmul st1
    call truncate_st0
    fistp dword [esp+4]
    fild dword [esp+16]
    fmulp st2
    fxch st1
    fmul st1
    call truncate_st0
    fistp dword [esp+24]
    fmul dword [blast_vertical_velocity]
    movsx ecx, bx
    imul edx, ecx, 44
    call truncate_st0
    fistp dword [esp+12]
    mov eax, [esp+4]
    mov [edx+sprite_xvel], ax
    mov eax, [esp+24]
    mov [edx+sprite_yvel], ax
    mov eax, [esp+12]
    mov [edx+sprite_zvel], ax
    mov eax, ecx
    call start_sequence
    mov ax, [nosplit ecx*2+sprite_actor_index]
    cwde
    cmp eax, -1
    je short .add_sprite
    mov byte [eax+actor_kind], 3
    mov al, [edx+sprite_xrepeat]
    xor ecx, ecx
    add al, al
    mov [edx+sprite_cstat], cx
    mov [edx+sprite_xrepeat], al
.add_sprite:
    movsx eax, bx
    call add_listed_sprite
.check_tile:
    movsx eax, bx
    imul edx, eax, 44
    movsx edx, word [edx+sprite_tile]
    cmp edx, 0x154
    jne short .advance
    call start_sequence
.advance:
    mov ebx, esi
.check_list:
    test bx, bx
    jge near .next_sprite
    add esp, 28
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
