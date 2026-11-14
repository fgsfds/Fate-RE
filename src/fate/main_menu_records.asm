; Packed Fate menu records and adjacent initial state.
BITS 32
ORG 0x12e18

%macro menu_entry 3
    db %1
    dw %2
    dd %3
    times 6 dw 0
    dw 1
%endmacro

menu_entries_12e18:
    menu_entry 1, 0, 0xc08  ; NEW GAME
    menu_entry 1, 0, 0xc11  ; OPTIONS
    menu_entry 0, 0, 0xc19  ; LOAD GAME
    menu_entry 0, 0, 0xc23  ; SAVE GAME
    menu_entry 1, 0, 0xc2d  ; HELP
    menu_entry 0, 0, 0xc32  ; VIEW INTRO
    menu_entry 0, 0, 0xc3d  ; BACK TO GAME
    menu_entry 1, 0, 0xc4a  ; QUIT
    menu_entry 0, 0, 0xc08  ; NEW GAME
    menu_entry 1, 0, 0xc11  ; OPTIONS
    menu_entry 0, 0, 0xc19  ; LOAD GAME
    menu_entry 0, 0, 0xc23  ; SAVE GAME
    menu_entry 1, 0, 0xc2d  ; HELP
    menu_entry 0, 0, 0xc32  ; VIEW INTRO
    menu_entry 1, 0, 0xc3d  ; BACK TO GAME
    menu_entry 1, 0, 0xc4a  ; QUIT
    menu_entry 1, 0, 0xc4f  ; GOREFEST
    menu_entry 0, 0, 0xc58  ; GRAPHICS OPTIONS
    menu_entry 1, 0, 0xc69  ; SOUND OPTIONS
    menu_entry 1, 0, 0xc77  ; CONTROLLER OPTIONS
    menu_entry 1, 0, 0xc8a  ; GENERAL OPTIONS
    menu_entry 1, 0, 0xc9a  ; PREVIOUS MENU
    times 21 db 0
    times 21 db 0
    menu_entry 1, 0, 0xca8  ; YES INDEED
    menu_entry 1, 0, 0xcb3  ; NO ACTUALLY

save_slot_names_1303a:
    times 10 db '     EMPTY      ', 0

menu_entries_130e4:
    menu_entry 1, 0, 0xcbf  ; KEYBOARD
    menu_entry 1, 0, 0xcc8  ; MOUSE
    menu_entry 0, 0, 0xcce  ; JOYSTICKS
    menu_entry 0, 0, 0xcd8  ; VR HEADSETS
    menu_entry 1, 0, 0xc9a  ; PREVIOUS MENU

menu_text_state_1314d:
    times 7 db 0
