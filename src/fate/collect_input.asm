; Collect one five-byte local input record for the game timer.
BITS 32
ORG 0x2d51a

toggled_word equ 0x203e
toggled_mode equ 0x2265
selection_1_enabled equ 0x2269
selection_2_enabled equ 0x226b
selection_3_enabled equ 0x226d
selection_4_enabled equ 0x226f
selection_5_enabled equ 0x2271
selection_6_enabled equ 0x2273
selection_7_enabled equ 0x2275
selection_2_stock equ 0x227b
selection_3_stock equ 0x227d
selection_4_stock equ 0x227f
selection_5_stock equ 0x2281
selection_6_stock equ 0x2283
selection_7_stock equ 0x2285
selection_2_alternate_stock equ 0x228b
map_x equ 0x2bf0
map_scale_or_y equ 0x2bf2
map_offset_y equ 0x2bf4
button_latch_disabled equ 0x2bf6
map_mode equ 0x2bfa
mouse_motion_disabled equ 0x2bfc
cursor_mode equ 0x3be5
saved_mouse_buttons equ 0x3cfc
brightness equ 0x3cfe
input_mode equ 0x3d03
adjust_view_held equ 0x12c34
mouse_history_index equ 0x12c35
primary_button_latch equ 0x12c37
secondary_button_latch equ 0x12c39
button_alternate equ 0x12c3b
key_forward equ 0x1363d
key_backward equ 0x1363e
key_left equ 0x1363f
key_right equ 0x13640
key_run equ 0x13641
key_strafe equ 0x13642
key_action_11 equ 0x13643
key_action_10 equ 0x13644
key_action_0 equ 0x13645
key_action_1 equ 0x13646
key_action_2 equ 0x13647
key_action_3 equ 0x13648
key_reset_view equ 0x13649
key_strafe_left equ 0x1364a
key_strafe_right equ 0x1364b
key_action_12 equ 0x1364c
key_action_4 equ 0x1364d
key_action_5 equ 0x1364e
key_latched_secondary equ 0x1364f
key_toggle_mode equ 0x13650
key_toggle_word equ 0x13653
key_adjust_view equ 0x13655
strafe_limit equ 0x13b9f
strafe_step equ 0x13ba3
prior_action_word equ 0x5ac8f
view_adjustment equ 0x62f8c
key_state equ 0x6793c
selection_key_0 equ 0x6793e
selection_key_1 equ 0x6793f
selection_key_2 equ 0x67940
selection_key_3 equ 0x67941
selection_key_4 equ 0x67942
selection_key_5 equ 0x67943
selection_key_6 equ 0x67944
selection_key_7 equ 0x67945
brightness_key equ 0x67993
selection equ 0x770c8
keyboard_strafe equ 0x770e4
keyboard_forward equ 0x770e8
keyboard_turn equ 0x770ec
mouse_dx equ 0x7deda
mouse_dy equ 0x7dedc
mouse_buttons equ 0x7dee2
smoothed_mouse_dx equ 0x7def2
input_forward equ 0x7def9
input_strafe equ 0x7defa
input_turn equ 0x7defb
input_actions equ 0x7defc
key_fifo_write equ 0x7f878
key_fifo_read equ 0x7f87b
cursor_y equ 0x8528c
cursor_x equ 0x8528e
active_mouse_buttons equ 0x85290
mouse_history equ 0x85292
brightness_palette equ 0x27c0a0
getmousevalues equ 0x54424
scale_mouse equ 0x3a96d
setbrightness equ 0x59bee

