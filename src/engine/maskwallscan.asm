; Render clipped wall columns with transparent texels.
BITS 32
ORG 0x49190

picsiz equ 0x1e5fe0
pow2long equ 0x14031
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
chainplace equ 0x286b4c
chainstat equ 0x14003
frameplace equ 0x286b74
row_offset equ 0x286bb0
palookup equ 0x203ca0
pow2char equ 0x14029
startdmost equ 0x1f8020
startumost equ 0x1f13a0
globalhoriz equ 0x286ae4
globalpal equ 0x286adc
globalpicnum equ 0x289144
globalshade equ 0x286a88
globalxpanning equ 0x286abc
globalyscale equ 0x286ab4
globalzd equ 0x286a8c
globvis equ 0x286ab8
viewoffset equ 0x286ae8
windowx1 equ 0x286b9c
windowy1 equ 0x286b94
gotpic equ 0x1ecda0
projection_scale equ 0x286b00
tile_y_shift equ 0x2891d6
engine_286af4 equ 0x286af4
engine_289146 equ 0x289146
engine_199010 equ 0x199010
engine_199040 equ 0x199040
engine_199020 equ 0x199020
engine_199030 equ 0x199030
engine_19901c equ 0x19901c
engine_199014 equ 0x199014
engine_199018 equ 0x199018
engine_199044 equ 0x199044
engine_199034 equ 0x199034
engine_199024 equ 0x199024
engine_199048 equ 0x199048
engine_199038 equ 0x199038
engine_199028 equ 0x199028
engine_19904c equ 0x19904c
engine_19903c equ 0x19903c
engine_19902c equ 0x19902c
engine_286bb4 equ 0x286bb4
loadtile equ 0x4bb0d
setupmvlineasm equ 0x742f0
getpalookup equ 0x5fed7
mvlineasm1 equ 0x74370
mvlineasm4 equ 0x74660
wallscan_timer_tail equ 0x49182
wallscan_return equ 0x49187

maskwallscan_:
    push esi
    push edi
    push ebp
    sub esp, 0x64
    mov esi, eax
    mov dword [esp + 0x28], edx
    mov dword [esp + 0x3c], ebx
    mov dword [esp + 0x40], ecx
    movsx eax, word [globalpicnum]
    movsx edx, word [nosplit eax*2 + tilesizx]
    movsx eax, word [nosplit eax*2 + tilesizy]
    mov dword [esp + 0x4c], eax
    mov ax, word [globalpicnum]
    cwde
    mov dword [esp + 0x54], edx
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_04c
    mov byte [eax + walock], 0xc7

.branch_04c:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + gotpic]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + gotpic], dl
    cmp dword [esp + 0x54], 0
    jle short wallscan_return
    cmp dword [esp + 0x4c], 0
    jle short wallscan_return
    mov eax, esi
    mov ecx, dword [esp + 0x3c]
    add eax, eax
    add eax, ecx
    mov edi, dword [engine_286af4]
    movsx eax, word [eax]
    cmp eax, edi
    jle short .branch_09e
    mov eax, dword [esp + 0x28]
    add eax, eax
    add eax, ecx
    movsx eax, word [eax]
    cmp eax, edi
    jg near wallscan_return

.branch_09e:
    mov ebx, dword [esp + 0x40]
    lea eax, [esi + esi]
    add eax, ebx
    cmp word [eax], 0
    jge short .branch_0bf
    mov eax, dword [esp + 0x28]
    add eax, eax
    add eax, ebx
    cmp word [eax], 0
    jl near wallscan_return

.branch_0bf:
    movsx eax, word [globalpicnum]
    cmp dword [eax*4 + waloff], 0
    jne short .branch_0d5
    call loadtile

.branch_0d5:
    cmp byte [chainstat], 0
    je short .branch_138
    mov eax, dword [viewoffset]
    add eax, esi
    and eax, 3
    mov edx, 4
    mov al, byte [eax + pow2char]
    mov ebx, 0xc
    mov byte [esp + 0x58], al
    mov byte [esp + 0x5c], al
    mov eax, dword [esp + 0x28]
    mov dword [esp + 0x44], edx
    sub eax, esi
    mov dword [esp + 0x24], ebx
    cmp eax, edx
    jge short .branch_12a
    mov eax, dword [esp + 0x28]
    add eax, dword [viewoffset]
    inc eax
    and eax, 3
    mov al, byte [eax + pow2char]
    mov byte [esp + 0x5c], al

