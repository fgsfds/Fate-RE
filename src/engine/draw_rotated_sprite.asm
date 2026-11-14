; Clip and rasterize a rotated sprite for the active video backend.
BITS 32
ORG 0x573ac

chainstat equ 0x14003
transarea equ 0x14008
pow2char equ 0x14029
xdimen equ 0x140b5
faketimerhandler equ 0x31ec4
select_vesa_draw_page equ 0x4417c
loadtile equ 0x4bb0d
restore_sprite_registers equ 0x573a6
sub_59135 equ 0x59135
setupvlineasm equ 0x742d0
setupmvlineasm equ 0x742f0
prevlineasm1 equ 0x74320
mvlineasm1 equ 0x74370
settransnormal equ 0x743d0
settransreverse equ 0x74450
vlineasm4 equ 0x74510
mvlineasm4 equ 0x74660
setupspritevline equ 0x748e0
spritevline equ 0x7492c
msetupspritevline equ 0x74950
mspritevline equ 0x749a0
tsetupspritevline equ 0x749c0
tspritevline equ 0x749f0
setup_sprite_horizontal_unrolled equ 0x75080
draw_sprite_horizontal_unrolled equ 0x75120
setup_sprite_horizontal_masked equ 0x75230
draw_sprite_horizontal_masked equ 0x75250
setup_sprite_horizontal_reverse equ 0x752b0
draw_sprite_horizontal_reverse equ 0x75310
lastx equ 0x197d50
engine_199010 equ 0x199010
engine_199014 equ 0x199014
engine_199018 equ 0x199018
engine_19901c equ 0x19901c
engine_199020 equ 0x199020
engine_199024 equ 0x199024
engine_199028 equ 0x199028
engine_19902c equ 0x19902c
engine_199030 equ 0x199030
engine_199034 equ 0x199034
engine_199038 equ 0x199038
engine_19903c equ 0x19903c
engine_199040 equ 0x199040
engine_199044 equ 0x199044
engine_199048 equ 0x199048
engine_19904c equ 0x19904c
lower_plane_edge equ 0x19f360
upper_clip_edge equ 0x1a3e60
frame_state_1a3e62 equ 0x1a3e62
rx1 equ 0x1cd160
engine_1cd164 equ 0x1cd164
engine_1cd168 equ 0x1cd168
engine_1cd16c equ 0x1cd16c
ry1 equ 0x1d1160
engine_1d1164 equ 0x1d1164
engine_1d1168 equ 0x1d1168
engine_1d116c equ 0x1d116c
engine_1ecda0 equ 0x1ecda0
picanm equ 0x1ed3a0
startumost equ 0x1f13a0
engine_1f13a2 equ 0x1f13a2
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
startdmost equ 0x1f8020
walock equ 0x1f8ca0
waloff equ 0x1ffca0
palookup equ 0x203ca0
sintable equ 0x2300a0
viewingrange_scaled equ 0x286b00
chainplace equ 0x286b4c
frame_state_286b50 equ 0x286b50
skip_bank_switch equ 0x286b54
draw_page_address equ 0x286b74
use_software_framebuffer equ 0x286b84
viewingrange_reciprocal equ 0x286bac
ylookup equ 0x286bb0
ylookup_second_row equ 0x286bb4
viewingrange equ 0x287e7c
xdim equ 0x287e90
numpalookups equ 0x289156
video_backend equ 0x2891db

draw_rotated_sprite:
    push esi
    push edi
    push ebp
    sub esp, strict dword 0xc4
    mov edi, eax
    mov [esp + 0x50], edx
    mov [esp + 0x58], ebx
    mov [esp + 0xbc], ecx
    movsx edx, word [esp + 0xd4]
    movsx eax, word [nosplit edx*2 + tilesizy]
    movsx ebx, word [nosplit edx*2 + tilesizx]
    mov [esp + 0xa8], eax
    mov al, [esp + 0xe0]
    mov [esp + 0x4c], ebx
    and al, 0x10
    and eax, strict dword 0xff
    jz short .branch_57403
    xor edx, edx
    xor esi, esi
    mov [esp + 0x54], edx
    jmp short .branch_57441

.branch_57403:
    mov eax, edx
    mov edx, [nosplit edx*4 + picanm]
    mov eax, [nosplit eax*4 + picanm]
    sar edx, byte 0x8
    sar eax, byte 0x10
    and edx, strict dword 0xff
    and eax, strict dword 0xff
    movsx ebx, dl
    movsx esi, al
    mov edx, [esp + 0x4c]
    mov eax, [esp + 0xa8]
    sar edx, 1
    sar eax, 1
    add ebx, edx
    add esi, eax
    mov [esp + 0x54], ebx

.branch_57441:
    mov al, [esp + 0xe0]
    and al, 0x4
    and eax, strict dword 0xff
    jz short .branch_5745c
    mov eax, [esp + 0xa8]
    sub eax, esi
    mov esi, eax

.branch_5745c:
    movsx eax, word [esp + 0xbc]
    add eax, strict dword 0x200
    and eax, strict dword 0x7ff
    movsx eax, word [nosplit eax*2 + sintable]
    mov [esp + 0x44], eax
    mov eax, [esp + 0xbc]
    and ah, 0x7
    cwde
    movsx eax, word [nosplit eax*2 + sintable]
    mov [esp + 0x40], eax
    mov al, [esp + 0xe0]
    and al, 0x2
    and eax, strict dword 0xff
    jz near .branch_5754b
    mov al, [esp + 0xe0]
    and al, 0x8
    mov edx, [esp + 0xe4]
    add edx, [esp + 0xec]
    add edx, 0x2
    and eax, strict dword 0xff
    shl edx, byte 0xf
    sub edi, strict dword 0xa00000
    mov [esp + 0x48], edx
    test eax, eax
    jnz short .branch_574e8
    mov ecx, 0x140
    mov ebp, [viewingrange_scaled]
    mov ebx, [xdimen]
    jmp short .branch_57504

.branch_574e8:
    mov ecx, 0x140
    mov ebx, [viewingrange]
    mov eax, [xdim]
    imul ebx
    idiv ecx
    mov ebx, [xdim]
    mov ebp, eax

.branch_57504:
    mov eax, edi
    mov edi, [esp + 0x48]
    imul ebx
    idiv ecx
    add edi, eax
    mov eax, [esp + 0xe8]
    mov ecx, [esp + 0xf0]
    mov ebx, ebp
    add ecx, eax
    mov eax, [esp + 0x50]
    add ecx, 0x2
    sub eax, strict dword 0x640000
    shl ecx, byte 0xf
    imul ebx
    shrd eax, edx, byte 0x10
    add ecx, eax
    mov eax, [esp + 0x58]
    mov [esp + 0x50], ecx
    imul ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0x58], eax

.branch_5754b:
    mov ebx, [esp + 0x58]
    mov eax, [esp + 0x44]
    imul ebx
    shrd eax, edx, byte 0xe
    mov ecx, eax
    mov [esp + 0xa0], eax
    mov eax, [esp + 0x40]
    imul ebx
    shrd eax, edx, byte 0xe
    mov edx, eax
    mov [esp + 0xac], eax
    mov al, [esp + 0xe0]
    and al, 0x2
    and eax, strict dword 0xff
    jnz short .branch_57595
    mov al, [esp + 0xe0]
    and al, 0x8
    and eax, strict dword 0xff
    jnz short .branch_575c5

.branch_57595:
    mov eax, [esp + 0xa0]
    mov ebx, [viewingrange_reciprocal]
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [viewingrange_reciprocal]
    mov [esp + 0x78], eax
    mov eax, [esp + 0xac]
    imul ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0x20], eax
    jmp short .branch_575cd

.branch_575c5:
    mov [esp + 0x78], ecx
    mov [esp + 0x20], edx

