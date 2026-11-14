; Trigger crusher on entry.
BITS 32
ORG 0x4052f

frame_state_1506 equ 0x1506
frame_state_1525 equ 0x1525
frame_state_1551 equ 0x1551
frame_state_1572 equ 0x1572
report_error equ 0x26a03
find_crush_sector equ 0x402d7
activate_crush_sector equ 0x40849
crusher_state equ 0x174640
numsectors equ 0x289154

trigger_crusher_on_entry:
    push ebx
    push ecx
    push esi
    mov ebx, eax
    mov ecx, edx
    test eax, eax
    jl short .branch_4053f
    cmp eax, 0x19
    jl short .branch_40549

.branch_4053f:
    mov eax, frame_state_1506
    call report_error

.branch_40549:
    mov eax, ebx
    shl eax, byte 0x7
    add eax, ebx
    mov esi, crusher_state
    shl eax, byte 0x3
    add esi, eax
    cmp dword [esi], 0x0
    jnz short .branch_40569
    mov eax, frame_state_1525
    call report_error

.branch_40569:
    test cx, cx
    jl short .branch_40577
    cmp cx, [numsectors]
    jl short .branch_40581

.branch_40577:
    mov eax, frame_state_1551
    call report_error

.branch_40581:
    movsx edx, cx
    mov eax, ebx
    call find_crush_sector
    mov edx, eax
    test eax, eax
    jl short .branch_40596
    cmp eax, 0x10
    jl short .branch_405a0

.branch_40596:
    mov eax, frame_state_1572
    call report_error

.branch_405a0:
    shl edx, byte 0x6
    cmp dword [edx + esi + 0x39], 0x1
    jz short .branch_405b4
    movsx edx, cx
    mov eax, ebx
    call activate_crush_sector

.branch_405b4:
    pop esi
    pop ecx
    pop ebx
    ret
