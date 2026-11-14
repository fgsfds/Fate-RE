; Draw two neighboring translucent columns, with single-column fallbacks.
BITS 32
ORG 0x4abc5

tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
waloff equ 0x1ffca0
chainplace equ 0x286b4c
chainstat equ 0x14003
frameplace equ 0x286b74
row_offset equ 0x286bb0
palookup equ 0x203ca0
startdmost equ 0x1f8020
startumost equ 0x1f13a0
dwall equ 0x1a63e0
globalhoriz equ 0x286ae4
globalpal equ 0x286adc
globalpicnum equ 0x289144
globalshade equ 0x286a88
globalxpanning equ 0x286abc
globalyscale equ 0x286ab4
globalzd equ 0x286a8c
globvis equ 0x286ab8
lwall equ 0x199150
swall equ 0x1a18e0
transarea equ 0x14008
uwall equ 0x19aa60
viewoffset equ 0x286ae8
windowx1 equ 0x286b9c
windowy1 equ 0x286b94
xdimen equ 0x140b5
asm1 equ 0x286aa4
asm2 equ 0x286aa8
walock equ 0x1f8ca0
gotpic equ 0x1ecda0
projection_scale equ 0x286b00
tile_y_shift equ 0x2891d6
engine_199010 equ 0x199010
engine_289146 equ 0x289146
engine_199014 equ 0x199014
engine_199020 equ 0x199020
engine_199030 equ 0x199030
engine_199024 equ 0x199024
engine_199034 equ 0x199034
engine_199040 equ 0x199040
engine_199044 equ 0x199044
engine_286bb4 equ 0x286bb4
transmaskvline equ 0x4aa28
getpalookup equ 0x5fed7
setuptvlineasm2 equ 0x74d20
tvlineasm1 equ 0x744d0
tvlineasm2 equ 0x74d50
faketimerhandler equ 0x31ec4
transmaskvline_restore equ 0x4abbe

transmaskvline2_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x20
    mov esi, eax
    test eax, eax
    jl near .restore_stack
    mov edx, dword [xdimen]
    cmp eax, edx
    jge near .restore_stack
    lea eax, [edx - 1]
    cmp esi, eax
    jne short .branch_032

.draw_single_column:
    call transmaskvline
    jmp near .restore_stack

.branch_032:
    cmp byte [chainstat], 0
    je short .branch_040
    lea edi, [esi + 4]
    jmp short .branch_043

.branch_040:
    lea edi, [esi + 1]

.branch_043:
    mov eax, dword [windowx1]
    add eax, esi
    mov ebx, dword [windowy1]
    movsx edx, word [nosplit eax*2 + startumost]
    movsx eax, word [nosplit esi*2 + uwall]
    sub edx, ebx
    cmp eax, edx
    jg short .branch_068
    mov eax, edx

.branch_068:
    mov dword [esp + 0x14], eax
    mov eax, dword [windowx1]
    add eax, esi
    mov ecx, dword [windowy1]
    movsx eax, word [nosplit eax*2 + startdmost]
    movsx edx, word [nosplit esi*2 + dwall]
    sub eax, ecx
    cmp edx, eax
    jge short .branch_091
    mov eax, edx

.branch_091:
    dec eax
    mov edx, dword [esp + 0x14]
    mov dword [esp + 0x18], eax
    cmp ax, dx
    jge short .branch_0a3
    mov eax, edi
    jmp short .draw_single_column

.branch_0a3:
    mov eax, dword [windowx1]
    add eax, edi
    mov ebp, dword [windowy1]
    movsx edx, word [nosplit eax*2 + startumost]
    movsx eax, word [nosplit edi*2 + uwall]
    sub edx, ebp
    cmp eax, edx
    jg short .branch_0c8
    mov eax, edx

