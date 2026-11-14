; Receive a multiplayer packet from the active serial or IPX transport.
BITS 32
ORG 0x42985

weapon_state_13cdc equ 0x13cdc
transport equ 0x13cde
frame_state_13cdf equ 0x13cdf
local_player equ 0x13ce2
startcom equ 0x4204f
restore_network_receive_registers equ 0x42489
getcrc equ 0x42f73
copy_network_buffer equ 0x432c1
frame_state_186d38 equ 0x186d38
checksum_table equ 0x18f778
frame_state_18fb78 equ 0x18fb78
next_player equ 0x18fd78
frame_state_18fda8 equ 0x18fda8
frame_state_18fdb4 equ 0x18fdb4
frame_state_18fdb8 equ 0x18fdb8
frame_state_18fdbc equ 0x18fdbc
read_index equ 0x18fdd8
frame_state_18fdf0 equ 0x18fdf0
frame_state_18fdf4 equ 0x18fdf4
frame_state_18fdfc equ 0x18fdfc
frame_state_18fe00 equ 0x18fe00
frame_state_18fe08 equ 0x18fe08
frame_state_18fe14 equ 0x18fe14
frame_state_18fe1c equ 0x18fe1c
frame_state_18fe24 equ 0x18fe24
frame_state_18fe2c equ 0x18fe2c
frame_state_18fe30 equ 0x18fe30
frame_state_18fe38 equ 0x18fe38
frame_state_18fe40 equ 0x18fe40
frame_state_18fe41 equ 0x18fe41
frame_state_190060 equ 0x190060
frame_state_190061 equ 0x190061
frame_state_190062 equ 0x190062
frame_state_190063 equ 0x190063
first_player equ 0x19028a

receive_packet:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x14
    mov ecx, eax
    mov ebp, edx
    cmp byte [transport], 0x0
    jna near .branch_42f10
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jnl near .branch_42cdf
    mov ax, [local_player]
    xor dl, dl
    xor al, 0x1
    mov [esp + 0xc], dl
    mov [ecx], ax
    jmp short .branch_42a1d

.branch_429c1:
    mov edx, [frame_state_18fdfc]
    test edx, edx
    jz near .branch_42ab4
    lea ecx, [edx-0x1]
    mov [frame_state_18fdfc], ecx
    cmp eax, strict dword 0x80
    jnl near .branch_42a6e
    mov edx, [frame_state_18fdf4]
    cmp byte [edx], 0x0
    jnz near .branch_42a6e
    mov esi, [frame_state_18fe14]
    mov ecx, eax
    sub ecx, esi
    and ecx, 0x7f
    cmp ecx, 0x4
    jng short .branch_42a6e
    mov byte [edx], 0x2
    mov edx, [read_index]
    mov ax, [nosplit eax*4 + frame_state_18fb78]
    mov [edx], ax

.branch_42a18:
    call startcom

.branch_42a1d:
    mov eax, [frame_state_18fdbc]
    mov edx, [frame_state_18fdf0]
    mov bx, [eax]
    cmp bx, [edx]
    jz near .branch_42f10
    movsx edx, word [eax]
    mov ebx, [frame_state_18fe24]
    add edx, ebx
    xor ebx, ebx
    mov bl, [edx]
    mov dx, [eax]
    inc edx
    and dh, 0x3f
    mov [eax], dx
    movsx eax, bx
    cmp eax, strict dword 0x8f
    jz near .branch_42ad5
    cmp eax, strict dword 0x83
    jnz near .branch_429c1
    inc dword [frame_state_18fdfc]
    jmp short .branch_42a1d

.branch_42a6e:
    mov edi, [frame_state_18fe38]
    cmp edi, strict dword 0x222
    jnl short .branch_42ab4
    movsx eax, bx
    cmp eax, strict dword 0x80
    jnz short .branch_42a98
    lea eax, [edi + 0x1]
    mov dl, 0x83
    mov [frame_state_18fe38], eax
    mov [edi + frame_state_190062], dl
    jmp short .branch_42a1d

