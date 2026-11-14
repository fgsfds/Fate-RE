; Apply clock-driven floor and ceiling panning to tagged sectors.
BITS 32
ORG 0x11e5e

format_string equ 0x601f3
report_error equ 0x26a03
overflow_message equ 0x18c
pan_sector_count equ 0x2bea
error_buffer equ 0x67e3c
pan_sectors equ 0x704bc
pan_clock equ 0x770b8
ceiling_pan_x equ 0x27c3b6
ceiling_pan_y equ 0x27c3b7
floor_pan_x equ 0x27c3be
floor_pan_y equ 0x27c3bf
sector_lotag equ 0x27c3c2

sector_panning_dispatch:
    dd update_sector_panning.floor_x_slow - 0x10000
    dd update_sector_panning.floor_x_normal - 0x10000
    dd update_sector_panning.store_floor_x - 0x10000
    dd update_sector_panning.floor_y_slow - 0x10000
    dd update_sector_panning.floor_y_normal - 0x10000
    dd update_sector_panning.floor_y_fast - 0x10000
    dd update_sector_panning.ceiling_x_slow - 0x10000
    dd update_sector_panning.ceiling_x_normal - 0x10000
    dd update_sector_panning.ceiling_x_fast - 0x10000
    dd update_sector_panning.ceiling_y_slow - 0x10000
    dd update_sector_panning.ceiling_y_normal - 0x10000
    dd update_sector_panning.store_ceiling_y - 0x10000

update_sector_panning:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 8
    mov ebx, 1
    jmp near .check_count
.next_sector:
    movsx eax, bx
    mov cx, [nosplit eax*2+pan_sectors]
    movsx edx, cx
    mov eax, edx
    shl eax, 2
    add eax, edx
    shl eax, 3
    mov dx, [eax+sector_lotag]
    sub edx, 18
    cmp dx, 11
    ja near .advance
    xor esi, esi
    mov edi, [pan_clock]
    mov si, dx
    mov dh, [pan_clock]
    sar edi, 2
    mov dl, dh
    and edi, 255
    shl dl, 2
    mov [esp], edi
    jmp dword [cs:sector_panning_dispatch-0x10000+esi*4]
.floor_x_slow:
    mov dl, [esp]
.store_floor_x:
    mov [eax+floor_pan_x], dl
    jmp near .advance
.floor_x_normal:
    mov [eax+floor_pan_x], dh
    jmp near .advance
.floor_y_slow:
    mov dl, [esp]
    mov [eax+floor_pan_y], dl
    jmp short .advance
.floor_y_normal:
    mov [eax+floor_pan_y], dh
    jmp short .advance
.floor_y_fast:
    mov [eax+floor_pan_y], dl
.ceiling_x_slow:
    mov eax, [pan_clock]
    sar eax, 4
    and eax, strict dword 255
    movsx edx, cx
    mov [esp+4], al
    mov eax, edx
    shl eax, 2
    add eax, edx
    mov dl, [esp+4]
    mov [eax*8+ceiling_pan_x], dl
    jmp short .advance
.ceiling_x_normal:
    mov [eax+ceiling_pan_x], dh
    jmp short .advance
.ceiling_x_fast:
    mov [eax+ceiling_pan_x], dl
    jmp short .advance
.ceiling_y_slow:
    mov edx, [pan_clock]
    sar edx, 4
    and edx, 255
.store_ceiling_y:
    mov [eax+ceiling_pan_y], dl
.advance:
    inc ebx
.check_count:
    cmp bx, [pan_sector_count]
    jle near .next_sector
    add esp, 8
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
.ceiling_y_normal:
    mov [eax+ceiling_pan_y], dh
    jmp short .advance

register_pan_sector:
    push ebx
    push edx
    mov edx, eax
    mov bx, [pan_sector_count]
    inc ebx
    movsx eax, bx
    mov [pan_sector_count], bx
    cmp eax, 63
    jle short .store_sector
    push overflow_message
    push error_buffer
    call format_string
    add esp, 8
    mov eax, error_buffer
    call report_error
.store_sector:
    movsx eax, word [pan_sector_count]
    mov [nosplit eax*2+pan_sectors], dx
    pop edx
    pop ebx
    ret
