; Draw the inventory grid and handle cursor selection, scrolling, and item transfers.
BITS 32
ORG 0x11628

draw_tile equ 0x57181
absolute_int equ 0x6032c
play_sound equ 0x34f79
select_item equ 0x380d8
window_right equ 0x286b98
window_left equ 0x286b9c
window_bottom equ 0x286b90
window_top equ 0x286b94
occupied_rows equ 0x7f87c
inventory_grid equ 0x3b9d
inventory_scroll equ 0x3e10
scroll_row equ 0x7f877
scroll_step equ 0x7a994
cursor_y equ 0x2bf2
cursor_x equ 0x2bf0
held_item equ 0x2bf6
item_groups equ 0x3e14
mouse_buttons equ 0x7dee2
button_latch equ 0x3e12
original_row equ 0x7f8dc
original_column equ 0x7f8da
original_item equ 0x7f8d8
active_player equ 0x13654
player_item_mode equ 0x6793c
selection_3_stock equ 0x227d
selection_3_enabled equ 0x226d
selected_item equ 0x770c8

draw_inventory_panel:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x38
    mov eax, dword [window_right]
    mov edx, dword [window_left]
    xor esi, esi
    sub eax, edx
    mov dword [esp + 0x14], esi
    cmp eax, strict dword 0x27f
    jne short .check_width_400
    mov ebp, 0x78
    mov eax, 0x1fa
    mov edx, 0x1d
    mov ebx, 0x6a
    mov dword [esp + 0xc], ebp
    mov dword [esp + 4], eax
    mov dword [esp + 8], edx
    mov dword [esp], ebx
    jmp near .draw_panel

.check_width_400:
    cmp eax, strict dword 0x18f
    jne short .check_width_360
    mov eax, 0x4b
    mov edx, 0x13c
    mov ebx, 0x18
    mov ecx, 0x58
    mov dword [esp + 0xc], eax
    mov dword [esp + 4], edx
    mov dword [esp + 8], ebx
    mov dword [esp], ecx
    jmp short .draw_panel

.check_width_360:
    cmp eax, strict dword 0x167
    jne short .default_width
    mov edx, 0x44
    mov ebx, 0x11d
    mov ecx, 0x16
    mov ebp, 0x4f
    mov dword [esp + 0xc], edx
    mov dword [esp + 4], ebx
    mov dword [esp + 8], ecx
    mov dword [esp], ebp
    jmp short .draw_panel

.default_width:
    mov ebx, 0x3c
    mov ecx, 0xfd
    mov ebp, 0xc
    mov eax, 0x2c
    mov dword [esp + 0xc], ebx
    mov dword [esp + 4], ecx
    mov dword [esp + 8], ebp
    mov dword [esp], eax

; Draw the panel, then build a mask of occupied rows.
.draw_panel:
    mov ecx, dword [window_bottom]
    push ecx
    mov ebp, dword [window_right]
    push ebp
    mov eax, dword [window_top]
    push eax
    mov edx, dword [window_left]
    push edx
    push 0x12
    push 0
    push 0
    mov ebx, 0x10000
    xor ecx, ecx
    push strict dword 0x82d
    mov eax, 0x3d0000
    mov edx, 0x40000
    call draw_tile
    xor ah, ah
    xor ebx, ebx
    mov byte [occupied_rows], ah
    mov word [esp + 0x24], bx
    jmp short .check_mask_row

.start_mask_row:
    xor edx, edx
    mov dword [esp + 0x28], edx
    jmp short .check_mask_column

.scan_mask_cell:
    movsx ebx, word [esp + 0x24]
    mov eax, ebx
    shl eax, 2
    add edx, edx
    sub eax, ebx
    cmp word [edx + eax*4 + inventory_grid], 0
    je short .advance_mask_column
    mov cl, byte [esp + 0x24]
    mov al, 1
    mov bl, byte [occupied_rows]
    shl al, cl
    or bl, al
    mov byte [occupied_rows], bl

.advance_mask_column:
    inc dword [esp + 0x28]

.check_mask_column:
    movsx edx, word [esp + 0x28]
    cmp edx, 5
    jle short .scan_mask_cell
    inc word [esp + 0x24]