.branch_12a:
    xor eax, eax
    mov edx, 0x3c5
    mov al, byte [esp + 0x58]
    out dx, al
    jmp short .branch_14a

.branch_138:
    mov ebp, 1
    mov eax, 3
    mov dword [esp + 0x44], ebp
    mov dword [esp + 0x24], eax

.branch_14a:
    movsx eax, word [globalpicnum]
    mov al, byte [eax + picsiz]
    mov dword [esp + 0x20], esi
    and al, 0xf
    and eax, 0xff
    mov esi, dword [esp + 0x54]
    mov eax, dword [eax*4 + pow2long]
    cmp eax, esi
    sete al
    and eax, 0xff
    mov dword [esp + 0x38], eax
    je short .branch_184
    lea edi, [esi - 1]
    mov dword [esp + 0x54], edi

.branch_184:
    movsx eax, word [globalpicnum]
    mov al, byte [eax + picsiz]
    and eax, 0xff
    sar eax, 4
    mov ebp, dword [esp + 0x4c]
    mov eax, dword [eax*4 + pow2long]
    cmp eax, ebp
    sete al
    and eax, 0xff
    mov dword [esp + 0x34], eax
    je short .branch_1cd
    movsx eax, word [globalpicnum]
    mov al, byte [eax + picsiz]
    and eax, 0xff
    sar eax, 4
    mov dword [esp + 0x4c], eax

.branch_1cd:
    mov eax, dword [globalpal]
    mov eax, dword [eax*4 + palookup]
    mov dword [esp + 0x2c], eax
    movsx eax, word [engine_289146]
    call setupmvlineasm

.branch_1e9:
    mov eax, dword [esp + 0x20]
    mov ebx, dword [esp + 0x28]
    mov dword [esp + 0x50], eax

.branch_1f5:
    mov eax, dword [esp + 0x50]
    add eax, dword [windowx1]
    mov dx, word [nosplit eax*2 + startumost]
    cmp dx, word [nosplit eax*2 + startdmost]
    jle short .branch_221
    cmp ebx, dword [esp + 0x50]
    jl short .branch_221
    mov eax, dword [esp + 0x44]
    add dword [esp + 0x50], eax
    jmp short .branch_1f5

.branch_221:
    cmp byte [chainstat], 0
    je short .branch_248
    mov eax, dword [esp + 0x50]
    add eax, dword [viewoffset]
    mov edx, dword [chainplace]
    sar eax, 2

.branch_23d:
    add edx, eax
    mov dword [esp + 0x48], edx
    jmp near .branch_3fc

.branch_248:
    mov eax, dword [esp + 0x50]
    mov ecx, dword [frameplace]
    mov edx, dword [viewoffset]
    add eax, ecx
    jmp short .branch_23d

.branch_25c:
    mov edx, dword [windowx1]
    mov ecx, dword [esp + 0x3c]
    add eax, edx
    mov edx, dword [esp + 0x50]
    mov ebx, dword [windowy1]
    add edx, edx
    movsx eax, word [nosplit eax*2 + startumost]
    add edx, ecx
    sub eax, ebx
    movsx edx, word [edx]
    cmp edx, eax
    jle short .branch_289
    mov eax, edx

.branch_289:
    mov esi, dword [windowx1]
    mov dword [esp], eax
    mov eax, dword [esp + 0x50]
    add eax, esi
    movsx edx, word [nosplit eax*2 + startdmost]
    mov eax, dword [esp + 0x50]
    mov ebp, dword [esp + 0x40]
    add eax, eax
    mov edi, dword [windowy1]
    add eax, ebp
    sub edx, edi
    movsx eax, word [eax]
    cmp eax, edx
    jl short .branch_2bd
    mov eax, edx

.branch_2bd:
    mov edx, dword [esp]
    mov dword [esp + 0x10], eax
    cmp eax, edx
    jle near .branch_3e5
    mov esi, dword [esp + 0x50]
    mov eax, dword [esp + 0x74]
    shl esi, 2
    mov ebx, dword [globvis]
    mov eax, dword [esi + eax]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    mov ebx, dword [esp + 0x78]
    add edx, eax
    add esi, ebx
    mov dword [engine_199010], edx
    mov ecx, dword [globalxpanning]
    mov eax, dword [esi]
    add eax, ecx
    mov esi, dword [esp + 0x54]
    mov dword [engine_199040], eax
    cmp eax, esi
    jl short .branch_33f
    cmp dword [esp + 0x38], 0
    jne short .branch_335
    mov edx, eax
    sar edx, 0x1f
    idiv esi
    mov dword [engine_199040], edx
    jmp short .branch_33f

