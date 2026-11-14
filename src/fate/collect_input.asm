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

collect_input_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    cmp byte [input_mode], 0
    jne near .keyboard_motion
    xor eax, eax
    mov al, byte [key_toggle_mode]
    cmp byte [eax + key_state], 0
    je short .loc_032
    xor dh, dh
    mov byte [eax + key_state], dh
    xor byte [toggled_mode], 1

.loc_032:
    cmp byte [selection_key_0], 0
    jbe short .loc_04b
    xor cl, cl
    mov byte [selection_key_0], cl
    xor edx, edx
    mov dword [selection], edx

.loc_04b:
    cmp byte [selection_key_1], 0
    jbe short .loc_06c
    xor al, al
    mov byte [selection_key_1], al
    movsx eax, word [selection_1_enabled]
    cmp eax, 1
    jne short .loc_06c
    mov dword [selection], eax

.loc_06c:
    cmp byte [selection_key_2], 0
    jbe short .loc_0a7
    xor dl, dl
    mov byte [selection_key_2], dl
    movsx eax, word [selection_2_enabled]
    cmp eax, 1
    jne short .loc_0a7
    cmp word [selection_2_stock], 0
    jg short .loc_09d
    cmp word [selection_2_alternate_stock], 0
    jle short .loc_0a7

.loc_09d:
    mov dword [selection], 2

.loc_0a7:
    cmp byte [selection_key_3], 0
    jbe short .loc_0d8
    xor bl, bl
    mov byte [selection_key_3], bl
    movsx eax, word [selection_3_enabled]
    cmp eax, 1
    jne short .loc_0d8
    cmp word [selection_3_stock], 0
    jle short .loc_0d8
    mov dword [selection], 3

.loc_0d8:
    cmp byte [selection_key_4], 0
    jbe short .loc_109
    xor cl, cl
    mov byte [selection_key_4], cl
    movsx eax, word [selection_4_enabled]
    cmp eax, 1
    jne short .loc_109
    cmp word [selection_4_stock], 0
    jle short .loc_109
    mov dword [selection], 4

.loc_109:
    cmp byte [selection_key_5], 0
    jbe short .loc_139
    xor al, al
    mov byte [selection_key_5], al
    movsx eax, word [selection_5_enabled]
    cmp eax, 1
    jne short .loc_139
    cmp word [selection_5_stock], 0
    jle short .loc_139
    mov dword [selection], 5

.loc_139:
    cmp byte [selection_key_6], 0
    jbe short .loc_16a
    xor dl, dl
    mov byte [selection_key_6], dl
    movsx eax, word [selection_6_enabled]
    cmp eax, 1
    jne short .loc_16a
    cmp word [selection_6_stock], 0
    jle short .loc_16a
    mov dword [selection], 6

.loc_16a:
    cmp byte [selection_key_7], 0
    jbe short .keyboard_motion
    xor bl, bl
    mov byte [selection_key_7], bl
    movsx eax, word [selection_7_enabled]
    cmp eax, 1
    jne short .keyboard_motion
    cmp word [selection_7_stock], 0
    jle short .keyboard_motion
    mov dword [selection], 7

; Apply keyboard acceleration and the strafe modifier.
.keyboard_motion:
    xor eax, eax
    mov al, byte [key_strafe]
    cmp byte [eax + key_state], 0
    jne short .strafe_modifier_motion
    xor eax, eax
    mov al, byte [key_left]
    cmp byte [eax + key_state], 0
    jbe short .loc_1d2
    mov eax, dword [keyboard_turn]
    sub eax, 0x30
    cmp eax, -0x80
    jg short .loc_1cd
    mov eax, 0xffffff80

.loc_1cd:
    mov dword [keyboard_turn], eax

.loc_1d2:
    xor eax, eax
    mov al, byte [key_right]
    cmp byte [eax + key_state], 0
    jbe near .toggle_keys
    mov eax, dword [keyboard_turn]
    add eax, 0x30
    cmp eax, 0x7f
    jl short .loc_1f8
    mov eax, 0x7f

.loc_1f8:
    mov dword [keyboard_turn], eax
    jmp near .toggle_keys

.strafe_modifier_motion:
    xor eax, eax
    mov al, byte [key_left]
    cmp byte [eax + key_state], 0
    jbe short .loc_238
    mov ebx, dword [strafe_step]
    mov eax, ebx
    shl eax, 2
    sub eax, ebx
    mov ebx, dword [keyboard_strafe]
    mov ecx, dword [strafe_limit]
    add eax, ebx
    cmp eax, ecx
    jl short .loc_233
    mov eax, ecx

