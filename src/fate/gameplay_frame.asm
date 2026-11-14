; Render player views, overlays, and the overhead map.
BITS 32
ORG 0x2c43d

weapon_state_570 equ 0x570
weapon_state_584 equ 0x584
weapon_state_591 equ 0x591
toggled_mode equ 0x2265
weapon_tile equ 0x2be4
close_hit_tile equ 0x2be6
cursor_mode equ 0x3be5
weapon_state_3be8 equ 0x3be8
network_enabled equ 0x3c98
weapon_state_3cda equ 0x3cda
weapon_state_3ce8 equ 0x3ce8
listener_index equ 0x3cfa
draw_status_panel equ 0x1067a
draw_inventory_panel equ 0x11628
weapon_state_12c2e equ 0x12c2e
weapon_state_12c32 equ 0x12c32
weapon_state_13651 equ 0x13651
weapon_state_13bc0 equ 0x13bc0
weapon_state_13cdc equ 0x13cdc
player_count equ 0x13ce0
local_player equ 0x13ce2
status_message_buffer equ 0x1df6c
board_state_209fc equ 0x209fc
update_sprite_view equ 0x2a32b
board_state_2ca2c equ 0x2ca2c
board_state_2ca6c equ 0x2ca6c
board_state_2caac equ 0x2caac
board_state_2caec equ 0x2caec
board_state_2cb2c equ 0x2cb2c
sub_2eb57 equ 0x2eb57
sub_3279b equ 0x3279b
finalize_board_state equ 0x34211
sub_345ac equ 0x345ac
sub_3460a equ 0x3460a
play_sound equ 0x34f79
sub_37f95 equ 0x37f95
sub_3850e equ 0x3850e
sub_40b49 equ 0x40b49
allocache equ 0x40c73
drawrooms equ 0x44796
sub_4b496 equ 0x4b496
drawmasks equ 0x4cc8a
sub_560de equ 0x560de
setview equ 0x56f0a
draw_tile equ 0x57181
drawmapview equ 0x59d2c
board_state_5ac8c equ 0x5ac8c
board_state_5ac8d equ 0x5ac8d
board_state_5ac8e equ 0x5ac8e
player_input_word equ 0x5ac8f
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
board_state_5ae1c equ 0x5ae1c
clearview equ 0x5cd99
setviewtotile equ 0x5d2f4
setviewback equ 0x5d46d
format_string equ 0x601f3
measure_message equ 0x60381
player_mode equ 0x62f1c
player_horizon equ 0x62f8c
board_state_6304c equ 0x6304c
player_angle equ 0x6308c
weapon_state_631dc equ 0x631dc
weapon_state_6772c equ 0x6772c
weapon_state_678bc equ 0x678bc
key_state equ 0x6793c
weapon_state_6797b equ 0x6797b
error_buffer equ 0x67e3c
weapon_state_7709c equ 0x7709c
view_state_770bc equ 0x770bc
weapon_state_77108 equ 0x77108
weapon_state_7aa70 equ 0x7aa70
board_state_7ded8 equ 0x7ded8
weapon_x_offset equ 0x7dee8
weapon_y_offset equ 0x7deea
board_state_7f874 equ 0x7f874
next_player equ 0x18fd78
first_player equ 0x19028a
engine_1ec6a0 equ 0x1ec6a0
weapon_state_1ecdc4 equ 0x1ecdc4
startumost equ 0x1f13a0
weapon_state_1f20ec equ 0x1f20ec
weapon_state_1f40ec equ 0x1f40ec
startdmost equ 0x1f8020
weapon_state_1f9c9e equ 0x1f9c9e
weapon_state_200128 equ 0x200128
weapon_state_203c98 equ 0x203c98
engine_27c3bc equ 0x27c3bc
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c
engine_287e7c equ 0x287e7c
totalclock equ 0x287e88
presentation_height equ 0x287e8c
presentation_width equ 0x287e90
video_backend equ 0x2891db

; Choose a viewport by player index in the two-by-two layout.
quadrant_view_dispatch:
    dd render_gameplay_frame.quadrant_view_0 - 0x10000
    dd render_gameplay_frame.quadrant_view_1 - 0x10000
    dd render_gameplay_frame.quadrant_view_2 - 0x10000
    dd render_gameplay_frame.quadrant_view_3 - 0x10000

