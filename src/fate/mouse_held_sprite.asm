; Update the mouse-held sprite, release velocity, and input lockout.
BITS 32
ORG 0x111a1

find_sprite_type equ 0x11035
spawn_sprite_at_position equ 0x11073
set_sprite_motion equ 0x339b9
get_z_range equ 0x562f9
add_listed_sprite equ 0x134c2
delete_sprite equ 0x50a09

advance_clock equ 0x229b
mouse_side equ 0x2bf0
mouse_forward equ 0x2bf2
mouse_vertical equ 0x2bf4
held_sprite_type equ 0x2bf6
held_sprite equ 0x2bf8
holding_sprite equ 0x2bfa
mouse_motion_disabled equ 0x2bfc
cursor_mode equ 0x3be5
release_timer equ 0x3e0c
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
player_angle equ 0x6308c
mouse_buttons equ 0x7dee2
vertical_bias equ 0x7f8c4
previous_x equ 0x7f8c8
previous_y equ 0x7f8cc
previous_z equ 0x7f8d0
tile_height equ 0x1f4020
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_yrepeat equ 0x2040b5
sprite_sector equ 0x2040b8
sprite_xvel equ 0x2040c0
sprite_yvel equ 0x2040c2
sprite_zvel equ 0x2040c4
sine_table equ 0x2300a0

update_mouse_held_sprite:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 28
    cmp word [held_sprite_type], 0
    je near .check_cancel
    cmp byte [cursor_mode], 0
    jne near .check_cancel
    mov ax, [mouse_buttons]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    je near .release
    movsx eax, word [holding_sprite]
    cmp eax, 1
    jge near .update_position
    mov ecx, 512
    movsx eax, word [held_sprite_type]
    mov di, [holding_sprite]
    xor ebx, ebx
    xor edx, edx
    mov [mouse_side], bx
    mov [mouse_forward], cx
    mov [mouse_vertical], bx
    inc edi
    mov [vertical_bias], edx
    mov [holding_sprite], di
    call find_sprite_type
    mov edx, eax
    mov eax, [player_x]
    mov [esp], eax
    mov eax, [player_y]
    mov [esp+4], eax
    mov eax, [player_z]
    movsx ebx, word [player_sector]
    mov [esp+8], eax
    movsx eax, dx
    mov edx, esp
    call spawn_sprite_at_position
    movsx edx, word [player_angle]
    add edx, strict dword 512
    and edx, 2047
    movsx edx, word [nosplit edx*2+sine_table]
    shl edx, 8
    xor ecx, ecx
    mov [esp], edx
    mov dx, [player_angle]
    push 0
    and dh, 7
    mov [held_sprite], ax
    movsx edx, dx
    push 1024
    movsx edx, word [nosplit edx*2+sine_table]
    cwde
    shl edx, 8
    push 1024
    mov [esp+16], edx
    mov ebx, edx
    mov edx, [esp+12]
    call set_sprite_motion
.update_position:
    movsx eax, word [held_sprite]
    imul eax, eax, 44
    mov edx, [eax+sprite_x]
    mov [previous_x], edx
    mov edx, [eax+sprite_y]
    mov eax, [eax+sprite_z]
    mov [previous_z], eax
    mov ax, [mouse_buttons]
    xor ah, ah
    and al, 2
    cwde
    mov [previous_y], edx
    test eax, eax
    je short .horizontal
    movsx eax, word [mouse_vertical]
    shl eax, 5
    mov [vertical_bias], eax
.horizontal:
    movsx edx, word [player_angle]
    lea eax, [edx+512]
    and eax, 2047
    movsx ecx, word [nosplit eax*2+sine_table]
    movsx eax, word [mouse_forward]
    mov ebx, ecx
    imul ebx, eax
    add ebx, ebx
    mov [esp], ebx
    mov bx, [player_angle]
    and bh, 7
    movsx ebx, bx
    movsx ebx, word [nosplit ebx*2+sine_table]
    imul eax, ebx
    add eax, eax
    mov [esp+4], eax
    lea eax, [edx+1024]
    and eax, 2047
    movsx edx, word [nosplit eax*2+sine_table]
    movsx eax, word [mouse_side]
    imul edx, eax
    imul eax, ecx
    mov ecx, [esp+4]
    add eax, eax
    movsx esi, word [held_sprite]
    sub ecx, eax
    imul eax, esi, 44
    push 0
    mov edi, [player_x]
    push 1024
    mov ebx, [esp+8]
    add edx, edx
    push 1024
    sub ebx, edx
    mov [esp+16], ecx
    mov [esp+12], ebx
    mov edx, [esp+16]
    mov ecx, ebx
    mov ebx, [player_y]
    sar ecx, 14
    sar edx, 14
    add ecx, edi
    add ebx, edx
    mov ebp, [eax+sprite_x]
    mov edi, [eax+sprite_y]
    mov eax, esi
    sub ecx, ebp
    sub ebx, edi
    mov edx, ecx
    shl ebx, 13
    shl edx, 13
    xor ecx, ecx
    call set_sprite_motion

    movsx eax, word [held_sprite]
    imul eax, eax, 44
    mov dx, [eax+sprite_cstat]
    xor dh, dh
    and dl, 0x80
    movsx edx, dx
    test edx, edx
    je short .no_sprite_height
    movsx edx, word [eax+sprite_tile]
    movsx edx, word [nosplit edx*2+tile_height]
    mov al, [eax+sprite_yrepeat]
    mov esi, eax
    and esi, 255
    imul esi, edx
    add esi, esi
    jmp short .query_z