.branch_335:
    mov ebp, eax
    and ebp, esi
    mov dword [engine_199040], ebp

.branch_33f:
    cmp dword [esp + 0x34], 0
    jne short .branch_359
    mov edi, dword [esp + 0x4c]
    mov eax, dword [engine_199040]
    imul eax, edi
    mov dword [engine_199040], eax
    jmp short .branch_363

.branch_359:
    mov cl, byte [esp + 0x4c]
    shl dword [engine_199040], cl

.branch_363:
    mov eax, dword [esp + 0x50]
    mov ebp, dword [esp + 0x74]
    shl eax, 2
    add eax, ebp
    mov edx, dword [globalyscale]
    mov eax, dword [eax]
    imul eax, edx
    mov ebx, dword [globalhoriz]
    mov dword [engine_199020], eax
    mov eax, dword [esp]
    sub eax, ebx
    mov ecx, dword [engine_199020]
    inc eax
    imul eax, ecx
    mov edi, dword [esp + 0x48]
    mov edx, dword [globalzd]
    mov ebx, dword [engine_199010]
    mov ecx, dword [esp + 0x10]
    add eax, edx
    movsx edx, word [globalpicnum]
    mov dword [engine_199030], eax
    mov eax, dword [esp]
    mov ebp, dword [edx*4 + waloff]
    mov edx, dword [engine_199030]
    mov esi, dword [eax*4 + row_offset]
    sub ecx, eax
    mov eax, dword [engine_199020]
    add edi, esi
    mov esi, dword [engine_199040]
    dec ecx
    add esi, ebp
    call mvlineasm1

.branch_3e5:
    mov eax, dword [esp + 0x44]
    mov edx, dword [esp + 0x50]
    mov ebx, dword [esp + 0x48]
    add edx, eax
    inc ebx
    mov dword [esp + 0x50], edx
    mov dword [esp + 0x48], ebx

.branch_3fc:
    mov eax, dword [esp + 0x50]
    cmp eax, dword [esp + 0x28]
    jg near .branch_a28
    test byte [esp + 0x50], 3
    jne near .branch_25c
    jmp near .branch_a28

.branch_41a:
    xor bl, bl
    mov edi, 3
    mov byte [esp + 0x60], bl
    lea ebx, [esi + ecx]
    jmp near .branch_54f

.branch_42d:
    mov eax, dword [windowx1]
    add eax, ebx
    movsx ebp, word [nosplit eax*2 + startumost]
    mov eax, dword [windowy1]
    mov edx, dword [esp + 0x3c]
    sub ebp, eax
    lea eax, [ebx + ebx]
    add eax, edx
    movsx eax, word [eax]
    cmp eax, ebp
    jg short .branch_455
    mov eax, ebp

.branch_455:
    mov dword [esp + edi*4], eax
    mov eax, dword [windowx1]
    add eax, ebx
    mov esi, dword [esp + 0x40]
    movsx ebp, word [nosplit eax*2 + startdmost]
    lea eax, [ebx + ebx]
    mov ecx, dword [windowy1]
    add eax, esi
    sub ebp, ecx
    movsx eax, word [eax]
    cmp eax, ebp
    jge short .branch_481
    mov ebp, eax

.branch_481:
    dec ebp
    mov edx, dword [esp + edi*4]
    mov dword [esp + edi*4 + 0x10], ebp
    cmp ebp, edx
    jge short .branch_4a2
    mov dh, byte [esp + 0x60]
    mov al, byte [edi + pow2char]
    add dh, al
    mov byte [esp + 0x60], dh
    jmp near .branch_548

.branch_4a2:
    mov ebp, ebx
    mov ecx, dword [esp + 0x78]
    shl ebp, 2
    add ebp, ecx
    mov esi, dword [globalxpanning]
    mov ebp, dword [ebp]
    mov eax, dword [esp + 0x54]
    add ebp, esi
    cmp ebp, eax
    jl short .branch_4da
    cmp dword [esp + 0x38], 0
    jne short .branch_4d8
    mov esi, dword [esp + 0x54]
    mov edx, ebp
    mov eax, ebp
    sar edx, 0x1f
    idiv esi
    mov ebp, edx
    jmp short .branch_4da

