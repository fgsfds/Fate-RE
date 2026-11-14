; Order two overlapping wall bunches using their representative scans.
BITS 32
ORG 0x45576

bunchlast equ 0x1d9560
bunchfirst equ 0x1d7560
xb2 equ 0x1c3160
xb1 equ 0x1c5160
p2 equ 0x1d8560
wallfront equ 0x45313

bunchfront_:
    push ebx
    push ecx
    push esi
    push edi
    mov ebx, eax
    mov eax, edx
    add eax, eax
    mov edx, ebx
    movsx ebx, word [eax + bunchlast]
    add edx, edx
    mov ebx, dword [ebx*4 + xb2]
    movsx edi, word [edx + bunchfirst]
    inc ebx
    mov ecx, dword [edi*4 + xb1]
    cmp ecx, ebx
    jl short .branch_039

.branch_02f:
    mov eax, 0xffffffff
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

.branch_039:
    movsx esi, word [eax + bunchfirst]
    movsx eax, word [edx + bunchlast]
    mov eax, dword [eax*4 + xb2]
    mov ebx, dword [esi*4 + xb1]
    inc eax
    cmp ebx, eax
    jge short .branch_02f
    cmp ecx, ebx
    jl short .branch_079
    mov eax, esi
    jmp short .branch_06a

.branch_062:
    movsx eax, word [nosplit eax*2 + p2]

.branch_06a:
    cmp ecx, dword [eax*4 + xb2]
    jg short .branch_062
    mov edx, eax
    mov eax, edi
    jmp short .branch_090

.branch_079:
    mov eax, edi
    jmp short .branch_085

.branch_07d:
    movsx eax, word [nosplit eax*2 + p2]

.branch_085:
    cmp ebx, dword [eax*4 + xb2]
    jg short .branch_07d
    mov edx, esi

.branch_090:
    call wallfront
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
