; Trigger tagged crushers.
BITS 32
ORG 0x405b8

frame_state_159e equ 0x159e
frame_state_15bc equ 0x15bc
frame_state_15e8 equ 0x15e8
frame_state_1608 equ 0x1608
report_error equ 0x26a03
find_crush_sector equ 0x402d7
activate_crush_sector equ 0x40849
crusher_state equ 0x174640
numsectors equ 0x289154

trigger_tagged_crushers:
    push ebx
    push ecx
    push esi
    mov ebx, eax
    mov ecx, edx
    test eax, eax
    jl short .branch_405c8
    cmp eax, 0x19
    jl short .branch_405d2

.branch_405c8:
    mov eax, frame_state_159e
    call report_error

.branch_405d2:
    mov eax, ebx
    shl eax, byte 0x7
    add eax, ebx
    mov esi, crusher_state
    shl eax, byte 0x3
    add esi, eax
    cmp dword [esi], 0x0
    jnz short .branch_405f2
    mov eax, frame_state_15bc
    call report_error

.branch_405f2:
    test cx, cx
    jl short .branch_40600
    cmp cx, [numsectors]
    jl short .branch_4060a

.branch_40600:
    mov eax, frame_state_15e8
    call report_error

.branch_4060a:
    movsx edx, cx
    mov eax, ebx
    call find_crush_sector
    mov edx, eax
    test eax, eax
    jl short .branch_4061f
    cmp eax, 0x10
    jl short .branch_40629

.branch_4061f:
    mov eax, frame_state_1608
    call report_error

.branch_40629:
    mov eax, edx
    shl eax, byte 0x6
    add eax, esi
    mov esi, [eax + 0x39]
    cmp esi, 0x1
    jz short .branch_4063d
    movsx edx, cx
    jmp short .branch_40657

.branch_4063d:
    cmp esi, esi
    jnz short .branch_4065e
    cmp esi, [eax + 0x3d]
    jnz short .branch_40651
    mov dword [eax + 0x3d], 0x0
    pop esi
    pop ecx
    pop ebx
    ret

.branch_40651:
    movsx edx, cx
    mov [eax + 0x3d], esi

.branch_40657:
    mov eax, ebx
    call activate_crush_sector

.branch_4065e:
    pop esi
    pop ecx
    pop ebx
    ret
