; Prepare texture and lighting state for a horizontal plane span.
BITS 32
ORG 0x4a7f3

chainplace equ 0x286b4c
chainstat equ 0x14003
frameplace equ 0x286b74
row_offset equ 0x286bb0
pow2char equ 0x14029
globalhoriz equ 0x286ae4
globalshade equ 0x286a88
globalxpanning equ 0x286abc
globalzd equ 0x286a8c
globvis equ 0x286ab8
ylookup equ 0x286ae8
lastx equ 0x197d50
texture_step_x equ 0x286aa4
texture_step_y equ 0x286aa8
globalx1 equ 0x286a80
globalx2 equ 0x286a4c
globaly1 equ 0x286a50
globaly2 equ 0x286a58
globalypanning equ 0x286ac0
horizycent equ 0x286ae0
horizlookup equ 0x286aec
getpalookup equ 0x5fed7
setuphlineasm4 equ 0x74110
hlineasm4 equ 0x74150
span_return equ 0x4551f

hline_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x24
    push eax
    mov esi, edx
    mov ecx, edx
    shl ecx, 2
    mov ebp, dword [ecx + lastx]
    cmp ebp, eax
    jg near span_return
    mov ebx, dword [globalhoriz]
    mov eax, edx
    mov edi, dword [horizycent]
    sub eax, ebx
    lea ebx, [eax + edi]
    mov eax, dword [horizlookup]
    shl ebx, 2
    mov ebx, dword [ebx + eax]
    mov eax, dword [globalzd]
    imul ebx
    shrd eax, edx, 0xa
    mov edi, eax
    mov eax, dword [globalx1]
    mov ebx, edi
    imul ebx
    shrd eax, edx, 8
    mov dword [texture_step_x], eax
    mov eax, dword [globaly2]
    imul ebx
    shrd eax, edx, 8
    mov dword [texture_step_y], eax
    mov eax, dword [globalx1]
    imul eax, ebp
    add eax, dword [globaly1]
    cmp byte [chainstat], 0
    jne near .branch_111
    mov ebx, dword [ecx + row_offset]
    mov esi, dword [frameplace]
    add ebx, ebp
    mov ecx, dword [ylookup]
    add ebx, esi
    add ecx, ebx
    mov ebx, edi
    imul ebx
    shrd eax, edx, 8
    mov esi, dword [globalxpanning]
    add esi, eax
    mov eax, dword [globaly2]
    imul eax, ebp
    add eax, dword [globalx2]
    imul ebx
    shrd eax, edx, 8
    mov ebx, dword [globalypanning]
    mov dword [esp + 4], ecx
    add ebx, eax
    mov ecx, dword [globalshade]
    mov dword [esp + 8], ebx
    mov eax, edi
    mov ebx, dword [globvis]
    test eax, eax
    jns short .branch_0e6
    neg eax

.branch_0e6:
    imul ebx
    shrd eax, edx, 0x12
    mov edx, ecx
    mov edi, dword [esp + 4]
    call getpalookup
    xor ebx, ebx
    mov edx, dword [esp + 8]
    mov ecx, eax
    mov eax, dword [esp]
    shl ecx, 8
    sub eax, ebp
    call hlineasm4
    jmp near span_return

.branch_111:
    imul ebx
    shrd eax, edx, 8
    mov ebx, dword [globalxpanning]
    add ebx, eax
    mov eax, dword [globaly2]
    imul eax, ebp
    mov dword [esp + 0x24], ebx
    add eax, dword [globalx2]
    mov ebx, edi
    imul ebx
    shrd eax, edx, 8
    mov ebx, dword [globalypanning]
    add ebx, eax
    mov ecx, dword [globalshade]
    mov dword [esp + 0x20], ebx
    mov eax, edi
    mov ebx, dword [globvis]
    test eax, eax
    jns short .branch_159
    neg eax

.branch_159:
    imul ebx
    shrd eax, edx, 0x12
    mov edx, ecx
    call getpalookup
    shl eax, 8
    mov dword [esp + 0xc], eax
    mov eax, dword [texture_step_x]
    mov dword [esp + 0x1c], eax
    shl eax, 2
    mov dword [texture_step_x], eax
    mov eax, dword [texture_step_y]
    mov ebx, dword [esp]
    mov dword [esp + 0x18], eax
    shl eax, 2
    inc ebx
    mov dword [texture_step_y], eax
    lea eax, [ebp + 4]
    cmp ebx, eax
    jge short .branch_19c
    mov eax, ebx

.branch_19c:
    mov ecx, dword [chainplace]
    mov dword [esp + 0x14], eax
    mov eax, dword [esi*4 + row_offset]
    add eax, ecx
    mov ebx, dword [texture_step_y]
    mov dword [esp + 0x10], eax
    mov eax, dword [texture_step_x]
    call setuphlineasm4

.branch_1c3:
    cmp ebp, dword [esp + 0x14]
    jge near span_return
    mov eax, dword [ylookup]
    add eax, ebp
    and eax, 3
    mov al, byte [eax + pow2char]
    mov edx, 0x3c5
    and eax, 0xff
    out dx, al
    mov eax, dword [ylookup]
    mov edi, dword [esp + 0x10]
    add eax, ebp
    mov esi, dword [esp + 0x24]
    sar eax, 2
    mov ecx, dword [esp + 0xc]
    add edi, eax
    mov eax, dword [esp]
    mov ebx, 0xffffffff
    sub eax, ebp
    mov edx, dword [esp + 0x20]
    sar eax, 2
    call hlineasm4
    mov eax, dword [esp + 0x1c]
    mov ecx, dword [esp + 0x24]
    mov esi, dword [esp + 0x20]
    add ecx, eax
    mov eax, dword [esp + 0x18]
    inc ebp
    add esi, eax
    mov dword [esp + 0x24], ecx
    mov dword [esp + 0x20], esi
    jmp short .branch_1c3
