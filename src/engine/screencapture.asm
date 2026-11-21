; Encode the current screen and palette into a capture file.
BITS 32
ORG 0x4c368

chainplace equ 0x286b4c
chainstat equ 0x14003
frameplace equ 0x286b74
qsetmode equ 0x140ba
presentation_width equ 0x287e90
presentation_height equ 0x287e8c
capture_sequence equ 0x140d3
engine_140dd equ 0x140dd
engine_140de equ 0x140de
engine_140df equ 0x140df
engine_140e0 equ 0x140e0
engine_140e1 equ 0x140e1
engine_140e2 equ 0x140e2
engine_140e3 equ 0x140e3
engine_140e4 equ 0x140e4
engine_14117 equ 0x14117
engine_14118 equ 0x14118
engine_140d5 equ 0x140d5
engine_1dda5f equ 0x1dda5f
engine_1dda60 equ 0x1dda60
engine_14155 equ 0x14155
runtime_open equ 0x61368
runtime_write equ 0x62a97
runtime_close equ 0x6219a
readpixel16 equ 0x4c293
ceiling_sprite_restore equ 0x50347

screencapture_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x18
    mov ebx, eax
    mov byte [esp + 0x14], dl
    movsx edx, word [capture_sequence]
    mov ecx, 0x3e8
    mov eax, edx
    sar edx, 0x1f
    idiv ecx
    mov edx, eax
    mov ecx, 0xa
    sar edx, 0x1f
    idiv ecx
    add edx, 0x30
    mov byte [ebx + 4], dl
    movsx edx, word [capture_sequence]
    mov ecx, 0x64
    mov eax, edx
    sar edx, 0x1f
    idiv ecx
    mov edx, eax
    mov ecx, 0xa
    sar edx, 0x1f
    idiv ecx
    add edx, 0x30
    mov byte [ebx + 5], dl
    movsx edx, word [capture_sequence]
    mov eax, edx
    sar edx, 0x1f
    idiv ecx
    mov edx, eax
    sar edx, 0x1f
    idiv ecx
    add edx, 0x30
    mov byte [ebx + 6], dl
    movsx edx, word [capture_sequence]
    mov eax, edx
    sar edx, 0x1f
    idiv ecx
    push 0x80
    push 0x261
    add edx, 0x30
    push ebx
    mov byte [ebx + 7], dl
    call runtime_open
    add esp, 0xc
    mov dword [esp + 8], eax
    cmp eax, -1
    je near .branch_51f
; C emits the mode check and both PCX geometry paths.
section .header_join align=1 vstart=0x4c4a9 follows=.text
    jmp short .branch_1a7

section .capture_body align=1 vstart=0x4c50f follows=.header_join
.branch_1a7:
    mov ebx, 0x80
    mov edx, engine_140d5
    mov eax, dword [esp + 8]
    call runtime_write
    mov ebx, dword [qsetmode]
    cmp ebx, 0xc8
    jne short .branch_1f8
    cmp byte [chainstat], 0
    je short .branch_1d9
    mov esi, dword [chainplace]
    jmp short .branch_1df

.branch_1d9:
    mov esi, dword [frameplace]

.branch_1df:
    mov ebp, dword [presentation_width]
    mov eax, dword [presentation_width]
    mov edi, dword [presentation_height]
    mov dword [esp], eax
    imul ebp, edi
    jmp short .branch_20a

.branch_1f8:
    mov eax, ebx
    mov ecx, 0x280
    lea eax, [eax + eax*4]
    mov ebp, eax
    mov dword [esp], ecx
    shl ebp, 7

.branch_20a:
    xor edi, edi
    xor ecx, ecx

.branch_20e:
    cmp ecx, ebp
    jge near .branch_40a
    mov edx, 0x61
    in al, dx
    or al, 3
    out dx, al
    mov eax, dword [qsetmode]
    lea ebx, [ecx + 1]
    cmp eax, 0xc8
    jne short .branch_276
    lea eax, [esi + 1]
    mov dl, byte [chainstat]
    mov dword [esp + 4], eax
    test dl, dl
    je short .branch_266
    mov eax, ecx
    and eax, 3
    shl eax, 8
    mov edx, 0x3ce
    add eax, 4
    out dx, ax
    xor eax, eax
    mov al, byte [esi]
    mov ecx, ebx
    mov dword [esp + 0xc], eax
    test bl, 3
    jne short .branch_29f
    mov esi, dword [esp + 4]
    jmp short .branch_29f

.branch_266:
    xor eax, eax
    mov ecx, ebx
    mov al, byte [esi]
    mov esi, dword [esp + 4]
    mov dword [esp + 0xc], eax
    jmp short .branch_29f

.branch_276:
    mov eax, ecx
    xor edx, edx
    call readpixel16
    mov dl, byte [esp + 0x14]
    mov dword [esp + 0xc], eax
    mov ecx, ebx
    cmp edx, 1
    jne short .branch_29f
    test al, 7
    je short .branch_29a
    and eax, 7
    cmp eax, 7
    jne short .branch_29f

.branch_29a:
    xor byte [esp + 0xc], 0xf

.branch_29f:
    mov edx, 1
    mov ebx, dword [qsetmode]
    mov dword [esp + 0x10], edx
    cmp ebx, 0xc8
    jne short .branch_2db
    cmp byte [chainstat], 0
    je short .branch_2d7

.branch_2bf:
    mov eax, ecx
    and eax, 3
    shl eax, 8
    mov edx, 0x3ce
    add eax, 4
    xor ebx, ebx
    out dx, ax

