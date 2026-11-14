; Packed Fate menu records and adjacent initial state.
BITS 32
ORG 0x13863

%macro menu_entry 3
    db %1
    dw %2
    dd %3
    times 6 dw 0
    dw 1
%endmacro

menu_entries_13863:
    menu_entry 1, 0, 0x1053  ; RESET TO DEFAULTS
    menu_entry 1, 0, 0x1065  ; PREVIOUS MENU
    menu_entry 1, 0, 0x1073  ; KEYBOARD CONFIGURE
    menu_entry 1, 0, 0x1086  ; KEYBOARD DEFAULTS
    menu_entry 1, 0, 0x1065  ; PREVIOUS MENU
    menu_entry 1, 0, 0x10d8  ; PYMANDROS DEMO
    menu_entry 1, 0, 0x10e7  ; LESYRGIA DEMO
    menu_entry 0, 0, 0x10f5  ; PREVIOUS MENU

demo_menu_state_1390b:
    times 1 db 0

menu_entries_1390c:
    menu_entry 1, 0, 0x1104  ; INVENTORY
    menu_entry 1, 0, 0x110e  ; KEY DEFAULTS
    menu_entry 0, 0, 0x111b  ; ABOUT
    menu_entry 1, 0, 0x1121  ; PREVIOUS MENU
    menu_entry 1, 0, 0x1121  ; PREVIOUS MENU
    times 21 db 0
    times 21 db 0

menu_entries_1399f:
    menu_entry 1, 0, 0x112f  ; PG FOREWARD
    menu_entry 1, 0, 0x113b  ; PG BACKWARD
    menu_entry 1, 0, 0x1121  ; PREVIOUS MENU

mouse_action_state_139de:
    dw 0
    dd 0x1164, 0x1172, 0x1180, 0x118e
    times 4 db 0
    db 6, 7, 0
    dd 0x119c, 0x11aa, 0x11b8

menu_entries_13a03:
    menu_entry 1, 2, 0x11c6  ; MOUSE X RATE
    menu_entry 1, 2, 0x11d3  ; MOUSE Y RATE
    menu_entry 1, 0, 0x11e0  ; PREVIOUS MENU
    menu_entry 1, 0, 0x11ee  ; MOUSE SENSITIVITY
    menu_entry 0, 0, 0x1200  ; MOUSE BUTTONS
    menu_entry 1, 0, 0x11e0  ; PREVIOUS MENU
