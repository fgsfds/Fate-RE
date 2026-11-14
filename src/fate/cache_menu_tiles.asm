; Cache menu tiles.
BITS 32
ORG 0x39488

menu_return equ 0x39234
loadtile equ 0x4bb0d
frame_state_201d1c equ 0x201d1c
frame_state_201d20 equ 0x201d20
frame_state_201d24 equ 0x201d24
frame_state_201d30 equ 0x201d30
frame_state_201d34 equ 0x201d34
frame_state_201d38 equ 0x201d38
frame_state_201d3c equ 0x201d3c

cache_menu_tiles:
    cmp dword [frame_state_201d30], 0x0
    jnz short .branch_3949b
    mov eax, 0x824
    call loadtile

.branch_3949b:
    cmp dword [frame_state_201d34], 0x0
    jnz short .branch_394ae
    mov eax, 0x825
    call loadtile

.branch_394ae:
    cmp dword [frame_state_201d38], 0x0
    jnz short .branch_394c1
    mov eax, 0x826
    call loadtile

.branch_394c1:
    cmp dword [frame_state_201d3c], 0x0
    jnz short .branch_394d4
    mov eax, 0x827
    call loadtile

.branch_394d4:
    cmp dword [frame_state_201d1c], 0x0
    jnz short .branch_394e7
    mov eax, 0x81f
    call loadtile

.branch_394e7:
    cmp dword [frame_state_201d20], 0x0
    jnz short .branch_394fa
    mov eax, 0x820
    call loadtile

.branch_394fa:
    cmp dword [frame_state_201d24], 0x0
    jnz near menu_return
    mov eax, 0x821
    jmp near loadtile
