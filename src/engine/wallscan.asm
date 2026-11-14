; Render clipped, textured columns for an opaque wall span.
BITS 32
ORG 0x48586

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
globalhoriz equ 0x286ae4
globalpal equ 0x286adc
globalpicnum equ 0x289144
globalshade equ 0x286a88
globalxpanning equ 0x286abc
globalyscale equ 0x286ab4
globalzd equ 0x286a8c
globvis equ 0x286ab8
viewoffset equ 0x286ae8
gotpic equ 0x1ecda0
projection_scale equ 0x286b00
tile_y_shift equ 0x2891d6
engine_286af4 equ 0x286af4
engine_289146 equ 0x289146
engine_19e6e0 equ 0x19e6e0
engine_1a7ce0 equ 0x1a7ce0
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
setupvlineasm equ 0x742d0
getpalookup equ 0x5fed7
vlineasm1 equ 0x74340
prevlineasm1 equ 0x74320
vlineasm4 equ 0x74510
faketimerhandler equ 0x31ec4

wallscan_:
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
    jle near .branch_c01
    cmp dword [esp + 0x4c], 0
    jle near .branch_c01
    mov eax, esi
    mov ecx, dword [esp + 0x3c]
    add eax, eax
    add eax, ecx
    mov edi, dword [engine_286af4]
    movsx eax, word [eax]
    cmp eax, edi
    jle short .branch_0a6
    mov eax, dword [esp + 0x28]
    add eax, eax
    add eax, ecx
    movsx eax, word [eax]
    cmp eax, edi
    jg near .branch_c01

.branch_0a6:
    mov ebx, dword [esp + 0x40]
    lea eax, [esi + esi]
    add eax, ebx
    cmp word [eax], 0
    jge short .branch_0c7
    mov eax, dword [esp + 0x28]
    add eax, eax
    add eax, ebx
    cmp word [eax], 0
    jl near .branch_c01

.branch_0c7:
    movsx eax, word [globalpicnum]
    cmp dword [eax*4 + waloff], 0
    jne short .branch_0dd
    call loadtile

.branch_0dd:
    cmp byte [chainstat], 0
    je short .branch_140
    mov eax, dword [viewoffset]
    add eax, esi
    and eax, 3
    mov edx, 4
    mov al, byte [eax + pow2char]
    mov ebx, 0xc
    mov byte [esp + 0x60], al
    mov byte [esp + 0x5c], al
    mov eax, dword [esp + 0x28]
    mov dword [esp + 0x44], edx
    sub eax, esi
    mov dword [esp + 0x24], ebx
    cmp eax, edx
    jge short .branch_132
    mov eax, dword [esp + 0x28]
    add eax, dword [viewoffset]
    inc eax
    and eax, 3
    mov al, byte [eax + pow2char]
    mov byte [esp + 0x5c], al

.branch_132:
    xor eax, eax
    mov edx, 0x3c5
    mov al, byte [esp + 0x60]
    out dx, al
    jmp short .branch_152

.branch_140:
    mov ebp, 1
    mov eax, 3
    mov dword [esp + 0x44], ebp
    mov dword [esp + 0x24], eax

.branch_152:
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
    je short .branch_18c
    lea edi, [esi - 1]
    mov dword [esp + 0x54], edi

.branch_18c:
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
    je short .branch_1d5
    movsx eax, word [globalpicnum]
    mov al, byte [eax + picsiz]
    and eax, 0xff
    sar eax, 4
    mov dword [esp + 0x4c], eax

.branch_1d5:
    mov eax, dword [globalpal]
    mov eax, dword [eax*4 + palookup]
    mov dword [esp + 0x2c], eax
    movsx eax, word [engine_289146]
    call setupvlineasm

.branch_1f1:
    mov eax, dword [esp + 0x20]
    mov dword [esp + 0x50], eax

.branch_1f9:
    mov eax, dword [esp + 0x50]
    mov dx, word [nosplit eax*2 + engine_19e6e0]
    cmp dx, word [nosplit eax*2 + engine_1a7ce0]
    jle short .branch_21f
    cmp eax, dword [esp + 0x28]
    jg short .branch_21f
    mov eax, dword [esp + 0x44]
    add dword [esp + 0x50], eax
    jmp short .branch_1f9