section .text align=1
collect_input_ equ 0x2d51a
; Guarded C supplies selection, motion and selected action operations.
.loc_032 equ 0x2d54c
.loc_04b equ 0x2d565
.loc_06c equ 0x2d586
.loc_09d equ 0x2d5b7
.loc_0a7 equ 0x2d5c1
.loc_0d8 equ 0x2d5f2
.loc_109 equ 0x2d623
.loc_139 equ 0x2d653
.loc_16a equ 0x2d684
.keyboard_motion equ 0x2d6b5
.loc_1cd equ 0x2d6e7
.loc_1d2 equ 0x2d6ec
.loc_1f8 equ 0x2d712
.strafe_modifier_motion equ 0x2d71c
.loc_233 equ 0x2d74d
.loc_238 equ 0x2d752
.loc_26d equ 0x2d787
.toggle_keys equ 0x2d78c
.loc_295 equ 0x2d7af
.poll_mouse equ 0x2d7d5
.loc_306 equ 0x2d820
.loc_318 equ 0x2d832
.loc_31d equ 0x2d837
.loc_33f equ 0x2d859
.loc_344 equ 0x2d85e
.loc_375 equ 0x2d88f
.loc_37a equ 0x2d894
.loc_3af equ 0x2d8c9
.decay_motion equ 0x2d8ce
.loc_3c6 equ 0x2d8e0
.loc_3cb equ 0x2d8e5
.loc_3de equ 0x2d8f8
.loc_3e3 equ 0x2d8fd
.loc_3f6 equ 0x2d910
.loc_3fb equ 0x2d915
.loc_40e equ 0x2d928
.loc_413 equ 0x2d92d
.loc_426 equ 0x2d940
.loc_42b equ 0x2d945
.loc_43e equ 0x2d958
.loc_443 equ 0x2d95d
.loc_452 equ 0x2d96c
.loc_457 equ 0x2d971
.loc_46d equ 0x2d987
.loc_472 equ 0x2d98c
.loc_486 equ 0x2d9a0
.loc_48b equ 0x2d9a5
.loc_49f equ 0x2d9b9
.loc_4a6 equ 0x2d9c0
.loc_4ab equ 0x2d9c5
.loc_4bf equ 0x2d9d9
.loc_4c4 equ 0x2d9de
.loc_4d8 equ 0x2d9f2
.loc_4df equ 0x2d9f9
.loc_4e4 equ 0x2d9fe
.cursor_or_map_motion equ 0x2da1b
.loc_55a equ 0x2da74
.loc_578 equ 0x2da92
.loc_57d equ 0x2da97
.loc_598 equ 0x2dab2
.loc_5b6 equ 0x2dad0
.loc_5bb equ 0x2dad5
.map_motion equ 0x2db22
.loc_65b equ 0x2db75
.loc_679 equ 0x2db93
.loc_67e equ 0x2db98
.loc_6a1 equ 0x2dbbb
.loc_6b7 equ 0x2dbd1
.map_vertical_offset equ 0x2dbdd
.loc_6ea equ 0x2dc04
.loc_708 equ 0x2dc22
.loc_70d equ 0x2dc27
.gameplay_mouse_motion equ 0x2dc30
.loc_736 equ 0x2dc50
.loc_73c equ 0x2dc56
.view_adjustment_key equ 0x2dc5d
.loc_765 equ 0x2dc7f
.blend_mouse_motion equ 0x2dc9f
.loc_7ba equ 0x2dcd4
.loc_82e equ 0x2dd48
.loc_858 equ 0x2dd72
.loc_871 equ 0x2dd8b
.loc_891 equ 0x2ddab
.loc_896 equ 0x2ddb0
.mouse_strafe_motion equ 0x2ddb7
.loc_8bf equ 0x2ddd9
.loc_8df equ 0x2ddf9
.loc_8e4 equ 0x2ddfe
.pack_actions equ 0x2de0c
.loc_937 equ 0x2de51
.loc_abd equ 0x2dfd7
.loc_b06 equ 0x2e020
.release_button_latches equ 0x2e044
.loc_b4e equ 0x2e068
.save_mouse_buttons equ 0x2e08b
.cycle_brightness equ 0x2e0b7
.loc_bcd equ 0x2e0e7
.check_fifo_mode equ 0x2e0f8
.drain_key_fifo equ 0x2e101
.done equ 0x2e12c

section .retained_0 align=1 vstart=0x2d51a follows=.text
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp

section .retained_1 align=1 vstart=0x2d52d follows=.retained_0
    xor eax, eax
    mov al, byte [key_toggle_mode]

