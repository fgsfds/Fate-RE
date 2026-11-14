; Advance a sprite toward a target, probing alternate headings when blocked.
BITS 32
ORG 0x197f8

random_value equ 0x602d0
get_angle equ 0x4c94c
clipmove equ 0x5291f
change_sprite_sector equ 0x50bc3
absolute_long equ 0x602c3
sprite_x equ 0x2040a0
ticks_per_step equ 0x7a994
sector_floor_z equ 0x27c3a8
tile_height equ 0x1f4020
actor_z_offset equ 0x79214
sine_table equ 0x2300a0
cansee equ 0x50d33
update_sector equ 0x542c4
sprite_actor_index equ 0x709dc
avoidance_angle_offset equ 0x822c0
blocked_steps equ 0x826aa
avoidance_steps equ 0x8289f
sector_lotag equ 0x27c3c2

; NASM selects 19 d0 for sbb eax, edx. Watcom used the equivalent 1b c2.
%macro sbb_eax_edx 0
    db 0x1b, 0xc2
%endmacro

move_sprite_toward_target:
    push esi
    push edi
    push ebp
    sub esp, 0x24
    push eax
    mov ebp, edx
    mov [esp + 0x10], ebx
    mov [esp + 0x24], cl
    cwde
    imul esi, eax, 0x2c
    mov di, [nosplit eax*2 + sprite_actor_index]
    movsx eax, di
    mov dx, [nosplit eax*2 + avoidance_angle_offset]
    add esi, sprite_x
    test dx, dx
    jnz near .check_avoidance
    mov edx, ebx
    mov eax, ebp
    mov ecx, [esi]
    mov ebx, [esi + 0x4]
    sub eax, ecx
    sub edx, ebx
    call get_angle
    and ah, 0x7
    mov [esi + 0x1c], ax
    cwde
    lea ebx, [eax + 0x200]
    and ebx, strict dword 0x7ff
    mov edx, [ticks_per_step]
    movsx ebx, word [nosplit ebx*2 + sine_table]
    imul ebx, edx
    xor ecx, ecx
    mov cl, [esp + 0x24]
    shl ebx, byte 0x2
    imul ebx, ecx
    movsx edx, word [nosplit eax*2 + sine_table]
    imul edx, [ticks_per_step]
    shl edx, byte 0x2
    imul edx, ecx
    mov ax, [esi + 0x18]
    mov [esp + 0x1c], eax
    mov eax, [esi]
    mov [esp + 0xc], eax
    mov eax, [esi + 0x4]
    mov [esp + 0x8], eax
    mov eax, [esi + 0x8]
    mov ecx, [esp + 0xc]
    mov [esp + 0x4], eax
    mov eax, ebx
    sub ebp, ecx
    sar eax, byte 0xe
    mov ecx, ebp
    call absolute_long
    mov ebp, eax
    mov eax, ecx
    call absolute_long
    cmp ebp, eax
    jng short .clamp_y_step
    mov ebx, ecx
    shl ebx, byte 0xe

.clamp_y_step:
    mov eax, edx
    mov ecx, [esp + 0x10]
    sar eax, byte 0xe
    mov ebp, [esp + 0x8]
    call absolute_long
    sub ecx, ebp
    mov ebp, eax
    mov eax, ecx
    call absolute_long
    cmp ebp, eax
    jng short .clip_direct_step
    mov edx, ecx
    shl edx, byte 0xe

.clip_direct_step:
    push strict byte 0x0
    xor eax, eax
    push strict dword 0x3e8
    mov al, [esi + 0x12]
    push strict dword 0x1c80
    shl eax, byte 0x2
    push eax
    push edx
    lea ecx, [esp + 0x30]
    lea eax, [esp + 0x20]
    push ebx
    lea edx, [esp + 0x20]
    lea ebx, [esp + 0x1c]
    call clipmove
    mov edx, [esp + 0xc]
    mov eax, [esi]
    sub eax, edx
    call absolute_long
    mov edx, [ticks_per_step]
    shl edx, byte 0x3
    cmp eax, edx
    jnl short .reset_blocked_steps
    mov ebx, [esp + 0x8]
    mov eax, [esi + 0x4]
    sub eax, ebx
    call absolute_long
    mov edx, [ticks_per_step]
    shl edx, byte 0x3
    cmp eax, edx
    jnl short .reset_blocked_steps
    movsx eax, di
    inc byte [eax + blocked_steps]
    jmp short .check_blocked_steps

