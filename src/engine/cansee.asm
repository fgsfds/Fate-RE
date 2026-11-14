; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's portal visibility query.
BITS 32
ORG 0x50d33
queue equ 0x195f50
sectors equ 0x27c3a0
walls equ 0x2310a0
intersect equ 0x5261d
slope_heights equ 0x5e07a
shared_return equ 0x4cc84

cansee_:
    push esi
    push edi
    push ebp
    sub esp,32
    push eax
    push edx
    push ebx
    cmp eax,[esp+60]
    jne .seed
    mov eax,[esp+4]
    cmp eax,[esp+64]
    jne .seed
    cmp cx,[esp+72]
    sete al
    and eax,255
    jmp near .done

.seed:
    mov [queue],cx
    xor ecx,ecx
    mov ebp,1
    mov [esp+32],ecx
    jmp near .test_queue
.sector:
    movsx eax,word [nosplit esi*2+queue]
    mov [esp+36],eax
    mov edx,eax
    shl eax,2
    add eax,edx
    shl eax,3
    add eax,sectors
    movsx esi,word [eax]
    movsx edx,word [eax+2]
    shl esi,5
    mov [esp+40],edx
    add esi,walls
    jmp near .test_wall

.wall:
    movsx eax,word [esi+8]
    shl eax,5
    mov edx,[esp+4]
    add eax,walls
    mov ebx,[esp+8]
    mov edi,[esi]
    mov ecx,[eax+4]
    sub edi,ebx
    sub ecx,edx
    imul edi,ecx
    mov ecx,[esi+4]
    sub ecx,edx
    mov edx,[eax]
    sub edx,ebx
    imul edx,ecx
    cmp edi,edx
    jl near .next_wall

    ; Intersect the sight segment with the candidate wall.
    lea edx,[esp+20]
    push edx
    lea edx,[esp+28]
    push edx
    lea edx,[esp+36]
    push edx
    mov ecx,[eax+4]
    push ecx
    mov edi,[eax]
    push edi
    mov eax,[esi+4]
    push eax
    mov edx,[esi]
    push edx
    mov ebx,[esp+96]
    mov ecx,[esp+92]
    push ebx
    mov eax,[esp+40]
    mov edx,[esp+36]
    push ecx
    mov ebx,[esp+36]
    mov ecx,[esp+96]
    call intersect
    test eax,eax
    je near .next_wall
    movsx edi,word [esi+12]
    test edi,edi
    jl near .blocked
    mov ax,[esi+14]
    xor ah,ah
    and al,32
    cwde
    test eax,eax
    jne near .blocked

    ; The intersection Z must be strictly inside both sectors' openings.
    lea eax,[esp+12]
    lea ecx,[esp+16]
    mov ebx,[esp+24]
    mov edx,[esp+28]
    push eax
    movsx eax,word [esp+40]
    call slope_heights
    mov eax,[esp+20]
    cmp eax,[esp+16]
    jle near .blocked
    cmp eax,[esp+12]
    jge near .blocked
    lea eax,[esp+12]
    lea ecx,[esp+16]
    mov ebx,[esp+24]
    mov edx,[esp+28]
    push eax
    movsx eax,di
    call slope_heights
    mov eax,[esp+20]
    cmp eax,[esp+16]
    jle near .blocked
    cmp eax,[esp+12]
    jge near .blocked
    lea eax,[ebp-1]
    jmp .test_seen
.seen:
    movsx edx,word [nosplit eax*2+queue]
    cmp edx,edi
    je .already_queued
    dec eax
.test_seen:
    test eax,eax
    jge .seen
.already_queued:
    test eax,eax
    jge .next_wall
    inc ebp
    mov [nosplit ebp*2+0x195f4e],di
.next_wall:
    mov ebx,[esp+40]
    dec ebx
    add esi,32
    mov [esp+40],ebx
.test_wall:
    cmp dword [esp+40],0
    jg near .wall
    inc dword [esp+32]
.test_queue:
    mov esi,[esp+32]
    cmp ebp,esi
    jg near .sector
    mov ebx,[esp+72]
    lea eax,[ebp-1]
    jmp .test_destination
.destination:
    cmp bx,[nosplit eax*2+queue]
    jne .previous
    mov eax,1
    jmp .done
.previous:
    dec eax
.test_destination:
    test eax,eax
    jge .destination
.blocked:
    xor eax,eax
.done:
    add esp,44
    jmp near shared_return