.loc_233:
    mov dword [keyboard_strafe], eax

.loc_238:
    xor eax, eax
    mov al, byte [key_right]
    cmp byte [eax + key_state], 0
    jbe short .toggle_keys
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
    jg short .loc_26d
    mov eax, ebx

.loc_26d:
    mov dword [keyboard_strafe], eax

.toggle_keys:
    xor eax, eax
    mov al, byte [key_toggle_word]
    xor ebx, ebx
    mov bl, byte [eax + key_state]
    cmp ebx, 1
    jne short .loc_295
    xor bl, bl
    mov byte [eax + key_state], bl
    not word [toggled_word]

.loc_295:
    xor eax, eax
    mov al, byte [key_reset_view]
    xor ebx, ebx
    mov bl, byte [eax + key_state]
    cmp ebx, 1
    jne short .poll_mouse
    xor bh, bh
    mov byte [eax + key_state], bh
    mov dword [view_adjustment], 0x64

; Read and scale the mouse deltas before blending them with keyboard motion.
.poll_mouse:
    mov ebx, mouse_buttons
    mov edx, mouse_dy
    xor ecx, ecx
    mov eax, mouse_dx
    mov word [mouse_buttons], cx
    call getmousevalues
    mov edx, mouse_dy
    mov eax, mouse_dx
    call scale_mouse
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

.loc_306:
    mov eax, dword [keyboard_forward]
    add eax, 0xc
    cmp eax, 0x7f
    jl short .loc_318
    mov eax, 0x7f

.loc_318:
    mov dword [keyboard_forward], eax

.loc_31d:
    xor eax, eax
    mov al, byte [key_backward]
    cmp byte [eax + key_state], 0
    jbe short .loc_344
    mov eax, dword [keyboard_forward]
    sub eax, 0xc
    cmp eax, -0x80
    jg short .loc_33f
    mov eax, 0xffffff80

.loc_33f:
    mov dword [keyboard_forward], eax

.loc_344:
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

.loc_375:
    mov dword [keyboard_strafe], eax

.loc_37a:
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

.loc_3af:
    mov dword [keyboard_strafe], eax

.decay_motion:
    mov eax, dword [keyboard_turn]
    test eax, eax
    jge short .loc_3cb
    add eax, 0x24
    test eax, eax
    jl short .loc_3c6
    xor eax, eax

.loc_3c6:
    mov dword [keyboard_turn], eax

.loc_3cb:
    mov edx, dword [keyboard_turn]
    test edx, edx
    jle short .loc_3e3
    lea eax, [edx - 0x24]
    test eax, eax
    jg short .loc_3de
    xor eax, eax

.loc_3de:
    mov dword [keyboard_turn], eax

.loc_3e3:
    mov ebx, dword [keyboard_strafe]
    test ebx, ebx
    jge short .loc_3fb
    lea eax, [ebx + 6]
    test eax, eax
    jl short .loc_3f6
    xor eax, eax

.loc_3f6:
    mov dword [keyboard_strafe], eax

.loc_3fb:
    mov ecx, dword [keyboard_strafe]
    test ecx, ecx
    jle short .loc_413
    lea eax, [ecx - 6]
    test eax, eax
    jg short .loc_40e
    xor eax, eax

.loc_40e:
    mov dword [keyboard_strafe], eax

.loc_413:
    mov esi, dword [keyboard_forward]
    test esi, esi
    jge short .loc_42b
    lea eax, [esi + 6]
    test eax, eax
    jl short .loc_426
    xor eax, eax

.loc_426:
    mov dword [keyboard_forward], eax

.loc_42b:
    mov edi, dword [keyboard_forward]
    test edi, edi
    jle short .loc_443
    lea eax, [edi - 6]
    test eax, eax
    jg short .loc_43e
    xor eax, eax

.loc_43e:
    mov dword [keyboard_forward], eax

.loc_443:
    mov ebp, dword [keyboard_forward]
    cmp ebp, -0x78
    jle short .loc_452
    mov eax, ebp
    jmp short .loc_457

.loc_452:
    mov eax, 0xffffff88

.loc_457:
    cmp eax, 0x77
    jge short .loc_46d
    mov eax, dword [keyboard_forward]
    cmp eax, -0x78
    jg short .loc_472
    mov eax, 0xffffff88
    jmp short .loc_472

.loc_46d:
    mov eax, 0x77

.loc_472:
    mov edx, dword [keyboard_strafe]
    mov byte [input_forward], al
    cmp edx, -0x78
    jle short .loc_486
    mov eax, edx
    jmp short .loc_48b

