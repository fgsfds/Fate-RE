; Select a waypoint for sprite movement and cache intermediate targets.
BITS 32
ORG 0x19c7d

integer_square_root equ 0x4ca38
absolute_int equ 0x6032c
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
sprite_sector equ 0x2040b8
sector_floor_z equ 0x27c3a8
cansee equ 0x50d33
report_error equ 0x26a03
move_sprite_toward_target equ 0x197f8
destination_scan_limit_message equ 0x2d8
destination_search_limit_message equ 0x2f9
sprite_scan_limit_message equ 0x325
sprite_search_limit_message equ 0x347
sector_ceiling_z equ 0x27c3a4

select_sprite_path_target:
    push esi
    push edi
    push ebp
    sub esp, 0x20
    mov ebp, [esp + 0x34]
    mov [esp + 0x10], eax
    mov [esp + 0x4], edx
    mov [esp], ebx
    mov edi, ecx
    mov ebx, [esp + 0x48]
    cwde
    imul eax, eax, 0x2c
    mov edx, [eax + sprite_x]
    mov [esp + 0xc], edx
    mov edx, [eax + sprite_y]
    mov ax, [eax + sprite_sector]
    mov [esp + 0x1c], eax
    mov eax, [esp + 0x50]
    mov [esp + 0x8], edx
    mov edx, [eax]
    cmp edx, -1
    jz short .check_route_state
    mov eax, [eax + 0x4]
    mov [esp + 0x4], edx
    jmp near .check_cache_distance

.check_route_state:
    movsx eax, word [esp + 0x30]
    cmp eax, edx
    jnz near .use_supplied_destination_waypoint
    test ebx, ebx
    jz short .skip_ceiling_trace
    movsx eax, cx
    push eax
    mov edx, eax
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + sector_ceiling_z]
    add eax, ebx
    push eax
    mov ecx, [esp + 0x8]
    push ecx
    movsx ecx, word [esp + 0x28]
    mov eax, ecx
    shl eax, byte 0x2
    mov esi, [esp + 0x10]
    add eax, ecx
    push esi
    mov edx, [nosplit eax*8 + sector_ceiling_z]
    mov eax, [esp + 0x1c]
    add ebx, edx
    mov edx, [esp + 0x18]
    call cansee
    mov esi, eax
    jmp short .check_floor_trace

.skip_ceiling_trace:
    mov esi, 0x1

.check_floor_trace:
    mov ebx, [esp + 0x44]
    test ebx, ebx
    jz short .skip_floor_trace
    movsx edx, di
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov eax, [nosplit eax*8 + sector_floor_z]
    push edx
    add eax, ebx
    push eax
    mov edi, [esp + 0x8]
    mov eax, [esp + 0xc]
    push edi
    movsx ecx, word [esp + 0x28]
    push eax
    mov eax, ecx
    shl eax, byte 0x2
    add eax, ecx
    mov edx, [esp + 0x54]
    mov ebx, [nosplit eax*8 + sector_floor_z]
    mov eax, [esp + 0x1c]
    add ebx, edx
    mov edx, [esp + 0x18]
    call cansee
    jmp short .check_direct_visibility

.skip_floor_trace:
    mov eax, 0x1

.check_direct_visibility:
    movsx edx, si
    cmp edx, 0x1
    jnz short .find_waypoint_near_destination
    cwde
    cmp eax, edx
    jz near .move_sprite

.find_waypoint_near_destination:
    mov edi, 0x7fffffff
    mov esi, 0x9c4

.restart_destination_scan:
    xor ecx, ecx
    jmp short .check_destination_scan_limit

.measure_destination_waypoint:
    shl eax, byte 0x3
    lea edx, [eax + ebp]
    mov eax, [edx]
    cmp eax, -1
    jz short .check_destination_search_result
    mov ebx, [edx + 0x4]
    mov edx, [esp + 0x4]
    sub edx, eax
    mov eax, [esp]
    sub eax, ebx
    mov ebx, eax
    mov eax, edx
    call absolute_int
    cmp eax, esi
    jnl short .advance_destination_scan
    mov eax, ebx
    call absolute_int
    cmp eax, esi
    jnl short .advance_destination_scan
    imul edx, edx
    mov eax, ebx
    imul eax, eax
    add eax, edx
    call integer_square_root
    cmp eax, edi
    jnl short .advance_destination_scan
    mov edi, eax
    mov [esp + 0x14], ecx

.advance_destination_scan:
    inc ecx

.check_destination_scan_limit:
    movsx eax, cx
    cmp eax, 0x32
    jng short .measure_destination_waypoint
    mov eax, destination_scan_limit_message
    call report_error

