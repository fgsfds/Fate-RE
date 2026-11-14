; Initialize both Build sprite lists and their free-list entries.
BITS 32
ORG 0x507e3

restore_edi_esi_edx_ecx_ebx equ 0x4abbf
save_state_1f6020 equ 0x1f6020
nextspritesect equ 0x1f9ca0
frame_state_1fbc9e equ 0x1fbc9e
nextspritestat equ 0x1fbca0
frame_state_1fdc9e equ 0x1fdc9e
prevspritestat equ 0x1fdca0
sprite_sector equ 0x2040b8
sprite_status equ 0x2040ba
framebuffer_selector equ 0x28811a
headspritesect equ 0x28891c
frame_state_28911e equ 0x28911e

initspritelists:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ebx, 0xffffffff
    xor eax, eax
    jmp short .branch_507fa

.branch_507f1:
    inc eax
    mov [nosplit eax*2 + headspritesect], bx

.branch_507fa:
    cmp eax, strict dword 0x400
    jl short .branch_507f1
    mov edi, 0x400
    xor edx, edx
    xor eax, eax
    mov [frame_state_28911e], dx
    jmp short .branch_50834

.branch_50813:
    mov ebx, eax
    dec ebx
    mov [nosplit eax*2 + save_state_1f6020], bx
    mov ebx, eax
    imul edx, eax, 0x2c
    inc ebx
    mov [nosplit eax*2 + nextspritesect], bx
    inc eax
    mov [edx + sprite_sector], di

.branch_50834:
    cmp eax, strict dword 0x1000
    jl short .branch_50813
    mov ecx, 0xffffffff
    mov ebx, 0xffffffff
    xor eax, eax
    mov [save_state_1f6020], cx
    mov [frame_state_1fbc9e], cx
    jmp short .branch_50860

.branch_50857:
    inc eax
    mov [nosplit eax*2 + framebuffer_selector], bx

.branch_50860:
    cmp eax, strict dword 0x400
    jl short .branch_50857
    xor eax, eax
    mov ecx, 0x400
    mov [headspritesect], ax
    xor eax, eax
    jmp short .branch_50899

.branch_50878:
    mov ebx, eax
    dec ebx
    mov [nosplit eax*2 + prevspritestat], bx
    mov ebx, eax
    imul edx, eax, 0x2c
    inc ebx
    mov [nosplit eax*2 + nextspritestat], bx
    inc eax
    mov [edx + sprite_status], cx

.branch_50899:
    cmp eax, strict dword 0x1000
    jl short .branch_50878
    mov esi, 0xffffffff
    mov [prevspritestat], si
    mov [frame_state_1fdc9e], si
    jmp near restore_edi_esi_edx_ecx_ebx
