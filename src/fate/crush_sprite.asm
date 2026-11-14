; Crush sprite.
BITS 32
ORG 0x40a48

bad_sprite_index_error equ 0x1732
button_latch_disabled equ 0x2bf6
map_mode equ 0x2bfa
adjust_status_value equ 0x1092e
start_sequence equ 0x11fdd
report_error equ 0x26a03
flatten_sprite equ 0x40991
restore_crush_sprite_registers equ 0x40a42
board_state_62f2c equ 0x62f2c
sprite_actor_index equ 0x709dc
actor_health equ 0x7cefa
actor_kind equ 0x7f0a0
sprite equ 0x2040a0
floor_base equ 0x27c3a8

crush_sprite:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ebx, eax
    test ax, ax
    jl short .branch_40a5c
    cwde
    cmp eax, strict dword 0x1000
    jl short .branch_40a66

.branch_40a5c:
    mov eax, bad_sprite_index_error
    call report_error

.branch_40a66:
    movsx edx, bx
    imul eax, edx, 0x2c
    mov cx, [nosplit edx*2 + sprite_actor_index]
    movsx ecx, cx
    add eax, sprite
    cmp ecx, -1
    jz short .branch_40abe
    xor esi, esi
    mov [nosplit ecx*2 + actor_health], si
    movsx esi, word [eax + 0x18]
    mov ebx, esi
    shl ebx, byte 0x2
    add ebx, esi
    mov ebx, [nosplit ebx*8 + floor_base]
    mov [eax + 0x8], ebx
    mov bl, [eax + 0x12]
    add bl, bl
    mov [eax + 0x12], bl
    mov byte [ecx + actor_kind], 0x3
    mov word [eax + 0xc], 0x0

.branch_40ab5:
    mov eax, edx
    call start_sequence
    jmp short restore_crush_sprite_registers

.branch_40abe:
    cmp bx, [board_state_62f2c]
    jnz short .branch_40ad6
    mov eax, 0x32
    call adjust_status_value
    jmp near restore_crush_sprite_registers

.branch_40ad6:
    mov si, [button_latch_disabled]
    cmp si, [eax + 0xe]
    jnz short .branch_40af8
    xor edi, edi
    mov [button_latch_disabled], di
    mov [map_mode], di
    jmp near restore_crush_sprite_registers

.branch_40af8:
    movsx eax, word [eax + 0x26]
    and eax, strict dword 0xff00
    sar eax, byte 0x8
    test eax, eax
    jnz short .branch_40ab5
    mov eax, edx
    call flatten_sprite
    jmp near restore_crush_sprite_registers
