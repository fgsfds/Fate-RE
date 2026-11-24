; Original dispatch and frame/register transitions between checked C suppliers.
; Prompt video mode.
BITS 32
ORG 0x36cf1

frame_state_12d48 equ 0x12d48
frame_state_12d4e equ 0x12d4e
frame_state_12d54 equ 0x12d54
frame_state_12d60 equ 0x12d60
frame_state_12d64 equ 0x12d64
frame_state_12d68 equ 0x12d68
video_default_height_offset equ 0x26950
set_background_color equ 0x6f1bf
set_text_color equ 0x6f25d
frame_state_173d56 equ 0x173d56

prompt_video_mode equ 0x36d0a
prompt_video_mode_dispatch equ 0x36cf2
prompt_video_mode_asm:
    nop
    dd 0x26d45
    dd 0x26d66
    dd 0x26d87
    dd 0x26d87
    dd 0x26d87
    dd 0x26d87
section .gap0 align=1 vstart=0x36d24 follows=.text
; video_prompt_original_setup
    mov [esp + 0x10], eax
    mov ax, [video_default_height_offset]
    mov [esp + 0xc], eax
    cmp bx, 0x5
    ja short 0x36da1
    xor eax, eax
    mov ax, bx
    jmp dword near [cs:eax*4 + prompt_video_mode_dispatch - 0x10000]
    mov ebp, frame_state_12d54
    mov ebx, frame_state_12d48
    mov esi, frame_state_12d4e
    mov edi, 0x3
    mov [esp + 0x4], ebx
    mov [frame_state_173d56], di
    jmp short 0x36da1
    mov ebp, frame_state_12d68
    mov edx, frame_state_12d60
    mov esi, frame_state_12d64
    mov ebx, 0x2
    mov [esp + 0x4], edx
    mov [frame_state_173d56], bx
    jmp short 0x36da1
    mov ebp, esp
    lea eax, [esp + 0x10]
    lea esi, [esp + 0xc]
    mov edx, 0x1
    mov [esp + 0x4], eax
    mov [frame_state_173d56], dx
section .gap1 align=1 vstart=0x36dc0 follows=.gap0
; video_prompt_original_search
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
section .gap2 align=1 vstart=0x36e27 follows=.gap1
; video_prompt_original_limit
    mov [esp + 0x14], eax
    test cx, cx
section .gap3 align=1 vstart=0x36e70 follows=.gap2
; video_prompt_original_brightness
    test cx, cx
section .gap4 align=1 vstart=0x36eb6 follows=.gap3
; video_prompt_original_selected_row
    test cx, cx
    jz short 0x36ec2
    mov eax, 0x7
    jmp short 0x36ec7
    mov eax, 0x1
    call set_background_color
    mov eax, 0xf
    call set_text_color
    movsx eax, dx
    mov di, [ebp + eax*4 + 0x0]
    mov ax, [ebp + eax*4 + 0x2]
    cwde
    movsx eax, word [esi + eax*2]
    mov [esp + 0x8], edi
section .gap5 align=1 vstart=0x36f2b follows=.gap4
; video_prompt_original_row_step
    test cx, cx
    jz short 0x36f37
    mov eax, 0xb
    jmp short 0x36f3c
    mov eax, 0x3
    cwde
    call set_text_color
    inc edx
    mov eax, edx
    add eax, strict dword 0x6
    mov edi, [esp + 0x14]
