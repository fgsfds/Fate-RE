; Find the DOS IPX driver, open its socket, and initialize receive buffers.
BITS 32
ORG 0x41694

ipx_allocation_error equ 0x18fe
frame_state_13e64 equ 0x13e64
frame_state_13e66 equ 0x13e66
print_runtime_message equ 0x40bb4
initialize_network_peer_state equ 0x42319
allocate_conventional_memory equ 0x42fbb
simulate_network_interrupt equ 0x42ffc
memcpy equ 0x63245
frame_state_186cb8 equ 0x186cb8
frame_state_186d39 equ 0x186d39
frame_state_186e49 equ 0x186e49
frame_state_18f6d8 equ 0x18f6d8
frame_state_18f6f8 equ 0x18f6f8
frame_state_18fd98 equ 0x18fd98
frame_state_18fd9c equ 0x18fd9c
frame_state_18fda0 equ 0x18fda0
frame_state_18fda4 equ 0x18fda4
frame_state_18fda8 equ 0x18fda8
frame_state_18fdac equ 0x18fdac
frame_state_18fdb0 equ 0x18fdb0
frame_state_18fdb4 equ 0x18fdb4
frame_state_18fdb8 equ 0x18fdb8
frame_state_18fdc0 equ 0x18fdc0
frame_state_18fdc4 equ 0x18fdc4
frame_state_18fdce equ 0x18fdce
frame_state_18fdcf equ 0x18fdcf
frame_state_18fdd4 equ 0x18fdd4
frame_state_18fde0 equ 0x18fde0
frame_state_18fde4 equ 0x18fde4
frame_state_18fdec equ 0x18fdec
frame_state_18fe0c equ 0x18fe0c
frame_state_18fe30 equ 0x18fe30

initialize_ipx:
    push ebx
    push ecx
    push edx
    push esi
    push ebp
    mov eax, 0x1e8
    cmp dword [eax], 0x0
    jnz short .branch_416ad

.branch_416a3:
    mov eax, 0xffffffff
    jmp near .branch_41a3f

.branch_416ad:
    mov eax, 0x7a00
    xor edx, edx
    xor ecx, ecx
    xor ebx, ebx
    int byte 0x2f
    and eax, strict dword 0xff
    cmp eax, strict dword 0xff
    jnz short .branch_416a3
    mov eax, 0x46e4
    call allocate_conventional_memory
    mov [frame_state_18fdc0], eax
    test eax, eax
    jnz short .branch_416e6
    push strict dword ipx_allocation_error
    call print_runtime_message
    add esp, 0x4

.branch_416e6:
    mov edx, [frame_state_18fdc0]
    mov [frame_state_18fde4], edx
    add edx, 0x30
    mov [frame_state_18fde0], edx
    add edx, 0x30
    mov [frame_state_18fdd4], edx
    add edx, 0x20
    mov [frame_state_18fdac], edx
    add edx, 0x20
    mov [frame_state_18fda0], edx
    add edx, strict dword 0x230
    mov [frame_state_18fd98], edx
    add edx, strict dword 0x230
    mov [frame_state_18fda4], edx
    add edx, 0x10
    mov ebx, 0x180
    mov [frame_state_18fd9c], edx
    add edx, 0x50
    mov eax, [frame_state_18fdc0]
    mov [frame_state_18fdb0], edx
    add edx, strict dword 0x180
    sar eax, byte 0x4
    mov [frame_state_18fdb8], edx
    add edx, 0x2
    mov [frame_state_18fdec], eax
    mov [frame_state_18fda8], edx
    add edx, 0x2
    mov eax, [frame_state_18fdb0]
    mov [frame_state_18fdb4], edx
    mov edx, frame_state_13e66
    xor ecx, ecx
    call memcpy
    mov ebx, 0x1
    movsx edx, word [frame_state_13e64]
    xor eax, eax
    int byte 0x7a
    mov eax, 0xff
    movsx edx, word [frame_state_13e64]
    xor ecx, ecx
    xor ebx, ebx
    int byte 0x7a
    test al, 0xff
    jz short .branch_417b1
    mov eax, 0xfffffffe
    jmp near .branch_41a3f

.branch_417b1:
    push strict byte 0x0
    mov ebx, [frame_state_18fd9c]
    push ebx
    mov eax, 0x7a
    xor ecx, ecx
    push strict byte 0x0
    xor edx, edx
    mov ebx, 0x9
    call simulate_network_interrupt
    mov ebx, 0xa
    mov eax, frame_state_18fdc4
    mov edx, [frame_state_18fd9c]
    call memcpy
    mov al, [frame_state_13e64]
    mov [frame_state_18fdce], al
    movsx eax, word [frame_state_13e64]
    sar eax, byte 0x8
    mov [frame_state_18fdcf], al
    mov eax, [frame_state_18fd9c]
    xor edx, edx
    mov dl, [eax + 0x7]
    mov ebx, edx
    xor edx, edx
    shl ebx, byte 0x8
    mov dl, [eax + 0x6]
    add ebx, edx
    xor edx, edx
    mov dl, [eax + 0x8]
    mov al, [eax + 0x9]
    and eax, strict dword 0xff
    xor eax, edx
    shl eax, byte 0x10
    add ebx, eax
    mov eax, [frame_state_18fe0c]
    shl eax, byte 0x18
    add ebx, eax
    mov edx, frame_state_18fdc4
    mov eax, ebx
    mov [frame_state_18fe30], ebx
    call initialize_network_peer_state
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x8], 0x1
    mov eax, [frame_state_18fde0]
    mov byte [eax + 0x8], 0x0
    mov eax, [frame_state_18fdb8]
    mov word [eax], 0x0
    mov eax, [frame_state_18fda8]
    mov word [eax], 0x0
    mov edx, 0xf
    jmp short .branch_4187f