.branch_2d3:
    mov bl, byte [esi]
    jmp short .branch_2fe

.branch_2d7:
    xor ebx, ebx
    jmp short .branch_2d3

.branch_2db:
    mov eax, ecx

.branch_2dd:
    xor edx, edx
    call readpixel16
    mov dl, byte [esp + 0x14]
    mov ebx, eax
    cmp edx, 1
    jne short .branch_2fe
    test al, 7
    je short .branch_2fb
    and eax, 7
    cmp eax, 7
    jne short .branch_2fe

.branch_2fb:
    xor bl, 0xf

.branch_2fe:
    cmp ebx, dword [esp + 0xc]
    jne near .branch_370
    cmp ecx, ebp
    jge short .branch_370
    cmp dword [esp + 0x10], 0x3f
    jge short .branch_370
    mov ebx, dword [esp]
    mov edx, ecx
    mov eax, ecx
    sar edx, 0x1f
    idiv ebx
    test edx, edx
    je short .branch_370
    mov ebx, dword [esp + 0x10]
    lea eax, [ecx + 1]
    inc ebx
    mov ecx, dword [qsetmode]
    mov dword [esp + 0x10], ebx
    cmp ecx, 0xc8
    jne short .branch_369
    mov cl, byte [chainstat]
    lea ebx, [esi + 1]
    test cl, cl
    je short .branch_35b
    mov ecx, eax
    test al, 3
    jne near .branch_2bf
    mov esi, ebx
    jmp near .branch_2bf

.branch_35b:
    mov ecx, eax
    mov esi, ebx
    mov bl, byte [ebx]
    and ebx, 0xff
    jmp short .branch_2fe

.branch_369:
    mov ecx, eax
    jmp near .branch_2dd

.branch_370:
    mov edx, 0x61
    in al, dx
    and eax, 0xfc
    out dx, al
    cmp dword [esp + 0x10], 1
    jg short .branch_38d
    cmp dword [esp + 0xc], 0xc0
    jl short .branch_3d1

.branch_38d:
    mov al, byte [esp + 0x10]
    inc edi
    or al, 0xc0
    mov byte [edi + engine_1dda5f], al
    cmp edi, 0x1000
    jne short .branch_3d1
    mov ebx, 0x1000
    mov edx, engine_1dda60
    mov eax, dword [esp + 8]
    call runtime_write
    xor edi, edi
    cmp eax, 0x1000
    jge short .branch_3d1

.branch_3be:
    mov eax, dword [esp + 8]
    call runtime_close
    mov eax, 0xffffffff
    jmp near .branch_51f

.branch_3d1:
    inc edi
    mov al, byte [esp + 0xc]
    mov byte [edi + engine_1dda5f], al
    cmp edi, 0x1000
    jne near .branch_20e
    mov ebx, 0x1000
    mov edx, engine_1dda60
    mov eax, dword [esp + 8]
    call runtime_write
    xor edi, edi
    cmp eax, 0x1000
    jge near .branch_20e
    jmp short .branch_3be

.branch_40a:
    inc edi
    mov byte [edi + engine_1dda5f], 0xc
    cmp edi, 0x1000
    jne short .branch_436
    mov ebx, 0x1000
    mov edx, engine_1dda60
    mov eax, dword [esp + 8]
    call runtime_write
    xor edi, edi
    cmp eax, 0x1000
    jl short .branch_3be

.branch_436:
    cmp dword [qsetmode], 0xc8
    jne short .branch_491
    mov edx, 0x3c7
    xor eax, eax
    out dx, al
    xor ecx, ecx
    jmp short .branch_487

.branch_44e:
    mov edx, 0x3c9
    in al, dx
    inc edi
    shl al, 2
    mov byte [edi + engine_1dda5f], al
    cmp edi, 0x1000
    jne short .branch_486
    mov ebx, 0x1000
    mov edx, engine_1dda60
    mov eax, dword [esp + 8]
    call runtime_write
    xor edi, edi
    cmp eax, 0x1000
    jl near .branch_3be

.branch_486:
    inc ecx

.branch_487:
    cmp ecx, 0x300
    jl short .branch_44e
    jmp short .branch_4e9

.branch_491:
    xor ecx, ecx
    jmp short .branch_4e1

.branch_495:
    lea eax, [edi + 1]
    cmp ecx, 0x30
    jge short .branch_4ae
    mov dl, byte [ecx + engine_14155]
    shl dl, 2
    mov byte [edi + engine_1dda60], dl
    jmp short .branch_4b6

.branch_4ae:
    xor bl, bl
    mov byte [edi + engine_1dda60], bl

.branch_4b6:
    mov edi, eax
    cmp edi, 0x1000
    jne short .branch_4e0
    mov ebx, 0x1000
    mov edx, engine_1dda60
    mov eax, dword [esp + 8]
    call runtime_write
    xor edi, edi
    cmp eax, 0x1000
    jl near .branch_3be

.branch_4e0:
    inc ecx

.branch_4e1:
    cmp ecx, 0x300
    jl short .branch_495

.branch_4e9:
    test edi, edi
    jle short .branch_505
    mov edx, engine_1dda60
    mov eax, dword [esp + 8]
    mov ebx, edi
    call runtime_write
    cmp eax, edi
    jl near .branch_3be

.branch_505:
    mov eax, dword [esp + 8]
    call runtime_close
    mov dx, word [capture_sequence]
    inc edx
    xor eax, eax
    mov word [capture_sequence], dx

.branch_51f:
    add esp, 0x18
    jmp near ceiling_sprite_restore
