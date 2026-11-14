; Dispatch a hit tag to matching sectors and sprites.
BITS 32
ORG 0x2b369

start_sequence equ 0x11fdd
activate_sector equ 0x28710
classify_sector_hit equ 0x3fccb
handle_board_hit equ 0x405b8
current_board equ 0x7f87e
next_sprite_stat equ 0x1fbca0
sprite_hitag equ 0x2040c8
sector_hitag equ 0x27c3c4
hit_sprite_list_head equ 0x28811c
sector_count equ 0x289154

dispatch_hit_event:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    xor ebx, ebx
    jmp short .check_sector

.inspect_sector:
    mov eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    cmp cx, [nosplit eax*8 + sector_hitag]
    jnz short .advance_sector
    movsx edx, bx
    mov eax, edx
    call classify_sector_hit
    cmp eax, 0x1
    jnz short .activate_matching_sector
    movsx eax, byte [current_board]
    call handle_board_hit
    jmp short .advance_sector

.activate_matching_sector:
    mov eax, ebx
    call activate_sector

.advance_sector:
    inc ebx

.check_sector:
    movsx eax, word [sector_count]
    cmp ebx, eax
    jl short .inspect_sector
    movsx ebx, word [hit_sprite_list_head]
    jmp short .check_sprite

.inspect_sprite:
    imul eax, ebx, 0x2c
    mov ax, [eax + sprite_hitag]
    xor ah, ah
    movsx edx, ax
    movsx eax, cx
    movsx esi, word [nosplit ebx*2 + next_sprite_stat]
    cmp edx, eax
    jnz short .advance_sprite
    mov eax, ebx
    call start_sequence

.advance_sprite:
    mov ebx, esi

.check_sprite:
    test ebx, ebx
    jnl short .inspect_sprite
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
