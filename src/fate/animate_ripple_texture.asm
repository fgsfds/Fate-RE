; Advance the ripple effect in a 128-by-128 texture.
BITS 32
ORG 0x2eb57

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
    mov eax, 0x20
    sub eax, [ripple_count]
    dec eax
    cmp eax, 0x3
    jl short .branch_2eb78
    mov eax, 0x3

.branch_2eb78:
    mov esi, 0x1
    mov [esp], eax
    jmp short .branch_2ebc5

.branch_2eb82:
    call random_value
    mov ebx, eax
    mov ebp, ecx
    mov eax, [ripple_count]
    and ebx, 0x7f
    sub ebp, esi
    mov [nosplit eax*4 + ripple_origin_x], ebx
    call random_value
    mov [esp], ebp
    mov ebx, eax
    mov eax, [ripple_count]
    and ebx, 0x7f
    lea edi, [eax + esi]
    mov [nosplit eax*4 + ripple_origin_y], ebx
    mov [nosplit eax*4 + ripple_radius], esi
    mov [ripple_count], edi

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
    xor eax, eax
    mov al, [ecx]
    cmp eax, strict dword 0xc0
    jnl short .branch_2ec5e
    mov byte [ecx], 0xc0

.branch_2ec5e:
    dec esi

.branch_2ec5f:
    test esi, esi
    jnl short .branch_2ec1c
    mov eax, [esp]
    shl eax, byte 0x2
    mov ebx, [eax + ripple_radius]
    inc ebx
    mov [eax + ripple_radius], ebx
    cmp ebx, 0xa
    jng short .branch_2ecaf
    mov esi, [ripple_count]
    dec esi
    mov ecx, [nosplit esi*4 + ripple_origin_x]
    mov ebx, [nosplit esi*4 + ripple_radius]
    mov [ripple_count], esi
    mov [eax + ripple_origin_x], ecx
    mov ecx, [nosplit esi*4 + ripple_origin_y]
    mov [eax + ripple_radius], ebx
    mov [eax + ripple_origin_y], ecx

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

.branch_2ecc8:
    mov ecx, 0x20
    jmp short .branch_2ecdf

.branch_2eccf:
    mov edi, [esi]
    dec ecx
    and edi, strict dword 0x1f1f1f1f
    add esi, 0x4
    mov [eax], edi
    mov eax, ebx

.branch_2ecdf:
    lea ebx, [eax + 0x4]
    test ecx, ecx
    jg short .branch_2eccf
    mov eax, ebx
    inc ebp

.branch_2ece9:
    cmp ebp, strict dword 0x80
    jl short .branch_2ecc8
    xor ecx, ecx
    jmp short .branch_2ed11

.branch_2ecf5:
    mov bl, [ecx + edx + 0x3f80]
    and bl, 0x1f
    mov [ecx + frame_state_6331d], bl
    mov al, [ecx + edx]
    inc ecx
    and al, 0x1f
    mov [ecx + frame_state_675a0], al

.branch_2ed11:
    cmp ecx, strict dword 0x80
    jl short .branch_2ecf5
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
    mov al, [edx + 0x3fff]
    and al, 0x1f
    mov [ripple_buffer], al
    mov al, [edx + 0x3f80]
    and al, 0x1f
    mov [frame_state_6339d], al
    mov al, [edx + 0x7f]
    and al, 0x1f
    mov [frame_state_675a0], al
    mov al, [edx]
    mov esi, edx
    and al, 0x1f
    xor ebp, ebp
    mov [frame_state_67623], al
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
    mov al, [ebx-0x85]
    mov dl, [ebx-0x1]
    add al, [ebx-0x84]
    add dl, [ebx + 0x83]
    add al, [ebx-0x83]
    add dl, [ebx + 0x84]
    add al, [ebx + 0x1]
    add al, dl
    lea ebx, [ecx + 0x1]
    mov edi, eax
    mov al, [ebx-0x85]
    mov dl, [ebx-0x1]
    add al, [ebx-0x84]
    add dl, [ebx + 0x83]
    add al, [ebx-0x83]
    add dl, [ebx + 0x84]
    add al, [ebx + 0x1]
    add al, dl
    and edi, strict dword 0xf8
    and eax, strict dword 0xf8
    sar edi, byte 0x3
    shl eax, byte 0x5
    lea ebx, [ecx + 0x2]
    add edi, eax
    mov al, [ebx-0x85]
    mov dl, [ebx-0x1]
    add al, [ebx-0x84]
    add dl, [ebx + 0x83]
    add al, [ebx-0x83]
    add dl, [ebx + 0x84]
    add al, [ebx + 0x1]
    add al, dl
    and eax, strict dword 0xf8
    shl eax, byte 0xd
    lea ebx, [ecx + 0x3]
    add edi, eax
    mov al, [ebx-0x85]
    mov dl, [ebx-0x1]
    add al, [ebx-0x84]
    add dl, [ebx + 0x83]
    add al, [ebx-0x83]
    add dl, [ebx + 0x84]
    add al, [ebx + 0x1]
    add al, dl
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