.branch_4d8:
    and ebp, eax

.branch_4da:
    cmp dword [esp + 0x34], 0
    jne short .branch_4e8
    imul ebp, dword [esp + 0x4c]
    jmp short .branch_4ee

.branch_4e8:
    mov cl, byte [esp + 0x4c]
    shl ebp, cl

.branch_4ee:
    movsx eax, word [globalpicnum]
    mov ecx, dword [eax*4 + waloff]
    add ebp, ecx
    mov dword [edi*4 + engine_199040], ebp
    mov ebp, ebx
    mov esi, dword [esp + 0x74]
    shl ebp, 2
    add ebp, esi
    mov edx, dword [globalyscale]
    mov ebp, dword [ebp]
    imul ebp, edx
    mov ecx, dword [globalhoriz]
    mov dword [edi*4 + engine_199020], ebp
    mov ebp, dword [esp + edi*4]
    sub ebp, ecx
    mov esi, dword [edi*4 + engine_199020]
    inc ebp
    imul ebp, esi
    mov edx, dword [globalzd]
    add ebp, edx
    mov dword [edi*4 + engine_199030], ebp

.branch_548:
    mov ecx, dword [esp + 0x44]
    dec edi
    sub ebx, ecx

.branch_54f:
    test edi, edi
    jge near .branch_42d
    xor eax, eax
    mov al, byte [esp + 0x60]
    cmp eax, 0xf
    je near .branch_a0c
    mov eax, dword [esp + 0x50]
    mov esi, dword [esp + 0x74]
    shl eax, 2
    add eax, esi
    mov ebx, dword [globvis]
    mov eax, dword [eax]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    mov edi, dword [esp + 0x24]
    add edx, eax
    mov eax, dword [esp + 0x50]
    add eax, edi
    shl eax, 2
    add eax, esi
    mov dword [engine_199010], edx
    mov ebx, dword [globvis]
    mov eax, dword [eax]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    add edx, eax
    mov eax, dword [engine_199010]
    mov dword [engine_19901c], edx
    cmp eax, edx
    jne short .branch_5fd
    mov al, byte [esp + 0x60]
    and al, 9
    and eax, 0xff
    jne short .branch_5fd
    mov eax, dword [engine_199010]
    mov dword [engine_199014], eax
    mov dword [engine_199018], eax
    jmp short .branch_672

.branch_5fd:
    mov eax, dword [esp + 0x50]
    mov esi, dword [esp + 0x44]
    add eax, esi
    mov edi, dword [esp + 0x74]
    shl eax, 2
    add eax, edi
    mov ebx, dword [globvis]
    mov eax, dword [eax]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    mov ebp, dword [esp + 0x50]
    add edx, eax
    lea eax, [esi + esi]
    add eax, ebp
    shl eax, 2
    add eax, edi
    mov dword [engine_199014], edx
    mov ebx, dword [globvis]
    mov eax, dword [eax]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    add edx, eax
    mov dword [engine_199018], edx

.branch_672:
    mov eax, dword [esp + 8]
    mov ebx, dword [esp + 0xc]
    cmp eax, ebx
    jle short .branch_682
    mov edx, eax
    jmp short .branch_684

.branch_682:
    mov edx, ebx

.branch_684:
    mov eax, dword [esp]
    mov ecx, dword [esp + 4]
    cmp eax, ecx
    jg short .branch_691
    mov eax, ecx

.branch_691:
    cmp eax, edx
    jle short .branch_6a4
    mov eax, dword [esp]
    mov edi, dword [esp + 4]
    cmp eax, edi
    jg short .branch_6b2
    mov eax, edi
    jmp short .branch_6b2

.branch_6a4:
    mov eax, dword [esp + 8]
    mov esi, dword [esp + 0xc]
    cmp eax, esi
    jg short .branch_6b2
    mov eax, esi

.branch_6b2:
    mov edx, dword [esp + 0x1c]
    mov ebp, eax
    mov eax, dword [esp + 0x18]
    cmp eax, edx
    jge short .branch_6c2
    mov edx, eax

.branch_6c2:
    mov eax, dword [esp + 0x10]
    mov ebx, dword [esp + 0x14]
    cmp eax, ebx
    jl short .branch_6d0
    mov eax, ebx