.loc_486:
    mov eax, 0xffffff88

.loc_48b:
    cmp eax, 0x77
    jge short .loc_4a6
    mov ebx, dword [keyboard_strafe]
    cmp ebx, -0x78
    jle short .loc_49f
    mov eax, ebx
    jmp short .loc_4ab

.loc_49f:
    mov eax, 0xffffff88
    jmp short .loc_4ab

.loc_4a6:
    mov eax, 0x77

.loc_4ab:
    mov ecx, dword [keyboard_turn]
    mov byte [input_strafe], al
    cmp ecx, -0x70
    jle short .loc_4bf
    mov eax, ecx
    jmp short .loc_4c4

.loc_4bf:
    mov eax, 0xffffff90

.loc_4c4:
    cmp eax, 0x6f
    jge short .loc_4df
    mov esi, dword [keyboard_turn]
    cmp esi, -0x70
    jle short .loc_4d8
    mov eax, esi
    jmp short .loc_4e4

.loc_4d8:
    mov eax, 0xffffff90
    jmp short .loc_4e4

.loc_4df:
    mov eax, 0x6f

.loc_4e4:
    mov bl, byte [cursor_mode]
    mov byte [input_turn], al
    test bl, bl
    jne short .cursor_or_map_motion
    cmp word [map_mode], 0
    je near .gameplay_mouse_motion

; Divert mouse motion to the cursor or map controls.
.cursor_or_map_motion:
    mov si, word [map_mode]
    xor edx, edx
    xor eax, eax
    mov word [active_mouse_buttons], dx
    test si, si
    jne near .map_motion
    mov bx, word [mouse_dx]
    mov di, word [cursor_x]
    mov cx, word [cursor_y]
    add edi, ebx
    mov bx, word [mouse_dy]
    mov word [cursor_x], di
    add ecx, ebx
    movsx ebx, di
    mov word [cursor_y], cx
    cmp ebx, 0x13c
    jg short .loc_55a
    mov ebx, 0x13c

.loc_55a:
    cmp ebx, 0x3dc
    jge short .loc_578
    movsx ebx, word [cursor_x]
    cmp ebx, 0x13c
    jg short .loc_57d
    mov ebx, 0x13c
    jmp short .loc_57d

.loc_578:
    mov ebx, 0x3dc

.loc_57d:
    mov word [cursor_x], bx
    movsx ebx, word [cursor_y]
    cmp ebx, 0x16c
    jg short .loc_598
    mov ebx, 0x16c

.loc_598:
    cmp ebx, 0x1b8
    jge short .loc_5b6
    movsx ebx, word [cursor_y]
    cmp ebx, 0x16c
    jg short .loc_5bb
    mov ebx, 0x16c
    jmp short .loc_5bb

.loc_5b6:
    mov ebx, 0x1b8

.loc_5bb:
    mov word [cursor_y], bx
    movsx ebx, word [cursor_x]
    sar ebx, 2
    mov word [map_x], bx
    movsx ebx, word [cursor_y]
    sar ebx, 2
    mov word [map_scale_or_y], bx
    mov bx, word [mouse_buttons]
    xor bh, bh
    and bl, 2
    movsx ebx, bx
    test ebx, ebx
    je near .view_adjustment_key
    xor bh, bh
    mov byte [cursor_mode], bh
    jmp near .view_adjustment_key

.map_motion:
    mov bx, word [mouse_buttons]
    xor bh, bh
    and bl, 2
    movsx ebx, bx
    test ebx, ebx
    jne near .map_vertical_offset
    mov bx, word [mouse_dx]
    mov cx, word [map_x]
    mov si, word [map_scale_or_y]
    sub ecx, ebx
    sub si, word [mouse_dy]
    mov word [map_x], cx
    movsx ebx, si
    mov word [map_scale_or_y], si
    cmp ebx, 0x100
    jg short .loc_65b
    mov ebx, 0x100

.loc_65b:
    cmp ebx, 0x800
    jge short .loc_679
    movsx ebx, word [map_scale_or_y]
    cmp ebx, 0x100
    jg short .loc_67e
    mov ebx, 0x100
    jmp short .loc_67e

.loc_679:
    mov ebx, 0x800

.loc_67e:
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

.loc_6a1:
    movsx ebx, bx
    cmp ecx, ebx
    jge short .loc_6b7
    movsx ecx, word [map_x]
    neg ebx
    cmp ecx, ebx
    jle short .loc_6b7
    mov ebx, ecx

