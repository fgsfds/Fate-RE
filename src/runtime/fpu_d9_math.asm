; D9 math dispatch and x87 stack transitions.
BITS 32
ORG 0x68e6e

decode_next equ 0x67e50
partial_remainder equ 0x6a209
log1p_multiply equ 0x6a3d8
square_root equ 0x6aae4
sine equ 0x6a8c3
cosine equ 0x6a8cd
condition_bits equ 0x57af2
tag_clear equ 0x57a9e
tag_empty equ 0x57aa6
next_top equ 0x57a4e
previous_top equ 0x57a50
top_bits equ 0x57a52

dispatch_d9_math:
    jmp dword cs:[ebx*4 + d9_math_table - 0x10000]

d9_math_table:
    dd fprem - 0x10000
    dd fyl2xp1 - 0x10000
    dd fsqrt - 0x10000
    dd fsincos - 0x10000
    dd 0x694cd - 0x10000
    dd 0x694e5 - 0x10000
    dd fsin - 0x10000
    dd fcos - 0x10000

fprem:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    call partial_remainder
    and eax, 7
    mov dx, word ds:[ebp + 4]
    and dx, 0xb8ff
    or dh, byte cs:[eax + condition_bits]
    mov word ds:[ebp + 4], dx
    jmp dword ds:[ebp + 0x76]

fyl2xp1:
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
    call log1p_multiply
    jmp dword ds:[ebp + 0x76]

fsqrt:
    lea eax, [edi + ebp + 0x1c]
    call square_root
    jmp dword ds:[ebp + 0x76]

fsincos:
    lea ebx, [edi + ebp + 0x1c]
    push dword [ebx]
    push dword [ebx + 4]
    push dword [ebx + 6]
    lea eax, [edi + ebp + 0x1c]
    call sine
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    lea ebx, [edi + ebp + 0x1c]
    pop dword [ebx + 6]
    pop dword [ebx + 4]
    pop dword [ebx]
    lea eax, [edi + ebp + 0x1c]
    call cosine
    jmp near decode_next

fsin:
    lea eax, [edi + ebp + 0x1c]
    call sine
    jmp dword ds:[ebp + 0x76]

fcos:
    lea eax, [edi + ebp + 0x1c]
    call cosine
    jmp dword ds:[ebp + 0x76]
