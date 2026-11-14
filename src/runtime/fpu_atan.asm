; Arctangent wrapper with axis cases and quadrant correction.
BITS 32
ORG 0x69ff0

divide_extended equ 0x697d3
atan_reduced equ 0x6a0a6
add_extended_stack equ 0x6959e

arctangent:
    push edi
    push esi
    push ecx
    db 0x8b, 0xf8 ; MOV edi, eax uses the register-destination opcode.
    mov cx, word [edi + 8]
    shl cx, 1
    jne short .check_denominator
    test byte [edx + 9], 0x80
    je short .store_zero
    mov word [ebx + 8], 0x4000
    mov dword [ebx + 4], 0xc90fdaa2
    mov dword [ebx], 0x2168c235
    jmp short .finish_zero_input

.store_zero:
    mov word [ebx + 8], 0
    mov dword [ebx + 4], 0
    mov dword [ebx], 0

.finish_zero_input:
    jmp short .restore_registers

.check_denominator:
    mov cx, word [edx + 8]
    shl cx, 1
    jne short .divide_operands
    mov ax, word [edi + 8]
    and ax, 0x8000
    or ax, 0x3fff
    mov word [ebx + 8], ax
    mov dword [ebx + 4], 0xc90fdaa2
    mov dword [ebx], 0x2168c235
    jmp short .restore_registers

.divide_operands:
    mov ch, byte [edi + 9]
    call divide_extended
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.
    call atan_reduced
    mov dl, byte [ebx + 9]
    db 0x0a, 0xed ; OR ch, ch uses the register-destination opcode.
    js short .adjust_negative_input
    db 0x0a, 0xd2 ; OR dl, dl uses the register-destination opcode.
    jns short .finish_positive_input
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.
    push strict dword 0x4000
    push strict dword 0xc90fdaa2
    push strict dword 0x2168c235
    call add_extended_stack

.finish_positive_input:
    jmp short .restore_registers

.adjust_negative_input:
    db 0x0a, 0xd2 ; OR dl, dl uses the register-destination opcode.
    jle short .restore_registers
    db 0x8b, 0xc3 ; MOV eax, ebx uses the register-destination opcode.
    push strict dword 0xc000
    push strict dword 0xc90fdaa2
    push strict dword 0x2168c235
    call add_extended_stack

.restore_registers:
    pop ecx
    pop esi
    pop edi
    ret