.branch_6d0:
    cmp eax, edx
    jge short .branch_6e4
    mov eax, dword [esp + 0x10]
    mov esi, dword [esp + 0x14]
    cmp eax, esi
    jl short .branch_6f2
    mov eax, esi
    jmp short .branch_6f2

.branch_6e4:
    mov eax, dword [esp + 0x18]
    mov ecx, dword [esp + 0x1c]
    cmp eax, ecx
    jl short .branch_6f2
    mov eax, ecx

.branch_6f2:
    mov dl, byte [esp + 0x60]
    mov dword [esp + 0x30], eax
    test dl, dl
    ja short .branch_706
    cmp ebp, eax
    jl near .branch_818

.branch_706:
    mov al, byte [esp + 0x60]
    and al, 1
    and eax, 0xff
    jne short .branch_745
    mov eax, dword [esp]
    mov ecx, dword [esp + 0x48]
    mov esi, dword [engine_199040]
    mov edi, dword [eax*4 + row_offset]
    mov edx, dword [engine_199030]
    add edi, ecx
    mov ecx, dword [esp + 0x10]
    mov ebx, dword [engine_199010]
    sub ecx, eax
    mov eax, dword [engine_199020]
    call mvlineasm1

.branch_745:
    mov al, byte [esp + 0x60]
    and al, 2
    and eax, 0xff
    jne short .branch_78a
    mov eax, dword [esp + 4]
    mov ecx, dword [esp + 0x14]
    mov ebx, dword [esp + 4]
    mov esi, dword [engine_199044]
    mov edx, dword [engine_199034]
    mov edi, dword [eax*4 + row_offset]
    sub ecx, ebx
    mov eax, dword [esp + 0x48]
    mov ebx, dword [engine_199014]
    add edi, eax
    mov eax, dword [engine_199024]
    inc edi
    call mvlineasm1

.branch_78a:
    mov al, byte [esp + 0x60]
    and al, 4
    and eax, 0xff
    jne short .branch_7cd
    mov eax, dword [esp + 8]
    mov ecx, dword [esp + 0x48]
    mov esi, dword [engine_199048]
    mov edx, dword [engine_199038]
    mov edi, dword [eax*4 + row_offset]
    mov ebx, dword [engine_199018]
    add edi, ecx
    mov ecx, dword [esp + 0x18]
    add edi, 2
    sub ecx, eax
    mov eax, dword [engine_199028]
    call mvlineasm1

.branch_7cd:
    mov al, byte [esp + 0x60]
    and al, 8
    and eax, 0xff
    jne near .branch_a0c
    mov eax, dword [esp + 0xc]
    mov ecx, dword [esp + 0x1c]
    mov ebx, dword [esp + 0xc]
    mov esi, dword [engine_19904c]
    mov edx, dword [engine_19903c]
    mov edi, dword [eax*4 + row_offset]
    sub ecx, ebx
    mov eax, dword [esp + 0x48]
    mov ebx, dword [engine_19901c]
    add edi, eax
    mov eax, dword [engine_19902c]
    add edi, 3
    jmp near .branch_a07

.branch_818:
    mov edi, dword [esp]
    cmp ebp, edi
    jle short .branch_855
    mov eax, dword [esp + 0x48]
    mov ebx, dword [esp]
    mov esi, dword [engine_199040]
    mov edx, dword [engine_199030]
    mov edi, dword [edi*4 + row_offset]
    mov ecx, ebp
    add edi, eax
    sub ecx, ebx
    mov ebx, dword [engine_199010]
    mov eax, dword [engine_199020]
    dec ecx
    call mvlineasm1
    mov dword [engine_199030], eax

.branch_855:
    mov ecx, dword [esp + 4]
    cmp ebp, ecx
    jle short .branch_893
    mov esi, dword [esp + 0x48]
    mov edx, dword [engine_199034]
    mov ebx, dword [engine_199014]
    mov eax, ecx
    mov edi, dword [ecx*4 + row_offset]
    mov ecx, ebp
    add edi, esi
    mov esi, dword [engine_199044]
    inc edi
    sub ecx, eax
    mov eax, dword [engine_199024]
    dec ecx
    call mvlineasm1
    mov dword [engine_199034], eax

