; Retained row-address setup between unchanged compiler-generated C sections.
BITS 32
ORG 0x14359

level_sector_ids equ 0x7639c

update_gameplay_row_setup:
    mov ebp, edx
    movsx ecx, si
    shl ebp, 7
    mov eax, ecx
    mov ax, word [ebp + eax*4 + level_sector_ids]
