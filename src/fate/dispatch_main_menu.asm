; Retained main-menu table and shared-frame entry. Other blocks are C.
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

dispatch_main_menu.new_game equ 0x3a1dd
dispatch_main_menu.options equ 0x3a298
dispatch_main_menu.load_game equ 0x3a2a2
dispatch_main_menu.save_game equ 0x3a2df
dispatch_main_menu.help equ 0x3a2e9
dispatch_main_menu.resume equ 0x3a2f3
dispatch_main_menu.confirm_exit equ 0x3a302

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
