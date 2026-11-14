; Update palette fade.
BITS 32
ORG 0x366f2

fade_level equ 0x12d14
qsetmode equ 0x140ba
palette_fade_shared_return equ 0x36587
scale_fade_palette equ 0x365b6
update_palette_entry equ 0x40b82
flush_palette equ 0x40b99
frame_state_171614 equ 0x171614
frame_state_172214 equ 0x172214
frame_state_173114 equ 0x173114
frame_state_173d14 equ 0x173d14
frame_state_173d18 equ 0x173d18
frame_state_173d1c equ 0x173d1c
frame_state_173d20 equ 0x173d20
frame_state_173d24 equ 0x173d24
frame_state_173d28 equ 0x173d28
frame_state_173d2c equ 0x173d2c
brightness_palette equ 0x27c0a0
totalclock equ 0x287e88

update_palette_fade:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    xor ebx, ebx
    xor edi, edi
    xor esi, esi
    xor eax, eax
    mov ecx, [totalclock]
    sub ecx, [frame_state_173d2c]
    mov edx, [totalclock]
    mov ebp, [frame_state_173d18]
    mov [frame_state_173d2c], edx
    test ebp, ebp
    jz short .branch_3675f
    mov eax, [fade_level]
    call scale_fade_palette
    mov ebp, [fade_level]
    test ebp, ebp
    jnz short .branch_36741
    mov [frame_state_173d18], ebx
    jmp near .branch_367ab

.branch_36741:
    mov eax, [frame_state_173d24]
    imul eax, ecx
    mov edx, ebp
    sub edx, eax
    mov [fade_level], edx
    test edx, edx
    jnl short .branch_367ab
    mov [fade_level], ebx
    jmp short .branch_367ab

.branch_3675f:
    cmp dword [frame_state_173d14], 0x0
    jz short .branch_367b0
    mov eax, [fade_level]
    call scale_fade_palette
    mov ebp, [fade_level]
    cmp ebp, strict dword 0xff
    jnz short .branch_36788
    mov [frame_state_173d14], ebx
    jmp short .branch_367ab

.branch_36788:
    mov eax, [frame_state_173d24]
    imul eax, ecx
    lea edx, [eax + ebp]
    mov [fade_level], edx
    cmp edx, strict dword 0xff
    jng short .branch_367ab
    mov dword [fade_level], 0xff

.branch_367ab:
    mov eax, 0x1

.branch_367b0:
    test eax, eax
    jnz short .branch_367d3
    cmp dword [frame_state_173d1c], 0x0
    jg short .branch_367d3
    cmp dword [frame_state_173d28], 0x0
    jg short .branch_367d3
    cmp dword [frame_state_173d20], 0x0
    jng near palette_fade_shared_return

.branch_367d3:
    mov ebp, [frame_state_173d1c]
    test ebp, ebp
    jng short .branch_3680f
    mov eax, ebp
    sub eax, ecx
    mov [frame_state_173d1c], eax
    test eax, eax
    jnl short .branch_367f2
    xor ebx, ebx
    mov [frame_state_173d1c], ebx

.branch_367f2:
    mov eax, [frame_state_173d1c]
    mov edx, eax
    mov ebx, 0xa
    sar edx, byte 0x1f
    idiv ebx
    mov ebx, eax
    cmp eax, 0x4
    jl short .branch_3680f
    mov ebx, 0x3

.branch_3680f:
    mov ebp, [frame_state_173d28]
    test ebp, ebp
    jng short .branch_3684b
    mov eax, ebp
    sub eax, ecx
    mov [frame_state_173d28], eax
    test eax, eax
    jnl short .branch_3682e
    xor edi, edi
    mov [frame_state_173d28], edi

.branch_3682e:
    mov eax, [frame_state_173d28]
    mov edx, eax
    mov edi, 0xa
    sar edx, byte 0x1f
    idiv edi
    mov edi, eax
    cmp eax, 0x4
    jl short .branch_3684b
    mov edi, 0x3

.branch_3684b:
    mov ebp, [frame_state_173d20]
    test ebp, ebp
    jng short .branch_36887
    mov eax, ebp
    sub eax, ecx
    mov [frame_state_173d20], eax
    test eax, eax
    jnl short .branch_3686a
    xor ecx, ecx
    mov [frame_state_173d20], ecx

.branch_3686a:
    mov eax, [frame_state_173d20]
    mov edx, eax
    mov ecx, 0xa
    sar edx, byte 0x1f
    idiv ecx
    mov esi, eax
    cmp eax, 0x4
    jl short .branch_36887
    mov esi, 0x3

.branch_36887:
    test ebx, ebx
    jng short .branch_368b7
    cmp dword [qsetmode], strict dword 0xc8
    jnz short .branch_368b7
    mov ecx, 0x1
    call update_palette_entry
    mov eax, ebx
    shl eax, byte 0x2
    sub eax, ebx
    mov esi, frame_state_171614

.branch_368ad:
    shl eax, byte 0x8
    add esi, eax
    jmp near .branch_36926

.branch_368b7:
    test edi, edi
    jng short .branch_368df
    cmp dword [qsetmode], strict dword 0xc8
    jnz short .branch_368df
    mov ecx, 0x1
    call update_palette_entry
    mov eax, edi
    shl eax, byte 0x2
    sub eax, edi
    mov esi, frame_state_172214
    jmp short .branch_368ad

.branch_368df:
    test esi, esi
    jng short .branch_36907
    cmp dword [qsetmode], strict dword 0xc8
    jnz short .branch_36907
    mov ecx, 0x1
    call update_palette_entry
    mov eax, esi
    shl eax, byte 0x2
    sub eax, esi
    mov esi, frame_state_173114
    jmp short .branch_368ad

.branch_36907:
    cmp dword [qsetmode], strict dword 0xc8
    jnz near palette_fade_shared_return
    mov ecx, 0x1
    mov esi, brightness_palette
    call update_palette_entry

.branch_36926:
    call flush_palette
    jmp near palette_fade_shared_return
