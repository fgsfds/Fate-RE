; Dpmi real mode far call.
BITS 32
ORG 0x438f9

memset equ 0x61350
segread equ 0x63072
int386x equ 0x6309a

dpmi_real_mode_far_call:
    push esi
    push edi
    push ebp
    sub esp, 0x5c
    push eax
    mov ebp, edx
    mov esi, ebx
    mov edi, ecx
    mov ebx, 0x32
    lea eax, [esp + 0x4]
    xor edx, edx
    call memset
    xor eax, eax
    mov ax, [ebp + 0x0]
    mov [esp + 0x20], eax
    xor eax, eax
    mov ax, [ebp + 0x2]
    mov [esp + 0x14], eax
    xor eax, eax
    mov ax, [ebp + 0x4]
    mov [esp + 0x1c], eax
    xor eax, eax
    mov ax, [ebp + 0x6]
    mov [esp + 0x18], eax
    xor eax, eax
    mov ax, [ebp + 0x8]
    mov [esp + 0x8], eax
    xor eax, eax
    mov ax, [ebp + 0xa]
    mov [esp + 0x4], eax
    mov ax, [ecx]
    mov [esp + 0x26], ax
    mov edx, 0x300
    mov ax, [ecx + 0x6]
    xor ebx, ebx
    mov [esp + 0x28], ax
    lea eax, [esp + 0x54]
    lea ecx, [esp + 0x54]
    call segread
    mov al, [esp]
    mov [esp + 0x38], dx
    mov [esp + 0x3c], al
    xor ah, ah
    mov [esp + 0x40], bx
    mov [esp + 0x3d], ah
    mov eax, [esp + 0x5a]
    lea ebx, [esp + 0x38]
    mov [esp + 0x54], ax
    lea eax, [esp + 0x4]
    lea edx, [esp + 0x38]
    mov [esp + 0x4c], eax
    mov eax, 0x31
    call int386x
    cld
    mov ax, ds
    mov es, eax
    mov eax, [esp + 0x20]
    mov [esi], ax
    mov eax, [esp + 0x14]
    mov [esi + 0x2], ax
    mov eax, [esp + 0x1c]
    mov [esi + 0x4], ax
    mov eax, [esp + 0x18]
    mov [esi + 0x6], ax
    mov eax, [esp + 0x8]
    mov [esi + 0x8], ax
    mov eax, [esp + 0x4]
    mov [esi + 0xa], ax
    mov eax, [esp + 0x26]
    mov [edi], ax
    mov eax, [esp + 0x30]
    mov [edi + 0x2], ax
    mov eax, [esp + 0x34]
    mov [edi + 0x4], ax
    mov eax, [esp + 0x28]
    mov [edi + 0x6], ax
    mov eax, [esp + 0x24]
    xor ah, ah
    and al, 0x1
    mov [esi + 0xc], ax
    xor eax, eax
    mov ax, [esi]
    add esp, 0x60
    pop ebp
    pop edi
    pop esi
    ret
