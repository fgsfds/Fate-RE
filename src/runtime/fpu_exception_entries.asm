; Adapt three x87 exception frame layouts to the common decoder.
BITS 32
ORG 0x67dbc

emulate_x87_instruction equ 0x67e50

extender_exception_entry:
    sti
    pushad
    db 0x8b, 0xec ; MOV EBP, ESP uses the register-destination opcode.
    push dword [ebp + 0x40]
    push dword [ebp + 0x44]
    mov cx, word [ebp + 0x3c]
    mov word [ebp - 6], cx
    mov ecx, dword [ebp + 0x38]
    mov dword [ebp + 0xc], ecx
    call emulate_x87_instruction
    pop ds
    pop es
    popad
    iretd

extender_entry_alignment:
    xchg ebx, ebx
    nop

alternate_exception_entry:
    sti
    mov eax, dword [esp + 0xc]
    push dword ss:[eax + 0x14]
    push dword ss:[eax + 0x10]
    push eax
    push eax
    push eax
    push dword ss:[eax]
    push ecx
    push edx
    push ebx
    push dword ss:[eax + 0x1c]
    db 0x8b, 0xc5 ; MOV EAX, EBP uses the register-destination opcode.
    push eax
    push esi
    push edi
    push es
    push ds
    mov word [esp + 2], ss
    call emulate_x87_instruction
    pop ds
    pop es
    pop edi
    pop esi
    pop eax
    db 0x8b, 0xe8 ; MOV EBP, EAX uses the register-destination opcode.
    pop eax
    pop ebx
    pop edx
    pop ecx
    pop eax
    xchg dword [esp], eax
    pop dword ss:[eax]
    add esp, 8
    pop dword ss:[eax + 0x10]
    add esp, 4
    mov eax, dword ss:[eax]
    iretd

alternate_entry_alignment:
    xchg ebx, ebx

emulator_exception_entry:
    sti
    sub esp, 0xc
    push eax
    db 0x8b, 0xc4 ; MOV EAX, ESP uses the register-destination opcode.
    add eax, 0x1c
    push ecx
    push edx
    push ebx
    push eax
    push ebp
    push esi
    push edi
    push es
    push ds
    mov word [esp + 2], ss
    call emulate_x87_instruction
    pop ds
    pop es
    popad
    add esp, 0xc
    iretd

emulator_entry_alignment:
    nop