.loc_6b7:
    mov word [map_x], bx
    jmp near .view_adjustment_key

.map_vertical_offset:
    mov bx, word [mouse_dy]
    mov di, word [map_offset_y]
    add edi, ebx
    movsx ebx, di
    mov word [map_offset_y], di
    cmp ebx, 0xffffff00
    jg short .loc_6ea
    mov ebx, 0xffffff00

.loc_6ea:
    cmp ebx, 0x100
    jge short .loc_708
    movsx ebx, word [map_offset_y]
    cmp ebx, 0xffffff00
    jg short .loc_70d
    mov ebx, 0xffffff00
    jmp short .loc_70d

.loc_708:
    mov ebx, 0x100

.loc_70d:
    mov word [map_offset_y], bx
    jmp short .view_adjustment_key

.gameplay_mouse_motion:
    cmp word [mouse_motion_disabled], 0
    jne short .loc_736
    mov dx, word [mouse_dx]
    mov bx, word [mouse_buttons]
    mov ax, word [mouse_dy]
    jmp short .loc_73c

.loc_736:
    xor edx, edx
    xor bh, bh
    xor eax, eax

.loc_73c:
    mov word [active_mouse_buttons], bx

.view_adjustment_key:
    xor ebx, ebx
    mov bl, byte [key_adjust_view]
    mov bl, byte [ebx + key_state]
    and ebx, 0xff
    cmp ebx, 1
    jne short .loc_765
    mov byte [adjust_view_held], 1
    jmp short .blend_mouse_motion

.loc_765:
    xor ebx, ebx
    mov bl, byte [adjust_view_held]
    cmp ebx, 1
    jne short .blend_mouse_motion
    xor cl, cl
    mov edi, 0x64
    mov byte [adjust_view_held], cl
    mov dword [view_adjustment], edi

; Maintain a four-sample horizontal history and update the outgoing motion.
.blend_mouse_motion:
    xor ebx, ebx
    mov bl, byte [key_strafe]
    cmp byte [ebx + key_state], 0
    jne near .mouse_strafe_motion
    mov di, word [mouse_history_index]
    inc edi
    movsx ebx, di
    mov word [mouse_history_index], di
    cmp ebx, 3
    jle short .loc_7ba
    xor ebx, ebx
    mov word [mouse_history_index], bx

.loc_7ba:
    movsx ebx, word [mouse_history_index]
    mov word [nosplit ebx*2 + mouse_history], dx
    movsx ebx, word [mouse_history+2]
    movsx ecx, word [mouse_history]
    add ebx, ecx
    movsx ecx, word [mouse_history+4]
    add ecx, ebx
    movsx ebx, word [mouse_history+6]
    add ebx, ecx
    sar ebx, 2
    mov ch, byte [adjust_view_held]
    mov word [smoothed_mouse_dx], bx
    test ch, ch
    je short .loc_858
    test ax, ax
    jle short .loc_82e
    mov ebx, dword [view_adjustment]
    add ebx, 4
    mov dword [view_adjustment], ebx
    cmp ebx, 0xc8
    jle near .pack_actions
    mov dword [view_adjustment], 0xc8
    jmp near .pack_actions

.loc_82e:
    jge near .pack_actions
    mov ebp, dword [view_adjustment]
    sub ebp, 4
    mov dword [view_adjustment], ebp
    test ebp, ebp
    jge near .pack_actions
    xor edx, edx
    mov dword [view_adjustment], edx
    jmp near .pack_actions

.loc_858:
    movsx ecx, ax
    movsx ebx, byte [input_forward]
    shl ecx, 3
    sub ebx, ecx
    cmp ebx, -0x80
    jg short .loc_871
    mov ebx, 0xffffff80

.loc_871:
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

.loc_891:
    mov eax, 0x7f

.loc_896:
    mov byte [input_forward], al
    jmp short .pack_actions

.mouse_strafe_motion:
    movsx ebx, dx
    movsx eax, byte [input_turn]
    shl ebx, 3
    xor esi, esi
    sub eax, ebx
    mov word [smoothed_mouse_dx], si
    cmp eax, -0x80
    jg short .loc_8bf
    mov eax, 0xffffff80

.loc_8bf:
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

.loc_8df:
    mov ebx, 0x7f

.loc_8e4:
    movsx eax, byte [input_strafe]
    add eax, ebx
    mov byte [input_strafe], al

