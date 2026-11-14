; Write a Build v7 board with sprites in status-list order.
BITS 32
ORG 0x4a11a

restore_ebp_edi_esi equ 0x4918a
open equ 0x61368
close equ 0x6219a
write equ 0x62a97
next_sprite_in_status equ 0x1fbca0
sprites equ 0x2040a0
walls equ 0x2310a0
sectors equ 0x27c3a0
map_version equ 0x286b28
status_sprite_heads equ 0x28811c
wall_count equ 0x289152
sector_count equ 0x289154

save_build_map:
    push esi
    push edi
    push ebp
    sub esp, 0x8
    mov ebp, edx
    mov [esp], ebx
    mov edi, ecx
    push strict dword 0x80
    push strict dword 0x261
    push eax
    call open
    add esp, 0xc
    movsx ecx, ax
    mov esi, eax
    cmp ecx, -1
    jnz short .branch_4a14b
    mov eax, ecx
    jmp near .branch_4a28c

.branch_4a14b:
    mov ebx, 0x4
    mov edx, map_version
    mov eax, ecx
    call write
    mov ebx, 0x4
    mov edx, ebp
    mov eax, ecx
    call write
    mov ebx, 0x4
    mov edx, [esp]
    mov eax, ecx
    call write
    mov ebx, 0x4
    mov edx, edi
    mov eax, ecx
    call write
    mov ebx, 0x2
    mov edx, [esp + 0x18]
    mov eax, ecx
    call write
    mov ebx, 0x2
    mov edx, [esp + 0x1c]
    mov eax, ecx
    call write
    mov ebx, 0x2
    mov edx, sector_count
    mov eax, ecx
    call write
    movsx edx, word [sector_count]
    mov ebx, edx
    shl ebx, byte 0x2
    mov eax, ecx
    add ebx, edx
    mov edx, sectors
    shl ebx, byte 0x3
    call write
    mov ebx, 0x2
    mov edx, wall_count
    mov eax, ecx
    call write
    mov edx, walls
    movsx ebx, word [wall_count]
    mov eax, ecx
    shl ebx, byte 0x5
    call write
    xor edx, edx
    xor edi, edi
    mov [esp + 0x4], edx
    jmp short .branch_4a228

.branch_4a206:
    mov ax, [nosplit eax*2 + status_sprite_heads]

.branch_4a20e:
    cwde
    cmp eax, -1
    jz short .branch_4a227
    mov ebx, [esp + 0x4]
    inc ebx
    mov ax, [nosplit eax*2 + next_sprite_in_status]
    mov [esp + 0x4], ebx
    jmp short .branch_4a20e

.branch_4a227:
    inc edi

.branch_4a228:
    movsx eax, di
    cmp eax, strict dword 0x400
    jl short .branch_4a206
    mov ebx, 0x2
    lea edx, [esp + 0x4]
    movsx eax, si
    call write
    xor edi, edi
    jmp short .branch_4a278

.branch_4a247:
    mov ax, [nosplit eax*2 + status_sprite_heads]

.branch_4a24f:
    movsx ecx, ax
    cmp ecx, -1
    jz short .branch_4a277
    imul edx, ecx, 0x2c
    mov ebx, 0x2c
    movsx eax, si
    add edx, sprites
    call write
    mov ax, [nosplit ecx*2 + next_sprite_in_status]
    jmp short .branch_4a24f

.branch_4a277:
    inc edi

.branch_4a278:
    movsx eax, di
    cmp eax, strict dword 0x400
    jl short .branch_4a247
    movsx eax, si
    call close
    xor eax, eax

.branch_4a28c:
    add esp, 0x8
    jmp near restore_ebp_edi_esi
