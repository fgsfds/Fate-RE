; Process nearby sprite interactions and pickups for the player.
BITS 32
ORG 0x2949c

left_icon equ 0x2038
middle_icon equ 0x203a
right_icon equ 0x203c
interaction_state_225d equ 0x225d
interaction_state_2261 equ 0x2261
interaction_state_2263 equ 0x2263
interaction_state_2269 equ 0x2269
interaction_state_226b equ 0x226b
interaction_state_226d equ 0x226d
interaction_state_2279 equ 0x2279
interaction_state_227b equ 0x227b
interaction_state_227d equ 0x227d
interaction_state_3b9d equ 0x3b9d
adjust_status_value equ 0x1092e
remove_sprite equ 0x10f9f
lookup_sprite_tile equ 0x10ff3
play_sound equ 0x34f79
select_item equ 0x380d8
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
status_right_tenths equ 0x6319c
interaction_state_729dc equ 0x729dc
selected_inventory_slot equ 0x770c8
tile_height equ 0x1f4020
next_sprite_in_sector equ 0x1f9ca0
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_z equ 0x2040a8
sprite_cstat equ 0x2040ac
sprite_tile equ 0x2040ae
sprite_hitag equ 0x2040c8
sector_sprite_head equ 0x28891e
sector_count equ 0x289154

interact_with_sector_sprites:
    push ebx
    push ecx
    push esi
    push edi
    sub esp, 0x8
    push eax
    test dx, dx
    jl near .return
    cmp dx, [sector_count]
    jnl near .return
    movsx edi, dx
    mov di, [nosplit edi*2 + sector_sprite_head]
    jmp near .check_sprite_index

.inspect_sprite:
    movsx ebx, di
    mov ax, [nosplit ebx*2 + next_sprite_in_sector]
    imul ebx, ebx, 0x2c
    mov [esp + 0x4], eax
    movsx eax, word [ebx + sprite_cstat]
    test ah, 0x80
    jnz near .advance_sprite
    movsx ecx, word [esp]
    shl ecx, byte 0x2
    mov edx, [ebx + sprite_x]
    mov eax, [ecx + player_x]
    sub eax, edx
    test eax, eax
    jns short .measure_y_distance
    neg eax

.measure_y_distance:
    mov edx, eax
    mov esi, [ebx + sprite_y]
    mov eax, [ecx + player_y]
    sub eax, esi
    test eax, eax
    jns short .check_horizontal_distance
    neg eax

.check_horizontal_distance:
    add eax, edx
    cmp eax, strict dword 0x200
    jnl near .advance_sprite
    movsx eax, word [ebx + sprite_tile]
    mov edx, [ebx + sprite_z]
    movsx eax, word [nosplit eax*2 + tile_height]
    sar edx, byte 0x8
    sar eax, 1
    sub edx, eax
    mov eax, edx
    mov edx, [ecx + player_z]
    sar edx, byte 0x8
    sub edx, eax
    mov eax, edx
    test eax, eax
    jns short .check_vertical_distance
    neg eax

.check_vertical_distance:
    cmp eax, 0x37
    jg near .advance_sprite
    mov ax, [ebx + sprite_hitag]
    xor ah, ah
    cwde
    cmp eax, 0x1
    jl short .branch_29582
    cmp eax, 0xf
    jg short .branch_29582
    mov word [nosplit eax*2 + interaction_state_729dc], 0x1

.branch_29582:
    movsx eax, di
    imul eax, eax, 0x2c
    mov ax, [eax + sprite_tile]
    cmp ax, 0x24c
    jc near .branch_296b2
    jna near .collect_counted_item
    cmp ax, 0x27e
    jc near .branch_29639
    jna near .branch_29986
    cmp ax, 0x28f
    jc short .branch_295ff
    jna near .branch_297dc
    cmp ax, 0x2a1
    jc short .branch_295e0
    jna near .collect_middle_icon
    cmp ax, 0x2a2
    jna near .collect_right_icon
    cmp ax, 0x4b9
    jz near .branch_29a4a
    jmp near .advance_sprite

.branch_295e0:
    cmp ax, 0x297
    jc near .advance_sprite
    jna near .branch_297dc
    cmp ax, 0x2a0

.branch_295f4:
    jz near .branch_298c1
    jmp near .advance_sprite

.branch_295ff:
    cmp ax, 0x282
    jc short .branch_2962a
    jna near .branch_29b7a
    cmp ax, 0x286
    jc near .advance_sprite
    jna near .find_matching_tile
    cmp ax, 0x287
    jz near .branch_297dc
    jmp near .advance_sprite