; Choose a viewport by player index in the four-by-four layout.
grid_view_dispatch:
    dd render_gameplay_frame.grid_view_0 - 0x10000
    dd render_gameplay_frame.grid_view_1 - 0x10000
    dd render_gameplay_frame.grid_view_2 - 0x10000
    dd render_gameplay_frame.grid_view_3 - 0x10000
    dd render_gameplay_frame.grid_view_4 - 0x10000
    dd render_gameplay_frame.grid_view_5 - 0x10000
    dd render_gameplay_frame.grid_view_6 - 0x10000
    dd render_gameplay_frame.grid_view_7 - 0x10000
    dd render_gameplay_frame.grid_view_8 - 0x10000
    dd render_gameplay_frame.grid_view_9 - 0x10000
    dd render_gameplay_frame.grid_view_10 - 0x10000
    dd render_gameplay_frame.grid_view_11 - 0x10000
    dd render_gameplay_frame.grid_view_12 - 0x10000
    dd render_gameplay_frame.grid_view_13 - 0x10000
    dd render_gameplay_frame.grid_view_14 - 0x10000
    dd render_gameplay_frame.grid_view_15 - 0x10000

render_gameplay_frame:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x50
    push eax
    cmp edx, strict dword 0x10000
    jnl short .branch_2c4a2
    mov eax, edx
    jmp short .branch_2c4a7

.branch_2c4a2:
    mov eax, 0x10000

.branch_2c4a7:
    test eax, eax
    jng short .branch_2c4ba
    cmp edx, strict dword 0x10000
    jl short .branch_2c4bc
    mov edx, 0x10000
    jmp short .branch_2c4bc

.branch_2c4ba:
    xor edx, edx

.branch_2c4bc:
    movsx esi, word [esp]
    mov [view_state_770bc], edx
    call sub_345ac
    call sub_40b49
    mov eax, [nosplit esi*4 + player_x]
    mov edx, [nosplit esi*4 + board_state_2caac]
    mov ebx, [view_state_770bc]
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit esi*4 + board_state_2caac]
    mov edi, [nosplit esi*4 + board_state_2caec]
    add edx, eax
    mov eax, [nosplit esi*4 + player_y]
    mov ebx, [view_state_770bc]
    sub eax, edi
    mov [esp + 0x14], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit esi*4 + board_state_2caec]
    mov ebp, [nosplit esi*4 + board_state_2ca6c]
    add edx, eax
    mov eax, [nosplit esi*4 + player_z]
    mov ebx, [view_state_770bc]
    sub eax, ebp
    mov [esp + 0x10], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit esi*4 + board_state_2ca6c]
    add edx, eax
    mov [esp + 0x8], edx
    mov eax, [nosplit esi*4 + player_horizon]
    mov edx, [nosplit esi*4 + board_state_2ca2c]
    mov ebx, [view_state_770bc]
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit esi*4 + board_state_2ca2c]
    mov edi, [nosplit esi*4 + board_state_2cb2c]
    add edx, eax
    mov eax, [nosplit esi*4 + board_state_5ae1c]
    mov ebx, [view_state_770bc]
    sub eax, edi
    mov [esp + 0xc], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit esi*4 + board_state_2cb2c]
    add edx, eax
    movsx eax, word [nosplit esi*2 + player_angle]
    mov [esp + 0x4], edx
    add eax, strict dword 0x400
    movsx edx, word [nosplit esi*2 + board_state_209fc]
    sub eax, edx
    and eax, strict dword 0x7ff
    mov ebx, [view_state_770bc]
    sub eax, strict dword 0x400
    imul ebx
    shrd eax, edx, byte 0x10
    mov dx, [nosplit esi*2 + board_state_209fc]
    add edx, eax
    xor eax, eax
    mov al, [esi + player_mode]
    mov [esp + 0x50], edx
    cmp eax, 0x2
    jz near .branch_2cefe
    movsx eax, word [player_count]
    cmp eax, 0x1
    jng near .branch_2ca42
    cmp byte [network_enabled], 0x0
    jnz near .branch_2ca42
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x2
    jnz near .branch_2c7aa
    movsx ebp, word [first_player]
    jmp short .branch_2c62f

.branch_2c61f:
    xor bl, bl
    mov [ebp + weapon_state_6772c], bl
    movsx ebp, word [nosplit ebp*2 + next_player]

.branch_2c62f:
    test ebp, ebp
    jnl short .branch_2c61f
    movsx eax, word [esp]
    mov byte [eax + weapon_state_6772c], 0x1
    mov edx, [nosplit eax*4 + player_x]
    mov eax, [nosplit eax*4 + player_y]
    mov [esp + 0x44], eax
    movsx eax, word [player_count]
    sar eax, byte 0x2
    inc eax
    mov [esp + 0x48], edx
    mov [esp + 0x4c], eax
    jmp near .branch_2c79d

