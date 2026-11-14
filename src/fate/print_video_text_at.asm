; Print video text at.
BITS 32
ORG 0x36b0e

print_video_text equ 0x36adf
branch_36b08 equ 0x36b08
strlen equ 0x60381
vsprintf equ 0x62eca
set_text_position equ 0x6ebf2

print_video_text_at:
    push ebx
    push edx
    sub esp, 0x54
    lea eax, [esp + 0x6c]
    lea ebx, [esp + 0x50]
    mov edx, [esp + 0x68]
    mov [esp + 0x50], eax
    mov eax, esp
    call vsprintf
    xor edx, edx
    movsx eax, word [esp + 0x60]
    mov [esp + 0x50], edx
    cmp eax, -1
    jnz short .branch_36b4e
    mov eax, esp
    mov edx, 0x28
    call strlen
    shr eax, 1
    sub edx, eax
    mov [esp + 0x60], edx

.branch_36b4e:
    movsx edx, word [esp + 0x60]
    movsx eax, word [esp + 0x64]
    call set_text_position
    mov eax, esp
    push eax
    call print_video_text
    add esp, 0x4
    jmp short branch_36b08
