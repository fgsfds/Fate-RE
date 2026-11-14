; x87 binary64 and extended-real memory operations and full state transfer.
BITS 32
ORG 0x68507

extend_double equ 0x69bd8
add_extended equ 0x69574
multiply_extended equ 0x699a8
compare_extended equ 0x6973a
subtract_extended equ 0x69566
divide_extended equ 0x697d3
update_flags equ 0x68044
update_flags_pop equ 0x67ff2
decode_next equ 0x67e50
pack_double equ 0x69cd7
mark_empty_and_pop equ 0x68009
reset_emulator equ 0x69043
previous_top equ 0x57a50
top_bits equ 0x57a52
tag_clear equ 0x57a9e
next_top equ 0x57a4e

fadd_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call add_extended
    jmp dword ds:[ebp + 0x76]

fmul_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call multiply_extended
    jmp dword ds:[ebp + 0x76]

fcom_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags

fcomp_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags_pop

fsub_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fsubr_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call subtract_extended
    jmp dword ds:[ebp + 0x76]

fdiv_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    lea ebx, [edi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fdivr_m64real:
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [ebp + 0x6c]
    call extend_double
    lea eax, [ebp + 0x6c]
    lea edx, [edi + ebp + 0x1c]
    lea ebx, [edi + ebp + 0x1c]
    call divide_extended
    jmp dword ds:[ebp + 0x76]

fld_m80real:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov eax, dword es:[esi]
    mov dword [edi + ebp + 0x1c], eax
    mov eax, dword es:[esi + 4]
    mov dword [edi + ebp + 0x20], eax
    mov ax, word es:[esi + 8]
    mov word [edi + ebp + 0x24], ax
    jmp near decode_next

fld_m64real:
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov eax, dword es:[esi]
    mov edx, dword es:[esi + 4]
    lea ebx, [edi + ebp + 0x1c]
    call extend_double
    jmp near decode_next

fst_m64real:
    lea eax, [edi + ebp + 0x1c]
    call pack_double
    mov dword es:[esi], eax
    mov dword es:[esi + 4], edx
    jmp near decode_next

fstp_m80real:
    mov eax, dword [edi + ebp + 0x1c]
    mov dword es:[esi], eax
    mov eax, dword [edi + ebp + 0x20]
    mov dword es:[esi + 4], eax
    mov ax, word [edi + ebp + 0x24]
    mov word es:[esi + 8], ax
    jmp near mark_empty_and_pop

fstp_m64real:
    lea eax, [edi + ebp + 0x1c]
    call pack_double
    mov dword es:[esi], eax
    mov dword es:[esi + 4], edx
    jmp near mark_empty_and_pop

frstor:
    mov ecx, 7
    push ds
    push es
    mov ax, es
    mov dx, ds
    db 0x66 ; Original operand-size prefix on the segment load.
    mov es, edx
    db 0x66 ; Original operand-size prefix on the segment load.
    mov ds, eax
    db 0x8b, 0xfd ; MOV edi, ebp uses the register-destination opcode.
    rep movsd
    mov ebx, dword es:[ebp + 4]
    and ebx, strict dword 0x3800
    shr ebx, 0xb
    lea ebx, [ebx + ebx*4]
    db 0x03, 0xdb ; ADD ebx, ebx uses the register-destination opcode.
    mov ecx, 8

restore_register:
    lea edi, [ebp + ebx + 0x1c]
    movsd
    movsd
    movsw
    movzx ebx, word cs:[ebx + next_top]
    loop restore_register
    pop es
    pop ds
    jmp near decode_next

fnsave:
    mov ecx, 7
    db 0x8b, 0xdf ; MOV ebx, edi uses the register-destination opcode.
    db 0x8b, 0xfe ; MOV edi, esi uses the register-destination opcode.
    db 0x8b, 0xf5 ; MOV esi, ebp uses the register-destination opcode.
    rep movsd
    mov ecx, 8

save_register:
    lea esi, [ebx + ebp + 0x1c]
    movsd
    movsd
    movsw
    movzx ebx, word cs:[ebx + next_top]
    loop save_register
    db 0x8b, 0xfb ; MOV edi, ebx uses the register-destination opcode.
    jmp near reset_emulator

fnstsw_m16:
    mov ax, word ds:[ebp + 4]
    mov word es:[esi], ax
    jmp near decode_next
