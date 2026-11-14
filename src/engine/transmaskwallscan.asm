; Dispatch translucent wall columns to the single- and two-column renderers.
BITS 32
ORG 0x49dd1

tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
chainstat equ 0x14003
pow2char equ 0x14029
startdmost equ 0x1f8020
startumost equ 0x1f13a0
globalpicnum equ 0x289144
viewoffset equ 0x286ae8
windowx1 equ 0x286b9c
row_offset equ 0x286bb0
gotpic equ 0x1ecda0
projection_scale equ 0x286b00
tile_y_shift equ 0x2891d6
engine_289146 equ 0x289146
loadtile equ 0x4bb0d
setuptvlineasm equ 0x74310
transmaskvline equ 0x4aa28
transmaskvline_pair equ 0x4abc5
faketimerhandler equ 0x31ec4
ceiling_sprite_restore equ 0x50347

transmaskwallscan_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    push eax
    push edx
    mov ax, word [globalpicnum]
    cwde
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jae short .branch_020
    mov byte [eax + walock], 0xc7

.branch_020:
    shr eax, 3
    and ebx, 7
    mov dl, byte [eax + gotpic]
    mov bl, byte [ebx + pow2char]
    or dl, bl
    mov byte [eax + gotpic], dl
    movsx edx, word [globalpicnum]
    lea eax, [edx + edx]
    cmp word [eax + tilesizx], 0
    jle near .branch_155
    cmp word [eax + tilesizy], 0
    jle near .branch_155
    cmp dword [edx*4 + waloff], 0
    jne short .branch_071
    mov eax, edx
    call loadtile

.branch_071:
    movsx eax, word [engine_289146]
    call setuptvlineasm
    cmp byte [chainstat], 0
    je near .branch_15d
    mov cl, byte [esp + 4]
    mov dl, byte [viewoffset]
    mov eax, dword [esp]
    add cl, dl
    mov esi, dword [esp + 4]
    and cl, 3
    sub eax, esi
    mov ch, cl
    cmp eax, 4
    jge short .branch_0b3
    mov ch, byte [esp]
    inc ch
    add ch, dl
    and ch, 3

.branch_0b3:
    mov esi, dword [esp + 4]
    mov ebp, dword [esp]

.branch_0ba:
    xor eax, eax
    mov al, cl
    mov al, byte [eax + pow2char]
    mov edx, 0x3c5
    and eax, 0xff
    out dx, al
    mov al, cl
    xor ah, ah
    and al, 3
    cwde
    shl eax, 8
    mov edx, 0x3ce
    add eax, 4
    out dx, ax
    mov edx, esi

.branch_0e5:
    mov eax, dword [windowx1]
    add eax, edx
    mov bx, word [nosplit eax*2 + startumost]
    cmp bx, word [nosplit eax*2 + startdmost]
    jle short .branch_108
    cmp edx, dword [esp]
    jg short .branch_108
    add edx, 4
    jmp short .branch_0e5

.branch_108:
    cmp edx, ebp
    jg short .branch_11b
    test dl, 1
    je short .branch_11b
    mov eax, edx
    call transmaskvline
    add edx, 4

.branch_11b:
    mov eax, dword [esp]
    sub eax, 4
    cmp edx, eax
    jg short .branch_131
    mov eax, edx
    call transmaskvline_pair
    add edx, 8
    jmp short .branch_11b

.branch_131:
    cmp edx, dword [esp]
    jg short .branch_142
    mov eax, edx
    call transmaskvline
    add edx, 4
    jmp short .branch_131

.branch_142:
    inc cl
    and cl, 3
    inc esi
    cmp cl, ch
    jne near .branch_0ba

.branch_150:
    call faketimerhandler

.branch_155:
    add esp, 8
    jmp near ceiling_sprite_restore

.branch_15d:
    mov edx, dword [esp + 4]
    mov edi, dword [esp]

.branch_164:
    mov eax, dword [windowx1]
    add eax, edx
    mov bx, word [nosplit eax*2 + startumost]
    cmp bx, word [nosplit eax*2 + startdmost]
    jle short .branch_184
    cmp edx, edi
    jg short .branch_184
    inc edx
    jmp short .branch_164

.branch_184:
    cmp edx, dword [esp]
    jg short .branch_196
    test dl, 1
    je short .branch_196
    mov eax, edx
    call transmaskvline
    inc edx

.branch_196:
    cmp edx, dword [esp]
    jge short .branch_1a7
    mov eax, edx
    call transmaskvline_pair
    add edx, 2
    jmp short .branch_196

.branch_1a7:
    mov ebx, dword [esp]

.branch_1aa:
    cmp edx, ebx
    jg short .branch_150
    mov eax, edx
    call transmaskvline
    inc edx
    jmp short .branch_1aa
