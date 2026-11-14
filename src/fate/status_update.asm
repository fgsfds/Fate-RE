; Update the status value and spawn the timed player effect.
BITS 32
ORG 0x1092e

report_error equ 0x26a03
start_negative_delta_effect equ 0x40b14
spawn_sprite_at_position equ 0x11073
set_sprite_motion equ 0x339b9
add_listed_sprite equ 0x134c2

invalid_difficulty_message equ 0xe8
effect_count equ 0x225d
effect_speed equ 0x225f
status_left_tenths equ 0x2263
difficulty_divisor equ 0x7deec
player_x equ 0x5ad9c
player_y equ 0x5ad5c
player_z equ 0x5ad1c
player_sector equ 0x5acfc
player_sprite equ 0x62f2c
player_angle equ 0x6308c
status_right_tenths equ 0x6319c
sine_table equ 0x2300a0
sprite_xvel equ 0x2040c0
sprite_yvel equ 0x2040c2
sprite_zvel equ 0x2040c4

adjust_status_value:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edx, eax
    movsx eax, word [difficulty_divisor]
    cmp eax, 1
    jge short .check_negative_delta
    mov eax, invalid_difficulty_message
    call report_error
.check_negative_delta:
    test dx, dx
    jge short .scale_delta
    mov ebx, [status_right_tenths]
    test ebx, ebx
    jge short .scale_delta
    cmp ebx, -1
    jge near .return
    mov dword [status_right_tenths], -1
    jmp near .return
.scale_delta:
    movsx edx, dx
    movsx ebx, word [difficulty_divisor]
    mov eax, edx
    sar edx, 31
    idiv ebx
    movsx ebx, ax
    mov edx, eax
    mov eax, ebx
    call start_negative_delta_effect
    mov cx, [status_left_tenths]
    test cx, cx
    jle short .add_delta
    test dx, dx
    jge short .add_delta
    mov esi, [status_right_tenths]
    sar ebx, 1
    movsx edx, cx
    add esi, ebx
    add edx, ebx
    mov [status_right_tenths], esi
    mov [status_left_tenths], dx
    test dx, dx
    jge short .cap_value
    xor edi, edi
    mov [status_left_tenths], di
    jmp short .cap_value
.add_delta:
    mov ecx, [status_right_tenths]
    movsx eax, dx
    add ecx, eax
    mov [status_right_tenths], ecx
.cap_value:
    cmp dword [status_right_tenths], 1000
    jle short .return
    mov dword [status_right_tenths], 1000
.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

spawn_counted_player_effect:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 12
    mov dx, [effect_count]
    test dx, dx
    jle near .return
    mov eax, [player_x]
    mov ebx, edx
    mov edx, esp
    mov [esp], eax
    mov eax, [player_y]
    dec ebx
    mov [esp+4], eax
    mov eax, [player_z]
    mov [effect_count], bx
    add eax, strict dword 4000
    movsx ebx, word [player_sector]
    mov [esp+8], eax
    mov eax, 36
    call spawn_sprite_at_position
    movsx edx, word [player_angle]
    mov esi, eax
    lea eax, [edx+212]
    and eax, 2047
    movsx eax, word [nosplit eax*2+sine_table]
    xor ecx, ecx
    shl eax, 8
    push 0
    mov [esp+4], eax
    lea eax, [edx-300]
    push 1024
    and eax, 2047
    movsx esi, si
    movsx eax, word [nosplit eax*2+sine_table]
    push 1024
    shl eax, 8
    mov edx, [esp+12]
    mov [esp+16], eax
    mov ebx, eax
    mov eax, esi
    call set_sprite_motion
    movsx eax, word [player_angle]
    add eax, strict dword 512
    and eax, 2047
    xor edx, edx
    movsx eax, word [nosplit eax*2+sine_table]
    mov dx, [effect_speed]
    sar eax, 3
    imul eax, edx
    mov ebx, eax
    imul eax, esi, 44
    mov [eax+sprite_xvel], bx
    mov bx, [player_angle]
    and bh, 7
    movsx ebx, bx
    movsx ebx, word [nosplit ebx*2+sine_table]
    sar ebx, 3
    imul edx, ebx
    mov [eax+sprite_yvel], dx
    movsx edx, word [player_sprite]
    imul edx, edx, 44
    mov word [eax+sprite_zvel], -1000
    mov bx, [edx+sprite_xvel]
    mov di, [eax+sprite_xvel]
    shl ebx, 3
    add edi, ebx
    mov [eax+sprite_xvel], di
    mov bx, [edx+sprite_yvel]
    mov cx, [eax+sprite_yvel]
    shl ebx, 3
    add ecx, ebx
    mov [eax+sprite_yvel], cx
    mov dx, [edx+sprite_zvel]
    mov di, [eax+sprite_zvel]
    shl edx, 3
    add edi, edx
    mov [eax+sprite_zvel], di
    mov eax, esi
    call add_listed_sprite
.return:
    add esp, 12
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
