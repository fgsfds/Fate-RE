; Initialize the room view, scan sectors, and draw wall bunches in depth order.
BITS 32
ORG 0x44796

activate_crush_numsectors equ 0x289154
totalclocklock equ 0x2863c0
frameplace equ 0x286b74
pow2char equ 0x14029
startdmost equ 0x1f8020
startumost equ 0x1f13a0
stereofps equ 0x14014
globalhoriz equ 0x286ae4
windowx1 equ 0x286b9c
windowy1 equ 0x286b94
xdimen equ 0x140b5
totalclock equ 0x287e88
sintable equ 0x2300a0
globalposx equ 0x286ad0
globalposy equ 0x286ad4
globalposz equ 0x286ad8
bunchfirst equ 0x1d7560
bunchlast equ 0x1d9560
scan_next equ 0x1d8560
scan_count equ 0x289130
bunch_count equ 0x289132
scan_wall equ 0x1c2160
remaining_columns equ 0x289134
gotsector equ 0x1ecda0
engine_14010 equ 0x14010
engine_286b98 equ 0x286b98
engine_286b90 equ 0x286b90
engine_286b00 equ 0x286b00
engine_1400c equ 0x1400c
engine_289148 equ 0x289148
engine_286af4 equ 0x286af4
engine_286b14 equ 0x286b14
engine_286acc equ 0x286acc
engine_286ba0 equ 0x286ba0
engine_286afc equ 0x286afc
engine_286aa0 equ 0x286aa0
engine_286ba8 equ 0x286ba8
engine_286bac equ 0x286bac
engine_286a9c equ 0x286a9c
engine_286a98 equ 0x286a98
engine_286a94 equ 0x286a94
engine_28914a equ 0x28914a
engine_286ac8 equ 0x286ac8
engine_286af8 equ 0x286af8
engine_286b38 equ 0x286b38
engine_286b40 equ 0x286b40
engine_286b24 equ 0x286b24
engine_13ff0 equ 0x13ff0
engine_14004 equ 0x14004
engine_1ecd20 equ 0x1ecd20
engine_19e6e0 equ 0x19e6e0
engine_1a7ce0 equ 0x1a7ce0
engine_140b1 equ 0x140b1
engine_1db560 equ 0x1db560
engine_1a31 equ 0x1a31
engine_28914c equ 0x28914c
engine_28914e equ 0x28914e
engine_287e84 equ 0x287e84
engine_1dda60 equ 0x1dda60
engine_2891d8 equ 0x2891d8
engine_1ec920 equ 0x1ec920
print_diagnostic equ 0x40bb4
runtime_exit equ 0x60353
updatesector equ 0x542c4
scansector equ 0x44bd6
bunchfront equ 0x45576
drawalls equ 0x45610
wallscan_restore equ 0x4918a
presentation_return equ 0x44764

drawrooms_:
    push esi
    push edi
    push ebp
    xor esi, esi
    mov dword [engine_14010], esi
    mov esi, dword [engine_286b98]
    mov edi, dword [windowx1]
    inc esi
    sub esi, edi
    mov edi, dword [engine_286b90]
    mov ebp, dword [windowy1]
    inc edi
    sub edi, ebp
    imul esi, edi
    mov dword [globalposx], eax
    mov dword [globalposy], edx
    mov dword [globalposz], ebx
    and ch, 7
    mov eax, dword [esp + 0x10]
    mov ebx, dword [engine_286b00]
    mov edi, dword [engine_1400c]
    mov word [engine_289148], cx
    add edi, esi
    sub eax, 0x64
    mov dword [engine_1400c], edi
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [engine_286af4]
    sar edx, 1
    add eax, edx
    mov edx, dword [engine_286b14]
    mov dword [globalhoriz], eax
    neg eax
    imul eax, edx
    mov ebp, dword [globalhoriz]
    mov edx, dword [engine_286af4]
    mov dword [engine_286acc], eax
    mov eax, dword [engine_286b14]
    sub edx, ebp
    imul edx, eax
    mov ebx, dword [engine_286b00]
    mov eax, dword [engine_286ba0]
    mov dword [engine_286afc], edx
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [engine_286b00]
    mov dword [engine_286aa0], eax
    mov eax, dword [engine_286ba8]
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, dword [engine_286bac]
    mov dword [engine_286a9c], eax
    imul ebx
    shrd eax, edx, 0x10
    mov ebx, 0x140
    mov dword [engine_286a98], eax
    imul ebx
    shrd eax, edx, 8
    mov dword [engine_286a94], eax
    mov eax, dword [esp + 0x14]
    mov word [engine_28914a], ax
    mov eax, dword [totalclock]
    mov dword [totalclocklock], eax
    movsx eax, word [engine_289148]
    add eax, 0x200
    and eax, 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    mov dword [engine_286ac8], eax
    mov ax, word [engine_289148]
    and ah, 7
    cwde
    movsx eax, word [nosplit eax*2 + sintable]
    mov dword [engine_286af8], eax
    cmp dword [stereofps], 0
    je near .branch_1f6
    cmp dword [engine_286b38], 0
    jne short .branch_19e
    mov ebx, dword [engine_286b40]
    mov eax, dword [engine_286af8]
    imul ebx
    shrd eax, edx, 0x18
    mov edi, dword [globalposx]
    mov ebx, dword [engine_286b40]
    add edi, eax
    mov eax, dword [engine_286ac8]
    mov dword [globalposx], edi
    imul ebx
    shrd eax, edx, 0x18
    mov ebp, dword [globalposy]
    sub ebp, eax
    mov eax, dword [engine_286b24]
    mov dword [globalposy], ebp
    cmp eax, 7
    jne short .branch_1f6
    mov eax, dword [engine_13ff0]
    jmp short .branch_1f1

