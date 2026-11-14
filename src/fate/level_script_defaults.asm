; Initialized state and configuration for board scripts 4, 5 and 7.
BITS 32
ORG 0x127f4

encounter_trigger_states:
    dw 0, 0

; Initial frame count, approach and reaction tiles, then animation tiles.
encounter_sequence:
    dw 12, 2331, 2391
    dw 833, 838, 843, -1

exit_scan_initialized:
    dw 0
exit_sequence:
    dw 12, 2441, 2470
    dw 833, 843, -1
encounter_clock:
    dw 0
    align 4, db 0

board_five_actors:
    dw 81, 82, 83, 84
board_five_destinations:
    dd -43776, 3072
    dd -43008, 4608
    dd -44288, 5632
    dd -43776, 6656

board_seven_key_consumed:
    dd 0
board_seven_sector_reset:
    dw 0
board_seven_sprite_presence:
    dw 0, 0
board_seven_trigger_sectors:
    dw 87, 76, 75, 74, 72, 86, 80, 79
    dw 78, 77, 56, 57, 58, 59, 60, 159
