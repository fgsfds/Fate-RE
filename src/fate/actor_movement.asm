; Set the actor movement state or turn toward a secondary target at close range.
BITS 32
ORG 0x196b2

get_angle equ 0x4c94c
absolute_int equ 0x6032c
check_attack_target equ 0x1d3ee
absolute_long equ 0x602c3
actor_sprite_index equ 0x7dab8
actor_kind equ 0x7f0a0
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
advance_clock equ 0x229b
sprite_angle equ 0x2040bc

move_actor:
    push esi
    push edi
    sub esp, 0x8
    mov edi, eax
    mov esi, edx
    mov [esp], ecx
    movsx ecx, ax
    mov ax, [nosplit ecx*2 + actor_sprite_index]
    movsx edx, ax
    imul edx, edx, 0x2c
    mov [esp + 0x4], eax
    mov eax, esi
    sub eax, [edx + sprite_x]
    call absolute_long
    cmp eax, strict dword 0x200
    jg near .request_movement
    mov eax, ebx
    sub eax, [edx + sprite_y]
    call absolute_long
    cmp eax, strict dword 0x200
    jg near .request_movement
    cmp dword [esp + 0x14], 0x0
    jnz short .check_turn_clock
    cmp dword [esp + 0x18], 0x0
    jnz short .check_turn_clock
    xor bh, bh
    mov [ecx + actor_kind], bh
    jmp near .return

.check_turn_clock:
    cmp word [advance_clock], 0x0
    jz near .return
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    movsx ecx, di
    mov byte [ecx + actor_kind], 0x2
    mov edx, [esp + 0x18]
    mov esi, [eax + sprite_y]
    mov bx, [eax + sprite_angle]
    sub edx, esi
    mov esi, [esp + 0x14]
    mov edi, [eax + sprite_x]
    mov eax, esi
    sub eax, edi
    call get_angle
    mov edx, eax
    mov esi, eax
    movsx edi, ax
    movsx eax, bx
    sub edi, eax
    mov eax, edi
    call absolute_int
    mov edi, eax
    cwde
    cmp eax, strict dword 0x100
    jnl short .select_turn_direction
    xor bl, bl
    mov [ecx + actor_kind], bl
    mov ebx, edx
    jmp short .store_angle

.select_turn_direction:
    cmp dx, bx
    jng short .turn_negative
    mov eax, 0x100
    jmp short .check_angle_wrap

.turn_negative:
    mov eax, 0xffffff00

.check_angle_wrap:
    movsx edx, di
    cmp edx, strict dword 0x400
    jng short .apply_turn_step
    neg eax

.apply_turn_step:
    add ebx, eax
    and bh, 0x7
    movsx edx, si
    movsx eax, bx
    sub edx, eax
    mov eax, edx
    call absolute_int
    cwde
    cmp eax, strict dword 0x100
    jnl short .store_angle
    mov ebx, esi

.store_angle:
    movsx eax, word [esp + 0x4]
    imul eax, eax, 0x2c
    mov [eax + sprite_angle], bx
    jmp short .return

.request_movement:
    mov dl, 0x1
    movsx eax, di
    movsx ecx, word [esp]
    mov [eax + actor_kind], dl
    mov edx, esi
    call check_attack_target

.return:
    add esp, 0x8
    pop edi
    pop esi
    ret word 0x8
