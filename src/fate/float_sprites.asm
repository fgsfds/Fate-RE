; Move vertical effects and spawn new effects near a supplied position.
BITS 32
ORG 0x136af

move_sprite equ 0x339b9
delete_sprite equ 0x50a09
random_value equ 0x602d0
update_sector equ 0x542c4
spawn_sprite_at_position equ 0x11073
format_string equ 0x601f3
report_error equ 0x26a03
float_sprite_list equ 0x6f8bc
ticks_per_step equ 0x7a994
sprite_zvel equ 0x2040c4
float_sprite_count equ 0x2bec
sector_floor_z equ 0x27c3a8
sprite_tile equ 0x2040ae
tile_height equ 0x1f4020
sprite_yrepeat equ 0x2040b5
sprite_z equ 0x2040a8
overflow_message equ 0x244
error_buffer equ 0x67e3c

update_float_sprites:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 4
    mov dword [esp], 1
    jmp near .check_count

.move_next_sprite:
    movsx edi, ax
    add edi, edi
    mov ax, word [edi + float_sprite_list]
    movsx esi, ax
    imul ecx, esi, 0x2c
    mov edx, dword [ticks_per_step]
    movsx ecx, word [ecx + sprite_zvel]
    imul ecx, edx
    push 1
    push 0x10
    xor ebx, ebx
    push 0x10
    mov eax, esi
    sar ecx, 2
    xor edx, edx
    call move_sprite
    test ax, ax
    je short .advance
    and eax, 0xffff
    cmp eax, strict dword 0x8000
    jge short .advance
    mov eax, esi
    call delete_sprite
    mov cx, word [float_sprite_count]
    movsx eax, word [float_sprite_count]
    dec ecx
    mov ax, word [nosplit eax*2 + float_sprite_list]
    mov word [float_sprite_count], cx
    mov word [edi + float_sprite_list], ax

.advance:
    inc dword [esp]

.check_count:
    mov eax, dword [esp]
    cmp ax, word [float_sprite_count]
    jle near .move_next_sprite
    add esp, 4
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

spawn_float_sprite:
    push esi
    push edi
    sub esp, 0x10
    mov esi, eax
    mov edi, edx
    mov edx, ecx
    call random_value
    add eax, eax
    movsx ecx, di
    cwde
    sar eax, cl
    mov ecx, dword [edx]
    add ecx, eax
    mov dword [esp], ecx
    call random_value
    add eax, eax
    movsx ecx, bx
    cwde
    mov edx, dword [edx + 4]
    sar eax, cl
    lea ebx, [esp + 0xc]
    add edx, eax
    mov eax, dword [esp]
    mov dword [esp + 4], edx
    call update_sector
    mov edx, dword [esp + 0xc]
    test dx, dx
    jl near .return
    movsx ebx, dx
    mov eax, ebx
    shl eax, 2
    add eax, ebx
    mov eax, dword [eax*8 + sector_floor_z]
    sub eax, strict dword 0x3e8
    mov edx, esp
    mov dword [esp + 8], eax
    movsx eax, si
    call spawn_sprite_at_position
    mov esi, eax
    cwde
    imul eax, eax, 0x2c
    movsx edx, word [eax + sprite_tile]
    movsx ebx, word [nosplit edx*2 + tile_height]
    xor edx, edx
    mov dl, byte [eax + sprite_yrepeat]
    mov ecx, edx
    imul ecx, ebx
    movsx ebx, word [esp + 0xc]
    mov edx, ebx
    shl edx, 2
    add edx, ebx
    add ecx, ecx
    mov edx, dword [edx*8 + sector_floor_z]
    sub edx, ecx
    sub edx, 0x3e8
    mov bx, word [float_sprite_count]
    mov dword [eax + sprite_z], edx
    mov edx, dword [esp + 0x1c]
    inc ebx
    mov word [eax + sprite_zvel], dx
    movsx eax, bx
    mov word [float_sprite_count], bx
    cmp eax, strict dword 0x1ff
    jle short .store_sprite
    push overflow_message
    push error_buffer
    call format_string
    add esp, 8
    mov eax, error_buffer
    call report_error

.store_sprite:
    movsx eax, word [float_sprite_count]
    mov word [nosplit eax*2 + float_sprite_list], si

.return:
    add esp, 0x10
    pop edi
    pop esi
    ret 4
