; Rotate a point around a pivot using the Build sine table.
BITS 32
ORG 0x5437c

restore_rotatepoint_registers equ 0x4c28a
sintable equ 0x2300a0

rotatepoint:
    push esi
    push edi
    push ebp
    sub esp, 0x4
    push eax
    push edx
    mov ebp, ebx
    movsx esi, word [esp + 0x1c]
    lea eax, [esi + 0xa00]
    and eax, strict dword 0x7ff
    mov edx, [esp + 0x4]
    mov ebx, [esp]
    movsx eax, word [nosplit eax*2 + sintable]
    sub ebp, edx
    mov [esp + 0x8], eax
    lea eax, [esi + 0x800]
    sub ecx, ebx
    and eax, strict dword 0x7ff
    mov ebx, [esp + 0x8]
    mov esi, ecx
    movsx eax, word [nosplit eax*2 + sintable]
    neg esi
    mov edi, eax
    mov eax, ebp
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0xe
    mov esi, [esp + 0x4]
    add esi, eax
    mov eax, [esp + 0x20]
    mov ebx, [esp + 0x8]
    mov [eax], esi
    mov esi, ebp
    mov eax, ecx
    mov ecx, [esp]
    imul ebx
    xchg eax, esi
    mov ebx, edx
    imul edi
    add eax, esi
    adc edx, ebx
    shrd eax, edx, byte 0xe
    add ecx, eax
    mov eax, [esp + 0x24]
    mov [eax], ecx
    jmp near restore_rotatepoint_registers
