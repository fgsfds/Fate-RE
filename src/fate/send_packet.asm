; Send a game packet through the active multiplayer transport.
BITS 32
ORG 0x424ec

transport equ 0x13cde
frame_state_13cdf equ 0x13cdf
local_player equ 0x13ce2
send_ipx_packet equ 0x41d59
comsend equ 0x41fce
startcom equ 0x4204f
getcrc equ 0x42f73
frame_state_186cb8 equ 0x186cb8
frame_state_186e47 equ 0x186e47
frame_state_186e48 equ 0x186e48
frame_state_186e57 equ 0x186e57
frame_state_18f6d8 equ 0x18f6d8
frame_state_18f6f8 equ 0x18f6f8
checksum_table equ 0x18f778
frame_state_18fb78 equ 0x18fb78
next_player equ 0x18fd78
frame_state_18fd98 equ 0x18fd98
write_index equ 0x18fdd0
frame_state_18fde0 equ 0x18fde0
frame_state_18fe14 equ 0x18fe14
frame_state_18fe34 equ 0x18fe34
first_player equ 0x19028a

send_packet:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x8
    push eax
    push edx
    push ebx
    cmp byte [transport], 0x0
    jna near .branch_4297d
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jnl near .branch_4261a
    xor eax, eax
    mov al, [edx]
    cmp eax, strict dword 0xfd
    jz short .branch_42525
    cmp eax, strict dword 0xfe
    jnz short .branch_4252d

.branch_42525:
    xor edx, edx
    mov [frame_state_18fe14], edx

.branch_4252d:
    mov eax, [write_index]
    movsx edx, word [eax]
    mov eax, [frame_state_18fe14]
    mov [nosplit eax*4 + frame_state_18fb78], edx
    mov al, [esp]
    and al, 0x1
    mov dl, [frame_state_18fe14]
    shl al, byte 0x7
    add al, dl
    and eax, strict dword 0xff
    movsx edx, word [esp]
    call comsend
    xor ebx, ebx
    jmp short .branch_42575

.branch_42563:
    mov eax, [esp + 0x4]
    mov al, [ebx + eax]
    and eax, strict dword 0xff
    call comsend
    inc ebx

.branch_42575:
    cmp ebx, edx
    jl short .branch_42563
    mov al, [frame_state_13cdf]
    and al, 0xf
    and eax, strict dword 0xff
    test eax, eax
    jng short .branch_425e1
    mov eax, [esp + 0x4]
    call getcrc
    mov edx, [esp]
    xor dh, dh
    and dl, 0x1
    movsx edx, dx
    mov ecx, [frame_state_18fe14]
    shl edx, byte 0x7
    add ecx, edx
    xor edx, edx
    mov dx, ax
    sar edx, byte 0x8
    and edx, strict dword 0xffff
    shl eax, byte 0x8
    xor edx, ecx
    and eax, strict dword 0xffff
    mov ebx, [nosplit edx*4 + checksum_table]
    xor ebx, eax
    mov al, bl
    and eax, strict dword 0xff
    call comsend
    sar ebx, byte 0x8
    xor eax, eax
    mov al, bl
    call comsend

.branch_425e1:
    mov eax, [write_index]
    movsx eax, word [eax]
    mov edx, [frame_state_18fe34]
    mov byte [edx + eax], 0x8f
    mov eax, [write_index]
    mov dx, [eax]
    inc edx
    and dh, 0x3f
    mov [eax], dx
    call startcom
    mov eax, [frame_state_18fe14]
    inc eax
    and eax, 0x7f
    mov [frame_state_18fe14], eax
    jmp near .branch_4297d

.branch_4261a:
    mov ebx, 0x40000
    mov eax, [frame_state_18fde0]

.branch_42624:
    test ebx, ebx
    jng short .branch_42631
    cmp byte [eax + 0x8], 0x0
    jz short .branch_42631
    dec ebx
    jmp short .branch_42624

.branch_42631:
    mov eax, [frame_state_18fd98]
    mov dl, [local_player]
    mov ebx, [esp + 0x4]
    mov [eax], dl
    xor eax, eax
    mov al, [ebx]
    mov edx, 0x1
    cmp eax, strict dword 0xc8
    jl short .branch_426ab
    cmp eax, strict dword 0xff
    jg short .branch_426ab
    xor ebx, ebx
    jmp short .branch_42666

