BITS 32
ORG 0x6e8d2

debugger_present equ 0x199a8

notify_debugger:
    cmp byte [debugger_present], 0
    je short .disabled
    and edx, 0xffff
    push edx
    push eax
    int3
    jmp short .acknowledge
    db "WVIDEO"
.acknowledge:
    mov eax, 1
    add esp, 8
    ret
.disabled:
    xor eax, eax
    ret
