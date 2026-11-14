; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. Adapted for FATE's ART file cache.
BITS 32
ORG 0x4bb0d
widths equ 0x1f2020
heights equ 0x1f4020
tile_file equ 0x1e3d20
tile_offset equ 0x1e6fe0
tile_pixels equ 0x1ffca0
tile_lock equ 0x1f8ca0
file_number equ 0x2863c4
file_position equ 0x2863c8
file_name equ 0x2863a8
handle equ 0x1418b
debug_tiles equ 0x1418f
print_format equ 0x1bd5
close_art equ 0x41503
open_art equ 0x41281
seek_art equ 0x41451
read_art equ 0x4137d
timer equ 0x31ec4
printf equ 0x40bb4
allocache equ 0x40c73
shared_return equ 0x4abbe

loadtile_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ecx,eax
    test ax,ax
    jl near shared_return
    movsx ebx,ax
    cmp ebx,4096
    jge near shared_return
    movsx eax,word [nosplit ebx*2+widths]
    movsx esi,word [nosplit ebx*2+heights]
    imul esi,eax
    test esi,esi
    jle near shared_return
    mov bl,[ebx+tile_file]
    mov edx,[file_number]
    and ebx,255
    cmp ebx,edx
    je near .diagnostic
    mov edi,[handle]
    cmp edi,-1
    je .digits
    mov eax,edi
    call close_art
.digits:
    ; Construct the three decimal digits of the ART name.
    mov edi,10
    mov edx,ebx
    mov eax,ebx
    sar edx,31
    idiv edi
    add edx,48
    mov [file_name+7],dl
    mov edx,ebx
    mov eax,ebx
    sar edx,31
    idiv edi
    mov edx,eax
    sar edx,31
    idiv edi
    add edx,48
    mov edi,100
    mov [file_name+6],dl
    mov edx,ebx
    mov eax,ebx
    sar edx,31
    idiv edi
    mov [file_number],ebx
    mov edx,eax
    mov ebx,10
    sar edx,31
    idiv ebx
    xor ebp,ebp
    add edx,48
    mov eax,file_name
    mov [file_name+5],dl
    xor edx,edx
    mov [file_position],ebp
    call open_art
    mov [handle],eax
    call timer
.diagnostic:
    cmp byte [debug_tiles],0
    je .cache
    movsx eax,cx
    push eax
    push dword print_format
    call printf
    add esp,8
.cache:
    movsx edx,cx
    mov ebx,edx
    shl ebx,2
    cmp dword [ebx+tile_pixels],0
    jne .position
    mov byte [edx+tile_lock],199
    mov eax,tile_pixels
    add edx,tile_lock
    add eax,ebx
    mov ebx,edx
    mov edx,esi
    call allocache
.position:
    movsx edx,cx
    shl edx,2
    mov eax,[file_position]
    mov ebx,[edx+tile_offset]
    cmp eax,ebx
    je .read
    mov edx,ebx
    mov ebx,1
    sub edx,eax
    mov eax,[handle]
    call seek_art
    call timer
.read:
    mov eax,[handle]
    movsx ecx,cx
    mov ebx,esi
    mov edx,[nosplit ecx*4+tile_pixels]
    call read_art
    call timer
    mov eax,[nosplit ecx*4+tile_offset]
    add eax,esi
    mov [file_position],eax
    jmp near shared_return