.branch_2962a:
    cmp ax, 0x281
    jz near .branch_29b29
    jmp near .advance_sprite

.branch_29639:
    cmp ax, 0x25b
    jc short .branch_29683
    jna near .branch_2992d
    cmp ax, 0x262
    jc short .branch_2966a
    jna near .branch_297f3
    cmp ax, 0x263
    jna near .branch_29c16
    cmp ax, 0x265
    jz near .branch_29c63
    jmp near .advance_sprite

.branch_2966a:
    cmp ax, 0x25c
    jna near .find_matching_tile
    cmp ax, 0x260
    jz near .branch_29961
    jmp near .advance_sprite

.branch_29683:
    cmp ax, 0x24e
    jc near .branch_29a1f
    jna near .branch_2989b
    cmp ax, 0x253
    jc near .advance_sprite
    jna near .find_matching_tile
    cmp ax, 0x259
    jc near .advance_sprite
    jmp near .find_matching_tile

.branch_296b2:
    cmp ax, 0x1fc
    jc near .branch_29748
    jna near .collect_middle_icon
    cmp ax, 0x22c
    jc short .branch_2970e
    jna near .branch_29c16
    cmp ax, 0x242
    jc short .branch_296ef
    jna near .branch_299ab
    cmp ax, 0x24a
    jc near .advance_sprite
    jna near .branch_29a8e
    jmp near .branch_29ada

.branch_296ef:
    cmp ax, 0x234
    jc near .advance_sprite
    jna near .branch_29bcc
    cmp ax, 0x241
    jz near .branch_299cd
    jmp near .advance_sprite

.branch_2970e:
    cmp ax, 0x1ff
    jc short .branch_29739
    jna near .find_matching_tile
    cmp ax, 0x20f
    jc near .advance_sprite
    jna near .find_matching_tile
    cmp ax, 0x224
    jz near .branch_29821
    jmp near .advance_sprite

.branch_29739:
    cmp ax, 0x1fd
    jz near .collect_right_icon
    jmp near .advance_sprite

.branch_29748:
    cmp ax, 0x1b8
    jc short .branch_29798
    jna near .find_matching_tile
    cmp ax, 0x1da
    jc short .branch_29779
    jna near .branch_2980a
    cmp ax, 0x1ea
    jc near .advance_sprite
    jna near .find_matching_tile
    cmp ax, 0x1fb
    jmp near .branch_295f4

.branch_29779:
    cmp ax, 0x1ba
    jc near .advance_sprite
    jna near .branch_2980a
    cmp ax, 0x1ca
    jz near .branch_2980a
    jmp near .advance_sprite

.branch_29798:
    cmp ax, 0x183
    jc short .branch_297d1
    cmp ax, 0x184
    jna near .find_matching_tile
    cmp ax, 0x18a
    jc near .advance_sprite
    cmp ax, 0x18f
    jna near .find_matching_tile
    cmp ax, 0x191
    jc near .advance_sprite
    cmp ax, 0x192
    jna short .find_matching_tile
    jmp near .advance_sprite

.branch_297d1:
    cmp ax, 0x10c
    jz short .find_matching_tile
    jmp near .advance_sprite

.branch_297dc:
    mov eax, 0x14
    call select_item
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov eax, 0x8
    jmp short .branch_29836

.branch_297f3:
    mov eax, 0x5
    call select_item
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov eax, 0xa
    jmp short .branch_29836

.branch_2980a:
    mov eax, 0x15
    call select_item
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov eax, 0x6
    jmp short .branch_29836

.branch_29821:
    mov eax, 0xb
    call select_item
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov eax, 0xa

.branch_29836:
    call play_sound

.find_matching_tile:
    movsx eax, di
    imul eax, eax, 0x2c
    movsx eax, word [eax + sprite_tile]
    xor esi, esi
    call lookup_sprite_tile
    mov [esp + 0x8], eax
    jmp short .branch_2988e

.branch_29855:
    xor edx, edx
    jmp short .branch_29885

.branch_29859:
    movsx ebx, si
    mov eax, ebx
    shl eax, byte 0x2
    sub eax, ebx
    add ecx, ecx
    shl eax, byte 0x2
    add eax, ecx
    cmp word [eax + interaction_state_3b9d], 0x0
    jnz short .branch_29884
    mov edx, [esp + 0x8]
    mov [eax + interaction_state_3b9d], dx
    jmp near .consume_sprite

