; Parse video mode.
BITS 32
ORG 0x36bfc

frame_state_12d30 equ 0x12d30
frame_state_12d48 equ 0x12d48
frame_state_12d4e equ 0x12d4e
frame_state_12d60 equ 0x12d60
frame_state_12d64 equ 0x12d64
stricmp equ 0x62d95

    db 0x8b, 0xc0 ; mov eax, eax using the original alignment encoding

parse_video_mode_dispatch:
    dd parse_video_mode.dispatch_case_36c4a - 0x10000
    dd parse_video_mode.dispatch_case_36c99 - 0x10000
    dd parse_video_mode.dispatch_case_36cdc - 0x10000
    dd parse_video_mode.dispatch_case_36cdc - 0x10000
    dd parse_video_mode.dispatch_case_36cdc - 0x10000
    dd parse_video_mode.dispatch_case_36cdc - 0x10000

parse_video_mode:
    push ecx
    push esi
    push edi
    mov edi, eax
    mov ecx, edx
    xor esi, esi

.branch_36c1f:
    mov eax, edi
    mov edx, [nosplit esi*4 + frame_state_12d30]
    call stricmp
    test eax, eax
    jz short .branch_36c37
    inc esi
    cmp esi, 0x6
    jl short .branch_36c1f

.branch_36c37:
    cmp esi, 0x5
    ja near .branch_36ce8
    mov eax, esi
    jmp dword near [cs:eax*4 + parse_video_mode_dispatch - 0x10000]
.dispatch_case_36c4a:
    xor eax, esi
    jmp short .branch_36c6a

.branch_36c4e:
    mov di, [ecx]
    lea edx, [eax + eax]
    cmp di, [edx + frame_state_12d48]
    jg short .branch_36c69
    mov ax, [edx + frame_state_12d48]
    mov [ecx], ax
    jmp short .branch_36c6f

.branch_36c69:
    inc eax

.branch_36c6a:
    cmp eax, 0x3
    jc short .branch_36c4e

.branch_36c6f:
    xor eax, eax
    jmp short .branch_36c8e

.branch_36c73:
    lea edx, [eax + eax]
    mov cx, [ebx]
    mov di, [edx + frame_state_12d4e]
    cmp cx, di
    jg short .branch_36c8d

.branch_36c85:
    mov [ebx], di
    jmp near .branch_36c93

.branch_36c8d:
    inc eax

.branch_36c8e:
    cmp eax, 0x3
    jc short .branch_36c73

.branch_36c93:
    mov eax, esi
    pop edi
    pop esi
    pop ecx
    ret
.dispatch_case_36c99:
    xor eax, esi
    jmp short .branch_36cb9

.branch_36c9d:
    mov di, [ecx]
    lea edx, [eax + eax]
    cmp di, [edx + frame_state_12d60]
    jg short .branch_36cb8
    mov ax, [edx + frame_state_12d60]
    mov [ecx], ax
    jmp short .branch_36cbe

.branch_36cb8:
    inc eax

.branch_36cb9:
    cmp eax, 0x2
    jc short .branch_36c9d

.branch_36cbe:
    xor eax, eax
    jmp short .branch_36cd5

.branch_36cc2:
    lea ecx, [eax + eax]
    mov dx, [ebx]
    mov di, [ecx + frame_state_12d64]
    cmp dx, di
    jng short .branch_36c85
    inc eax

.branch_36cd5:
    cmp eax, 0x2
    jc short .branch_36cc2
    jmp short .branch_36c93
.dispatch_case_36cdc:
    mov word [ecx], 0x140
    mov word [ebx], 0xc8
    jmp short .branch_36c93

.branch_36ce8:
    mov eax, 0xffffffff
    pop edi
    pop esi
    pop ecx
    ret
