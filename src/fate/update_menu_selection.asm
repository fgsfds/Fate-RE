; Update menu selection.
BITS 32
ORG 0x39235

frame_state_12dd4 equ 0x12dd4
play_sound equ 0x34f79
presentation_input equ 0x3625c
mouse_dx equ 0x7deda
mouse_dy equ 0x7dedc
frame_state_174048 equ 0x174048
frame_state_1740f0 equ 0x1740f0
frame_state_1740f4 equ 0x1740f4
frame_state_1740f8 equ 0x1740f8
frame_state_1740fc equ 0x1740fc
frame_state_1741d6 equ 0x1741d6
frame_state_1741da equ 0x1741da

update_menu_selection:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    call presentation_input
    mov edx, [frame_state_1741da]
    mov esi, eax
    movsx eax, word [mouse_dy]
    add edx, eax
    mov [frame_state_1741da], edx
    cmp edx, 0xffffffffffffff88
    jnl short .branch_3926b
    xor ebp, ebp
    mov esi, 0x48
    mov [frame_state_1741da], ebp
    jmp short .branch_3927d

.branch_3926b:
    cmp edx, 0x78
    jng short .branch_3927d
    xor edi, edi
    mov esi, 0x50
    mov [frame_state_1741da], edi

.branch_3927d:
    movsx eax, word [mouse_dx]
    mov edx, [frame_state_1741d6]
    add edx, eax
    mov [frame_state_1741d6], edx
    cmp edx, 0xffffffffffffff9c
    jnl short .branch_392a6
    xor ebp, ebp
    mov esi, 0x4b
    mov [frame_state_1741d6], ebp
    jmp short .branch_392b8

.branch_392a6:
    cmp edx, 0x64
    jng short .branch_392b8
    xor edi, edi
    mov esi, 0x4d
    mov [frame_state_1741d6], edi

.branch_392b8:
    mov eax, esi
    and eax, 0x7f
    cmp eax, 0x48
    jc short .branch_392f4
    jna short .branch_3931b
    mov edx, [frame_state_1740f0]
    shl edx, byte 0x2
    cmp eax, 0x4d
    jc short .branch_392e6
    jna near .branch_39394
    cmp eax, 0x50
    jz near .branch_3935e
    jmp near .branch_3947f

.branch_392e6:
    cmp eax, 0x4b
    jz near .branch_393f4
    jmp near .branch_3947f

.branch_392f4:
    cmp eax, 0x1c
    jc short .branch_3930d
    jna near .branch_39444
    cmp eax, 0x39
    jz near .branch_39444
    jmp near .branch_3947f

.branch_3930d:
    cmp eax, 0x1
    jz near .branch_39464
    jmp near .branch_3947f

.branch_3931b:
    mov edx, [frame_state_1740fc]

.branch_39321:
    mov edi, [frame_state_1740f0]
    dec edi
    mov [frame_state_1740f0], edi
    test edi, edi
    jnl short .branch_3933d
    mov eax, [frame_state_1740f8]
    dec eax
    mov [frame_state_1740f0], eax

.branch_3933d:
    mov eax, 0x1
    mov cl, [frame_state_1740f0]
    shl eax, cl
    test eax, edx
    jz short .branch_39321

.branch_3934e:
    mov eax, 0x2
    xor ecx, ecx
    xor ebx, ebx

.branch_39357:
    xor edx, edx
    jmp near .branch_3947a

.branch_3935e:
    mov edx, [frame_state_1740f8]

.branch_39364:
    mov ebp, [frame_state_1740f0]
    inc ebp
    mov [frame_state_1740f0], ebp
    cmp ebp, edx
    jl short .branch_3937d
    xor ebx, ebx
    mov [frame_state_1740f0], ebx

.branch_3937d:
    mov eax, 0x1
    mov cl, [frame_state_1740f0]
    shl eax, cl
    test [frame_state_1740fc], eax
    jz short .branch_39364
    jmp short .branch_3934e

.branch_39394:
    mov eax, [edx + frame_state_174048]
    mov dx, [eax + 0x1]
    cmp dx, 0x1
    jc near .branch_3947f
    jna short .branch_393b5
    cmp dx, 0x2
    jz short .branch_393cf
    jmp near .branch_3947f

.branch_393b5:
    mov eax, [frame_state_1740f4]
    mov edx, [frame_state_1740f0]
    xor edi, edi
    mov [eax], edx
    mov [frame_state_12dd4], edi
    jmp near .branch_3947f

.branch_393cf:
    mov edx, [eax + 0xb]
    mov ebx, [eax + 0x7]
    dec edx
    cmp edx, ebx
    jng near .branch_3947f
    lea ecx, [ebx + 0x1]
    xor edx, edx
    xor ebx, ebx
    mov [eax + 0x7], ecx
    mov eax, 0x9c
    xor ecx, ecx
    jmp near .branch_3947a

.branch_393f4:
    mov eax, [edx + frame_state_174048]
    mov dx, [eax + 0x1]
    cmp dx, 0x1
    jc near .branch_3947f
    jna short .branch_39412
    cmp dx, 0x2
    jz short .branch_39429
    jmp short .branch_3947f

.branch_39412:
    mov eax, [frame_state_1740f4]
    mov edx, [frame_state_1740f0]
    xor ebx, ebx
    mov [eax], edx
    mov [frame_state_12dd4], ebx
    jmp short .branch_3947f

.branch_39429:
    mov ebp, [eax + 0x7]
    test ebp, ebp
    jng short .branch_3947f
    lea edx, [ebp-0x1]
    xor ecx, ecx
    xor ebx, ebx
    mov [eax + 0x7], edx
    mov eax, 0x9c
    jmp near .branch_39357

.branch_39444:
    mov eax, [frame_state_1740f4]
    mov edx, [frame_state_1740f0]
    xor ecx, ecx
    xor ebx, ebx
    mov [eax], edx
    mov eax, 0x4
    xor edx, edx
    mov [frame_state_12dd4], ecx
    jmp short .branch_3947a

.branch_39464:
    mov edi, 0xffffffff
    mov eax, 0x3
    xor ecx, ecx
    xor ebx, ebx
    xor edx, edx
    mov [frame_state_12dd4], edi

.branch_3947a:
    call play_sound

.branch_3947f:
    mov eax, esi
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
