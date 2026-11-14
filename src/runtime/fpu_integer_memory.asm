; Dispatch x87 signed 32-bit integer memory operations.
BITS 32
ORG 0x6837b

extend_integer equ 0x69b92
add_extended equ 0x69574
multiply_extended equ 0x699a8
compare_extended equ 0x6973a
subtract_extended equ 0x69566
divide_extended equ 0x697d3
round_to_integer equ 0x69e63
pack_integer equ 0x69b23
update_flags equ 0x68044
update_flags_pop equ 0x67ff2
decode_next equ 0x67e50
mark_empty_and_pop equ 0x68009
previous_top equ 0x57a50
top_bits equ 0x57a52
tag_clear equ 0x57a9e

fiadd_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call add_extended
    jmp dword ds:[ebp + 0x76]

fimul_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call multiply_extended
    jmp dword ds:[ebp + 0x76]

ficom_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags

ficomp_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags_pop

fisub_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fisubr_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fidiv_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fidivr_m32int:
    mov eax, dword es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_integer
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fild_m32int:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov eax, dword es:[esi]
    lea edx, [edi + ebp + 0x1c]
    call extend_integer
    jmp near decode_next

fist_m32int:
    lea ebx, [edi + ebp + 0x1c]
    push dword [ebx]
    push dword [ebx + 4]
    push dword [ebx + 6]
    lea eax, [edi + ebp + 0x1c]
    mov dx, word ds:[byte ebp]
    and dx, 0xc00
    call round_to_integer
    lea eax, [edi + ebp + 0x1c]
    call pack_integer
    mov dword es:[esi], eax
    lea ebx, [edi + ebp + 0x1c]
    pop dword [ebx + 6]
    pop dword [ebx + 4]
    pop dword [ebx]
    jmp near decode_next

fistp_m32int:
    lea eax, [edi + ebp + 0x1c]
    mov dx, word ds:[byte ebp]
    and dx, 0xc00
    call round_to_integer
    lea eax, [edi + ebp + 0x1c]
    call pack_integer
    mov dword es:[esi], eax
    jmp near mark_empty_and_pop
