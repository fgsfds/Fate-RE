; Inventory tiles and teleport terminal records indexed by board.
BITS 32
ORG 0x3e04

    times 12 db 0                ; Restore count, adjacent state and release timer.
    dw 68, 0                     ; Scroll position and button latch.

item_groups:
    dw 0, 644, 645, 0, 643, 0, 646, 671, 0
    dw 394, 396, 395, 388, 0, 0, 399, 0
    dw 394, 388, 0, 389, 402, 0, 401, 0
    dw 474, 458, 511, 442, 0, 490, 527, 0
    times 15 dw 0

%macro terminal 6
    dd %1, %2, %3, %4, %5, %6    ; Origin XY, destination XY, board and entry.
%endmacro

%macro end_terminals 1
    terminal -1, 0, 0, 0, 0, 0
    times (5 - %1) * 6 dd 0
%endmacro

    terminal 24704, 20992, -25587, -1966, 1, 1583
    end_terminals 1
    terminal -12158, 2916, -3011, 23545, 2, 4
    end_terminals 1
    terminal 109, 26796, 38589, 19390, 0, 177
    end_terminals 1
    end_terminals 0
    terminal -3328, 14336, -39680, 6144, 5, 512
    end_terminals 1
    terminal -40448, 6144, -960, 14336, 4, 512
    terminal 30459, -22010, 30459, -22010, 5, 100
    end_terminals 2
    terminal -2176, 2432, 12576, 38272, 7, 1052
    end_terminals 1
    terminal 12544, 36736, -2176, 896, 6, 1018
    terminal 6080, 26176, -14039, 13239, 4, 880
    end_terminals 2
%rep 17
    end_terminals 0
%endrep
    terminal 28710, 29546, -6408, 17659, 4, 9
    end_terminals 1

    dw 0, -1                     ; Inventory override and previous override.
    dd 1000                      ; Saved status value.