.branch_575cd:
    mov edx, [esp + 0xac]
    imul edx, [esp + 0x54]
    mov eax, [esp + 0xa0]
    imul eax, esi
    add eax, edx
    mov edx, [esp + 0x50]
    sub edx, eax
    mov eax, [esp + 0x4c]
    mov [ry1], edx
    mov edx, [esp + 0xac]
    imul edx, eax
    mov eax, [ry1]
    mov ebx, [esp + 0xa8]
    add eax, edx
    mov edx, [esp + 0xa0]
    imul edx, ebx
    mov [engine_1d1164], eax
    mov eax, [ry1]
    add eax, edx
    mov edx, [engine_1d1164]
    mov [engine_1d116c], eax
    add edx, eax
    mov eax, [ry1]
    sub edx, eax
    mov eax, [esp + 0xe8]
    shl eax, byte 0x10
    mov [esp + 0x74], eax
    mov ebp, [esp + 0x74]
    mov eax, [ry1]
    mov [engine_1d1168], edx
    cmp eax, ebp
    jnl short .branch_57670
    cmp ebp, [engine_1d1164]
    jng short .branch_57670
    cmp edx, ebp
    jnl short .branch_57670
    cmp ebp, [engine_1d116c]
    jg near .branch_5912a

.branch_57670:
    mov eax, [esp + 0xf0]
    shl eax, byte 0x10
    mov [esp + 0x74], eax
    mov ebp, [esp + 0x74]
    cmp ebp, [ry1]
    jnl short .branch_576a6
    cmp ebp, [engine_1d1164]
    jnl short .branch_576a6
    cmp ebp, [engine_1d1168]
    jnl short .branch_576a6
    cmp ebp, [engine_1d116c]
    jl near .branch_5912a

.branch_576a6:
    mov eax, [esp + 0x78]
    imul eax, [esp + 0x54]
    imul esi, [esp + 0x20]
    mov ebx, [esp + 0x4c]
    mov edx, [esp + 0x78]
    imul edx, ebx
    sub eax, esi
    sub edi, eax
    mov ecx, [esp + 0xa8]
    mov [rx1], edi
    lea eax, [edi + edx]
    mov edx, [esp + 0x20]
    imul edx, ecx
    mov [engine_1cd164], eax
    mov eax, edi
    sub eax, edx
    mov edx, [engine_1cd164]
    mov [engine_1cd16c], eax
    add edx, eax
    mov eax, [esp + 0xe4]
    shl eax, byte 0x10
    sub edx, edi
    mov [esp + 0x74], eax
    mov eax, edi
    mov edi, [esp + 0x74]
    mov [engine_1cd168], edx
    cmp eax, edi
    jnl short .branch_57728
    cmp edi, [engine_1cd164]
    jng short .branch_57728
    cmp edx, edi
    jnl short .branch_57728
    cmp edi, [engine_1cd16c]
    jg near .branch_5912a

.branch_57728:
    mov eax, [esp + 0xec]
    shl eax, byte 0x10
    mov [esp + 0x74], eax
    mov ecx, [esp + 0x74]
    cmp ecx, [rx1]
    jnl short .branch_5775e
    cmp ecx, [engine_1cd164]
    jnl short .branch_5775e
    cmp ecx, [engine_1cd168]
    jnl short .branch_5775e
    cmp ecx, [engine_1cd16c]
    jl near .branch_5912a

.branch_5775e:
    mov ecx, [esp + 0xf0]
    mov ebx, [esp + 0xec]
    mov eax, [rx1]
    mov edx, [esp + 0xe8]
    mov [esp + 0x38], eax
    inc ecx
    inc ebx
    shl edx, byte 0x10
    mov eax, [ry1]
    shl ecx, byte 0x10
    mov [esp + 0x34], eax
    mov eax, [esp + 0xe4]
    shl ebx, byte 0x10
    shl eax, byte 0x10
    call sub_59135
    mov ebp, eax
    cmp eax, 0x3
    jl near .branch_5912a
    mov eax, [rx1]
    dec ebp
    mov [esp + 0x68], eax
    mov [esp + 0x64], eax
    xor eax, eax
    jmp near .branch_578e1

.branch_577bf:
    mov edx, [nosplit ebp*4 + rx1]
    mov esi, [esp + 0x68]
    mov [esp + 0x70], edx
    mov edx, [nosplit eax*4 + rx1]
    mov edi, [esp + 0x70]
    mov [esp + 0x24], edx
    mov edx, [esp + 0x70]
    sar edi, byte 0x10
    cmp edx, esi
    jnl short .branch_577ec
    mov [esp + 0x68], edx

.branch_577ec:
    mov ecx, [esp + 0x24]
    mov edx, [esp + 0x70]
    mov ebx, [esp + 0x64]
    sar ecx, byte 0x10
    cmp edx, ebx
    jng short .branch_57803
    mov [esp + 0x64], edx

.branch_57803:
    cmp edi, ecx
    jz near .branch_578de
    mov ebx, [esp + 0x24]
    mov esi, [esp + 0x70]
    mov eax, [nosplit eax*4 + ry1]
    mov edx, [nosplit ebp*4 + ry1]
    mov [esp + 0xb4], eax
    sub ebx, esi
    sub eax, edx
    mov [esp + 0x2c], edx
    mov edx, eax
    sar edx, byte 0x10
    shl eax, byte 0x10
    idiv ebx
    mov esi, eax
    cmp ecx, edi
    jng short .branch_5786a
    mov eax, edi
    shl eax, byte 0x10
    mov edx, [esp + 0x70]
    add eax, strict dword 0xffff
    mov ebx, esi
    sub eax, edx
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0x2c]
    sub ecx, edi
    add edx, eax
    lea eax, [edi + edi]
    add eax, upper_clip_edge
    jmp short .branch_57897

.branch_5786a:
    mov eax, ecx
    shl eax, byte 0x10
    mov ebx, [esp + 0x24]
    add eax, strict dword 0xffff
    sub eax, ebx
    mov ebx, esi
    imul ebx
    shrd eax, edx, byte 0x10
    mov edx, [esp + 0xb4]
    sub edi, ecx
    add edx, eax
    lea eax, [ecx + ecx]
    add eax, lower_plane_edge
    mov ecx, edi

.branch_57897:
    test ecx, ecx
    jz short .branch_578de
    test al, 0x2
    jz short .branch_578af
    mov ebx, edx
    sar ebx, byte 0x10
    mov [eax], bx
    add edx, esi
    add eax, 0x2
    dec ecx
    jz short .branch_578de

.branch_578af:
    sub ecx, 0x2
    jc short .branch_578d6

.branch_578b4:
    mov ebx, edx
    add edx, esi
    sar ebx, byte 0x10
    mov edi, edx
    and edi, strict dword 0xffff0000
    add edx, esi
    add ebx, edi
    mov [eax], ebx
    add eax, 0x4
    sub ecx, 0x2
    jnc short .branch_578b4
    test cl, 0x1
    jz short .branch_578de

.branch_578d6:
    mov ebx, edx
    sar ebx, byte 0x10
    mov [eax], bx

.branch_578de:
    mov eax, ebp
    dec ebp

.branch_578e1:
    test ebp, ebp
    jnl near .branch_577bf
    movsx edx, word [esp + 0xd4]
    cmp dword [nosplit edx*4 + waloff], 0x0
    jnz short .branch_57902
    mov eax, edx
    call loadtile

.branch_57902:
    movsx eax, word [esp + 0xd4]
    mov ebx, eax
    cmp byte [eax + walock], 0xc8
    jnc short .branch_5791c
    mov byte [eax + walock], 0xc7

.branch_5791c:
    shr eax, byte 0x3
    and ebx, 0x7
    mov dl, [eax + engine_1ecda0]
    mov bl, [ebx + pow2char]
    or dl, bl
    mov [eax + engine_1ecda0], dl
    movsx eax, word [esp + 0xd4]
    mov eax, [nosplit eax*4 + waloff]
    mov [esp + 0xa4], eax
    movsx eax, word [numpalookups]
    movsx edx, byte [esp + 0xd8]
    dec eax
    cmp edx, eax
    jnl short .branch_57962
    mov eax, edx

.branch_57962:
    test eax, eax
    jng short .branch_5797e
    movsx eax, word [numpalookups]
    movsx edx, byte [esp + 0xd8]
    dec eax
    cmp edx, eax
    jnl short .branch_57980
    mov eax, edx
    jmp short .branch_57980