.reset_blocked_steps:
    movsx eax, di
    xor dl, dl
    mov [eax + blocked_steps], dl

.check_blocked_steps:
    movsx eax, di
    mov al, [eax + blocked_steps]
    and eax, strict dword 0xff
    cmp eax, 0x2
    jl near .check_avoidance
    movsx ecx, word [esi + 0x1c]
    lea edx, [ecx + 0x800]
    and edx, strict dword 0x7ff
    add edx, edx
    movsx edx, word [edx + sine_table]
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x5
    sbb_eax_edx
    sar eax, byte 0x5
    lea edx, [ecx + 0x600]
    and edx, strict dword 0x7ff
    movsx edx, word [nosplit edx*2 + sine_table]
    mov ebx, eax
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x5
    sbb_eax_edx
    sar eax, byte 0x5
    mov ecx, [esi + 0x4]
    mov edx, eax
    mov ebp, [esi + 0x8]
    add ecx, edx
    mov eax, [esi]
    mov edx, ecx
    add eax, ebx
    lea ebx, [esp + 0x18]
    mov [esp + 0x14], eax
    call update_sector
    xor ebx, ebx
    mov eax, [esp + 0x18]
    mov [esp + 0x20], ebx
    test ax, ax
    jl short .probe_opposite_side
    cwde
    push eax
    push ebp
    mov ebx, ebp
    mov edx, [esi + 0x4]
    push ecx
    mov ecx, [esp + 0x20]
    mov eax, [esi]
    push ecx
    movsx ecx, word [esi + 0x18]
    call cansee
    mov [esp + 0x20], eax

.probe_opposite_side:
    movsx ecx, word [esi + 0x1c]
    lea edx, [ecx + 0x400]
    and edx, strict dword 0x7ff
    add edx, edx
    movsx edx, word [edx + sine_table]
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x5
    sbb_eax_edx
    sar eax, byte 0x5
    lea edx, [ecx + 0x200]
    and edx, strict dword 0x7ff
    movsx edx, word [nosplit edx*2 + sine_table]
    mov ebx, eax
    mov eax, edx
    sar edx, byte 0x1f
    shl edx, byte 0x5
    sbb_eax_edx
    sar eax, byte 0x5
    mov ecx, [esi + 0x4]
    mov edx, eax
    mov ebp, [esi + 0x8]
    add ecx, edx
    mov eax, [esi]
    mov edx, ecx
    add eax, ebx
    lea ebx, [esp + 0x18]
    mov [esp + 0x14], eax
    call update_sector
    mov edx, [esp + 0x18]
    xor eax, eax
    test dx, dx
    jl short .compare_probe_results
    movsx eax, dx
    push eax
    push ebp
    mov ebx, ebp
    push ecx
    mov eax, [esp + 0x20]
    mov edx, [esi + 0x4]
    push eax
    movsx ecx, word [esi + 0x18]
    mov eax, [esi]
    call cansee

.compare_probe_results:
    mov ebx, [esp + 0x20]
    cmp ax, bx
    jnz short .check_second_probe
    call random_value
    and eax, 0x1
    cmp eax, 0x1
    jnz short .choose_positive_offset

.choose_negative_offset:
    call random_value
    and ah, 0x1
    add ah, 0x5
    jmp short .store_avoidance_offset

.choose_positive_offset:
    call random_value
    and ah, 0x1
    inc ah
    jmp short .store_avoidance_offset

