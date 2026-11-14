; Read ART headers and initialize tile dimensions, animation and file offsets.
BITS 32
ORG 0x4bd46

frame_state_1401d equ 0x1401d
art_size equ 0x14021
frame_state_14025 equ 0x14025
pow2long equ 0x14031
art_file_handle equ 0x1418b
sub_40c49 equ 0x40c49
open_game_file equ 0x41281
read_game_file equ 0x4137d
close_game_file equ 0x41503
engine_malloc equ 0x4478c
restore_ebp_edi_esi_edx_ecx_ebx equ 0x4abbe
strcpy equ 0x60333
tile_file equ 0x1e3d20
picsiz equ 0x1e5fe0
tile_offset equ 0x1e6fe0
engine_1ecda0 equ 0x1ecda0
picanm equ 0x1ed3a0
tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
art_filename equ 0x2863a8
frame_state_2863ad equ 0x2863ad
frame_state_2863ae equ 0x2863ae
frame_state_2863af equ 0x2863af
frame_state_2863bc equ 0x2863bc
file_number equ 0x2863c4
file_position equ 0x2863c8
frame_state_286b30 equ 0x286b30
frame_state_286ba4 equ 0x286ba4

load_art_files:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0xc
    mov edx, eax
    mov eax, art_filename
    call strcpy
    xor edx, edx
    jmp short .branch_4bd7b

.branch_4bd5f:
    xor ecx, ecx
    mov [nosplit ebx*2 + tilesizx], cx
    mov [nosplit ebx*2 + tilesizy], cx
    xor ecx, ecx
    inc edx
    mov [nosplit ebx*4 + picanm], ecx

.branch_4bd7b:
    movsx ebx, dx
    cmp ebx, strict dword 0x1000
    jl short .branch_4bd5f
    xor edx, edx
    mov [art_size], edx
    mov [frame_state_2863bc], edx

.branch_4bd94:
    mov ax, [frame_state_2863bc]
    mov ecx, 0xa
    movsx ebx, ax
    mov [esp + 0x8], ax
    mov edx, ebx
    mov eax, ebx
    sar edx, byte 0x1f
    idiv ecx
    add edx, 0x30
    mov [frame_state_2863af], dl
    mov edx, ebx
    mov eax, ebx
    sar edx, byte 0x1f
    idiv ecx
    mov edx, eax
    sar edx, byte 0x1f
    idiv ecx
    add edx, 0x30
    mov ecx, 0x64
    mov [frame_state_2863ae], dl
    mov edx, ebx
    mov eax, ebx
    sar edx, byte 0x1f
    idiv ecx
    mov edx, eax
    mov ebx, 0xa
    sar edx, byte 0x1f
    idiv ebx
    add edx, 0x30
    mov eax, art_filename
    mov [frame_state_2863ad], dl
    xor edx, edx
    call open_game_file
    movsx ecx, ax
    mov esi, eax
    cmp ecx, -1
    jz near .branch_4bf1e
    mov ebx, 0x4
    mov edx, frame_state_286b30
    mov eax, ecx
    call read_game_file
    cmp dword [frame_state_286b30], 0x1
    jz short .branch_4be33

.branch_4be29:
    mov eax, 0xffffffff
    jmp near .branch_4c02e

.branch_4be33:
    mov ebx, 0x4
    mov edx, frame_state_286ba4
    mov eax, ecx
    call read_game_file
    mov ebx, 0x4
    lea edx, [esp + 0x4]
    mov eax, ecx
    call read_game_file
    mov ebx, 0x4
    mov edx, esp
    mov eax, ecx
    call read_game_file
    mov eax, [esp]
    mov ebp, [esp + 0x4]
    sub eax, ebp
    add eax, eax
    lea edx, [ebp + ebp + 0x0]
    lea ebx, [eax + 0x2]
    add edx, tilesizx
    mov eax, ecx
    call read_game_file
    mov ebx, [esp]
    mov eax, [esp + 0x4]
    sub ebx, eax
    add ebx, ebx
    lea edx, [eax + eax]
    add ebx, 0x2
    add edx, tilesizy
    mov eax, ecx
    call read_game_file
    mov eax, [esp]
    mov edx, [esp + 0x4]
    sub eax, edx
    shl eax, byte 0x2
    shl edx, byte 0x2
    lea ebx, [eax + 0x4]
    add edx, picanm
    mov eax, ecx
    call read_game_file
    mov ebx, [esp]
    sub ebx, [esp + 0x4]
    mov edx, [esp + 0x4]
    shl ebx, byte 0x3
    mov edi, [esp]
    add ebx, 0x18
    jmp short .branch_4bf09

