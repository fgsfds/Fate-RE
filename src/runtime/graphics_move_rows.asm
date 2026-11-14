; Move rows through the graphics device or directly within text video memory.
BITS 32
ORG 0x6f796

begin_graphics_device equ 0x70052
end_graphics_device equ 0x7005b
set_drawing_action equ 0x71950
bitmap_row_bytes equ 0x71b4a
graphics_stack_limit equ 0x71b86

graphics_error equ 0x16c66
active_text_page equ 0x16c78
bios_data_selector equ 0x16cf7
mono_text_selector equ 0x16cf9
color_text_selector equ 0x16cfb
bios_data_offset equ 0x16d01
mono_text_offset equ 0x16d05
color_text_offset equ 0x16d09
pixel_address equ 0x2891ec
pixel_selector equ 0x2891f0
pixel_bit_offset equ 0x2891f6
text_columns equ 0x289200
graphics_colors equ 0x289206
video_mode equ 0x28920a
video_device equ 0x289212

; Both entries take the first and last columns on the stack.
; EAX and EDX are source and destination rows, EBX is the signed step,
; and ECX is the number of rows.
move_graphics_rows:
    push esi
    push edi
    push es
    enter 40, 0
    push eax
    push edx
    push ebx
    push ecx
    mov eax, [ebp+24]
    sub eax, [ebp+20]
    inc eax
    mov [ebp-12], eax
    cwde
    call bitmap_row_bytes
    add eax, strict dword 3
    and al, 0xfc
    mov esi, eax
    mov eax, esp
    mov edx, eax
    call graphics_stack_limit
    sub edx, eax
    movsx eax, si
    sub edx, eax
    cmp edx, 0x100
    ja short .allocate_row
    mov word [graphics_error], -5
    jmp near move_rows_return
.allocate_row:
    add eax, 3
    and al, 0xfc
    sub esp, eax
    mov [ebp-36], esp
    mov eax, 3
    call set_drawing_action
    mov [ebp-8], eax
    call begin_graphics_device
    mov eax, [video_device]
    mov [ebp-32], eax
    mov eax, [eax+0x44]
    mov [ebp-40], eax
    mov eax, [ebp-32]
    mov eax, [eax+0x40]
    mov [ebp-20], eax
    movsx eax, si
    movsx ebx, word [graphics_colors]
    cdq
    idiv ebx
    mov [ebp-16], eax
.next_row:
    cmp word [ebp-56], 0
    je near .restore_action
    movsx edx, word [ebp-44]
    movsx eax, word [ebp+20]
    mov edi, [ebp-32]
    mov [ebp-4], ds
    xor ebx, ebx
    mov [ebp-28], eax
    call [edi+0x10]
    movsx eax, word [ebp-12]
    mov edi, [ebp-36]
    movsx edx, word [pixel_bit_offset]
    mov si, [pixel_selector]
    mov [ebp-24], eax
    xor ebx, ebx
    mov ecx, [ebp-24]
    mov eax, [pixel_address]
    mov es, [ebp-4]
    call [ebp-40]
    movsx edx, word [ebp-48]
    mov eax, [ebp-28]
    mov edi, [ebp-32]
    mov esi, [ebp-4]
    xor ebx, ebx
    mov ecx, [ebp-24]
    call [edi+0x10]
    movsx ebx, word [ebp-16]
    mov eax, [ebp-36]
    movsx edx, word [pixel_bit_offset]
    mov es, [pixel_selector]
    shl edx, 8
    mov edi, [pixel_address]
    call [ebp-20]
    mov eax, [ebp-52]
    dec dword [ebp-56]
    add [ebp-44], eax
    add [ebp-48], eax
    jmp near .next_row
.restore_action:
    call end_graphics_device
    movsx eax, word [ebp-8]
    call set_drawing_action
move_rows_return:
    leave
    pop es
    pop edi
    pop esi
    ret 8

move_text_rows:
    push esi
    push edi
    push es
    enter 28, 0
    mov esi, eax
    mov [ebp-24], edx
    mov [ebp-12], ebx
    mov [ebp-16], ecx
    cmp word [video_mode], 7
    jne short .color_buffer
    mov eax, [mono_text_offset]
    mov cx, [mono_text_selector]
    jmp short .locate_page
.color_buffer:
    mov eax, [color_text_offset]
    mov cx, [color_text_selector]
.locate_page:
    mov ebx, [bios_data_offset]
    mov es, [bios_data_selector]
    add ebx, 0x4c
    movsx edx, word [es:ebx]
    movsx ebx, word [active_text_page]
    imul edx, ebx
    movsx ebx, si
    add eax, edx
    movsx edx, word [text_columns]
    mov esi, ebx
    imul esi, edx
    movsx ebx, word [ebp+20]
    add esi, ebx
    add esi, esi
    lea edi, [eax+esi]
    movsx esi, word [ebp-24]
    imul edx, esi
    add ebx, edx
    add ebx, ebx
    add ebx, eax
    mov eax, [ebp-12]
    imul ax, [text_columns]
    mov [ebp-12], eax
    mov eax, [ebp+24]
    mov [ebp-8], ecx
    sub eax, [ebp+20]
    mov [ebp-4], ecx
    inc eax
    mov [ebp-28], edi
    add eax, eax
    mov edx, [ebp-4]
    mov [ebp-20], eax
.next_row:
    cmp word [ebp-16], 0
    je near move_rows_return
    movsx eax, word [ebp-20]
    mov ecx, [ebp-8]
    mov esi, [ebp-28]
    mov edi, ebx
    push ds
    push es
    push edi
    xchg eax, ecx
    mov ds, ax
    mov es, dx
    mov eax, ecx
    shr ecx, 2
    repne movsd
    db 0x8a, 0xc8 ; mov cl, al using the register-load opcode
    and cl, 3
    repne movsb
    pop eax
    pop es
    pop ds
    movsx eax, word [ebp-12]
    add eax, eax
    dec dword [ebp-16]
    add [ebp-28], eax
    add ebx, eax
    jmp short .next_row
