; Prompt video settings.
BITS 32
ORG 0x36f73

frame_state_a1f equ 0xa1f
frame_state_a32 equ 0xa32
frame_state_a3e equ 0xa3e
frame_state_12d30 equ 0x12d30
frame_state_12d70 equ 0x12d70
print_video_text_at equ 0x36b0e
prompt_video_mode equ 0x36d0a
set_background_color equ 0x6f1bf
get_text_color equ 0x6f22c
set_text_color equ 0x6f25d

prompt_video_settings:
    push ebx
    push ecx
    push edx
    push esi
    mov ecx, eax
    mov eax, 0x1
    call set_background_color
    test cx, cx
    jz short .branch_36f8f
    mov eax, 0xb
    jmp short .branch_36f94

.branch_36f8f:
    mov eax, 0x3

.branch_36f94:
    cwde
    call set_text_color
    push strict dword frame_state_a1f
    push strict byte 0x5
    push strict byte 0x10
    xor ebx, ebx
    jmp near .branch_3704c

.branch_36faa:
    cmp eax, [frame_state_12d70]
    jnz short .branch_36fd2
    test cx, cx
    jz short .branch_36fbe
    mov eax, 0x7
    jmp short .branch_36fc3

.branch_36fbe:
    mov eax, 0x1

.branch_36fc3:
    call set_background_color
    mov eax, 0xf
    call set_text_color

.branch_36fd2:
    movsx eax, bx
    mov esi, [nosplit eax*4 + frame_state_12d30]
    mov eax, ebx
    add eax, ebx
    push esi
    add eax, strict dword 0x6
    push strict dword frame_state_a32
    cwde
    push eax
    push strict byte 0x10
    call print_video_text_at
    add esp, 0x10
    call get_text_color
    cwde
    cmp eax, 0xf
    jnz short .branch_37039
    test cx, cx
    setz al
    and eax, strict dword 0xff
    movsx edx, ax
    movsx eax, bx
    call prompt_video_mode
    mov eax, 0x1
    call set_background_color
    test cx, cx
    jz short .branch_3702e
    mov eax, 0xb
    jmp short .branch_37033

.branch_3702e:
    mov eax, 0x3

.branch_37033:
    cwde
    call set_text_color

.branch_37039:
    mov eax, ebx
    add eax, ebx
    add eax, strict dword 0x7
    push strict dword frame_state_a3e
    cwde
    push eax
    push strict byte 0x10
    inc ebx

.branch_3704c:
    call print_video_text_at
    add esp, 0xc
    movsx eax, bx
    cmp eax, 0x6
    jl near .branch_36faa
    mov eax, ebx
    add eax, ebx
    add eax, strict dword 0x5
    push strict dword frame_state_a1f
    cwde
    push eax
    push strict byte 0x10
    call print_video_text_at
    add esp, 0xc
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