.branch_21f:
    cmp byte [chainstat], 0
    je short .branch_246
    mov eax, dword [esp + 0x50]
    add eax, dword [viewoffset]
    mov edx, dword [chainplace]
    sar eax, 2

.branch_23b:
    add edx, eax
    mov dword [esp + 0x48], edx
    jmp near .branch_3d8

.branch_246:
    mov eax, dword [esp + 0x50]
    mov ebx, dword [frameplace]
    mov edx, dword [viewoffset]
    add eax, ebx
    jmp short .branch_23b

.branch_25a:
    mov ebx, dword [esp + 0x3c]
    add eax, eax
    add ebx, eax
    mov si, word [eax + engine_19e6e0]
    mov dx, word [ebx]
    cmp dx, si
    jle short .branch_275
    mov eax, edx
    jmp short .branch_277

.branch_275:
    mov eax, esi

.branch_277:
    cwde
    mov dword [esp], eax
    mov eax, dword [esp + 0x50]
    mov ebx, dword [esp + 0x40]
    add eax, eax
    add ebx, eax
    mov di, word [eax + engine_1a7ce0]
    mov dx, word [ebx]
    cmp dx, di
    jge short .branch_29a
    mov eax, edx
    jmp short .branch_29c

.branch_29a:
    mov eax, edi

.branch_29c:
    cwde
    mov ebp, dword [esp]
    mov dword [esp + 0x10], eax
    cmp eax, ebp
    jle near .branch_3c1
    mov esi, dword [esp + 0x50]
    mov eax, dword [esp + 0x74]
    mov ebx, dword [globvis]
    mov eax, dword [eax + esi*4]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    add edx, eax
    mov eax, dword [esp + 0x78]
    mov dword [engine_199010], edx
    mov edx, dword [globalxpanning]
    mov eax, dword [eax + esi*4]
    add eax, edx
    mov ebx, dword [esp + 0x54]
    mov dword [engine_199040], eax
    cmp eax, ebx
    jl short .branch_31b
    cmp dword [esp + 0x38], 0
    jne short .branch_311
    mov edx, eax
    sar edx, 0x1f
    idiv ebx
    mov dword [engine_199040], edx
    jmp short .branch_31b

.branch_311:
    mov esi, eax
    and esi, ebx
    mov dword [engine_199040], esi

.branch_31b:
    cmp dword [esp + 0x34], 0
    jne short .branch_335
    mov edx, dword [esp + 0x4c]
    mov eax, dword [engine_199040]
    imul eax, edx
    mov dword [engine_199040], eax
    jmp short .branch_33f

.branch_335:
    mov cl, byte [esp + 0x4c]
    shl dword [engine_199040], cl

.branch_33f:
    mov eax, dword [esp + 0x50]
    mov ebx, dword [esp + 0x74]
    shl eax, 2
    add eax, ebx
    mov ecx, dword [globalyscale]
    mov eax, dword [eax]
    imul eax, ecx
    mov esi, dword [globalhoriz]
    mov dword [engine_199020], eax
    mov eax, dword [esp]
    sub eax, esi
    mov edi, dword [engine_199020]
    inc eax
    imul eax, edi
    mov edx, dword [globalzd]
    mov ecx, dword [esp + 0x10]
    mov esi, dword [engine_199040]
    mov edi, dword [esp + 0x48]
    add eax, edx
    movsx edx, word [globalpicnum]
    mov dword [engine_199030], eax
    mov eax, dword [esp]
    mov ebx, dword [edx*4 + waloff]
    mov edx, dword [engine_199030]
    mov ebp, dword [eax*4 + row_offset]
    add esi, ebx
    sub ecx, eax
    mov ebx, dword [engine_199010]
    mov eax, dword [engine_199020]
    dec ecx
    add edi, ebp
    call vlineasm1

