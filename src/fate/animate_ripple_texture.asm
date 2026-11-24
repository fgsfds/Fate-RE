; Advance the ripple effect in a 128-by-128 texture.
BITS 32
ORG 0x2eb57
section .text align=1

radial_sample_count equ 0x5ae5c
radial_x_offsets equ 0x5aedc
radial_y_offsets equ 0x5eedc
random_value equ 0x602d0
ripple_radius equ 0x62fcc
frame_state_630fc equ 0x630fc
ripple_buffer equ 0x6331c
frame_state_6331d equ 0x6331d
frame_state_6339d equ 0x6339d
frame_state_633a1 equ 0x633a1
frame_state_675a0 equ 0x675a0
frame_state_67623 equ 0x67623
ripple_origin_y equ 0x6773c
ripple_origin_x equ 0x677bc
ripple_count equ 0x770e0
ripple_frame equ 0x770f4

animate_ripple_texture:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x14
    mov edx, eax
; C computes and clamps the creation count in EAX.
section .control align=1 vstart=0x2eb78 follows=.text
.branch_2eb78:
    mov esi, 0x1
    mov [esp], eax
    jmp short .branch_2ebc5

.branch_2eb82:
    call random_value
; C copies the X draw, reads the slot, masks it, and stores the coordinate.
section .x_countdown_copy align=1 vstart=0x2eb89 follows=.control
    mov ebp, ecx
section .x_countdown_step align=1 vstart=0x2eb93 follows=.x_countdown_copy
    sub ebp, esi
section .after_x_store align=1 vstart=0x2eb9c follows=.x_countdown_step
    call random_value
    mov [esp], ebp
; C stores the Y draw, radius and updated count.
section .after_spawn_slot align=1 vstart=0x2ebc5 follows=.after_x_store

.branch_2ebc5:
    mov ecx, [esp]
    test ecx, ecx
    jnl short .branch_2eb82
    mov eax, [ripple_count]
    dec eax
    mov [esp], eax
    jmp near .branch_2ecb2

.branch_2ebda:
    mov ebp, eax
    mov ebx, ebp
    and ebx, 0x1
    mov eax, [nosplit eax*4 + ripple_radius]
    add ebx, ebx
    mov eax, [nosplit eax*4 + frame_state_630fc]
    dec ebx
    imul eax, ebx
    mov edi, [nosplit ebp*4 + ripple_radius]
    mov esi, [nosplit edi*4 + radial_sample_count]
    mov [esp + 0x8], eax
    mov eax, [nosplit ebp*4 + ripple_origin_x]
    dec esi
    mov [esp + 0xc], eax
    mov ebp, [nosplit ebp*4 + ripple_origin_y]
    jmp short .branch_2ec5f

.branch_2ec1c:
    mov eax, edi
    mov ecx, esi
    shl eax, byte 0x9
    shl ecx, byte 0x2
    add ecx, eax
    mov ebx, [esp + 0xc]
    mov eax, [ecx + radial_x_offsets]
    add eax, ebx
    mov ebx, [ecx + radial_y_offsets]
    and eax, 0x7f
    add ebx, ebp
    shl eax, byte 0x7
    and ebx, 0x7f
    add eax, ebx
    lea ecx, [edx + eax]
    mov al, [esp + 0x8]
    add [ecx], al
; C clamps the updated pixel to the original floor.
section .after_pixel_floor align=1 vstart=0x2ec5e follows=.after_spawn_slot

.branch_2ec5e:
    dec esi

.branch_2ec5f:
    test esi, esi
    jnl short .branch_2ec1c
    mov eax, [esp]
; C advances the radius and removes expired rings.
section .after_radius_update align=1 vstart=0x2ecaf follows=.after_pixel_floor

.branch_2ecaf:
    dec dword [esp]

.branch_2ecb2:
    mov eax, [esp]
    test eax, eax
    jnl near .branch_2ebda
    mov eax, frame_state_633a1
    mov esi, edx
    xor ebp, ebp
    jmp short .branch_2ece9

.branch_2ecc8 equ 0x2ecc8
; C copies and masks one 128-byte row, returning the next row in EAX.
section .after_mask_row align=1 vstart=0x2ece8 follows=.after_radius_update
    inc ebp

.branch_2ece9:
    cmp ebp, strict dword 0x80
    jl short .branch_2ecc8
; C supplies the counter initialization and top/bottom border loop.
section .after_border_columns align=1 vstart=0x2ed19 follows=.after_mask_row
    xor ebp, ebp
    jmp short .branch_2ed4c

.branch_2ed1d:
    mov ebx, ebp
    shl ebx, byte 0x7
    mov al, [edx + ebx + 0x7f]
    and al, 0x1f
    inc ebp
    mov [esp + 0x10], al
    mov eax, ebp
    shl eax, byte 0x5
    add eax, ebp
    mov cl, [esp + 0x10]
    mov [nosplit eax*4 + ripple_buffer], cl
    mov bl, [edx + ebx]
    and bl, 0x1f
    mov [nosplit eax*4 + frame_state_6339d], bl

.branch_2ed4c:
    cmp ebp, strict dword 0x80
    jl short .branch_2ed1d
; C supplies all four corner reads, masks and stores.
section .corners_output_pointer align=1 vstart=0x2ed7a follows=.after_border_columns
    mov esi, edx
section .corners_output_row align=1 vstart=0x2ed7e follows=.corners_output_pointer
    xor ebp, ebp
section .after_corners align=1 vstart=0x2ed85 follows=.corners_output_row
    jmp near .branch_2ee92

.branch_2ed8a:
    lea edx, [ebp + 0x1]
    mov eax, edx
    shl eax, byte 0x5
    add eax, edx
    shl eax, byte 0x2
    inc eax
    add eax, ripple_buffer
    lea edx, [eax + 0x80]
    mov [esp + 0x4], edx
    mov ecx, eax
    jmp near .branch_2ee87

.branch_2edae:
    mov ebx, ecx
; Compiler-generated C supplies this seven-neighbor sum.
section .after_sum1 align=1 vstart=0x2edd6 follows=.after_corners
    lea ebx, [ecx + 0x1]
    mov edi, eax
; Compiler-generated C supplies this seven-neighbor sum.
section .after_sum2 align=1 vstart=0x2ee01 follows=.after_sum1
    and edi, strict dword 0xf8
    and eax, strict dword 0xf8
    sar edi, byte 0x3
    shl eax, byte 0x5
    lea ebx, [ecx + 0x2]
    add edi, eax
; Compiler-generated C supplies this seven-neighbor sum.
section .after_sum3 align=1 vstart=0x2ee3d follows=.after_sum2
    and eax, strict dword 0xf8
    shl eax, byte 0xd
    lea ebx, [ecx + 0x3]
    add edi, eax
; Compiler-generated C supplies this seven-neighbor sum.
section .after_sum4 align=1 vstart=0x2ee70 follows=.after_sum3
    and eax, strict dword 0xf8
    shl eax, byte 0x15
    add eax, edi
    sub eax, strict dword 0x3d3d3d3e
    add ecx, 0x4
    mov [esi], eax
    add esi, 0x4

.branch_2ee87:
    cmp ecx, [esp + 0x4]
    jl near .branch_2edae
    inc ebp

.branch_2ee92:
    cmp ebp, strict dword 0x80
    jl near .branch_2ed8a
    inc dword [ripple_frame]
    add esp, 0x14
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
