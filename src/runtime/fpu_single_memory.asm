; x87 single-precision memory operations and environment loads/stores.
BITS 32
ORG 0x681ad

decode_next equ 0x67e50
round_single equ 0x67f84
round_double equ 0x67fc0
update_flags equ 0x68044
update_flags_pop equ 0x67ff2
mark_empty_and_pop equ 0x68009
extend_single equ 0x69d9e
pack_single equ 0x69c58
add_extended equ 0x69574
multiply_extended equ 0x699a8
compare_extended equ 0x6973a
subtract_extended equ 0x69566
divide_extended equ 0x697d3
previous_top equ 0x67a50 - 0x10000
top_bits equ 0x67a52 - 0x10000
tag_clear equ 0x67a9e - 0x10000

%macro load_operand 0
    mov eax, es:[esi]
    lea edx, [ebp + 0x6c]
    call extend_single
%endmacro

%macro arithmetic 3
%1:
    load_operand
    %if %3
        lea eax, [ebp + 0x6c]
        lea edx, [edi + ebp + 0x1c]
    %else
        lea eax, [edi + ebp + 0x1c]
        lea edx, [ebp + 0x6c]
    %endif
    lea ebx, [edi + ebp + 0x1c]
    call %2
    jmp dword ds:[ebp + 0x76]
%endmacro

%macro compare_operand 2
%1:
    load_operand
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near %2
%endmacro

arithmetic fadd_m32real, add_extended, 0
arithmetic fmul_m32real, multiply_extended, 0
compare_operand fcom_m32real, update_flags
compare_operand fcomp_m32real, update_flags_pop
arithmetic fsub_m32real, subtract_extended, 0
arithmetic fsubr_m32real, subtract_extended, 1
arithmetic fdiv_m32real, divide_extended, 0
arithmetic fdivr_m32real, divide_extended, 1

fld_m32real:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov eax, es:[esi]
    lea edx, [edi + ebp + 0x1c]
    call extend_single
    jmp near decode_next

%macro store_operand 2
%1:
    lea eax, [edi + ebp + 0x1c]
    call pack_single
    mov es:[esi], eax
    jmp near %2
%endmacro

store_operand fst_m32real, decode_next
store_operand fstp_m32real, mark_empty_and_pop

fldenv:
    mov ecx, 7
    push ds
    push es
    mov ax, es
    mov dx, ds
    db 0x66 ; Original operand-size prefix on the segment load.
    mov es, edx
    db 0x66
    mov ds, eax
    db 0x8b, 0xfd ; MOV EDI, EBP uses the register-destination opcode.
    rep movsd
    pop es
    pop ds
    jmp near decode_next

fldcw:
    mov ax, word es:[esi]
    mov word ds:[byte ebp], ax
    and ax, 0x300
    cmp ax, 0x300
    jne short .check_double
    lea edx, [decode_next - 0x10000]
    mov dword ds:[ebp + 0x76], edx
    jmp short .dispatch
.check_double:
    cmp ax, 0x200
    jne short .use_single
    lea edx, [round_double - 0x10000]
    mov dword ds:[ebp + 0x76], edx
    jmp short .dispatch
.use_single:
    lea edx, [round_single - 0x10000]
    mov dword ds:[ebp + 0x76], edx
.dispatch:
    jmp near decode_next

fnstenv:
    mov ecx, 7
    db 0x8b, 0xdf ; MOV EBX, EDI
    db 0x8b, 0xfe ; MOV EDI, ESI
    db 0x8b, 0xf5 ; MOV ESI, EBP
    rep movsd
    db 0x8b, 0xfb ; MOV EDI, EBX
    jmp near decode_next

fnstcw:
    mov ax, word ds:[byte ebp]
    mov word es:[esi], ax
    jmp near decode_next
