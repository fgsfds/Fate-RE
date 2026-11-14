; Initialize route tables for the remaining ten board variants.
BITS 32
ORG 0x1b9b4

route_record_size equ 22

; Last slot, board route descriptors, board waypoints.
%macro init_board 3
    mov word [eax], %1
    mov dword [edx], %2
    mov dword [ebx], %3
%endmacro

; Register, record offset, waypoint list, sector workspace, next-hop matrix,
; matrix width, ceiling trace offset, floor trace offset.
%macro route_fields 8
    mov dword [%1 + %2], %3
    mov dword [%1 + %2 + 4], %4
    mov dword [%1 + %2 + 8], %5
    mov word [%1 + %2 + 12], %6
    mov dword [%1 + %2 + 14], %7
    mov dword [%1 + %2 + 18], %8
%endmacro

%macro init_route 7
    route_fields ecx, %1*route_record_size, %2, %3, %4, %5, %6, %7
%endmacro

; The last board initializer stages each record address in EAX. Its first
; and penultimate records update the pointer before the final field store.
%macro init_indirect_route 9
    mov dword [%1], %3
    mov dword [%1 + 4], %4
    mov dword [%1 + 8], %5
    mov word [%1 + 12], %6
    mov dword [%1 + 14], %7
    %ifidni %1, %2
        mov dword [%1 + 18], %8
        lea %2, [ecx + %9*route_record_size]
    %elifidni %2, ecx
        add ecx, %9*route_record_size
        mov dword [%1 + 18], %8
    %else
        lea %2, [ecx + %9*route_record_size]
        mov dword [%1 + 18], %8
    %endif
%endmacro

initialize_sprite_path_board_16:
    init_board 14, 0xba54, 0xb964
    init_route 0, 0xbcf7, 0x8363c, 0xbd1f, 4, -1000, 0
    init_route 1, 0xbd2f, 0x83626, 0xbd8f, 11, -2000, 0
    init_route 2, 0xbe08, 0x83614, 0xbe58, 9, -8000, 0
    init_route 3, 0xbea9, 0x8360a, 0xbed9, 5, -3000, 0
    init_route 4, 0xbef2, 0x835fc, 0xbf32, 7, -1000, 0
    init_route 5, 0xbf63, 0x835ee, 0xbfa3, 7, -1000, 0
    init_route 6, 0xbfd4, 0x835e8, 0xbff4, 3, -3000, 0
    init_route 7, 0xbffd, 0x835e2, 0xc01d, 3, -3000, 0
    init_route 8, 0xc026, 0x835d2, 0xc06e, 8, -2000, 0
    init_route 9, 0xc0ae, 0x835ce, 0xc0c6, 2, -1000, 0
    init_route 10, 0xc0ca, 0x835ca, 0xc0e2, 2, -1000, 0
    init_route 11, 0xc0e6, 0x835c6, 0xc0fe, 2, -1000, 0
    init_route 12, 0xc102, 0x835c0, 0xc122, 3, -1000, 0
    init_route 13, 0xc12b, 0x835b8, 0xc153, 4, -10000, 0
    init_route 14, 0xc163, 0x835b4, 0xc17b, 2, -1000, 0
    ret

initialize_sprite_path_board_17:
    init_board 8, 0xc210, 0xc180
    init_route 0, 0xc303, 0x836ca, 0xc35b, 10, -1000, 0
    init_route 1, 0xc3bf, 0x836b6, 0xc417, 10, -1000, 0
    init_route 2, 0xc47b, 0x836aa, 0xc4b3, 6, -1000, 0
    init_route 3, 0xc4d7, 0x83696, 0xc52f, 10, -1000, 0
    init_route 4, 0xc593, 0x83674, 0xc623, 17, -1000, 0
    init_route 5, 0xc744, 0x8366a, 0xc774, 5, -1000, 0
    init_route 6, 0xc78d, 0x83660, 0xc7bd, 5, -1000, 0
    init_route 7, 0xc7d6, 0x83652, 0xc816, 7, -1000, 0
    init_route 8, 0xc847, 0x83644, 0xc887, 7, -1000, 0
    ret

