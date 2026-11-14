; Starting inventory and actor state serialized by GAMEDATA.
BITS 32
ORG 0x225d

    dw 0, 1, 0, 0, 0                 ; Effect counters and interaction state.
    dw 1, 0, 0, 0, 0, 0, 0, 0        ; Inventory availability.
    dw 1, 1, 0, 0, 0, 0, 0, 0        ; Primary inventory counts.
    dw 1, 1, 0, 0, 0, 0, 0, 0        ; Secondary inventory counts.
    dw 0, 0, 0                       ; Action and actor clocks.

waypoints:
    dd 5120, 4608,  7168, 4608,  7168, 7680,  5120, 7680
    dd -1, -1

    dd 9728, 4864,  9728, 7424
    dd -1, -1

    dd -7040, -8704,  -8704, -10624,  -10496, -8576,  -8576, -6912
    dd -1, -1

    dd -11264, 256,  -17280, -256,  -17536, 2688
    dd -1, -1

    dd -1, -1

    dd -6400, 0,  0, -384,  256, 2944
    dd -1, -1

    dd -1, -1

    dd -8704, 4736,  -8704, 18944
    dd -1, -1

    dd -4608, 8704,  -12800, 8704
    dd -1, -1

    dd 3328, -4608,  -8576, -3456,  -14336, 5120
    dd -1, -1

    dd 14080, -9216,  9600, 3584
    dd -1, -1

    dd 10240, 3840,  14080, -9600
    dd -1, -1

    dd 7296, 13824,  5632, 5632
    dd -1, -1

    dd -1, -1

    dd -4224, 19712,  -9344, 22272,  -6400, 28800,  3712, 28672
    dd 5888, 18688
    dd -1, -1

    dd -1, -1

    dd 9344, 37120,  9344, 48896
    dd -1, -1

    dd 9984, 49536,  9984, 37632
    dd -1, -1

    dd -20224, 29952,  -14848, 32128
    dd -1, -1

    dd -896, 25984,  -2816, 29824
    dd -1, -1

    dd -28672, 11776,  -40192, 11776,  -36096, 17024,  -31360, 22144
    dd -1, -1

    dd -24832, 8832,  -24832, 1536
    dd -1, -1

    dd -25728, 13312,  -25728, 22016
    dd -1, -1

    dd -13696, 2048,  -9984, 7040
    dd -1, -1

    dd -9856, -6528,  -17280, -3712,  -20096, 2048
    dd -1, -1

    dd -5376, -6528,  -1664, -1920,  0, 2048
    dd -1, -1

    dd 2432, -21376,  2432, -14720,  -384, -11520,  -512, -4224
    dd -1, -1

    dd 18176, -25536,  18432, -38272,  6272, -39808,  3712, -28288
    dd 7936, -25088
    dd -1, -1

    dd 11392, -39808,  4352, -39168,  4096, -26240,  4352, -39168
    dd -1, -1

    dd 28032, -19456,  24320, -18816,  23680, -14464,  28416, -13440
    dd -1, -1

    dd -25600, 8704,  -25600, 5120
    dd -1, -1

    dd -13312, -512,  -11008, -512
    dd -1, -1

    dd -5760, 27136,  -2560, 27136
    dd -1, -1

    dd 27008, -6272,  27008, -2432
    dd -1, -1

    times 256 * 8 - ($ - waypoints) db 0

; Packed 29-byte actor sprite templates used to restore board actors.
%macro sprite_template 5
    dw 0x181                     ; cstat
    db %1, 0, %2                 ; shade, palette, clip distance
    db %3, %4, 0, 0              ; repeats and offsets
    dw %5, 0x320, 0, 0, 0, -1   ; tile, angle, velocities and owner
    times 8 db 0                 ; Status, tags and trailing state.
%endmacro

sprite_templates:
    sprite_template -64, 32, 22, 18, 2406
    sprite_template -4,  32, 22, 18, 2411
    sprite_template -64, 32, 33, 27, 2672
    sprite_template -64, 32, 22, 18, 2296
    sprite_template -4,  32, 17, 17, 2488
    sprite_template -64, 64, 22, 18, 2562
    times 5 * 29 db 0
