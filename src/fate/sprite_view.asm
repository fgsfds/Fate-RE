; Directional tile IDs and their two targets in the adjacent compiled sprite view.
BITS 32
ORG 0x2a1ef

directional_sprite_tiles:
    dw 2767, 2762, 2757, 2752, 2747, 2742, 2737, 2732
    dw 2727, 2707, 2677, 2672, 2657, 2652, 2647, 2642
    dw 2637, 2632, 2627, 2622, 2617, 2597, 2567, 2562
    dw 2533, 2528, 2523, 2518, 2513, 2493, 2488, 2441
    dw 2411, 2406, 2391, 2386, 2381, 2376, 2371, 2366
    dw 2361, 2356, 2351, 2331, 2301, 2296, 843, 838
    dw 833, 785, 766, 165

sprite_view_dispatch:
    dd 0x2a3df - 0x10000
    times 52 dd 0x2a35e - 0x10000
