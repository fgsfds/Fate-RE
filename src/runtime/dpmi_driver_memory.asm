; Allocate a driver selector and memory block, free them, or create a code alias.
BITS 32
ORG 0x6640b

driver_selector equ 0x16c00

allocate_driver_memory:
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    mov ax, 0
    mov cx, 1
    int 0x31
    push eax
    mov word [driver_selector], ax
    push eax
    db 0x66, 0x8b, 0xd8 ; MOV BX, AX, register-destination encoding.
    mov ax, 8
    db 0x66, 0x33, 0xc9 ; XOR CX, CX, register-destination encoding.
    mov edx, dword [ebp + 8]
    int 0x31
    pop eax
    mov ax, 0x501
    db 0x33, 0xdb ; XOR EBX, EBX, register-destination encoding.
    mov ecx, dword [ebp + 8]
    add cx, 0x50
    int 0x31
    jae short .store_handle_and_base
    nop
    nop
    nop
    nop
    pop eax
    mov eax, 0
    mov edx, 0
    jmp short .return
    nop
    nop
    nop

.store_handle_and_base:
    push ebx
    mov ebx, dword [ebp + 0xc]
    mov word [ebx], si
    mov word [ebx + 2], di
    pop ebx
    pop eax
    push eax
    mov esi, dword [ebp + 0x10]
    mov word [esi], cx
    mov word [esi + 2], bx
    db 0x66, 0x8b, 0xd1 ; MOV DX, CX, register-destination encoding.
    db 0x66, 0x8b, 0xcb ; MOV CX, BX, register-destination encoding.
    db 0x66, 0x8b, 0xd8 ; MOV BX, AX, register-destination encoding.
    mov ax, 7
    int 0x31
    movzx ecx, word [driver_selector]
    lar ecx, ecx
    shr ecx, 8
    or cx, 0x4000
    mov bx, word [driver_selector]
    mov ax, 9
    int 0x31
    pop eax
    db 0x33, 0xd2 ; XOR EDX, EDX, register-destination encoding.
    db 0x66, 0x8b, 0xd0 ; MOV DX, AX, register-destination encoding.
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.

.return:
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

release_driver_memory:
    push eax
    mov ax, ds
    mov gs, ax
    pop eax
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    mov si, word [ebp + 0x10]
    mov di, word [ebp + 0x12]
    mov ax, 0x502
    int 0x31
    mov ax, 1
    mov bx, word [ebp + 0xc]
    int 0x31
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

get_driver_alias:
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    mov ax, 0
    mov cx, 1
    int 0x31
    push eax
    push eax
    push eax
    push eax
    mov bx, word [ebp + 0xc]
    mov ax, 6
    int 0x31
    pop ebx
    mov ax, 7
    int 0x31
    db 0x33, 0xdb ; XOR EBX, EBX, register-destination encoding.
    mov bx, word [ebp + 0xc]
    lsl edx, ebx
    mov ax, 8
    pop ebx
    db 0x33, 0xc9 ; XOR ECX, ECX, register-destination encoding.
    int 0x31
    mov ax, 9
    pop ebx
    lar ecx, ebx
    shr ecx, 8
    or cx, 0x4008
    int 0x31
    pop edx
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret
