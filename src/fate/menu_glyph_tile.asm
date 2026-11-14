; Menu glyph tile.
BITS 32
ORG 0x38499


menu_glyph_tile:
    push edx
    cmp al, 0x5c
    jc short .branch_384a6
    jna short .branch_384b1
    cmp al, 0x5d
    jz short .branch_384b8
    jmp short .branch_384bf

.branch_384a6:
    cmp al, 0x5b
    jnz short .branch_384bf
    mov eax, 0x871
    pop edx
    ret

.branch_384b1:
    mov eax, 0x872
    pop edx
    ret

.branch_384b8:
    mov eax, 0x873
    pop edx
    ret

.branch_384bf:
    xor edx, edx
    mov dl, al
    cmp edx, 0x41
    jl short .branch_384d5
    cmp edx, 0x5a
    jg short .branch_384d5

.branch_384cd:
    lea eax, [edx + 0x816]
    pop edx
    ret

.branch_384d5:
    xor edx, edx
    mov dl, al
    cmp edx, 0x61
    jl short .branch_384e3
    cmp edx, 0x7a
    jng short .branch_384cd

.branch_384e3:
    xor edx, edx
    mov dl, al
    cmp edx, 0x27
    jl short .branch_384f9
    cmp edx, 0x3e
    jg short .branch_384f9
    lea eax, [edx + 0x818]
    pop edx
    ret

.branch_384f9:
    and eax, strict dword 0xff
    cmp eax, 0x5b
    jl short .branch_3850a
    add eax, strict dword 0x815
    pop edx
    ret

.branch_3850a:
    xor eax, eax
    pop edx
    ret