.branch_893:
    mov edx, dword [esp + 8]
    cmp ebp, edx
    jle short .branch_8d3
    mov ebx, dword [esp + 0x48]
    mov esi, dword [engine_199048]
    mov eax, edx
    mov ecx, ebp
    mov edi, dword [edx*4 + row_offset]
    mov edx, dword [engine_199038]
    add edi, ebx
    sub ecx, eax
    mov ebx, dword [engine_199018]
    mov eax, dword [engine_199028]
    add edi, 2
    dec ecx
    call mvlineasm1
    mov dword [engine_199038], eax

.branch_8d3:
    mov edx, dword [esp + 0xc]
    cmp ebp, edx
    jle short .branch_913
    mov ebx, dword [esp + 0x48]
    mov esi, dword [engine_19904c]
    mov eax, edx
    mov ecx, ebp
    mov edi, dword [edx*4 + row_offset]
    mov edx, dword [engine_19903c]
    add edi, ebx
    sub ecx, eax
    mov ebx, dword [engine_19901c]
    mov eax, dword [engine_19902c]
    add edi, 3
    dec ecx
    call mvlineasm1
    mov dword [engine_19903c], eax

.branch_913:
    mov edx, dword [esp + 0x30]
    cmp ebp, edx
    jg short .branch_932
    mov ebx, dword [esp + 0x48]
    mov ecx, edx
    mov edi, dword [ebp*4 + row_offset]
    sub ecx, ebp
    add edi, ebx
    inc ecx
    call mvlineasm4

.branch_932:
    mov eax, dword [esp + 0x30]
    mov ebp, dword [esp + 0x48]
    mov esi, dword [esp + 0x30]
    mov ecx, dword [eax*4 + engine_286bb4]
    mov eax, dword [esp + 0x10]
    add ebp, ecx
    cmp eax, esi
    jle short .branch_976
    mov edi, dword [esp + 0x30]
    mov esi, dword [engine_199040]
    mov edx, dword [engine_199030]
    mov ecx, eax
    mov ebx, dword [engine_199010]
    sub ecx, edi
    mov eax, dword [engine_199020]
    dec ecx
    mov edi, ebp
    call mvlineasm1

.branch_976:
    mov eax, dword [esp + 0x14]
    cmp eax, dword [esp + 0x30]
    jle short .branch_9a8
    mov ebx, dword [esp + 0x30]
    mov esi, dword [engine_199044]
    mov edx, dword [engine_199034]
    lea edi, [ebp + 1]
    mov ecx, eax
    mov eax, dword [engine_199024]
    sub ecx, ebx
    mov ebx, dword [engine_199014]
    dec ecx
    call mvlineasm1

.branch_9a8:
    mov eax, dword [esp + 0x18]
    cmp eax, dword [esp + 0x30]
    jle short .branch_9da
    mov esi, dword [engine_199048]
    mov edx, dword [engine_199038]
    mov ebx, dword [engine_199018]
    mov ecx, eax
    mov eax, dword [esp + 0x30]
    lea edi, [ebp + 2]
    sub ecx, eax
    mov eax, dword [engine_199028]
    dec ecx
    call mvlineasm1

.branch_9da:
    mov eax, dword [esp + 0x1c]
    cmp eax, dword [esp + 0x30]
    jle short .branch_a0c
    mov ebx, dword [esp + 0x30]
    mov esi, dword [engine_19904c]
    mov edx, dword [engine_19903c]
    lea edi, [ebp + 3]
    mov ecx, eax
    mov eax, dword [engine_19902c]
    sub ecx, ebx
    mov ebx, dword [engine_19901c]
    dec ecx

.branch_a07:
    call mvlineasm1

.branch_a0c:
    mov eax, dword [esp + 0x44]
    mov ecx, dword [esp + 0x50]
    mov esi, dword [esp + 0x48]
    shl eax, 2
    add esi, 4
    add ecx, eax
    mov dword [esp + 0x48], esi
    mov dword [esp + 0x50], ecx

.branch_a28:
    mov eax, dword [esp + 0x28]
    mov ecx, dword [esp + 0x24]
    mov esi, dword [esp + 0x50]
    sub eax, ecx
    cmp eax, esi
    jge near .branch_41a
    jmp near .branch_bdf

.branch_a43:
    add eax, dword [windowx1]
    movsx edx, word [nosplit eax*2 + startumost]
    mov eax, dword [esp + 0x50]
    mov ebp, dword [esp + 0x3c]
    add eax, eax
    mov edi, dword [windowy1]
    add eax, ebp
    sub edx, edi
    movsx eax, word [eax]
    cmp eax, edx
    jg short .branch_a6e
    mov eax, edx