.check_destination_search_result:
    cmp edi, strict dword 0x7fffffff
    jnz short .find_waypoint_near_sprite
    cmp esi, strict dword 0x4e20
    jl short .expand_destination_search
    mov eax, destination_search_limit_message
    call report_error

.expand_destination_search:
    add esi, esi
    jmp near .restart_destination_scan

.use_supplied_destination_waypoint:
    mov eax, [esp + 0x30]
    mov [esp + 0x14], eax

.find_waypoint_near_sprite:
    mov edi, 0x7fffffff
    mov esi, 0x9c4

.restart_sprite_scan:
    xor ecx, ecx
    jmp short .check_sprite_scan_limit

.measure_sprite_waypoint:
    shl eax, byte 0x3
    lea edx, [eax + ebp]
    mov eax, [edx]
    cmp eax, -1
    jz short .check_sprite_search_result
    mov ebx, [edx + 0x4]
    mov edx, [esp + 0xc]
    sub edx, eax
    mov eax, [esp + 0x8]
    sub eax, ebx
    mov ebx, eax
    mov eax, edx
    call absolute_int
    cmp eax, esi
    jnl short .advance_sprite_scan
    mov eax, ebx
    call absolute_int
    cmp eax, esi
    jnl short .advance_sprite_scan
    imul edx, edx
    mov eax, ebx
    imul eax, eax
    add eax, edx
    call integer_square_root
    cmp eax, edi
    jnl short .advance_sprite_scan
    mov edi, eax
    mov [esp + 0x18], ecx

.advance_sprite_scan:
    inc ecx

.check_sprite_scan_limit:
    movsx eax, cx
    cmp eax, 0x32
    jng short .measure_sprite_waypoint
    mov eax, sprite_scan_limit_message
    call report_error

.check_sprite_search_result:
    cmp edi, strict dword 0x7fffffff
    jnz short .look_up_next_waypoint
    cmp esi, strict dword 0x4e20
    jl short .expand_sprite_search
    mov eax, sprite_search_limit_message
    call report_error

.expand_sprite_search:
    add esi, esi
    jmp near .restart_sprite_scan

.look_up_next_waypoint:
    movsx edx, word [esp + 0x18]
    movsx eax, word [esp + 0x40]
    imul eax, edx
    mov ebx, [esp + 0x3c]
    movsx edx, word [esp + 0x14]
    add eax, ebx
    movzx si, byte [edx + eax]
    dec esi
    movsx eax, si
    mov ecx, [esp + 0x38]
    lea edi, [eax + eax]
    mov edx, [ebp + eax*8 + 0x0]
    add edi, ecx
    mov [esp + 0x4], edx
    mov di, [edi]
    mov eax, [ebp + eax*8 + 0x4]
    movsx edx, di
    mov [esp], eax
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    mov edi, [esp + 0x44]
    mov eax, [nosplit eax*8 + sector_floor_z]
    push edx
    add eax, edi
    push eax
    mov eax, [esp + 0x8]
    movsx ecx, word [esp + 0x24]
    push eax
    mov eax, ecx
    shl eax, byte 0x2
    mov edx, [esp + 0x10]
    add eax, ecx
    push edx
    mov edx, [esp + 0x18]
    mov ebx, [nosplit eax*8 + sector_floor_z]
    mov eax, [esp + 0x1c]
    add ebx, edi
    call cansee
    cwde
    cmp eax, 0x1
    jz short .load_selected_waypoint
    mov esi, [esp + 0x18]

.load_selected_waypoint:
    movsx eax, si
    shl eax, byte 0x3
    add ebp, eax
    mov eax, [ebp + 0x0]
    mov [esp + 0x4], eax
    mov eax, [ebp + 0x4]

.check_cache_distance:
    mov [esp], eax
    mov edx, [esp + 0xc]
    mov ebp, [esp + 0x4]
    sub edx, ebp
    imul edx, edx
    mov ebx, [esp + 0x8]
    mov eax, [esp]
    sub ebx, eax
    mov eax, ebx
    imul eax, ebx
    add eax, edx
    call integer_square_root
    cmp eax, strict dword 0x960
    jg short .invalidate_cached_target
    cmp eax, strict dword 0x80
    jnl short .store_cached_target

.invalidate_cached_target:
    mov eax, [esp + 0x50]
    mov dword [eax], 0xffffffff
    jmp short .move_sprite

.store_cached_target:
    mov edx, [esp + 0x50]
    mov eax, [esp]
    mov [edx], ebp
    mov [edx + 0x4], eax

.move_sprite:
    movsx eax, word [esp + 0x10]
    mov ebx, [esp]
    xor ecx, ecx
    mov edx, [esp + 0x4]
    mov cl, [esp + 0x4c]
    call move_sprite_toward_target
    add esp, 0x20
    pop ebp
    pop edi
    pop esi
    ret 0x24
