; D9 transcendental dispatch and TOP rotation.
BITS 32
ORG 0x68d64

decode_next equ 0x67e50
exp2_minus_one equ 0x6a910
log2_multiply equ 0x6a3f1
tangent equ 0x6a8da
tag_clear equ 0x57a9e
tag_empty equ 0x57aa6
next_top equ 0x57a4e
previous_top equ 0x57a50
top_bits equ 0x57a52

dispatch_d9_stack:
    jmp dword cs:[ebx*4 + d9_stack_table - 0x10000]

d9_stack_table:
    dd f2xm1 - 0x10000
    dd fyl2x - 0x10000
    dd fptan - 0x10000
    dd 0x693f5 - 0x10000
    dd 0x6943e - 0x10000
    dd 0x694a3 - 0x10000
    dd fdecstp - 0x10000
    dd fincstp - 0x10000

f2xm1:
    lea eax, [edi + ebp + 0x1c]
    call exp2_minus_one
    jmp dword ds:[ebp + 0x76]

fyl2x:
    lea eax, [edi + ebp + 0x1c]
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    lea edx, [edi + ebp + 0x1c]
    call log2_multiply
    jmp dword ds:[ebp + 0x76]

fptan:
    lea eax, [edi + ebp + 0x1c]
    call tangent
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    lea esi, [edi + ebp + 0x1c]
    db 0x2b, 0xc0 ; SUB eax, eax uses the register-destination opcode.
    mov dword [esi], eax
    mov dword [esi + 4], 0x80000000
    mov word [esi + 8], 0x3fff
    jmp near decode_next

fdecstp:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp near decode_next

fincstp:
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp near decode_next