.check_mask_row:
    movsx eax, word [esp + 0x24]
    cmp eax, 5
    jle short .start_mask_row
    movsx edx, word [inventory_scroll]
    add edx, 0x5c
    mov ebx, 5
    mov eax, edx
    sar edx, 0x1f
    idiv ebx
    sub eax, 0x20
    call absolute_int
    mov edx, eax
    mov ebx, 6
    sar edx, 0x1f
    idiv ebx
    mov dl, byte [occupied_rows]
    mov byte [scroll_row], al
    test dl, dl
    je short .check_up_arrow
    mov cl, al
    mov eax, 1
    shl eax, cl
    xor ebx, ebx
    mov edx, eax
    mov bl, byte [occupied_rows]
    not edx
    and edx, ebx
    cmp edx, eax
    setg al
    mov edx, 1
    xor ebx, ebx
    shl edx, cl
    mov bl, byte [occupied_rows]
    not edx
    and edx, ebx
    xor ah, ah
    shl edx, cl
    mov dword [esp + 0x14], eax
    cmp edx, 1
    jle short .hide_up_arrow
    test cl, cl
    je short .hide_up_arrow
    mov esi, 1
    jmp short .check_up_arrow

.hide_up_arrow:
    xor esi, esi

.check_up_arrow:
    test si, si
    je short .check_down_arrow
    mov ebx, dword [window_bottom]
    push ebx
    mov ecx, dword [window_right]
    push ecx
    mov esi, dword [window_top]
    push esi
    mov ebp, dword [window_left]
    push ebp
    push 0x12
    push 0
    push 0
    mov edx, 0x40000
    mov eax, 0x980000
    push strict dword 0x17d
    mov ebx, 0x10000
    xor ecx, ecx
    call draw_tile

.check_down_arrow:
    cmp word [esp + 0x14], 0
    je short .check_scroll_input
    mov eax, dword [window_bottom]
    push eax
    mov edx, dword [window_right]
    push edx
    mov ebx, dword [window_top]
    push ebx
    mov ecx, dword [window_left]
    push ecx
    push 0x12
    push 0
    push 0
    mov eax, 0x980000
    mov edx, 0x2d0000
    push strict dword 0x17e
    mov ebx, 0x10000
    xor ecx, ecx
    call draw_tile

.check_scroll_input:
    mov dx, word [scroll_step]
    movsx eax, word [cursor_y]
    add edx, edx
    cmp eax, 0x5b
    jne short .check_scroll_up
    movsx eax, word [inventory_scroll]
    cmp eax, 0x44
    jge short .start_grid
    mov bx, word [inventory_scroll]
    add ebx, edx
    movsx eax, bx
    mov word [inventory_scroll], bx
    cmp eax, 0x44
    jle short .start_grid
    mov word [inventory_scroll], 0x44
    jmp short .start_grid

.check_scroll_up:
    cmp eax, 0x6e
    jne short .start_grid
    movsx eax, word [inventory_scroll]
    cmp eax, -0x5c
    jl short .start_grid
    mov si, word [inventory_scroll]
    sub esi, edx
    movsx eax, si
    mov word [inventory_scroll], si
    cmp eax, -0x5c
    jge short .start_grid
    mov word [inventory_scroll], 0xffa4

; Visit each visible cell and remember the row and column under the cursor.
.start_grid:
    mov esi, 0x1f
    xor eax, eax
    mov dword [esp + 0x34], esi
    mov word [esp + 0x24], ax
    jmp near .check_grid_row

.start_grid_row:
    mov edx, 0x54
    xor ebx, ebx
    mov dword [esp + 0x20], edx
    mov dword [esp + 0x28], ebx
    jmp near .check_grid_column

.check_cell:
    movsx edx, word [esp + 0x24]
    mov eax, edx
    shl eax, 2
    sub eax, edx
    mov edx, eax
    shl edx, 2
    mov eax, ebx
    mov ax, word [edx + eax*2 + inventory_grid]
    movsx edx, word [inventory_scroll]
    mov dword [esp + 0x1c], eax
    movsx eax, word [esp + 0x34]
    add eax, edx
    movsx edx, word [cursor_y]
    sub edx, eax
    mov eax, edx
    call absolute_int
    cmp eax, 0x11
    jge near .ordinary_cell
    movsx edx, word [esp + 0x20]
    movsx eax, word [cursor_x]
    sub eax, edx
    call absolute_int
    cmp eax, 0x10
    jge near .ordinary_cell
    mov eax, dword [esp + 0x24]
    mov si, word [held_item]
    mov dword [esp + 0x18], eax
    mov eax, dword [esp + 0x28]
    xor edi, edi
    mov dword [esp + 0x30], eax
    test si, si
    je near .choose_highlight_tile
    cmp word [esp + 0x1c], 0
    je near .choose_highlight_tile
    mov dword [esp + 0x10], edi
    jmp near .check_highlight_group

; Search the item groups for a valid replacement while an item is held.
.start_highlight_group:
    mov dword [esp + 0x2c], 1
    jmp short .check_held_group_item

.find_held_group_item:
    movsx ebx, word [esp + 0x10]
    shl ebx, 4
    mov dx, word [held_item]
    cmp dx, word [ebx + eax*2 + item_groups]
    jne short .advance_held_group_item
    mov edx, 1
    jmp short .check_highlight_candidate