.branch_4bed4:
    mov cl, [esp + 0x8]
    mov [nosplit eax*4 + tile_offset], ebx
    mov [eax + tile_file], cl
    movsx ecx, word [nosplit eax*2 + tilesizx]
    movsx eax, word [nosplit eax*2 + tilesizy]
    imul eax, ecx
    mov ecx, [art_size]
    inc edx
    add ecx, eax
    add ebx, eax
    mov [art_size], ecx

.branch_4bf09:
    movsx eax, dx
    cmp eax, edi
    jng short .branch_4bed4
    movsx eax, si
    call close_game_file
    inc dword [frame_state_2863bc]

.branch_4bf1e:
    movsx eax, word [esp + 0x8]
    mov esi, [frame_state_2863bc]
    cmp eax, esi
    jnz near .branch_4bd94
    mov ecx, 0x80
    mov edi, engine_1ecda0
    xor eax, esi
    rep stosd
    mov edi, [art_size]
    cmp edi, strict dword 0x100000
    jng short .branch_4bf51
    mov eax, edi
    jmp short .branch_4bf56

.branch_4bf51:
    mov eax, 0x100000

.branch_4bf56:
    mov [frame_state_14025], eax

.branch_4bf5b:
    mov eax, [frame_state_14025]
    call engine_malloc
    mov [frame_state_1401d], eax
    test eax, eax
    jnz short .branch_4bf8d
    mov ebp, [frame_state_14025]
    sub ebp, strict dword 0x10000
    mov [frame_state_14025], ebp
    cmp ebp, strict dword 0x10000
    jnl short .branch_4bf5b
    jmp near .branch_4be29

.branch_4bf8d:
    mov edx, [frame_state_14025]
    call sub_40c49
    xor edx, edx
    jmp near .branch_4c009

.branch_4bf9f:
    mov eax, 0xf

.branch_4bfa4:
    movsx ecx, ax
    cmp ecx, 0x1
    jng short .branch_4bfc5
    movsx ebx, dx
    mov esi, [nosplit ecx*4 + pow2long]
    movsx ebx, word [nosplit ebx*2 + tilesizx]
    cmp ebx, esi
    jnl short .branch_4bfc5
    dec eax
    jmp short .branch_4bfa4

.branch_4bfc5:
    movsx ebx, dx
    mov [ebx + picsiz], al
    mov eax, 0xf

.branch_4bfd3:
    movsx ebx, ax
    cmp ebx, 0x1
    jng short .branch_4bff4
    movsx ecx, dx
    mov edi, [nosplit ebx*4 + pow2long]
    movsx ecx, word [nosplit ecx*2 + tilesizy]
    cmp ecx, edi
    jnl short .branch_4bff4
    dec eax
    jmp short .branch_4bfd3

.branch_4bff4:
    movsx ebx, dx
    shl al, byte 0x4
    mov ah, [ebx + picsiz]
    add ah, al
    inc edx
    mov [ebx + picsiz], ah

.branch_4c009:
    movsx eax, dx
    cmp eax, strict dword 0x1000
    jl short .branch_4bf9f
    mov edx, 0xffffffff
    xor ecx, ecx
    xor eax, eax
    mov [art_file_handle], edx
    mov [file_number], edx
    mov [file_position], ecx

.branch_4c02e:
    add esp, 0xc
    jmp near restore_ebp_edi_esi_edx_ecx_ebx