section .retained_2 align=1 vstart=0x2d801 follows=.retained_1
    xor eax, eax
    mov al, byte [key_forward]
    cmp byte [eax + key_state], 0
    ja short .loc_306
    mov ax, word [active_mouse_buttons]
    xor ah, ah
    and al, 2
    cwde
    test eax, eax
    je short .loc_31d
    mov eax, dword [keyboard_forward]
    add eax, 0xc
    cmp eax, 0x7f
    jl short .loc_318
    mov eax, 0x7f
    mov dword [keyboard_forward], eax

section .retained_3 align=1 vstart=0x2d85e follows=.retained_2
    xor eax, eax
    mov al, byte [key_strafe_left]
    cmp byte [eax + key_state], 0
    jbe short .loc_37a
    mov ebx, dword [strafe_step]
    mov eax, ebx
    shl eax, 2
    mov edi, dword [keyboard_strafe]
    sub eax, ebx
    mov ebp, dword [strafe_limit]
    add eax, edi
    cmp eax, ebp
    jl short .loc_375
    mov eax, ebp
    mov dword [keyboard_strafe], eax
    xor eax, eax
    mov al, byte [key_strafe_right]
    cmp byte [eax + key_state], 0
    jbe short .decay_motion
    mov ebx, dword [strafe_step]
    mov eax, ebx
    shl eax, 2
    sub eax, ebx
    mov ebx, dword [keyboard_strafe]
    sub ebx, eax
    mov eax, ebx
    mov ebx, dword [strafe_limit]
    neg ebx
    cmp eax, ebx
    jg short .loc_3af
    mov eax, ebx
    mov dword [keyboard_strafe], eax
    mov eax, dword [keyboard_turn]
    test eax, eax
    jge short .loc_3cb
    add eax, 0x24
    test eax, eax
    jl short .loc_3c6
    xor eax, eax
    mov dword [keyboard_turn], eax
    mov edx, dword [keyboard_turn]
    test edx, edx
    jle short .loc_3e3
    lea eax, [edx - 0x24]
    test eax, eax
    jg short .loc_3de
    xor eax, eax
    mov dword [keyboard_turn], eax

section .retained_4 align=1 vstart=0x2d92d follows=.retained_3
    mov esi, dword [keyboard_forward]
    test esi, esi
    jge short .loc_42b
    lea eax, [esi + 6]
    test eax, eax
    jl short .loc_426
    xor eax, eax
    mov dword [keyboard_forward], eax
    mov edi, dword [keyboard_forward]
    test edi, edi
    jle short .loc_443
    lea eax, [edi - 6]
    test eax, eax
    jg short .loc_43e
    xor eax, eax
    mov dword [keyboard_forward], eax
    mov ebp, dword [keyboard_forward]
    cmp ebp, -0x78
    jle short .loc_452
    mov eax, ebp
    jmp short .loc_457
    mov eax, 0xffffff88
    cmp eax, 0x77
    jge short .loc_46d
    mov eax, dword [keyboard_forward]
    cmp eax, -0x78
    jg short .loc_472
    mov eax, 0xffffff88
    jmp short .loc_472
    mov eax, 0x77
    mov edx, dword [keyboard_strafe]
    mov byte [input_forward], al
    cmp edx, -0x78
    jle short .loc_486
    mov eax, edx
    jmp short .loc_48b
    mov eax, 0xffffff88
    cmp eax, 0x77
    jge short .loc_4a6
    mov ebx, dword [keyboard_strafe]
    cmp ebx, -0x78
    jle short .loc_49f
    mov eax, ebx
    jmp short .loc_4ab
    mov eax, 0xffffff88
    jmp short .loc_4ab
    mov eax, 0x77
    mov ecx, dword [keyboard_turn]
    mov byte [input_strafe], al
    cmp ecx, -0x70
    jle short .loc_4bf
    mov eax, ecx
    jmp short .loc_4c4
    mov eax, 0xffffff90
    cmp eax, 0x6f
    jge short .loc_4df
    mov esi, dword [keyboard_turn]
    cmp esi, -0x70
    jle short .loc_4d8
    mov eax, esi
    jmp short .loc_4e4
    mov eax, 0xffffff90
    jmp short .loc_4e4
    mov eax, 0x6f
    mov bl, byte [cursor_mode]
    mov byte [input_turn], al
    test bl, bl
    jne short .cursor_or_map_motion
    cmp word [map_mode], 0
    je near .gameplay_mouse_motion

