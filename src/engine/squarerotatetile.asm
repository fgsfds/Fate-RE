; Transpose the cached pixels of a square tile in place.
BITS 32
ORG 0x5d5a2

tilesizx equ 0x1f2020
tilesizy equ 0x1f4020
waloff equ 0x1ffca0
rotate_tile_restore equ 0x4d6c2

squarerotatetile_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x10
    push eax
    cwde
    movsx edi, word [nosplit eax*2 + tilesizx]
    movsx eax, word [nosplit eax*2 + tilesizy]
    mov dword [esp + 0xc], edi
    cmp eax, edi
    jne near rotate_tile_restore
    lea eax, [edi + edi]
    mov dword [esp + 8], eax
    lea eax, [edi - 1]
    mov dword [esp + 4], eax
    jmp short .check_column

.transpose_column:
    mov ebp, dword [esp + 0xc]
    inc ebp
    imul ebp, ebx
    movsx edi, word [esp]
    mov edi, dword [edi*4 + waloff]
    add edi, ebp
    mov ah, byte [esp + 4]
    mov ebp, edi
    test ah, 1
    je short .prepare_pixel_pairs
    ; Swap the first pixel separately when the count is odd.
    mov esi, dword [esp + 0xc]
    dec edi
    sub ebp, esi
    mov eax, edi
    mov ebx, ebp
    mov cl, byte [eax]
    mov ch, byte [ebx]
    mov byte [ebx], cl
    mov byte [eax], ch

.prepare_pixel_pairs:
    mov eax, dword [esp + 4]
    sar eax, 1
    dec eax
    mov dword [esp + 0x10], eax
    jmp short .check_pixel_pair

.swap_pixel_pair:
    ; Swap two adjacent pixels against two strided pixels.
    mov ebx, dword [esp + 8]
    mov esi, dword [esp + 0xc]
    sub edi, 2
    sub ebp, ebx
    mov eax, edi
    mov ebx, ebp
    add esi, ebx
    mov cx, word [eax]
    mov dl, byte [ebx]
    mov byte [ebx], cl
    mov dh, byte [esi]
    mov byte [esi], ch
    mov word [eax], dx
    dec dword [esp + 0x10]

.check_pixel_pair:
    cmp dword [esp + 0x10], 0
    jge short .swap_pixel_pair
    dec dword [esp + 4]

.check_column:
    mov ebx, dword [esp + 4]
    test ebx, ebx
    jge short .transpose_column
    jmp near rotate_tile_restore