.branch_2c668:
    mov ecx, 0x80000000
    movsx ebp, word [first_player]
    jmp near .branch_2c747

.branch_2c679:
    cmp byte [ebp + weapon_state_6772c], 0x0
    jnz near .branch_2c73f
    mov edi, [esp + 0x48]
    mov edx, [esp + 0x44]
    mov esi, [nosplit ebp*4 + player_y]
    mov eax, [nosplit ebp*4 + player_x]
    sub esi, edx
    sub eax, edi
    mov edi, esi
    mov ebx, eax
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0xc
    mov esi, eax
    cmp eax, 0x40
    jnl short .branch_2c6c1
    mov edx, 0x4000
    jmp short .branch_2c6dd

.branch_2c6c1:
    cmp eax, strict dword 0x4000
    jng short .branch_2c6cf
    mov edx, 0x40
    jmp short .branch_2c6dd

.branch_2c6cf:
    mov eax, 0x100000
    mov edx, eax
    sar edx, byte 0x1f
    idiv esi
    mov edx, eax

.branch_2c6dd:
    mov eax, ebp
    shl eax, byte 0x2
    imul edx, [eax + weapon_state_678bc]
    mov esi, [eax + player_x]
    cmp esi, [eax + board_state_2caac]
    jnz short .branch_2c733
    mov esi, [eax + player_y]
    cmp esi, [eax + board_state_2caec]
    jnz short .branch_2c733
    mov esi, [eax + player_z]
    cmp esi, [eax + board_state_2ca6c]
    jnz short .branch_2c733
    mov bx, [nosplit ebp*2 + player_angle]
    cmp bx, [nosplit ebp*2 + board_state_209fc]
    jnz short .branch_2c733
    mov esi, [eax + player_horizon]
    cmp esi, [eax + board_state_2ca2c]
    jz short .branch_2c735

.branch_2c733:
    add edx, edx

.branch_2c735:
    cmp edx, ecx
    jng short .branch_2c73f
    mov ecx, edx
    mov [esp + 0x40], ebp

.branch_2c73f:
    movsx ebp, word [nosplit ebp*2 + next_player]

.branch_2c747:
    test ebp, ebp
    jnl near .branch_2c679
    movsx ebp, word [first_player]
    jmp short .branch_2c77b

.branch_2c758:
    mov edx, [nosplit ebp*4 + weapon_state_678bc]
    sar edx, byte 0x3
    mov edi, [nosplit ebp*4 + weapon_state_678bc]
    inc edx
    add edi, edx
    mov [nosplit ebp*4 + weapon_state_678bc], edi
    movsx ebp, word [nosplit ebp*2 + next_player]

.branch_2c77b:
    test ebp, ebp
    jnl short .branch_2c758
    mov eax, [esp + 0x40]
    mov esi, [esp + 0x4c]
    xor ecx, ecx
    dec esi
    mov [nosplit eax*4 + weapon_state_678bc], ecx
    mov cl, 0x1
    mov [esp + 0x4c], esi
    mov [eax + weapon_state_6772c], cl

.branch_2c79d:
    cmp dword [esp + 0x4c], 0x0
    jg near .branch_2c668
    jmp short .branch_2c7c7

.branch_2c7aa:
    mov dl, 0x1
    movsx ebp, word [first_player]
    jmp short .branch_2c7c3

.branch_2c7b5:
    mov [ebp + weapon_state_6772c], dl
    movsx ebp, word [nosplit ebp*2 + next_player]

.branch_2c7c3:
    test ebp, ebp
    jnl short .branch_2c7b5

.branch_2c7c7:
    xor eax, eax
    movsx ebp, word [first_player]
    mov [esp + 0x4c], eax
    jmp near .branch_2ca35

.branch_2c7d9:
    cmp byte [ebp + weapon_state_6772c], 0x0
    jz near .branch_2ca24
    mov ecx, [esp + 0x4c]
    movsx edi, word [player_count]
    mov eax, [presentation_width]
    mov ebx, [presentation_height]
    mov edx, [presentation_height]
    dec eax
    dec ebx
    sar edx, 1
    shl ecx, byte 0x2
    mov [esp + 0x34], eax
    mov eax, [presentation_width]
    mov [esp + 0x18], ecx
    sar eax, 1
    lea ecx, [edx-0x1]
    lea esi, [eax-0x1]
    cmp edi, 0x4
    jg short .check_grid_view
    cmp dword [esp + 0x4c], 0x3
    ja near .draw_player_view
    mov edi, [esp + 0x18]
    jmp dword near [cs:edi + quadrant_view_dispatch - 0x10000]