.branch_3c1:
    mov eax, dword [esp + 0x44]
    mov edx, dword [esp + 0x50]
    mov ebx, dword [esp + 0x48]
    add edx, eax
    inc ebx
    mov dword [esp + 0x50], edx
    mov dword [esp + 0x48], ebx

.branch_3d8:
    mov eax, dword [esp + 0x50]
    cmp eax, dword [esp + 0x28]
    jg near .branch_9fc
    test byte [esp + 0x50], 3
    jne near .branch_25a
    jmp near .branch_9fc

.branch_3f6:
    xor bl, bl
    lea edi, [esi + ecx]
    mov byte [esp + 0x58], bl
    mov ebx, 3
    jmp near .branch_51e

.branch_409:
    mov ebp, dword [esp + 0x3c]
    lea eax, [edi + edi]
    add ebp, eax
    mov cx, word [eax + engine_19e6e0]
    mov dx, word [ebp]
    cmp dx, cx
    jle short .branch_426
    mov eax, edx
    jmp short .branch_428

.branch_426:
    mov eax, ecx

.branch_428:
    movsx ebp, ax
    lea eax, [edi + edi]
    mov dword [esp + ebx*4], ebp
    mov ebp, dword [esp + 0x40]
    add ebp, eax
    mov si, word [eax + engine_1a7ce0]
    mov dx, word [ebp]
    cmp dx, si
    jge short .branch_44b
    mov eax, edx
    jmp short .branch_44d

.branch_44b:
    mov eax, esi

.branch_44d:
    movsx ebp, ax
    dec ebp
    mov edx, dword [esp + ebx*4]
    mov dword [esp + ebx*4 + 0x10], ebp
    cmp ebp, edx
    jge short .branch_471
    mov dh, byte [esp + 0x58]
    mov al, byte [ebx + pow2char]
    add dh, al
    mov byte [esp + 0x58], dh
    jmp near .branch_517

.branch_471:
    mov ebp, edi
    mov ecx, dword [esp + 0x78]
    shl ebp, 2
    add ebp, ecx
    mov esi, dword [globalxpanning]
    mov ebp, dword [ebp]
    mov eax, dword [esp + 0x54]
    add ebp, esi
    cmp ebp, eax
    jl short .branch_4a9
    cmp dword [esp + 0x38], 0
    jne short .branch_4a7
    mov esi, dword [esp + 0x54]
    mov edx, ebp
    mov eax, ebp
    sar edx, 0x1f
    idiv esi
    mov ebp, edx
    jmp short .branch_4a9

.branch_4a7:
    and ebp, eax

.branch_4a9:
    cmp dword [esp + 0x34], 0
    jne short .branch_4b7
    imul ebp, dword [esp + 0x4c]
    jmp short .branch_4bd

.branch_4b7:
    mov cl, byte [esp + 0x4c]
    shl ebp, cl

.branch_4bd:
    movsx eax, word [globalpicnum]
    mov ecx, dword [eax*4 + waloff]
    add ebp, ecx
    mov dword [ebx*4 + engine_199040], ebp
    mov ebp, edi
    mov esi, dword [esp + 0x74]
    shl ebp, 2
    add ebp, esi
    mov edx, dword [globalyscale]
    mov ebp, dword [ebp]
    imul ebp, edx
    mov ecx, dword [globalhoriz]
    mov dword [ebx*4 + engine_199020], ebp
    mov ebp, dword [esp + ebx*4]
    sub ebp, ecx
    mov esi, dword [ebx*4 + engine_199020]
    inc ebp
    imul ebp, esi
    mov edx, dword [globalzd]
    add ebp, edx
    mov dword [ebx*4 + engine_199030], ebp

.branch_517:
    mov ecx, dword [esp + 0x44]
    dec ebx
    sub edi, ecx