.branch_29884:
    inc edx

.branch_29885:
    movsx ecx, dx
    cmp ecx, 0x5
    jng short .branch_29859
    inc esi

.branch_2988e:
    movsx eax, si
    cmp eax, 0x5
    jng short .branch_29855
    jmp near .advance_sprite

.branch_2989b:
    mov ecx, 0x1
    mov eax, 0x7
    xor ebx, ebx
    xor edx, edx
    mov [interaction_state_2261], cx
    call select_item

.branch_298b5:
    mov eax, 0x8

.branch_298ba:
    xor ecx, ecx
    jmp near .play_pickup_sound

.branch_298c1:
    mov eax, 0xc
    mov dh, [left_icon]
    xor ecx, ecx
    or dh, 0x1
    xor ebx, ebx
    mov [left_icon], dh

.branch_298d9:
    call select_item
    mov eax, 0x6

.branch_298e3:
    xor edx, edx
    jmp near .play_pickup_sound

.collect_middle_icon:
    mov eax, 0xd
    mov dl, [middle_icon]
    xor ecx, ecx
    or dl, 0x1
    xor ebx, ebx
    mov [middle_icon], dl
    jmp short .branch_298d9

.collect_right_icon:
    mov ah, [right_icon]
    xor ecx, ecx
    or ah, 0x1
    xor ebx, ebx
    mov [right_icon], ah
    mov eax, 0xe
    xor edx, edx
    call select_item
    mov eax, 0x6
    jmp near .play_pickup_sound

.branch_2992d:
    cmp dword [status_right_tenths], strict dword 0x3e8
    jnl near .advance_sprite
    mov eax, 0xfa
    call adjust_status_value
    xor ecx, ecx
    xor ebx, ebx
    mov eax, 0x6

.branch_29950:
    xor edx, edx
    call select_item
    mov eax, 0x9
    jmp near .play_pickup_sound

.branch_29961:
    cmp dword [status_right_tenths], strict dword 0x3e8
    jnl near .advance_sprite
    mov eax, 0xfa
    call adjust_status_value
    xor ecx, ecx
    xor ebx, ebx
    mov eax, 0xa
    jmp short .branch_29950

.branch_29986:
    cmp dword [status_right_tenths], strict dword 0x3e8
    jnl near .advance_sprite
    mov eax, 0x96
    call adjust_status_value
    xor ecx, ecx
    xor ebx, ebx
    mov eax, 0x9
    jmp short .branch_29950

.branch_299ab:
    mov eax, 0x4
    mov dx, [interaction_state_2263]
    xor ecx, ecx
    add edx, strict dword 0x1f4
    xor ebx, ebx
    mov [interaction_state_2263], dx
    jmp near .branch_298d9

.branch_299cd:
    mov eax, 0x1
    mov bx, [interaction_state_225d]
    xor ecx, ecx
    add ebx, 0x14
    xor edx, edx
    mov [interaction_state_225d], bx
    call select_item
    mov eax, 0x8

.branch_299f1:
    xor ebx, ebx
    jmp near .play_pickup_sound

.collect_counted_item:
    mov eax, 0x1
    mov dx, [interaction_state_225d]
    xor ecx, ecx
    inc edx
    xor ebx, ebx
    mov [interaction_state_225d], dx
    call select_item
    mov eax, 0x8
    jmp near .branch_298e3

.branch_29a1f:
    mov eax, 0x1
    mov si, [interaction_state_225d]
    xor ecx, ecx
    xor ebx, ebx
    add esi, 0x5
    xor edx, edx
    mov [interaction_state_225d], si

.branch_29a3b:
    call select_item

.branch_29a40:
    mov eax, 0x8
    jmp near .play_pickup_sound

.branch_29a4a:
    xor eax, eax
    call select_item
    cmp word [interaction_state_2279], 0x0
    jnz short .branch_29a75
    cmp dword [selected_inventory_slot], 0x1
    jnl short .branch_29a75
    movsx eax, word [interaction_state_2269]
    cmp eax, 0x1
    jnz short .branch_29a75
    mov [selected_inventory_slot], eax

.branch_29a75:
    mov ax, [interaction_state_2279]
    xor ecx, ecx
    xor ebx, ebx
    add eax, strict dword 0x1e
    xor edx, edx
    mov [interaction_state_2279], ax
    jmp short .branch_29a40

