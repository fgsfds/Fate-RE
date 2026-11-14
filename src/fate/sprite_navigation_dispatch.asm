; Load the current board routes, resolve waypoint sectors and steer the actor.
BITS 32
ORG 0x1d38a

change_sprite_sector equ 0x50bc3
absolute_long equ 0x602c3
actor_sprite_index equ 0x7dab8
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
sprite_z equ 0x2040a8
sprite_sector equ 0x2040b8
sector_floor_z equ 0x27c3a8
actor_sequence_initial equ 0x7e4e2
update_sector equ 0x542c4
format_string equ 0x601f3
report_error equ 0x26a03
error_buffer equ 0x67e3c
loaded_board equ 0x127e4
current_board equ 0x7f87e
sprite_hitag equ 0x2040ca
route_waypoints equ 0x83d88
route_sectors equ 0x83d8c
route_next_hops equ 0x83d90
route_width equ 0x83d94
route_ceiling_offset equ 0x83d96
route_floor_offset equ 0x83d9a
zone_bounds equ 0x841d4
zone_routes equ 0x841d8
last_zone equ 0x841dc
actor_route_cache equ 0x841de
bad_waypoint_sector_message equ 0x378
missing_waypoint_terminator_message equ 0x3aa
select_sprite_path_target equ 0x19c7d

%macro dispatch_board 1-2
    mov ecx, route_waypoints
    mov ebx, zone_bounds
    mov edx, zone_routes
    mov eax, last_zone
    call %1
    %if %0 = 2
        jmp %2 .resolve_route_sectors
    %endif
%endmacro

navigation_dispatch:
%assign case_address 0x1d44a
%rep 25
    dd case_address - 0x10000
    %if case_address < 0x1d6a2
        %assign case_address case_address + 30
    %else
        %assign case_address case_address + 27
    %endif
%endrep

route_actor_toward_target:
    push esi
    push edi
    push ebp
    sub esp, 0x2c
    push eax
    push edx
    push ebx
    push ecx
    movsx ax, byte [current_board]
    cmp ax, [loaded_board]
    jz near .find_actor_sprite
    mov edx, 0xffffffff
    mov [loaded_board], ax
    xor ecx, ecx
    jmp short .check_cache_index

.invalidate_cache_entry:
    inc ecx
    mov [nosplit eax*8 + actor_route_cache], edx

.check_cache_index:
    movsx eax, cx
    cmp eax, strict dword 0x1f4
    jl short .invalidate_cache_entry
    mov al, [current_board]
    dec al
    cmp al, 0x18
    ja near .resolve_route_sectors
    and eax, strict dword 0xff
    jmp dword near [cs:eax*4 + navigation_dispatch - 0x10000]

    dispatch_board 0x1d193, near
    dispatch_board 0x1cfd8, near
    dispatch_board 0x1ce1d, near
    dispatch_board 0x1cbec, near
    dispatch_board 0x1c894, near
    dispatch_board 0x1c6d9, near
    dispatch_board 0x1c3bc, near
    dispatch_board 0x1be8c, near
    dispatch_board 0x1bcd1, near
    dispatch_board 0x1b9b4, near
    dispatch_board 0x1b7f9, near
    dispatch_board 0x1b63e, near
    dispatch_board 0x1b483, near
    dispatch_board 0x1b2c8, near
    dispatch_board 0x1b10d, near
    dispatch_board 0x1af52, near
    dispatch_board 0x1ad97, near
    dispatch_board 0x1abdc, near
    dispatch_board 0x1aa21, near
    dispatch_board 0x1a866, near
    dispatch_board 0x1a6ab, short
    dispatch_board 0x1a4f0, short
    dispatch_board 0x1a335, short
    dispatch_board 0x1a17a, short
    dispatch_board 0x19fbf

.resolve_route_sectors:
    xor ebx, ebx
    mov [esp + 0x30], ebx
    jmp near .check_zone_index

.start_zone_scan:
    xor ecx, ecx
    jmp near .check_waypoint_index

