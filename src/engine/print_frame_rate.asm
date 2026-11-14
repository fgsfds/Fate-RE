; Print the average frame rate from elapsed engine ticks.
BITS 32
ORG 0x4c036

frame_rate_format equ 0x1bdf
print_diagnostic equ 0x40bb4
frame_count equ 0x287e74
totalclock equ 0x287e88

print_frame_rate:
    push ebx
    push ecx
    push edx
    cmp dword [totalclock], 0x0
    jz short .branch_4c0ac
    mov edx, [frame_count]
    mov eax, edx
    shl eax, byte 0x2
    sub eax, edx
    shl eax, byte 0x4
    sub eax, edx
    shl eax, byte 0x3
    sub eax, edx
    shl eax, byte 0x5
    mov edx, eax
    sar edx, byte 0x1f
    mov ebx, [totalclock]
    idiv ebx
    mov edx, eax
    mov ecx, 0xa
    sar edx, byte 0x1f
    mov ebx, eax
    idiv ecx
    movsx eax, dx
    push eax
    mov edx, ebx
    mov eax, ebx
    sar edx, byte 0x1f
    idiv ecx
    mov edx, eax
    sar edx, byte 0x1f
    idiv ecx
    movsx eax, dx
    mov ecx, 0x64
    push eax
    mov edx, ebx
    mov eax, ebx
    sar edx, byte 0x1f
    idiv ecx
    cwde
    push eax
    push strict dword frame_rate_format
    call print_diagnostic
    add esp, 0x10

.branch_4c0ac:
    pop edx
    pop ecx
    pop ebx
    ret