.branch_51e:
    test ebx, ebx
    jge near .branch_409
    xor eax, eax
    mov al, byte [esp + 0x58]
    cmp eax, 0xf
    je near .branch_9e0
    mov eax, dword [esp + 0x50]
    mov edx, dword [esp + 0x74]
    shl eax, 2
    add eax, edx
    mov ebx, dword [globvis]
    mov eax, dword [eax]
    mov ecx, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, ecx
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    mov esi, dword [esp + 0x24]
    add edx, eax
    mov eax, dword [esp + 0x50]
    add eax, esi
    mov edi, dword [esp + 0x74]
    shl eax, 2
    add eax, edi
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
    jne short .branch_5d0
    mov al, byte [esp + 0x58]
    and al, 9
    and eax, 0xff
    jne short .branch_5d0
    mov eax, dword [engine_199010]
    mov dword [engine_199014], eax
    mov dword [engine_199018], eax
    jmp short .branch_646

.branch_5d0:
    mov eax, dword [esp + 0x50]
    add eax, dword [esp + 0x44]
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
    add edx, eax
    mov eax, dword [esp + 0x44]
    mov edi, dword [esp + 0x50]
    add eax, eax
    add eax, edi
    shl eax, 2
    add eax, esi
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

.branch_646:
    mov eax, dword [esp + 8]
    mov edx, dword [esp + 0xc]
    cmp eax, edx
    jle short .branch_654
    mov edx, eax

.branch_654:
    mov eax, dword [esp]
    mov ebx, dword [esp + 4]
    cmp eax, ebx
    jg short .branch_661
    mov eax, ebx

.branch_661:
    cmp eax, edx
    jle short .branch_674
    mov eax, dword [esp]
    mov esi, dword [esp + 4]
    cmp eax, esi
    jg short .branch_682
    mov eax, esi
    jmp short .branch_682

.branch_674:
    mov eax, dword [esp + 8]
    mov ecx, dword [esp + 0xc]
    cmp eax, ecx
    jg short .branch_682
    mov eax, ecx

.branch_682:
    mov edi, dword [esp + 0x1c]
    mov ebp, eax
    mov eax, dword [esp + 0x18]
    cmp eax, edi
    jge short .branch_694
    mov edx, eax
    jmp short .branch_696

.branch_694:
    mov edx, edi

.branch_696:
    mov eax, dword [esp + 0x10]
    mov ebx, dword [esp + 0x14]
    cmp eax, ebx
    jl short .branch_6a4
    mov eax, ebx

.branch_6a4:
    cmp eax, edx
    jge short .branch_6b8
    mov eax, dword [esp + 0x10]
    mov esi, dword [esp + 0x14]
    cmp eax, esi
    jl short .branch_6c6
    mov eax, esi
    jmp short .branch_6c6

.branch_6b8:
    mov eax, dword [esp + 0x18]
    mov ecx, dword [esp + 0x1c]
    cmp eax, ecx
    jl short .branch_6c6
    mov eax, ecx

.branch_6c6:
    mov dl, byte [esp + 0x58]
    mov dword [esp + 0x30], eax
    test dl, dl
    jne short .branch_6da
    cmp ebp, eax
    jl near .branch_7ec

.branch_6da:
    mov al, byte [esp + 0x58]
    and al, 1
    and eax, 0xff
    jne short .branch_719
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
    call prevlineasm1

.branch_719:
    mov al, byte [esp + 0x58]
    and al, 2
    and eax, 0xff
    jne short .branch_75e
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
    call prevlineasm1

.branch_75e:
    mov al, byte [esp + 0x58]
    and al, 4
    and eax, 0xff
    jne short .branch_7a1
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
    call prevlineasm1

.branch_7a1:
    mov al, byte [esp + 0x58]
    and al, 8
    and eax, 0xff
    jne near .branch_9e0
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
    jmp near .branch_9db

.branch_7ec:
    mov edi, dword [esp]
    cmp ebp, edi
    jle short .branch_829
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
    call prevlineasm1
    mov dword [engine_199030], eax

.branch_829:
    mov ecx, dword [esp + 4]
    cmp ebp, ecx
    jle short .branch_867
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
    call prevlineasm1
    mov dword [engine_199034], eax

.branch_867:
    mov edx, dword [esp + 8]
    cmp ebp, edx
    jle short .branch_8a7
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
    call prevlineasm1
    mov dword [engine_199038], eax

.branch_8a7:
    mov edx, dword [esp + 0xc]
    cmp ebp, edx
    jle short .branch_8e7
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
    call prevlineasm1
    mov dword [engine_19903c], eax