.check_highlight_group_item:
    movsx esi, word [esp + 0x10]
    mov ebx, eax
    shl esi, 4
    mov ecx, dword [esp + 0x1c]
    cmp cx, word [esi + ebx*2 + item_groups]
    jne short .advance_highlight_candidate
    movsx ebx, word [esp + 0x2c]
    mov ecx, ebx
    or ecx, eax
    xor eax, ebx
    cmp ecx, eax
    jne short .advance_highlight_candidate
    mov di, word [esi + eax*2 + item_groups]
    test di, di
    jne short .choose_highlight_tile

.advance_highlight_candidate:
    inc edx

.check_highlight_candidate:
    movsx eax, dx
    cmp eax, 7
    jle short .check_highlight_group_item

.advance_held_group_item:
    inc dword [esp + 0x2c]

.check_held_group_item:
    movsx eax, word [esp + 0x2c]
    cmp eax, 7
    jle short .find_held_group_item
    inc dword [esp + 0x10]

.check_highlight_group:
    movsx eax, word [esp + 0x10]
    cmp eax, 5
    jle near .start_highlight_group

.choose_highlight_tile:
    test di, di
    je short .highlight_cell
    mov edx, 0x186
    jmp short .draw_cell

.highlight_cell:
    mov edx, 0x17c
    jmp short .draw_cell

.ordinary_cell:
    mov edx, 0x190

.draw_cell:
    mov ebx, dword [esp]
    mov ecx, dword [esp + 4]
    push ebx
    mov esi, dword [esp + 0xc]
    mov ebp, dword [esp + 0x10]
    push ecx
    movsx eax, dx
    push esi
    movsx edx, word [inventory_scroll]
    push ebp
    mov ebx, 0x10000
    xor ecx, ecx
    push 2
    movsx esi, word [esp + 0x34]
    push 0
    movsx ebp, word [esp + 0x4c]
    push 0
    shl esi, 0x10
    add edx, ebp
    push eax
    shl edx, 0x10
    mov eax, esi
    call draw_tile
    cmp word [esp + 0x1c], 0
    je short .advance_grid_column
    mov eax, dword [esp]
    push eax
    mov edx, dword [esp + 8]
    push edx
    mov ebx, dword [esp + 0x10]
    push ebx
    mov ecx, dword [esp + 0x18]
    push ecx
    movsx eax, word [esp + 0x2c]
    push 2
    movsx edx, word [inventory_scroll]
    push 0
    mov ebx, 0x7fff
    add edx, ebp
    push 0
    shl edx, 0x10
    push eax
    xor ecx, ecx
    mov eax, esi
    call draw_tile

.advance_grid_column:
    mov ebx, dword [esp + 0x20]
    mov ecx, dword [esp + 0x28]
    add ebx, 0x1f
    inc ecx
    mov dword [esp + 0x20], ebx
    mov dword [esp + 0x28], ecx

.check_grid_column:
    movsx ebx, word [esp + 0x28]
    cmp ebx, 5
    jle near .check_cell
    mov ebx, dword [esp + 0x34]
    mov ecx, dword [esp + 0x24]
    add ebx, 0x20
    inc ecx
    mov dword [esp + 0x34], ebx
    mov word [esp + 0x24], cx

.check_grid_row:
    movsx eax, word [esp + 0x24]
    cmp eax, 5
    jle near .start_grid_row
    mov ax, word [mouse_buttons]
    xor ah, ah
    and al, 1
    cwde
    test eax, eax
    je near .release_button
    cmp word [button_latch], 0
    jne short .check_held_item
    mov eax, 0xb
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    mov word [button_latch], 1

; On the press path, pick up the hovered item or draw the held item.
.check_held_item:
    mov si, word [held_item]
    test si, si
    jne near .draw_held_item
    mov eax, dword [esp + 0x18]
    mov word [original_row], ax
    mov eax, dword [esp + 0x30]
    movsx edx, word [esp + 0x18]
    mov word [original_column], ax
    mov eax, edx
    shl eax, 2
    movsx ecx, word [esp + 0x30]
    sub eax, edx
    add ecx, ecx
    shl eax, 2
    add ecx, eax
    mov ax, word [ecx + inventory_grid]
    mov word [original_item], ax
    xor eax, eax
    mov al, byte [active_player]
    cmp byte [eax + player_item_mode], 0
    jne short .find_pickup_group
    mov ax, word [ecx + inventory_grid]
    mov word [held_item], ax
    mov word [ecx + inventory_grid], si
    jmp near .draw_cursor

.find_pickup_group:
    mov cx, word [ecx + inventory_grid]
    test cx, cx
    je near .draw_cursor
    mov dword [esp + 0x10], esi
    jmp near .check_pickup_group

