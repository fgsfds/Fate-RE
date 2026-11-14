; Initialize navigation pointers for fifteen copies of the same board layout.
BITS 32
ORG 0x19fbf

board_count equ 15
board_data_stride equ 0x738
board_sector_stride equ 0x9c
board_route_descriptors equ 0x4dac
board_waypoints equ 0x4d1c
route_record_size equ 22

; Slot, waypoint coordinates, sector workspace, next-hop matrix, matrix width.
%macro init_route 5
    mov dword [ecx + %1*route_record_size], %2 + board*board_data_stride
    mov dword [ecx + %1*route_record_size + 4], %3 + board*board_sector_stride
    mov dword [ecx + %1*route_record_size + 8], %4 + board*board_data_stride
    mov word [ecx + %1*route_record_size + 12], %5
    mov dword [ecx + %1*route_record_size + 14], -1000
    mov dword [ecx + %1*route_record_size + 18], 0
%endmacro

%assign board 0
%rep board_count
    mov word [eax], 8
    mov dword [edx], board_route_descriptors + board*board_data_stride
    mov dword [ebx], board_waypoints + board*board_data_stride
    init_route 0, 0x4e9f, 0x82d16, 0x4ef7, 10
    init_route 1, 0x4f5b, 0x82d02, 0x4fb3, 10
    init_route 2, 0x5017, 0x82cf6, 0x504f, 6
    init_route 3, 0x5073, 0x82ce2, 0x50cb, 10
    init_route 4, 0x512f, 0x82cc0, 0x51bf, 17
    init_route 5, 0x52e0, 0x82cb6, 0x5310, 5
    init_route 6, 0x5329, 0x82cac, 0x5359, 5
    init_route 7, 0x5372, 0x82c9e, 0x53b2, 7
    init_route 8, 0x53e3, 0x82c90, 0x5423, 7
    ret
%assign board board + 1
%endrep