.check_second_probe:
    movsx eax, bx
    cmp eax, 0x1
    jz short .choose_negative_offset
    call random_value
    and ah, 0x1
    inc ah

.store_avoidance_offset:
    and ah, 0x7
    mov edx, eax
    movsx eax, di
    mov [nosplit eax*2 + avoidance_angle_offset], dx
    movsx eax, di
    xor ecx, ecx
    mov [nosplit eax*2 + avoidance_steps], cx

.check_avoidance:
    movsx ebx, di
    add ebx, ebx
    cmp word [ebx + avoidance_angle_offset], 0x0
    jz near .commit_position
    mov dx, [ebx + avoidance_steps]
    mov eax, 0x18
    inc edx
    mov ebp, [ticks_per_step]
    movsx ecx, dx
    mov [ebx + avoidance_steps], dx
    mov edx, eax
    inc ebp
    sar edx, byte 0x1f
    idiv ebp
    cmp ecx, eax
    jl short .clip_avoidance_step
    xor ecx, ecx
    mov [ebx + avoidance_angle_offset], cx

.clip_avoidance_step:
    mov ax, [esi + 0x18]
    mov [esp + 0x1c], eax
    mov eax, [esi]
    mov [esp + 0xc], eax
    mov eax, [esi + 0x4]
    mov [esp + 0x8], eax
    mov eax, [esi + 0x8]
    mov [esp + 0x4], eax
    movsx eax, di
    movsx edx, word [esi + 0x1c]
    movsx eax, word [nosplit eax*2 + avoidance_angle_offset]
    add eax, edx
    lea ebx, [eax + 0x200]
    and ebx, strict dword 0x7ff
    add ebx, ebx
    mov edx, [ticks_per_step]
    movsx ebx, word [ebx + sine_table]
    imul ebx, edx
    xor ecx, ecx
    mov cl, [esp + 0x24]
    shl ebx, byte 0x2
    imul ebx, ecx
    mov edx, eax
    and edx, strict dword 0x7ff
    add edx, edx
    mov ebp, [ticks_per_step]
    movsx edx, word [edx + sine_table]
    imul edx, ebp
    shl edx, byte 0x2
    imul edx, ecx
    push strict byte 0x0
    xor eax, eax
    push strict dword 0x3e8
    mov al, [esi + 0x12]
    push strict dword 0x1c80
    shl eax, byte 0x2
    push eax
    push edx
    lea eax, [esp + 0x20]
    lea ecx, [esp + 0x30]
    push ebx
    lea edx, [esp + 0x20]
    lea ebx, [esp + 0x1c]
    call clipmove
    movsx edx, word [esp + 0x1c]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    movsx eax, word [nosplit eax*8 + sector_lotag]
    cmp eax, 0x4
    jz short .reject_tagged_sector
    cmp eax, strict dword 0x100
    jnz short .commit_position

.reject_tagged_sector:
    mov dword [esp + 0x1c], 0xffffffff

.commit_position:
    cmp word [esp + 0x1c], 0x0
    jl short .return
    mov eax, [esp + 0xc]
    mov [esi], eax
    mov eax, [esp + 0x8]
    mov [esi + 0x4], eax
    movsx eax, word [esi + 0xe]
    movsx edx, word [nosplit eax*2 + tile_height]
    xor eax, eax
    mov al, [esi + 0x15]
    mov ebx, eax
    imul ebx, edx
    movsx edx, word [esp + 0x1c]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    movsx edx, di
    mov eax, [nosplit eax*8 + sector_floor_z]
    mov ecx, [nosplit edx*4 + actor_z_offset]
    add ebx, ebx
    add eax, ecx
    sub eax, ebx
    mov [esi + 0x8], eax
    mov bx, [esi + 0x18]
    mov eax, [esp + 0x1c]
    cmp ax, bx
    jz short .return
    test ax, ax
    jl short .return
    movsx edx, ax
    movsx eax, word [esp]
    call change_sprite_sector

.return:
    add esp, 0x28
    pop ebp
    pop edi
    pop esi
    ret
