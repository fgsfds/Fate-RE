; Round x87 significands and update emulator condition and exception state.
BITS 32
ORG 0x67f84

decode_next_instruction equ 0x67e50
condition_bits equ 0x57aee
tag_clear_masks equ 0x57a9e
empty_tag_bits equ 0x57aa6
next_stack_index equ 0x57a4e
top_index_bits equ 0x57a52
exception_hook equ 0x144a5

round_single_significand:
    lea ebx, [edi + ebp + 0x1c]
    mov edx, 0xffffff00
    mov eax, dword [ebx + 4]
    shl eax, 0x19
    jae short mask_single
    jne short increment_single
    cmp dword [ebx], 0
    jne short increment_single
    db 0x3, 0xd2 ; ADD edx, edx uses the register-destination opcode.

increment_single:
    add dword [ebx + 4], 0x100
    jae short mask_single
    mov dword [ebx + 4], 0x80000000
    inc word [ebx + 8]

mask_single:
    and dword [ebx + 4], edx
    mov dword [ebx], 0
    jmp near decode_next_instruction

round_double_significand:
    lea ebx, [edi + ebp + 0x1c]
    mov edx, 0xfffff800
    mov eax, dword [ebx]
    shl eax, 0x16
    jae short mask_double
    jne short increment_double
    db 0x3, 0xd2 ; ADD edx, edx uses the register-destination opcode.

increment_double:
    add dword [ebx], 0x800
    adc dword [ebx + 4], 0
    jae short mask_double
    mov dword [ebx + 4], 0x80000000
    inc word [ebx + 8]

mask_double:
    and dword [ebx], edx
    jmp near decode_next_instruction

update_flags_and_pop:
    inc eax
    mov dx, word ds:[ebp + 4]
    and dx, 0xb8ff
    or dh, byte cs:[eax + condition_bits]
    mov word ds:[ebp + 4], dx
    mov bx, word cs:[edi + tag_clear_masks]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + empty_tag_bits]
    or word ds:[ebp + 8], bx
    movzx edi, word cs:[edi + next_stack_index]
    mov bx, word cs:[edi + top_index_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    jmp near decode_next_instruction

update_condition_flags:
    inc eax
    mov dx, word ds:[ebp + 4]
    and dx, 0xb8ff
    or dh, byte cs:[eax + condition_bits]
    mov word ds:[ebp + 4], dx
    jmp near decode_next_instruction

signal_x87_exception:
    or byte ds:[ebp + 4], al
    test byte ds:[ebp], al
    jne short return_exception
    push esi
    push edi
    push ecx
    push es
    push ds
    sub esp, 0x6c
    mov cx, ss
    db 0x66 ; Original operand-size prefix on the segment load.
    mov es, ecx
    db 0x8b, 0xf5 ; MOV esi, ebp uses the register-destination opcode.
    db 0x8b, 0xfc ; MOV edi, esp uses the register-destination opcode.
    mov ecx, 0x1b
    cld
    rep movsd
    movzx eax, ah
    call dword [exception_hook]
    mov cx, ds
    db 0x66 ; Original operand-size prefix on the segment load.
    mov es, ecx
    mov cx, ss
    db 0x66 ; Original operand-size prefix on the segment load.
    mov ds, ecx
    db 0x8b, 0xfd ; MOV edi, ebp uses the register-destination opcode.
    db 0x8b, 0xf4 ; MOV esi, esp uses the register-destination opcode.
    mov ecx, 0x1b
    cld
    rep movsd
    add esp, 0x6c
    pop ds
    pop es
    pop ecx
    pop edi
    pop esi

return_exception:
    ret