.branch_5797e:
    xor eax, eax

.branch_57980:
    mov [esp + 0xd8], al
    xor eax, eax
    movsx edx, byte [esp + 0xd8]
    mov al, [esp + 0xdc]
    shl edx, byte 0x8
    mov eax, [nosplit eax*4 + palookup]
    mov ebx, [esp + 0x58]
    add eax, edx
    mov edx, 0x1
    mov [esp + 0x5c], eax
    xor eax, eax
    idiv ebx
    mov ebx, eax
    mov eax, [esp + 0x40]
    imul ebx
    shrd eax, edx, byte 0xe
    mov esi, eax
    mov [esp + 0xa0], eax
    mov eax, [esp + 0x44]
    imul ebx
    shrd eax, edx, byte 0xe
    mov edx, eax
    mov [esp + 0xac], eax
    mov al, [esp + 0xe0]
    and al, 0x2
    and eax, strict dword 0xff
    jnz short .branch_579fd
    mov al, [esp + 0xe0]
    and al, 0x8
    and eax, strict dword 0xff
    jnz short .branch_57a2f

.branch_579fd:
    mov eax, [esp + 0xa0]
    mov ebx, [viewingrange]
    neg eax
    imul ebx
    shrd eax, edx, byte 0x10
    mov ebx, [viewingrange]
    mov [esp + 0x20], eax
    mov eax, [esp + 0xac]
    imul ebx
    shrd eax, edx, byte 0x10
    mov [esp + 0x78], eax
    jmp short .branch_57a3f

.branch_57a2f:
    mov ecx, esi
    mov [esp + 0x20], esi
    neg ecx
    mov [esp + 0x78], edx
    mov [esp + 0x20], ecx

.branch_57a3f:
    mov eax, [esp + 0x68]
    mov edi, [esp + 0x38]
    mov ecx, 0xffff
    mov ebx, [esp + 0x78]
    xor esi, esi
    sar eax, byte 0x10
    mov [esp + 0xb0], esi
    mov [esp + 0x70], eax
    mov eax, [esp + 0x64]
    mov ebp, [esp + 0x70]
    sar eax, byte 0x10
    shl ebp, byte 0x10
    mov [esp + 0x24], eax
    dec ebp
    mov eax, [esp + 0x34]
    sub ebp, edi
    sub ecx, eax
    mov edi, [esp + 0xa0]
    mov esi, ecx
    mov eax, ebp
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edi, [esp + 0xac]
    mov ebx, [esp + 0x20]
    mov [esp + 0xb8], eax
    mov esi, ecx
    mov eax, ebp
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0x10
    mov edx, eax
    mov [esp + 0x28], eax
    mov al, [esp + 0xe0]
    and al, 0x4
    and eax, strict dword 0xff
    jz short .branch_57af6
    mov ecx, [esp + 0x20]
    mov ebx, edi
    mov eax, [esp + 0xa8]
    neg ebx
    shl eax, byte 0x10
    neg ecx
    dec eax
    mov [esp + 0xac], ebx
    sub eax, edx
    mov [esp + 0x20], ecx
    mov [esp + 0x28], eax

.branch_57af6:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x1
    jnz short .branch_57b35
    mov al, [esp + 0xe0]
    and al, 0x80
    and eax, strict dword 0xff
    jz short .branch_57b35
    mov esi, [skip_bank_switch]
    test esi, esi
    jnz short .branch_57b35
    mov eax, [use_software_framebuffer]
    mov [esp + 0x3c], eax
    mov eax, [frame_state_286b50]
    mov [use_software_framebuffer], esi
    call select_vesa_draw_page

.branch_57b35:
    cmp byte [chainstat], 0x0
    jnz near .branch_58db7
    mov al, [esp + 0xe0]
    and al, 0x1
    and eax, strict dword 0xff
    jnz near .branch_58db7
    mov eax, [esp + 0xbc]
    and ah, 0x3
    cwde
    test eax, eax
    jnz near .branch_5854c
    cmp dword [esp + 0xa8], strict dword 0x100
    jg near .branch_5854c
    mov al, [esp + 0xe0]
    and al, 0x40
    and eax, strict dword 0xff
    jz short .branch_57b96
    mov eax, 0x18
    call setupvlineasm
    jmp short .branch_57ba0

.branch_57b96:
    mov eax, 0x18
    call setupmvlineasm

.branch_57ba0:
    mov ebx, [esp + 0x28]
    mov ecx, [esp + 0xac]
    mov eax, [esp + 0x5c]
    mov ebp, [esp + 0x70]
    shl ebx, byte 0x8
    shl ecx, byte 0x8
    mov [engine_19901c], eax
    mov [engine_199018], eax
    mov [engine_199014], eax
    mov [engine_199010], eax
    mov [esp + 0x28], ebx
    mov [esp + 0xac], ecx
    mov [engine_19902c], ecx
    mov [engine_199028], ecx
    mov [engine_199024], ecx
    mov [engine_199020], ecx
    jmp near .branch_5853b

.branch_57bf5:
    mov byte [esp + 0xc0], 0xf
    mov eax, ecx
    sub eax, ebp
    cmp eax, 0x4
    jl short .branch_57c0b
    mov eax, 0x4

.branch_57c0b:
    mov edi, eax
    xor ecx, ecx
    jmp near .branch_57d20

.branch_57c14:
    mov eax, [esp + 0x78]
    mov edx, [esp + 0xb8]
    add edx, eax
    lea eax, [ecx + ebp]
    add eax, eax
    mov [esp + 0xb8], edx
    movsx edx, word [eax + upper_clip_edge]
    mov [esp + 0x2c], edx
    movsx edx, word [eax + lower_plane_edge]
    mov [esp + 0xb4], edx
    mov dl, [esp + 0xe0]
    and dl, 0x8
    and edx, strict dword 0xff
    jnz short .branch_57c88
    mov ebx, [esp + 0x2c]
    movsx eax, word [eax + startumost]
    cmp eax, ebx
    jng short .branch_57c6b
    mov [esp + 0x2c], eax

.branch_57c6b:
    lea eax, [ecx + ebp]
    mov esi, [esp + 0xb4]
    movsx eax, word [nosplit eax*2 + startdmost]
    cmp eax, esi
    jnl short .branch_57c88
    mov [esp + 0xb4], eax

.branch_57c88:
    mov eax, [esp + 0xb4]
    mov edx, [esp + 0x2c]
    cmp eax, edx
    jng near .branch_57d1f
    mov ebx, [esp + 0xb0]
    mov eax, edx
    mov esi, [esp + 0xac]
    sub eax, ebx
    imul eax, esi
    mov edx, [esp + 0x28]
    add edx, eax
    mov eax, [esp + 0x2c]
    mov [esp + 0xb0], eax
    mov eax, [esp + 0xb8]
    mov ebx, [esp + 0xa8]
    sar eax, byte 0x10
    imul eax, ebx
    mov [esp + 0x28], edx
    mov edx, [esp + 0xa4]
    add edx, eax
    mov bl, [esp + 0xc0]
    mov [nosplit ecx*4 + engine_199040], edx
    mov edx, [esp + 0x28]
    mov al, [ecx + pow2char]
    mov [nosplit ecx*4 + engine_199030], edx
    mov edx, [esp + 0x2c]
    not al
    mov [esp + ecx*4 + 0x10], edx
    mov edx, [esp + 0xb4]
    and bl, al
    dec edx
    mov [esp + 0xc0], bl
    mov [esp + ecx*4], edx

.branch_57d1f:
    inc ecx

.branch_57d20:
    cmp ecx, edi
    jl near .branch_57c14
    mov eax, [draw_page_address]
    add eax, ebp
    mov esi, [esp + 0x1c]
    mov [esp + 0x94], eax
    mov eax, [esp + 0x18]
    cmp eax, esi
    jng short .branch_57d46
    mov edx, eax
    jmp short .branch_57d48

.branch_57d46:
    mov edx, esi

.branch_57d48:
    mov eax, [esp + 0x10]
    mov edi, [esp + 0x14]
    cmp eax, edi
    jg short .branch_57d56
    mov eax, edi

