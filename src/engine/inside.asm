; FATE point-in-sector leaf, object 1+0x3c88f. EAX=x, EDX=y, BX=sector.
; Invalid sectors return -1; valid sectors return crossing parity (0 or 1).
; Sector records are 40 bytes; wall records are 32 bytes.
; Define ENGINE_DATA_BASE=0x80000 to assemble loaded pointers for emulator checks.
BITS 32
%ifndef ENGINE_DATA_BASE
%define ENGINE_DATA_BASE 0
%endif
numsectors equ ENGINE_DATA_BASE + 0x289154
sector equ ENGINE_DATA_BASE + 0x27c3a0
wall equ ENGINE_DATA_BASE + 0x2310a0

inside_:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 4
    push eax
    push edx
    mov eax, ebx
    test bx, bx
    jl .invalid
    cmp bx, [numsectors]
    jl .sector
.invalid:
    mov edx, -1
    jmp near .return
.sector:
    movsx edx, ax
    mov eax, edx
    shl eax, 2
    add edx, eax
    shl edx, 3                  ; sector index * 40
    movsx eax, word [edx+sector]
    xor bl, bl                  ; crossing parity
    shl eax, 5
    movsx edx, word [edx+sector+2]
    add eax, wall
    mov [esp+8], edx            ; walls remaining
.edge:
    mov edx, [esp]
    mov ecx, [eax+4]
    sub ecx, edx                ; first y relative to query
    movsx edx, word [eax+8]     ; point2
    shl edx, 5
    mov edi, [esp]
    mov esi, [edx+wall+4]
    sub esi, edi                ; second relative y
    mov edi, ecx
    xor edi, esi
    test edi, edi
    jge .next                   ; no crossing of horizontal query line
    mov ebp, [esp+4]
    mov edi, [eax]
    mov edx, [edx+wall]
    sub edi, ebp
    sub edx, ebp
    mov ebp, edi
    xor ebp, edx
    test ebp, ebp
    jge .same_side
    imul edi, esi
    imul edx, ecx
    cmp edi, edx
    setl dl
    cmp ecx, esi
    setl dh
    xor dl, dh
    xor bl, dl
    jmp short .next
.same_side:
    test edi, edi
    jl .next
    xor bl, 1
.next:
    mov edx, [esp+8]
    add eax, 32
    dec edx
    mov [esp+8], edx
    jne .edge
    mov dl, bl
.return:
    mov eax, edx
    add esp, 12
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
