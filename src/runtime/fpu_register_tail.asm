; x87 double-pop comparison, control dispatch and ST(i) operations.
BITS 32
ORG 0x68f86

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

dispatch_fucompp:
    jmp dword cs:[ebx*4 + fucompp_table - 0x10000]

fucompp_table:
    dd skip_register - 0x10000
    dd fucompp - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000

fucompp:
    mov eax, dword [edi + ebp + 0x1c]
    mov dword ds:[ebp + 0x6c], eax
    mov eax, dword [edi + ebp + 0x20]
    mov dword ds:[ebp + 0x70], eax
    mov ax, word [edi + ebp + 0x24]
    mov word ds:[ebp + 0x74], ax
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    call compare_extended
    jmp near update_flags_pop

dispatch_fpu_control:
    jmp dword cs:[ebx*4 + fpu_control_table - 0x10000]

fpu_control_table:
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd fnclex - 0x10000
    dd reset_emulator - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000

fnclex:
    and word ds:[ebp + 4], 0x7f00
    jmp near decode_next
