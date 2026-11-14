; x87 arithmetic with pop, status transfer, and register math handlers.
BITS 32
ORG 0x69182

add_extended equ 0x69574
multiply_extended equ 0x699a8
subtract_extended equ 0x69566
divide_extended equ 0x697d3
compare_extended equ 0x6973a
update_flags_pop equ 0x67ff2
decode_next equ 0x67e50
arctangent equ 0x69ff0
pack_signed_integer equ 0x69b23
partial_remainder equ 0x6a209
round_to_integer equ 0x69e63
skip_register equ 0x68984
tag_clear equ 0x57a9e
tag_empty equ 0x57aa6
next_top equ 0x57a4e
previous_top equ 0x57a50
top_bits equ 0x57a52
condition_bits equ 0x57af2

faddp:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call add_extended
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp dword ds:[ebp + 0x76]

fmulp:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call multiply_extended
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp dword ds:[ebp + 0x76]

dispatch_fcompp:
    jmp dword cs:[ebx*4 + fcompp_table - 0x10000]

fcompp_table:
    dd skip_register - 0x10000
    dd fcompp - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000

fcompp:
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

fsubrp:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call subtract_extended
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp dword ds:[ebp + 0x76]

fsubp:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call subtract_extended
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp dword ds:[ebp + 0x76]

fdivrp:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call divide_extended
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp dword ds:[ebp + 0x76]

fdivp:
    lea eax, [esi + ebp + 0x1c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [esi + ebp + 0x1c]
    call divide_extended
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp dword ds:[ebp + 0x76]

dispatch_fnstsw:
    jmp dword cs:[ebx*4 + fnstsw_table - 0x10000]

fnstsw_table:
    dd fnstsw_ax - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000
    dd skip_register - 0x10000

fpatan:
    lea edx, [edi + ebp + 0x1c]
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_empty]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    lea eax, [edi + ebp + 0x1c]
    db 0x8b, 0xd8 ; MOV ebx, eax uses the register-destination opcode.
    call arctangent
    jmp dword ds:[ebp + 0x76]

fxtract:
    lea esi, [edi + ebp + 0x1c]
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    lea ebx, [edi + ebp + 0x1c]
    mov eax, dword [esi]
    mov dword [ebx], eax
    mov eax, dword [esi + 4]
    mov dword [ebx + 4], eax
    mov ax, word [esi + 8]
    db 0x66, 0x8b, 0xd0 ; MOV dx, ax uses the register-destination opcode.
    and dx, 0x8000
    or dx, 0x3fff
    mov word [ebx + 8], dx
    and ax, 0x7fff
    sub ax, 0x3fff
    cwde
    db 0x8b, 0xd6 ; MOV edx, esi uses the register-destination opcode.
    call pack_signed_integer
    jmp near decode_next

fprem1:
    lea eax, [edi + ebp + 0x1c]
    lea edx, [esi + ebp + 0x1c]
    call partial_remainder
    and eax, 7
    mov dx, word ds:[ebp + 4]
    and dx, 0xb8ff
    or dh, byte cs:[eax + condition_bits]
    mov word ds:[ebp + 4], dx
    jmp dword ds:[ebp + 0x76]

frndint:
    lea eax, [edi + ebp + 0x1c]
    mov dx, word ds:[ebp]
    and dx, 0xc00
    call round_to_integer
    jmp near decode_next

fscale:
    db 0x8b, 0xf7 ; MOV esi, edi uses the register-destination opcode.
    movzx edi, word cs:[edi + next_top]
    lea eax, [edi + ebp + 0x1c]
    mov cx, word [eax + 8]
    call pack_signed_integer
    db 0x8b, 0xfe ; MOV edi, esi uses the register-destination opcode.
    lea ebx, [edi + ebp + 0x1c]
    db 0x8b, 0xd0 ; MOV edx, eax uses the register-destination opcode.
    cwde
    db 0x3b, 0xc2 ; CMP eax, edx uses the register-destination opcode.
    je short .apply_scale
    db 0x0a, 0xed ; OR ch, ch uses the register-destination opcode.
    jns short .large_positive_scale
    db 0x66, 0x2b, 0xd2 ; SUB dx, dx uses the register-destination opcode.
    db 0x66, 0x2b, 0xc9 ; SUB cx, cx uses the register-destination opcode.
    jmp short .finish_large_scale

.large_positive_scale:
    mov dx, 0x7fff
    mov cx, word [ebx + 8]
    and cx, 0x8000

.finish_large_scale:
    jmp short .store_exponent

.apply_scale:
    mov dx, word [ebx + 8]
    db 0x66, 0x8b, 0xca ; MOV cx, dx uses the register-destination opcode.
    and cx, 0x8000
    and dx, 0x7fff
    db 0x66, 0x03, 0xd0 ; ADD dx, ax uses the register-destination opcode.
    jns short .store_exponent
    db 0x0a, 0xe4 ; OR ah, ah uses the register-destination opcode.
    jns short .saturate_exponent
    db 0x66, 0x2b, 0xd2 ; SUB dx, dx uses the register-destination opcode.
    db 0x66, 0x2b, 0xc9 ; SUB cx, cx uses the register-destination opcode.
    jmp short .store_exponent

.saturate_exponent:
    mov dx, 0x7fff

.store_exponent:
    db 0x66, 0x0b, 0xd1 ; OR dx, cx uses the register-destination opcode.
    mov word [ebx + 8], dx
    jmp near decode_next

fnstsw_ax:
    mov ax, word ds:[ebp + 4]
    db 0x8b, 0xec ; MOV ebp, esp uses the register-destination opcode.
    mov word [ebp + 0x28], ax
    jmp near decode_next
