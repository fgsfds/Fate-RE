; Query length and restore the original descriptor position.
BITS 32
ORG 0x63208
lseek equ 0x615b6

filelength_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ecx, eax
    mov ebx, 1
    xor edx, edx
    call lseek
    mov esi, eax
    cmp eax, -1
    je short .restore_registers
    mov ebx, 2
    mov eax, ecx
    xor edx, edx
    call lseek
    mov edi, eax
    mov edx, esi
    xor ebx, ebx
    mov eax, ecx
    call lseek
    mov eax, edi

.restore_registers:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