.branch_42a98:
    cmp eax, strict dword 0x81
    jnz short .branch_42ab4
    lea eax, [edi + 0x1]
    mov ch, 0x8f
    mov [frame_state_18fe38], eax
    mov [edi + frame_state_190062], ch
    jmp near .branch_42a1d

.branch_42ab4:
    mov eax, [frame_state_18fe38]
    cmp eax, strict dword 0x222
    jnl near .branch_42a1d
    inc eax
    mov [eax + frame_state_190061], bl
    mov [frame_state_18fe38], eax
    jmp near .branch_42a1d

.branch_42ad5:
    mov ebx, [frame_state_18fdfc]
    test ebx, ebx
    jz short .branch_42b00
    xor esi, esi
    mov eax, [frame_state_18fe1c]
    mov [frame_state_18fdfc], esi
    mov [frame_state_18fe2c], esi
    mov byte [eax], 0x0
    mov [frame_state_18fe38], esi
    jmp near .branch_42a1d

.branch_42b00:
    mov al, [frame_state_13cdf]
    and al, 0xf
    and eax, strict dword 0xff
    setz al
    xor ah, ah
    mov esi, eax
    add esi, eax
    mov ax, [frame_state_18fe38]
    sub eax, 0x3
    add esi, eax
    mov al, [frame_state_190062]
    xor edx, edx
    and al, 0x7f
    mov dl, al
    mov eax, [frame_state_18fe00]
    mov bl, [eax]
    cmp edx, ebx
    jz short .branch_42b6b
    or byte [esp + 0xc], 0x1
    mov al, [eax]
    and eax, strict dword 0xff
    cmp eax, 0x1
    jnz short .branch_42b6b
    xor eax, eax
    mov al, [frame_state_190063]
    cmp eax, strict dword 0xfe
    jnz short .branch_42b6b
    mov eax, [frame_state_18fe30]
    cmp eax, [frame_state_18fe08]
    setl al
    xor ah, ah
    mov [local_player], ax

.branch_42b6b:
    mov al, [frame_state_190062]
    xor edx, edx
    and al, 0x80
    mov dl, al
    mov eax, esi
    xor ah, ah
    and al, 0x1
    sar edx, byte 0x7
    cwde
    cmp edx, eax
    jz short .branch_42b89
    or byte [esp + 0xc], 0x2

.branch_42b89:
    xor ebx, ebx
    jmp short .branch_42b9c

.branch_42b8d:
    movsx eax, bx
    lea edx, [eax + ebp]
    mov al, [eax + frame_state_190063]
    inc ebx
    mov [edx], al

.branch_42b9c:
    cmp bx, si
    jl short .branch_42b8d
    mov al, [frame_state_13cdf]
    and al, 0xf
    and eax, strict dword 0xff
    test eax, eax
    jng short .branch_42c0f
    movsx edx, si
    mov eax, ebp
    call getcrc
    xor edx, edx
    mov dx, ax
    mov ebx, edx
    xor edx, edx
    sar ebx, byte 0x8
    mov dl, [frame_state_190062]
    and ebx, strict dword 0xffff
    xor edx, ebx
    mov ebx, eax
    mov di, [nosplit edx*4 + checksum_table]
    mov eax, [frame_state_18fe38]
    xor edx, edx
    shl ebx, byte 0x8
    mov dl, [eax + frame_state_190061]
    xor ebx, edi
    shl edx, byte 0x8
    mov al, [eax + frame_state_190060]
    and eax, strict dword 0xff
    add edx, eax
    xor eax, eax
    mov ax, bx
    cmp eax, edx
    jz short .branch_42c0f
    or byte [esp + 0xc], 0x2

