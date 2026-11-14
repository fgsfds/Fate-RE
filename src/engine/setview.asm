; Set the viewport bounds and initialize column clipping.
BITS 32
ORG 0x56f0a

chainstat equ 0x14003
xdimen equ 0x140b5
rebuild_view_angle_table equ 0x56e8f
setaspect equ 0x5708a
startumost_previous equ 0x1f139e
startumost equ 0x1f13a0
startdmost_previous equ 0x1f801e
viewoffset equ 0x286ae8
view_height equ 0x286af4
view_width_reciprocal equ 0x286b04
half_view_width equ 0x286b08
frame_state_286b0c equ 0x286b0c
frame_state_286b10 equ 0x286b10
frame_state_286b18 equ 0x286b18
frame_state_286b1c equ 0x286b1c
bytesperline equ 0x286b64
window_bottom equ 0x286b90
window_top equ 0x286b94
window_right equ 0x286b98
window_left equ 0x286b9c
ydim equ 0x287e8c
xdim equ 0x287e90

setview:
    push esi
    push edi
    push ebp
    mov esi, edx
    mov edx, eax
    mov edi, [xdimen]
    shl edx, byte 0xc
    mov [window_left], eax
    mov [frame_state_286b10], edx
    mov edx, esi
    mov [window_top], esi
    shl edx, byte 0xc
    mov [window_right], ebx
    mov [frame_state_286b1c], edx
    lea edx, [ebx + 0x1]
    mov [window_bottom], ecx
    shl edx, byte 0xc
    sub ebx, eax
    mov [frame_state_286b0c], edx
    inc ebx
    lea edx, [ecx + 0x1]
    mov [xdimen], ebx
    mov eax, ebx
    shl edx, byte 0xc
    sar eax, 1
    sub ecx, esi
    mov [frame_state_286b18], edx
    mov [half_view_width], eax
    mov edx, 0x1
    inc ecx
    xor eax, eax
    idiv ebx
    mov edx, [xdimen]
    mov [view_width_reciprocal], eax
    mov [view_height], ecx
    cmp edi, edx
    jz short .branch_56f94
    mov eax, edx
    call rebuild_view_angle_table

.branch_56f94:
    mov edx, [xdim]
    mov ebx, edx
    shl ebx, byte 0x2
    sub ebx, edx
    shl ebx, byte 0x3
    add ebx, edx
    mov edx, [ydim]
    mov eax, edx
    shl eax, byte 0x2
    add eax, edx
    shl ebx, byte 0x3
    shl eax, byte 0x6
    mov edx, eax
    sar edx, byte 0x10
    shl eax, byte 0x10
    idiv ebx
    call setaspect
    xor eax, eax
    jmp short .branch_56fe4

.branch_56fcc:
    inc eax
    mov ebx, 0x1
    xor ecx, ecx
    mov [nosplit eax*2 + startumost_previous], bx
    mov [nosplit eax*2 + startdmost_previous], cx

.branch_56fe4:
    mov ebx, [window_left]
    cmp eax, ebx
    jl short .branch_56fcc
    mov ecx, [window_right]
    mov eax, ebx
    jmp short .branch_57018

.branch_56ff8:
    mov bx, [window_top]
    mov [nosplit eax*2 + startumost], bx
    mov bx, [window_bottom]
    inc eax
    inc ebx
    mov [nosplit eax*2 + startdmost_previous], bx

.branch_57018:
    cmp eax, ecx
    jng short .branch_56ff8
    lea eax, [ecx + 0x1]
    jmp short .branch_57039

.branch_57021:
    inc eax
    mov esi, 0x1
    xor edi, edi
    mov [nosplit eax*2 + startumost_previous], si
    mov [nosplit eax*2 + startdmost_previous], di

.branch_57039:
    cmp eax, [xdim]
    jl short .branch_57021
    cmp byte [chainstat], 0x0
    jz short .branch_5706c
    mov eax, [bytesperline]
    mov ebp, [window_top]
    shl eax, byte 0x2
    imul eax, ebp
    mov edx, [window_left]
    add eax, edx
    mov [viewoffset], eax
    pop ebp
    pop edi
    pop esi
    ret

.branch_5706c:
    mov edx, [window_top]
    imul edx, [bytesperline]
    mov eax, [window_left]
    add edx, eax
    mov [viewoffset], edx
    pop ebp
    pop edi
    pop esi
    ret