.branch_57d56:
    cmp eax, edx
    jng short .branch_57d6a
    mov eax, [esp + 0x10]
    mov ebx, [esp + 0x14]
    cmp eax, ebx
    jg short .branch_57d78
    mov eax, ebx
    jmp short .branch_57d78

.branch_57d6a:
    mov eax, [esp + 0x18]
    mov edx, [esp + 0x1c]
    cmp eax, edx
    jg short .branch_57d78
    mov eax, edx

.branch_57d78:
    mov ecx, [esp + 0xc]
    mov [esp + 0x8c], eax
    mov eax, [esp + 0x8]
    cmp eax, ecx
    jnl short .branch_57d8f
    mov edx, eax
    jmp short .branch_57d91

.branch_57d8f:
    mov edx, ecx

.branch_57d91:
    mov eax, [esp]
    mov esi, [esp + 0x4]
    cmp eax, esi
    jl short .branch_57d9e
    mov eax, esi

.branch_57d9e:
    cmp eax, edx
    jnl short .branch_57db5
    mov eax, [esp]
    mov edx, [esp + 0x4]
    cmp eax, edx
    jnl short .branch_57db1

.branch_57dad:
    mov ecx, eax
    jmp short .branch_57dc3

.branch_57db1:
    mov ecx, edx
    jmp short .branch_57dc3

.branch_57db5:
    mov eax, [esp + 0x8]
    mov edi, [esp + 0xc]
    cmp eax, edi
    jl short .branch_57dad
    mov ecx, edi

.branch_57dc3:
    mov al, [esp + 0xe0]
    mov ebx, [esp + 0x8c]
    mov esi, [esp + 0x10]
    mov [esp + 0x88], ecx
    xor edx, edx
    and al, 0x40
    sub ebx, esi
    mov dl, al
    mov eax, esi
    dec ebx
    shl eax, byte 0x2
    test edx, edx
    jz near .branch_58197
    cmp byte [esp + 0xc0], 0x0
    jnz short .branch_57e0b
    mov edx, [esp + 0x8c]
    cmp ecx, edx
    jg near .branch_57f32

.branch_57e0b:
    mov al, [esp + 0xc0]
    and al, 0x1
    and eax, strict dword 0xff
    jnz short .branch_57e50
    mov eax, [esp + 0x10]
    mov edx, [esp + 0x94]
    mov ecx, [esp]
    mov esi, [engine_199040]
    mov ebx, [engine_199010]
    mov edi, [nosplit eax*4 + ylookup]
    sub ecx, eax
    mov eax, [engine_199020]
    add edi, edx
    mov edx, [engine_199030]
    call prevlineasm1

.branch_57e50:
    mov al, [esp + 0xc0]
    and al, 0x2
    and eax, strict dword 0xff
    jnz short .branch_57e97
    mov eax, [esp + 0x14]
    mov ecx, [esp + 0x94]
    mov esi, [engine_199044]
    mov edx, [engine_199034]
    mov edi, [nosplit eax*4 + ylookup]
    mov ebx, [engine_199014]
    add edi, ecx
    mov ecx, [esp + 0x4]
    inc edi
    sub ecx, eax
    mov eax, [engine_199024]
    call prevlineasm1

.branch_57e97:
    mov al, [esp + 0xc0]
    and al, 0x4
    and eax, strict dword 0xff
    jnz short .branch_57ee0
    mov eax, [esp + 0x18]
    mov edx, [esp + 0x94]
    mov ecx, [esp + 0x8]
    mov esi, [engine_199048]
    mov ebx, [engine_199018]
    mov edi, [nosplit eax*4 + ylookup]
    sub ecx, eax
    mov eax, [engine_199028]
    add edi, edx
    mov edx, [engine_199038]
    add edi, 0x2
    call prevlineasm1

.branch_57ee0:
    mov al, [esp + 0xc0]
    and al, 0x8
    and eax, strict dword 0xff
    jnz near .branch_58538
    mov eax, [esp + 0x1c]
    mov ecx, [esp + 0x94]
    mov esi, [engine_19904c]
    mov edx, [engine_19903c]
    mov edi, [nosplit eax*4 + ylookup]
    mov ebx, [engine_19901c]
    add edi, ecx
    mov ecx, [esp + 0xc]
    add edi, 0x3
    sub ecx, eax
    mov eax, [engine_19902c]
    call prevlineasm1
    jmp near .branch_58538

.branch_57f32:
    cmp edx, esi
    jng short .branch_57f72
    mov esi, [esp + 0x94]
    mov edx, [engine_199030]
    mov ecx, [engine_199020]
    mov edi, [eax + ylookup]
    mov eax, [engine_199010]
    mov [esp + 0x30], ecx
    add edi, esi
    mov esi, [engine_199040]
    mov ecx, ebx
    mov ebx, eax
    mov eax, [esp + 0x30]
    call prevlineasm1
    mov [engine_199030], eax

.branch_57f72:
    mov eax, [esp + 0x8c]
    mov edi, [esp + 0x14]
    cmp eax, edi
    jng short .branch_57fc1
    mov eax, [esp + 0x94]
    mov ecx, [esp + 0x8c]
    mov ebx, [esp + 0x14]
    mov esi, [engine_199044]
    mov edi, [nosplit edi*4 + ylookup]
    mov edx, [engine_199034]
    add edi, eax
    sub ecx, ebx
    mov ebx, [engine_199014]
    mov eax, [engine_199024]
    inc edi
    dec ecx
    call prevlineasm1
    mov [engine_199034], eax

.branch_57fc1:
    mov eax, [esp + 0x8c]
    mov ecx, [esp + 0x18]
    cmp eax, ecx
    jng short .branch_58010
    mov esi, [esp + 0x94]
    mov edx, [engine_199038]
    mov ebx, [engine_199018]
    mov eax, ecx
    mov edi, [nosplit ecx*4 + ylookup]
    mov ecx, [esp + 0x8c]
    add edi, esi
    mov esi, [engine_199048]
    add edi, 0x2
    sub ecx, eax
    mov eax, [engine_199028]
    dec ecx
    call prevlineasm1
    mov [engine_199038], eax

.branch_58010:
    mov eax, [esp + 0x8c]
    mov edx, [esp + 0x1c]
    cmp eax, edx
    jng short .branch_5805f
    mov ebx, [esp + 0x94]
    mov ecx, [esp + 0x8c]
    mov esi, [engine_19904c]
    mov eax, edx
    mov edi, [nosplit edx*4 + ylookup]
    mov edx, [engine_19903c]
    add edi, ebx
    sub ecx, eax
    mov ebx, [engine_19901c]
    mov eax, [engine_19902c]
    add edi, 0x3
    dec ecx
    call prevlineasm1
    mov [engine_19903c], eax

.branch_5805f:
    mov eax, [esp + 0x88]
    mov edx, [esp + 0x8c]
    cmp eax, edx
    jl short .branch_5808b
    mov ebx, [esp + 0x94]
    mov ecx, eax
    mov edi, [nosplit edx*4 + ylookup]
    sub ecx, edx
    add edi, ebx
    inc ecx
    call vlineasm4

.branch_5808b:
    mov eax, [esp + 0x88]
    mov edx, [esp + 0x94]
    add edx, [nosplit eax*4 + ylookup_second_row]
    mov eax, [esp]
    mov [esp + 0x74], edx
    cmp eax, [esp + 0x88]
    jng short .branch_580dc
    mov ebx, [esp + 0x88]
    mov edi, [esp + 0x74]
    mov esi, [engine_199040]
    mov edx, [engine_199030]
    mov ecx, eax
    mov eax, [engine_199020]
    sub ecx, ebx
    mov ebx, [engine_199010]
    dec ecx
    call prevlineasm1

.branch_580dc:
    mov eax, [esp + 0x4]
    cmp eax, [esp + 0x88]
    jng short .branch_58116
    mov edi, [esp + 0x74]
    mov esi, [engine_199044]
    mov edx, [engine_199034]
    mov ebx, [engine_199014]
    mov ecx, eax
    mov eax, [esp + 0x88]
    inc edi
    sub ecx, eax
    mov eax, [engine_199024]
    dec ecx
    call prevlineasm1