.start_pickup_group:
    mov dword [esp + 0x2c], 1
    jmp near .check_pickup_item_index

.check_pickup_item:
    movsx edx, word [esp + 0x10]
    mov ebx, eax
    shl edx, 4
    cmp cx, word [edx + ebx*2 + item_groups]
    jne near .advance_pickup_item
    mov esi, dword [esp + 0x2c]
    cmp eax, 1
    je near .draw_cursor
    cmp eax, 2
    je near .draw_cursor
    cmp eax, 4
    je near .draw_cursor

.find_replacement_item:
    mov eax, dword [esp + 0x2c]
    movsx ecx, word [esp + 0x10]
    dec eax
    shl ecx, 4
    movsx edx, ax
    mov dword [esp + 0x2c], eax
    mov eax, edx
    mov bx, word [ecx + eax*2 + item_groups]
    test bx, bx
    je short .find_replacement_item
    movsx eax, si
    or edx, eax
    cmp edx, eax
    jne short .find_replacement_item
    movsx edx, word [esp + 0x18]
    mov eax, edx
    shl eax, 2
    sub eax, edx
    mov edx, eax
    movsx eax, word [esp + 0x30]
    shl edx, 2
    mov word [edx + eax*2 + inventory_grid], bx
    mov edx, dword [esp + 0x2c]
    xor edx, esi
    movsx eax, dx
    mov ax, word [ecx + eax*2 + item_groups]
    mov dword [esp + 0x2c], edx
    mov word [held_item], ax
    jmp near .draw_cursor

.advance_pickup_item:
    inc dword [esp + 0x2c]

.check_pickup_item_index:
    movsx eax, word [esp + 0x2c]
    cmp eax, 7
    jle near .check_pickup_item
    inc dword [esp + 0x10]

.check_pickup_group:
    movsx eax, word [esp + 0x10]
    cmp eax, 5
    jle near .start_pickup_group
    jmp near .draw_cursor

.draw_held_item:
    mov edi, dword [esp]
    push edi
    mov ebp, dword [esp + 8]
    push ebp
    mov eax, dword [esp + 0x10]
    push eax
    mov edx, dword [esp + 0x18]
    push edx
    push 2
    mov ebx, 0x7fff
    xor ecx, ecx
    push 0
    movsx eax, si
    push 0
    movsx edx, word [cursor_y]
    push eax
    movsx eax, word [cursor_x]
    shl edx, 0x10
    shl eax, 0x10
    call draw_tile
    jmp near .draw_cursor

; On release, place the held item or restore its original cell.
.release_button:
    cmp word [held_item], 0
    je near .clear_button_latch
    movsx edx, word [esp + 0x18]
    mov eax, edx
    shl eax, 2
    movsx esi, word [esp + 0x30]
    sub eax, edx
    add esi, esi
    shl eax, 2
    add esi, eax
    cmp word [esi + inventory_grid], 0
    jne short .check_drop_replacement
    mov ax, word [held_item]
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov word [esi + inventory_grid], ax
    mov eax, 0xd
    call play_sound
    jmp near .clear_held_item

.check_drop_replacement:
    test di, di
    je short .restore_original_item
    movsx eax, di
    cmp eax, strict dword 0x29f
    jne short .drop_replacement
    mov eax, 3
    xor ecx, ecx
    mov di, word [selection_3_stock]
    mov word [esi + inventory_grid], cx
    mov esi, 3
    add edi, 0x32
    mov dword [selected_item], esi
    mov esi, 1
    mov word [selection_3_stock], di
    mov word [selection_3_enabled], si
    call select_item
    jmp short .clear_held_item

.drop_replacement:
    mov eax, 0xc
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    mov word [esi + inventory_grid], di
    jmp short .clear_held_item

.restore_original_item:
    mov eax, 0xe
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    call play_sound
    movsx edx, word [original_row]
    mov eax, edx
    shl eax, 2
    sub eax, edx
    mov edx, eax
    movsx eax, word [original_column]
    shl edx, 2
    add eax, eax
    add eax, edx
    mov dx, word [original_item]
    mov word [eax + inventory_grid], dx

.clear_held_item:
    xor eax, eax
    mov word [held_item], ax

.clear_button_latch:
    xor edx, edx
    mov word [button_latch], dx

.draw_cursor:
    mov esi, dword [esp]
    push esi
    mov edi, dword [esp + 8]
    push edi
    mov ebp, dword [esp + 0x10]
    push ebp
    mov eax, dword [esp + 0x18]
    push eax
    mov ebx, 0x7fff
    push 2
    movsx edx, word [cursor_y]
    xor ecx, ecx
    push 0
    shl edx, 0x10
    push 0
    movsx eax, word [cursor_x]
    push strict dword 0x174
    shl eax, 0x10
    call draw_tile
    add esp, 0x38
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