.branch_0c8:
    mov dword [esp + 0x10], eax
    mov eax, dword [windowx1]
    add eax, edi
    mov edx, dword [windowy1]
    movsx eax, word [nosplit eax*2 + startdmost]
    sub eax, edx
    movsx edx, word [nosplit edi*2 + dwall]
    cmp edx, eax
    jge short .branch_0f1
    mov eax, edx

.branch_0f1:
    dec eax
    mov ebx, dword [esp + 0x10]
    mov dword [esp + 0x1c], eax
    cmp ax, bx
    jge short .branch_106
    mov eax, esi
    jmp near .draw_single_column

.branch_106:
    mov eax, dword [globalshade]
    mov ebx, dword [globvis]
    mov dword [esp], eax
    mov eax, dword [esi*4 + swall]
    mov ecx, dword [globalpal]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, dword [esp]
    call getpalookup
    shl eax, 8
    mov edx, dword [ecx*4 + palookup]
    add eax, edx
    mov dword [engine_199010], eax
    mov eax, dword [globalpal]
    shl eax, 2
    mov dword [esp], eax
    mov eax, edi
    shl eax, 2
    mov ebx, dword [globvis]
    mov dword [esp + 4], eax
    mov eax, dword [eax + swall]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov ecx, dword [esp]
    shl eax, 8
    mov ecx, dword [ecx + palookup]
    mov ebx, dword [engine_199010]
    add ecx, eax
    movsx eax, word [engine_289146]
    mov dword [engine_199014], ecx
    call setuptvlineasm2
    mov ebx, dword [globalyscale]
    mov eax, dword [esi*4 + swall]
    imul eax, ebx
    mov edx, dword [esp + 4]
    mov edx, dword [edx + swall]
    imul edx, ebx
    mov ecx, dword [globalhoriz]
    movsx ebx, word [esp + 0x14]
    sub ebx, ecx
    inc ebx
    imul ebx, eax
    mov dword [engine_199020], eax
    mov eax, dword [globalzd]
    add ebx, eax
    mov dword [engine_199030], ebx
    movsx ebx, word [esp + 0x10]
    sub ebx, ecx
    inc ebx
    mov dword [engine_199024], edx
    imul edx, ebx
    mov ebp, dword [globalxpanning]
    movsx ebx, word [globalpicnum]
    add eax, edx
    mov edx, dword [esi*4 + lwall]
    mov dword [engine_199034], eax
    add edx, ebp
    movsx ebx, word [nosplit ebx*2 + tilesizx]
    mov ebp, edx
    cmp edx, ebx
    jl short .branch_21e
    mov eax, edx
    sar edx, 0x1f
    idiv ebx
    mov ebp, edx

.branch_21e:
    movsx edx, word [globalpicnum]
    movsx ebx, word [nosplit edx*2 + tilesizy]
    imul ebx, ebp
    mov eax, edx
    mov edx, dword [edx*4 + waloff]
    add edx, ebx
    mov ebx, dword [globalxpanning]
    mov dword [engine_199040], edx
    mov edx, dword [edi*4 + lwall]
    add edx, ebx
    movsx ebx, word [nosplit eax*2 + tilesizx]
    mov ebp, edx
    cmp edx, ebx
    jl short .branch_267
    mov eax, edx
    sar edx, 0x1f
    idiv ebx
    mov ebp, edx

.branch_267:
    movsx edx, word [globalpicnum]
    movsx eax, word [nosplit edx*2 + tilesizy]
    imul eax, ebp
    mov edx, dword [edx*4 + waloff]
    add eax, edx
    mov ecx, dword [esp + 0x10]
    mov dword [engine_199044], eax
    mov eax, dword [esp + 0x14]
    cmp ax, cx
    jg short .branch_296
    mov eax, ecx

.branch_296:
    cwde
    mov edi, dword [esp + 0x1c]
    mov dword [esp + 8], eax
    mov eax, dword [esp + 0x18]
    cmp ax, di
    jl short .branch_2aa
    mov eax, edi

