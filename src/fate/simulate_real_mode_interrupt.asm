; Simulate real mode interrupt.
BITS 32
ORG 0x375e9

memset equ 0x61350
segread equ 0x63072
int386x equ 0x6309a

simulate_real_mode_interrupt:
    push ebx
    push ecx
    push esi
    sub esp, 0x28
    mov esi, eax
    mov ecx, edx
    mov ebx, 0x1c
    mov eax, esp
    xor edx, edx
    call memset
    lea eax, [esp + 0x1c]
    mov edx, 0x300
    call segread
    xor ebx, ebx
    movsx eax, si
    mov [esp], edx
    mov [esp + 0x4], eax
    mov edx, ds
    mov eax, ecx
    mov [esp + 0x8], ebx
    mov [esp + 0x1c], dx
    mov [esp + 0x14], ecx
    mov word [ecx + 0x2e], 0x0
    mov word [ecx + 0x20], 0x0
    mov ebx, esp
    mov ax, [ecx + 0x2e]
    mov edx, esp
    mov [ecx + 0x30], ax
    lea ecx, [esp + 0x1c]
    mov eax, 0x31
    call int386x
    add esp, 0x28
    pop esi
    pop ecx
    pop ebx
    ret
