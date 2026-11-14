; Effective-address helpers for the x87 emulator's saved register frame.
BITS 32
ORG 0x680ae

sib_base_dispatch equ 0x67b5c - 0x10000
decode_next_instruction equ 0x67e50

%macro base_address 3
%1:
    %if %2 = 0
        db 0x33, 0xdb ; XOR EBX, EBX, register-destination encoding.
    %elif %2 = 1
        movsx ebx, byte [esi]
        inc esi
    %elif %2 = 4
        mov ebx, [esi]
        add esi, 4
    %endif
    %if %3
        add ebx, [ebp + %3]
        %if %3 = 0x18 || %3 = 0x14
            db 0x8b, 0xca ; MOV ECX, EDX selects the stack segment.
        %endif
    %endif
    ret
%endmacro

base_address address_eax, 0, 0x28
base_address address_ecx, 0, 0x24
base_address address_edx, 0, 0x20
base_address address_ebx, 0, 0x1c
base_address address_esp, 0, 0x18
base_address address_absolute, 4, 0
base_address address_esi, 0, 0x10
base_address address_edi, 0, 0xc

base_address address_eax_disp8, 1, 0x28
base_address address_ecx_disp8, 1, 0x24
base_address address_edx_disp8, 1, 0x20
base_address address_ebx_disp8, 1, 0x1c
base_address address_esp_disp8, 1, 0x18
base_address address_ebp_disp8, 1, 0x14
base_address address_esi_disp8, 1, 0x10
base_address address_edi_disp8, 1, 0xc

base_address address_eax_disp32, 4, 0x28
base_address address_ecx_disp32, 4, 0x24
base_address address_edx_disp32, 4, 0x20
base_address address_ebx_disp32, 4, 0x1c
base_address address_esp_disp32, 4, 0x18
base_address address_ebp_disp32, 4, 0x14
base_address address_esi_disp32, 4, 0x10
base_address address_edi_disp32, 4, 0xc

address_sib:
    mov bl, [esi]
    inc esi
    push ebx
    and bl, 7
    db 0x8a, 0xfc ; MOV BH, AH, register-destination encoding.
    shr bh, 3
    and bh, 0x18
    db 0x0a, 0xdf ; OR BL, BH, register-destination encoding.
    mov bh, 0
    call dword cs:[ebx*4 + sib_base_dispatch]
    pop edx
    push ecx
    db 0x8b, 0xca ; MOV ECX, EDX, register-destination encoding.
    and dl, 0x38
    cmp dl, 0x20
    je short .done
    shr edx, 1
    neg edx
    mov edx, [ebp + edx + 0x28]
    shr cl, 6
    shl edx, cl
    db 0x03, 0xda ; ADD EBX, EDX, register-destination encoding.
.done:
    pop ecx
    ret

skip_memory_operation:
    jmp near decode_next_instruction