section .retained_5 align=1 vstart=0x2da67 follows=.retained_4
    cmp ebx, 0x13c
    jg short .loc_55a
    mov ebx, 0x13c
    cmp ebx, 0x3dc
    jge short .loc_578
    movsx ebx, word [cursor_x]
    cmp ebx, 0x13c
    jg short .loc_57d
    mov ebx, 0x13c
    jmp short .loc_57d
    mov ebx, 0x3dc
    mov word [cursor_x], bx
    movsx ebx, word [cursor_y]
    cmp ebx, 0x16c
    jg short .loc_598
    mov ebx, 0x16c
    cmp ebx, 0x1b8
    jge short .loc_5b6
    movsx ebx, word [cursor_y]
    cmp ebx, 0x16c
    jg short .loc_5bb
    mov ebx, 0x16c
    jmp short .loc_5bb
    mov ebx, 0x1b8
    mov word [cursor_y], bx

section .retained_6 align=1 vstart=0x2dafe follows=.retained_5
    mov bx, word [mouse_buttons]
    xor bh, bh
    and bl, 2
    movsx ebx, bx
    test ebx, ebx
    je near .view_adjustment_key
    xor bh, bh
    mov byte [cursor_mode], bh
    jmp near .view_adjustment_key
    mov bx, word [mouse_buttons]
    xor bh, bh
    and bl, 2
    movsx ebx, bx
    test ebx, ebx
    jne near .map_vertical_offset

section .retained_7 align=1 vstart=0x2db68 follows=.retained_6
    cmp ebx, 0x100
    jg short .loc_65b
    mov ebx, 0x100
    cmp ebx, 0x800
    jge short .loc_679
    movsx ebx, word [map_scale_or_y]
    cmp ebx, 0x100
    jg short .loc_67e
    mov ebx, 0x100
    jmp short .loc_67e
    mov ebx, 0x800
    mov word [map_scale_or_y], bx
    movsx ebx, bx
    mov ecx, ebx
    sar ecx, 3
    sub ebx, ecx
    movsx esi, bx
    movsx ecx, word [map_x]
    neg esi
    cmp ecx, esi
    jg short .loc_6a1
    mov ecx, esi
    movsx ebx, bx
    cmp ecx, ebx
    jge short .loc_6b7
    movsx ecx, word [map_x]
    neg ebx
    cmp ecx, ebx
    jle short .loc_6b7
    mov ebx, ecx
    mov word [map_x], bx
    jmp near .view_adjustment_key

section .retained_8 align=1 vstart=0x2dbf7 follows=.retained_7
    cmp ebx, 0xffffff00
    jg short .loc_6ea
    mov ebx, 0xffffff00
    cmp ebx, 0x100
    jge short .loc_708
    movsx ebx, word [map_offset_y]
    cmp ebx, 0xffffff00
    jg short .loc_70d
    mov ebx, 0xffffff00
    jmp short .loc_70d
    mov ebx, 0x100
    mov word [map_offset_y], bx
    jmp short .view_adjustment_key
    cmp word [mouse_motion_disabled], 0
    jne short .loc_736
    mov dx, word [mouse_dx]
    mov bx, word [mouse_buttons]
    mov ax, word [mouse_dy]
    jmp short .loc_73c
    xor edx, edx
    xor bh, bh
    xor eax, eax
    mov word [active_mouse_buttons], bx

section .retained_9 align=1 vstart=0x2dc9f follows=.retained_8
    xor ebx, ebx
    mov bl, byte [key_strafe]
    cmp byte [ebx + key_state], 0
    jne near .mouse_strafe_motion

section .retained_10 align=1 vstart=0x2dd15 follows=.retained_9
    test ch, ch
    je short .loc_858
    test ax, ax
    jle short .loc_82e

