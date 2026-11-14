; DOS protected-mode services for locking and unlocking linear memory.
BITS 32
ORG 0x66391

%macro dpmi_region 1
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
    mov cx, [ebp + 8]
    mov bx, [ebp + 0xa]
    mov di, [ebp + 0xc]
    mov si, [ebp + 0xe]
    mov ax, %1
    int 0x31
    mov eax, 0
    jae short .return
    times 4 nop
    mov eax, 1
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
%endmacro

lock_memory_region:
    dpmi_region 0x0600

unlock_memory_region:
    dpmi_region 0x0601