.resolve_waypoint_sector:
    movsx eax, word [esp + 0x30]
    mov [esp + 0x14], eax
    imul eax, eax, 0x16
    mov ebx, ebp
    shl ebx, byte 0x3
    mov eax, [eax + route_waypoints]
    add eax, ebx
    mov esi, [eax]
    cmp esi, -1
    jz near .advance_zone
    mov edi, [eax + 0x4]
    lea ebx, [esp + 0x24]
    mov edx, edi
    mov eax, esi
    call update_sector
    cmp word [esp + 0x24], 0x0
    jnl short .store_waypoint_sector
    push edi
    push esi
    push ebp
    mov esi, [esp + 0x20]
    push esi
    push strict dword bad_waypoint_sector_message
    push strict dword error_buffer
    call format_string
    add esp, 0x18
    mov eax, error_buffer
    call report_error

.store_waypoint_sector:
    movsx eax, word [esp + 0x30]
    imul eax, eax, 0x16
    movsx ebx, cx
    mov esi, [eax + route_sectors]
    mov eax, [esp + 0x24]
    inc ecx
    mov [esi + ebx*2], ax

.check_waypoint_index:
    movsx ebp, cx
    cmp ebp, 0x32
    jng near .resolve_waypoint_sector
    movsx eax, word [esp + 0x30]
    push eax
    push strict dword missing_waypoint_terminator_message
    push strict dword error_buffer
    call format_string
    add esp, 0xc
    mov eax, error_buffer
    call report_error

.advance_zone:
    inc dword [esp + 0x30]

.check_zone_index:
    mov eax, [esp + 0x30]
    cmp ax, [last_zone]
    jng near .start_zone_scan

.find_actor_sprite:
    movsx edx, word [esp + 0xc]
    mov ax, [nosplit edx*2 + actor_sprite_index]
    mov [esp + 0x28], eax
    cwde
    imul eax, eax, 0x2c
    mov bx, [eax + sprite_hitag]
    xor bl, bl
    and bh, 0x40
    movsx ebx, bx
    test ebx, ebx
    jnz near .return
    mov dl, [edx + actor_sequence_initial]
    mov [esp + 0x38], dl
    mov edx, [eax + sprite_x]
    mov eax, [eax + sprite_y]
    xor ecx, ecx
    mov [esp + 0x1c], eax
    jmp near .check_bounds_index

.read_zone_bounds:
    movsx eax, cx
    mov ebx, [zone_bounds]
    shl eax, byte 0x4
    add eax, ebx
    mov ebx, [eax]
    mov eax, [eax + 0x8]
    cmp ebx, eax
    jnl short .use_second_x_minimum
    mov esi, ebx
    jmp short .select_x_maximum

.use_second_x_minimum:
    mov esi, eax

.select_x_maximum:
    mov ebp, esi
    jng short .read_y_bounds
    mov eax, ebx

.read_y_bounds:
    mov edi, eax
    movsx eax, cx
    mov ebx, [zone_bounds]
    shl eax, byte 0x4
    add eax, ebx
    mov ebx, [eax + 0x4]
    mov eax, [eax + 0xc]
    cmp ebx, eax
    jnl short .use_second_y_minimum
    mov esi, ebx
    jmp short .select_y_maximum

.use_second_y_minimum:
    mov esi, eax

.select_y_maximum:
    jng short .check_destination_zone
    mov eax, ebx

.check_destination_zone:
    mov ebx, eax
    cmp ebp, [esp + 0x8]
    jg short .check_sprite_zone
    cmp edi, [esp + 0x8]
    jl short .check_sprite_zone
    cmp esi, [esp + 0x4]
    jg short .check_sprite_zone
    cmp eax, [esp + 0x4]
    jl short .check_sprite_zone
    mov [esp + 0x34], ecx

.check_sprite_zone:
    cmp edx, ebp
    jl short .advance_bounds_index
    cmp edx, edi
    jg short .advance_bounds_index
    mov edi, [esp + 0x1c]
    cmp esi, edi
    jg short .advance_bounds_index
    cmp ebx, edi
    jl short .advance_bounds_index
    mov [esp + 0x2c], ecx

.advance_bounds_index:
    inc ecx

.check_bounds_index:
    mov bx, [last_zone]
    cmp cx, bx
    jng near .read_zone_bounds
    mov eax, [esp + 0x2c]
    cmp ax, [esp + 0x34]
    jnz short .read_zone_route
    movsx eax, word [esp + 0xc]
    shl eax, byte 0x3
    add eax, actor_route_cache
    push eax
    xor eax, eax
    mov al, [esp + 0x3c]
    push eax
    movsx eax, word [esp + 0x34]
    imul eax, eax, 0x16
    mov edi, [eax + route_floor_offset]
    push edi
    mov ebp, [eax + route_ceiling_offset]
    push ebp
    movsx edx, word [eax + route_width]
    push edx
    mov edx, [eax + route_next_hops]
    push edx
    mov ebx, [eax + route_sectors]
    mov ecx, [eax + route_waypoints]
    push ebx
    movsx eax, word [esp + 0x44]
    push ecx
    mov edx, [esp + 0x28]
    mov ebx, [esp + 0x24]
    push strict byte -1
    movsx ecx, word [esp + 0x24]
    jmp near .select_target