.branch_a6e:
    mov edx, dword [windowx1]
    mov dword [esp], eax
    mov eax, dword [esp + 0x50]
    add eax, edx
    movsx edx, word [nosplit eax*2 + startdmost]
    mov eax, dword [esp + 0x50]
    mov ecx, dword [esp + 0x40]
    add eax, eax
    mov ebx, dword [windowy1]
    add eax, ecx
    sub edx, ebx
    movsx eax, word [eax]
    cmp eax, edx
    jl short .branch_aa2
    mov eax, edx

.branch_aa2:
    mov esi, dword [esp]
    mov dword [esp + 0x10], eax
    cmp eax, esi
    jle near .branch_bc8
    mov ecx, dword [esp + 0x50]
    mov eax, dword [esp + 0x74]
    mov ebx, dword [globvis]
    mov eax, dword [eax + ecx*4]
    mov esi, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, esi
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    add edx, eax
    mov eax, dword [esp + 0x78]
    mov dword [engine_199010], edx
    mov edi, dword [globalxpanning]
    mov eax, dword [eax + ecx*4]
    add eax, edi
    mov ebp, dword [esp + 0x54]
    mov dword [engine_199040], eax
    cmp eax, ebp
    jl short .branch_b21
    cmp dword [esp + 0x38], 0
    jne short .branch_b1b
    mov eax, dword [engine_199040]
    mov edx, eax
    sar edx, 0x1f
    idiv ebp
    mov dword [engine_199040], edx
    jmp short .branch_b21

.branch_b1b:
    and dword [engine_199040], ebp

.branch_b21:
    cmp dword [esp + 0x34], 0
    jne short .branch_b3b
    mov edi, dword [esp + 0x4c]
    mov eax, dword [engine_199040]
    imul eax, edi
    mov dword [engine_199040], eax
    jmp short .branch_b45

.branch_b3b:
    mov cl, byte [esp + 0x4c]
    shl dword [engine_199040], cl

.branch_b45:
    mov eax, dword [esp + 0x50]
    mov ebp, dword [esp + 0x74]
    shl eax, 2
    add eax, ebp
    mov edx, dword [globalyscale]
    mov eax, dword [eax]
    imul eax, edx
    mov ebx, dword [globalhoriz]
    mov dword [engine_199020], eax
    mov eax, dword [esp]
    sub eax, ebx
    mov edx, dword [engine_199020]
    inc eax
    imul edx, eax
    mov edi, dword [esp + 0x48]
    mov ebp, dword [esp]
    mov eax, dword [globalzd]
    movsx ebx, word [globalpicnum]
    add eax, edx
    mov esi, dword [ebx*4 + waloff]
    mov dword [engine_199030], eax
    mov eax, dword [esp]
    mov ebx, dword [engine_199010]
    mov edx, dword [engine_199030]
    mov ecx, dword [eax*4 + row_offset]
    mov eax, dword [engine_199040]
    add edi, ecx
    mov ecx, dword [esp + 0x10]
    add esi, eax
    sub ecx, ebp
    mov eax, dword [engine_199020]
    dec ecx
    call mvlineasm1

.branch_bc8:
    mov eax, dword [esp + 0x44]
    mov edx, dword [esp + 0x50]
    mov ebx, dword [esp + 0x48]
    add edx, eax
    inc ebx
    mov dword [esp + 0x50], edx
    mov dword [esp + 0x48], ebx

.branch_bdf:
    mov eax, dword [esp + 0x50]
    cmp eax, dword [esp + 0x28]
    jle near .branch_a43
    cmp byte [chainstat], 0
    je short .branch_c23
    mov cl, byte [esp + 0x58]
    xor eax, eax
    add cl, cl
    mov al, cl
    mov byte [esp + 0x58], cl
    cmp eax, 0x10
    jne short .branch_c0e
    mov byte [esp + 0x58], 1

.branch_c0e:
    mov edx, 0x3c5
    xor eax, eax
    mov ebx, dword [esp + 0x20]
    mov al, byte [esp + 0x58]
    inc ebx
    out dx, al
    mov dword [esp + 0x20], ebx

.branch_c23:
    cmp dword [esp + 0x44], 4
    jne near wallscan_timer_tail
    mov al, byte [esp + 0x58]
    cmp al, byte [esp + 0x5c]
    jne near .branch_1e9
    jmp near wallscan_timer_tail
