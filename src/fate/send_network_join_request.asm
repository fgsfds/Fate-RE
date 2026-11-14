; Send network join request.
BITS 32
ORG 0x43590

transport equ 0x13cde
send_packet equ 0x424ec
frame_state_18fdc3 equ 0x18fdc3
frame_state_18fe0c equ 0x18fe0c
frame_state_18fe30 equ 0x18fe30

send_network_join_request:
    push ebx
    push edx
    sub esp, 0x10
    cmp byte [transport], 0x0
    jna near .branch_43676
    xor eax, eax
    mov dl, 0xfd
    mov al, [transport]
    mov [esp], dl
    cmp eax, 0x5
    jnl short .branch_43615
    mov edx, 0x40
    in al, dx
    mov edx, 0x40
    mov [esp + 0x1], al
    in al, dx
    mov edx, 0x40
    mov [esp + 0x2], al
    in al, dx
    mov edx, eax
    mov [esp + 0x3], al
    mov al, [frame_state_18fe0c]
    mov [esp + 0x4], al
    xor eax, eax
    xor ebx, ebx
    mov al, [esp + 0x2]
    mov bl, [esp + 0x1]
    shl eax, byte 0x8
    add ebx, eax
    xor eax, eax
    mov al, dl
    shl eax, byte 0x10
    lea edx, [ebx + eax]
    mov eax, [frame_state_18fe0c]
    shl eax, byte 0x18
    mov ebx, 0x5
    add edx, eax
    mov eax, 0xffffffff
    mov [frame_state_18fe30], edx
    mov edx, esp
    jmp short .branch_43671

.branch_43615:
    mov al, [frame_state_18fe30]
    mov [esp + 0x1], al
    mov eax, [frame_state_18fe30]
    sar eax, byte 0x8
    and eax, strict dword 0xff
    mov [esp + 0x2], al
    mov eax, [frame_state_18fe30]
    sar eax, byte 0x10
    and eax, strict dword 0xff
    mov [esp + 0x3], al
    mov eax, [frame_state_18fe30]
    sar eax, byte 0x18
    and eax, strict dword 0xff
    mov [esp + 0x4], al
    xor eax, eax
    jmp short .branch_43660

.branch_43655:
    inc eax
    mov dl, [eax + frame_state_18fdc3]
    mov [esp + eax + 0x4], dl

.branch_43660:
    cmp eax, 0xa
    jl short .branch_43655
    mov ebx, 0xf
    mov edx, esp
    mov eax, 0xffffffff

.branch_43671:
    call send_packet

.branch_43676:
    add esp, 0x10
    pop edx
    pop ebx
    ret
