; Render save slot preview.
BITS 32
ORG 0x39a02

weapon_tile equ 0x2be4
listener_index equ 0x3cfa
board_state_209fc equ 0x209fc
board_state_2ca2c equ 0x2ca2c
board_state_2ca6c equ 0x2ca6c
board_state_2caac equ 0x2caac
board_state_2caec equ 0x2caec
board_state_2cb2c equ 0x2cb2c
draw_weapon_overlay equ 0x37f95
restore_saved_registers equ 0x39481
drawrooms equ 0x44796
drawmasks equ 0x4cc8a
board_state_5ac8c equ 0x5ac8c
board_state_5ac8d equ 0x5ac8d
board_state_5ac8e equ 0x5ac8e
player_input_word equ 0x5ac8f
player_sector equ 0x5acfc
player_z equ 0x5ad1c
player_y equ 0x5ad5c
player_x equ 0x5ad9c
board_state_5ae1c equ 0x5ae1c
setviewtotile equ 0x5d2f4
setviewback equ 0x5d46d
board_state_62f2c equ 0x62f2c
player_horizon equ 0x62f8c
player_angle equ 0x6308c
view_state_770bc equ 0x770bc
weapon_x_offset equ 0x7dee8
weapon_y_offset equ 0x7deea
frame_state_173fc0 equ 0x173fc0
weapon_state_203c98 equ 0x203c98
frame_state_2040ad equ 0x2040ad
engine_27c3bc equ 0x27c3bc

render_save_slot_preview:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x8
    mov esi, eax
    cmp dword [weapon_state_203c98], 0x0
    jz near .branch_39c3d
    mov ebx, 0x140
    mov edx, 0xc8
    mov eax, 0xffe
    call setviewtotile
    movsx ecx, word [listener_index]
    movsx eax, word [nosplit ecx*2 + board_state_62f2c]
    imul eax, eax, 0x2c
    mov dl, [eax + frame_state_2040ad]
    or dl, 0x80
    mov edi, [nosplit ecx*4 + board_state_2caac]
    mov [eax + frame_state_2040ad], dl
    mov eax, [nosplit ecx*4 + player_x]
    mov ebx, [view_state_770bc]
    sub eax, edi
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit ecx*4 + board_state_2caac]
    movsx ecx, word [listener_index]
    add edx, eax
    mov eax, [nosplit ecx*4 + player_y]
    mov ebp, [nosplit ecx*4 + board_state_2caec]
    mov ebx, [view_state_770bc]
    sub eax, ebp
    mov [esp + 0x4], edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebp, [nosplit ecx*4 + board_state_2caec]
    movsx ecx, word [listener_index]
    add ebp, eax
    mov eax, [nosplit ecx*4 + player_z]
    mov edx, [nosplit ecx*4 + board_state_2ca6c]
    mov ebx, [view_state_770bc]
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edi, [nosplit ecx*4 + board_state_2ca6c]
    movsx ecx, word [listener_index]
    add edi, eax
    mov eax, [nosplit ecx*4 + player_horizon]
    mov edx, [nosplit ecx*4 + board_state_2ca2c]
    mov ebx, [view_state_770bc]
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [nosplit ecx*4 + board_state_2ca2c]
    add edx, eax
    movsx eax, word [listener_index]
    mov [esp], edx
    mov ecx, [nosplit eax*4 + board_state_5ae1c]
    mov edx, [nosplit eax*4 + board_state_2cb2c]
    mov eax, ecx
    mov ebx, [view_state_770bc]
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    movsx ecx, word [listener_index]
    movsx eax, word [nosplit ecx*2 + player_angle]
    movsx edx, word [nosplit ecx*2 + board_state_209fc]
    add eax, strict dword 0x400
    sub eax, edx
    and eax, strict dword 0x7ff
    mov ebx, [view_state_770bc]
    sub eax, strict dword 0x400
    imul ebx
    shrd eax, edx, byte 0x10
    mov dx, [nosplit ecx*2 + board_state_209fc]
    add edx, eax
    movsx eax, word [listener_index]
    movsx eax, word [nosplit eax*2 + player_sector]
    mov ebx, [esp]
    push eax
    movsx ecx, dx
    mov edx, ebp
    push ebx
    mov eax, [esp + 0xc]
    mov ebx, edi
    call drawrooms
    call drawmasks
    cmp word [weapon_tile], 0x0
    jz short .branch_39c00
    movsx eax, word [weapon_y_offset]
    push eax
    movsx eax, word [weapon_x_offset]
    movsx ebx, word [listener_index]
    push eax
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov dx, [eax + player_input_word]
    xor dl, dl
    and dh, 0x1
    movsx edi, byte [eax + board_state_5ac8c]
    movsx ecx, dx
    movsx edx, byte [eax + board_state_5ac8e]
    movsx eax, byte [eax + board_state_5ac8d]
    or edi, edx
    movsx ebx, word [nosplit ebx*2 + player_sector]
    or edi, eax
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    mov ebx, edi
    movsx edx, byte [nosplit eax*8 + engine_27c3bc]
    movsx eax, word [weapon_tile]
    call draw_weapon_overlay

.branch_39c00:
    movsx eax, word [listener_index]
    movsx eax, word [nosplit eax*2 + board_state_62f2c]
    imul eax, eax, 0x2c
    and byte [eax + frame_state_2040ad], 0x7f
    call setviewback
    movsx eax, si
    mov edx, [nosplit eax*4 + frame_state_173fc0]
    mov dword [edx + 0x7], 0xffe
    mov eax, [nosplit eax*4 + frame_state_173fc0]
    mov dword [eax + 0xb], 0x6000

.branch_39c3d:
    add esp, 0x8
    jmp near restore_saved_registers