.branch_8e7:
    mov edx, dword [esp + 0x30]
    cmp ebp, edx
    jg short .branch_906
    mov ebx, dword [esp + 0x48]
    mov ecx, edx
    mov edi, dword [ebp*4 + row_offset]
    sub ecx, ebp
    add edi, ebx
    inc ecx
    call vlineasm4

.branch_906:
    mov eax, dword [esp + 0x30]
    mov ebp, dword [esp + 0x48]
    mov esi, dword [esp + 0x30]
    mov ecx, dword [eax*4 + engine_286bb4]
    mov eax, dword [esp + 0x10]
    add ebp, ecx
    cmp eax, esi
    jle short .branch_94a
    mov edi, dword [esp + 0x30]
    mov esi, dword [engine_199040]
    mov edx, dword [engine_199030]
    mov ecx, eax
    mov ebx, dword [engine_199010]
    sub ecx, edi
    mov eax, dword [engine_199020]
    dec ecx
    mov edi, ebp
    call prevlineasm1

.branch_94a:
    mov eax, dword [esp + 0x14]
    cmp eax, dword [esp + 0x30]
    jle short .branch_97c
    mov ebx, dword [esp + 0x30]
    mov esi, dword [engine_199044]
    mov edx, dword [engine_199034]
    lea edi, [ebp + 1]
    mov ecx, eax
    mov eax, dword [engine_199024]
    sub ecx, ebx
    mov ebx, dword [engine_199014]
    dec ecx
    call prevlineasm1

.branch_97c:
    mov eax, dword [esp + 0x18]
    cmp eax, dword [esp + 0x30]
    jle short .branch_9ae
    mov esi, dword [engine_199048]
    mov edx, dword [engine_199038]
    mov ebx, dword [engine_199018]
    mov ecx, eax
    mov eax, dword [esp + 0x30]
    lea edi, [ebp + 2]
    sub ecx, eax
    mov eax, dword [engine_199028]
    dec ecx
    call prevlineasm1

.branch_9ae:
    mov eax, dword [esp + 0x1c]
    cmp eax, dword [esp + 0x30]
    jle short .branch_9e0
    mov ebx, dword [esp + 0x30]
    mov esi, dword [engine_19904c]
    mov edx, dword [engine_19903c]
    lea edi, [ebp + 3]
    mov ecx, eax
    mov eax, dword [engine_19902c]
    sub ecx, ebx
    mov ebx, dword [engine_19901c]
    dec ecx

.branch_9db:
    call prevlineasm1

.branch_9e0:
    mov eax, dword [esp + 0x44]
    mov ecx, dword [esp + 0x50]
    mov esi, dword [esp + 0x48]
    shl eax, 2
    add esi, 4
    add ecx, eax
    mov dword [esp + 0x48], esi
    mov dword [esp + 0x50], ecx

.branch_9fc:
    mov eax, dword [esp + 0x28]
    mov ecx, dword [esp + 0x24]
    mov esi, dword [esp + 0x50]
    sub eax, ecx
    cmp eax, esi
    jge near .branch_3f6
    jmp near .branch_ba3

.branch_a17:
    mov ebx, dword [esp + 0x3c]
    add eax, eax
    add ebx, eax
    mov cx, word [eax + engine_19e6e0]
    mov dx, word [ebx]
    cmp dx, cx
    jle short .branch_a32
    mov eax, edx
    jmp short .branch_a34

.branch_a32:
    mov eax, ecx

.branch_a34:
    cwde
    mov dword [esp], eax
    mov eax, dword [esp + 0x50]
    mov ebx, dword [esp + 0x40]
    add eax, eax
    add ebx, eax
    mov si, word [eax + engine_1a7ce0]
    mov dx, word [ebx]
    cmp dx, si
    jge short .branch_a57
    mov eax, edx
    jmp short .branch_a59

.branch_a57:
    mov eax, esi

