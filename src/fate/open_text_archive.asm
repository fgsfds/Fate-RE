; Open text archive.
BITS 32
ORG 0x3803e

text_archive_filename equ 0xbbc
text_archive_open equ 0x12d94
text_archive_handle equ 0x12d98
frame_state_12d9c equ 0x12d9c
frame_state_12da0 equ 0x12da0
frame_state_12da4 equ 0x12da4
open equ 0x61368
read equ 0x615f7

open_text_archive:
    push ebx
    push ecx
    push edx
    push edi
    push strict dword 0x200
    xor edx, edx
    push strict dword text_archive_filename
    mov ecx, 0x2e
    mov [text_archive_open], edx
    call open
    add esp, 0x8
    mov [text_archive_handle], eax
    cmp eax, -1
    jz short .branch_380af
    mov ebx, 0x1
    mov edi, 0xffffffff
    mov [frame_state_12da0], edx
    mov eax, ecx
    mov [text_archive_open], ebx
    mov [frame_state_12d9c], edi

.branch_38089:
    cmp eax, ecx
    jnz short .branch_380aa
    mov edx, frame_state_12da4
    mov eax, [text_archive_handle]
    mov ebx, ecx
    call read
    cmp eax, ecx
    jnz short .branch_38089
    inc dword [frame_state_12da0]
    jmp short .branch_38089

.branch_380aa:
    mov eax, 0x1

.branch_380af:
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