.branch_58116:
    mov eax, [esp + 0x8]
    cmp eax, [esp + 0x88]
    jng short .branch_58152
    mov edi, [esp + 0x74]
    mov ebx, [esp + 0x88]
    mov esi, [engine_199048]
    mov edx, [engine_199038]
    mov ecx, eax
    mov eax, [engine_199028]
    add edi, 0x2
    sub ecx, ebx
    mov ebx, [engine_199018]
    dec ecx
    call prevlineasm1

.branch_58152:
    mov eax, [esp + 0xc]
    cmp eax, [esp + 0x88]
    jng near .branch_58533
    mov edi, [esp + 0x74]
    mov esi, [engine_19904c]
    mov edx, [engine_19903c]
    mov ebx, [engine_19901c]
    mov ecx, eax
    mov eax, [esp + 0x88]
    add edi, 0x3
    sub ecx, eax
    mov eax, [engine_19902c]
    dec ecx
    call prevlineasm1
    jmp near .branch_58533

.branch_58197:
    cmp byte [esp + 0xc0], 0x0
    jnz short .branch_581b0
    mov edi, [esp + 0x8c]
    cmp ecx, edi
    jg near .branch_582d7

.branch_581b0:
    mov al, [esp + 0xc0]
    and al, 0x1
    and eax, strict dword 0xff
    jnz short .branch_581f5
    mov eax, [esp + 0x10]
    mov edx, [esp + 0x94]
    mov ecx, [esp]
    mov esi, [engine_199040]
    mov ebx, [engine_199010]
    mov edi, [nosplit eax*4 + ylookup]
    sub ecx, eax
    mov eax, [engine_199020]
    add edi, edx
    mov edx, [engine_199030]
    call mvlineasm1

.branch_581f5:
    mov al, [esp + 0xc0]
    and al, 0x2
    and eax, strict dword 0xff
    jnz short .branch_5823c
    mov eax, [esp + 0x14]
    mov ecx, [esp + 0x94]
    mov esi, [engine_199044]
    mov edx, [engine_199034]
    mov edi, [nosplit eax*4 + ylookup]
    mov ebx, [engine_199014]
    add edi, ecx
    mov ecx, [esp + 0x4]
    inc edi
    sub ecx, eax
    mov eax, [engine_199024]
    call mvlineasm1

.branch_5823c:
    mov al, [esp + 0xc0]
    and al, 0x4
    and eax, strict dword 0xff
    jnz short .branch_58285
    mov eax, [esp + 0x18]
    mov edx, [esp + 0x94]
    mov ecx, [esp + 0x8]
    mov esi, [engine_199048]
    mov ebx, [engine_199018]
    mov edi, [nosplit eax*4 + ylookup]
    sub ecx, eax
    mov eax, [engine_199028]
    add edi, edx
    mov edx, [engine_199038]
    add edi, 0x2
    call mvlineasm1

.branch_58285:
    mov al, [esp + 0xc0]
    and al, 0x8
    and eax, strict dword 0xff
    jnz near .branch_58538
    mov eax, [esp + 0x1c]
    mov ecx, [esp + 0x94]
    mov esi, [engine_19904c]
    mov edx, [engine_19903c]
    mov edi, [nosplit eax*4 + ylookup]
    mov ebx, [engine_19901c]
    add edi, ecx
    mov ecx, [esp + 0xc]
    add edi, 0x3
    sub ecx, eax
    mov eax, [engine_19902c]
    call mvlineasm1
    jmp near .branch_58538

.branch_582d7:
    cmp edi, esi
    jng short .branch_58317
    mov esi, [esp + 0x94]
    mov edx, [engine_199030]
    mov ecx, [engine_199020]
    mov edi, [eax + ylookup]
    mov eax, [engine_199010]
    mov [esp + 0x30], ecx
    add edi, esi
    mov esi, [engine_199040]
    mov ecx, ebx
    mov ebx, eax
    mov eax, [esp + 0x30]
    call mvlineasm1
    mov [engine_199030], eax

.branch_58317:
    mov eax, [esp + 0x8c]
    mov edi, [esp + 0x14]
    cmp eax, edi
    jng short .branch_58366
    mov eax, [esp + 0x94]
    mov ecx, [esp + 0x8c]
    mov ebx, [esp + 0x14]
    mov esi, [engine_199044]
    mov edi, [nosplit edi*4 + ylookup]
    mov edx, [engine_199034]
    add edi, eax
    sub ecx, ebx
    mov ebx, [engine_199014]
    mov eax, [engine_199024]
    inc edi
    dec ecx
    call mvlineasm1
    mov [engine_199034], eax

.branch_58366:
    mov eax, [esp + 0x8c]
    mov ecx, [esp + 0x18]
    cmp eax, ecx
    jng short .branch_583b5
    mov esi, [esp + 0x94]
    mov edx, [engine_199038]
    mov ebx, [engine_199018]
    mov eax, ecx
    mov edi, [nosplit ecx*4 + ylookup]
    mov ecx, [esp + 0x8c]
    add edi, esi
    mov esi, [engine_199048]
    add edi, 0x2
    sub ecx, eax
    mov eax, [engine_199028]
    dec ecx
    call mvlineasm1
    mov [engine_199038], eax

.branch_583b5:
    mov eax, [esp + 0x8c]
    mov edx, [esp + 0x1c]
    cmp eax, edx
    jng short .branch_58404
    mov ebx, [esp + 0x94]
    mov ecx, [esp + 0x8c]
    mov esi, [engine_19904c]
    mov eax, edx
    mov edi, [nosplit edx*4 + ylookup]
    mov edx, [engine_19903c]
    add edi, ebx
    sub ecx, eax
    mov ebx, [engine_19901c]
    mov eax, [engine_19902c]
    add edi, 0x3
    dec ecx
    call mvlineasm1
    mov [engine_19903c], eax

.branch_58404:
    mov eax, [esp + 0x88]
    mov edx, [esp + 0x8c]
    cmp eax, edx
    jl short .branch_58430
    mov ebx, [esp + 0x94]
    mov ecx, eax
    mov edi, [nosplit edx*4 + ylookup]
    sub ecx, edx
    add edi, ebx
    inc ecx
    call mvlineasm4

.branch_58430:
    mov eax, [esp + 0x88]
    mov edx, [esp + 0x94]
    add edx, [nosplit eax*4 + ylookup_second_row]
    mov eax, [esp]
    mov [esp + 0x74], edx
    cmp eax, [esp + 0x88]
    jng short .branch_58481
    mov ebx, [esp + 0x88]
    mov edi, [esp + 0x74]
    mov esi, [engine_199040]
    mov edx, [engine_199030]
    mov ecx, eax
    mov eax, [engine_199020]
    sub ecx, ebx
    mov ebx, [engine_199010]
    dec ecx
    call mvlineasm1

.branch_58481:
    mov eax, [esp + 0x4]
    cmp eax, [esp + 0x88]
    jng short .branch_584bb
    mov edi, [esp + 0x74]
    mov esi, [engine_199044]
    mov edx, [engine_199034]
    mov ebx, [engine_199014]
    mov ecx, eax
    mov eax, [esp + 0x88]
    inc edi
    sub ecx, eax
    mov eax, [engine_199024]
    dec ecx
    call mvlineasm1

.branch_584bb:
    mov eax, [esp + 0x8]
    cmp eax, [esp + 0x88]
    jng short .branch_584f7
    mov edi, [esp + 0x74]
    mov ebx, [esp + 0x88]
    mov esi, [engine_199048]
    mov edx, [engine_199038]
    mov ecx, eax
    mov eax, [engine_199028]
    add edi, 0x2
    sub ecx, ebx
    mov ebx, [engine_199018]
    dec ecx
    call mvlineasm1

.branch_584f7:
    mov eax, [esp + 0xc]
    cmp eax, [esp + 0x88]
    jng short .branch_58533
    mov edi, [esp + 0x74]
    mov esi, [engine_19904c]
    mov edx, [engine_19903c]
    mov ebx, [engine_19901c]
    mov ecx, eax
    mov eax, [esp + 0x88]
    add edi, 0x3
    sub ecx, eax
    mov eax, [engine_19902c]
    dec ecx
    call mvlineasm1

