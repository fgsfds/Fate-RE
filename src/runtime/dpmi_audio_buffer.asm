; Allocate and release an audio buffer in DOS conventional memory.
BITS 32
ORG 0x6654a

%macro save_registers 0
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
%endmacro

%macro restore_registers 0
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret
%endmacro

allocate_dos_buffer:
    save_registers
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    mov ax, 0x100
    mov ebx, [ebp + 8]
    add ebx, 0x100
    int 0x31
    mov esi, [ebp + 0xc]
    shl eax, 4
    mov [esi], eax
    mov esi, [ebp + 0x10]
    mov [esi], dx
    restore_registers

release_dos_buffer:
    mov ax, ds
    mov gs, ax
    mov es, ax
    mov fs, ax
    save_registers
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    mov ax, 0x101
    mov edx, [ebp + 8]
    int 0x31
    restore_registers

copy_far_driver_interface_raw:
    save_registers
    mov eax, 8
    lfs edi, [ebp + 0x10]
    mov dx, ds
    call far [ebp + 8]
    push ds
    push ds
    pop es
    mov edi, [ebp + 0x18]
    lds esi, [ebp + 0x10]
    db 0x8b, 0xf2 ; MOV ESI, EDX, register-destination encoding.
    mov ecx, 0x6a
    cld
    rep movsb
    pop ds
    restore_registers