.branch_a59:
    cwde
    mov esi, dword [esp]
    mov dword [esp + 0x10], eax
    cmp eax, esi
    jle near .branch_b8c
    mov ecx, dword [esp + 0x50]
    mov eax, dword [esp + 0x74]
    shl ecx, 2
    mov ebx, dword [globvis]
    mov eax, dword [ecx + eax]
    mov esi, dword [globalshade]
    imul ebx
    shrd eax, edx, 0x10
    mov edx, esi
    call getpalookup
    mov edx, dword [esp + 0x2c]
    shl eax, 8
    mov edi, dword [esp + 0x78]
    add edx, eax
    add ecx, edi
    mov dword [engine_199010], edx
    mov ebp, dword [globalxpanning]
    mov eax, dword [ecx]
    add eax, ebp
    mov edx, dword [esp + 0x54]
    mov dword [engine_199040], eax
    cmp eax, edx
    jl short .branch_ae0
    cmp dword [esp + 0x38], 0
    jne short .branch_ad6
    mov edx, eax
    mov esi, dword [esp + 0x54]
    sar edx, 0x1f
    idiv esi
    mov dword [engine_199040], edx
    jmp short .branch_ae0

.branch_ad6:
    mov ecx, eax
    and ecx, edx
    mov dword [engine_199040], ecx

.branch_ae0:
    cmp dword [esp + 0x34], 0
    jne short .branch_afa
    mov edx, dword [esp + 0x4c]
    mov eax, dword [engine_199040]
    imul eax, edx
    mov dword [engine_199040], eax
    jmp short .branch_b04

.branch_afa:
    mov cl, byte [esp + 0x4c]
    shl dword [engine_199040], cl

.branch_b04:
    mov eax, dword [esp + 0x50]
    mov ebx, dword [esp + 0x74]
    shl eax, 2
    add eax, ebx
    mov ecx, dword [globalyscale]
    mov eax, dword [eax]
    imul eax, ecx
    mov esi, dword [globalhoriz]
    mov dword [engine_199020], eax
    mov eax, dword [esp]
    sub eax, esi
    mov edx, dword [engine_199020]
    inc eax
    imul edx, eax
    mov ecx, dword [esp + 0x10]
    mov esi, dword [esp]
    mov edi, dword [esp + 0x48]
    sub ecx, esi
    mov eax, dword [globalzd]
    dec ecx
    add eax, edx
    movsx edx, word [globalpicnum]
    mov dword [engine_199030], eax
    mov eax, dword [esp]
    mov ebx, dword [edx*4 + waloff]
    mov edx, dword [engine_199030]
    mov ebp, dword [eax*4 + row_offset]
    mov eax, dword [engine_199040]
    add edi, ebp
    mov ebp, dword [engine_199020]
    add eax, ebx
    mov ebx, dword [engine_199010]
    mov esi, eax
    mov eax, ebp
    call vlineasm1

.branch_b8c:
    mov eax, dword [esp + 0x44]
    mov edi, dword [esp + 0x50]
    mov ebp, dword [esp + 0x48]
    add edi, eax
    inc ebp
    mov dword [esp + 0x50], edi
    mov dword [esp + 0x48], ebp

.branch_ba3:
    mov eax, dword [esp + 0x50]
    cmp eax, dword [esp + 0x28]
    jle near .branch_a17
    cmp byte [chainstat], 0
    je short .branch_be7
    mov cl, byte [esp + 0x60]
    xor eax, eax
    add cl, cl
    mov al, cl
    mov byte [esp + 0x60], cl
    cmp eax, 0x10
    jne short .branch_bd2
    mov byte [esp + 0x60], 1

.branch_bd2:
    mov edx, 0x3c5
    xor eax, eax
    mov ebx, dword [esp + 0x20]
    mov al, byte [esp + 0x60]
    inc ebx
    out dx, al
    mov dword [esp + 0x20], ebx

.branch_be7:
    cmp dword [esp + 0x44], 4
    jne short .branch_bfc
    mov al, byte [esp + 0x60]
    cmp al, byte [esp + 0x5c]
    jne near .branch_1f1

.branch_bfc:
    call faketimerhandler

.branch_c01:
    add esp, 0x64
    pop ebp
    pop edi
    pop esi
    ret 8
