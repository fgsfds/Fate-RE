; Dispatch main menu.
BITS 32
ORG 0x3a127

frame_state_d72 equ 0xd72
frame_state_d7c equ 0xd7c
toggled_mode equ 0x2265
last_tick equ 0x3cea
frame_state_12dd4 equ 0x12dd4
frame_state_12df8 equ 0x12df8
frame_state_13150 equ 0x13150
draw_menu_text equ 0x386d3
reset_menu_animation_clock equ 0x390bc
menu_selection_return equ 0x3947f
cache_menu_tiles equ 0x39488
run_menu_loop equ 0x3963b
run_options_menu equ 0x397f4
run_save_game_menu equ 0x39d95
run_load_game_menu equ 0x39f1f
confirm_menu_action equ 0x3a0ce
sub_3a6e5 equ 0x3a6e5
sub_3a8bc equ 0x3a8bc
sub_3ae7c equ 0x3ae7c
sub_3b14b equ 0x3b14b
nextpage equ 0x4b496
rotatesprite equ 0x57181
clearview equ 0x5cd99
frame_state_77114 equ 0x77114
special_case_counter equ 0x77118
frame_state_772b8 equ 0x772b8
difficulty_divisor equ 0x7deec
frame_state_173ff0 equ 0x173ff0
frame_state_174028 equ 0x174028
frame_state_1740ec equ 0x1740ec
totalclock equ 0x287e88
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

    nop

main_menu_dispatch:
    dd dispatch_main_menu.new_game - 0x10000
    dd dispatch_main_menu.options - 0x10000
    dd dispatch_main_menu.load_game - 0x10000
    dd dispatch_main_menu.save_game - 0x10000
    dd dispatch_main_menu.help - 0x10000
    dd dispatch_main_menu.resume - 0x10000
    dd dispatch_main_menu.resume - 0x10000
    dd dispatch_main_menu.confirm_exit - 0x10000

dispatch_main_menu:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov esi, 0x1
    mov edi, [totalclock]
    mov ebp, [last_tick]
    xor edx, edx
    call reset_menu_animation_clock
    mov [frame_state_13150], edx
    call cache_menu_tiles
    cmp dword [frame_state_772b8], 0x0
    jz short .branch_3a182
    mov [frame_state_1740ec], esi
    jmp short .branch_3a188

.branch_3a182:
    mov [frame_state_1740ec], edx

.branch_3a188:
    cmp dword [special_case_counter], 0x0
    jz near .branch_3a334
    cmp dword [frame_state_772b8], 0x0
    jnz short .branch_3a1a5
    push strict dword frame_state_173ff0
    jmp short .branch_3a1aa

.branch_3a1a5:
    push strict dword frame_state_174028

.branch_3a1aa:
    mov ecx, frame_state_d72
    mov ebx, 0x820
    mov edx, 0x8
    mov eax, frame_state_1740ec
    call run_menu_loop
    test eax, eax
    jz near .branch_3a325
    mov eax, [frame_state_1740ec]
    cmp eax, 0x7
    ja short .branch_3a188
    jmp dword near [cs:eax*4 + main_menu_dispatch - 0x10000]
.new_game:
    mov ebx, 0x1
    mov eax, [frame_state_772b8]
    mov [toggled_mode], bx
    test eax, eax
    jz short .branch_3a1fb
    call confirm_menu_action
    test eax, eax
    jz short .branch_3a188

.branch_3a1fb:
    call sub_3a6e5
    test eax, eax
    jng short .branch_3a20e

.branch_3a204:
    mov esi, 0x1
    jmp near .branch_3a334

.branch_3a20e:
    call sub_3ae7c
    test eax, eax
    jz near .branch_3a188
    xor eax, eax
    mov esi, 0x1
    call clearview
    mov eax, [presentation_height]
    sub eax, esi
    push eax
    mov eax, [presentation_width]
    sub eax, esi
    push eax
    push strict byte 0x0
    push strict byte 0x0
    push strict byte 0x2
    push strict byte 0x0
    push strict byte 0x0
    mov ebx, 0x10000
    mov edx, 0x640000
    push strict dword 0x9a1
    xor ecx, ecx
    mov eax, 0xa00000
    call rotatesprite
    mov edx, [frame_state_12df8]
    mov eax, edx
    shl eax, byte 0x3
    mov ecx, frame_state_d7c
    sub eax, edx
    mov edx, 0xa0
    sar eax, 1
    mov ebx, 0xffffffff
    sub edx, eax
    push esi
    mov eax, edx
    mov edx, 0x4e
    call draw_menu_text
    call nextpage

.branch_3a28e:
    call sub_3b14b
    jmp near .branch_3a334
.options:
    call run_options_menu
    jmp near .branch_3a188
.load_game:
    cmp dword [frame_state_772b8], 0x0
    jz short .branch_3a2b8
    call confirm_menu_action
    test eax, eax
    jz near .branch_3a188

.branch_3a2b8:
    call run_load_game_menu
    cmp eax, -1
    jz near .branch_3a188
    mov esi, 0x1
    mov edx, 0x2
    mov [frame_state_77114], esi
    mov [difficulty_divisor], dx
    jmp short .branch_3a28e
.save_game:
    call run_save_game_menu
    jmp near .branch_3a188
.help:
    call sub_3a8bc
    jmp near .branch_3a188
.resume:
    cmp dword [frame_state_772b8], 0x0
    jnz near .branch_3a204
    jmp short .branch_3a332
.confirm_exit:
    call confirm_menu_action
    test eax, eax
    jz near .branch_3a188
    xor esi, esi
    mov [special_case_counter], esi
    mov [frame_state_772b8], esi
    mov [frame_state_12dd4], esi
    jmp short .branch_3a334

.branch_3a325:
    cmp dword [frame_state_772b8], 0x0
    jnz near .branch_3a204

.branch_3a332:
    xor esi, esi

.branch_3a334:
    mov [totalclock], edi
    mov [last_tick], ebp
    jmp near menu_selection_return
