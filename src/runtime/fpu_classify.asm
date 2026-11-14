; Classify the x87 top register and update its tag and status.
BITS 32
ORG 0x6a2ea

tag_empty equ 0x57aa6
tag_zero equ 0x57aa0
tag_special equ 0x57aa4

classify_x87:
    push ebx
    push edx
    db 0x8b, 0xd8 ; MOV ebx, eax uses the register-destination opcode.
    mov ax, word cs:[edi + tag_empty]
    db 0x8b, 0xd0 ; MOV edx, eax uses the register-destination opcode.
    db 0x3e, 0x66, 0x23, 0x45, 0x08 ; AND ax, word ds:[ebp + 8] uses the register-destination opcode.
    db 0x66, 0x3b, 0xc2 ; CMP ax, dx uses the register-destination opcode.
    jne short classify_nonempty
    mov al, 0x41
    mov dh, 0
    jmp short update_status

classify_nonempty:
    not edx
    and word ds:[ebp + 8], dx
    mov ax, word [ebx + 8]
    db 0x8b, 0xd0 ; MOV edx, eax uses the register-destination opcode.
    and dh, 0x80
    rol dh, 1
    shl dh, 1
    and ax, 0x7fff
    jne short check_special_exponent
    mov eax, dword [ebx + 4]
    db 0x0b, 0x03 ; OR eax, dword [ebx] uses the register-destination opcode.
    mov al, 0x44
    jne short finish_zero
    mov ax, word cs:[edi + tag_zero]
    or word ds:[ebp + 8], ax
    mov al, 0x40

finish_zero:
    jmp short update_status

check_special_exponent:
    cmp ax, 0x7fff
    jne short check_explicit_bit
    mov ax, word cs:[edi + tag_special]
    or word ds:[ebp + 8], ax
    cmp dword [ebx], 0
    jne short select_nan_or_infinity
    mov eax, dword [ebx + 4]
    cmp eax, 0x80000000

select_nan_or_infinity:
    mov al, 1
    jne short finish_special
    mov al, 5

finish_special:
    jmp short update_status

check_explicit_bit:
    test byte [ebx + 7], 0x80
    mov al, 4
    jne short update_status
    mov ax, word cs:[edi + tag_special]
    or word ds:[ebp + 8], ax
    mov al, 0x44

update_status:
    db 0x0a, 0xc6 ; OR al, dh uses the register-destination opcode.
    mov dx, word ds:[ebp + 4]
    and dx, 0xb8ff
    db 0x0a, 0xf0 ; OR dh, al uses the register-destination opcode.
    mov word ds:[ebp + 4], dx
    pop edx
    pop ebx
    ret