.branch_4265d:
    inc ebx
    xor cl, cl
    mov [ebx + frame_state_186e47], cl

.branch_42666:
    cmp ebx, 0x10
    jl short .branch_4265d
    mov ebx, [frame_state_18fd98]
    mov eax, edx
    mov esi, [esp + 0x4]
    inc edx
    mov byte [ebx + eax], 0xfe
    xor ebx, ebx
    jmp short .branch_42691

.branch_42680:
    mov ecx, [frame_state_18fd98]
    mov eax, edx
    inc edx
    add eax, ecx
    mov cl, [esi + ebx]
    inc ebx
    mov [eax], cl

.branch_42691:
    movsx eax, word [esp]
    cmp ebx, eax
    jl short .branch_42680
    movsx eax, word [esp + 0x8]
    movsx edx, dx
    call send_ipx_packet
    jmp near .branch_4297d

.branch_426ab:
    mov ebx, [esp + 0x8]
    test bx, bx
    jnl near .branch_42747
    mov edi, [esp + 0x4]
    movsx ecx, word [first_player]
    jmp near .branch_42741

.branch_426c8:
    movsx eax, word [local_player]
    cmp ecx, eax
    jz short .branch_42739
    mov eax, ecx
    movsx ebx, word [nosplit ecx*2 + frame_state_18f6d8]
    shl eax, byte 0x3
    add ebx, ebx
    add eax, ebx
    mov esi, 0xffffffff
    mov ebx, [esp]
    mov [eax + frame_state_186cb8], si
    mov [eax + frame_state_18f6f8], bx
    xor ebx, ebx
    jmp short .branch_42731

.branch_426fe:
    movsx esi, word [nosplit ecx*2 + frame_state_18f6d8]
    mov eax, ecx
    mov ebp, esi
    shl eax, byte 0x4
    shl ebp, byte 0x4
    add eax, ecx
    add ebp, esi
    shl eax, byte 0x4
    shl ebp, byte 0x4
    add eax, ecx
    add ebp, esi
    shl eax, byte 0x3
    add ebp, ebp
    lea esi, [eax + ebp]
    mov al, [edi + ebx]
    inc ebx
    mov [esi + ebx + frame_state_186e57], al

.branch_42731:
    movsx eax, word [esp]
    cmp ebx, eax
    jl short .branch_426fe

.branch_42739:
    movsx ecx, word [nosplit ecx*2 + next_player]

.branch_42741:
    test ecx, ecx
    jnl short .branch_426c8
    jmp short .branch_427b5

.branch_42747:
    movsx eax, bx
    movsx ebx, word [nosplit eax*2 + frame_state_18f6d8]
    shl eax, byte 0x3
    add ebx, ebx
    add eax, ebx
    mov ebx, [esp + 0x8]
    mov esi, [esp + 0x4]
    mov [eax + frame_state_186cb8], bx
    mov ebx, [esp]
    movsx edi, word [esp + 0x8]
    mov [eax + frame_state_18f6f8], bx
    xor ebx, ebx
    jmp short .branch_427ad

.branch_4277b:
    mov eax, edi
    movsx ecx, word [nosplit edi*2 + frame_state_18f6d8]
    shl eax, byte 0x4
    mov ebp, ecx
    add eax, edi
    shl ebp, byte 0x4
    shl eax, byte 0x4
    add ebp, ecx
    add eax, edi
    shl ebp, byte 0x4
    shl eax, byte 0x3
    add ebp, ecx
    mov cl, [esi + ebx]
    add ebp, ebp
    inc ebx
    add eax, ebp
    mov [ebx + eax + frame_state_186e57], cl

.branch_427ad:
    movsx eax, word [esp]
    cmp ebx, eax
    jl short .branch_4277b

.branch_427b5:
    xor ebx, ebx
    mov [esp + 0xc], ebx
    jmp near .branch_428f8

.branch_427c0:
    movsx eax, word [esp + 0x8]
    mov esi, [esp + 0xc]
    movsx ecx, word [nosplit eax*2 + frame_state_18f6d8]
    sub ecx, esi
    mov ebx, eax
    and ecx, 0x3
    shl ebx, byte 0x3
    lea esi, [ecx + ecx]
    add esi, ebx
    mov di, [esi + frame_state_186cb8]
    lea ebx, [edx + 0x1]
    test di, di
    jnl short .branch_42836
    mov eax, [frame_state_18fd98]
    mov esi, edx
    mov byte [esi + eax], 0xff
    mov edx, ebx
    movsx ebx, word [first_player]
    jmp short .branch_42830

