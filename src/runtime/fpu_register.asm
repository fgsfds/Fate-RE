; x87 register dispatch for D8 operations and D9 load/exchange.
BITS 32
ORG 0x68984

decode_next equ 0x67e50
add_extended equ 0x69574
multiply_extended equ 0x699a8
subtract_extended equ 0x69566
divide_extended equ 0x697d3
compare_extended equ 0x6973a
update_flags equ 0x68044
update_flags_pop equ 0x67ff2
previous_top equ 0x57a50
top_bits equ 0x57a52
tag_clear equ 0x57a9e

skip_register_operation:
    jmp near decode_next

dispatch_fnop:
    jmp dword cs:[ebx*4 + fnop_table - 0x10000]

fnop_table:
    dd fnop - 0x10000
    times 7 dd skip_register_operation - 0x10000

fnop:
    jmp near decode_next

%macro arithmetic 4
%1:
    lea eax, [%3 + ebp + 0x1c]
    lea edx, [%4 + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call %2
    jmp dword ds:[ebp + 0x76]
%endmacro

%macro compare 2
%1:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    call compare_extended
    jmp near %2
%endmacro

arithmetic fadd_st0_sti, add_extended, edi, esi
arithmetic fmul_st0_sti, multiply_extended, edi, esi
compare fcom_sti, update_flags
compare fcomp_sti, update_flags_pop
arithmetic fsub_st0_sti, subtract_extended, edi, esi
arithmetic fsubr_st0_sti, subtract_extended, esi, edi
arithmetic fdiv_st0_sti, divide_extended, edi, esi
arithmetic fdivr_st0_sti, divide_extended, esi, edi

fld_sti:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov eax, [esi + ebp + 0x1c]
    mov [edi + ebp + 0x1c], eax
    mov eax, [esi + ebp + 0x20]
    mov [edi + ebp + 0x20], eax
    mov ax, [esi + ebp + 0x24]
    mov [edi + ebp + 0x24], ax
    jmp near decode_next

fxch_sti:
    lea ebx, [edi + ebp + 0x1c]
    lea esi, [esi + ebp + 0x1c]
    mov eax, [esi]
    xchg [ebx], eax
    mov [esi], eax
    mov eax, [esi + 4]
    xchg [ebx + 4], eax
    mov [esi + 4], eax
    mov ax, [esi + 8]
    xchg [ebx + 8], ax
    mov [esi + 8], ax
    jmp near decode_next