.branch_2aa:
    cwde
    mov dl, byte [chainstat]
    mov dword [esp + 0xc], eax
    test dl, dl
    je short .branch_2ca
    add esi, dword [viewoffset]
    mov ebp, dword [chainplace]
    sar esi, 2
    jmp short .branch_2d8

.branch_2ca:
    mov ecx, dword [frameplace]
    mov ebp, dword [viewoffset]
    add esi, ecx

.branch_2d8:
    add ebp, esi
    mov eax, dword [esp + 0x14]
    cmp ax, word [esp + 0x10]
    je near .branch_366
    mov edx, dword [esp + 8]
    cwde
    cmp eax, edx
    jge short .branch_325
    mov ecx, dword [esp + 8]
    mov esi, dword [engine_199040]
    mov edx, dword [engine_199030]
    mov edi, dword [eax*4 + row_offset]
    mov ebx, dword [engine_199010]
    add edi, ebp
    sub ecx, eax
    mov eax, dword [engine_199020]
    dec ecx
    call tvlineasm1
    mov dword [engine_199030], eax
    jmp short .branch_366

.branch_325:
    movsx edx, word [esp + 0x10]
    mov eax, dword [esp + 8]
    mov esi, dword [engine_199044]
    mov ecx, dword [engine_199034]
    mov ebx, dword [engine_199014]
    sub eax, edx
    mov edi, dword [edx*4 + row_offset]
    dec eax
    mov edx, ecx
    add edi, ebp
    mov dword [esp + 4], eax
    inc edi
    mov ecx, dword [esp + 4]
    mov eax, dword [engine_199024]
    call tvlineasm1
    mov dword [engine_199034], eax

.branch_366:
    mov eax, dword [esp + 0xc]
    mov ebx, dword [esp + 8]
    cmp eax, ebx
    jle short .branch_3d4
    mov eax, dword [engine_199024]
    mov esi, dword [engine_199030]
    mov dword [asm1], eax
    mov eax, dword [esp + 0xc]
    mov edx, dword [engine_199044]
    mov ecx, dword [engine_199040]
    mov eax, dword [eax*4 + row_offset]
    mov edi, dword [ebx*4 + row_offset]
    add eax, ebp
    mov ebx, dword [engine_199020]
    inc eax
    add edi, ebp
    mov dword [asm2], eax
    mov eax, dword [engine_199034]
    call tvlineasm2
    mov eax, dword [esp + 0xc]
    sub eax, dword [esp + 8]
    mov esi, dword [transarea]
    add eax, eax
    add esi, eax
    mov dword [transarea], esi
    jmp short .branch_3e8

.branch_3d4:
    mov eax, dword [engine_199030]
    mov dword [asm1], eax
    mov eax, dword [engine_199034]
    mov dword [asm2], eax

.branch_3e8:
    mov eax, dword [esp + 0xc]
    mov edx, dword [esp + 0x18]
    mov ebx, dword [esp + 0x1c]
    shl eax, 2
    cmp dx, bx
    jle short .branch_429
    movsx ecx, word [esp + 0x18]
    mov esi, dword [engine_199040]
    mov edx, dword [asm1]
    mov ebx, dword [engine_199010]
    mov edi, dword [eax + engine_286bb4]
    mov eax, dword [esp + 0xc]
    add edi, ebp
    sub ecx, eax
    mov eax, dword [engine_199020]
    dec ecx
    jmp short .branch_457

.branch_429:
    jge short .run_timer
    mov esi, dword [engine_199044]
    mov edi, dword [eax + engine_286bb4]
    movsx eax, bx
    add edi, ebp
    mov ebp, dword [esp + 0xc]
    mov edx, dword [asm2]
    sub eax, ebp
    mov ebx, dword [engine_199014]
    lea ecx, [eax - 1]
    inc edi
    mov eax, dword [engine_199024]

.branch_457:
    call tvlineasm1

.run_timer:
    call faketimerhandler

.restore_stack:
    add esp, 0x20
    jmp near transmaskvline_restore