.branch_29a8e:
    xor eax, eax
    call select_item
    cmp word [interaction_state_227b], 0x0
    jnz short .branch_29abe
    cmp dword [selected_inventory_slot], 0x2
    jnl short .branch_29abe
    movsx eax, word [interaction_state_226b]
    cmp eax, 0x1
    jnz short .branch_29abe
    mov dword [selected_inventory_slot], 0x2

.branch_29abe:
    mov ax, [interaction_state_227b]
    xor ecx, ecx
    xor ebx, ebx
    add eax, strict dword 0xf
    xor edx, edx
    mov [interaction_state_227b], ax
    jmp near .branch_29a40

.branch_29ada:
    xor eax, eax
    call select_item
    cmp word [interaction_state_227b], 0x0
    jnz short .branch_29b0a
    cmp dword [selected_inventory_slot], 0x2
    jnl short .branch_29b0a
    movsx eax, word [interaction_state_226b]
    cmp eax, 0x1
    jnz short .branch_29b0a
    mov dword [selected_inventory_slot], 0x2

.branch_29b0a:
    mov eax, 0x8
    mov cx, [interaction_state_227b]
    xor ebx, ebx
    add ecx, 0x32
    xor edx, edx
    mov [interaction_state_227b], cx
    jmp near .branch_298ba

.branch_29b29:
    xor eax, eax
    call select_item
    cmp word [interaction_state_227d], 0x0
    jnz short .branch_29b59
    cmp dword [selected_inventory_slot], 0x3
    jnl short .branch_29b59
    movsx eax, word [interaction_state_226d]
    cmp eax, 0x1
    jnz short .branch_29b59
    mov dword [selected_inventory_slot], 0x3

.branch_29b59:
    mov eax, 0x8
    mov si, [interaction_state_227d]
    xor ecx, ecx
    xor ebx, ebx
    add esi, 0x32
    xor edx, edx
    mov [interaction_state_227d], si
    jmp near .play_pickup_sound

.branch_29b7a:
    xor eax, eax
    call select_item
    cmp word [interaction_state_227d], 0x0
    jnz short .branch_29baa
    cmp dword [selected_inventory_slot], 0x3
    jnl short .branch_29baa
    movsx eax, word [interaction_state_226d]
    cmp eax, 0x1
    jnz short .branch_29baa
    mov dword [selected_inventory_slot], 0x3

.branch_29baa:
    mov eax, 0x8
    mov bx, [interaction_state_227d]
    xor ecx, ecx
    add ebx, strict dword 0x96
    xor edx, edx
    mov [interaction_state_227d], bx
    jmp near .branch_299f1

.branch_29bcc:
    cmp word [interaction_state_2269], 0x0
    jnz short .branch_29be9
    cmp dword [selected_inventory_slot], 0x1
    jnl short .branch_29be9
    mov dword [selected_inventory_slot], 0x1

.branch_29be9:
    mov esi, 0x1
    mov ax, [interaction_state_2279]
    xor ecx, ecx
    xor ebx, ebx
    add eax, strict dword 0x5
    xor edx, edx
    mov [interaction_state_2279], ax
    mov eax, 0x8
    mov [interaction_state_2269], si
    jmp near .branch_29a3b

.branch_29c16:
    cmp word [interaction_state_226b], 0x0
    jnz short .branch_29c33
    cmp dword [selected_inventory_slot], 0x2
    jnl short .branch_29c33
    mov dword [selected_inventory_slot], 0x2

.branch_29c33:
    mov ebx, 0x1
    mov eax, 0x2
    mov cx, [interaction_state_227b]
    xor edx, edx
    add ecx, 0x19
    mov [interaction_state_226b], bx
    mov [interaction_state_227b], cx
    call select_item
    xor ebx, ebx
    jmp near .branch_298b5

.branch_29c63:
    cmp word [interaction_state_226d], 0x0
    jnz short .branch_29c80
    cmp dword [selected_inventory_slot], 0x3
    jnl short .branch_29c80
    mov dword [selected_inventory_slot], 0x3

.branch_29c80:
    mov edx, 0x1
    mov eax, 0x3
    mov bx, [interaction_state_227d]
    xor ecx, ecx
    add ebx, 0x32
    mov [interaction_state_226d], dx
    mov [interaction_state_227d], bx
    call select_item
    xor edx, edx
    mov eax, 0x8
    xor ebx, ebx

.play_pickup_sound:
    call play_sound

.consume_sprite:
    movsx eax, di
    call remove_sprite

.advance_sprite:
    mov edi, [esp + 0x4]

.check_sprite_index:
    test di, di
    jnl near .inspect_sprite

.return:
    add esp, 0xc
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