.branch_19e:
    mov ebx, dword [engine_286b40]
    mov eax, dword [engine_286af8]
    imul ebx
    shrd eax, edx, 0x18
    mov ebx, dword [globalposx]
    sub ebx, eax
    mov eax, dword [engine_286ac8]
    mov dword [globalposx], ebx
    mov ebx, dword [engine_286b40]
    imul ebx
    shrd eax, edx, 0x18
    mov ecx, dword [globalposy]
    add ecx, eax
    mov esi, dword [engine_286b24]
    mov dword [globalposy], ecx
    cmp esi, 7
    jne short .branch_1f6
    mov eax, dword [engine_13ff0]
    add eax, 0x10000

.branch_1f1:
    mov dword [frameplace], eax

.branch_1f6:
    cmp dword [engine_14004], 0
    jle short .branch_20a
    mov eax, 2
    mov edx, 0x3c4
    out dx, al

.branch_20a:
    movsx ecx, word [activate_crush_numsectors]
    mov edi, engine_1ecd20
    add ecx, 0x1f
    xor eax, eax
    sar ecx, 5
    mov edx, startumost
    rep stosd
    mov esi, dword [windowx1]
    mov ebx, dword [xdimen]
    mov di, word [windowy1]
    add esi, esi
    dec ebx
    add edx, esi
    add esi, startdmost

.branch_243:
    mov eax, ebx
    mov cx, word [edx + eax*2]
    sub ecx, edi
    mov word [nosplit ebx*2 + engine_19e6e0], cx
    mov cx, word [esi + eax*2]
    sub ecx, edi
    mov word [nosplit ebx*2 + engine_1a7ce0], cx
    dec ebx
    jne short .branch_243
    mov ax, word [edx]
    sub eax, edi
    mov word [engine_19e6e0], ax
    mov ax, word [esi]
    sub eax, edi
    mov ebx, dword [engine_140b1]
    mov word [engine_1a7ce0], ax
    test ebx, ebx
    jge short .branch_2be
    mov ebx, engine_1db560
    xor eax, eax
    mov ecx, 0x20
    mov edx, dword [ebx + ecx*4 - 4]
    ror edx, cl
    adc eax, edx
    bswap eax
    loop 0x44a26
    cmp eax, 0x56c764d4
    je short .branch_2be
    mov eax, 3
    int 0x10
    push engine_1a31
    call print_diagnostic
    add esp, 4
    xor eax, eax
    call runtime_exit

.branch_2be:
    mov ebx, engine_28914a
    mov ax, word [xdimen]
    mov edx, dword [globalposy]
    xor ecx, ecx
    mov word [remaining_columns], ax
    mov word [scan_count], cx
    mov word [bunch_count], cx
    mov word [engine_28914c], cx
    xor ecx, ecx
    xor eax, eax
    mov dword [engine_140b1], ecx
    mov word [engine_28914e], ax
    mov eax, dword [globalposx]
    mov dword [engine_287e84], ecx
    call updatesector
    movsx eax, word [engine_28914a]
    call scansector

.branch_318:
    mov dx, word [bunch_count]
    test dx, dx
    jle near wallscan_restore
    cmp word [remaining_columns], 0
    jle near wallscan_restore
    movsx ecx, dx
    mov edi, engine_1dda60
    add ecx, 3
    xor eax, eax
    sar ecx, 2
    mov ebx, 1
    rep stosd
    mov ah, 1
    xor ecx, ecx
    mov byte [engine_1dda60], ah
    jmp short .branch_379

.branch_359:
    mov edx, ecx
    mov eax, ebx
    call bunchfront
    test eax, eax
    jl short .branch_378
    mov dl, 1
    mov byte [ebx + engine_1dda60], dl
    jne short .branch_378
    mov byte [ecx + engine_1dda60], dl
    mov ecx, ebx

.branch_378:
    inc ebx

.branch_379:
    movsx eax, word [bunch_count]
    cmp ebx, eax
    jl short .branch_359
    xor ebx, ebx
    jmp short .branch_3b3

.branch_388:
    cmp byte [ebx + engine_1dda60], 0
    jne short .branch_3b2
    mov edx, ecx
    mov eax, ebx
    call bunchfront
    test eax, eax
    jl short .branch_3b2
    mov dl, 1
    mov byte [ebx + engine_1dda60], dl
    jne short .branch_3b2
    mov byte [ecx + engine_1dda60], dl
    mov ecx, ebx
    xor ebx, ebx

.branch_3b2:
    inc ebx

.branch_3b3:
    movsx eax, word [bunch_count]
    cmp ebx, eax
    jl short .branch_388
    mov eax, ecx
    call drawalls
    cmp byte [engine_2891d8], 0
    je short .branch_409
    movsx eax, word [nosplit ecx*2 + bunchfirst]
    jmp short .branch_405

.branch_3d8:
    lea ebx, [eax + eax]
    mov si, word [ebx + scan_wall]
    and esi, 7
    movsx eax, word [ebx + scan_wall]
    movsx esi, si
    sar eax, 3
    mov dl, byte [esi + pow2char]
    or byte [eax + engine_1ec920], dl
    movsx eax, word [ebx + scan_next]

.branch_405:
    test eax, eax
    jge short .branch_3d8

.branch_409:
    mov si, word [bunch_count]
    dec esi
    movsx eax, si
    mov word [bunch_count], si
    mov bx, word [nosplit eax*2 + bunchfirst]
    mov ax, word [nosplit eax*2 + bunchlast]
    mov word [nosplit ecx*2 + bunchfirst], bx
    mov word [nosplit ecx*2 + bunchlast], ax
    jmp near .branch_318
