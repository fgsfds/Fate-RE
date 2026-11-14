; Dispatch fatal errors through the debugger hook or the DOS console.
BITS 32
ORG 0x6e69c

write_console_and_exit equ 0x60199
notify_debugger equ 0x6e8d2

fatal_runtime_error:
    push ebx
    push ecx
    mov ebx, eax
    mov ecx, edx
    mov edx, ds
    call notify_debugger
    test eax, eax
    jne short .restore
    mov eax, ebx
    mov edx, ecx
    call write_console_and_exit
.restore:
    pop ecx
    pop ebx
    ret