.quadrant_view_0:
    mov ebx, esi

.branch_2c83b:
    xor edx, edx

.branch_2c83d:
    xor eax, eax
    jmp short .set_player_view

.quadrant_view_1:
    mov ebx, [esp + 0x34]

.branch_2c845:
    xor edx, edx
    jmp short .set_player_view

.quadrant_view_2:
    mov ecx, ebx
    xor eax, eax
    jmp near .branch_2c921

.quadrant_view_3:
    mov ecx, ebx
    mov ebx, [esp + 0x34]

.set_player_view:
    call setview
    jmp near .draw_player_view

.check_grid_view:
    cmp dword [esp + 0x4c], 0xf
    ja near .draw_player_view
    mov edi, [presentation_width]
    sar edi, byte 0x2
    mov [esp + 0x3c], edi
    mov edi, [presentation_height]
    sar edi, byte 0x2
    mov [esp + 0x38], edi
    mov edi, [esp + 0x3c]
    dec edi
    mov [esp + 0x1c], edi
    mov edi, [esp + 0x38]
    dec edi
    mov [esp + 0x20], edi
    mov edi, [presentation_width]
    sub edi, [esp + 0x3c]
    mov [esp + 0x30], edi
    mov edi, [presentation_height]
    sub edi, [esp + 0x38]
    mov [esp + 0x2c], edi
    mov edi, [esp + 0x30]
    dec edi
    mov [esp + 0x24], edi
    mov edi, [esp + 0x2c]
    dec edi
    mov [esp + 0x28], edi
    mov edi, [esp + 0x18]
    jmp dword near [cs:edi + grid_view_dispatch - 0x10000]

.grid_view_0:
    mov ecx, [esp + 0x20]
    mov ebx, [esp + 0x1c]
    jmp near .branch_2c83b

.grid_view_1:
    mov ecx, [esp + 0x20]
    mov eax, [esp + 0x3c]
    mov ebx, esi
    jmp near .branch_2c845

.grid_view_2:
    mov ecx, [esp + 0x20]
    mov ebx, [esp + 0x24]
    jmp near .branch_2c845

.grid_view_3:
    mov ecx, [esp + 0x20]
    mov ebx, [esp + 0x34]
    mov eax, [esp + 0x30]
    jmp near .branch_2c845

.grid_view_4:
    mov ebx, [esp + 0x1c]
    mov edx, [esp + 0x38]
    jmp near .branch_2c83d

.grid_view_5:
    mov edx, [esp + 0x38]

.branch_2c91d:
    mov eax, [esp + 0x3c]

.branch_2c921:
    mov ebx, esi
    jmp near .set_player_view

.grid_view_6:
    mov ebx, [esp + 0x24]
    mov edx, [esp + 0x38]
    jmp near .set_player_view

.grid_view_7:
    mov ebx, [esp + 0x34]
    mov edx, [esp + 0x38]

.branch_2c93d:
    mov eax, [esp + 0x30]
    jmp near .set_player_view

.grid_view_8:
    mov ecx, [esp + 0x28]
    mov ebx, [esp + 0x1c]
    jmp near .branch_2c83d

.grid_view_9:
    mov ecx, [esp + 0x28]
    jmp short .branch_2c91d

.grid_view_10:
    mov ecx, [esp + 0x28]

.branch_2c95d:
    mov ebx, [esp + 0x24]
    jmp near .set_player_view

.grid_view_11:
    mov ecx, [esp + 0x28]
    mov ebx, [esp + 0x34]
    jmp short .branch_2c93d

.grid_view_12:
    mov edx, [esp + 0x2c]
    mov ecx, ebx
    xor eax, eax
    mov ebx, [esp + 0x1c]
    jmp near .set_player_view

.grid_view_13:
    mov edx, [esp + 0x2c]
    mov eax, [esp + 0x3c]
    mov ecx, ebx
    jmp short .branch_2c921

.grid_view_14:
    mov edx, [esp + 0x2c]
    mov ecx, ebx
    jmp short .branch_2c95d

.grid_view_15:
    mov edx, [esp + 0x2c]
    mov eax, [esp + 0x30]
    jmp near .quadrant_view_3