.branch_58533:
    call faketimerhandler

.branch_58538:
    add ebp, 0x4

.branch_5853b:
    mov ecx, [esp + 0x24]
    cmp ebp, ecx
    jl near .branch_57bf5
    jmp near .branch_590f2

.branch_5854c:
    mov al, [esp + 0xe0]
    and al, 0x40
    mov ecx, [esp + 0x78]
    mov esi, [esp + 0xa8]
    sar ecx, byte 0x10
    imul ecx, esi
    mov edx, [esp + 0x20]
    mov ebx, [esp + 0x20]
    mov ebp, [esp + 0x78]
    and eax, strict dword 0xff
    sar edx, byte 0x10
    shl ebx, byte 0x10
    shl ebp, byte 0x10
    add ecx, edx
    test eax, eax
    jz short .branch_585c2
    test word [esp + 0x78], 0xffff
    jnz short .branch_585ac
    mov edx, [esp + 0x5c]
    xor edi, edi
    xor esi, esi
    xor eax, eax
    mov ebp, 0x1
    call setup_sprite_horizontal_reverse
    mov [esp + 0x9c], ebp
    jmp short .branch_585cf

.branch_585ac:
    mov edx, [esp + 0x5c]
    xor edi, edi
    mov eax, ebp
    mov [esp + 0x9c], edi
    call setup_sprite_horizontal_unrolled
    jmp short .branch_585cf

.branch_585c2:
    mov edx, [esp + 0x5c]
    mov eax, ebp
    xor edi, edi
    call setup_sprite_horizontal_masked

.branch_585cf:
    mov edx, [esp + 0x70]
    add edx, edx
    movsx eax, word [edx + upper_clip_edge]
    mov [esp + 0x2c], eax
    mov al, [esp + 0xe0]
    and al, 0x8
    and eax, strict dword 0xff
    jnz short .branch_58601
    movsx eax, word [edx + startumost]
    cmp eax, [esp + 0x2c]
    jng short .branch_58601
    mov [esp + 0x2c], eax

.branch_58601:
    mov eax, [esp + 0x2c]
    mov ebp, [esp + 0x70]
    mov [esp + 0xb4], eax
    jmp near .branch_58c72

.branch_58615:
    lea eax, [ebp + ebp + 0x0]
    movsx edx, word [eax + upper_clip_edge]
    dec edx
    mov [esp + 0x98], edx
    movsx edx, word [eax + lower_plane_edge]
    mov [esp + 0x90], edx
    mov dl, [esp + 0xe0]
    and dl, 0x8
    and edx, strict dword 0xff
    jnz short .branch_5867c
    movsx eax, word [eax + startumost]
    mov ecx, [esp + 0x98]
    dec eax
    cmp eax, ecx
    jng short .branch_58662
    mov [esp + 0x98], eax

.branch_58662:
    mov esi, [esp + 0x90]
    movsx eax, word [nosplit ebp*2 + startdmost]
    cmp eax, esi
    jnl short .branch_5867c
    mov [esp + 0x90], eax

.branch_5867c:
    mov eax, [esp + 0x90]
    mov edi, [esp + 0x98]
    dec eax
    cmp eax, edi
    jng near .branch_58b01
    cmp edi, [esp + 0xb4]
    jl near .branch_5892f

.branch_586a0:
    mov eax, [esp + 0xb4]
    mov edx, [esp + 0x2c]
    dec eax
    cmp eax, edx
    jng near .branch_587dd
    lea ebx, [edx + 0x1]
    mov [esp + 0x2c], ebx
    test byte [esp + 0x2c], 0x1f
    jnz short .branch_586c7
    call faketimerhandler

.branch_586c7:
    mov eax, [esp + 0x2c]
    mov ecx, [esp + 0xb0]
    mov edx, [esp + 0xa0]
    sub eax, ecx
    imul edx, eax
    imul eax, [esp + 0xac]
    mov esi, [esp + 0xb8]
    add esi, edx
    mov ebx, esi
    sar ebx, byte 0x10
    imul ebx, [esp + 0xa8]
    mov edx, [esp + 0x28]
    xor ecx, ecx
    add edx, eax
    mov eax, [esp + 0x2c]
    mov [esp + 0xb8], esi
    mov [esp + 0xb0], eax
    mov al, [esp + 0xe0]
    mov [esp + 0x28], edx
    and al, 0x40
    mov esi, edx
    mov cl, al
    mov eax, edx
    shl esi, byte 0x10
    sar eax, byte 0x10
    mov edx, [esp + 0xb8]
    mov [esp + 0x80], eax
    shl edx, byte 0x10
    mov edi, [esp + 0x80]
    mov eax, [esp + 0x2c]
    add ebx, edi
    mov edi, [esp + 0xa4]
    shl eax, byte 0x2
    add ebx, edi
    test ecx, ecx
    jz short .branch_587b7
    cmp dword [esp + 0x9c], 0x0
    jz short .branch_58791
    mov edx, [draw_page_address]
    mov edi, [eax + ylookup]
    mov ecx, [eax + lastx]
    add edi, ebp
    mov eax, ebp
    add edi, edx
    sub eax, ecx
    mov edx, ebp
    xor ecx, ecx
    xor edx, ebp
    call draw_sprite_horizontal_reverse
    jmp near .branch_586a0

.branch_58791:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_unrolled
    jmp near .branch_586a0

.branch_587b7:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_masked
    jmp near .branch_586a0

.branch_587dd:
    mov eax, [esp + 0x98]
    mov [esp + 0x2c], eax

.branch_587e8:
    mov eax, [esp + 0xb4]
    cmp eax, [esp + 0x90]
    jng near .branch_58a94
    lea edi, [eax-0x1]
    mov [esp + 0xb4], edi
    test byte [esp + 0xb4], 0x1f
    jnz short .branch_58815
    call faketimerhandler

.branch_58815:
    mov eax, [esp + 0xb4]
    sub eax, [esp + 0xb0]
    mov edx, [esp + 0xa0]
    imul edx, eax
    imul eax, [esp + 0xac]
    mov esi, [esp + 0x28]
    mov ebx, [esp + 0xb8]
    add esi, eax
    mov eax, [esp + 0xb4]
    add ebx, edx
    mov [esp + 0xb0], eax
    mov al, [esp + 0xe0]
    xor ecx, ecx
    and al, 0x40
    mov [esp + 0xb8], ebx
    mov cl, al
    mov eax, [esp + 0xb8]
    sar eax, byte 0x10
    mov [esp + 0x7c], eax
    mov edi, [esp + 0x7c]
    imul edi, [esp + 0xa8]
    mov edx, [esp + 0xb8]
    shl edx, byte 0x10
    mov ebx, esi
    mov [esp + 0x28], esi
    sar ebx, byte 0x10
    shl esi, byte 0x10
    mov eax, [esp + 0xb4]
    add ebx, edi
    mov edi, [esp + 0xa4]
    shl eax, byte 0x2
    add ebx, edi
    test ecx, ecx
    jz near .branch_58a6e
    cmp dword [esp + 0x9c], 0x0
    jz near .branch_58a48
    mov edx, [draw_page_address]
    mov edi, [eax + ylookup]
    mov ecx, [eax + lastx]
    add edi, ebp
    mov eax, ebp
    add edi, edx
    sub eax, ecx
    mov edx, ebp
    xor ecx, ecx
    xor edx, ebp
    call draw_sprite_horizontal_reverse
    jmp near .branch_587e8

.branch_588eb:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_unrolled
    jmp short .branch_5892f

.branch_5890e:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_masked

.branch_5892f:
    mov eax, [esp + 0x2c]
    cmp eax, [esp + 0x98]
    jnl near .branch_58a25
    lea ebx, [eax + 0x1]
    mov [esp + 0x2c], ebx
    test byte [esp + 0x2c], 0x1f
    jnz short .branch_58953
    call faketimerhandler

