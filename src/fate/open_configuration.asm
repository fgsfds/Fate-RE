; Open configuration.
BITS 32
ORG 0x35732

strcpy equ 0x60333
malloc equ 0x6126d
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
free equ 0x6170a
close equ 0x6219a

open_configuration:
    push esi
    mov ecx, [esp + 0x8]
    mov ebx, [esp + 0xc]
    lea eax, [ecx + 0x4]
    mov edx, ebx
    call strcpy
    push strict dword 0x200
    push ebx
    call open
    mov esi, eax
    add esp, 0x8
    cmp eax, -1
    jnz short .branch_3575e

.branch_3575a:
    xor eax, eax
    pop esi
    ret

.branch_3575e:
    mov ebx, 0x2
    xor edx, edx
    call lseek
    xor ebx, ebx
    mov [ecx + 0x88], eax
    add eax, strict dword 0x400
    xor edx, edx
    mov [ecx + 0x8c], eax
    mov eax, esi
    call lseek
    mov eax, [ecx + 0x8c]
    call malloc
    mov edx, eax
    mov [ecx + 0x84], eax
    test eax, eax
    jnz short .branch_357a6
    mov eax, esi
    call close
    jmp short .branch_3575a

.branch_357a6:
    mov eax, esi
    mov ebx, [ecx + 0x88]
    call read
    cmp eax, [ecx + 0x88]
    jz short .branch_357cf
    mov eax, esi
    call close
    mov eax, [ecx + 0x84]
    call free
    jmp short .branch_3575a

.branch_357cf:
    mov eax, esi
    call close
    mov dword [ecx + 0x94], 0x0
    mov dword [ecx + 0xa0], 0x0
    mov dword [ecx + 0xa4], 0x0
    mov eax, [ecx + 0x84]
    mov dword [ecx + 0x9c], 0x0
    mov [ecx + 0x90], eax
    mov ah, [ecx + 0x1]
    mov dword [ecx + 0xa8], 0x0
    and ah, 0x7f
    mov [ecx + 0x1], ah
    mov eax, 0x1
    pop esi
    ret
