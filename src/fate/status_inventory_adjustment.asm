; Adjust player status and select the highest usable inventory slot.
BITS 32
ORG 0x29317

status_state_514 equ 0x514
active_status_format equ 0x51e
depleted_status_message equ 0x52a
inventory_available equ 0x2267
inventory_primary_count equ 0x2277
inventory_secondary_count equ 0x2287
viewed_player equ 0x3cfa
status_message_buffer equ 0x1df6c
draw_status_message equ 0x3462d
play_positioned_sound equ 0x34f76
position_sound_offset equ 0x562e5
player_y equ 0x5ad5c
player_x equ 0x5ad9c
format_string equ 0x601f3
measure_message equ 0x60381
player_status_sprite equ 0x62f2c
status_right_tenths equ 0x6319c
selected_inventory_slot equ 0x770c8
status_minimum_width equ 0x7ded8
sprite_tile equ 0x2040ae
presentation_height equ 0x287e8c
presentation_width equ 0x287e90

adjust_player_status:
    push ebx
    push ecx
    push esi
    push edi
    mov esi, eax
    cwde
    shl eax, byte 0x2
    mov ebx, [eax + status_right_tenths]
    test ebx, ebx
    jng near .return_depletion
    movsx edx, dx
    lea ecx, [ebx + edx]
    mov [eax + status_right_tenths], ecx
    cmp ecx, strict dword 0x3e7
    jng short .check_depletion
    mov dword [eax + status_right_tenths], 0x3e7

.check_depletion:
    movsx edi, si
    mov eax, edi
    shl eax, byte 0x2
    cmp dword [eax + status_right_tenths], 0x0
    jg short .check_status_display
    mov ebx, 0xffffffff
    mov edx, player_y
    push strict byte 0x1
    add edx, eax
    mov ecx, player_x
    push edx
    add ecx, eax
    mov [eax + status_right_tenths], ebx
    call position_sound_offset
    and eax, 0x7f
    lea edx, [eax + 0xfc0]
    mov ebx, 0x100
    mov eax, status_state_514
    call play_positioned_sound
    movsx eax, word [nosplit edi*2 + player_status_sprite]
    imul eax, eax, 0x2c
    mov word [eax + sprite_tile], 0x71

.check_status_display:
    mov bx, [viewed_player]
    cmp si, bx
    jnz near .return_depletion
    movsx eax, word [status_minimum_width]
    cmp eax, [presentation_width]
    jg short .return_depletion
    movsx eax, bx
    shl eax, byte 0x2
    mov edi, [eax + status_right_tenths]
    test edi, edi
    jng short .format_depleted_status
    push edi
    push strict dword active_status_format
    push strict dword status_message_buffer
    call format_string
    add esp, 0xc
    jmp short .draw_status

.format_depleted_status:
    push strict dword depleted_status_message
    push strict dword status_message_buffer
    call format_string
    add esp, 0x8

.draw_status:
    push strict byte 0x50
    mov eax, status_message_buffer
    mov ebx, status_message_buffer
    mov edx, [presentation_height]
    call measure_message
    mov ecx, eax
    mov eax, [presentation_width]
    shl ecx, byte 0x2
    sar eax, 1
    sub edx, 0x18
    sub eax, ecx
    mov ecx, 0x49
    call draw_status_message

.return_depletion:
    movsx eax, si
    cmp dword [nosplit eax*4 + status_right_tenths], 0x0
    setng al
    and eax, strict dword 0xff
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

refresh_inventory:
    push ebx
    push edx
    mov edx, 0x7
    jmp short .check_slot_index

.check_inventory_slot:
    movsx eax, dx
    add eax, eax
    movsx ebx, word [eax + inventory_available]
    cmp ebx, 0x1
    jnz short .previous_slot
    cmp word [eax + inventory_primary_count], 0x0
    jg short .select_slot
    cmp word [eax + inventory_secondary_count], 0x0
    jng short .previous_slot

.select_slot:
    movsx eax, dx
    mov [selected_inventory_slot], eax
    jmp short .check_selection

.previous_slot:
    dec edx

.check_slot_index:
    test dx, dx
    jnl short .check_inventory_slot

.check_selection:
    movsx eax, dx
    cmp eax, -1
    jnz short .return
    xor edx, edx
    mov [selected_inventory_slot], edx

.return:
    pop edx
    pop ebx
    ret