.draw_player_view:
    movsx edx, word [esp]
    lea eax, [ebp + ebp + 0x0]
    cmp ebp, edx
    jnz short .branch_2c9db
    movsx eax, word [eax + player_sector]
    mov ebx, [esp + 0xc]
    push eax
    movsx ecx, word [esp + 0x54]
    mov edx, [esp + 0x14]
    push ebx
    mov eax, [esp + 0x1c]
    mov ebx, [esp + 0x10]
    call drawrooms
    mov edx, [esp + 0x10]
    mov eax, [esp + 0x14]
    jmp short .draw_view_sprites

.branch_2c9db:
    movsx edx, word [eax + player_sector]
    movsx ecx, word [eax + player_angle]
    push edx
    mov edx, [nosplit ebp*4 + player_horizon]
    mov ebx, [nosplit ebp*4 + player_z]
    push edx
    mov eax, [nosplit ebp*4 + player_x]
    mov edx, [nosplit ebp*4 + player_y]
    call drawrooms
    mov edx, [nosplit ebp*4 + player_y]
    mov eax, [nosplit ebp*4 + player_x]

.draw_view_sprites:
    call update_sprite_view
    call drawmasks

.branch_2ca24:
    mov ecx, [esp + 0x4c]
    inc ecx
    movsx ebp, word [nosplit ebp*2 + next_player]
    mov [esp + 0x4c], ecx

.branch_2ca35:
    test ebp, ebp
    jnl near .branch_2c7d9
    jmp near .branch_2cefe

.branch_2ca42:
    mov esi, [weapon_state_3be8]
    test esi, esi
    jnz short .branch_2ca59
    cmp byte [weapon_state_3ce8], 0x0
    jz near .branch_2cb15

.branch_2ca59:
    mov dh, 0xff
    mov ebp, [weapon_state_203c98]
    mov [weapon_state_1f9c9e], dh
    test ebp, ebp
    jnz short .branch_2ca7f
    mov ebx, weapon_state_1f9c9e
    mov edx, 0x19000
    mov eax, weapon_state_203c98
    call allocache

.branch_2ca7f:
    test si, 0x3ff
    jnz short .branch_2caa1
    mov ebx, 0x140
    mov edx, 0xc8
    mov cl, [weapon_state_3ce8]
    mov eax, 0xffe
    sar ebx, cl
    sar edx, cl
    jmp short .branch_2cab5

.branch_2caa1:
    mov edx, 0x140
    mov cl, [weapon_state_3ce8]
    sar edx, cl
    mov eax, 0xffe
    mov ebx, edx

.branch_2cab5:
    call setviewtotile
    mov eax, esi
    and eax, strict dword 0x3ff
    cmp eax, strict dword 0x200
    jnz short .branch_2cb15
    mov edx, 0x104
    mov ebp, 0x3c
    mov cl, [weapon_state_3ce8]
    mov ebx, 0x1
    sar edx, cl
    sar ebp, cl
    mov [esp + 0x4c], edx
    dec ebp
    jmp short .branch_2cb11

.branch_2cae8:
    mov eax, [esp + 0x4c]
    xor edi, edi
    mov [nosplit ebp*2 + startumost], bx
    add eax, ebp
    mov [nosplit ebp*2 + startdmost], di
    dec ebp
    mov [nosplit eax*2 + startumost], bx
    mov [nosplit eax*2 + startdmost], di

.branch_2cb11:
    test ebp, ebp
    jnl short .branch_2cae8

.branch_2cb15:
    movsx eax, word [listener_index]
    cmp word [nosplit eax*2 + board_state_6304c], 0x0
    jng near .branch_2cbbb
    cmp dword [window_left], 0x0
    jnz near .branch_2cbbb
    cmp dword [window_right], strict dword 0x13f
    jnz near .branch_2cbbb
    cmp dword [engine_287e7c], strict dword 0x10000
    jnz short .branch_2cbbb
    test esi, esi
    jnz short .branch_2cbbb
    movsx eax, word [weapon_state_1f20ec]
    mov edx, 0xa0
    sar eax, 1
    sub edx, eax
    movsx eax, word [weapon_state_1f40ec]
    mov [esp + 0x48], edx
    mov edx, 0xb8
    sar eax, 1
    sub edx, eax
    mov [esp + 0x44], edx
    xor ebp, ebp
    mov ecx, [esp + 0x44]
    jmp short .branch_2cbb0

.branch_2cb88:
    xor eax, eax
    mov edx, [window_bottom]
    mov al, [ebp + weapon_state_631dc]
    inc edx
    add eax, ecx
    cmp edx, eax
    jnl short .branch_2cb9f
    mov eax, edx

