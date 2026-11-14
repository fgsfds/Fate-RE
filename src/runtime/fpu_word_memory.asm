; x87 word-integer operations and the emulator-specific DF memory entries.
BITS 32
ORG 0x68766

extend_signed equ 0x69b92
extend_unsigned_entry equ 0x69ba3
pack_signed equ 0x69b23
pack_unsigned equ 0x69b28
add_extended equ 0x69574
multiply_extended equ 0x699a8
compare_extended equ 0x6973a
subtract_extended equ 0x69566
divide_extended equ 0x697d3
update_flags equ 0x68044
update_flags_pop equ 0x67ff2
decode_next equ 0x67e50
mark_empty_and_pop equ 0x68009
round_to_integer equ 0x69e63
previous_top equ 0x57a50
top_bits equ 0x57a52
tag_clear equ 0x57a9e

fiadd_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call add_extended
    jmp dword ds:[ebp + 0x76]

fimul_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call multiply_extended
    jmp dword ds:[ebp + 0x76]

ficom_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags

ficomp_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags_pop

fisub_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fisubr_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fidiv_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fidivr_m16int:
    mov ax, word es:[esi]
    cwde
    lea edx, [ebp + 0x6c]
    call extend_signed
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fild_m16int:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov ax, word es:[esi]
    cwde
    lea edx, [edi + ebp + 0x1c]
    call extend_signed
    jmp near decode_next

fist_m16int:
    lea ebx, [edi + ebp + 0x1c]
    push dword [ebx]
    push dword [ebx + 4]
    push dword [ebx + 6]
    lea eax, [edi + ebp + 0x1c]
    mov dx, word ds:[byte ebp]
    and dx, 0xc00
    call round_to_integer
    lea eax, [edi + ebp + 0x1c]
    call pack_signed
    db 0x8b, 0xd0 ; MOV edx, eax uses the register-destination opcode.
    cwde
    db 0x3b, 0xc2 ; CMP eax, edx uses the register-destination opcode.
    je short store_word
    mov ax, 0x8000

store_word:
    mov word es:[esi], ax
    lea ebx, [edi + ebp + 0x1c]
    pop dword [ebx + 6]
    pop dword [ebx + 4]
    pop dword [ebx]
    jmp near decode_next

fistp_m16int:
    lea eax, [edi + ebp + 0x1c]
    mov dx, word ds:[byte ebp]
    and dx, 0xc00
    call round_to_integer
    lea eax, [edi + ebp + 0x1c]
    call pack_signed
    db 0x8b, 0xd0 ; MOV edx, eax uses the register-destination opcode.
    cwde
    db 0x3b, 0xc2 ; CMP eax, edx uses the register-destination opcode.
    je short store_word_and_pop
    mov ax, 0x8000

store_word_and_pop:
    mov word es:[esi], ax
    jmp near mark_empty_and_pop

skip_bcd_load:
    jmp near decode_next

load_integer_low_dword:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov eax, dword es:[esi]
    lea edx, [edi + ebp + 0x1c]
    call extend_unsigned_entry
    jmp near decode_next

pop_without_bcd_store:
    jmp near mark_empty_and_pop

store_integer_low_dword:
    lea eax, [edi + ebp + 0x1c]
    mov dx, word ds:[ebp]
    and dx, 0xc00
    call round_to_integer
    lea eax, [edi + ebp + 0x1c]
    call pack_unsigned
    mov dword es:[esi], eax
    jmp near mark_empty_and_pop
