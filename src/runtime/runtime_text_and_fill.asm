; Fill memory, flush streams, format strings and handle console text.
BITS 32
ORG 0x62dce


    times 14 db 0    ; toupper is placed here from C.

toupper_padding:
    times 4 db 0

fill_byte_pattern:
    or ecx, ecx
    je short .return
    cmp byte [eax], dl

.align_byte_destination:
    test al, 3
    je short .fill_words
    mov byte [eax], dl
    inc eax
    ror edx, 8
    dec ecx
    jne short .align_byte_destination

.fill_words:
    push ecx
    shr ecx, 2
    call fill_dword_pattern
    pop ecx
    and ecx, 3
    je short .return
    mov byte [eax], dl
    dec ecx
    je short .return
    mov byte [eax + 1], dh
    dec ecx
    je short .return
    mov byte [eax + 2], dl

.return:
    ret

fill_alignment:
    times 6 nop

fill_dword_pattern:
    or ecx, ecx
    je short .return

.align_dword_destination:
    test al, 0x1f
    je short .fill_blocks
    mov dword [eax], edx
    lea eax, [eax + 4]
    dec ecx
    jne short .align_dword_destination

.fill_blocks:
    push ecx
    shr ecx, 2
    je short .store_tail
    dec ecx
    je short .store_four_dwords

.store_dword_pairs:
    mov dword [eax], edx
    mov dword [eax + 4], edx
    dec ecx
    mov dword [eax + 8], edx
    mov dword [eax + 0xc], edx
    je short .advance_half_block
    cmp byte [eax + 0x20], dl
    mov dword [eax + 0x10], edx
    mov dword [eax + 0x14], edx
    dec ecx
    mov dword [eax + 0x18], edx
    mov dword [eax + 0x1c], edx
    lea eax, [eax + 0x20]
    jne short .store_dword_pairs
    lea eax, [eax - 0x10]

.advance_half_block:
    lea eax, [eax + 0x10]

.store_four_dwords:
    mov dword [eax], edx
    mov dword [eax + 4], edx
    mov dword [eax + 8], edx
    mov dword [eax + 0xc], edx
    lea eax, [eax + 0x10]

.store_tail:
    pop ecx
    and ecx, 3
    je short .return
    mov dword [eax], edx
    lea eax, [eax + 4]
    dec ecx
    je short .return
    mov dword [eax], edx
    lea eax, [eax + 4]
    dec ecx
    je short .return
    mov dword [eax], edx
    lea eax, [eax + 4]

.return:
    ret

    times 52 db 0    ; flushall and flush_matching_streams are placed here from C.

    times 40 db 0    ; vsprintf and its callback are placed here from C.

    times 29 db 0    ; getch is supplied by C.

    times 31 db 0    ; strupr is placed here from C.

    times 194 db 0    ; strstr is supplied by C.

    times 149 db 0    ; strtok is supplied by C.
