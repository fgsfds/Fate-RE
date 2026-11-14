; The first X offset aliases the last board-seven trigger sector at DS:0x12868.
BITS 32
ORG 0x1286a

weapon_frame_offsets_after_shared_word:

    ; Weapon slot 0, 24 pairs of signed screen offsets.
    dw 106 ; Frame 0 Y offset.
    dw 202, 108
    dw 253, 124
    dw 0, 0
    dw 25, 109
    dw 0, 133
    dw 12, 160
    times 17 dw 0, 0

    ; Weapon slot 1, 24 pairs of signed screen offsets.
    dw 191, 175
    dw 160, 160
    dw 142, 144
    dw 141, 157
    dw 146, 170
    dw 150, 183
    dw 149, 137
    dw 151, 122
    dw 144, 142
    dw 157, 183
    dw 115, 45
    dw 59, 0
    dw 0, 0
    dw 40, 38
    dw 57, 136
    dw 0, 0
    dw 0, 0
    dw 142, 167
    times 6 dw 0, 0

    ; Weapon slot 2, 24 pairs of signed screen offsets.
    dw 155, 186
    dw 147, 157
    dw 138, 147
    dw 126, 130
    dw 138, 147
    dw 147, 157
    dw 155, 186
    dw 0, 0
    dw 131, 110
    dw 136, 135
    dw 135, 131
    dw 133, 133
    times 12 dw 0, 0

    ; Weapon slot 3, 24 pairs of signed screen offsets.
    dw 140, 166
    dw 0, 146
    dw 0, 131
    dw 0, 116
    dw 0, 98
    dw 0, 124
    dw 0, 126
    dw 0, 140
    times 16 dw 0, 0

    ; Weapon slot 4, 24 pairs of signed screen offsets.
    times 24 dw 0, 0

    ; Weapon slot 5, 24 pairs of signed screen offsets.
    times 24 dw 0, 0

    ; Weapon slot 6, 24 pairs of signed screen offsets.
    times 24 dw 0, 0

    ; Weapon slot 7, 24 pairs of signed screen offsets.
    times 24 dw 0, 0

weapon_animation_records:
    ; Base, ready, lower start/end, primary start/end/fire/projectile,
    ; secondary start/end/fire/projectile.
    dw 0, 0, 0, 0, 1057, 1059, 1057, 0, 1053, 1055, 1053, 0
    dw 1033, 1035, 1036, 1038, 1039, 1041, 1040, 2, 1042, 1050, 1048, 0
    dw 1021, 1024, 1025, 1027, 1029, 1032, 1030, 1, 0, 0, 0, 0
    dw 1067, 1069, 1069, 1067, 1073, 1073, 1073, 3, 1070, 1072, 1070, 1
    times 4*12 dw 0
