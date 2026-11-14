; Resolve the sector containing a wall from adjacency or sector wall ranges.
BITS 32
ORG 0x5ddc6

numwalls equ 0x289152
wall_nextwall equ 0x2310aa
wall_nextsector equ 0x2310ac
numsectors equ 0x289154
sector_wallptr equ 0x27c3a0
sector_wallnum equ 0x27c3a2

sectorofwall_:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    test ax, ax
    jl short .invalid_wall
    cmp ax, word [numwalls]
    jl short .check_adjacent_wall

.invalid_wall:
    mov edx, 0xffffffff
    jmp near .restore_registers

.check_adjacent_wall:
    cwde
    shl eax, 5
    movsx eax, word [eax + wall_nextwall]
    test eax, eax
    jl short .search_sector_table
    shl eax, 5
    movsx edx, word [eax + wall_nextsector]
    jmp near .restore_registers

.search_sector_table:
    movsx ebx, word [numsectors]
    sar ebx, 1
    mov eax, ebx

.check_search_step:
    cmp ebx, 1
    jle short .check_first_wall
    mov edx, eax
    shl edx, 2
    add edx, eax
    mov si, word [edx*8 + sector_wallptr]
    sar ebx, 1
    cmp cx, si
    jle short .search_lower_half
    add eax, ebx
    jmp short .check_search_step

.search_lower_half:
    sub eax, ebx
    jmp short .check_search_step

.check_first_wall:
    mov edx, eax
    shl edx, 2
    add edx, eax
    cmp cx, word [edx*8 + sector_wallptr]
    jge short .check_last_wall
    dec eax
    jmp short .check_first_wall

.check_last_wall:
    mov edx, eax
    shl edx, 2
    add edx, eax
    movsx ebx, word [edx*8 + sector_wallnum]
    movsx edx, word [edx*8 + sector_wallptr]
    add edx, ebx
    movsx ebx, cx
    cmp edx, ebx
    jg short .use_sector_index
    inc eax
    jmp short .check_last_wall

.use_sector_index:
    mov edx, eax

.restore_registers:
    mov eax, edx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