.branch_58953:
    mov eax, [esp + 0x2c]
    mov ecx, [esp + 0xb0]
    mov edx, [esp + 0xa0]
    sub eax, ecx
    imul edx, eax
    imul eax, [esp + 0xac]
    mov esi, [esp + 0xb8]
    add esi, edx
    mov ebx, esi
    sar ebx, byte 0x10
    imul ebx, [esp + 0xa8]
    mov edx, [esp + 0x28]
    xor ecx, ecx
    add edx, eax
    mov eax, [esp + 0x2c]
    mov [esp + 0xb8], esi
    mov [esp + 0xb0], eax
    mov al, [esp + 0xe0]
    mov [esp + 0x28], edx
    and al, 0x40
    mov esi, edx
    mov cl, al
    mov eax, edx
    shl esi, byte 0x10
    sar eax, byte 0x10
    mov edx, [esp + 0xb8]
    mov [esp + 0x84], eax
    shl edx, byte 0x10
    mov edi, [esp + 0x84]
    mov eax, [esp + 0x2c]
    add ebx, edi
    mov edi, [esp + 0xa4]
    shl eax, byte 0x2
    add ebx, edi
    test ecx, ecx
    jz near .branch_5890e
    cmp dword [esp + 0x9c], 0x0
    jz near .branch_588eb
    mov edx, [draw_page_address]
    mov edi, [eax + ylookup]
    mov ecx, [eax + lastx]
    add edi, ebp
    mov eax, ebp
    add edi, edx
    sub eax, ecx
    mov edx, ebp
    xor ecx, ecx
    xor edx, ebp
    call draw_sprite_horizontal_reverse
    jmp near .branch_5892f

.branch_58a25:
    mov esi, [esp + 0x98]

.branch_58a2c:
    mov eax, [esp + 0x2c]
    cmp eax, esi
    jng near .branch_587e8
    lea edi, [eax-0x1]
    mov [nosplit eax*4 + lastx], ebp
    mov [esp + 0x2c], edi
    jmp short .branch_58a2c

.branch_58a48:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_unrolled
    jmp near .branch_587e8

.branch_58a6e:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_masked
    jmp near .branch_587e8

.branch_58a94:
    mov esi, [esp + 0x90]

.branch_58a9b:
    mov eax, [esp + 0xb4]
    cmp eax, esi
    jnl near .branch_58c4f
    lea edi, [eax + 0x1]
    mov [nosplit eax*4 + lastx], ebp
    mov [esp + 0xb4], edi
    jmp short .branch_58a9b

.branch_58abd:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_unrolled
    jmp short .branch_58b01

.branch_58ae0:
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    sub ecx, [eax + lastx]
    mov eax, ecx
    xor ecx, ecx
    call draw_sprite_horizontal_masked

.branch_58b01:
    mov eax, [esp + 0xb4]
    mov ebx, [esp + 0x2c]
    dec eax
    cmp eax, ebx
    jng near .branch_58be5
    lea eax, [ebx + 0x1]
    mov [esp + 0x2c], eax
    test byte [esp + 0x2c], 0x1f
    jnz short .branch_58b28
    call faketimerhandler

.branch_58b28:
    mov eax, [esp + 0x2c]
    sub eax, [esp + 0xb0]
    mov edx, [esp + 0xa0]
    imul edx, eax
    imul eax, [esp + 0xac]
    mov ebx, [esp + 0xb8]
    add ebx, edx
    mov [esp + 0xb8], ebx
    sar ebx, byte 0x10
    imul ebx, [esp + 0xa8]
    mov edx, [esp + 0xb8]
    mov esi, [esp + 0x28]
    shl edx, byte 0x10
    add esi, eax
    mov eax, [esp + 0x2c]
    mov [esp + 0x28], esi
    mov ecx, esi
    mov [esp + 0xb0], eax
    sar ecx, byte 0x10
    shl esi, byte 0x10
    mov al, [esp + 0xe0]
    add ebx, ecx
    and al, 0x40
    mov ecx, [esp + 0xa4]
    movzx edi, al
    mov eax, [esp + 0x2c]
    add ebx, ecx
    shl eax, byte 0x2
    test edi, edi
    jz near .branch_58ae0
    cmp dword [esp + 0x9c], 0x0
    jz near .branch_58abd
    mov edx, [draw_page_address]
    mov edi, [eax + ylookup]
    mov ecx, [eax + lastx]
    add edi, ebp
    mov eax, ebp
    add edi, edx
    sub eax, ecx
    mov edx, ebp
    xor ecx, ecx
    xor edx, ebp
    call draw_sprite_horizontal_reverse
    jmp near .branch_58b01

.branch_58be5:
    mov eax, [esp + 0x24]
    dec eax
    cmp ebp, eax
    jnz short .branch_58c10
    mov eax, [esp + 0x78]
    mov esi, [esp + 0xb8]
    mov edi, [esp + 0x28]
    add esi, eax
    add edi, [esp + 0x20]
    mov [esp + 0xb8], esi
    mov [esp + 0x28], edi
    jmp short .branch_58c7c

.branch_58c10:
    lea eax, [ebp + ebp + 0x0]
    movsx edx, word [eax + frame_state_1a3e62]
    mov [esp + 0x2c], edx
    mov dl, [esp + 0xe0]
    and dl, 0x8
    and edx, strict dword 0xff
    jnz short .branch_58c44
    mov ecx, [esp + 0x2c]
    movsx eax, word [eax + engine_1f13a2]
    cmp eax, ecx
    jng short .branch_58c44
    mov [esp + 0x2c], eax

.branch_58c44:
    mov eax, [esp + 0x2c]
    mov [esp + 0xb4], eax

.branch_58c4f:
    mov eax, [esp + 0x78]
    mov edx, [esp + 0xb8]
    mov ebx, [esp + 0x28]
    add edx, eax
    mov eax, [esp + 0x20]
    inc ebp
    add ebx, eax
    mov [esp + 0xb8], edx
    mov [esp + 0x28], ebx

.branch_58c72:
    cmp ebp, [esp + 0x24]
    jl near .branch_58615

.branch_58c7c:
    mov eax, [esp + 0xb4]
    mov esi, [esp + 0x2c]
    dec eax
    cmp eax, esi
    jng near .branch_590f2
    lea edi, [esi + 0x1]
    mov [esp + 0x2c], edi
    test byte [esp + 0x2c], 0x1f
    jnz short .branch_58ca3
    call faketimerhandler

.branch_58ca3:
    mov eax, [esp + 0x2c]
    mov ebp, [esp + 0xb0]
    mov edx, [esp + 0xa0]
    sub eax, ebp
    imul edx, eax
    imul eax, [esp + 0xac]
    mov ebx, [esp + 0xb8]
    add ebx, edx
    mov ebp, [esp + 0xa8]
    mov [esp + 0xb8], ebx
    sar ebx, byte 0x10
    imul ebx, ebp
    mov edx, [esp + 0xb8]
    mov esi, [esp + 0x28]
    shl edx, byte 0x10
    add esi, eax
    xor ecx, ecx
    mov eax, [esp + 0x2c]
    mov [esp + 0x28], esi
    mov edi, esi
    mov [esp + 0xb0], eax
    sar edi, byte 0x10
    shl esi, byte 0x10
    mov al, [esp + 0xe0]
    add ebx, edi
    and al, 0x40
    mov edi, [esp + 0xa4]
    mov cl, al
    mov eax, [esp + 0x2c]
    add ebx, edi
    shl eax, byte 0x2
    test ecx, ecx
    jz short .branch_58d8b
    cmp dword [esp + 0x9c], 0x0
    jz short .branch_58d5f
    mov edx, [esp + 0x24]
    mov ecx, [draw_page_address]
    mov edi, [eax + ylookup]
    mov ebp, [eax + lastx]
    add edi, edx
    mov eax, edx
    add edi, ecx
    sub eax, ebp
    xor edx, edx
    xor ecx, ecx
    call draw_sprite_horizontal_reverse
    jmp near .branch_58c7c

.branch_58d5f:
    mov ebp, [esp + 0x24]
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    mov ebp, [eax + lastx]
    mov eax, ecx
    sub eax, ebp
    xor ecx, ecx
    call draw_sprite_horizontal_unrolled
    jmp near .branch_58c7c

