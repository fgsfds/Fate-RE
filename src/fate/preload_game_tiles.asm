; Preload game tiles.
BITS 32
ORG 0x3b14b

loadtile equ 0x4bb0d
current_board equ 0x7f87e
waloff equ 0x1ffca0

preload_game_tiles:
    push edx
    mov edx, 0x2fe

.branch_3b151:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b163
    movsx eax, dx
    call loadtile

.branch_3b163:
    inc edx
    cmp edx, strict dword 0x32a
    jng short .branch_3b151
    mov edx, 0x3e5

.branch_3b171:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b183
    movsx eax, dx
    call loadtile

.branch_3b183:
    inc edx
    cmp edx, strict dword 0x3fb
    jng short .branch_3b171
    mov edx, 0x5ab

.branch_3b191:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b1a3
    movsx eax, dx
    call loadtile

.branch_3b1a3:
    inc edx
    cmp edx, strict dword 0x5ad
    jng short .branch_3b191
    movsx eax, byte [current_board]
    cmp eax, 0x4
    jz short .branch_3b1c2
    cmp eax, 0x5
    jz short .branch_3b1c2
    cmp eax, 0x7
    jnz short .branch_3b1e2

.branch_3b1c2:
    mov edx, 0x8f8

.branch_3b1c7:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b1d9
    movsx eax, dx
    call loadtile

.branch_3b1d9:
    inc edx
    cmp edx, strict dword 0x9b6
    jng short .branch_3b1c7

.branch_3b1e2:
    movsx eax, byte [current_board]
    cmp eax, 0x6
    jz short .branch_3b1f3
    cmp eax, 0x7
    jnz short .branch_3b213

.branch_3b1f3:
    mov edx, 0x9b8

.branch_3b1f8:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b20a
    movsx eax, dx
    call loadtile

.branch_3b20a:
    inc edx
    cmp edx, strict dword 0xa01
    jng short .branch_3b1f8

.branch_3b213:
    movsx eax, byte [current_board]
    cmp eax, 0x6
    jz short .branch_3b224
    cmp eax, 0x7
    jnz short .branch_3b244

.branch_3b224:
    mov edx, 0xa02

.branch_3b229:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b23b
    movsx eax, dx
    call loadtile

.branch_3b23b:
    inc edx
    cmp edx, strict dword 0xa6f
    jng short .branch_3b229

.branch_3b244:
    movsx eax, byte [current_board]
    cmp eax, 0x5
    jnz short .branch_3b270
    mov edx, 0xa70

.branch_3b255:
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_3b267
    movsx eax, dx
    call loadtile

.branch_3b267:
    inc edx
    cmp edx, strict dword 0xadd
    jng short .branch_3b255

.branch_3b270:
    pop edx
    ret
