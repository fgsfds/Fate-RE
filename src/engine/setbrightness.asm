; Update the shade table when required and write the brightness-adjusted VGA palette.
BITS 32
ORG 0x59bee

current_brightness equ 0x14018
video_mode equ 0x286b24
palookup equ 0x203ca0
brightness_table equ 0x1c1d60
ceilspritescan_return equ 0x50344
dac_index equ 0x3c8
dac_data equ 0x3c9

setbrightness_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 4
    mov edi, edx
    and eax, 0xff
    mov dword [current_brightness], eax
    test eax, eax
    jge short .check_ceiling
    xor ebx, ebx
    mov dword [current_brightness], ebx

.check_ceiling:
    cmp dword [current_brightness], 0xf
    jle short .select_mode
    mov dword [current_brightness], 0xf

.select_mode:
    cmp dword [video_mode], 7
    jne near .rgb_dac
    mov ebp, 0xf
    xor ecx, ecx
    jmp short .next_color

.shade_color:
    mov eax, ecx
    shl eax, 2
    mov edx, ecx
    sub eax, ecx
    xor edx, ecx
    xor ebx, ebx
    mov dl, byte [edi + eax + 1]
    mov bl, byte [edi + eax]
    movzx esi, byte [edi + eax + 2]
    add edx, ebx
    mov eax, dword [palookup]
    add esi, edx
    add eax, ecx
    xor ebx, ebx
    sar esi, 1
    jmp short .next_shade

.shade_level:
    mov edx, 0x1f
    sub edx, ebx
    imul edx, esi
    sar edx, 7
    mov dword [esp], edx
    cmp edx, 0xf
    jle short .write_shade
    mov dword [esp], ebp

.write_shade:
    mov dl, byte [esp]
    inc ebx
    mov byte [eax], dl
    add eax, 0x100

.next_shade:
    cmp ebx, 0x20
    jl short .shade_level
    inc ecx

.next_color:
    cmp ecx, 0x100
    jl short .shade_color
    mov edx, dac_index
    xor eax, eax
    out dx, al
    xor ebx, ebx
    jmp short .dac_next_row

.dac_row:
    xor ecx, ecx
    jmp short .dac_next_color

.dac_color:
    mov eax, dword [current_brightness]
    mov edx, ecx
    shl eax, 6
    mov al, byte [eax + edx*4 + brightness_table]
    mov edx, dac_data
    and eax, 0xff
    out dx, al
    xor eax, eax
    out dx, al
    mov edx, dword [current_brightness]
    mov eax, ebx
    shl edx, 6
    mov al, byte [edx + eax*4 + brightness_table]
    mov edx, dac_data
    and eax, 0xff
    out dx, al
    inc ecx

.dac_next_color:
    cmp ecx, 0x10
    jl short .dac_color
    inc ebx

.dac_next_row:
    cmp ebx, 0x10
    jl short .dac_row
    jmp ceilspritescan_return

.rgb_dac:
    mov edx, dac_index
    xor eax, eax
    out dx, al
    xor ecx, ecx
    jmp short .rgb_next_component

.rgb_component:
    mov al, byte [ecx + edi]
    mov edx, dword [current_brightness]
    and eax, 0xff
    shl edx, 6
    mov al, byte [edx + eax + brightness_table]
    mov edx, dac_data
    and eax, 0xff
    out dx, al
    inc ecx

.rgb_next_component:
    cmp ecx, 0x300
    jl short .rgb_component
    jmp ceilspritescan_return
