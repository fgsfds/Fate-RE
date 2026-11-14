; Teleport a sprite and refresh its saved coordinates and visibility.
BITS 32
ORG 0x2e9ec

projectile_positions equ 0x20a2c
resolve_teleport_destination equ 0x2e7f7
change_sprite_sector equ 0x50bc3
engine_1ec6a0 equ 0x1ec6a0
sprite_visibility equ 0x1ecfa0
sprite equ 0x2040a0
sprite_sector equ 0x2040b8

teleport_sprite:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    push eax
    movsx ebp, ax
    imul esi, ebp, 0x2c
    mov ax, [esi + sprite_sector]
    add esi, sprite
    lea ecx, [esi + 0x1c]
    mov [esp + 0x4], eax
    lea ebx, [esi + 0x8]
    lea eax, [esp + 0x4]
    lea edx, [esi + 0x4]
    push eax
    mov eax, esi
    call resolve_teleport_destination
    mov eax, ebp
    shl eax, byte 0x2
    sub eax, ebp
    mov edi, projectile_positions
    shl eax, byte 0x2
    mov ecx, 0x3
    add edi, eax
    rep movsd
    movsx edx, word [esp + 0x4]
    mov eax, ebp
    mov cl, [esp]
    call change_sprite_sector
    mov dl, 0x1
    and cl, 0x7
    mov eax, ebp
    shl dl, cl
    sar eax, byte 0x3
    mov dh, dl
    mov bl, [eax + sprite_visibility]
    not dh
    and bl, dh
    mov [eax + sprite_visibility], bl
    movsx ebx, word [esp + 0x4]
    sar ebx, byte 0x3
    mov bl, [ebx + engine_1ec6a0]
    mov ecx, [esp + 0x4]
    xor ch, ch
    and cl, 0x7
    mov esi, 0x1
    movsx ecx, cx
    and ebx, strict dword 0xff
    shl esi, cl
    test ebx, esi
    jz short .branch_2ea98
    or [eax + sprite_visibility], dl

.branch_2ea98:
    add esp, 0x8
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
