; Decode x87 prefixes and dispatch memory or register operands.
BITS 32
ORG 0x67e50

reload_runtime_ds equ 0x601d4
address_dispatch equ 0x57afc
memory_dispatch equ 0x57bbc
register_dispatch equ 0x57cbc
emulator_state equ 0x17410

emulate_x87_instruction:
    db 0x8b, 0xec ; MOV ebp, esp uses the original register opcode.
    mov esi, dword [ebp + 0x38]
    mov ds, [ebp + 0x3c]
    mov cx, word [ebp + 4]
    mov dx, word [ebp + 6]
    mov al, byte [esi]
    cmp al, 0x9b
    jbe near .classify_prefix

.decode_opcode:
    db 0x8a, 0xd8 ; MOV bl, al uses the original register opcode.
    and bl, 0xf8
    cmp bl, 0xd8
    jne near .return_unsupported_opcode
    mov ah, byte [esi + 1]
    add esi, 2
    and al, 7
    cmp ah, 0xc0
    jae near .dispatch_register_operation
    db 0x8a, 0xdc ; MOV bl, ah uses the original register opcode.
    db 0x8a, 0xfc ; MOV bh, ah uses the original register opcode.
    shr bh, 3
    and ebx, strict dword 0x1807
    db 0xa, 0xdf ; OR bl, bh uses the original register opcode.
    mov bh, 0
    call dword cs:[ebx*4 + address_dispatch]
    db 0x66 ; Original operand-size prefix on the segment load.
    mov es, ecx
    mov dword [ebp + 0x38], esi
    db 0x8b, 0xf3 ; MOV esi, ebx uses the original register opcode.
    db 0x8a, 0xdc ; MOV bl, ah uses the original register opcode.
    and ebx, 0x38
    db 0xa, 0xd8 ; OR bl, al uses the original register opcode.
    call reload_runtime_ds
    lea ebp, [emulator_state]
    mov edi, dword ds:[ebp + 4]
    and edi, strict dword 0x3800
    shr edi, 0xb
    lea edi, [edi + edi*4]
    db 0x03, 0xff ; ADD EDI, EDI uses the register-destination opcode.
    jmp dword cs:[ebx*4 + memory_dispatch]

.read_after_prefix:
    mov al, byte [esi]
    cmp al, 0x9b
    ja short .decode_opcode

.classify_prefix:
    je short .skip_prefix
    cmp al, 0x26
    je short .override_es
    cmp al, 0x2e
    je short .override_cs
    cmp al, 0x36
    je short .override_ss
    cmp al, 0x3e
    je short .override_ds
    cmp al, 0x64
    je short .override_fs
    cmp al, 0x65
    je short .override_gs
    cmp al, 0x66
    je short .skip_prefix
    cmp al, 0x67
    jne near .decode_opcode

.skip_prefix:
    inc esi
    jmp short .read_after_prefix

.override_cs:
    mov cx, word [ebp + 0x3c]
    db 0x8b, 0xd1 ; MOV edx, ecx uses the original register opcode.
    inc esi
    jmp short .read_after_prefix

.override_ds:
    mov cx, word [ebp + 4]
    db 0x8b, 0xd1 ; MOV edx, ecx uses the original register opcode.
    inc esi
    jmp short .read_after_prefix

.override_ss:
    mov cx, word [ebp + 6]
    db 0x8b, 0xd1 ; MOV edx, ecx uses the original register opcode.
    inc esi
    jmp short .read_after_prefix

.override_es:
    mov cx, word [ebp + 8]
    db 0x8b, 0xd1 ; MOV edx, ecx uses the original register opcode.
    inc esi
    jmp short .read_after_prefix

.override_fs:
    mov cx, fs
    db 0x8b, 0xd1 ; MOV edx, ecx uses the original register opcode.
    inc esi
    jmp short .read_after_prefix

.override_gs:
    mov cx, gs
    db 0x8b, 0xd1 ; MOV edx, ecx uses the original register opcode.
    inc esi
    jmp short .read_after_prefix

.dispatch_register_operation:
    mov dword [ebp + 0x38], esi
    call reload_runtime_ds
    lea ebp, [emulator_state]
    db 0x8a, 0xd4 ; MOV dl, ah uses the original register opcode.
    and edx, 0x38
    db 0xa, 0xd0 ; OR dl, al uses the original register opcode.
    mov edi, dword ds:[ebp + 4]
    and edi, strict dword 0x3800
    shr edi, 0xb
    db 0x8a, 0xdc ; MOV bl, ah uses the original register opcode.
    and ebx, 7
    db 0x8b, 0xf3 ; MOV esi, ebx uses the original register opcode.
    cmp ax, 0xf801
    jne short .select_stack_register
    mov si, 1

.select_stack_register:
    db 0x03, 0xf7 ; ADD ESI, EDI uses the register-destination opcode.
    and esi, 7
    lea edi, [edi + edi*4]
    db 0x03, 0xff ; ADD EDI, EDI uses the register-destination opcode.
    lea esi, [esi + esi*4]
    db 0x03, 0xf6 ; ADD ESI, ESI uses the register-destination opcode.
    jmp dword cs:[edx*4 + register_dispatch]

.return_unsupported_opcode:
    ret
