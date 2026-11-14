; Print video text.
BITS 32
ORG 0x36adf

vsprintf equ 0x62eca
output_text_string equ 0x6eaae

print_video_text:
    push ebx
    push edx
    sub esp, 0x54
    lea eax, [esp + 0x64]
    lea ebx, [esp + 0x50]
    mov edx, [esp + 0x60]
    mov [esp + 0x50], eax
    mov eax, esp
    call vsprintf
    xor edx, edx
    mov eax, esp
    mov [esp + 0x50], edx
    call output_text_string
    add esp, 0x54
    pop edx
    pop ebx
    ret