section .retained_11 align=1 vstart=0x2dd48 follows=.retained_10
    jge near .pack_actions
    mov ebp, dword [view_adjustment]
    sub ebp, 4
    mov dword [view_adjustment], ebp
    test ebp, ebp
    jge near .pack_actions
    xor edx, edx
    mov dword [view_adjustment], edx
    jmp near .pack_actions
    movsx ecx, ax
    movsx ebx, byte [input_forward]
    shl ecx, 3
    sub ebx, ecx
    cmp ebx, -0x80
    jg short .loc_871
    mov ebx, 0xffffff80
    cmp ebx, 0x7f
    jge short .loc_891
    cwde
    mov ebx, eax
    movsx eax, byte [input_forward]
    shl ebx, 3
    sub eax, ebx
    cmp eax, -0x80
    jg short .loc_896
    mov eax, 0xffffff80
    jmp short .loc_896
    mov eax, 0x7f
    mov byte [input_forward], al
    jmp short .pack_actions
    movsx ebx, dx
    movsx eax, byte [input_turn]
    shl ebx, 3
    xor esi, esi
    sub eax, ebx
    mov word [smoothed_mouse_dx], si
    cmp eax, -0x80
    jg short .loc_8bf
    mov eax, 0xffffff80
    cmp eax, 0x7f
    jge short .loc_8df
    movsx eax, dx
    movsx ebx, byte [input_turn]
    shl eax, 3
    sub ebx, eax
    cmp ebx, -0x80
    jg short .loc_8e4
    mov ebx, 0xffffff80
    jmp short .loc_8e4
    mov ebx, 0x7f
    movsx eax, byte [input_strafe]
    add eax, ebx
    mov byte [input_strafe], al

section .retained_12 align=1 vstart=0x2de3c follows=.retained_11
    xor ah, ah

section .retained_13 align=1 vstart=0x2decd follows=.retained_12
    mov al, byte [eax + key_state]
    xor ah, ah
    mov ecx, ebx
    shl eax, 8
    or ecx, eax
    xor eax, eax
    mov al, byte [key_action_2]
    mov word [input_actions], cx
    mov al, byte [eax + key_state]
    xor ah, ah
    mov esi, ecx
    shl eax, 2
    or esi, eax
    xor eax, eax
    mov al, byte [key_action_3]
    mov word [input_actions], si
    mov al, byte [eax + key_state]
    xor ah, ah
    mov edi, esi
    shl eax, 3
    or edi, eax

section .retained_14 align=1 vstart=0x2df66 follows=.retained_13
    mov ax, word [active_mouse_buttons]
    xor ah, ah
    and al, 1
    mov word [input_actions], bx
    movsx ebx, ax
    mov ax, word [saved_mouse_buttons]
    xor ah, ah
    and al, 1
    cwde
    cmp ebx, eax
    setg al
    xor ah, ah
    mov cx, word [input_actions]
    shl eax, 0xb
    or ecx, eax
    mov ax, word [active_mouse_buttons]
    xor ah, ah
    and al, 1
    cwde
    mov word [input_actions], cx
    test eax, eax
    je near .release_button_latches
    mov si, word [button_latch_disabled]
    test si, si
    jne near .release_button_latches

section .retained_15 align=1 vstart=0x2dffd follows=.retained_14
    xor eax, eax
    mov al, byte [key_action_11]
    mov byte [eax + key_state], 1
    mov edx, 1
    mov word [primary_button_latch], dx
    mov word [button_alternate], dx
    jmp short .save_mouse_buttons
    xor eax, eax
    mov al, byte [key_latched_secondary]
    mov byte [eax + key_state], 1
    mov edi, 1
    xor eax, eax
    mov word [secondary_button_latch], di
    mov word [button_alternate], ax
    jmp short .save_mouse_buttons

section .retained_16 align=1 vstart=0x2e07c follows=.retained_15
    xor eax, eax

section .retained_17 align=1 vstart=0x2e0f8 follows=.retained_16
    cmp byte [input_mode], 0
    je short .done
    mov al, byte [key_fifo_read]
    cmp al, byte [key_fifo_write]
    je short .done
    xor eax, eax
    mov al, byte [key_fifo_read]
    xor eax, eax
    mov al, byte [key_fifo_read]
    mov al, byte [key_fifo_read]
    add al, 2
    and al, 0x3f
    mov byte [key_fifo_read], al
    jmp short .drain_key_fifo
    pop ebp
