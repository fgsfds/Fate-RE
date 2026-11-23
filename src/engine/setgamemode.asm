; Configure engine video mode, allocate render buffers and initialize viewport state.
BITS 32
ORG 0x4b050

out_of_memory_message equ 0x1af9
horizon_allocation_message equ 0x1b08
screen_allocation_message_1 equ 0x1b31
screen_allocation_message_2 equ 0x1b5a
screen_allocation_message_3 equ 0x1b83
screen_allocation_message_4 equ 0x1bac
software_framebuffer equ 0x13ff0
chainstat equ 0x14003
engine_14004 equ 0x14004
page_flip_enabled equ 0x14014
frame_state_140c2 equ 0x140c2
video_mode_dispatch equ 0x3b02e
print_diagnostic equ 0x40bb4
engine_malloc equ 0x4478c
initialize_video_backend equ 0x4a294
finish_video_mode_setup equ 0x4a367
sub_4c0b0 equ 0x4c0b0
runtime_exit equ 0x60353
engine_1ec6a0 equ 0x1ec6a0
show_2d_walls equ 0x1ec920
show_2d_sprites equ 0x1ecfa0
engine_1ed1a0 equ 0x1ed1a0
waloff equ 0x1ffca0
frame_state_203c9c equ 0x203c9c
horizlookup_base equ 0x286ac4
horizycent equ 0x286ae0
horizlookup equ 0x286aec
video_mode equ 0x286b24
engine_286b40 equ 0x286b40
frame_state_286b44 equ 0x286b44
frame_state_286b48 equ 0x286b48
chainplace equ 0x286b4c
draw_page_address equ 0x286b74
engine_286b88 equ 0x286b88
engine_286b8c equ 0x286b8c
engine_286ba0 equ 0x286ba0
engine_286ba8 equ 0x286ba8
viewingrange_reciprocal equ 0x286bac
ydim equ 0x287e8c
xdim equ 0x287e90
engine_289122 equ 0x289122
engine_28912a equ 0x28912a
frame_state_28913a equ 0x28913a
frame_state_28913c equ 0x28913c
frame_state_289142 equ 0x289142
engine_289150 equ 0x289150
engine_2891d8 equ 0x2891d8
engine_2891d9 equ 0x2891d9
engine_2891da equ 0x2891da
video_backend equ 0x2891db

setgamemode equ 0x4b04e
; Watcom saves ECX/ESI and initializes the video state. The shared exit also
; restores EDI and EBP, so keep those saves in their original slots.
    push edi
    push ebp

section .backend_dispatch align=1 vstart=0x4b1d1 follows=.text
    cmp al, 0x7
    ja near .branch_4b386
    xor edx, edx
    mov ebx, [ydim]
    mov dl, al
    mov eax, [xdim]
    imul eax, ebx
    jmp dword near [cs:edx*4 + video_mode_dispatch]
section .backend_padded_entry align=1 vstart=0x4b275 follows=.backend_dispatch
    mov eax, [xdim]
section .backend_stereo_state align=1 vstart=0x4b2e0 follows=.backend_padded_entry
.branch_4b2e0:
    mov ch, 0x2
    mov ebp, 0x1
    mov eax, [software_framebuffer]
    mov edx, 0x20
    mov [draw_page_address], eax
    xor eax, eax
    mov [page_flip_enabled], ebp
    mov al, [video_backend]
    mov [frame_state_286b44], edx
    mov [video_mode], eax
    mov eax, 0x8000
    mov [video_backend], ch
    mov [engine_286b40], eax
    jmp short .branch_4b386
section .backend_stereo_double_state align=1 vstart=0x4b347 follows=.backend_stereo_state
.branch_4b347:
    mov cl, 0x2
    mov esi, 0x8000
    mov eax, [software_framebuffer]
    mov edi, 0x20
    mov [draw_page_address], eax
    mov [engine_286b40], esi
    xor eax, eax
    mov [frame_state_286b44], edi
    mov al, [video_backend]
    mov [video_backend], cl
    mov ecx, 0x1
    mov [video_mode], eax
    mov [page_flip_enabled], ecx

.branch_4b386:
    call finish_video_mode_setup
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