.branch_42c0f:
    xor ebx, ebx
    mov [frame_state_18fe38], ebx
    mov bl, [esp + 0xc]
    test bl, bl
    jz near .branch_42c99
    xor eax, eax
    mov al, bl
    cmp eax, 0x1
    jnz short .branch_42c5a
    mov al, [frame_state_190062]
    xor edx, edx
    and al, 0x7f
    mov dl, al
    mov eax, [frame_state_18fe00]
    mov al, [eax]
    and eax, strict dword 0xff
    sub edx, eax
    mov eax, edx
    and eax, 0x7f
    cmp eax, 0x7c
    jl short .branch_42c5a
    xor cl, cl
    mov [esp + 0xc], cl
    jmp near .branch_42a1d

.branch_42c5a:
    xor bh, bh
    mov eax, [frame_state_18fe2c]
    mov [esp + 0xc], bh
    test eax, eax
    jz short .branch_42c72
    lea edx, [eax-0x1]
    mov [frame_state_18fe2c], edx

.branch_42c72:
    mov eax, [frame_state_18fe1c]
    xor edx, edx
    mov dl, [eax]
    or edx, [frame_state_18fe2c]
    jnz near .branch_42a1d
    mov byte [eax], 0x2
    mov dword [frame_state_18fe2c], 0x2
    jmp near .branch_42a18

.branch_42c99:
    mov eax, [frame_state_18fe00]
    mov dl, [eax]
    inc dl
    and dl, 0x7f
    mov [eax], dl
    test si, si
    jng short .branch_42cc2
    xor eax, eax
    mov al, [ebp + 0x0]
    cmp eax, strict dword 0xc8
    jl short .branch_42cc2
    movsx eax, si
    mov edx, ebp
    call copy_network_buffer

.branch_42cc2:
    xor ecx, ecx
    mov eax, [frame_state_18fe1c]
    mov [frame_state_18fdfc], ecx
    mov [frame_state_18fe2c], ecx
    mov byte [eax], 0x0
    mov eax, esi
    jmp near .branch_42f12

.branch_42cdf:
    mov eax, [frame_state_18fdb8]
    mov edx, [frame_state_18fda8]
    mov bx, [eax]
    cmp bx, [edx]
    jz near .branch_42f10
    movsx ebx, word [eax]
    inc ebx
    mov edx, [frame_state_18fdb4]
    and ebx, strict dword 0x3fff
    movzx si, byte [edx + ebx]
    shl esi, byte 0x8
    movsx eax, word [eax]
    add edx, eax
    xor eax, eax
    mov al, [edx]
    xor ebx, ebx
    add esi, eax
    jmp short .branch_42d44

.branch_42d1d:
    mov eax, [frame_state_18fdb8]
    movsx edx, word [eax]
    movsx eax, bx
    add edx, eax
    lea edi, [edx + 0x2]
    mov edx, [frame_state_18fdb4]
    and edi, strict dword 0x3fff
    add edi, edx
    mov dl, [edi]
    inc ebx
    mov [eax + frame_state_18fe40], dl

.branch_42d44:
    cmp bx, si
    jl short .branch_42d1d
    xor eax, eax
    xor dh, dh
    mov al, [frame_state_18fe40]
    mov [esp + 0x10], dh
    mov [ecx], ax
    mov eax, 0x1
    jmp near .branch_42edf

.branch_42d63:
    movsx edx, ax
    mov dl, [edx + frame_state_18fe40]
    and edx, strict dword 0xff
    inc eax
    cmp edx, strict dword 0xfe
    jnz short .branch_42d90
    movsx edx, word [ecx]
    xor bh, bh
    mov [edx + frame_state_186d38], bh
    mov edx, esi
    sub edx, 0x2
    jmp near .branch_42e21

.branch_42d90:
    cmp edx, strict dword 0xff
    jnz short .branch_42dd4
    mov bx, [first_player]
    mov di, [local_player]
    jmp short .branch_42dcd