.branch_42805:
    movsx eax, word [local_player]
    cmp ebx, eax
    jz short .branch_42828
    mov al, [ebx + frame_state_186e48]
    mov edi, [frame_state_18fd98]
    mov ah, [esp + 0xc]
    mov esi, edx
    sub al, ah
    inc edx
    mov [edi + esi], al

.branch_42828:
    movsx ebx, word [nosplit ebx*2 + next_player]

.branch_42830:
    test ebx, ebx
    jnl short .branch_42805
    jmp short .branch_42863

.branch_42836:
    mov esi, [frame_state_18fd98]
    mov edi, edx
    mov dl, [esp + 0x8]
    mov [edi + esi], dl
    mov al, [eax + frame_state_186e48]
    sub al, [esp + 0xc]
    lea edx, [ebx + 0x1]
    mov [esp + 0x10], al
    mov eax, [frame_state_18fd98]
    add ebx, eax
    mov al, [esp + 0x10]
    mov [ebx], al

.branch_42863:
    movsx ebx, word [esp + 0x8]
    lea eax, [ecx + ecx]
    shl ebx, byte 0x3
    add eax, ebx
    mov bl, [eax + frame_state_18f6f8]
    mov esi, [frame_state_18fd98]
    mov [esp + 0x10], bl
    mov ebx, edx
    add esi, ebx
    mov bl, [esp + 0x10]
    mov [esi], bl
    movsx eax, word [eax + frame_state_18f6f8]
    sar eax, byte 0x8
    inc edx
    and eax, strict dword 0xff
    mov esi, [frame_state_18fd98]
    mov bl, al
    mov eax, edx
    inc edx
    mov [esi + eax], bl
    xor ebx, ebx
    jmp short .branch_428de

.branch_428ac:
    mov eax, ecx
    shl edi, byte 0x4
    shl eax, byte 0x4
    add edi, esi
    add eax, ecx
    shl edi, byte 0x4
    shl eax, byte 0x4
    add edi, esi
    add eax, ecx
    shl edi, byte 0x3
    add eax, eax
    lea esi, [edi + eax]
    mov eax, [frame_state_18fd98]
    mov edi, edx
    inc ebx
    add edi, eax
    mov al, [esi + ebx + frame_state_186e57]
    inc edx
    mov [edi], al

.branch_428de:
    movsx esi, word [esp + 0x8]
    lea eax, [ecx + ecx]
    mov edi, esi
    movsx eax, word [eax + edi*8 + frame_state_18f6f8]
    cmp ebx, eax
    jl short .branch_428ac
    inc dword [esp + 0xc]

.branch_428f8:
    cmp dword [esp + 0xc], 0x4
    jl near .branch_427c0
    movsx ebx, word [esp + 0x8]
    movsx edx, dx
    mov eax, ebx
    mov edi, [esp + 0x8]
    call send_ipx_packet
    test di, di
    jnl short .branch_42959
    movsx ebx, word [first_player]
    movsx eax, word [local_player]
    jmp short .branch_42953

.branch_4292b:
    cmp ebx, eax
    jz short .branch_4294b
    inc byte [ebx + frame_state_186e48]
    mov dx, [nosplit ebx*2 + frame_state_18f6d8]
    inc edx
    xor dh, dh
    and dl, 0x3
    mov [nosplit ebx*2 + frame_state_18f6d8], dx

.branch_4294b:
    movsx ebx, word [nosplit ebx*2 + next_player]

.branch_42953:
    test ebx, ebx
    jnl short .branch_4292b
    jmp short .branch_4297d

.branch_42959:
    mov dx, [nosplit ebx*2 + frame_state_18f6d8]
    inc edx
    mov ch, [ebx + frame_state_186e48]
    xor dh, dh
    inc ch
    and dl, 0x3
    mov [ebx + frame_state_186e48], ch
    mov [nosplit ebx*2 + frame_state_18f6d8], dx

.branch_4297d:
    add esp, 0x14
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