.no_sprite_height:
    xor esi, esi
.query_z:
    push 0
    push 128
    lea eax, [esp+20]
    push eax
    lea eax, [esp+28]
    push eax
    lea eax, [esp+40]
    push eax
    lea eax, [esp+40]
    push eax
    movsx eax, word [held_sprite]
    imul eax, eax, 44
    movsx ecx, word [eax+sprite_sector]
    mov ebx, [eax+sprite_z]
    mov edx, [eax+sprite_y]
    mov eax, [eax+sprite_x]
    call get_z_range
    movsx eax, word [held_sprite]
    imul eax, eax, 44
    mov ebx, [player_z]
    mov ebp, [eax+sprite_z]
    mov edx, [vertical_bias]
    sub ebx, ebp
    add edx, ebx
    sar edx, 4
    add edx, ebp
    mov edi, [esp+16]
    lea ecx, [edx+esi]
    cmp ecx, edi
    jle short .check_ceiling
    mov [vertical_bias], ebx
    mov ebp, ebx
    mov ebx, edi
    neg ebp
    sub ebx, esi
    mov [vertical_bias], ebp
    mov [eax+sprite_z], ebx
.check_ceiling:
    mov eax, [esp+20]
    sub edx, esi
    cmp edx, eax
    jge short .settle_z
    movsx eax, word [held_sprite]
    imul eax, eax, 44
    mov edx, [player_z]
    mov ebx, [eax+sprite_z]
    mov edi, [esp+20]
    sub edx, ebx
    add esi, edi
    mov ecx, edx
    mov [vertical_bias], edx
    neg ecx
    mov [eax+sprite_z], esi
    mov [vertical_bias], ecx
.settle_z:
    movsx eax, word [held_sprite]
    imul eax, eax, 44
    mov edx, [player_z]
    mov ebp, [eax+sprite_z]
    mov ebx, [vertical_bias]
    sub edx, ebp
    add edx, ebx
    sar edx, 2
    lea ecx, [edx+ebp]
    mov [eax+sprite_z], ecx
    jmp near .check_lockout
.release:
    movsx esi, word [held_sprite]
    imul eax, esi, 44
    xor edx, edx
    mov cx, [previous_x]
    mov [held_sprite_type], dx
    mov dx, [eax+sprite_x]
    sub edx, ecx
    shl edx, 4
    mov [eax+sprite_xvel], dx
    mov di, [previous_y]
    mov dx, [eax+sprite_y]
    sub edx, edi
    shl edx, 4
    mov [eax+sprite_yvel], dx
    mov edx, -220
    xor ebx, ebx
    mov [eax+sprite_zvel], dx
    mov eax, esi
    mov [holding_sprite], bx
    call add_listed_sprite
    jmp short .check_lockout
.check_cancel:
    cmp word [holding_sprite], 0
    je short .check_lockout
    cmp word [held_sprite_type], 0
    je short .check_lockout
    xor esi, esi
    mov di, [held_sprite]
    mov [holding_sprite], si
    test di, di
    jl short .check_lockout
    movsx eax, di
    call delete_sprite
    mov word [held_sprite], -1
.check_lockout:
    cmp word [mouse_motion_disabled], 0
    je short .advance_timer
    cmp word [holding_sprite], 0
    jne short .advance_timer
    cmp word [release_timer], 0
    jne short .advance_timer
    mov word [release_timer], 1
.advance_timer:
    mov si, [release_timer]
    test si, si
    jle short .update_lockout
    cmp word [advance_clock], 0
    je short .check_timer
    mov eax, esi
    inc eax
    mov [release_timer], ax
.check_timer:
    movsx eax, word [release_timer]
    cmp eax, 8
    jl short .return
    xor edx, edx
    mov [mouse_motion_disabled], dx
    mov [release_timer], dx
    jmp short .return
.update_lockout:
    mov ax, [holding_sprite]
    mov [mouse_motion_disabled], ax
.return:
    add esp, 28
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
