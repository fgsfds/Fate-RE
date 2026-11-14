; Load the palette, shade lookup and translucency tables once.
BITS 32
ORG 0x4a367

palette_filename equ 0x1a47
frame_state_1401c equ 0x1401c
translucency_table equ 0x140be
palette_loaded equ 0x140c2
allocache equ 0x40c73
open_game_file equ 0x41281
read_game_file equ 0x4137d
close_game_file equ 0x41503
engine_malloc equ 0x4478c
sub_59582 equ 0x59582
setpalookupaddress equ 0x740e0
fixtransluscence equ 0x743a0
palookup equ 0x203ca0
palette equ 0x27c0a0
globalpal equ 0x286adc
current_palookup equ 0x286af0
numpalookups equ 0x289156

load_palette_tables:
    push ebx
    push ecx
    push edx
    push esi
    cmp byte [palette_loaded], 0x0
    jnz near .branch_4a47b
    mov eax, palette_filename
    xor edx, edx
    call open_game_file
    mov ecx, eax
    mov esi, eax
    cmp eax, -1
    jz near .branch_4a47b
    mov ebx, 0x300
    mov edx, palette
    call read_game_file
    mov ebx, 0x2
    mov edx, numpalookups
    mov eax, ecx
    call read_game_file
    movsx eax, word [numpalookups]
    shl eax, byte 0x8
    call engine_malloc
    mov [palookup], eax
    test eax, eax
    jnz short .branch_4a3e2
    mov ebx, frame_state_1401c
    movsx edx, word [numpalookups]
    mov eax, palookup
    shl edx, byte 0x8
    call allocache

.branch_4a3e2:
    mov eax, 0x10000
    call engine_malloc
    mov [translucency_table], eax
    test eax, eax
    jnz short .branch_4a409
    mov ebx, frame_state_1401c
    mov edx, 0x10000
    mov eax, translucency_table
    call allocache

.branch_4a409:
    mov eax, [palookup]
    xor edx, edx
    mov [current_palookup], eax
    mov [globalpal], edx
    call setpalookupaddress
    mov eax, [translucency_table]
    call fixtransluscence
    movsx ebx, word [numpalookups]
    mov eax, [globalpal]
    shl ebx, byte 0x8
    mov edx, [nosplit eax*4 + palookup]
    mov eax, esi
    call read_game_file
    mov ebx, 0x10000
    mov edx, [translucency_table]
    mov eax, esi
    call read_game_file
    mov ebx, 0xb
    mov eax, esi
    mov edx, 0x3b
    call close_game_file
    mov eax, 0x1e
    call sub_59582
    mov byte [palette_loaded], 0x1

.branch_4a47b:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