.branch_41870:
    dec edx
    xor ah, ah
    mov [edx + frame_state_186d39], ah
    mov [edx + frame_state_186e49], ah

.branch_4187f:
    test edx, edx
    jnl short .branch_41870
    xor edx, edx
    jmp short .branch_418b5

.branch_41887:
    xor ebx, ebx
    mov ecx, edx
    mov [nosplit edx*2 + frame_state_18f6d8], bx
    mov ebx, 0x3
    jmp short .branch_418b0

.branch_4189a:
    lea eax, [ebx + ebx]
    xor esi, esi
    dec ebx
    mov [eax + ecx*8 + frame_state_18f6f8], si
    mov [eax + ecx*8 + frame_state_186cb8], si

.branch_418b0:
    test ebx, ebx
    jnl short .branch_4189a
    inc edx

.branch_418b5:
    cmp edx, 0x10
    jl short .branch_41887
    xor edx, edx
    jmp short .branch_418c8

.branch_418be:
    mov eax, [frame_state_18fdd4]
    mov byte [edx + eax], 0x0
    inc edx

.branch_418c8:
    cmp edx, 0x1e
    jl short .branch_418be
    xor edx, edx
    jmp short .branch_418db

.branch_418d1:
    mov eax, [frame_state_18fde4]
    mov byte [edx + eax], 0x0
    inc edx

.branch_418db:
    cmp edx, 0x30
    jl short .branch_418d1
    mov dl, [frame_state_18fdb0]
    mov bh, [frame_state_18fdc0]
    mov eax, [frame_state_18fde4]
    sub dl, bh
    mov [eax + 0x4], dl
    mov eax, [frame_state_18fdb0]
    sub eax, [frame_state_18fdc0]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde4]
    mov [eax + 0x5], dl
    mov eax, [frame_state_18fde4]
    mov dl, [frame_state_18fdec]
    mov [eax + 0x6], dl
    mov edx, [frame_state_18fdec]
    mov eax, [frame_state_18fde4]
    sar edx, byte 0x8
    mov [eax + 0x7], dl
    mov eax, [frame_state_18fde4]
    mov dl, [frame_state_13e64]
    mov [eax + 0xa], dl
    movsx eax, word [frame_state_13e64]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde4]
    mov [eax + 0xb], dl
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x22], 0x2
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x23], 0x0
    mov dl, [frame_state_18fdd4]
    mov cl, [frame_state_18fdc0]
    mov eax, [frame_state_18fde4]
    sub dl, cl
    mov [eax + 0x24], dl
    mov edx, [frame_state_18fdd4]
    sub edx, [frame_state_18fdc0]
    mov eax, [frame_state_18fde4]
    sar edx, byte 0x8
    mov [eax + 0x25], dl
    mov eax, [frame_state_18fde4]
    mov dl, [frame_state_18fdec]
    mov [eax + 0x26], dl
    mov eax, [frame_state_18fdec]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde4]
    mov [eax + 0x27], dl
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x28], 0x1e
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x29], 0x0
    mov dl, [frame_state_18fda0]
    mov ch, [frame_state_18fdc0]
    mov eax, [frame_state_18fde4]
    sub dl, ch
    mov [eax + 0x2a], dl
    mov eax, [frame_state_18fda0]
    sub eax, [frame_state_18fdc0]
    sar eax, byte 0x8
    mov dl, al
    mov eax, [frame_state_18fde4]
    mov [eax + 0x2b], dl
    mov eax, [frame_state_18fde4]
    mov dl, [frame_state_18fdec]
    mov [eax + 0x2c], dl
    mov edx, [frame_state_18fdec]
    mov eax, [frame_state_18fde4]
    sar edx, byte 0x8
    mov [eax + 0x2d], dl
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x2e], 0x22
    mov eax, [frame_state_18fde4]
    mov byte [eax + 0x2f], 0x2
    push strict byte 0x0
    mov ebp, [frame_state_18fde4]
    push ebp
    mov ebx, 0x4
    xor ecx, ecx
    push strict byte 0x0
    xor edx, edx
    mov eax, 0x7a
    call simulate_network_interrupt
    xor eax, eax

.branch_41a3f:
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