.branch_2cb9f:
    mov edx, eax
    mov eax, [esp + 0x48]
    add eax, ebp
    inc ebp
    mov [nosplit eax*2 + startdmost], dx

.branch_2cbb0:
    movsx eax, word [weapon_state_1f20ec]
    cmp ebp, eax
    jl short .branch_2cb88

.branch_2cbbb:
    movsx eax, word [esp]
    movsx eax, word [nosplit eax*2 + player_sector]
    mov edi, [esp + 0xc]
    push eax
    movsx ecx, word [esp + 0x54]
    mov ebx, [esp + 0xc]
    push edi
    mov edx, [esp + 0x18]
    mov eax, [esp + 0x1c]
    call drawrooms
    mov edx, [esp + 0x10]
    mov eax, [esp + 0x14]
    call update_sprite_view
    call drawmasks
    test esi, esi
    jnz short .branch_2cc02
    cmp byte [weapon_state_3ce8], 0x0
    jz short .branch_2cc59

.branch_2cc02:
    call setviewback
    mov ebp, [window_bottom]
    push ebp
    mov eax, [window_right]
    push eax
    mov edx, [window_top]
    push edx
    mov ebx, [window_left]
    push ebx
    xor eax, eax
    push strict byte 0x46
    mov al, [weapon_state_3ce8]
    push strict byte 0x0
    shl eax, byte 0x10
    push strict byte 0x0
    lea ecx, [esi + 0x200]
    lea ebx, [eax + 0x10000]
    push strict dword 0xffe
    mov edx, 0x640000
    mov eax, 0xa00000
    call draw_tile
    mov byte [weapon_state_1f9c9e], 0x1

.branch_2cc59:
    movsx eax, word [listener_index]
    cmp word [nosplit eax*2 + board_state_6304c], 0x0
    jng near .branch_2cd2a
    cmp dword [window_left], 0x0
    jnz short .branch_2ccd4
    cmp dword [window_right], strict dword 0x13f
    jnz short .branch_2ccd4
    cmp dword [engine_287e7c], strict dword 0x10000
    jnz short .branch_2ccd4
    test esi, esi
    jnz short .branch_2ccd4
    movsx eax, word [weapon_state_1f20ec]
    mov edx, 0xa0
    sar eax, 1
    sub edx, eax
    mov eax, [window_bottom]
    inc eax
    xor ebp, ebp
    mov [esp + 0x44], eax
    mov [esp + 0x48], edx
    mov edx, [esp + 0x44]
    jmp short .branch_2ccc9

.branch_2ccba:
    mov eax, [esp + 0x48]
    add eax, ebp
    inc ebp
    mov [nosplit eax*2 + startdmost], dx

.branch_2ccc9:
    movsx eax, word [weapon_state_1f20ec]
    cmp ebp, eax
    jl short .branch_2ccba

.branch_2ccd4:
    mov eax, [window_bottom]
    push eax
    mov edx, [window_right]
    mov ebx, [window_top]
    push edx
    movsx eax, word [listener_index]
    push ebx
    movsx edx, word [nosplit eax*2 + player_sector]
    mov ecx, [window_left]
    mov eax, edx
    push ecx
    shl eax, byte 0x2
    push strict byte 0x2
    add eax, edx
    push strict byte 0x0
    movsx eax, byte [nosplit eax*8 + engine_27c3bc]
    push eax
    mov ebx, 0x10000
    xor ecx, ecx
    push strict byte 0x66
    mov edx, 0xb80000
    mov eax, 0xa00000
    call draw_tile

.branch_2cd2a:
    cmp word [close_hit_tile], 0x0
    jz near .branch_2cde6
    cmp dword [weapon_state_12c2e], -1
    jnz short .branch_2cd5b
    mov eax, [totalclock]
    mov [weapon_state_12c2e], eax
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov eax, 0x5e
    call play_sound

.branch_2cd5b:
    movsx eax, word [weapon_state_12c32]
    cmp eax, 0x3
    jg short .branch_2cdcc
    mov ebp, [window_bottom]
    push ebp
    mov edx, [window_right]
    push edx
    mov ebx, [window_top]
    push ebx
    mov ecx, [window_left]
    push ecx
    push strict byte 0x2
    push strict byte 0x0
    movsx edx, word [close_hit_tile]
    mov ebx, 0x40000
    push strict byte 0x0
    add eax, edx
    mov edx, 0x640000
    push eax
    xor ecx, ecx
    mov eax, 0xa00000
    call draw_tile
    mov eax, [totalclock]
    sub eax, [weapon_state_12c2e]
    cmp eax, 0xc
    jng short .branch_2cde6
    inc word [weapon_state_12c32]
    mov eax, [totalclock]
    mov [weapon_state_12c2e], eax
    jmp short .branch_2cde6

