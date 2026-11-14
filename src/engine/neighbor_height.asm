; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's adjacent-sector height selection.
BITS 32
ORG 0x50c63
sector_walls equ 0x27c3a0
sector_wall_count equ 0x27c3a2
ceiling_z equ 0x27c3a4
floor_z equ 0x27c3a8
walls equ 0x2310a0
shared_return equ 0x4c1ab

nextsectorneighborz_:
    push esi
    push edi
    push ebp
    sub esp,12
    mov esi,edx
    mov [esp+8],ebx
    mov [esp+4],ecx
    movsx edx,cx
    xor ebx,ebx
    cmp edx,1
    setne dl
    mov bl,dl
    movsx edx,ax
    mov edi,edx
    shl edi,2
    add edi,edx
    shl edi,3
    mov ecx,-1
    movsx eax,word [edi+sector_walls]
    add ebx,0x7fffffff
    shl eax,5
    movsx edi,word [edi+sector_wall_count]
    add eax,walls
.wall:
    cmp word [eax+12],0
    jl near .next
    movsx edx,word [esp+8]
    cmp edx,1
    jne .ceiling
    movsx edx,word [eax+12]
    mov [esp],edx
    mov ebp,[esp]
    shl edx,2
    add edx,ebp
    movsx ebp,word [esp+4]
    mov edx,[nosplit edx*8+floor_z]
    cmp ebp,1
    jne .below_floor
.above:
    cmp edx,esi
    jle .next
    cmp edx,ebx
    jge .next
    jmp .remember
.below_floor:
    cmp edx,esi
    jge .next
    cmp edx,ebx
    jle .next
    jmp .remember
.ceiling:
    movsx edx,word [eax+12]
    mov [esp],edx
    mov ebp,[esp]
    shl edx,2
    add edx,ebp
    movsx ebp,word [esp+4]
    mov edx,[nosplit edx*8+ceiling_z]
    cmp ebp,1
    je .above
    cmp edx,esi
    jge .next
    cmp edx,ebx
    jle .next
.remember:
    mov ebx,edx
    mov cx,[eax+12]
.next:
    add eax,32
    dec edi
    jne short .wall
    movsx eax,cx
    jmp near shared_return
