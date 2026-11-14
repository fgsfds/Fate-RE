; Convert a binary32 operand to the emulator's 10-byte temporary format.
BITS 32
ORG 0x69d9e

extend_single:
    push ecx
    push ebx
    db 0x8b, 0xda ; MOV EBX, EDX
    db 0x2b, 0xd2 ; SUB EDX, EDX
    db 0x8b, 0xc8 ; MOV ECX, EAX
    sar ecx, 23
    and cx, strict word 0xff
    je short .store
    shl eax, 8
    cmp cl, 0xff
    je short .special
    add cx, strict word 0x3f80
    jmp short .merge_sign
.special:
    mov ch, 0xff
    and eax, 0x7fffffff
    je short .merge_sign
    or eax, 0x40000000
.merge_sign:
    db 0x03, 0xc9 ; ADD ECX, ECX
    rcr cx, 1
    or eax, 0x80000000
.store:
    mov [ebx], edx
    mov [ebx + 4], eax
    mov [ebx + 8], cx
    pop ebx
    pop ecx
    ret