.branch_2cdcc:
    xor edi, edi
    mov [close_hit_tile], di
    mov [weapon_state_12c32], di
    mov dword [weapon_state_12c2e], 0xffffffff

.branch_2cde6:
    cmp word [weapon_tile], 0x0
    jz short .branch_2ce59
    movsx eax, word [weapon_y_offset]
    push eax
    movsx eax, word [weapon_x_offset]
    movsx edx, word [listener_index]
    push eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov bx, [eax + player_input_word]
    xor bl, bl
    and bh, 0x1
    movsx esi, byte [eax + board_state_5ac8c]
    movsx ecx, bx
    movsx ebx, byte [eax + board_state_5ac8e]
    movsx edx, word [nosplit edx*2 + player_sector]
    or esi, ebx
    movsx ebx, byte [eax + board_state_5ac8d]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    or ebx, esi
    movsx edx, byte [nosplit eax*8 + engine_27c3bc]
    movsx eax, word [weapon_tile]
    call sub_37f95

.branch_2ce59:
    xor eax, eax
    mov al, [weapon_state_13651]
    cmp byte [eax + key_state], 0x0
    jna short .branch_2ce77
    xor ch, ch
    mov [eax + key_state], ch
    not byte [cursor_mode]

.branch_2ce77:
    cmp byte [cursor_mode], 0x0
    jz short .branch_2ce85
    call draw_inventory_panel

.branch_2ce85:
    cmp word [toggled_mode], 0x0
    jz short .branch_2ce94
    call draw_status_panel

.branch_2ce94:
    push strict byte 0x1
    mov ecx, 0xffffffff
    mov ebx, 0x1f
    push strict dword error_buffer
    mov edx, 0x64
    xor eax, eax
    call sub_560de
    cmp dword [weapon_state_13bc0], 0x0
    jz short .branch_2cefe
    mov ebp, [window_bottom]
    push ebp
    mov eax, [window_right]
    push eax
    mov edx, [window_top]
    push edx
    mov ebx, [window_left]
    push ebx
    push strict byte 0x2
    push strict byte 0x0
    push strict byte 0x0
    xor ecx, ecx
    mov eax, 0x1300000
    push strict dword 0x35d
    mov edx, 0x100000
    mov ebx, 0x8000
    call draw_tile
    xor ecx, ecx
    mov [weapon_state_13bc0], ecx

.branch_2cefe:
    mov al, [weapon_state_1ecdc4]
    and al, 0x4
    and eax, strict dword 0xff
    test eax, eax
    jng short .branch_2cf2b
    mov al, [weapon_state_1ecdc4]
    and al, 0xfb
    mov esi, [weapon_state_200128]
    mov [weapon_state_1ecdc4], al
    test esi, esi
    jz short .branch_2cf2b
    mov eax, esi
    call sub_2eb57

.branch_2cf2b:
    movsx eax, word [esp]
    movsx edx, word [nosplit eax*2 + player_sector]
    mov ebx, edx
    sar ebx, byte 0x3
    mov bl, [ebx + engine_1ec6a0]
    mov ax, [nosplit eax*2 + player_sector]
    xor ah, ah
    and al, 0x7
    movsx ecx, ax
    mov eax, 0x1
    and ebx, strict dword 0xff
    shl eax, cl
    test ebx, eax
    jnz short .branch_2cf69
    mov eax, edx
    call finalize_board_state

.branch_2cf69:
    movsx esi, word [esp]
    xor eax, eax
    mov al, [esi + player_mode]
    cmp eax, 0x3
    jz short .branch_2cfce
    mov ax, [board_state_7ded8]
    mov ecx, 0x140
    movsx ebx, ax
    mov eax, [esp + 0x4]
    imul ebx
    idiv ecx
    mov ebx, eax
    mov ebp, eax
    xor eax, eax
    mov al, [esi + player_mode]
    cmp eax, 0x2
    jnz short .branch_2cfba
    movsx ecx, word [esp + 0x50]
    xor eax, eax
    mov edx, [esp + 0x10]
    call clearview
    mov eax, [esp + 0x14]
    call drawmapview

.branch_2cfba:
    movsx ecx, word [esp + 0x50]
    mov edx, [esp + 0x10]
    mov eax, [esp + 0x14]
    mov ebx, ebp
    call sub_3279b