initialize_sprite_path_board_18:
    init_board 23, 0xca38, 0xc8b8
    init_route 0, 0xd0f8, 0x83858, 0xd158, 11, -3000, 0
    init_route 1, 0xd1d1, 0x83846, 0xd221, 9, -15000, 0
    init_route 2, 0xd272, 0x83836, 0xd2ba, 8, -2000, 0
    init_route 3, 0xd2fa, 0x83824, 0xd34a, 9, -2000, 0
    init_route 4, 0xd39b, 0x8381c, 0xd3c3, 4, -2000, 0
    init_route 5, 0xd3d3, 0x83812, 0xd403, 5, -3000, 0
    init_route 6, 0xd41c, 0x83808, 0xd44c, 5, -3000, 0
    init_route 7, 0xd465, 0x837e6, 0xd4f5, 17, -3000, 0
    init_route 8, 0xd616, 0x837dc, 0xd646, 5, -4000, 0
    init_route 9, 0xd65f, 0x837c8, 0xd6b7, 10, -3000, 0
    init_route 10, 0xd71b, 0x837ba, 0xd75b, 7, -3000, 0
    init_route 11, 0xd78c, 0x837ac, 0xd7cc, 7, -3000, 0
    init_route 12, 0xd7fd, 0x8378a, 0xd88d, 17, -4000, 0
    init_route 13, 0xd9ae, 0x83778, 0xd9fe, 9, -4000, 0
    init_route 14, 0xda4f, 0x8376e, 0xda7f, 5, -2000, 0
    init_route 15, 0xda98, 0x8375e, 0xdae0, 8, -3000, 0
    init_route 16, 0xdb20, 0x83752, 0xdb58, 6, -3000, 0
    init_route 17, 0xdb7c, 0x83746, 0xdbb4, 6, -3000, 0
    init_route 18, 0xdbd8, 0x83738, 0xdc18, 7, -4000, 0
    init_route 19, 0xdc49, 0x8372a, 0xdc89, 7, -4000, 0
    init_route 20, 0xdcba, 0x8371c, 0xdcfa, 7, -3000, 0
    init_route 21, 0xdd2b, 0x8370a, 0xdd7b, 9, -3000, 0
    init_route 22, 0xddcc, 0x836f8, 0xde1c, 9, -3000, 0
    init_route 23, 0xde6d, 0x836e0, 0xded5, 12, -4000, 0
    ret

initialize_sprite_path_board_19:
    init_board 14, 0xe058, 0xdf68
    init_route 0, 0xe2fb, 0x8390e, 0xe323, 4, -1000, 0
    init_route 1, 0xe333, 0x838f0, 0xe3b3, 15, -3000, 0
    init_route 2, 0xe494, 0x838de, 0xe4e4, 9, -8000, 0
    init_route 3, 0xe535, 0x838c6, 0xe59d, 12, -4000, 0
    init_route 4, 0xe62d, 0x838b8, 0xe66d, 7, -1000, 0
    init_route 5, 0xe69e, 0x838aa, 0xe6de, 7, -1000, 0
    init_route 6, 0xe70f, 0x838a4, 0xe72f, 3, -3000, 0
    init_route 7, 0xe738, 0x8389e, 0xe758, 3, -3000, 0
    init_route 8, 0xe761, 0x8388e, 0xe7a9, 8, -2000, 0
    init_route 9, 0xe7e9, 0x8388a, 0xe801, 2, -1000, 0
    init_route 10, 0xe805, 0x83886, 0xe81d, 2, -1000, 0
    init_route 11, 0xe821, 0x83882, 0xe839, 2, -1000, 0
    init_route 12, 0xe83d, 0x8387c, 0xe85d, 3, -1000, 0
    init_route 13, 0xe866, 0x83874, 0xe88e, 4, -10000, 0
    init_route 14, 0xe89e, 0x83870, 0xe8b6, 2, -1000, 0
    ret

initialize_sprite_path_board_20:
    init_board 8, 0xe94c, 0xe8bc
    init_route 0, 0xea3f, 0x83988, 0xea97, 10, -1000, 0
    init_route 1, 0xeafb, 0x83982, 0xeb1b, 3, -1000, 0
    init_route 2, 0xeb24, 0x83974, 0xeb64, 7, -2000, 0
    init_route 3, 0xeb95, 0x83964, 0xebdd, 8, -1000, 0
    init_route 4, 0xec1d, 0x83950, 0xec75, 10, -1000, 0
    init_route 5, 0xecd9, 0x83948, 0xed01, 4, -1000, 0
    init_route 6, 0xed11, 0x8393a, 0xed51, 7, -1000, 0
    init_route 7, 0xed82, 0x83922, 0xedea, 12, -1000, 0
    init_route 8, 0xee7a, 0x83918, 0xeeaa, 5, -1000, 0
    ret

initialize_sprite_path_board_21:
    init_board 15, 0xefc4, 0xeec4
    init_route 0, 0xf2c4, 0x83ad0, 0xf394, 25, -4000, 0
    init_route 1, 0xf605, 0x83aba, 0xf665, 11, -5000, 0
    init_route 2, 0xf6de, 0x83ab2, 0xf706, 4, -3000, 0
    init_route 3, 0xf716, 0x83aa0, 0xf766, 9, -2000, 0
    init_route 4, 0xf7b7, 0x83a92, 0xf7f7, 7, -3000, 0
    init_route 5, 0xf828, 0x83a86, 0xf860, 6, -6000, 0
    init_route 6, 0xf884, 0x83a78, 0xf8c4, 7, -6000, 0
    init_route 7, 0xf8f5, 0x83a62, 0xf955, 11, -5000, 0
    init_route 8, 0xf9ce, 0x83a5c, 0xf9ee, 3, -5000, 0
    init_route 9, 0xf9f7, 0x83a56, 0xfa17, 3, -5000, 0
    init_route 10, 0xfa20, 0x83a2e, 0xfac8, 20, -5000, 0
    init_route 11, 0xfc58, 0x83a16, 0xfcc0, 12, -15000, 0
    init_route 12, 0xfd50, 0x839f0, 0xfdf0, 19, -6000, 0
    init_route 13, 0xff59, 0x839e4, 0xff91, 6, -6000, 0
    init_route 14, 0xffb5, 0x839ce, 0x10015, 11, -2000, 0
    init_route 15, 0x1008e, 0x8399c, 0x1015e, 25, -6000, 0
    ret

