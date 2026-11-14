; Group integer offsets by radius and initialize the ripple lookup tables.
BITS 32
ORG 0x2eaa2

integer_square_root equ 0x4ca38
radial_sample_count equ 0x5ae5c
radial_x_offsets equ 0x5aedc
radial_y_offsets equ 0x5eedc
frame_state_630f8 equ 0x630f8
frame_state_6783b equ 0x6783b
ripple_count equ 0x770e0
ripple_frame equ 0x770f4

initialize_ripple_tables:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, 0xfffffff0
    jmp short .branch_2eaf0

.branch_2eaad:
    mov edx, 0xfffffff0
    jmp short .branch_2eaea

.branch_2eab4:
    mov eax, ecx
    imul eax, ecx
    mov ebx, edx
    imul ebx, edx
    add eax, ebx
    call integer_square_root
    mov ebx, eax
    mov esi, [nosplit eax*4 + radial_sample_count]
    shl ebx, byte 0x9
    mov [ebx + esi*4 + radial_x_offsets], ecx
    mov [ebx + esi*4 + radial_y_offsets], edx
    lea ebx, [esi + 0x1]
    inc edx
    mov [nosplit eax*4 + radial_sample_count], ebx

.branch_2eaea:
    cmp edx, 0x10
    jng short .branch_2eab4
    inc ecx

.branch_2eaf0:
    cmp ecx, 0x10
    jng short .branch_2eaad
    xor ebx, ebx
    jmp short .branch_2eb17

.branch_2eaf9:
    mov eax, ebx
    call integer_square_root
    lea ecx, [eax + 0x1]
    mov eax, 0x8
    mov edx, eax
    sar edx, byte 0x1f
    idiv ecx
    inc ebx
    mov [nosplit ebx*4 + frame_state_630f8], eax

.branch_2eb17:
    cmp ebx, 0x10
    jl short .branch_2eaf9
    xor ebx, ebx
    jmp short .branch_2eb3c

.branch_2eb20:
    mov eax, ebx
    xor al, 0x11
    sar eax, byte 0x4
    and eax, 0x7
    sub eax, 0x4
    inc ebx
    test eax, eax
    jns short .branch_2eb34
    neg eax

.branch_2eb34:
    add al, 0xc
    mov [ebx + frame_state_6783b], al

.branch_2eb3c:
    cmp ebx, strict dword 0x80
    jl short .branch_2eb20
    xor ecx, ecx
    mov [ripple_count], ecx
    mov [ripple_frame], ecx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
