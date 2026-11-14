; Initialize game sound slots and their playback settings.
BITS 32
ORG 0x34b13

sound_cache_error equ 0x831
report_error equ 0x26a03
frame_state_8531c equ 0x8531c
frame_state_854dc equ 0x854dc
frame_state_8551c equ 0x8551c
frame_state_16fdac equ 0x16fdac
frame_state_16fdb0 equ 0x16fdb0

initialize_sound_slots:
    push ebx
    push ecx
    push edx
    push esi
    xor ebx, ebx

.branch_34b19:
    mov eax, ebx
    shl eax, byte 0x3
    sub eax, ebx
    shl eax, byte 0x2
    add eax, frame_state_8531c
    mov [nosplit ebx*4 + frame_state_854dc], eax
    mov dword [eax], 0xffffffff
    mov eax, [nosplit ebx*4 + frame_state_854dc]
    mov dword [eax + 0x4], 0x0
    mov eax, [nosplit ebx*4 + frame_state_854dc]
    mov byte [eax + 0xc], 0xff
    mov eax, ebx
    shl eax, byte 0x5
    sub eax, ebx
    shl eax, byte 0x2
    add eax, ebx
    shl eax, byte 0x5
    mov ecx, eax
    shl eax, byte 0x4
    sub eax, ecx
    mov ecx, frame_state_8551c
    add ecx, eax
    mov eax, [nosplit ebx*4 + frame_state_854dc]
    mov [eax + 0x8], ecx
    mov eax, [nosplit ebx*4 + frame_state_854dc]
    cmp dword [eax + 0x8], 0x0
    jnz short .branch_34b90
    mov byte [eax + 0xc], 0x0
    mov eax, sound_cache_error
    call report_error

.branch_34b90:
    mov edx, [nosplit ebx*4 + frame_state_854dc]
    mov esi, [edx + 0x8]
    mov [nosplit ebx*8 + frame_state_16fdac], esi
    mov esi, 0xffffffff
    mov [nosplit ebx*8 + frame_state_16fdb0], esi
    mov word [edx + 0xe], 0x0
    mov edx, [nosplit ebx*4 + frame_state_854dc]
    mov dword [edx + 0x10], 0x0
    mov edx, [nosplit ebx*4 + frame_state_854dc]
    mov dword [edx + 0x14], 0x0
    mov edx, [nosplit ebx*4 + frame_state_854dc]
    mov dword [edx + 0x18], 0x0
    mov eax, [nosplit ebx*4 + frame_state_854dc]
    inc ebx
    mov [eax + 0x4], esi
    cmp ebx, 0x10
    jl near .branch_34b19
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