initialize_sprite_path_board_22:
    init_board 10, 0x10480, 0x103d0
    init_route 0, 0x105eb, 0x83bac, 0x10603, 2, -1000, 0
    init_route 1, 0x10607, 0x83b96, 0x10667, 11, -1000, 0
    init_route 2, 0x106e0, 0x83b90, 0x10700, 3, -1000, 0
    init_route 3, 0x10709, 0x83b60, 0x107d1, 24, -1000, 0
    init_route 4, 0x10a11, 0x83b54, 0x10a49, 6, -1000, 0
    init_route 5, 0x10a6d, 0x83b4a, 0x10a9d, 5, -1000, 0
    init_route 6, 0x10ab6, 0x83b34, 0x10b16, 11, -1000, 0
    init_route 7, 0x10b8f, 0x83b20, 0x10be7, 10, -5000, 0
    init_route 8, 0x10c4b, 0x83b1c, 0x10c63, 2, 0, 1000
    init_route 9, 0x10c67, 0x83b18, 0x10c7f, 2, -1000, 0
    init_route 10, 0x10c83, 0x83b04, 0x10cdb, 10, -1000, 0
    ret

initialize_sprite_path_board_23:
    init_board 8, 0x10dd0, 0x10d40
    init_route 0, 0x10ec3, 0x83c0e, 0x10edb, 2, -1000, 0
    init_route 1, 0x10edf, 0x83be4, 0x10f8f, 21, -1000, 0
    init_route 2, 0x11148, 0x83bda, 0x11178, 5, -3000, 0
    init_route 3, 0x11191, 0x83bd6, 0x111a9, 2, -1000, 0
    init_route 4, 0x111ad, 0x83bd2, 0x111c5, 2, -1000, 0
    init_route 5, 0x111c9, 0x83bce, 0x111e1, 2, -3000, 0
    init_route 6, 0x111e5, 0x83bba, 0x1123d, 10, -1000, 0
    init_route 7, 0x112a1, 0x83bb6, 0x112b9, 2, -3000, 0
    init_route 8, 0x112bd, 0x83bb0, 0x112dd, 3, -3000, 0
    ret

initialize_sprite_path_board_24:
    init_board 8, 0x11378, 0x112e8
    init_route 0, 0x1146b, 0x83c9a, 0x114c3, 10, -1000, 0
    init_route 1, 0x11527, 0x83c86, 0x1157f, 10, -1000, 0
    init_route 2, 0x115e3, 0x83c7a, 0x1161b, 6, -1000, 0
    init_route 3, 0x1163f, 0x83c66, 0x11697, 10, -1000, 0
    init_route 4, 0x116fb, 0x83c44, 0x1178b, 17, -1000, 0
    init_route 5, 0x118ac, 0x83c3a, 0x118dc, 5, -1000, 0
    init_route 6, 0x118f5, 0x83c30, 0x11925, 5, -1000, 0
    init_route 7, 0x1193e, 0x83c22, 0x1197e, 7, -1000, 0
    init_route 8, 0x119af, 0x83c14, 0x119ef, 7, -1000, 0
    ret

initialize_sprite_path_board_25:
    init_board 10, 0x11ad0, 0x11a20
    init_indirect_route ecx, eax, 0x11c3b, 0x83d52, 0x11d03, 24, -500, 0, 1
    init_indirect_route eax, eax, 0x11f43, 0x83d4a, 0x11f6b, 4, -7000, 0, 2
    init_indirect_route eax, eax, 0x11f7b, 0x83d3c, 0x11fbb, 7, -500, 0, 3
    init_indirect_route eax, eax, 0x11fec, 0x83d34, 0x12014, 4, -500, 0, 4
    init_indirect_route eax, eax, 0x12024, 0x83d00, 0x120fc, 26, -500, 0, 5
    init_indirect_route eax, eax, 0x123a0, 0x83cfc, 0x123b8, 2, -7000, 0, 6
    init_indirect_route eax, eax, 0x123bc, 0x83cf2, 0x123ec, 5, -7000, 0, 7
    init_indirect_route eax, eax, 0x12405, 0x83cbe, 0x124dd, 26, -500, 0, 8
    init_indirect_route eax, eax, 0x12781, 0x83cba, 0x12799, 2, -7000, 0, 9
    init_indirect_route eax, ecx, 0x1279d, 0x83cb4, 0x127bd, 3, -7000, 0, 10
    route_fields ecx, 0, 0x127c6, 0x83cb0, 0x127de, 2, -316584, 0
    ret
