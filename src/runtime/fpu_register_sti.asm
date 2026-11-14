; x87 register operations with ST(i) as the destination.
BITS 32
ORG 0x69069

decode_next equ 0x67e50
compare_extended equ 0x6973a
update_flags_pop equ 0x67ff2
update_flags equ 0x68044
mark_empty_and_pop equ 0x68009
add_extended equ 0x69574
multiply_extended equ 0x699a8
subtract_extended equ 0x69566
divide_extended equ 0x697d3
skip_register equ 0x68984
reset_emulator equ 0x69043
tag_clear equ 0x57a9e
tag_empty equ 0x57aa6
next_top equ 0x57a4e
top_bits equ 0x57a52


fadd_sti_st0:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call add_extended
    jmp dword ds:[ebp + 0x76]

fmul_sti_st0:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call multiply_extended
    jmp dword ds:[ebp + 0x76]

fsubr_sti_st0:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fsub_sti_st0:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fdivr_sti_st0:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fdiv_sti_st0:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

ffree_sti:
    mov bx, word cs:[esi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[esi + tag_empty]
    or word ds:[ebp + 8], bx
    jmp near decode_next

fst_sti:
    mov eax, dword [edi + ebp + 0x1c]
    mov dword [esi + ebp + 0x1c], eax
    mov eax, dword [edi + ebp + 0x20]
    mov dword [esi + ebp + 0x20], eax
    mov ax, word [edi + ebp + 0x24]
    mov word [esi + ebp + 0x24], ax
    mov bx, word cs:[esi + tag_clear]
    and word ds:[ebp + 8], bx
    jmp near decode_next

fucom_sti:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    call compare_extended
    jmp near update_flags

fucomp_sti:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    call compare_extended
    jmp near update_flags_pop

fstp_sti:
    mov eax, dword [edi + ebp + 0x1c]
    mov dword [esi + ebp + 0x1c], eax
    mov eax, dword [edi + ebp + 0x20]
    mov dword [esi + ebp + 0x20], eax
    mov ax, word [edi + ebp + 0x24]
    mov word [esi + ebp + 0x24], ax
    mov bx, word cs:[esi + tag_clear]
    and word ds:[ebp + 8], bx
    jmp near mark_empty_and_pop
