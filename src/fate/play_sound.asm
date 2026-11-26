; Load or reuse a sound sample and queue it for playback.
BITS 32
ORG 0x34f79
section .text align=1

invalid_sound_number equ 0x936
frame_state_12cd0 equ 0x12cd0
frame_state_12cd4 equ 0x12cd4
frame_state_12cd8 equ 0x12cd8
frame_state_12cec equ 0x12cec
sound_callback_return_offset equ 0x24c35
sound_sample_done_offset equ 0x24c36
audio_volume equ 0x34e1b
audio_pan equ 0x34e77
format_string equ 0x601f3
memset equ 0x61350
lseek equ 0x615b6
read equ 0x615f7
queue_audio_sample equ 0x621b4
error_buffer equ 0x67e3c
sound_slots equ 0x854dc
frame_state_16fb1c equ 0x16fb1c
frame_state_16fdac equ 0x16fdac
frame_state_16fdb0 equ 0x16fdb0
frame_state_1705dc equ 0x1705dc
sound_archive_handle equ 0x1714e0
audio_enabled equ 0x171602
frame_state_17160b equ 0x17160b
frame_state_17160f equ 0x17160f

play_sound:
    push esi
    push edi
    push ebp
    sub esp, 0x8
    mov edi, eax
    mov [esp + 0x4], edx
    mov ebp, ebx
    cmp byte [audio_enabled], 0x0
    jnz short .branch_34f9a

.branch_34f90:
    mov eax, 0xffffffff
    jmp near .branch_35265

.branch_34f9a:
    cmp dword [frame_state_12cd4], 0x0
    jz short .branch_34f90
    cmp dword [frame_state_12cd8], 0x0
    jz short .branch_34f90
    cmp edi, strict dword 0xa3
    jng short .branch_34fd0
    push strict dword invalid_sound_number
    push strict dword error_buffer
    call format_string
    mov eax, 0xffffffff
    add esp, 0x8
    jmp near .branch_35265

.branch_34fd0:
    xor eax, eax
    mov [frame_state_17160f], eax

.branch_34fd7:
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    cmp dword [eax], -1
    jnz short .branch_3500f
    mov edx, [frame_state_17160f]
    mov eax, edx
    shl eax, byte 0x4
    sub eax, edx
    mov esi, frame_state_1705dc
    shl eax, byte 0x4
    mov ebx, 0xf0
    add esi, eax
    xor edx, edx
    mov eax, esi
    call memset
    jmp short .branch_3502d

.branch_3500f:
    test cl, 0x4
    jz short .branch_3501d
    cmp edi, [eax + 0x4]
    jz near .branch_34f90

.branch_3501d:
    mov eax, [frame_state_17160f]
    inc eax
    mov [frame_state_17160f], eax
    cmp eax, 0x10
    jl short .branch_34fd7

.branch_3502d:
    mov ebx, [frame_state_17160f]
    cmp ebx, 0x10
    jz near .branch_34f90
    cmp dword [nosplit ebx*8 + frame_state_16fdb0], -1
    jz short .branch_3507b
    xor ebx, ebx
    mov [frame_state_17160b], ebx

.branch_3504e:
    mov eax, [frame_state_17160b]
    shl eax, byte 0x3
    cmp edi, [eax + frame_state_16fdb0]
    jnz short .branch_35069
    mov eax, [eax + frame_state_16fdac]
    jmp near .branch_350f1

.branch_35069:
    mov ebx, [frame_state_17160b]
    inc ebx
    mov [frame_state_17160b], ebx
    cmp ebx, 0x10
    jl short .branch_3504e

.branch_3507b:
    cmp dword [frame_state_17160f], 0x10
    jz near .branch_34f90
    mov eax, edi
    shl eax, byte 0x2
    mov [esp], eax
    mov eax, [eax + frame_state_16fb1c]
    xor ebx, ebx
    mov edx, [eax + 0x4]
    mov eax, [sound_archive_handle]
    call lseek
    mov eax, [esp]
    mov eax, [eax + frame_state_16fb1c]
    mov ebx, [eax + 0x8]
    mov eax, [frame_state_17160f]
    mov edx, [nosplit eax*8 + frame_state_16fdac]
    mov eax, [sound_archive_handle]
    call read
    mov edx, [esp]
    mov edx, [edx + frame_state_16fb1c]
    mov [frame_state_12cec], eax
    cmp eax, [edx + 0x8]
    jnz near .branch_34f90
    mov eax, [frame_state_17160f]
    mov [nosplit eax*8 + frame_state_16fdb0], edi
    mov eax, [nosplit eax*8 + frame_state_16fdac]

.branch_350f1:
; Descriptor initialization is supplied by sound_playback_description.c.
; Positioning and callback setup are supplied by compiler-generated C.
section .sound_tail align=1 vstart=0x351c8 follows=.text
.branch_351c8:
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov [eax + 0x4], edi
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov [eax + 0x18], ecx
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov edx, [esp + 0x4]
    mov [eax + 0x10], edx
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov [eax + 0x14], ebp
    mov edx, esi
    mov eax, [frame_state_12cd0]
    call queue_audio_sample
    mov edx, eax
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov [eax], edx
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov edx, [eax]
    cmp edx, -1
    jnz short .branch_35260
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov word [eax + 0xe], 0x0
    mov eax, [frame_state_17160f]
    mov eax, [nosplit eax*4 + sound_slots]
    mov dword [eax + 0x18], 0x0
    mov eax, edx
    jmp short .branch_35265

.branch_35260:
    mov eax, [frame_state_17160f]

.branch_35265:
    add esp, 0x8
    pop ebp
    pop edi
    pop esi
    ret
