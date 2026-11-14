; Prompt video mode.
BITS 32
ORG 0x36cf1

frame_state_9e3 equ 0x9e3
frame_state_9eb equ 0x9eb
frame_state_9fd equ 0x9fd
frame_state_a0d equ 0xa0d
frame_state_12d30 equ 0x12d30
frame_state_12d48 equ 0x12d48
frame_state_12d4e equ 0x12d4e
frame_state_12d54 equ 0x12d54
frame_state_12d60 equ 0x12d60
frame_state_12d64 equ 0x12d64
frame_state_12d68 equ 0x12d68
frame_state_12d70 equ 0x12d70
frame_state_12d74 equ 0x12d74
frame_state_12d78 equ 0x12d78
video_default_mode_offset equ 0x2694a
video_default_width_offset equ 0x2694e
video_default_height_offset equ 0x26950
print_video_text_at equ 0x36b0e
set_background_color equ 0x6f1bf
get_text_color equ 0x6f22c
set_text_color equ 0x6f25d
frame_state_173d54 equ 0x173d54
frame_state_173d56 equ 0x173d56

    nop

prompt_video_mode_dispatch:
    dd prompt_video_mode.dispatch_case_36d45 - 0x10000
    dd prompt_video_mode.dispatch_case_36d66 - 0x10000
    dd prompt_video_mode.dispatch_case_36d87 - 0x10000
    dd prompt_video_mode.dispatch_case_36d87 - 0x10000
    dd prompt_video_mode.dispatch_case_36d87 - 0x10000
    dd prompt_video_mode.dispatch_case_36d87 - 0x10000

prompt_video_mode:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x18
    mov ebx, eax
    mov ecx, edx
    mov eax, [video_default_mode_offset]
    mov [esp], eax
    mov ax, [video_default_width_offset]
    mov [esp + 0x10], eax
    mov ax, [video_default_height_offset]
    mov [esp + 0xc], eax
    cmp bx, 0x5
    ja short .branch_36da1
    xor eax, eax
    mov ax, bx
    jmp dword near [cs:eax*4 + prompt_video_mode_dispatch - 0x10000]
.dispatch_case_36d45:
    mov ebp, frame_state_12d54
    mov ebx, frame_state_12d48
    mov esi, frame_state_12d4e
    mov edi, 0x3
    mov [esp + 0x4], ebx
    mov [frame_state_173d56], di
    jmp short .branch_36da1
.dispatch_case_36d66:
    mov ebp, frame_state_12d68
    mov edx, frame_state_12d60
    mov esi, frame_state_12d64
    mov ebx, 0x2
    mov [esp + 0x4], edx
    mov [frame_state_173d56], bx
    jmp short .branch_36da1
.dispatch_case_36d87:
    mov ebp, esp
    lea eax, [esp + 0x10]
    lea esi, [esp + 0xc]
    mov edx, 0x1
    mov [esp + 0x4], eax
    mov [frame_state_173d56], dx

.branch_36da1:
    mov ax, [frame_state_173d54]
    mov dx, [frame_state_173d56]
    cmp ax, dx
    jl short .branch_36dbc
    mov eax, edx
    dec eax
    mov [frame_state_173d54], ax

.branch_36dbc:
    xor edx, edx
    jmp short .branch_36e06

.branch_36dc0:
    movsx eax, dx
    mov bx, [ebp + eax*4 + 0x0]
    mov [esp + 0x8], ebx
    mov bx, [ebp + eax*4 + 0x2]
    movsx eax, word [esp + 0x8]
    mov edi, [esp + 0x4]
    add eax, eax
    add eax, edi
    mov di, [eax]
    movsx eax, bx
    mov bx, [esi + eax*2]
    movsx eax, di
    cmp eax, [frame_state_12d74]
    jnz short .branch_36e05
    movsx eax, bx
    cmp eax, [frame_state_12d78]
    jnz short .branch_36e05
    mov [frame_state_173d54], dx

.branch_36e05:
    inc edx

.branch_36e06:
    cmp dx, [frame_state_173d56]
    jl short .branch_36dc0
    mov bx, [frame_state_173d54]
    sub ebx, 0x5
    test bx, bx
    jnl short .branch_36e20
    xor ebx, ebx

.branch_36e20:
    mov eax, ebx
    add eax, strict dword 0xb
    mov [esp + 0x14], eax
    test cx, cx
    jz short .branch_36e37
    mov eax, 0xb
    jmp short .branch_36e3c

.branch_36e37:
    mov eax, 0x3

.branch_36e3c:
    call set_background_color
    xor eax, eax
    call set_text_color
    mov eax, [frame_state_12d70]
    mov edi, [nosplit eax*4 + frame_state_12d30]
    push edi
    push strict dword frame_state_9e3
    push strict byte 0x5
    push strict byte 0x2f
    call print_video_text_at
    add esp, 0x10
    mov eax, 0x1
    call set_background_color
    test cx, cx
    jz short .branch_36e7c
    mov eax, 0xb
    jmp short .branch_36e81

.branch_36e7c:
    mov eax, 0x3

.branch_36e81:
    cwde
    call set_text_color
    mov edx, ebx
    jmp near .branch_36f43

.branch_36e8e:
    cmp dx, [frame_state_173d56]
    jl short .branch_36ead
    push strict dword frame_state_9eb
    cwde
    push eax
    push strict byte 0x2f
    call print_video_text_at
    add esp, 0xc
    jmp near .branch_36f42

.branch_36ead:
    cmp dx, [frame_state_173d54]
    jnz short .branch_36ed6
    test cx, cx
    jz short .branch_36ec2
    mov eax, 0x7
    jmp short .branch_36ec7

.branch_36ec2:
    mov eax, 0x1

.branch_36ec7:
    call set_background_color
    mov eax, 0xf
    call set_text_color

.branch_36ed6:
    movsx eax, dx
    mov di, [ebp + eax*4 + 0x0]
    mov ax, [ebp + eax*4 + 0x2]
    cwde
    movsx eax, word [esi + eax*2]
    mov [esp + 0x8], edi
    push eax
    movsx eax, di
    mov edi, [esp + 0x8]
    add eax, eax
    add eax, edi
    movsx eax, word [eax]
    push eax
    mov eax, edx
    add eax, strict dword 0x6
    sub eax, ebx
    push strict dword frame_state_9fd
    cwde
    push eax
    push strict byte 0x2f
    call print_video_text_at
    add esp, 0x14
    call get_text_color
    cwde
    cmp eax, 0xf
    jnz short .branch_36f42
    mov eax, 0x1
    call set_background_color
    test cx, cx
    jz short .branch_36f37
    mov eax, 0xb
    jmp short .branch_36f3c

.branch_36f37:
    mov eax, 0x3

.branch_36f3c:
    cwde
    call set_text_color

.branch_36f42:
    inc edx

.branch_36f43:
    mov eax, edx
    add eax, strict dword 0x6
    mov edi, [esp + 0x14]
    sub eax, ebx
    cmp dx, di
    jl near .branch_36e8e
    push strict dword frame_state_a0d
    cwde
    push eax
    push strict byte 0x2f
    call print_video_text_at
    add esp, 0xc
    add esp, 0x18
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