.branch_2cfce:
    cmp byte [board_state_7f874], 0x0
    jna near .branch_2d096
    mov esi, 0x28
    xor ebp, ebp
    jmp near .branch_2d072

.branch_2cfe7:
    xor eax, eax
    mov [esp + 0x4c], eax
    jmp short .branch_2d005

.branch_2cfef:
    mov eax, edx
    lea ebx, [edx + 0x1]
    mov al, [eax + ebp + weapon_state_7aa70]
    mov [esp + 0x4c], ebx
    mov [edx + status_message_buffer], al

.branch_2d005:
    mov edx, [esp + 0x4c]
    cmp esi, edx
    jg short .branch_2cfef
    xor eax, eax
    lea edx, [esi + ebp]
    mov al, [board_state_7f874]
    cmp eax, edx
    jnl short .branch_2d027
    sub eax, ebp
    xor bl, bl
    mov [eax + status_message_buffer], bl
    jmp short .branch_2d02f

.branch_2d027:
    xor dh, dh
    mov [esi + status_message_buffer], dh

.branch_2d02f:
    xor edx, edx
    mov dl, [board_state_7f874]
    dec edx
    mov eax, edx
    sar edx, byte 0x1f
    idiv esi
    mov ebx, eax
    mov edx, ebp
    mov eax, ebp
    sar edx, byte 0x1f
    idiv esi
    push strict byte 0x0
    mov ecx, 0xffffffff
    shl eax, byte 0x3
    shl ebx, byte 0x3
    lea edx, [eax + 0xa0]
    push strict dword status_message_buffer
    sub edx, ebx
    xor eax, eax
    mov ebx, 0x97
    add ebp, esi
    call sub_560de

.branch_2d072:
    xor eax, eax
    mov al, [board_state_7f874]
    cmp ebp, eax
    jng near .branch_2cfe7
    mov eax, [totalclock]
    cmp eax, [weapon_state_7709c]
    jng short .branch_2d096
    xor dl, dl
    mov [board_state_7f874], dl

.branch_2d096:
    movsx eax, word [player_count]
    cmp eax, 0x2
    jl near .branch_2d133
    mov ax, [listener_index]
    cmp ax, [local_player]
    jz near .branch_2d133
    mov ecx, 0x1
    movsx ebp, word [first_player]
    movsx eax, word [listener_index]
    mov [esp + 0x4c], ecx
    jmp short .branch_2d0e7

.branch_2d0d2:
    cmp ebp, eax
    jz short .branch_2d0eb
    mov esi, [esp + 0x4c]
    inc esi
    movsx ebp, word [nosplit ebp*2 + next_player]
    mov [esp + 0x4c], esi

.branch_2d0e7:
    test ebp, ebp
    jnl short .branch_2d0d2

.branch_2d0eb:
    mov edi, [esp + 0x4c]
    push edi
    push strict dword weapon_state_570
    push strict dword status_message_buffer
    call format_string
    add esp, 0xc
    push strict byte 0x0
    push strict dword status_message_buffer
    mov eax, status_message_buffer
    call measure_message
    mov edx, [presentation_width]
    shl eax, byte 0x2
    sar edx, 1
    mov ecx, 0xffffffff
    sub edx, eax
    mov ebx, 0x18
    mov eax, edx
    xor edx, edx
    call sub_560de

.branch_2d133:
    cmp word [weapon_state_3cda], 0x0
    jz short .branch_2d15a
    push strict byte 0x0
    mov ebx, 0x1f
    mov edx, 0x54
    push strict dword weapon_state_584
    mov eax, 0x44
    xor ecx, ecx
    call sub_560de

.branch_2d15a:
    cmp byte [weapon_state_13cdc], 0x0
    jz short .branch_2d180
    push strict byte 0x0
    mov ebx, 0x1f
    mov edx, 0x5c
    push strict dword weapon_state_591
    mov eax, 0x44
    xor ecx, ecx
    call sub_560de

.branch_2d180:
    mov eax, [weapon_state_77108]
    cmp eax, [totalclock]
    jng short .branch_2d192
    call sub_3850e

.branch_2d192:
    call sub_4b496
    cmp byte [weapon_state_6797b], 0x0
    jna short .branch_2d1af
    xor ch, ch
    mov [weapon_state_6797b], ch
    xor byte [weapon_state_3ce8], 0x1

.branch_2d1af:
    call sub_3460a
    add esp, 0x54
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