.read_zone_route:
    movsx eax, bx
    movsx ebx, word [esp + 0x2c]
    inc eax
    mov ecx, ebx
    imul ecx, eax
    mov esi, ecx
    shl esi, byte 0x2
    mov eax, [zone_routes]
    sub esi, ecx
    movsx ecx, word [esp + 0x34]
    add esi, eax
    mov eax, ecx
    shl eax, byte 0x2
    sub eax, ecx
    mov ecx, eax
    mov al, [ecx + esi]
    xor ah, ah
    dec eax
    mov [esp + 0x20], eax
    imul eax, ebx, 0x16
    movsx esi, word [esp + 0x20]
    shl esi, byte 0x3
    mov edi, [eax + route_waypoints]
    add edi, esi
    mov eax, [edi]
    sub eax, edx
    mov edi, [edi + 0x4]
    call absolute_long
    cmp eax, strict dword 0x100
    jnl near .move_to_zone_exit
    mov ebp, [esp + 0x1c]
    mov eax, edi
    sub eax, ebp
    call absolute_long
    cmp eax, strict dword 0x100
    jnl near .move_to_zone_exit
    movsx edx, word [last_zone]
    inc edx
    imul edx, ebx
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    mov edx, eax
    mov eax, [zone_routes]
    add eax, edx
    xor edx, edx
    mov dl, [ecx + eax + 0x1]
    xor ebx, ebx
    dec edx
    mov bl, [ecx + eax + 0x2]
    movsx eax, dx
    imul eax, eax, 0x16
    dec ebx
    movsx edx, bx
    mov ebx, edx
    mov edi, [eax + route_waypoints]
    movsx ebp, word [esp + 0x28]
    mov esi, [edi + ebx*8]
    mov edi, [edi + ebx*8 + 0x4]
    imul ebx, ebp, 0x2c
    mov eax, [eax + route_sectors]
    mov ax, [eax + edx*2]
    movsx edx, word [ebx + sprite_sector]
    mov [esp + 0x24], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl eax, byte 0x3
    movsx edx, word [esp + 0x24]
    mov [esp + 0x10], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + sector_floor_z]
    mov [esp + 0x18], eax
    mov eax, [esp + 0x10]
    mov ecx, [esp + 0x18]
    mov eax, [eax + sector_floor_z]
    sub ecx, eax
    mov eax, ecx
    mov ecx, [ebx + sprite_z]
    add ecx, eax
    mov eax, ebp
    mov [ebx + sprite_z], ecx
    call change_sprite_sector
    movsx eax, word [esp + 0xc]
    mov [ebx + sprite_x], esi
    mov esi, 0xffffffff
    mov [ebx + sprite_y], edi
    mov [nosplit eax*8 + actor_route_cache], esi
    jmp short .return

.move_to_zone_exit:
    movsx eax, word [esp + 0xc]
    shl eax, byte 0x3
    add eax, actor_route_cache
    push eax
    xor eax, eax
    mov al, [esp + 0x3c]
    push eax
    movsx eax, word [esp + 0x34]
    imul eax, eax, 0x16
    mov edx, [eax + route_floor_offset]
    push edx
    mov ebx, [eax + route_ceiling_offset]
    push ebx
    movsx edx, word [eax + route_width]
    mov ecx, [eax + route_next_hops]
    push edx
    mov esi, [eax + route_sectors]
    mov edi, [eax + route_waypoints]
    push ecx
    movsx eax, word [esp + 0x38]
    push esi
    mov ebx, [esp + 0x20]
    mov edx, [esp + 0x24]
    push edi
    movsx ecx, word [esp + 0x20]
    push eax
    movsx eax, word [esp + 0x4c]

.select_target:
    call select_sprite_path_target

.return:
    add esp, 0x3c
    pop ebp
    pop edi
    pop esi
    ret