.branch_42da8:
    cmp bx, [ecx]
    jz short .branch_42dc2
    cmp bx, di
    jnz short .branch_42dc1
    movsx edx, ax
    mov dl, [edx + frame_state_18fe40]
    xor dh, dh
    mov [esp + 0x8], edx

.branch_42dc1:
    inc eax

.branch_42dc2:
    movsx ebx, bx
    mov bx, [nosplit ebx*2 + next_player]

.branch_42dcd:
    test bx, bx
    jnl short .branch_42da8
    jmp short .branch_42de4

.branch_42dd4:
    movsx edx, ax
    mov dl, [edx + frame_state_18fe40]
    xor dh, dh
    inc eax
    mov [esp + 0x8], edx

.branch_42de4:
    movsx edx, word [ecx]
    xor ebx, ebx
    mov edi, [esp + 0x8]
    mov bl, [edx + frame_state_186d38]
    cmp bx, di
    jnz near .branch_42eba
    movsx ebx, ax
    movzx di, byte [ebx + frame_state_18fe41]
    shl edi, byte 0x8
    mov bl, [ebx + frame_state_18fe40]
    xor bh, bh
    inc byte [edx + frame_state_186d38]
    mov edx, edi
    add edx, ebx
    add eax, strict dword 0x2

.branch_42e21:
    mov [esp + 0x4], edx
    xor ebx, ebx
    jmp short .branch_42e41

.branch_42e29:
    movsx edx, bx
    add edx, ebp
    movsx edi, ax
    mov [esp], edx
    mov dl, [edi + frame_state_18fe40]
    mov edi, [esp]
    inc eax
    inc ebx
    mov [edi], dl

.branch_42e41:
    cmp bx, [esp + 0x4]
    jl short .branch_42e29
    cmp byte [esp + 0x10], 0x0
    jnz short .branch_42ea7
    mov eax, [frame_state_18fdb8]
    mov bx, [eax]
    mov edx, esi
    add edx, ebx
    add edx, 0x2
    and dh, 0x3f
    mov [eax], dx
    mov esi, [esp + 0x4]
    test si, si
    jng short .branch_42ea7
    xor eax, eax
    mov al, [ebp + 0x0]
    cmp eax, strict dword 0xc8
    jl short .branch_42ea7
    cmp eax, strict dword 0xfd
    jl short .branch_42ea1
    movsx eax, si
    mov edx, ebp
    call copy_network_buffer
    xor eax, eax
    mov al, [ebp + 0x0]
    cmp eax, strict dword 0xfd
    jz near .branch_42f10
    cmp eax, strict dword 0xfe
    jz short .branch_42f10

.branch_42ea1:
    mov eax, [esp + 0x4]
    jmp short .branch_42f12

.branch_42ea7:
    mov di, [local_player]
    mov ax, [ecx]
    cmp ax, di
    jnz short .branch_42ea1
    xor eax, edi
    jmp short .branch_42f12

.branch_42eba:
    movsx edx, ax
    xor ebx, ebx
    mov bl, [edx + frame_state_18fe41]
    shl ebx, byte 0x8
    mov dl, [edx + frame_state_18fe40]
    xor dh, dh
    add edx, ebx
    mov [esp + 0x4], edx
    add edx, 0x2
    add eax, edx
    inc byte [esp + 0x10]

.branch_42edf:
    xor edx, edx
    mov dl, [esp + 0x10]
    cmp edx, 0x4
    jl near .branch_42d63
    mov bl, [weapon_state_13cdc]
    inc bl
    mov eax, [frame_state_18fdb8]
    mov [weapon_state_13cdc], bl
    add si, [eax]
    add esi, 0x2
    and esi, strict dword 0x3fff
    mov [eax], si

.branch_42f10:
    xor eax, eax

.branch_42f12:
    add esp, 0x14
    jmp near restore_network_receive_registers
