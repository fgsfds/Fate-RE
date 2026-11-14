; Release video buffers and palette lookup allocations.
BITS 32
ORG 0x4b390

software_framebuffer equ 0x13ff0
frame_state_1401d equ 0x1401d
frame_state_140be equ 0x140be
handle equ 0x1418b
close_art equ 0x41503
sub_4476c equ 0x4476c
engine_free equ 0x44791
restore_ebp_edi_esi_edx_ecx_ebx equ 0x4abbe
palookup equ 0x203ca0
horizlookup_base equ 0x286ac4
horizlookup equ 0x286aec
video_backend equ 0x2891db

shutdown_video_engine:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov eax, 0x36
    mov edx, 0x43
    out dx, al
    mov eax, 0xff
    mov edx, 0x40
    out dx, al
    out dx, al
    xor eax, eax
    mov al, [video_backend]
    cmp eax, 0x1
    jnz short .branch_4b3be
    call sub_4476c

.branch_4b3be:
    mov edx, [handle]
    cmp edx, -1
    jz short .branch_4b3d0
    mov eax, edx
    call close_art

.branch_4b3d0:
    mov ebx, [frame_state_140be]
    test ebx, ebx
    jz short .branch_4b3e9
    mov eax, ebx
    xor ecx, ecx
    call engine_free
    mov [frame_state_140be], ecx

.branch_4b3e9:
    mov esi, [frame_state_1401d]
    test esi, esi
    jz short .branch_4b402
    mov eax, esi
    xor edi, edi
    call engine_free
    mov [frame_state_1401d], edi

.branch_4b402:
    mov ebp, [software_framebuffer]
    test ebp, ebp
    jz short .branch_4b41a
    mov eax, ebp
    call engine_free
    xor eax, eax
    mov [software_framebuffer], eax

.branch_4b41a:
    mov edx, [horizlookup_base]
    test edx, edx
    jz short .branch_4b433
    mov eax, edx
    xor ebx, ebx
    call engine_free
    mov [horizlookup_base], ebx

.branch_4b433:
    mov ecx, [horizlookup]
    test ecx, ecx
    jz short .branch_4b44c
    mov eax, ecx
    xor esi, esi
    call engine_free
    mov [horizlookup], esi

.branch_4b44c:
    xor ebx, ebx
    jmp short .branch_4b46f

.branch_4b450:
    mov edx, ebx
    shl edx, byte 0x2
    mov edi, [edx + palookup]
    test edi, edi
    jz short .branch_4b46e
    mov eax, edi
    xor ebp, ebp
    call engine_free
    mov [edx + palookup], ebp

.branch_4b46e:
    inc ebx

.branch_4b46f:
    cmp ebx, strict dword 0x100
    jl short .branch_4b450
    jmp near restore_ebp_edi_esi_edx_ecx_ebx
