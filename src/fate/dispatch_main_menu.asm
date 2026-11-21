; Retained main-menu alignment and jump table. Body sections are C.
BITS 32
ORG 0x3a127

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