; Pack selection in the top three bits and combine the action flags.
.pack_actions:
    mov ax, word [selection]
    shl eax, 0xd
    mov word [input_actions], ax
    cmp byte [input_mode], 0
    jne short .loc_937
    xor eax, eax
    mov al, byte [key_action_12]
    mov al, byte [eax + key_state]
    and eax, 0xff
    cmp eax, 1
    sete al
    xor ah, ah
    mov cx, word [input_actions]
    shl eax, 0xc
    or ecx, eax
    mov word [input_actions], cx

.loc_937:
    xor eax, eax
    mov al, byte [key_action_0]
    mov al, byte [eax + key_state]
    mov si, word [input_actions]
    xor ah, ah
    or esi, eax
    xor eax, eax
    mov al, byte [key_action_1]
    mov word [input_actions], si
    mov al, byte [eax + key_state]
    xor ah, ah
    mov edi, esi
    add eax, eax
    or edi, eax
    xor eax, eax
    mov al, byte [key_action_4]
    mov word [input_actions], di
    mov al, byte [eax + key_state]
    xor ah, ah
    mov edx, edi
    shl eax, 4
    or edx, eax
    xor eax, eax
    mov al, byte [key_action_5]
    mov word [input_actions], dx
    mov al, byte [eax + key_state]
    xor ah, ah
    mov ebx, edx
    shl eax, 5
    or ebx, eax
    xor eax, eax
    mov al, byte [key_run]
    mov word [input_actions], bx
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
    xor eax, eax
    mov al, byte [key_action_10]
    mov word [input_actions], di
    mov al, byte [eax + key_state]
    and eax, 0xff
    cmp eax, 1
    sete al
    xor ah, ah
    mov edx, edi
    shl eax, 0xa
    or edx, eax
    xor eax, eax
    mov al, byte [key_action_11]
    mov word [input_actions], dx
    mov al, byte [eax + key_state]
    and eax, 0xff
    cmp eax, 1
    sete al
    xor ah, ah
    mov ebx, edx
    shl eax, 0xb
    or ebx, eax
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
    movsx eax, word [prior_action_word]
    sar eax, 0xd
    test al, 7
    je short .loc_abd
    mov word [button_alternate], si

.loc_abd:
    cmp word [primary_button_latch], 0
    jne near .save_mouse_buttons
    cmp word [secondary_button_latch], 0
    jne near .save_mouse_buttons
    cmp word [button_alternate], 0
    jne short .loc_b06
    xor eax, eax
    mov al, byte [key_action_11]
    mov byte [eax + key_state], 1
    mov edx, 1
    mov word [primary_button_latch], dx
    mov word [button_alternate], dx
    jmp short .save_mouse_buttons

.loc_b06:
    xor eax, eax
    mov al, byte [key_latched_secondary]
    mov byte [eax + key_state], 1
    mov edi, 1
    xor eax, eax
    mov word [secondary_button_latch], di
    mov word [button_alternate], ax
    jmp short .save_mouse_buttons

; Release synthesized key presses after the mouse button goes up.
.release_button_latches:
    movsx eax, word [primary_button_latch]
    cmp eax, 1
    jne short .loc_b4e
    xor eax, eax
    xor edi, edi
    mov al, byte [key_action_11]
    xor dl, dl
    mov word [primary_button_latch], di
    mov byte [eax + key_state], dl

.loc_b4e:
    movsx eax, word [secondary_button_latch]
    cmp eax, 1
    jne short .save_mouse_buttons
    xor eax, eax
    mov word [secondary_button_latch], ax
    xor eax, eax
    mov al, byte [key_latched_secondary]
    xor dh, dh
    mov byte [eax + key_state], dh

.save_mouse_buttons:
    mov ax, word [active_mouse_buttons]
    mov word [saved_mouse_buttons], ax
    mov ax, word [input_actions]
    xor al, al
    and ah, 8
    cwde
    test eax, eax
    jle short .cycle_brightness
    cmp dword [selection], 3
    jne short .cycle_brightness
    and byte [saved_mouse_buttons], 0xfe

.cycle_brightness:
    cmp byte [brightness_key], 0
    jbe short .check_fifo_mode
    xor al, al
    mov byte [brightness_key], al
    mov cx, word [brightness]
    inc ecx
    movsx eax, cx
    mov word [brightness], cx
    cmp eax, 8
    jle short .loc_bcd
    xor esi, esi
    mov word [brightness], si

.loc_bcd:
    mov edx, brightness_palette
    movsx eax, word [brightness]
    call setbrightness

.check_fifo_mode:
    cmp byte [input_mode], 0
    je short .done

.drain_key_fifo:
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

.done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
