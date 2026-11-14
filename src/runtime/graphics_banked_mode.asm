; Translate a VBE mode request and install the banked graphics layout.
BITS 32
ORG 0x70b06

probe_video_adapter equ 0x72ed2
set_extended_graphics_mode equ 0x70774
apply_graphics_mode_state equ 0x6fe1e

vendor_mode_numbers equ 0x16f48
bank_selector_table equ 0x171c8
select_bank equ 0x2891e8
current_bank equ 0x289249
graphics_buffer_offset equ 0x16d0d
graphics_buffer_selector equ 0x16cfd
text_columns equ 0x289200
text_rows equ 0x289202
adapter_class equ 0x28920c
video_mode equ 0x28920a

banked_layout_table:
    dd set_banked_graphics_mode.mode_100 - 0x10000
    dd set_banked_graphics_mode.mode_101 - 0x10000
    dd set_banked_graphics_mode.mode_102 - 0x10000
    dd set_banked_graphics_mode.mode_103 - 0x10000
    dd set_banked_graphics_mode.mode_104 - 0x10000
    dd set_banked_graphics_mode.mode_105 - 0x10000

set_banked_graphics_mode:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, eax
    call probe_video_adapter
    mov edx, eax
    mov ebx, eax
    test ax, ax
    je near .done
    cmp ax, strict word 1
    jne short .translate_mode
    mov eax, esi
    jmp short .check_mode
.translate_mode:
    cwde
    dec eax
    dec eax
    imul edx, eax, 0xc
    movsx eax, si
    mov ax, word [edx + eax*2 + vendor_mode_numbers]
.check_mode:
    test ax, ax
    je near .done
    movsx ebx, bx
    movsx edx, ax
    mov eax, ebx
    call set_extended_graphics_mode
    test ax, ax
    je near .done
    mov eax, dword [ebx*4 + bank_selector_table]
    mov dword [select_bank], eax
    mov eax, esi
    db 0x81, 0xe8 ; SUB EAX, imm32, original non-accumulator encoding.
    dd 0x100
    mov byte [current_bank], 0xff
    cmp ax, strict word 5
    ja near .publish_mode
    movzx eax, ax
    jmp dword cs:[eax*4 + banked_layout_table - 0x10000]
.mode_100:
    push 2
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x190
    mov ebx, 0x100
    push 1
    mov ecx, 8
    mov eax, 0x280
    call apply_graphics_mode_state
    mov word [text_columns], 0x50
    mov word [text_rows], 0x19
    jmp near .publish_mode
.mode_101:
    push 2
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x1e0
    mov ebx, 0x100
    push 1
    mov ecx, 8
    mov eax, 0x280
    call apply_graphics_mode_state
    mov word [text_columns], 0x50
    mov word [text_rows], 0x1e
    jmp near .publish_mode
.mode_102:
    push 3
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x258
    mov ebx, 0x10
    push 1
    mov ecx, 4
.apply_800:
    mov eax, 0x320
    call apply_graphics_mode_state
    mov word [text_columns], 0x64
    mov word [text_rows], 0x28
    jmp near .publish_mode
.mode_103:
    push 2
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x258
    mov ebx, 0x100
    push 1
    mov ecx, 8
    jmp short .apply_800
.mode_104:
    push 3
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x300
    mov ebx, 0x10
    push 1
    mov ecx, 4
    jmp short .apply_1024
.mode_105:
    push 2
    push 0
    push dword [graphics_buffer_offset]
    movsx eax, word [graphics_buffer_selector]
    push eax
    mov edx, 0x300
    mov ebx, 0x100
    push 1
    mov ecx, 8
.apply_1024:
    mov eax, 0x400
    call apply_graphics_mode_state
    mov word [text_columns], 0x80
    mov word [text_rows], 0x32
.publish_mode:
    mov word [adapter_class], 7
    mov eax, 1
    mov word [video_mode], si
.done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
