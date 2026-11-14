; Difficulty, audio and movement-limit menu records.
BITS 32
ORG 0x13a89

    dd -1
    times 3 db 0

%macro menu_entry 3
    db %1
    dw %2
    dd %3
    times 6 dw 0
    dw 1
%endmacro

difficulty:
    menu_entry 1, 0, 0x126c  ; EASY
    menu_entry 1, 0, 0x1271  ; MEDIUM
    menu_entry 1, 0, 0x1278  ; HARD
    menu_entry 1, 0, 0x127d  ; PREVIOUS MENU

audio:
    menu_entry 1, 2, 0x1298  ; SOUND FX VOLUME
    menu_entry 0, 2, 0x12a8  ; AMBIENT VOLUME
    menu_entry 1, 1, 0x12b7  ; SOUND FX
    menu_entry 0, 1, 0x12c0  ; AMBIENT
    menu_entry 1, 0, 0x12c8  ; PREVIOUS MENU

    dd 8, 8, 1, 1
    times 3 db 0

movement_limits:
    menu_entry 1, 2, 0x12e4  ; STRAFE SPEED
    menu_entry 1, 2, 0x12f1  ; STRAFE ACCEL
    menu_entry 1, 0, 0x12fe  ; PREVIOUS MENU

    dd 127, 8                 ; Strafe limit and step.
    db 0