.branch_58d8b:
    mov ebp, [esp + 0x24]
    mov edi, [eax + ylookup]
    mov ecx, [draw_page_address]
    add edi, ebp
    add edi, ecx
    mov ecx, ebp
    mov ebp, [eax + lastx]
    mov eax, ecx
    sub eax, ebp
    xor ecx, ecx
    call draw_sprite_horizontal_masked
    jmp near .branch_58c7c

.branch_58db7:
    mov al, [esp + 0xe0]
    xor edx, edx
    and al, 0x1
    mov dl, al
    mov eax, [esp + 0xa0]
    mov ebp, [esp + 0xa8]
    sar eax, byte 0x10
    imul eax, ebp
    mov ecx, [esp + 0xa0]
    shl ecx, byte 0x10
    test edx, edx
    jnz short .branch_58e28
    mov dl, [esp + 0xe0]
    and dl, 0x40
    and edx, strict dword 0xff
    jz short .branch_58e10
    mov esi, [esp + 0xac]
    mov edx, ebp
    mov ebx, eax
    xor edi, edi
    mov eax, [esp + 0x5c]
    call setupspritevline
    jmp short .branch_58e5a

.branch_58e10:
    mov esi, [esp + 0xac]
    mov edx, ebp
    mov ebx, eax
    xor edi, edi
    mov eax, [esp + 0x5c]
    call msetupspritevline
    jmp short .branch_58e5a

.branch_58e28:
    mov esi, [esp + 0xac]
    mov edx, ebp
    mov ebx, eax
    xor edi, edi
    mov eax, [esp + 0x5c]
    call tsetupspritevline
    mov al, [esp + 0xe0]
    and al, 0x20
    and eax, strict dword 0xff
    jz short .branch_58e55
    call settransreverse
    jmp short .branch_58e5a

.branch_58e55:
    call settransnormal

.branch_58e5a:
    mov ebp, [esp + 0x70]
    jmp near .branch_590e8

.branch_58e63:
    mov eax, [esp + 0x78]
    mov ecx, [esp + 0xb8]
    mov esi, [esp + 0x28]
    add ecx, eax
    add esi, [esp + 0x20]
    lea eax, [ebp + ebp + 0x0]
    movsx edx, word [eax + upper_clip_edge]
    mov [esp + 0x2c], edx
    movsx edx, word [eax + lower_plane_edge]
    mov [esp + 0xb8], ecx
    mov [esp + 0xb4], edx
    mov dl, [esp + 0xe0]
    mov [esp + 0x28], esi
    and dl, 0x8
    and edx, strict dword 0xff
    jnz short .branch_58edf
    mov edi, [esp + 0x2c]
    movsx eax, word [eax + startumost]
    cmp eax, edi
    jng short .branch_58ec5
    mov [esp + 0x2c], eax

.branch_58ec5:
    mov edx, [esp + 0xb4]
    movsx eax, word [nosplit ebp*2 + startdmost]
    cmp eax, edx
    jnl short .branch_58edf
    mov [esp + 0xb4], eax

.branch_58edf:
    mov eax, [esp + 0xb4]
    mov ebx, [esp + 0x2c]
    cmp eax, ebx
    jng near .branch_590e7
    mov ecx, [esp + 0xb0]
    mov eax, ebx
    sub eax, ecx
    test eax, eax
    jl short .branch_58f0e
    jng near .branch_58fb7
    cmp eax, 0x1
    jz short .branch_58f44
    jmp short .branch_58f75

.branch_58f0e:
    cmp eax, -1
    jnz short .branch_58f75
    mov eax, [esp + 0xa0]
    mov edi, [esp + 0xb8]
    mov edx, [esp + 0x28]
    sub edi, eax
    mov eax, [esp + 0xac]
    mov [esp + 0xb0], ebx
    sub edx, eax
    mov [esp + 0xb8], edi
    mov [esp + 0x28], edx
    jmp short .branch_58fb7

.branch_58f44:
    mov eax, [esp + 0xa0]
    mov esi, [esp + 0xb8]
    mov edi, [esp + 0x28]
    add esi, eax
    mov eax, [esp + 0xac]
    mov [esp + 0xb0], ebx
    add edi, eax
    mov [esp + 0xb8], esi
    mov [esp + 0x28], edi
    jmp short .branch_58fb7

.branch_58f75:
    mov eax, [esp + 0x2c]
    sub eax, [esp + 0xb0]
    mov edx, [esp + 0xa0]
    imul edx, eax
    imul eax, [esp + 0xac]
    mov ebx, [esp + 0xb8]
    add ebx, edx
    mov esi, [esp + 0x28]
    mov [esp + 0xb8], ebx
    add esi, eax
    mov eax, [esp + 0x2c]
    mov [esp + 0x28], esi
    mov [esp + 0xb0], eax

.branch_58fb7:
    cmp byte [chainstat], 0x0
    jz short .branch_59019
    mov ebx, ebp
    and ebx, 0x3
    mov eax, 0x100
    mov cl, bl
    shl eax, cl
    mov edx, 0x3c4
    add eax, 0x2
    out dx, ax
    mov al, [esp + 0xe0]
    and al, 0x1
    and eax, strict dword 0xff
    jz short .branch_58ff7
    mov eax, ebx
    shl eax, byte 0x8
    mov edx, 0x3ce
    add eax, 0x4
    out dx, ax

.branch_58ff7:
    mov edx, ebp
    mov eax, [esp + 0x2c]
    sar edx, byte 0x2
    mov ebx, [nosplit eax*4 + ylookup]
    mov eax, [chainplace]
    add edx, ebx
    add eax, edx
    mov [esp + 0x94], eax
    jmp short .branch_59035

.branch_59019:
    mov eax, [esp + 0x2c]
    mov eax, [nosplit eax*4 + ylookup]
    mov edx, [draw_page_address]
    add eax, ebp
    add edx, eax
    mov [esp + 0x94], edx

.branch_59035:
    mov al, [esp + 0xe0]
    and al, 0x1
    mov esi, [esp + 0xb8]
    mov edi, [esp + 0xa8]
    sar esi, byte 0x10
    imul esi, edi
    mov edx, [esp + 0xb4]
    mov ecx, [esp + 0x2c]
    mov ebx, [esp + 0x28]
    sub edx, ecx
    and eax, strict dword 0xff
    mov [esp + 0x6c], edx
    mov edx, [esp + 0x28]
    shl ebx, byte 0x10
    sar edx, byte 0x10
    mov ecx, [esp + 0x6c]
    mov [esp + 0x60], edx
    inc ecx
    mov edi, [esp + 0x60]
    mov edx, [esp + 0xb8]
    add esi, edi
    mov edi, [esp + 0xa4]
    shl edx, byte 0x10
    add esi, edi
    test eax, eax
    jnz short .branch_590ca
    mov al, [esp + 0xe0]
    and al, 0x40
    and eax, strict dword 0xff
    jz short .branch_590bc
    mov edi, [esp + 0x94]
    xor eax, eax
    call spritevline
    jmp short .branch_590e2

.branch_590bc:
    mov edi, [esp + 0x94]
    call mspritevline
    jmp short .branch_590e2

.branch_590ca:
    mov edi, [esp + 0x94]
    xor eax, eax
    call tspritevline
    mov eax, [esp + 0x6c]
    add [transarea], eax

.branch_590e2:
    call faketimerhandler

.branch_590e7:
    inc ebp

.branch_590e8:
    cmp ebp, [esp + 0x24]
    jl near .branch_58e63

.branch_590f2:
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x1
    jnz short .branch_5912a
    mov al, [esp + 0xe0]
    and al, 0x80
    and eax, strict dword 0xff
    jz short .branch_5912a
    cmp dword [skip_bank_switch], 0x0
    jnz short .branch_5912a
    mov eax, [esp + 0x3c]
    mov [use_software_framebuffer], eax
    mov eax, [frame_state_286b50]
    call select_vesa_draw_page

.branch_5912a:
    add esp, strict dword 0xc4
    jmp near restore_sprite_registers
